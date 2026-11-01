[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$matches = $assembly.GetType('FolderMap.CachedScanner').GetMethod('Matches', [Reflection.BindingFlags]'Static,NonPublic')
$snapshot = [FolderMap.CacheSnapshot]::new()
$snapshot.RootPath = 'C:\cache-validation'
$snapshot.VolumeName = '\\?\Volume{11111111-2222-3333-4444-555555555555}\'
$snapshot.AccessContext = 'test-user|administrator=False|groups=test'
$snapshot.VolumeSerial = 42
$snapshot.RootFileId = [uint64]::MaxValue - 7
$snapshot.JournalId = [uint64]::MaxValue - 3
$snapshot.Checkpoint = 150
$session = [Runtime.Serialization.FormatterServices]::GetUninitializedObject($assembly.GetType('FolderMap.JournalSession'))
$session.RootPath = $snapshot.RootPath
$session.VolumeName = $snapshot.VolumeName
$session.VolumeSerial = $snapshot.VolumeSerial
$session.RootFileId = $snapshot.RootFileId
$head = [Runtime.Serialization.FormatterServices]::GetUninitializedObject($assembly.GetType('FolderMap.UsnCheckpoint'))
$head.JournalId = $snapshot.JournalId
$head.FirstUsn = 100
$head.LowestValidUsn = 110
$head.NextUsn = 200
$passed = 0
$skipped = 0

function Assert-CacheMatch([bool]$Expected, [string]$Message) {
    $actual = $script:matches.Invoke($null, @($script:snapshot, $script:session, $script:head, $script:snapshot.AccessContext))
    if ($actual -ne $Expected) { throw "FAIL: $Message" }
    $script:passed++
}

Assert-CacheMatch $true 'matching root, access context, volume and journal permit reuse'
foreach ($field in @('RootPath', 'VolumeName')) {
    $old = $session.$field
    $session.$field = $old + '-changed'
    Assert-CacheMatch $false "changed $field invalidates the cache"
    $session.$field = $old
}
$session.VolumeSerial = 43
Assert-CacheMatch $false 'a replacement volume invalidates cached sizes'
$session.VolumeSerial = 42
$session.RootFileId--
Assert-CacheMatch $false 'a deleted and recreated root cannot reuse the old snapshot'
$session.RootFileId = $snapshot.RootFileId
$head.JournalId--
Assert-CacheMatch $false 'journal reset invalidates the cache'
$head.JournalId = $snapshot.JournalId
$snapshot.Checkpoint = 99
Assert-CacheMatch $false 'records evicted from the journal require a full scan'
$snapshot.Checkpoint = 105
Assert-CacheMatch $false 'a checkpoint below LowestValidUsn is rejected'
$snapshot.Checkpoint = 201
Assert-CacheMatch $false 'a checkpoint ahead of the current journal is rejected'
$snapshot.Checkpoint = 110
Assert-CacheMatch $true 'the lowest valid retained checkpoint is accepted'
$snapshot.Checkpoint = 200
Assert-CacheMatch $true 'an unchanged journal head is a valid checkpoint'
$actual = $matches.Invoke($null, @($snapshot, $session, $head, 'test-user|administrator=True|groups=test'))
if ($actual) { throw 'FAIL: elevated and non-elevated cache contexts must not be interchangeable' }
$passed++
$phaseUpdates = [Collections.Generic.List[object]]::new()
$phaseWorker = [ComponentModel.BackgroundWorker]::new()
try {
    $phaseWorker.WorkerReportsProgress = $true
    $phaseWorker.WorkerSupportsCancellation = $true
    $phaseWorker.add_ProgressChanged({ param($sourceWorker, $phaseEvent) $phaseUpdates.Add($phaseEvent.UserState) })
    $report = $assembly.GetType('FolderMap.CachedScanner').GetMethod('ReportPhase', [Reflection.BindingFlags]'Static,NonPublic')
    foreach ($mode in [Enum]::GetValues([FolderMap.ScanCacheMode])) {
        [void]$report.Invoke($null, [object[]]@($phaseWorker, $mode, 'phase detail'))
    }
    if ($phaseUpdates.Count -ne 3) { throw 'FAIL: all cache phases must be reported' }
    for ($index = 0; $index -lt 3; $index++) {
        if ($phaseUpdates[$index] -isnot [FolderMap.ScanProgressUpdate] -or
            [int]$phaseUpdates[$index].Mode -ne $index -or $phaseUpdates[$index].Detail -ne 'phase detail') {
            throw 'FAIL: cache mode and detail must travel together in typed progress updates'
        }
        $passed++
    }
    $phaseWorker.WorkerReportsProgress = $false
    [void]$report.Invoke($null, @($phaseWorker, [FolderMap.ScanCacheMode]::FullScan, 'disabled'))
    if ($phaseUpdates.Count -ne 3) { throw 'FAIL: disabled progress must not emit updates' }
    $passed++
    $phaseWorker.CancelAsync()
    $caught = $null
    try { [void]$report.Invoke($null, @($phaseWorker, [FolderMap.ScanCacheMode]::UsingCache, 'cancelled')) }
    catch { $caught = $_.Exception.GetBaseException() }
    if ($caught -isnot [OperationCanceledException]) { throw 'FAIL: cancelled scans must not emit cache-phase updates' }
    $passed++
} finally { $phaseWorker.Dispose() }
[string]$cacheProbe = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-cache-boundary-' + [Guid]::NewGuid().ToString('N') + '.fmc')
try {
    [IO.File]::WriteAllBytes($cacheProbe, [byte[]]@(1, 2, 3))
    $load = $assembly.GetType('FolderMap.CachedScanner').GetMethod('Load', [Reflection.BindingFlags]'Static,NonPublic')
    $arguments = [object[]]@($cacheProbe, $null, $null)
    $loaded = $load.Invoke($null, $arguments)
    if ($null -ne $loaded -or [string]::IsNullOrWhiteSpace($arguments[2])) {
        throw 'FAIL: malformed cache data must become an explained cache miss'
    }
    $passed++
    $save = $assembly.GetType('FolderMap.CachedScanner').GetMethod('Save', [Reflection.BindingFlags]'Static,NonPublic')
    $saveFailure = $save.Invoke($null, @($cacheProbe, $snapshot, $null))
    if ([string]::IsNullOrWhiteSpace($saveFailure)) { throw 'FAIL: invalid cache data must produce a cache-save explanation' }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($cacheProbe)) -cne 'AQID') {
        throw 'FAIL: failed cache validation must preserve the previous file'
    }
    $passed++
} finally {
    if ([IO.File]::Exists($cacheProbe)) { [IO.File]::Delete($cacheProbe) }
}
try {
    $context = [FolderMap.CachedScanner]::AccessContext()
    if ([string]::IsNullOrWhiteSpace($context) -or $context -cne [FolderMap.CachedScanner]::AccessContext()) {
        throw 'FAIL: current Windows access context must be explicit and stable'
    }
    $passed++
} catch {
    if ($_.Exception.GetBaseException() -isnot [Security.SecurityException]) { throw }
    Write-Host "SKIP: This token is deliberately ineligible for cache reuse: $($_.Exception.GetBaseException().Message)"
    $skipped++
}
Write-Host "Cached scanner identity tests: $passed passed, 0 failed, $skipped skipped."
