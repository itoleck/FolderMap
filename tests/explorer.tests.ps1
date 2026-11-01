[CmdletBinding()]
param(
    [string]$AssemblyPath,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
if ($Launch -and [Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'Explorer launch checks require Windows PowerShell -STA.'
}
Add-Type -AssemblyName System.Windows.Forms
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-explorer-' + [Guid]::NewGuid().ToString('N'))
$treePath = Join-Path $fixture ('Tree space, & ' + [char]0x96ea)
$groupPath = Join-Path $fixture ('Files space, & ' + [char]0x00e9)
$passed = 0
$form = $null
$shell = $null
$originalContext = [Threading.SynchronizationContext]::Current
$existingWindows = [Collections.Generic.HashSet[long]]::new()

function Assert-Explorer([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Assert-ExplorerThrows([scriptblock]$Action, [type]$Expected, [string]$Message) {
    $caught = $null
    try { & $Action } catch { $caught = $_.Exception.GetBaseException() }
    Assert-Explorer ($null -ne $caught -and $Expected.IsInstanceOfType($caught)) $Message
}

function Get-ExplorerPath($Window) {
    if ([IO.Path]::GetFileName($Window.FullName) -ine 'explorer.exe') { return $null }
    # LocationURL can use legacy %-encoding rather than UTF-8; use the native path.
    $item = $Window.Document.Folder.Self
    if ($item.IsFileSystem) {
        return ([string]$item.Path).TrimEnd('\')
    }
    return $null
}

function Wait-ExplorerFolder([string]$Path) {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        [Windows.Forms.Application]::DoEvents()
        foreach ($window in $script:shell.Windows()) {
            if ((Get-ExplorerPath $window) -ieq $Path.TrimEnd('\')) { return $true }
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $deadline)
    $observed = @($script:shell.Windows() | ForEach-Object { Get-ExplorerPath $_ } |
        Where-Object { $_ -and $_.StartsWith($script:fixture, [StringComparison]::OrdinalIgnoreCase) })
    throw "File Explorer did not open the expected test directory: $Path. Observed test locations: $($observed -join '; ')"
}

try {
    [void][IO.Directory]::CreateDirectory($treePath)
    [void][IO.Directory]::CreateDirectory($groupPath)
    [IO.File]::WriteAllBytes((Join-Path $treePath 'tree.bin'), [byte[]]::new(16))
    [IO.File]::WriteAllBytes((Join-Path $groupPath 'group.bin'), [byte[]]::new(32))
    foreach ($path in @($fixture, $treePath, $groupPath, ($groupPath + '\'), [IO.Path]::GetPathRoot($fixture))) {
        $info = [FolderMap.Explorer]::CreateStartInfo($path)
        Assert-Explorer ($info.FileName -ceq [IO.Path]::GetFullPath($path)) 'the exact directory is the shell target'
        Assert-Explorer ($info.UseShellExecute -and $info.Verb -eq 'explore') 'the Windows folder explore verb is requested'
        Assert-Explorer ([string]::IsNullOrEmpty($info.Arguments)) 'paths are never interpolated into command-line arguments'
        Assert-Explorer (-not $info.ErrorDialog) 'launch failures are returned to the application for visible reporting'
    }
    Assert-ExplorerThrows { [FolderMap.Explorer]::CreateStartInfo($null) } ([ArgumentException]) 'null paths are rejected'
    Assert-ExplorerThrows { [FolderMap.Explorer]::CreateStartInfo(' ') } ([ArgumentException]) 'blank paths are rejected'
    Assert-ExplorerThrows { [FolderMap.Explorer]::CreateStartInfo((Join-Path $fixture 'missing')) } ([IO.IOException]) 'unavailable folders fail explicitly'
    Assert-ExplorerThrows { [FolderMap.Explorer]::CreateStartInfo((Join-Path $treePath 'tree.bin')) } ([ArgumentException]) 'regular files are not launched as programs'
    Assert-ExplorerThrows { [FolderMap.Explorer]::Open((Join-Path $fixture 'missing')) } ([IO.IOException]) 'the launch operation rejects missing directories before invoking the shell'

    if ($Launch) {
        $shell = New-Object -ComObject Shell.Application
        foreach ($window in $shell.Windows()) { [void]$existingWindows.Add([long]$window.HWND) }
        [Windows.Forms.Application]::EnableVisualStyles()
        $form = [FolderMap.MainForm]::new()
        $form.ShowInTaskbar = $false
        $form.Show()
        $flags = [Reflection.BindingFlags]'NonPublic,Instance'
        $result = [FolderMap.Scanner]::Scan($fixture, $null)
        $completed = [ComponentModel.RunWorkerCompletedEventArgs]::new($result, $null, $false)
        $form.GetType().GetMethod('ScanCompleted', $flags).Invoke($form, @($null, $completed))
        [Windows.Forms.Application]::DoEvents()
        $tree = $form.Controls.Find('folderTree', $true)[0]
        $map = $form.Controls.Find('treemap', $true)[0]
        $menu = $form.GetType().GetField('folderMenu', $flags).GetValue($form)
        $menuInvocations = [Collections.Generic.List[string]]::new()
        $menu.Items[0].add_Click({ $script:menuInvocations.Add($menu.Tag) })

        foreach ($source in @('tree', 'treemap')) {
            $form.Activate()
            [Windows.Forms.Application]::DoEvents()
            $expectedPath = if ($source -eq 'tree') { $treePath } else { $groupPath }
            $target = @($result.Root.Children | Where-Object FullPath -eq $expectedPath)[0]
            if ($source -eq 'tree') {
                $node = @($tree.Nodes[0].Nodes | Where-Object { $_.Tag -eq $target })[0]
                $mouse = [Windows.Forms.TreeNodeMouseClickEventArgs]::new(
                    $node, [Windows.Forms.MouseButtons]::Right, 1, $node.Bounds.X + 5, $node.Bounds.Y + 5)
                $tree.GetType().GetMethod('OnNodeMouseClick', $flags).Invoke($tree, @($mouse))
            } else {
                $map.GetType().GetMethod('EnsureLayout', $flags).Invoke($map, @())
                $tiles = $map.GetType().GetField('tiles', $flags).GetValue($map)
                $tile = @($tiles | Where-Object { $_.Folder -eq $target -and $_.DirectFiles })[0]
                $mouse = [Windows.Forms.MouseEventArgs]::new(
                    [Windows.Forms.MouseButtons]::Right, 1, [int]$tile.Bounds.X + 5, [int]$tile.Bounds.Y + 5, 0)
                $map.GetType().GetMethod('OnMouseClick', $flags).Invoke($map, @($mouse))
            }
            Assert-Explorer ($menu.Visible -and $menu.Tag -ceq $expectedPath) "$source menu captures the right-clicked directory"
            $beforeClick = $menuInvocations.Count
            $menu.Items[0].PerformClick()
            Assert-Explorer ($menuInvocations.Count -eq $beforeClick + 1 -and $menuInvocations[$beforeClick] -ceq $expectedPath) "$source menu action is invoked for the captured directory"
            $menu.Close()
            Assert-Explorer (Wait-ExplorerFolder $expectedPath) "$source menu action opens File Explorer at that exact directory"
        }
    }
} finally {
    if ($null -ne $form) { $form.Dispose() }
    [Threading.SynchronizationContext]::SetSynchronizationContext($originalContext)
    if ($null -ne $shell) {
        # Close only newly created Explorer windows still showing this unique fixture.
        foreach ($window in @($shell.Windows())) {
            $path = Get-ExplorerPath $window
            if ($path -and -not $existingWindows.Contains([long]$window.HWND) -and
                ($path -ieq $fixture -or $path.StartsWith($fixture + '\', [StringComparison]::OrdinalIgnoreCase))) {
                $window.Quit()
            }
        }
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)
    }
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
}
Write-Host "Explorer tests: $passed passed, 0 failed (launch checks: $Launch)."
