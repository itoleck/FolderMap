[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$passed = 0

function Assert-Elevation([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

$cases = @(
    @{ InputPath = 'C:\folder with spaces\subdir'; Quoted = '"C:\folder with spaces\subdir"' },
    @{ InputPath = 'C:\'; Quoted = '"C:\\"' },
    @{ InputPath = '\\server\share\'; Quoted = '"\\server\share"' },
    @{ InputPath = '"C:\folder with spaces\"'; Quoted = '"C:\folder with spaces"' },
    @{ InputPath = 'C:\folder & comma, value'; Quoted = '"C:\folder & comma, value"' }
)
foreach ($case in $cases) {
    $info = [FolderMap.Elevation]::CreateStartInfo($case.InputPath)
    Assert-Elevation ($info.FileName -eq $assembly.Location) 'restart targets this exact application, not a PATH lookup'
    Assert-Elevation ($info.UseShellExecute -and $info.Verb -eq 'runas') 'elevation uses the explicit Windows consent flow'
    Assert-Elevation ($info.Arguments -ceq $case.Quoted) "the directory is one quoted argument: input=[$($case.InputPath)], expected=[$($case.Quoted)], actual=[$($info.Arguments)]"
    Assert-Elevation ($info.WorkingDirectory -eq [IO.Path]::GetDirectoryName($assembly.Location)) 'restart uses the application directory'
}
foreach ($path in @($null, '', ' ')) {
    $info = [FolderMap.Elevation]::CreateStartInfo($path)
    Assert-Elevation ([string]::IsNullOrEmpty($info.Arguments)) 'an empty path restarts without requesting an automatic scan'
}
foreach ($path in @('C:\bad"argument', ("C:\bad" + [char]0 + 'argument'))) {
    $caught = $null
    try { [void][FolderMap.Elevation]::CreateStartInfo($path) } catch { $caught = $_.Exception.GetBaseException() }
    Assert-Elevation ($caught -is [ArgumentException]) 'invalid command-line path characters are rejected'
}
Assert-Elevation ([FolderMap.Elevation]::IsAdministrator() -is [bool]) 'administrator detection returns a boolean'
Write-Host "Elevation tests: $passed passed, 0 failed. No elevation prompt was launched."
