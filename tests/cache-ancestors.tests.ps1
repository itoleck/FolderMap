param([string]$AssemblyPath)
$ErrorActionPreference = 'Stop'
if (-not $AssemblyPath) { $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe' }
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$passed = 0
function Assert-Ancestor([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}
$snapshot = [FolderMap.CacheSnapshot]::new()
$snapshot.RootPath = 'C:\ancestor-policy'
$snapshot.RootFileId = 100
$root = [FolderMap.CacheDirectory]::new()
$root.Name = 'ancestor-policy'
$root.FileId = 100
$snapshot.Directories.Add($root)
$child = [FolderMap.CacheDirectory]::new()
$child.Name = 'child'; $child.ParentIndex = 0; $child.FileId = 200
$child.LinkedFiles.Add(500)
$snapshot.Directories.Add($child)
$ancestors = [Collections.Generic.Dictionary[uint64,bool]]::new()
$ancestors.Add(50, $true)
function New-PolicyChange([uint64]$FileId, [uint64]$ParentId, [uint32]$Attributes = 0) {
    $change = [FolderMap.UsnChange]::new()
    $change.FileId = $FileId; $change.ParentId = $ParentId
    $change.Attributes = $Attributes; $change.Reason = 0x800
    return $change
}
$plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
$plan.Observe((New-PolicyChange 900 901))
Assert-Ancestor (-not [string]::IsNullOrEmpty($plan.FullScanReason)) 'unknown ancestry keeps the conservative security fallback'
$plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
$plan.SetAncestors($ancestors)
$plan.Observe((New-PolicyChange 900 901))
Assert-Ancestor ([string]::IsNullOrEmpty($plan.FullScanReason) -and $plan.DirtyIds.Count -eq 0) 'unrelated file security changes do not invalidate a known tree'
foreach ($fileId in @([uint64]50, [uint64]100, [uint64]200)) {
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.SetAncestors($ancestors)
    $plan.Observe((New-PolicyChange $fileId 999 16))
    Assert-Ancestor (-not [string]::IsNullOrEmpty($plan.FullScanReason)) 'security changes on ancestors or known directories force a baseline'
}
$plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
$plan.SetAncestors($ancestors)
$plan.Observe((New-PolicyChange 300 200))
Assert-Ancestor ([string]::IsNullOrEmpty($plan.FullScanReason) -and $plan.DirtyIds.ContainsKey(200)) 'file security changes refresh their containing directory'
$plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
$plan.SetAncestors($ancestors)
$plan.Observe((New-PolicyChange 300 200 16))
Assert-Ancestor (-not [string]::IsNullOrEmpty($plan.FullScanReason)) 'security changes on newly introduced in-tree directories force a baseline'
$plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
$plan.SetAncestors($ancestors)
$plan.Observe((New-PolicyChange 500 999))
Assert-Ancestor ($plan.DirtyIds.ContainsKey(200)) 'hard-link permission changes refresh in-tree aliases'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('FolderMap-ancestor-' + [Guid]::NewGuid().ToString('N'))
try {
    [void][IO.Directory]::CreateDirectory("$fixture\root")
    $serial = [FolderMap.NtfsJournal]::GetIdentity("$fixture\root").VolumeSerial
    $actual = [FolderMap.CacheAncestors]::new("$fixture\root", $serial, $null)
    $parentId = [FolderMap.NtfsJournal]::GetIdentity($fixture).FileId
    Assert-Ancestor ($null -ne $actual.Ids -and $actual.Ids.ContainsKey($parentId)) 'native ancestry includes the direct parent'
    $again = [FolderMap.CacheAncestors]::new("$fixture\root", $serial, $null)
    Assert-Ancestor ($actual.Fingerprint -ceq $again.Fingerprint) 'unchanged ancestor identities produce a stable fingerprint'
    $unknown = [FolderMap.CacheAncestors]::new("$fixture\root", ($serial -bxor [uint32]1), $null)
    Assert-Ancestor ($null -eq $unknown.Ids -and $unknown.Fingerprint -eq 'unknown') 'uncertain backing-volume ancestry fails closed'
} finally { if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) } }
Write-Host "Cache ancestor tests: $passed passed, 0 failed."
