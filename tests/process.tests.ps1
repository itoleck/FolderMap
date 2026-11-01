[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$passed = 0
$skipped = 0
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-process-' + [Guid]::NewGuid().ToString('N'))
$process = $null

function Assert-Process([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Wait-RootBytes([long]$Bytes) {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    $condition = [Windows.Automation.PropertyCondition]::new(
        [Windows.Automation.AutomationElement]::ControlTypeProperty,
        [Windows.Automation.ControlType]::Text)
    do {
        $process.Refresh()
        if ($process.HasExited) { throw "FolderMap exited unexpectedly: $($process.ExitCode)" }
        if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
            $window = [Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
            $labels = $window.FindAll([Windows.Automation.TreeScope]::Descendants, $condition)
            foreach ($label in $labels) {
                if ($label.Current.Name.StartsWith("$Bytes bytes (")) { return $window }
            }
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $deadline)
    $observed = @()
    if ($null -ne $window) {
        $observed = @($window.FindAll([Windows.Automation.TreeScope]::Descendants,
            [Windows.Automation.Condition]::TrueCondition) | ForEach-Object {
                "$($_.Current.ControlType.ProgrammaticName): $($_.Current.Name)"
            })
    }
    throw "The native executable did not show the expected $Bytes-byte root. Observed UI: $($observed -join '; ')"
}

try {
    [void][IO.Directory]::CreateDirectory((Join-Path $fixture 'data'))
    [void][IO.Directory]::CreateDirectory((Join-Path $fixture 'empty'))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'own.bin'), [byte[]]::new(11))
    [IO.File]::WriteAllBytes((Join-Path $fixture 'data\child.bin'), [byte[]]::new(64))
    $process = Start-Process -FilePath ((Resolve-Path -LiteralPath $AssemblyPath).Path) `
        -ArgumentList ('"' + $fixture + '"') -PassThru
    Assert-Process ($process.WaitForInputIdle(15000)) 'the compiled executable starts its native message loop'
    $window = Wait-RootBytes 75
    Assert-Process ($process.Responding -and $window.Current.Name.Contains('x64')) 'the actual x64 application is responsive'
    Assert-Process ($null -ne $window) 'command-line startup scans the requested path and displays 75 bytes'

    $scanCondition = [Windows.Automation.PropertyCondition]::new(
        [Windows.Automation.AutomationElement]::NameProperty, 'Scan')
    $scanButton = $window.FindFirst([Windows.Automation.TreeScope]::Descendants, $scanCondition)
    Assert-Process ($null -ne $scanButton -and $scanButton.Current.IsEnabled) 'the native Scan button is accessible and enabled'
    $invoke = $null
    if ($scanButton.TryGetCurrentPattern([Windows.Automation.InvokePattern]::Pattern, [ref]$invoke)) {
        [IO.File]::WriteAllBytes((Join-Path $fixture 'own.bin'), [byte[]]::new(36))
        $invoke.Invoke()
        $window = Wait-RootBytes 100
        Assert-Process ($null -ne $window) 'a real UI Automation button click refreshes the native window to 100 bytes'
    } else {
        Write-Host 'SKIP: This desktop exposes the native Scan button without UI Automation InvokePattern. In-process button/rescan checks run in gui.tests.ps1.'
        $skipped++
    }
    Assert-Process ($process.CloseMainWindow()) 'the compiled application accepts a normal close request'
    Assert-Process ($process.WaitForExit(15000) -and $process.ExitCode -eq 0) 'the entry point exits cleanly with code zero'
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) {
            [void]$process.CloseMainWindow()
            if (-not $process.WaitForExit(5000)) {
                Stop-Process -Id $process.Id -Force
                $process.WaitForExit()
            }
        }
        $process.Dispose()
    }
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
}
Write-Host "Native executable tests: $passed passed, 0 failed, $skipped skipped."
