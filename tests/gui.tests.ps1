[CmdletBinding()]
param(
    [string]$AssemblyPath,
    [string]$ScreenshotPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'GUI tests require Windows PowerShell with -STA.'
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
[Windows.Forms.Application]::SetUnhandledExceptionMode([Windows.Forms.UnhandledExceptionMode]::ThrowException)
[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
$originalThreadChecks = [Windows.Forms.Control]::CheckForIllegalCrossThreadCalls
[Windows.Forms.Control]::CheckForIllegalCrossThreadCalls = $true
$originalContext = [Threading.SynchronizationContext]::Current
$uiContext = $null

$passed = 0
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-gui-' + [Guid]::NewGuid().ToString('N'))
$cacheFixture = $fixture + '-cache'
$form = $null
$shortcutForm = $null
$bitmap = $null

function Assert-Gui([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Wait-Scan($Window) {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        [Windows.Forms.Application]::DoEvents()
        if ([DateTime]::UtcNow -gt $deadline) { throw 'GUI scan did not complete within 20 seconds.' }
        Start-Sleep -Milliseconds 10
    } while ($Window.IsScanning())
    [Windows.Forms.Application]::DoEvents()
    if ($Window.LastError) { throw $Window.LastError }
}

function Start-GuiScan($Button) {
    # DoEvents restores the host context; match Application.Run before starting work.
    [Threading.SynchronizationContext]::SetSynchronizationContext($script:uiContext)
    $Button.PerformClick()
}

function Assert-StatusText($Status, [string]$Scenario) {
    $Status.PerformLayout()
    foreach ($item in @($Status.Items | Where-Object { $_.Visible -and $_.Text })) {
        $textSize = [Windows.Forms.TextRenderer]::MeasureText($item.Text, $item.Font)
        Assert-Gui ($item.ContentRectangle.Height -ge $textSize.Height) "$Scenario`: status text fits vertically"
        Assert-Gui ($item.Bounds.Top -ge 4 -and $item.Bounds.Bottom -le $Status.ClientSize.Height - 4) "$Scenario`: status items have vertical breathing room"
    }
    Assert-Gui ($Status.Height -ge $Status.PreferredSize.Height) "$Scenario`: the status row accommodates its preferred height"
    Assert-Gui ($Status.Bottom -le $Status.Parent.ClientSize.Height - $Status.Parent.Padding.Bottom) "$Scenario`: the status bar remains inside the window padding"
}

function Assert-SelectionStatus($Status, $Folder, [long]$Bytes, [bool]$DirectFiles) {
    $text = $Status.Items[0].Text
    $prefix = if ($DirectFiles) { '[Files here] | ' } else { 'Folder | ' }
    Assert-Gui ($text.StartsWith($prefix) -and $text.Contains($Folder.FullPath)) 'status identifies the selected item and its full path'
    Assert-Gui ($text.Contains("$Bytes bytes")) 'status shows the selected item byte count rather than a different folder total'
    if ($DirectFiles) {
        Assert-Gui ($text.Contains("$($Folder.DirectFiles) files directly in this folder")) 'file-group status uses direct file counts'
    } else {
        Assert-Gui ($text.Contains("$($Folder.TotalFiles) files") -and $text.Contains("$($Folder.FolderCount) subfolders")) 'folder status uses recursive counts'
    }
    Assert-Gui ($Status.ShowItemToolTips -and $Status.Items[0].ToolTipText -eq $text) 'full selection details are available in the status tooltip'
}

function Assert-CheckedChoice($Menu, [int]$Expected) {
    $checked = @($Menu.DropDownItems | Where-Object Checked)
    Assert-Gui ($checked.Count -eq 1 -and [int]$checked[0].Tag -eq $Expected) 'exactly the active menu choice is checked'
}

function Assert-CompletionTime($Window, $Status) {
    $match = [regex]::Match($Status.Items[0].Text, 'Scan completed in ([0-9]+\.[0-9]{3}) s\.')
    Assert-Gui $match.Success 'successful scans report their total elapsed time'
    $clock = $Window.GetType().GetField('scanClock', [Reflection.BindingFlags]'NonPublic,Instance').GetValue($Window)
    $seconds = [double]::Parse($match.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
    Assert-Gui (-not $clock.IsRunning -and [Math]::Abs($seconds - $clock.ElapsedMilliseconds / 1000.0) -lt 0.00051) 'completion time matches the stopped scan stopwatch'
}

function Invoke-MapClick($Map, $Folder, [bool]$DirectFiles,
    [Windows.Forms.MouseButtons]$Button = [Windows.Forms.MouseButtons]::Left) {
    $flags = [Reflection.BindingFlags]'NonPublic,Instance'
    $Map.GetType().GetMethod('EnsureLayout', $flags).Invoke($Map, @())
    $tiles = $Map.GetType().GetField('tiles', $flags).GetValue($Map)
    $tile = @($tiles | Where-Object { $_.Folder -eq $Folder -and $_.DirectFiles -eq $DirectFiles })[0]
    if ($null -eq $tile) { throw "No clickable tile for $($Folder.FullPath), direct=$DirectFiles" }
    $mouse = [Windows.Forms.MouseEventArgs]::new($Button, 1,
        [int]$tile.Bounds.X + 5, [int]$tile.Bounds.Y + 5, 0)
    $Map.GetType().GetMethod('OnMouseClick', $flags).Invoke($Map, @($mouse))
    return $tile
}

try {
    [void][IO.Directory]::CreateDirectory((Join-Path $fixture 'alpha\deep'))
    [void][IO.Directory]::CreateDirectory((Join-Path $fixture 'beta'))
    [void][IO.Directory]::CreateDirectory((Join-Path $fixture 'empty'))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'root.bin'), [byte[]]::new(50))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'alpha\a.bin'), [byte[]]::new(120))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'alpha\deep\d.bin'), [byte[]]::new(30))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'beta\b.bin'), [byte[]]::new(200))

    $form = [FolderMap.MainForm]::new()
    $form.CacheDirectory = $cacheFixture
    $phaseLog = [Collections.Generic.List[object]]::new()
    $scanWorker = $form.GetType().GetField('worker', [Reflection.BindingFlags]'NonPublic,Instance').GetValue($form)
    $scanWorker.add_ProgressChanged({
        param($sourceWorker, $phaseEvent)
        if ($phaseEvent.UserState -is [FolderMap.ScanProgressUpdate]) { $script:phaseLog.Add($phaseEvent.UserState.Mode) }
    })
    $form.ShowInTaskbar = $false
    $form.SetInitialPath($fixture)
    $form.Show()
    $uiContext = [Windows.Forms.WindowsFormsSynchronizationContext]::new()
    Wait-Scan $form
    Assert-Gui ($form.LastResult.Root.TotalBytes -eq 400) 'background scan publishes the correct recursive total'
    Assert-Gui ($form.LastResult.Root.FolderCount -eq 4) 'all descendant folders are included'
    Assert-Gui ($form.CurrentFolder -eq $form.LastResult.Root) 'initial selection is the scanned root'
    Assert-Gui ($form.Handle -ne [IntPtr]::Zero -and $form.Visible) 'a real native GUI window is created'
    Assert-Gui ([Environment]::Is64BitProcess) 'the GUI runs in a 64-bit process'
    Assert-Gui ($phaseLog.Contains([FolderMap.ScanCacheMode]::Checking) -and
        $phaseLog.Contains([FolderMap.ScanCacheMode]::FullScan) -and
        -not $phaseLog.Contains([FolderMap.ScanCacheMode]::UsingCache)) 'a fresh scan reports checking and then full scanning, not unverified cache reuse'
    $mainMenu = $form.MainMenuStrip
    Assert-Gui ($null -ne $mainMenu -and $mainMenu.Visible) 'a visible standard main menu is installed'
    Assert-Gui ($mainMenu.Items.Count -eq 3 -and $mainMenu.Items[0].Text -eq '&File' -and
        $mainMenu.Items[1].Text -eq '&Edit' -and $mainMenu.Items[2].Text -eq '&Treemaps') 'File, Edit, and Treemaps are available as top-level menus'
    $fileMenu = $mainMenu.Items[0]
    Assert-Gui ($fileMenu.DropDownItems.Count -eq 5 -and $fileMenu.DropDownItems[4].Text -eq 'E&xit') 'the File menu retains Exit after the scan, retry and administrator commands'
    $exitItem = $fileMenu.DropDownItems[4]
    $fullScanItem = $fileMenu.DropDownItems[0]
    $retryCacheItem = $fileMenu.DropDownItems[1]
    $restartItem = $fileMenu.DropDownItems[2]
    Assert-Gui ($retryCacheItem.Text -eq 'Retry &USN cache') 'a paused cache can be retried explicitly'
    Assert-Gui ($fullScanItem.Text -eq '&Full rescan' -and
        $fullScanItem.ShortcutKeys -eq ([Windows.Forms.Keys]::Control -bor [Windows.Forms.Keys]::F5)) 'a full rescan is available through File and Ctrl+F5'
    Assert-Gui ($restartItem.Text -eq 'Restart as &administrator...' -and
        $restartItem.Enabled -eq (-not [FolderMap.Elevation]::IsAdministrator())) 'administrator restart is explicit and disabled when already elevated'
    $exitKeys = [Windows.Forms.Keys]([Windows.Forms.Keys]::Alt -bor [Windows.Forms.Keys]::F4)
    Assert-Gui ($exitItem.ShortcutKeys -eq $exitKeys -and $exitItem.ShowShortcutKeys) 'Exit advertises and handles Alt+F4'
    $fileMenu.ShowDropDown()
    [Windows.Forms.Application]::DoEvents()
    Assert-Gui ($fileMenu.DropDown.Visible -and $exitItem.Visible -and $exitItem.Enabled) 'opening File reveals an enabled Exit command'
    $fileMenu.HideDropDown()
    Assert-Gui ($mainMenu.Top -eq 0 -and $form.Controls[0].Top -ge $mainMenu.Bottom) 'the menu occupies its own top row without overlapping content'

    $tree = $form.Controls.Find('folderTree', $true)[0]
    $map = $form.Controls.Find('treemap', $true)[0]
    $algorithmMenu = $mainMenu.Items[2]
    $colorsMenu = $mainMenu.Items[1].DropDownItems[0]
    Assert-Gui ($algorithmMenu.DropDownItems.Count -eq 3) 'all three tiling algorithms are offered'
    Assert-Gui ($colorsMenu.Text -eq '&Colors' -and $colorsMenu.DropDownItems.Count -eq 5) 'Edit Colors offers all five palettes'
    Assert-Gui ([int]$map.Algorithm -eq 0 -and $algorithmMenu.DropDownItems[0].Checked) 'Binary is the default layout'
    Assert-Gui ([int]$map.ColorScheme -eq 0 -and $colorsMenu.DropDownItems[0].Checked) 'Classic is the default color scheme'
    Assert-CheckedChoice $algorithmMenu 0
    Assert-CheckedChoice $colorsMenu 0
    foreach ($setting in @(
        @{ Name = 'Algorithm'; Type = [FolderMap.TreemapAlgorithm]; Invalid = -1 },
        @{ Name = 'Algorithm'; Type = [FolderMap.TreemapAlgorithm]; Invalid = 3 },
        @{ Name = 'ColorScheme'; Type = [FolderMap.ColorScheme]; Invalid = -1 },
        @{ Name = 'ColorScheme'; Type = [FolderMap.ColorScheme]; Invalid = 5 }
    )) {
        $caught = $null
        try {
            $map.GetType().GetProperty($setting.Name).SetValue($map, [Enum]::ToObject($setting.Type, $setting.Invalid), $null)
        } catch {
            $caught = $_.Exception.GetBaseException()
        }
        Assert-Gui ($caught -is [ArgumentOutOfRangeException]) 'invalid display options fail explicitly'
    }
    Assert-Gui ([int]$map.Algorithm -eq 0 -and [int]$map.ColorScheme -eq 0) 'invalid options do not change the current view settings'
    $up = $form.Controls.Find('upButton', $true)[0]
    $scan = $form.Controls.Find('scanButton', $true)[0]
    $cancel = $form.Controls.Find('cancelButton', $true)[0]
    $pathBox = $form.Controls.Find('pathBox', $true)[0]
    $root = $form.LastResult.Root
    $alpha = @($root.Children | Where-Object Name -eq 'alpha')[0]
    $beta = @($root.Children | Where-Object Name -eq 'beta')[0]
    $empty = @($root.Children | Where-Object Name -eq 'empty')[0]
    $deep = $alpha.Children[0]
    $status = @($form.Controls[0].Controls | Where-Object { $_ -is [Windows.Forms.StatusStrip] })[0]
    Assert-SelectionStatus $status $root 400 $false
    Assert-CompletionTime $form $status
    Assert-Gui (-not [string]::IsNullOrWhiteSpace($form.LastResult.CacheInfo) -and
        $status.Items[0].Text.Contains($form.LastResult.CacheInfo)) 'scan provenance and cache fallback information are visible'
    $flags = [Reflection.BindingFlags]'NonPublic,Instance'
    $menuField = $form.GetType().GetField('folderMenu', $flags)
    Assert-Gui ($null -ne $menuField) 'both views have an Explorer context menu'
    $folderMenu = $menuField.GetValue($form)
    Assert-Gui ($folderMenu.Items.Count -eq 1 -and $folderMenu.Items[0].Text -eq 'Open in File Explorer') 'the context menu provides the Explorer action'
    Assert-Gui ($tree.Nodes.Count -eq 1 -and $tree.Nodes[0].Nodes.Count -eq 3) 'root expansion populates the folder tree'
    Assert-Gui ($tree.Nodes[0].Text.Contains('400 bytes')) 'the tree shows exact byte counts'
    Assert-Gui (-not $up.Enabled -and $scan.Enabled -and -not $cancel.Enabled) 'idle navigation and scan controls have correct states'

    $form.SelectFolder($deep)
    [Windows.Forms.Application]::DoEvents()
    Assert-Gui ($tree.SelectedNode.Tag -eq $deep -and $map.Root -eq $deep) 'deep navigation synchronizes the tree and treemap'
    Assert-SelectionStatus $status $deep 30 $false
    Assert-Gui ($up.Enabled) 'Up is enabled below the root'
    $up.PerformClick()
    Assert-Gui ($form.CurrentFolder -eq $alpha) 'Up navigates to the parent'
    Assert-SelectionStatus $status $alpha 150 $false
    $up.PerformClick()
    Assert-Gui ($form.CurrentFolder -eq $root) 'Up returns to the root'

    $betaTree = @($tree.Nodes[0].Nodes | Where-Object { $_.Tag -eq $beta })[0]
    $tree.SelectedNode = $betaTree
    Assert-Gui ($form.CurrentFolder -eq $beta -and $map.Root -eq $beta) 'tree selection changes the displayed folder'
    Assert-SelectionStatus $status $beta 200 $false
    $form.SelectFolder($root)
    [Windows.Forms.Application]::DoEvents()
    $flags = [Reflection.BindingFlags]'NonPublic,Instance'
    $tiles = $map.GetType().GetField('tiles', $flags).GetValue($map)
    $alphaTile = @($tiles | Where-Object { $_.Folder -eq $alpha -and -not $_.DirectFiles })[0]
    $mouse = [Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::Left, 2,
        [int]$alphaTile.Bounds.X + 5, [int]$alphaTile.Bounds.Y + 5, 0)
    $beforeHover = $status.Items[0].Text
    $map.GetType().GetMethod('OnMouseMove', $flags).Invoke($map, @($mouse))
    Assert-Gui ($status.Items[0].Text -eq $beforeHover) 'hover does not replace the pinned selection'
    [void](Invoke-MapClick $map $alpha $false)
    Assert-Gui ($map.Root -eq $root -and $form.CurrentFolder -eq $root) 'single-clicking a tile shows details without zooming'
    Assert-Gui ($map.SelectedTile.Folder -eq $alpha -and -not $map.SelectedTile.DirectFiles) 'the clicked folder is retained for its selection highlight'
    Assert-SelectionStatus $status $alpha 150 $false
    [void](Invoke-MapClick $map $alpha $true)
    Assert-SelectionStatus $status $alpha 120 $true
    $scanSnapshot = $form.LastResult
    $selectedDetails = $status.Items[0].Text
    foreach ($algorithmItem in $algorithmMenu.DropDownItems) {
        $algorithmItem.PerformClick()
        $map.Refresh()
        Assert-Gui ([int]$map.Algorithm -eq [int]$algorithmItem.Tag) 'the Treemaps menu applies its tiling algorithm immediately'
        Assert-CheckedChoice $algorithmMenu ([int]$algorithmItem.Tag)
        Assert-Gui ($form.CurrentFolder -eq $root -and $map.Root -eq $root -and
            [object]::ReferenceEquals($form.LastResult, $scanSnapshot) -and -not $form.IsScanning()) 'changing tilers preserves the zoom and scan result without rescanning'
        Assert-Gui ($map.SelectedTile.Folder -eq $alpha -and $map.SelectedTile.DirectFiles -and
            $status.Items[0].Text -eq $selectedDetails) 'changing tilers preserves the selected item and status details'
        [void](Invoke-MapClick $map $alpha $true ([Windows.Forms.MouseButtons]::Right))
        Assert-Gui ($folderMenu.Visible -and $folderMenu.Tag -ceq $alpha.FullPath) 'the context menu targets the correct group after retiling'
        $folderMenu.Close()
        [void](Invoke-MapClick $map $beta $false)
        Assert-SelectionStatus $status $beta 200 $false
        [void](Invoke-MapClick $map $alpha $true)
        foreach ($colorItem in $colorsMenu.DropDownItems) {
            $beforeColors = $map.GetType().GetField('tiles', $flags).GetValue($map)
            $beforeBounds = (@($beforeColors | ForEach-Object { $_.Bounds.ToString() }) -join '|')
            $colorItem.PerformClick()
            $map.Refresh()
            Assert-Gui ([int]$map.ColorScheme -eq [int]$colorItem.Tag) 'Edit Colors applies the selected palette immediately'
            Assert-CheckedChoice $colorsMenu ([int]$colorItem.Tag)
            $coloredTiles = $map.GetType().GetField('tiles', $flags).GetValue($map)
            $afterBounds = (@($coloredTiles | ForEach-Object { $_.Bounds.ToString() }) -join '|')
            Assert-Gui ($beforeBounds -eq $afterBounds -and [int]$map.Algorithm -eq [int]$algorithmItem.Tag) 'changing colors does not change the tiling geometry'
            Assert-Gui ($map.SelectedTile.Folder -eq $alpha -and $map.SelectedTile.DirectFiles -and
                $status.Items[0].Text -eq $selectedDetails) 'palette changes preserve the selected group'
            $groupTile = @($coloredTiles | Where-Object { $_.Folder -eq $alpha -and $_.DirectFiles })[0]
            $colorBitmap = [Drawing.Bitmap]::new($map.Width, $map.Height)
            try {
                $map.DrawToBitmap($colorBitmap, [Drawing.Rectangle]::new(0, 0, $map.Width, $map.Height))
                $pixel = $colorBitmap.GetPixel(
                    [int]($groupTile.Bounds.X + $groupTile.Bounds.Width / 2),
                    [int]($groupTile.Bounds.Y + $groupTile.Bounds.Height / 2))
                $expectedColor = [FolderMap.TileColors]::GetColor($alpha, $map.ColorScheme)
                Assert-Gui ($pixel.ToArgb() -eq $expectedColor.ToArgb()) 'the painted tile uses the selected palette'
            } finally {
                $colorBitmap.Dispose()
            }
        }
    }
    $algorithmMenu.DropDownItems[1].PerformClick()
    $colorsMenu.DropDownItems[1].PerformClick()
    $algorithmMenu.DropDownItems[1].PerformClick()
    $colorsMenu.DropDownItems[1].PerformClick()
    Assert-CheckedChoice $algorithmMenu 1
    Assert-CheckedChoice $colorsMenu 1
    $map.Refresh()
    $selectionBitmap = [Drawing.Bitmap]::new($map.Width, $map.Height)
    try {
        $map.DrawToBitmap($selectionBitmap, [Drawing.Rectangle]::new(0, 0, $map.Width, $map.Height))
        $renderedTiles = $map.GetType().GetField('tiles', $flags).GetValue($map)
        $renderedSelection = @($renderedTiles | Where-Object { $_.Folder -eq $alpha -and $_.DirectFiles })[0]
        $selectionBounds = [Drawing.Rectangle]::Round($renderedSelection.Bounds)
        Assert-Gui ($selectionBitmap.GetPixel($selectionBounds.X + 1, $selectionBounds.Y + 1).ToArgb() -eq [Drawing.Color]::White.ToArgb()) 'the selected tile is visibly outlined'
    } finally {
        $selectionBitmap.Dispose()
    }
    $map.GetType().GetMethod('OnMouseLeave', $flags).Invoke($map, @([EventArgs]::Empty))
    Assert-SelectionStatus $status $alpha 120 $true
    [void](Invoke-MapClick $map $beta $false ([Windows.Forms.MouseButtons]::Right))
    Assert-Gui ($folderMenu.Visible -and $folderMenu.SourceControl -eq $map -and $folderMenu.Tag -ceq $beta.FullPath) 'treemap right-click targets the clicked folder, not the selected tile'
    Assert-Gui ($folderMenu.Tag -is [string]) 'context targets retain only their path, not old scan trees'
    Assert-Gui ($folderMenu.Items[0].ToolTipText -eq $beta.FullPath) 'the Explorer action identifies the exact target path'
    $folderMenu.Close()
    [void](Invoke-MapClick $map $alpha $true ([Windows.Forms.MouseButtons]::Right))
    Assert-Gui ($folderMenu.Visible -and $folderMenu.Tag -ceq $alpha.FullPath) 'a Files here context menu targets the folder containing that file group'
    $folderMenu.Close()
    [void](Invoke-MapClick $map $root $true ([Windows.Forms.MouseButtons]::Right))
    Assert-Gui ($folderMenu.Tag -ceq $root.FullPath) 'a root-level file group targets the scanned root, not its parent'
    $folderMenu.Close()
    $outsideRight = [Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::Right, 1, -1, -1, 0)
    $map.GetType().GetMethod('OnMouseClick', $flags).Invoke($map, @($outsideRight))
    Assert-Gui (-not $folderMenu.Visible) 'right-clicking empty treemap space does not offer a stale target'
    foreach ($node in @($tree.Nodes[0], $betaTree, @($tree.Nodes[0].Nodes | Where-Object { $_.Tag -eq $empty })[0])) {
        $rightClick = [Windows.Forms.TreeNodeMouseClickEventArgs]::new($node, [Windows.Forms.MouseButtons]::Right, 1, 10, 10)
        $tree.GetType().GetMethod('OnNodeMouseClick', $flags).Invoke($tree, @($rightClick))
        Assert-Gui ($folderMenu.Visible -and $folderMenu.SourceControl -eq $tree -and $folderMenu.Tag -ceq $node.Tag.FullPath) 'folder-list right-click targets the requested root, child, or empty folder'
        $folderMenu.Close()
    }
    $placeholder = [Windows.Forms.TreeNode]::new('Expand to load folders')
    $placeholderClick = [Windows.Forms.TreeNodeMouseClickEventArgs]::new($placeholder, [Windows.Forms.MouseButtons]::Right, 1, 10, 10)
    $tree.GetType().GetMethod('OnNodeMouseClick', $flags).Invoke($tree, @($placeholderClick))
    Assert-Gui (-not $folderMenu.Visible) 'placeholder nodes do not offer an Explorer action'
    Assert-Gui ($form.CurrentFolder -eq $root -and $map.Root -eq $root) 'context menus do not zoom or change the current folder'
    Assert-SelectionStatus $status $alpha 120 $true
    $outside = [Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::Left, 1, -1, -1, 0)
    $map.GetType().GetMethod('OnMouseClick', $flags).Invoke($map, @($outside))
    Assert-Gui ($map.SelectedTile.Folder -eq $alpha -and $map.SelectedTile.DirectFiles) 'right-clicking and clicking outside tiles preserve the selection'
    $rootClick = [Windows.Forms.TreeNodeMouseClickEventArgs]::new($tree.Nodes[0], [Windows.Forms.MouseButtons]::Left, 1, 0, 0)
    $tree.GetType().GetMethod('OnNodeMouseClick', $flags).Invoke($tree, @($rootClick))
    Assert-Gui ($null -eq $map.SelectedTile) 'clicking the already-selected tree folder clears a tile selection'
    Assert-SelectionStatus $status $root 400 $false
    $alphaTile = Invoke-MapClick $map $alpha $false
    $mouse = [Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::Left, 2,
        [int]$alphaTile.Bounds.X + 5, [int]$alphaTile.Bounds.Y + 5, 0)
    $map.GetType().GetMethod('OnMouseDoubleClick', $flags).Invoke($map, @($mouse))
    Assert-Gui ($form.CurrentFolder -eq $alpha -and $tree.SelectedNode.Tag -eq $alpha) 'a treemap double-click drills down and synchronizes the tree'
    Assert-Gui ([int]$map.Algorithm -eq 1 -and [int]$map.ColorScheme -eq 1) 'zooming retains the chosen layout and palette'
    Assert-SelectionStatus $status $alpha 150 $false
    $map.GetType().GetMethod('OnMouseLeave', $flags).Invoke($map, @([EventArgs]::Empty))

    $form.SelectFolder($empty)
    [Windows.Forms.Application]::DoEvents()
    $emptyTiles = $map.GetType().GetField('tiles', $flags).GetValue($map)
    Assert-Gui ($emptyTiles.Count -eq 0 -and $form.CurrentFolder.TotalBytes -eq 0) 'empty folders show an empty map rather than stale tiles'
    Assert-Gui ([int]$map.Algorithm -eq 1 -and [int]$map.ColorScheme -eq 1) 'empty-folder navigation retains display preferences'
    Assert-SelectionStatus $status $empty 0 $false

    $form.SelectFolder($root)
    $form.Size = [Drawing.Size]::new(980, 620)
    [Windows.Forms.Application]::DoEvents()
    Assert-Gui ($tree.Width -ge 250 -and $map.Width -ge 340 -and $map.Height -gt 200) 'both panels remain usable at the minimum window size'
    $form.ClientSize = [Drawing.Size]::new(1280, 820)
    [Windows.Forms.Application]::DoEvents()
    $originalStatusFont = $status.Font
    $originalStatusText = $status.Items[0].Text
    $originalWindowSize = $form.Size
    $scaledFont = $null
    try {
        foreach ($scale in @(1.5, 1, 2)) {
            $scaledFont = [Drawing.Font]::new($originalStatusFont.FontFamily, [single]($originalStatusFont.Size * $scale))
            $status.Font = $scaledFont
            foreach ($text in @($originalStatusText, "$originalStatusText`r`nPartial scan - some entries are excluded from totals.")) {
                $status.Items[0].Text = $text
                foreach ($size in @($originalWindowSize, $form.MinimumSize)) {
                    $form.Size = $size
                    $form.PerformLayout()
                    [Windows.Forms.Application]::DoEvents()
                    Assert-StatusText $status "Multiline details, font scale $scale at $($size.Width)x$($size.Height)"
                }
            }
            $status.Font = $originalStatusFont
            $scaledFont.Dispose()
            $scaledFont = $null
        }
    } finally {
        $status.Font = $originalStatusFont
        $status.Items[0].Text = $originalStatusText
        $form.Size = $originalWindowSize
        if ($null -ne $scaledFont) { $scaledFont.Dispose() }
        [Windows.Forms.Application]::DoEvents()
    }
    $bitmap = [Drawing.Bitmap]::new($form.Width, $form.Height)
    $form.DrawToBitmap($bitmap, [Drawing.Rectangle]::new(0, 0, $form.Width, $form.Height))
    Assert-Gui ($bitmap.Width -gt 1200 -and $bitmap.Height -gt 700) 'the complete window renders successfully'
    if ($ScreenshotPath) { $bitmap.Save($ScreenshotPath, [Drawing.Imaging.ImageFormat]::Png) }
    $bitmap.Dispose()
    $bitmap = $null
    $mapBitmap = [Drawing.Bitmap]::new($map.Width, $map.Height)
    try {
        $map.DrawToBitmap($mapBitmap, [Drawing.Rectangle]::new(0, 0, $map.Width, $map.Height))
        $colored = 0
        for ($x = 15; $x -lt $map.Width - 15; $x += 30) {
            for ($y = 15; $y -lt $map.Height - 15; $y += 30) {
                if ($mapBitmap.GetPixel($x, $y).ToArgb() -ne $map.BackColor.ToArgb()) { $colored++ }
            }
        }
        Assert-Gui ($colored -gt 50) 'the treemap paints data rectangles, not just a blank background'
    } finally {
        $mapBitmap.Dispose()
    }

    $previous = $form.LastResult
    Start-GuiScan $scan
    Assert-Gui ($pathBox.ReadOnly -and -not $scan.Enabled -and $cancel.Enabled) 'scanning locks the input without blocking the GUI'
    Assert-Gui ($status.Items[0].Text.Contains('Checking cache')) 'a regular scan starts by reporting cache eligibility checking'
    Assert-Gui (-not $fullScanItem.Enabled) 'a second full scan cannot be started while scanning'
    Assert-Gui (-not $retryCacheItem.Enabled) 'a cache retry cannot race an active scan'
    $algorithmMenu.DropDownItems[2].PerformClick()
    $colorsMenu.DropDownItems[3].PerformClick()
    Assert-Gui ([int]$map.Algorithm -eq 2 -and [int]$map.ColorScheme -eq 3) 'layout and color choices remain available during a scan'
    [void](Invoke-MapClick $map $root $true)
    $stage = [FolderMap.ScanProgressUpdate]::new([FolderMap.ScanCacheMode]::UsingCache, 'Refreshing changed folders.')
    $stageEvent = [ComponentModel.ProgressChangedEventArgs]::new(0, $stage)
    $form.GetType().GetMethod('ScanProgress', $flags).Invoke($form, @($null, $stageEvent))
    $progress = [ComponentModel.ProgressChangedEventArgs]::new(0, 'C:\progress-test')
    $form.GetType().GetMethod('ScanProgress', $flags).Invoke($form, @($null, $progress))
    Assert-SelectionStatus $status $root 50 $true
    Assert-Gui ($status.Items[0].Text.Contains('Using cache') -and $status.Items[0].Text.Contains('C:\progress-test')) 'folder progress retains the cache-in-use callout'
    $stage = [FolderMap.ScanProgressUpdate]::new([FolderMap.ScanCacheMode]::FullScan, 'Cache cannot be reused.')
    $form.GetType().GetMethod('ScanProgress', $flags).Invoke($form, @($null, [ComponentModel.ProgressChangedEventArgs]::new(0, $stage)))
    $form.GetType().GetMethod('ScanProgress', $flags).Invoke($form, @($null, $progress))
    Assert-Gui ($status.Items[0].Text.Contains('Full scan (cache not used)') -and
        -not $status.Items[0].Text.Contains('Using cache')) 'fallback updates the mode and later folder progress preserves it'
    Assert-StatusText $status 'During a scan with the progress indicator visible'
    $cancel.PerformClick()
    Wait-Scan $form
    Assert-Gui ([object]::ReferenceEquals($form.LastResult, $previous)) 'cancellation, including a late cancellation, preserves the previous result'
    Assert-Gui (-not $pathBox.ReadOnly -and $scan.Enabled -and -not $cancel.Enabled) 'controls recover after cancellation'
    Assert-SelectionStatus $status $root 50 $true
    Assert-Gui ($status.Items[0].Text.Contains('Scan cancelled.')) 'cancellation is reported alongside the preserved selection'
    Assert-Gui (-not $status.Items[0].Text.Contains('Scan completed in')) 'cancellation is not reported as successful completion'
    [IO.File]::WriteAllBytes((Join-Path $fixture 'root.bin'), [byte[]]::new(75))
    $phaseLog.Clear()
    Start-GuiScan $fullScanItem
    Assert-Gui ($status.Items[0].Text.Contains('Full scan (cache not used)')) 'forced full scans immediately report that the cache is bypassed'
    Wait-Scan $form
    Assert-Gui ($phaseLog.Count -gt 0 -and @($phaseLog | Where-Object { $_ -ne [FolderMap.ScanCacheMode]::FullScan }).Count -eq 0) 'the backend reports cache bypass throughout a forced full scan'
    Assert-Gui ($form.LastResult.Root.TotalBytes -eq 425) 'a rescan refreshes sizes rather than accumulating prior totals'
    Assert-Gui ($form.LastResult.ReusedDirectories -eq 0 -and $form.LastResult.RefreshedDirectories -ge 5) 'File Full rescan bypasses cached directory sizes'
    Assert-Gui ([int]$map.Algorithm -eq 2 -and [int]$map.ColorScheme -eq 3) 'rescanning preserves the chosen layout and palette'
    Assert-CheckedChoice $algorithmMenu 2
    Assert-CheckedChoice $colorsMenu 3
    Assert-SelectionStatus $status $form.LastResult.Root 425 $false
    Assert-CompletionTime $form $status
    $completedStatus = $status.Items[0].Text
    $form.GetType().GetMethod('ScanProgress', $flags).Invoke($form, @($null, $progress))
    Assert-Gui ($status.Items[0].Text -ceq $completedStatus) 'late progress cannot overwrite the completed scan time'
    $policyKey = [FolderMap.CachePolicy]::Key($fixture, $cacheFixture)
    [FolderMap.CachePolicy]::RecordOutcome($policyKey, $true, 0, 'First ineligible cache attempt')
    [FolderMap.CachePolicy]::RecordOutcome($policyKey, $true, 0, 'Second ineligible cache attempt')
    Start-GuiScan $scan
    Wait-Scan $form
    Assert-Gui ($form.LastResult.CacheInfo.Contains('USN cache paused') -and -not $form.LastResult.CacheConsidered) 'repeat scans visibly bypass a cache that does not help'
    Start-GuiScan $retryCacheItem
    Wait-Scan $form
    Assert-Gui (-not $form.LastResult.CacheInfo.Contains('USN cache paused')) 'File Retry USN cache rechecks eligibility'
    Assert-CompletionTime $form $status
    Assert-Gui ($null -eq $map.SelectedTile -and -not $status.Items[0].Text.Contains('Scanning')) 'a completed rescan clears stale tile selection and progress'

    $partial = $form.LastResult
    $partial.Root.IssueCount = 5
    $partial.IssueCount = 5
    $completed = [ComponentModel.RunWorkerCompletedEventArgs]::new($partial, $null, $false)
    $form.GetType().GetMethod('ScanCompleted', $flags).Invoke($form, @($null, $completed))
    Assert-SelectionStatus $status $partial.Root 425 $false
    Assert-Gui ($status.Items[0].Text.Contains('5 skipped/errors') -and $status.Items[0].Text.Contains('Partial scan')) 'partial results show both selected-folder details and the warning'
    Assert-CompletionTime $form $status
    Assert-StatusText $status 'Selection details and a partial-scan warning'

    $cancelClose = [Windows.Forms.FormClosingEventHandler]{ param($sourceForm, $closingEvent) $closingEvent.Cancel = $true }
    $form.add_FormClosing($cancelClose)
    $exitItem.PerformClick()
    Assert-Gui (-not $form.IsDisposed -and $form.Visible) 'File Exit honors a cancelled FormClosing event'
    $form.remove_FormClosing($cancelClose)

    Start-GuiScan $scan
    Assert-Gui ($exitItem.Enabled) 'File Exit remains available during a scan'
    $exitItem.PerformClick()
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while ($form.IsScanning() -and [DateTime]::UtcNow -lt $deadline) {
        [Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    Assert-Gui ($form.IsDisposed -and -not $form.IsScanning()) 'File Exit cancels a running scan and closes cleanly'
    Assert-Gui ($folderMenu.IsDisposed) 'closing the window disposes the context menu'
    Assert-Gui ($mainMenu.IsDisposed -and $exitItem.IsDisposed) 'closing the window disposes the main menu and its commands'

    $shortcutForm = [FolderMap.MainForm]::new()
    $shortcutForm.CacheDirectory = $cacheFixture
    $shortcutForm.ShowInTaskbar = $false
    $shortcutForm.Show()
    [Windows.Forms.Application]::DoEvents()
    $emptyMap = $shortcutForm.Controls.Find('treemap', $true)[0]
    $shortcutForm.MainMenuStrip.Items[2].DropDownItems[1].PerformClick()
    $shortcutForm.MainMenuStrip.Items[1].DropDownItems[0].DropDownItems[4].PerformClick()
    Assert-Gui ($null -eq $emptyMap.Root -and [int]$emptyMap.Algorithm -eq 1 -and
        [int]$emptyMap.ColorScheme -eq 4) 'display preferences can be chosen before scanning a folder'
    $message = [Windows.Forms.Message]::Create($shortcutForm.Handle, 0x0104,
        [IntPtr]::new([int][Windows.Forms.Keys]::F4), [IntPtr]::Zero)
    $arguments = [object[]]@($message, $exitKeys)
    $handled = $shortcutForm.GetType().GetMethod('ProcessCmdKey', $flags).Invoke($shortcutForm, $arguments)
    Assert-Gui ($handled -and $shortcutForm.IsDisposed) 'Alt+F4 closes an idle window through the standard menu shortcut'
} catch {
    Write-Host "GUI failure: $($_.Exception.ToString())"
    Write-Host $_.ScriptStackTrace
    throw
} finally {
    if ($null -ne $bitmap) { $bitmap.Dispose() }
    if ($null -ne $form) { $form.Dispose() }
    if ($null -ne $shortcutForm) { $shortcutForm.Dispose() }
    [Threading.SynchronizationContext]::SetSynchronizationContext($originalContext)
    if ($null -ne $uiContext) { $uiContext.Dispose() }
    [Windows.Forms.Control]::CheckForIllegalCrossThreadCalls = $originalThreadChecks
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
    if ([IO.Directory]::Exists($cacheFixture)) { [IO.Directory]::Delete($cacheFixture, $true) }
}
Write-Host "GUI tests: $passed passed, 0 failed."
