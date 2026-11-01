[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-refresh-' + [Guid]::NewGuid().ToString('N'))
$outside = $fixture + '-outside'
$cachePath = $fixture + '.fmc'
$passed = 0
$skipped = 0
$nextUsn = 101

function Assert-Refresh([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function New-RefreshSnapshot {
    $rootIdentity = [FolderMap.NtfsJournal]::GetIdentity($script:fixture)
    $recorder = [FolderMap.CacheRecorder]::new($rootIdentity.VolumeSerial)
    $scan = [FolderMap.Scanner]::ScanObserved($script:fixture, $null, $recorder)
    $captured = [FolderMap.CacheRefresh]::Capture($scan, $recorder, $null)
    $snapshot = $captured.Snapshot
    $snapshot.VolumeName = '\\?\Volume{11111111-2222-3333-4444-555555555555}\'
    $snapshot.VolumeSerial = $rootIdentity.VolumeSerial
    $snapshot.RootFileId = $rootIdentity.FileId
    $snapshot.JournalId = 1
    $snapshot.Checkpoint = 100
    $snapshot.SavedUtcTicks = [DateTime]::UtcNow.Ticks
    $snapshot.AccessContext = 'cache-refresh-test'
    Assert-Refresh ($captured.MetadataFailures -eq 0) 'native identities were captured for the test tree'
    return $snapshot
}

function New-RefreshChange([uint64]$FileId, [uint64]$ParentId, [uint32]$Reason, [uint32]$Attributes = 0) {
    $change = [FolderMap.UsnChange]::new()
    $change.FileId = $FileId
    $change.ParentId = $ParentId
    $change.Reason = $Reason
    $change.Attributes = $Attributes
    $change.Usn = $script:nextUsn
    $script:nextUsn += 8
    return $change
}

function Get-RefreshSignature($Root) {
    $nodes = [Collections.Generic.Stack[object]]::new()
    $rows = [Collections.Generic.List[string]]::new()
    $nodes.Push($Root)
    while ($nodes.Count -gt 0) {
        $node = $nodes.Pop()
        $rows.Add("$($node.FullPath)|$($node.DirectBytes)|$($node.TotalBytes)|$($node.DirectFiles)|$($node.TotalFiles)|$($node.FolderCount)|$($node.IssueCount)")
        foreach ($child in $node.Children) {
            Assert-Refresh ([object]::ReferenceEquals($child.Parent, $node)) 'reconstructed child points to its new parent'
            $nodes.Push($child)
        }
    }
    $rows.Sort([StringComparer]::Ordinal)
    return [string]::Join("`n", $rows)
}

function Assert-Equivalent($Result) {
    $full = [FolderMap.Scanner]::Scan($script:fixture, $null)
    Assert-Refresh ((Get-RefreshSignature $Result.Root) -ceq (Get-RefreshSignature $full.Root)) 'incremental sizes and structure match a fresh full scan'
}

function Apply-Refresh($Snapshot, [object[]]$Changes) {
    $plan = [FolderMap.CacheDeltaPlan]::new($Snapshot)
    foreach ($change in $Changes) { $plan.Observe($change) }
    Assert-Refresh ([string]::IsNullOrEmpty($plan.FullScanReason)) 'the fixture changes permit directory-level refresh'
    $updated = [FolderMap.CacheRefresh]::Apply($Snapshot, $plan, $null)
    Assert-Equivalent $updated.Result
    return $updated
}

try {
    foreach ($path in @($fixture, "$fixture\change", "$fixture\stable\deep", "$fixture\empty", $outside)) {
        [void][IO.Directory]::CreateDirectory($path)
    }
    [IO.File]::WriteAllBytes("$fixture\own.bin", [byte[]]::new(10))
    [IO.File]::WriteAllBytes("$fixture\change\log.bin", [byte[]]::new(20))
    [IO.File]::WriteAllBytes("$fixture\stable\deep\data.bin", [byte[]]::new(30))
    $snapshot = New-RefreshSnapshot
    $originalSignature = Get-RefreshSignature ([FolderMap.CacheTree]::ToResult($snapshot, $null).Root)
    $unchanged = Apply-Refresh $snapshot @()
    Assert-Refresh ($unchanged.RefreshedDirectories -eq 0 -and $unchanged.ReusedDirectories -eq 5) 'an unchanged tree reuses every directory without disk enumeration'

    $changeId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\change").FileId
    $fileId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\change\log.bin").FileId
    [IO.File]::WriteAllBytes("$fixture\change\log.bin", [byte[]]::new(35))
    $updated = Apply-Refresh $snapshot @((New-RefreshChange $fileId $changeId 2147483650))
    Assert-Refresh ($updated.RefreshedDirectories -eq 1 -and $updated.ReusedDirectories -eq 4) 'one changed file refreshes only its containing directory'
    Assert-Refresh ((Get-RefreshSignature ([FolderMap.CacheTree]::ToResult($snapshot, $null).Root)) -ceq $originalSignature) 'refresh does not mutate the previous snapshot'
    $snapshot = $updated.Snapshot

    $ownId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\own.bin").FileId
    [IO.File]::WriteAllBytes("$fixture\own.bin", [byte[]]::new(12))
    $updated = Apply-Refresh $snapshot @((New-RefreshChange $ownId $snapshot.RootFileId 2147483650))
    Assert-Refresh ($updated.RefreshedDirectories -eq 1 -and $updated.ReusedDirectories -eq 4) 'a root-level file change does not rescan unchanged child subtrees'
    $snapshot = $updated.Snapshot

    [void][IO.Directory]::CreateDirectory("$fixture\change\new\deep")
    [IO.File]::WriteAllBytes("$fixture\change\new\deep\added.bin", [byte[]]::new(9))
    $newId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\change\new").FileId
    $updated = Apply-Refresh $snapshot @((New-RefreshChange $newId $changeId 2147483904 16))
    Assert-Refresh ($updated.RefreshedDirectories -eq 3 -and $updated.ReusedDirectories -eq 4) 'new directory subtrees are scanned while unrelated directories are reused'
    $snapshot = $updated.Snapshot

    [IO.File]::Delete("$fixture\change\log.bin")
    $updated = Apply-Refresh $snapshot @((New-RefreshChange $fileId $changeId 2147484160))
    $snapshot = $updated.Snapshot
    [IO.Directory]::Move("$fixture\change\new", "$fixture\change\renamed")
    $updated = Apply-Refresh $snapshot @(
        (New-RefreshChange $newId $changeId 4096 16),
        (New-RefreshChange $newId $changeId 2147491840 16)
    )
    Assert-Refresh (([FolderMap.CacheTree]::Paths($updated.Snapshot) -join '|').Contains('\renamed\deep')) 'renamed descendants receive updated full paths'
    $snapshot = $updated.Snapshot

    [IO.Directory]::Move("$fixture\change\renamed", "$outside\moved")
    $outsideId = [FolderMap.NtfsJournal]::GetIdentity($outside).FileId
    $updated = Apply-Refresh $snapshot @(
        (New-RefreshChange $newId $changeId 4096 16),
        (New-RefreshChange $newId $outsideId 2147491840 16)
    )
    $snapshot = $updated.Snapshot
    [IO.Directory]::Move("$outside\moved", "$fixture\change\returned")
    $updated = Apply-Refresh $snapshot @((New-RefreshChange $newId $changeId 2147491840 16))
    $snapshot = $updated.Snapshot

    $emptyId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\empty").FileId
    [IO.Directory]::Delete("$fixture\empty")
    [void][IO.Directory]::CreateDirectory("$fixture\empty")
    [IO.File]::WriteAllBytes("$fixture\empty\replacement.bin", [byte[]]::new(4))
    $replacementId = [FolderMap.NtfsJournal]::GetIdentity("$fixture\empty").FileId
    $updated = Apply-Refresh $snapshot @(
        (New-RefreshChange $emptyId $snapshot.RootFileId 2147484160 16),
        (New-RefreshChange $replacementId $snapshot.RootFileId 2147483904 16)
    )
    $snapshot = $updated.Snapshot

    $snapshot.Directories[0].Retry = $true
    $recovered = Apply-Refresh $snapshot @()
    Assert-Refresh (-not $recovered.Snapshot.Directories[0].Retry) 'retryable metadata is refreshed even without a journal event'
    $snapshot = $recovered.Snapshot
    $snapshot.SavedUtcTicks = [DateTime]::UtcNow.Ticks
    [FolderMap.CacheStore]::Save($cachePath, $snapshot, $null)
    $loaded = [FolderMap.CacheStore]::Load($cachePath, $null)
    $afterRestart = Apply-Refresh $loaded @()
    Assert-Refresh ($afterRestart.RefreshedDirectories -eq 0) 'a persisted snapshot can be reused after reloading it'

    $linked = $false
    try {
        [void](New-Item -ItemType HardLink -Path "$outside\alias.bin" -Target "$fixture\own.bin")
        $linked = $true
    } catch {
        Write-Host "SKIP: Hardlink fixture could not be created: $($_.Exception.Message)"
        $skipped++
    }
    if ($linked) {
        $snapshot = New-RefreshSnapshot
        [IO.File]::WriteAllBytes("$outside\alias.bin", [byte[]]::new(47))
        $updated = Apply-Refresh $snapshot @((New-RefreshChange $ownId $outsideId 2147483650))
        Assert-Refresh ($updated.Result.Root.DirectBytes -eq 47 -and $updated.RefreshedDirectories -eq 1) 'writes through an out-of-root hardlink refresh the cached in-root directory'
    }

    $worker = [ComponentModel.BackgroundWorker]::new()
    try {
        $worker.WorkerSupportsCancellation = $true
        $worker.CancelAsync()
        $caught = $null
        try { [void][FolderMap.CacheRefresh]::Apply($snapshot, [FolderMap.CacheDeltaPlan]::new($snapshot), $worker) }
        catch { $caught = $_.Exception.GetBaseException() }
        Assert-Refresh ($caught -is [OperationCanceledException]) 'incremental refresh honors cancellation'
    } finally { $worker.Dispose() }
} finally {
    if ([IO.File]::Exists($cachePath)) { [IO.File]::Delete($cachePath) }
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
    if ([IO.Directory]::Exists($outside)) { [IO.Directory]::Delete($outside, $true) }
}
Write-Host "Cache refresh tests: $passed passed, $skipped skipped."
