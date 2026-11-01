param([string]$AssemblyPath)
$ErrorActionPreference = 'Stop'
if (-not $AssemblyPath) { $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe' }
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$passed = 0
function Assert-Policy([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-policy-' + [Guid]::NewGuid().ToString('N'))
$cacheDirectory = $fixture + '-cache'
$key = [FolderMap.CachePolicy]::Key($fixture, $cacheDirectory)
$otherKey = [FolderMap.CachePolicy]::Key($fixture + '-other', $cacheDirectory)
try {
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'new paths start with cache eligibility checking enabled'
    for ($i = 0; $i -lt 4; $i++) {
        [FolderMap.CachePolicy]::RecordOutcome($key, $false, 0, 'Cold baseline')
    }
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'ordinary cold baselines do not penalize cache eligibility'
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 0, 'Unknown journal reason')
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'one unsuccessful cache attempt does not disable the path'
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 0, 'Unknown journal reason again')
    Assert-Policy ([FolderMap.CachePolicy]::BypassReason($key).Contains('Unknown journal reason again')) 'two unsuccessful attempts disable the path with an explanation'
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($otherKey)) 'one path does not disable another path'
    [FolderMap.CachePolicy]::Reset($key)
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'explicit retry restores eligibility checking'
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 0, 'first failure')
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 8, 'Eight directories reused')
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 0, 'later failure')
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'a useful cache refresh resets the consecutive-failure count'
    [FolderMap.CachePolicy]::RecordOutcome($key, $true, 0, 'later failure again')

    [void][IO.Directory]::CreateDirectory("$fixture\child")
    [IO.File]::WriteAllBytes("$fixture\own.bin", [byte[]]::new(11))
    [IO.File]::WriteAllBytes("$fixture\child\child.bin", [byte[]]::new(17))
    $result = [FolderMap.CachedScanner]::ScanWithDirectory($fixture, $null, $false, $cacheDirectory)
    Assert-Policy ($result.Root.TotalBytes -eq 28 -and $result.RefreshedDirectories -eq 2) 'a bypassed path still gets correct fresh sizes'
    Assert-Policy (-not $result.CacheConsidered -and $result.CacheInfo.Contains('USN cache paused')) 'bypass avoids a new journal/cache attempt'
    Assert-Policy (-not [IO.Directory]::Exists($cacheDirectory)) 'bypass performs no cache-file creation'
    $forced = [FolderMap.CachedScanner]::ScanWithDirectory($fixture, $null, $true, $cacheDirectory)
    Assert-Policy (-not $forced.CacheConsidered -and $forced.Root.TotalBytes -eq 28) 'forced full scans honor the adaptive bypass without cache overhead'
    [FolderMap.CachedScanner]::RetryCache($fixture, $cacheDirectory)
    Assert-Policy ($null -eq [FolderMap.CachePolicy]::BypassReason($key)) 'the scanner retry action resets the correct normalized path'
} finally {
    [FolderMap.CachePolicy]::Reset($key)
    [FolderMap.CachePolicy]::Reset($otherKey)
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
    if ([IO.Directory]::Exists($cacheDirectory)) { [IO.Directory]::Delete($cacheDirectory, $true) }
}
Write-Host "Cache policy tests: $passed passed, 0 failed."
