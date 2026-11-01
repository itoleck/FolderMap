[CmdletBinding()]
param(
    [string]$AssemblyPath,
    [switch]$Probe,
    [string]$RootPath,
    [string]$CacheDirectory,
    [string]$ResultPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$AssemblyPath = (Resolve-Path -LiteralPath $AssemblyPath).Path
[void][Reflection.Assembly]::LoadFrom($AssemblyPath)
[AppContext]::SetSwitch('Switch.System.IO.UseLegacyPathHandling', $false)
[AppContext]::SetSwitch('Switch.System.IO.BlockLongPaths', $false)

if ($Probe) {
    if (-not $RootPath -or -not $CacheDirectory -or -not $ResultPath) { throw 'Probe paths are required.' }
    $result = [FolderMap.CachedScanner]::ScanWithDirectory($RootPath, $null, $false, $CacheDirectory)
    $second = [FolderMap.CachedScanner]::ScanWithDirectory($RootPath, $null, $false, $CacheDirectory)
    @{
        Bytes = $result.Root.TotalBytes
        Refreshed = $result.RefreshedDirectories
        Reused = $result.ReusedDirectories
        Info = $result.CacheInfo
        NextReused = $second.ReusedDirectories
        NextRefreshed = $second.RefreshedDirectories
        NextInfo = $second.CacheInfo
    } | ConvertTo-Json | Set-Content -LiteralPath $ResultPath -Encoding UTF8
    exit 0
}
if (-not [FolderMap.Elevation]::IsAdministrator()) {
    throw 'Live cache verification requires an administrator PowerShell session. It never enables a journal.'
}
[void][FolderMap.NtfsJournal]::SecurityContext()
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-live-cache-' + [Guid]::NewGuid().ToString('N'))
$cacheDirectoryPath = $fixture + '-cache'
$probeResult = $fixture + '.json'
$passed = 0

function Assert-Live([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Scan-Live([bool]$Full = $false) {
    return [FolderMap.CachedScanner]::ScanWithDirectory($script:fixture, $null, $Full, $script:cacheDirectoryPath)
}

function Fresh-Total {
    return [FolderMap.Scanner]::Scan($script:fixture, $null).Root.TotalBytes
}

try {
    [void][IO.Directory]::CreateDirectory("$fixture\changed")
    [IO.File]::WriteAllBytes("$fixture\own.bin", [byte[]]::new(10))
    [IO.File]::WriteAllBytes("$fixture\changed\log.bin", [byte[]]::new(20))
    for ($i = 0; $i -lt 100; $i++) {
        $directory = Join-Path $fixture ("stable-{0:D3}" -f $i)
        [void][IO.Directory]::CreateDirectory($directory)
        for ($j = 0; $j -lt 3; $j++) {
            [IO.File]::WriteAllBytes((Join-Path $directory "data-$j.bin"), [byte[]]::new(128))
        }
    }
    $session = [FolderMap.NtfsJournal]::Open($fixture)
    try {
        $head = $session.Query()
        Assert-Live ($head.NextUsn -ge $head.FirstUsn) 'the real NTFS journal can be queried read-only'
    } finally { $session.Dispose() }

    $clock = [Diagnostics.Stopwatch]::StartNew()
    $baseline = Scan-Live $true
    $clock.Stop()
    $fullMilliseconds = $clock.ElapsedMilliseconds
    Assert-Live ($baseline.Root.TotalBytes -eq 38430) 'the baseline has the expected total'
    Assert-Live ($baseline.CacheInfo.Contains('Snapshot saved.')) "a usable baseline was persisted: $($baseline.CacheInfo)"
    $cachePath = [FolderMap.CacheStore]::GetPath($cacheDirectoryPath, $fixture, [FolderMap.CachedScanner]::CacheFileContext())
    Assert-Live ([IO.File]::Exists($cachePath)) 'the cache survives beyond the scan result object'

    $clock.Restart()
    $unchanged = Scan-Live
    $clock.Stop()
    $cachedMilliseconds = $clock.ElapsedMilliseconds
    Assert-Live ($unchanged.Root.TotalBytes -eq 38430) 'journal refresh preserves the unchanged total'
    Assert-Live ($unchanged.RefreshedDirectories -eq 0 -and $unchanged.ReusedDirectories -eq 102) "unchanged directories are reused: $($unchanged.CacheInfo)"
    Assert-Live ($unchanged.CacheInfo.Contains('Cached / last-observed')) 'the live-writer limitation is visible'

    $process = Start-Process -FilePath "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'),
            '-Probe', '-AssemblyPath', ('"' + $AssemblyPath + '"'),
            '-RootPath', ('"' + $fixture + '"'), '-CacheDirectory', ('"' + $cacheDirectoryPath + '"'),
            '-ResultPath', ('"' + $probeResult + '"')) -PassThru -Wait
    try {
        Assert-Live ($process.ExitCode -eq 0 -and [IO.File]::Exists($probeResult)) 'an independent process can reload the snapshot'
    } finally { $process.Dispose() }
    $probeData = Get-Content -LiteralPath $probeResult -Raw | ConvertFrom-Json
    Assert-Live ($probeData.Bytes -eq 38430) "a new process revalidates the persisted snapshot: $($probeData.Info)"
    Assert-Live ($probeData.NextReused -eq 102 -and $probeData.NextRefreshed -eq 0) "subsequent scans in the new process reuse its verified baseline: $($probeData.NextInfo)"
    [void](Scan-Live)

    [IO.File]::WriteAllBytes("$fixture\changed\log.bin", [byte[]]::new(57))
    $changed = Scan-Live
    Assert-Live ($changed.Root.TotalBytes -eq (Fresh-Total)) 'a real USN size change matches full-scan totals'
    Assert-Live ($changed.RefreshedDirectories -eq 1 -and $changed.ReusedDirectories -eq 101) "only the changed file's directory is rescanned: $($changed.CacheInfo)"

    [void][IO.Directory]::CreateDirectory("$fixture\changed\new\deep")
    [IO.File]::WriteAllBytes("$fixture\changed\new\deep\added.bin", [byte[]]::new(19))
    $created = Scan-Live
    Assert-Live ($created.Root.TotalBytes -eq (Fresh-Total)) 'journal-reported new subtrees are discovered'
    [IO.Directory]::Move("$fixture\changed\new", "$fixture\changed\renamed")
    $renamed = Scan-Live
    Assert-Live ($renamed.Root.TotalBytes -eq (Fresh-Total)) 'journal-reported renames preserve totals'
    [IO.File]::Delete("$fixture\changed\log.bin")
    $deleted = Scan-Live
    Assert-Live ($deleted.Root.TotalBytes -eq (Fresh-Total)) 'journal-reported deletes remove file bytes'

    $snapshot = [FolderMap.CacheStore]::Load($cachePath, $null)
    $snapshot.JournalId = $snapshot.JournalId -bxor [uint64]1
    [FolderMap.CacheStore]::Save($cachePath, $snapshot, $null)
    $reset = Scan-Live
    Assert-Live ($reset.ReusedDirectories -eq 0 -and $reset.Root.TotalBytes -eq (Fresh-Total)) 'a mismatched journal ID rebuilds instead of trusting stale data'

    $stream = [IO.File]::Open($cachePath, [IO.FileMode]::Append, [IO.FileAccess]::Write)
    try { $stream.WriteByte(1) } finally { $stream.Dispose() }
    $corrupt = Scan-Live
    Assert-Live ($corrupt.ReusedDirectories -eq 0 -and $corrupt.Root.TotalBytes -eq (Fresh-Total)) 'a corrupt cache triggers a fresh baseline'
    Assert-Live ($corrupt.CacheInfo.Contains('Snapshot saved.')) 'the corrupt snapshot is replaced with valid data'

    $prior = [IO.File]::ReadAllBytes($cachePath)
    $worker = [ComponentModel.BackgroundWorker]::new()
    try {
        $worker.WorkerSupportsCancellation = $true
        $worker.CancelAsync()
        $caught = $null
        try { [void][FolderMap.CachedScanner]::ScanWithDirectory($fixture, $worker, $false, $cacheDirectoryPath) }
        catch { $caught = $_.Exception.GetBaseException() }
        Assert-Live ($caught -is [OperationCanceledException]) 'cancellation propagates rather than accepting cached results'
    } finally { $worker.Dispose() }
    Assert-Live ([Convert]::ToBase64String($prior) -ceq [Convert]::ToBase64String([IO.File]::ReadAllBytes($cachePath))) 'cancelled work does not advance the persisted checkpoint'
    Write-Host "Live cache performance fixture: full=$fullMilliseconds ms, unchanged USN refresh=$cachedMilliseconds ms; 102 directories, 302 files."
    Write-Host "Live cache tests: $passed passed, 0 failed."
} finally {
    if ([IO.File]::Exists($probeResult)) { [IO.File]::Delete($probeResult) }
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
    if ([IO.Directory]::Exists($cacheDirectoryPath)) { [IO.Directory]::Delete($cacheDirectoryPath, $true) }
}
