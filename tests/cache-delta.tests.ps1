param([string]$AssemblyPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 5 -or
    ($PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -ne 'Desktop')) {
    throw 'Run these tests with Windows PowerShell 5.x and .NET Framework.'
}
if (-not [Environment]::Is64BitProcess) {
    throw 'Run these tests in x64 Windows PowerShell.'
}
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$AssemblyPath = (Resolve-Path -LiteralPath $AssemblyPath).Path
$assembly = [Reflection.Assembly]::LoadFrom($AssemblyPath)
$script:passed = 0
$script:failed = 0
$script:assertions = 0
$script:prepared = 0
$closeBit = [uint32]2147483648
$clock = [Diagnostics.Stopwatch]::StartNew()

function Assert-True([bool]$Condition, [string]$Message) {
    $script:assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Equal($Actual, $Expected, [string]$Message) {
    Assert-True ([object]::Equals($Actual, $Expected)) (
        '{0}: expected [{1}], actual [{2}]' -f $Message, $Expected, $Actual)
}

function Assert-Text([string]$Actual, [string]$Expected, [string]$Message) {
    Assert-True ([string]::Equals($Actual, $Expected, [StringComparison]::Ordinal)) (
        '{0}: expected [{1}], actual [{2}]' -f $Message, $Expected, $Actual)
}

function Assert-Throws([scriptblock]$Action, [type]$ExceptionType) {
    try {
        & $Action
    }
    catch {
        $cause = $_.Exception
        while ($null -ne $cause.InnerException) { $cause = $cause.InnerException }
        Assert-True ($ExceptionType.IsInstanceOfType($cause)) (
            'Expected {0}, got {1}: {2}' -f $ExceptionType.FullName, $cause.GetType().FullName, $cause.Message)
        return
    }
    throw ('Expected {0}, but the call succeeded.' -f $ExceptionType.FullName)
}

function Invoke-Case([string]$Name, [scriptblock]$Body) {
    try {
        & $Body
        $script:passed++
    }
    catch {
        $script:failed++
        Write-Host ('FAIL: {0}' -f $Name) -ForegroundColor Red
        Write-Host ($_ | Out-String)
        Write-Host $_.ScriptStackTrace
    }
}

function Add-Directory([FolderMap.CacheSnapshot]$Snapshot, [int]$ParentIndex,
    [string]$Name, [uint64]$Id, [long]$Bytes = 0, [long]$Files = 0, [int]$Issues = 0) {
    $item = [FolderMap.CacheDirectory]::new()
    $item.ParentIndex = $ParentIndex
    $item.Name = $Name
    $item.FileId = $Id
    $item.DirectBytes = $Bytes
    $item.DirectFiles = $Files
    $item.DirectIssueCount = $Issues
    $Snapshot.Directories.Add($item)
    return $item
}

function New-Snapshot {
    $snapshot = [FolderMap.CacheSnapshot]::new()
    $snapshot.RootPath = 'C:\cache-root'
    $snapshot.VolumeName = 'synthetic-volume'
    $snapshot.AccessContext = 'synthetic-access'
    $snapshot.RootFileId = [uint64]1
    $snapshot.VolumeSerial = [uint32]123
    $snapshot.JournalId = [uint64]456
    $snapshot.Checkpoint = [long]789
    $snapshot.SavedUtcTicks = [long]987
    $null = Add-Directory $snapshot -1 'ignored-root-name' 1
    return $snapshot
}

function New-BranchSnapshot {
    $snapshot = New-Snapshot
    $null = Add-Directory $snapshot 0 'alpha' 2
    $null = Add-Directory $snapshot 0 'beta' 3
    $null = Add-Directory $snapshot 1 'nested' 4
    return $snapshot
}

function Copy-Snapshot([FolderMap.CacheSnapshot]$Source) {
    $copy = [FolderMap.CacheSnapshot]::new()
    foreach ($field in 'RootPath', 'VolumeName', 'AccessContext', 'RootFileId',
        'VolumeSerial', 'JournalId', 'Checkpoint', 'SavedUtcTicks') {
        $copy.$field = $Source.$field
    }
    foreach ($item in $Source.Directories) {
        $copy.Directories.Add([FolderMap.CacheTree]::CopyDirectory($item, $item.ParentIndex))
    }
    foreach ($pair in $Source.PendingWrites) {
        $copy.PendingWrites.Add([FolderMap.PendingWrite]::new($pair.FileId, $pair.ParentId))
    }
    return $copy
}

function New-Change([uint64]$FileId, [uint64]$ParentId, [uint32]$Reason, [uint32]$Attributes = 0) {
    $change = [FolderMap.UsnChange]::new()
    $change.FileId = $FileId
    $change.ParentId = $ParentId
    $change.Reason = $Reason
    $change.Attributes = $Attributes
    $change.Usn = [long]800
    return $change
}

function Assert-Dirty([FolderMap.CacheDeltaPlan]$Plan,
    [AllowEmptyCollection()][uint64[]]$Expected) {
    Assert-Equal $Plan.DirtyIds.Count $Expected.Count 'Dirty directory count'
    foreach ($id in $Expected) {
        Assert-True ($Plan.DirtyIds.ContainsKey($id) -and $Plan.DirtyIds[$id]) (
            'Directory {0} must be dirty' -f $id)
    }
}

function Get-PendingKey([FolderMap.CacheDeltaPlan]$Plan) {
    $pairs = $Plan.GetPendingWrites()
    $parts = foreach ($pair in $pairs) {
        '{0}:{1}' -f $pair.FileId.ToString([Globalization.CultureInfo]::InvariantCulture),
            $pair.ParentId.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    return ($parts -join ',')
}

function Get-SnapshotKey([FolderMap.CacheSnapshot]$Snapshot) {
    return (ConvertTo-Json -InputObject $Snapshot -Depth 8 -Compress)
}

Invoke-Case 'JIT every managed method and constructor without executing native operations' {
    $flags = [Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly'
    foreach ($type in $assembly.GetTypes()) {
        $methods = @($type.GetMethods($flags)) + @($type.GetConstructors($flags))
        foreach ($method in $methods) {
            if (-not $method.IsAbstract -and -not $method.ContainsGenericParameters -and
                $null -ne $method.GetMethodBody()) {
                [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
                $script:prepared++
            }
        }
    }
    Assert-True ($script:prepared -ge 20) 'Expected all cache helper methods to be prepared'
}

Invoke-Case 'Absolute lexical normalization and ordinal case-sensitive siblings' {
    $snapshot = New-Snapshot
    $snapshot.RootPath = 'c:/base/./work/../Root//'
    $null = Add-Directory $snapshot 0 'a' 2
    $null = Add-Directory $snapshot 0 'A' 3
    $null = Add-Directory $snapshot 1 '.git' 4
    $paths = [FolderMap.CacheTree]::Paths($snapshot)
    Assert-Text ($paths -join '|') 'C:\base\Root|C:\base\Root\a|C:\base\Root\A|C:\base\Root\a\.git' 'Normalized paths'
    Assert-Text $snapshot.RootPath 'c:/base/./work/../Root//' 'Root path remains unchanged'
    $paths[0] = 'changed'
    Assert-Text ([FolderMap.CacheTree]::Paths($snapshot)[0]) 'C:\base\Root' 'Paths are independent'
}

Invoke-Case 'Drive, UNC, and extended-length roots remain absolute' {
    $examples = @(
        @('C:\', 'C:\'),
        @('\\server\share', '\\server\share\'),
        @('\\server\share\one\..\Root\', '\\server\share\Root'),
        @('\\?\c:\Root\.', '\\?\C:\Root'),
        @('\\?\unc\server\share\Root\\', '\\?\UNC\server\share\Root')
    )
    foreach ($example in $examples) {
        $snapshot = New-Snapshot
        $snapshot.RootPath = $example[0]
        $null = Add-Directory $snapshot 0 'leaf' 2
        $paths = [FolderMap.CacheTree]::Paths($snapshot)
        Assert-Text $paths[0] $example[1] 'Normalized absolute root'
        Assert-Text $paths[1] ($example[1].TrimEnd('\') + '\leaf') 'Child separator'
    }
}

Invoke-Case 'Independent materialization, direct diagnostics, recursive totals, and parents' {
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[0].DirectBytes = 7
    $snapshot.Directories[0].DirectFiles = 1
    $snapshot.Directories[0].DirectIssueCount = 2
    $snapshot.Directories[0].Issues.Add('root-1')
    $snapshot.Directories[0].Issues.Add('root-2')
    $snapshot.Directories[1].DirectBytes = 4
    $snapshot.Directories[1].DirectFiles = 1
    $snapshot.Directories[1].DirectIssueCount = 3
    $snapshot.Directories[1].Issues.Add('alpha-1')
    $snapshot.Directories[2].DirectBytes = 10
    $snapshot.Directories[2].DirectFiles = 2
    $snapshot.Directories[3].DirectBytes = 6
    $snapshot.Directories[3].DirectFiles = 1
    $snapshot.Directories[3].DirectIssueCount = 1
    $snapshot.Directories[3].Issues.Add('leaf-1')
    $before = Get-SnapshotKey $snapshot
    $result = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    $root = $result.Root
    Assert-Equal $root.DirectBytes ([long]7) 'Root direct bytes'
    Assert-Equal $root.DirectFiles ([long]1) 'Root direct files'
    Assert-Equal $root.TotalBytes ([long]27) 'Recursive bytes'
    Assert-Equal $root.TotalFiles ([long]5) 'Recursive files'
    Assert-Equal $root.FolderCount ([long]3) 'Recursive directory count excludes the current node'
    Assert-Equal $root.IssueCount 6 'Recursive issue count from direct counts'
    Assert-Equal $result.IssueCount 6 'Result issue count'
    Assert-Text ($result.Issues -join '|') 'root-1|root-2|alpha-1|leaf-1' 'Direct diagnostics appear once'
    Assert-True ($null -eq $root.Parent) 'Root has no parent'
    $alpha = $root.Children[0]
    Assert-Text $alpha.Name 'alpha' 'Tied totals sorted by name'
    Assert-Equal $alpha.IssueCount 4 'Child recursive issues'
    Assert-Equal $alpha.DirectBytes ([long]4) 'Child direct bytes unchanged'
    Assert-True ([object]::ReferenceEquals($alpha.Parent, $root)) 'Child attaches to new root'
    Assert-True ([object]::ReferenceEquals($alpha.Children[0].Parent, $alpha)) 'Grandchild attaches to new parent'
    Assert-Text $alpha.Children[0].FullPath 'C:\cache-root\alpha\nested' 'Grandchild full path'
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Materialization never modifies snapshot'
    $other = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    Assert-True (-not [object]::ReferenceEquals($root, $other.Root)) 'Independent roots'
    Assert-True (-not [object]::ReferenceEquals($alpha, $other.Root.Children[0])) 'Independent descendants'
    $alpha.DirectBytes = 999
    $result.Issues.Clear()
    $root.Children.Clear()
    Assert-Equal $other.Root.Children[0].DirectBytes ([long]4) 'No cross-result node alias'
    Assert-Equal $other.Issues.Count 4 'No cross-result diagnostic alias'
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Result edits do not modify snapshot'
}

Invoke-Case 'Shared scanner sort is bytes descending then ordinal ignore-case then ordinal' {
    $snapshot = New-Snapshot
    $null = Add-Directory $snapshot 0 'z' 2 10
    $null = Add-Directory $snapshot 0 'a' 3 7
    $null = Add-Directory $snapshot 0 'A' 4 7
    $null = Add-Directory $snapshot 0 'b' 5 99
    $result = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    Assert-Text (($result.Root.Children | ForEach-Object { $_.Name }) -join ',') 'b,z,A,a' 'Deterministic child ordering'
}

Invoke-Case 'Diagnostics cap is global first 200 while all issues are counted' {
    $snapshot = New-Snapshot
    $snapshot.Directories[0].DirectIssueCount = 120
    for ($i = 0; $i -lt 120; $i++) { $snapshot.Directories[0].Issues.Add("root-$i") }
    $child = Add-Directory $snapshot 0 'child' 2 0 0 180
    for ($i = 0; $i -lt 180; $i++) { $child.Issues.Add("child-$i") }
    $result = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    Assert-Equal $result.Issues.Count 200 'Bounded global diagnostics'
    Assert-Equal $result.IssueCount 300 'Uncapped total issues'
    Assert-Equal $result.Root.IssueCount 300 'Uncapped root issues'
    Assert-Text $result.Issues[119] 'root-119' 'End of first direct diagnostic list'
    Assert-Text $result.Issues[120] 'child-0' 'Next directory diagnostics'
    Assert-Text $result.Issues[199] 'child-79' 'Global diagnostic boundary'
    Assert-Equal $child.Issues.Count 180 'Source diagnostics not truncated'
}

Invoke-Case 'CopyDirectory copies metadata and independently owns both lists' {
    $snapshot = New-BranchSnapshot
    $source = $snapshot.Directories[1]
    $source.DirectBytes = 123
    $source.DirectFiles = 7
    $source.DirectIssueCount = 3
    $source.Retry = $true
    $source.Issues.Add('one')
    $source.LinkedFiles.Add([uint64]500)
    $source.LinkedFiles.Add([uint64]::MaxValue)
    $copy = [FolderMap.CacheTree]::CopyDirectory($source, 77)
    Assert-Equal $copy.ParentIndex 77 'New parent index'
    foreach ($field in 'Name', 'FileId', 'DirectBytes', 'DirectFiles', 'DirectIssueCount', 'Retry', 'Reparse') {
        Assert-Equal $copy.$field $source.$field ("Copied $field")
    }
    Assert-True (-not [object]::ReferenceEquals($source.Issues, $copy.Issues)) 'Independent issues list'
    Assert-True (-not [object]::ReferenceEquals($source.LinkedFiles, $copy.LinkedFiles)) 'Independent linked IDs list'
    Assert-Equal $copy.LinkedFiles[1] ([uint64]::MaxValue) 'High unsigned link ID preserved'
    $copy.Issues[0] = 'copy-only'
    $copy.LinkedFiles.Clear()
    $source.Issues.Add('source-only')
    Assert-Text $source.Issues[0] 'one' 'Copy cannot modify source strings list'
    Assert-Equal $copy.Issues.Count 1 'Source cannot modify copy list'
    Assert-Equal $source.LinkedFiles.Count 2 'Copy cannot clear source links'
    $source.ParentIndex = 9
    Assert-Equal $copy.ParentIndex 77 'Parent metadata independent'
}

Invoke-Case 'Reparse placeholders are retained without traversal' {
    $snapshot = New-Snapshot
    $link = Add-Directory $snapshot 0 'junction' 0 0 0 1
    $link.Reparse = $true
    $link.Issues.Add('not traversed')
    $result = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    Assert-Equal $result.Root.Children[0].TotalBytes ([long]0) 'Reparse zero size'
    Assert-Equal $result.Root.Children[0].Children.Count 0 'Reparse no traversal'
    Assert-Equal $result.IssueCount 1 'Reparse direct issue retained'
}

Invoke-Case 'Cancellation is preserved without changing snapshot' {
    $snapshot = New-BranchSnapshot
    $before = Get-SnapshotKey $snapshot
    $worker = [ComponentModel.BackgroundWorker]::new()
    try {
        $worker.WorkerSupportsCancellation = $true
        $worker.CancelAsync()
        Assert-Throws { [FolderMap.CacheTree]::ToResult($snapshot, $worker) } ([OperationCanceledException])
        Assert-Text (Get-SnapshotKey $snapshot) $before 'Canceled snapshot unchanged'
    }
    finally { $worker.Dispose() }
}

Invoke-Case 'Null and empty snapshots are rejected explicitly' {
    Assert-Throws { [FolderMap.CacheTree]::Paths($null) } ([ArgumentNullException])
    Assert-Throws { [FolderMap.CacheTree]::ToResult($null, $null) } ([ArgumentNullException])
    Assert-Throws { [FolderMap.CacheTree]::CopyDirectory($null, -1) } ([ArgumentNullException])
    Assert-Throws { [FolderMap.CacheDeltaPlan]::new($null) } ([ArgumentNullException])
    $empty = [FolderMap.CacheSnapshot]::new()
    $empty.RootPath = 'C:\empty'
    Assert-Throws { [FolderMap.CacheTree]::ToResult($empty, $null) } ([ArgumentException])
    Assert-Throws { [FolderMap.CacheDeltaPlan]::new($empty) } ([ArgumentException])
    $empty.Directories = $null
    Assert-Throws { [FolderMap.CacheTree]::Paths($empty) } ([ArgumentException])
    $snapshot = New-Snapshot
    $snapshot.Directories[0] = $null
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Parent ordering, extra roots, cycles, and duplicate ordinal siblings are rejected' {
    foreach ($badParent in -2, -1, 1, 2, [int]::MaxValue) {
        $snapshot = New-BranchSnapshot
        $snapshot.Directories[1].ParentIndex = $badParent
        Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
        Assert-Throws { [FolderMap.CacheDeltaPlan]::new($snapshot) } ([ArgumentException])
    }
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[0].ParentIndex = 0
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].ParentIndex = 2
    $snapshot.Directories[2].ParentIndex = 1
    Assert-Throws { [FolderMap.CacheTree]::ToResult($snapshot, $null) } ([ArgumentException])
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[2].Name = 'alpha'
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Traversal, rooted child names, devices, and invalid name components are rejected' {
    $badNames = @('', '.', '..', '..\escape', 'a/b', 'C:\evil', '\evil', 'name:stream',
        'trailing.', 'trailing ', 'CON', 'nul.txt', 'COM1', 'LPT9.log', 'CONOUT$',
        ('COM' + [char]185), ('control' + [char]1), 'wild*', 'wild?', 'a|b', ('x' * 256))
    foreach ($badName in $badNames) {
        $snapshot = New-BranchSnapshot
        $snapshot.Directories[1].Name = $badName
        Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    }
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].Name = $null
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Relative, drive-relative, device, and escaping root paths are rejected' {
    foreach ($rootPath in '', 'relative', 'C:relative', '\relative', '\\server', '\\server\',
        '\\.\device\folder', '\\?\GLOBALROOT\Device\HarddiskVolume1', 'C:\..\escape') {
        $snapshot = New-Snapshot
        $snapshot.RootPath = $rootPath
        Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    }
    $snapshot = New-Snapshot
    $snapshot.RootPath = $null
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Paths reject oversized roots and cumulative paths before concatenating descendants' {
    $snapshot = New-Snapshot
    $snapshot.RootPath = 'C:\' + ('x' * 40000)
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot.RootPath = 'C:\' + ((1..135 | ForEach-Object { 'a' * 240 }) -join '\')
    Assert-Equal ([FolderMap.CacheTree]::Paths($snapshot)[0].Length) 32537 'Long roots do not use legacy MAX_PATH'
    $null = Add-Directory $snapshot 0 ('b' * 255) 2
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Negative statistics, invalid lists, and invalid zero identities are rejected' {
    foreach ($field in 'DirectBytes', 'DirectFiles', 'DirectIssueCount') {
        $snapshot = New-Snapshot
        $snapshot.Directories[0].$field = -1
        Assert-Throws { [FolderMap.CacheTree]::ToResult($snapshot, $null) } ([ArgumentException])
    }
    foreach ($field in 'Issues', 'LinkedFiles') {
        $snapshot = New-Snapshot
        $snapshot.Directories[0].$field = $null
        Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
        Assert-Throws { [FolderMap.CacheTree]::CopyDirectory($snapshot.Directories[0], -1) } ([ArgumentException])
    }
    $snapshot = New-Snapshot
    $snapshot.Directories[0].FileId = 0
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot.Directories[0].Retry = $true
    Assert-Equal ([FolderMap.CacheTree]::Paths($snapshot).Count) 1 'Zero retry identity allowed'
    $snapshot = New-Snapshot
    $snapshot.Directories[0].Issues.Add('uncounted')
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot.Directories[0].DirectIssueCount = 1
    $snapshot.Directories[0].Issues.GetType().GetProperty('Item').SetValue(
        $snapshot.Directories[0].Issues, $null, [object[]]@(0))
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot = New-Snapshot
    Assert-Throws { [FolderMap.CacheTree]::CopyDirectory($snapshot.Directories[0], -2) } ([ArgumentException])
}

Invoke-Case 'Reparse entries cannot have own file sizes, known linked files, or children' {
    foreach ($field in 'DirectBytes', 'DirectFiles') {
        $snapshot = New-Snapshot
        $snapshot.Directories[0].Reparse = $true
        $snapshot.Directories[0].$field = 1
        Assert-Throws { [FolderMap.CacheTree]::ToResult($snapshot, $null) } ([ArgumentException])
    }
    $snapshot = New-Snapshot
    $snapshot.Directories[0].Reparse = $true
    $snapshot.Directories[0].LinkedFiles.Add([uint64]100)
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].Reparse = $true
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
}

Invoke-Case 'Aggregation rejects byte, file, and issue overflow with checked arithmetic' {
    foreach ($field in 'DirectBytes', 'DirectFiles', 'DirectIssueCount') {
        $snapshot = New-BranchSnapshot
        if ($field -eq 'DirectIssueCount') { $snapshot.Directories[0].$field = [int]::MaxValue }
        else { $snapshot.Directories[0].$field = [long]::MaxValue }
        $snapshot.Directories[1].$field = 1
        $before = Get-SnapshotKey $snapshot
        Assert-Throws { [FolderMap.CacheTree]::ToResult($snapshot, $null) } ([OverflowException])
        Assert-Text (Get-SnapshotKey $snapshot) $before 'Overflow never modifies snapshot'
    }
}

Invoke-Case 'Five-thousand-level tree reconstructs and aggregates without recursion' {
    $snapshot = New-Snapshot
    $snapshot.RootPath = 'C:\d'
    $snapshot.Directories[0].DirectBytes = 1
    $snapshot.Directories[0].DirectFiles = 1
    $depth = 5000
    for ($i = 1; $i -lt $depth; $i++) {
        $null = Add-Directory $snapshot ($i - 1) 'd' ([uint64]($i + 1)) 1 1
    }
    $result = [FolderMap.CacheTree]::ToResult($snapshot, $null)
    Assert-Equal $result.Root.TotalBytes ([long]$depth) 'Deep recursive bytes'
    Assert-Equal $result.Root.TotalFiles ([long]$depth) 'Deep recursive files'
    Assert-Equal $result.Root.FolderCount ([long]($depth - 1)) 'Deep descendant directory count'
    $node = $result.Root
    for ($i = 1; $i -lt $depth; $i++) {
        $next = $node.Children[0]
        Assert-True ([object]::ReferenceEquals($next.Parent, $node)) 'Deep parent references are new and correct'
        $node = $next
    }
    Assert-Equal $node.FullPath.Length (4 + 2 * ($depth - 1)) 'Deep paths are not truncated'
    Assert-Equal $node.Children.Count 0 'Deep leaf'
    Assert-Equal $node.TotalBytes ([long]1) 'Deep leaf direct aggregation'
}

Invoke-Case 'Overlong deep chains fail length preflight without materializing a huge path prefix' {
    $snapshot = New-Snapshot
    $snapshot.RootPath = 'C:\d'
    for ($i = 1; $i -lt 17000; $i++) {
        $null = Add-Directory $snapshot ($i - 1) 'd' ([uint64]($i + 1))
    }
    Assert-Throws { [FolderMap.CacheTree]::Paths($snapshot) } ([ArgumentException])
    Assert-Equal $snapshot.Directories.Count 17000 'Length rejection leaves all source entries intact'
}

Invoke-Case 'Clean construction and unrelated records leave root clean but count all observations' {
    $snapshot = New-BranchSnapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    Assert-Dirty $plan @()
    Assert-True ($null -eq $plan.FullScanReason) 'Clean plan needs no full scan'
    Assert-Equal $plan.RecordsSeen ([long]0) 'Initial record count'
    $plan.Observe((New-Change 900 901 0x100))
    $plan.Observe((New-Change 900 901 0x200))
    $plan.Observe((New-Change 900 901 0x1000 0x10))
    $plan.Observe((New-Change 900 901 $closeBit))
    $plan.Observe((New-Change 2 1 0))
    Assert-Dirty $plan @()
    Assert-Equal $plan.RecordsSeen ([long]5) 'All unrelated and zero-reason records counted'
    Assert-Text (Get-PendingKey $plan) '' 'No unrelated pending writes'
}

Invoke-Case 'Creates and deletes refresh the known containing directory rather than the root' {
    foreach ($reason in 0x100, 0x200) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 100 2 $reason))
        Assert-Dirty $plan @(2)
        Assert-Equal $plan.RecordsSeen ([long]1) 'One create/delete record'
        Assert-True ($null -eq $plan.FullScanReason) 'Ordinary create/delete is incremental'
    }
}

Invoke-Case 'New directories refresh only their known parents; unknown descendants do not dirty root' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 100 2 0x100 0x10))
    $plan.Observe((New-Change 101 100 0x100))
    Assert-Dirty $plan @(2)
    Assert-Text (Get-PendingKey $plan) '100:2' 'Only in-scope containing directories tracked'
}

Invoke-Case 'Cached-directory changes dirty both directory ID and known parent' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 4 2 0x2000 0x10))
    Assert-Dirty $plan @(2, 4)
    Assert-Text (Get-PendingKey $plan) '' 'Rename is not an unnamed data write'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 4 999 0x1000 0x10))
    Assert-Dirty $plan @(4)
    Assert-True ($null -eq $plan.FullScanReason) 'Moving a nonroot cached directory is not global invalidation'
}

Invoke-Case 'Rename old/new records cover both sides of in-tree and boundary moves' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 100 2 0x1000))
    $plan.Observe((New-Change 100 3 0x2000))
    Assert-Dirty $plan @(2, 3)
    Assert-Equal $plan.RecordsSeen ([long]2) 'Both rename records counted'
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 100 999 0x1000))
    $plan.Observe((New-Change 100 3 0x2000))
    Assert-Dirty $plan @(3)
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 100 2 0x1000))
    $plan.Observe((New-Change 100 999 0x2000))
    Assert-Dirty $plan @(2)
}

Invoke-Case 'Documented ordinary reasons besides CLOSE dirty known parents without invalidating the plan' {
    foreach ($reason in 1, 2, 4, 0x10, 0x400, ($closeBit + 0x400)) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 100 2 ([uint32]$reason)))
        Assert-Dirty $plan @(2)
        Assert-True ($null -eq $plan.FullScanReason) 'Supported ordinary reason remains incremental'
    }
}

Invoke-Case 'Every unsupported reason bit forces a full scan even for an unrelated outside record' {
    $snapshot = New-BranchSnapshot
    $before = Get-SnapshotKey $snapshot
    foreach ($unsupported in 0x8, 0x80, 0x02000000, 0x04000000,
        0x08000000, 0x10000000, 0x20000000, 0x40000000) {
        foreach ($reason in $unsupported, ($closeBit + $unsupported)) {
            $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
            $plan.Observe((New-Change ([uint64]::MaxValue) 999 ([uint32]$reason)))
            Assert-Dirty $plan @()
            Assert-True ($plan.FullScanReason -match 'unsupported.*reason') (
                'Unsupported reason 0x{0:X8} requires an explained full scan' -f $reason)
            Assert-True ($plan.FullScanReason.Contains(('0x{0:X8}' -f $unsupported))) 'The exact unknown bits are included in the explanation'
            Assert-Equal $plan.RecordsSeen ([long]1) 'Unsupported record is still counted'
            Assert-Text (Get-PendingKey $plan) '' 'No unrelated pending pair is introduced'
        }
    }
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Unsupported records do not mutate the snapshot'
}

Invoke-Case 'Every current Windows SDK reason flag is recognized rather than classified as unsupported' {
    $knownReasons = @(1, 2, 4, 0x10, 0x20, 0x40, 0x100, 0x200, 0x400, 0x800,
        0x1000, 0x2000, 0x4000, 0x8000, 0x10000, 0x20000, 0x40000, 0x80000,
        0x100000, 0x200000, 0x400000, 0x800000, 0x01000000, $closeBit)
    foreach ($reason in $knownReasons) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 900 999 ([uint32]$reason)))
        Assert-Dirty $plan @()
        if ($reason -in 0x800, 0x10000) {
            Assert-True ($null -ne $plan.FullScanReason -and $plan.FullScanReason -notmatch 'unsupported') (
                'Known security/hardlink flags retain their specific invalidation policy')
        }
        else {
            Assert-True ($null -eq $plan.FullScanReason) (
                'Documented unrelated reason 0x{0:X8} remains incremental' -f $reason)
        }
        Assert-Equal $plan.RecordsSeen ([long]1) 'Documented record is counted'
    }
    $knownMask = [uint32]::Parse('81FFFF77', [Globalization.NumberStyles]::HexNumber)
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 900 999 ([uint32]($knownMask - 0x10800))))
    Assert-Dirty $plan @()
    Assert-True ($null -eq $plan.FullScanReason) 'Combining all known nonglobal flags remains supported'
    $plan.Observe((New-Change 900 999 $knownMask))
    Assert-True ($plan.FullScanReason -match 'hard-link' -and $plan.FullScanReason -notmatch 'unsupported') (
        'The entire documented mask is recognized and preserves global hardlink invalidation')
}

Invoke-Case 'Storage-class changes invalidate only the affected cached directory' {
    $snapshot = New-BranchSnapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.Observe((New-Change 900 999 0x01000000))
    Assert-True ($null -eq $plan.FullScanReason) 'Unrelated storage-tier activity does not discard the whole snapshot'
    Assert-Dirty $plan @()
    $plan.Observe((New-Change 901 2 ([uint32]($closeBit + 0x01000000))))
    Assert-True ($null -eq $plan.FullScanReason) 'A known storage-class reason stays incremental'
    Assert-Dirty $plan @(2)
}

Invoke-Case 'Unsupported mixed reasons preserve record counting and independent pending close/delete bookkeeping' {
    $snapshot = New-BranchSnapshot
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 3))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(101, 4))
    $before = Get-SnapshotKey $snapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 100 999 ($closeBit + 0x9)))
    Assert-True ($plan.FullScanReason -match 'unsupported.*reason') 'Mixed close/data record fails closed'
    $firstReason = $plan.FullScanReason
    Assert-Dirty $plan @(2, 3)
    Assert-Text (Get-PendingKey $plan) '101:4' 'Close still refreshes and removes all prior containing pairs'
    $plan.Observe((New-Change 102 2 0x9))
    Assert-Text (Get-PendingKey $plan) '101:4,102:2' 'Known data bit still tracks an independently pending writer'
    $plan.Observe((New-Change 101 2 0x208))
    Assert-Dirty $plan @(2, 3, 4)
    Assert-Text (Get-PendingKey $plan) '102:2' 'Delete still removes the finished file across its prior parents'
    $plan.Observe((New-Change 900 999 0x800))
    Assert-Text $plan.FullScanReason $firstReason 'Unsupported first reason survives a later security invalidation'
    Assert-Equal $plan.RecordsSeen ([long]4) 'All records counted after fail-closed invalidation'
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Pending removals are confined to the plan, not prior stored state'
}

Invoke-Case 'Known hardlinked files with outside journal parents refresh every cached containing directory' {
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].LinkedFiles.Add([uint64]500)
    $snapshot.Directories[1].LinkedFiles.Add([uint64]500)
    $snapshot.Directories[2].LinkedFiles.Add([uint64]500)
    $before = Get-SnapshotKey $snapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.Observe((New-Change 500 999 1))
    Assert-Dirty $plan @(2, 3)
    Assert-Text (Get-PendingKey $plan) '500:2,500:3' 'Known hardlink containing directories become pending'
    Assert-True ($null -eq $plan.FullScanReason) 'Data change of known link is incremental'
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Hardlink metadata not changed'
}

Invoke-Case 'Known parent and distinct hardlink parents are all refreshed and deduplicated' {
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].LinkedFiles.Add([uint64]500)
    $snapshot.Directories[2].LinkedFiles.Add([uint64]500)
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.Observe((New-Change 500 4 1))
    $plan.Observe((New-Change 500 2 2))
    Assert-Dirty $plan @(2, 3, 4)
    Assert-Text (Get-PendingKey $plan) '500:2,500:3,500:4' 'Every distinct known parent retained'
}

Invoke-Case 'Volume-wide hard-link change invalidates even wholly unrelated or previously single-link files' {
    foreach ($reason in 0x10000, ($closeBit + 0x10000)) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 900 901 ([uint32]$reason)))
        Assert-Dirty $plan @()
        Assert-True ($plan.FullScanReason -match 'hard-link') 'Hardlink topology requires a full scan'
        Assert-Equal $plan.RecordsSeen ([long]1) 'Invalidating record counted'
    }
}

Invoke-Case 'Volume-wide security changes invalidate conservatively and first reason wins' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 900 901 0x800))
    Assert-Dirty $plan @()
    Assert-True ($plan.FullScanReason -match 'security|permission|inheritance') 'Permissions require a full scan'
    $firstReason = $plan.FullScanReason
    $plan.Observe((New-Change 900 901 0x10000))
    $plan.Observe((New-Change 1 999 0x200))
    $plan.Observe((New-Change 900 901 0x40000000))
    Assert-Text $plan.FullScanReason $firstReason 'First full-scan explanation retained'
    Assert-Equal $plan.RecordsSeen ([long]4) 'Continue counting after full-scan invalidation'
}

Invoke-Case 'Root deletion, both rename sides, and reparse changes force full scans' {
    foreach ($reason in 0x200, 0x1000, 0x2000, 0x100000) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 1 999 $reason))
        Assert-True ($plan.FullScanReason -match 'root') 'Root identity/topology invalidation explained'
        Assert-Dirty $plan @(1)
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 4 2 $reason))
        Assert-True ($null -eq $plan.FullScanReason) 'Equivalent nonroot change is not globally invalidating'
    }
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $plan.Observe((New-Change 1 999 0x400))
    Assert-True ($null -eq $plan.FullScanReason) 'Ordinary root metadata change is incremental'
    Assert-Dirty $plan @(1)
}

Invoke-Case 'Retry IDs and surviving pending parents start dirty; reparse and zero IDs are not known' {
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[3].Retry = $true
    $retry = Add-Directory $snapshot 0 'retry-unknown' 0
    $retry.Retry = $true
    $reparse = Add-Directory $snapshot 0 'junction' 5
    $reparse.Reparse = $true
    $reparse.Retry = $true
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 999))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(101, 5))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(102, 0))
    $before = Get-SnapshotKey $snapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    Assert-Dirty $plan @(2, 4)
    Assert-Text (Get-PendingKey $plan) '100:2' 'Only surviving known pending parents retained'
    Assert-Equal $plan.RecordsSeen ([long]0) 'Persisted state is not an observed record'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 1000 5 1))
    $plan.Observe((New-Change 1001 0 1))
    Assert-Dirty $plan @()
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Prior pending records not mutated or removed'
}

Invoke-Case 'Unnamed data bits and file create remain pending until a finishing record' {
    foreach ($reason in 1, 2, 4, 7, 0x100) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 100 2 $reason))
        $plan.Observe((New-Change 100 2 $reason))
        Assert-Text (Get-PendingKey $plan) '100:2' 'Pending pair is deduplicated'
        Assert-Dirty $plan @(2)
    }
    foreach ($reason in 0x10, 0x20, 0x40, 0x1000, 0x400, ($closeBit + 1), ($closeBit + 0x100), 0x201) {
        $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
        $plan.Observe((New-Change 100 2 ([uint32]$reason)))
        Assert-Text (Get-PendingKey $plan) '' 'Non-unnamed-data or already-finished records are not pending'
    }
}

Invoke-Case 'A pure close with no pending state does not dirty even known parents or hardlink parents' {
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[1].LinkedFiles.Add([uint64]500)
    $snapshot.Directories[2].LinkedFiles.Add([uint64]500)
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.Observe((New-Change 500 2 $closeBit))
    $plan.Observe((New-Change 4 2 $closeBit 0x10))
    $plan.Observe((New-Change 1 999 $closeBit 0x10))
    Assert-Dirty $plan @()
    Assert-Text (Get-PendingKey $plan) '' 'No newly pending pure-close record'
    Assert-Equal $plan.RecordsSeen ([long]3) 'All closes counted'
}

Invoke-Case 'Close finishes every pending parent once even after file moved outside root' {
    $snapshot = New-BranchSnapshot
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 3))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(101, 4))
    $before = Get-SnapshotKey $snapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 100 999 $closeBit))
    Assert-Dirty $plan @(2, 3)
    Assert-Text (Get-PendingKey $plan) '101:4' 'All parents for only the finished file removed'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 100 2 $closeBit))
    Assert-Dirty $plan @()
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Finishing does not mutate source pairs'
}

Invoke-Case 'Delete clears pending across old parents and refreshes its current known parent' {
    $snapshot = New-BranchSnapshot
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 3))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(101, 2))
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 100 4 0x201))
    Assert-Dirty $plan @(2, 3, 4)
    Assert-Text (Get-PendingKey $plan) '101:2' 'Deleted file not re-added by data bit'
}

Invoke-Case 'Data plus close clears prior pending parents without opening a new pending pair' {
    $snapshot = New-BranchSnapshot
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 100 3 ($closeBit + 1)))
    Assert-Dirty $plan @(2, 3)
    Assert-Text (Get-PendingKey $plan) '' 'Final data record closes, rather than reopens, writer'
}

Invoke-Case 'Pending bookkeeping survives snapshots and keeps writers dirty across zero-record intervals' {
    $snapshot = New-BranchSnapshot
    $before = Get-SnapshotKey $snapshot
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $plan.Observe((New-Change 100 2 1))
    $next = Copy-Snapshot $snapshot
    $next.PendingWrites = $plan.GetPendingWrites()
    $second = [FolderMap.CacheDeltaPlan]::new($next)
    Assert-Dirty $second @(2)
    Assert-Equal $second.RecordsSeen ([long]0) 'No record needed to refresh a pending directory'
    Assert-Text (Get-PendingKey $second) '100:2' 'Pending carried through no-record interval'
    $thirdSnapshot = Copy-Snapshot $next
    $thirdSnapshot.PendingWrites = $second.GetPendingWrites()
    $third = [FolderMap.CacheDeltaPlan]::new($thirdSnapshot)
    $third.DirtyIds.Clear()
    $third.Observe((New-Change 100 999 $closeBit))
    Assert-Dirty $third @(2)
    Assert-Text (Get-PendingKey $third) '' 'Later close finishes previously persisted writer'
    Assert-Text (Get-SnapshotKey $snapshot) $before 'Original baseline untouched'
    Assert-Equal $next.PendingWrites.Count 1 'Intermediate snapshot retains its own pending pair'
}

Invoke-Case 'Exported pending lists and planner metadata do not alias prior or future snapshots' {
    $snapshot = New-BranchSnapshot
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(100, 2))
    $snapshot.Directories[1].LinkedFiles.Add([uint64]500)
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $first = $plan.GetPendingWrites()
    $second = $plan.GetPendingWrites()
    Assert-True (-not [object]::ReferenceEquals($first, $second)) 'Independent pending lists'
    Assert-True (-not [object]::ReferenceEquals($first[0], $second[0])) 'Independent pending DTOs'
    Assert-True (-not [object]::ReferenceEquals($first[0], $snapshot.PendingWrites[0])) 'Not a source DTO'
    $first[0].FileId = 99
    $first[0].ParentId = 99
    $first.Clear()
    $snapshot.PendingWrites[0].ParentId = 3
    $snapshot.Directories[1].LinkedFiles.Clear()
    $snapshot.Directories[1].FileId = 22
    $snapshot.RootFileId = 88
    Assert-Text (Get-PendingKey $plan) '100:2' 'Planner retained independent original pair'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 500 999 1))
    Assert-Dirty $plan @(2)
    $plan.Observe((New-Change 1 999 0x2000))
    Assert-True ($plan.FullScanReason -match 'root') 'Planner retains original root identity'
}

Invoke-Case 'High-bit uint64 directory and file IDs sort unsigned by file then parent' {
    $high = [uint64]::Parse('9223372036854775808')
    $maximum = [uint64]::MaxValue
    $snapshot = New-Snapshot
    $snapshot.RootFileId = $high
    $snapshot.Directories[0].FileId = $high
    $null = Add-Directory $snapshot 0 'low' 2
    $null = Add-Directory $snapshot 0 'maximum' $maximum
    $snapshot.Directories[1].LinkedFiles.Add($maximum)
    $snapshot.Directories[2].LinkedFiles.Add($maximum)
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new($maximum, $maximum))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(2, $maximum))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new($high, $high))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(2, 2))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new(0, 2))
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    Assert-Dirty $plan @(2, $high, $maximum)
    Assert-Text (Get-PendingKey $plan) '0:2,2:2,2:18446744073709551615,9223372036854775808:9223372036854775808,18446744073709551615:18446744073709551615' 'Unsigned ordering'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change $maximum 999 1))
    Assert-Dirty $plan @(2, $maximum)
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change $maximum 999 $closeBit))
    Assert-Dirty $plan @(2, $maximum)
    $plan.Observe((New-Change $high 999 0x200))
    Assert-True ($plan.FullScanReason -match 'root') 'High-bit root ID comparison'
}

Invoke-Case 'Streaming Action callback and multiple independent writers keep exact record counts' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    $callback = [Delegate]::CreateDelegate([Action[FolderMap.UsnChange]], $plan, 'Observe')
    $callback.Invoke((New-Change 100 2 1))
    $callback.Invoke((New-Change 101 2 1))
    $callback.Invoke((New-Change 100 3 2))
    $callback.Invoke((New-Change 102 4 0x100))
    $callback.Invoke((New-Change 999 999 1))
    $callback.Invoke((New-Change 101 999 $closeBit))
    Assert-Dirty $plan @(2, 3, 4)
    Assert-Text (Get-PendingKey $plan) '100:2,100:3,102:4' 'Independent writers and parents'
    Assert-Equal $plan.RecordsSeen ([long]6) 'Relevant and unrelated callbacks all counted'
}

Invoke-Case 'Pending export is deterministic regardless of insertion order and source duplicates' {
    $left = New-BranchSnapshot
    $right = New-BranchSnapshot
    $pairs = @(@(17, 4), @(3, 2), @(17, 2), @(8, 3), @(17, 3), @(3, 2))
    foreach ($pair in $pairs) { $left.PendingWrites.Add([FolderMap.PendingWrite]::new($pair[0], $pair[1])) }
    for ($i = $pairs.Count - 1; $i -ge 0; $i--) {
        $right.PendingWrites.Add([FolderMap.PendingWrite]::new($pairs[$i][0], $pairs[$i][1]))
    }
    $leftPlan = [FolderMap.CacheDeltaPlan]::new($left)
    $rightPlan = [FolderMap.CacheDeltaPlan]::new($right)
    Assert-Text (Get-PendingKey $leftPlan) '3:2,8:3,17:2,17:3,17:4' 'Canonical ordering and deduplication'
    Assert-Text (Get-PendingKey $rightPlan) (Get-PendingKey $leftPlan) 'Order independent of insertion history'
}

Invoke-Case 'Thousands of pending pairs retain independent files and remove one file across parents' {
    $snapshot = New-BranchSnapshot
    for ($id = 3000; $id -ge 1001; $id--) {
        foreach ($parent in 4, 2, 3, 2) {
            $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new([uint64]$id, [uint64]$parent))
        }
    }
    $plan = [FolderMap.CacheDeltaPlan]::new($snapshot)
    $pending = $plan.GetPendingWrites()
    Assert-Equal $pending.Count 6000 'Large pending set deduplicated'
    Assert-Equal $pending[0].FileId ([uint64]1001) 'First file sorted'
    Assert-Equal $pending[0].ParentId ([uint64]2) 'First parent sorted'
    Assert-Equal $pending[5999].FileId ([uint64]3000) 'Last file sorted'
    Assert-Equal $pending[5999].ParentId ([uint64]4) 'Last parent sorted'
    $plan.DirtyIds.Clear()
    $plan.Observe((New-Change 2000 999 $closeBit))
    Assert-Dirty $plan @(2, 3, 4)
    Assert-Equal ($plan.GetPendingWrites().Count) 5997 'Finishing removes only the target file'
    Assert-Equal $snapshot.PendingWrites.Count 8000 'Original large list never edited'
}

Invoke-Case 'Null changes and overflowing record counts fail before mutating plan state' {
    $plan = [FolderMap.CacheDeltaPlan]::new((New-BranchSnapshot))
    Assert-Throws { $plan.Observe($null) } ([ArgumentNullException])
    Assert-Equal $plan.RecordsSeen ([long]0) 'Null record not counted'
    $plan.RecordsSeen = [long]::MaxValue
    Assert-Throws { $plan.Observe((New-Change 100 2 1)) } ([OverflowException])
    Assert-Equal $plan.RecordsSeen ([long]::MaxValue) 'Overflow does not wrap count'
    Assert-Dirty $plan @()
    Assert-Text (Get-PendingKey $plan) '' 'Overflow occurs before bookkeeping'
}

Invoke-Case 'Malformed pending lists and ambiguous known directory identities fail explicitly' {
    $snapshot = New-Snapshot
    $snapshot.PendingWrites = $null
    Assert-Throws { [FolderMap.CacheDeltaPlan]::new($snapshot) } ([ArgumentException])
    $snapshot = New-Snapshot
    $snapshot.PendingWrites.Add($null)
    Assert-Throws { [FolderMap.CacheDeltaPlan]::new($snapshot) } ([ArgumentException])
    $snapshot = New-BranchSnapshot
    $snapshot.Directories[2].FileId = 2
    Assert-Throws { [FolderMap.CacheDeltaPlan]::new($snapshot) } ([ArgumentException])
}

$clock.Stop()
Write-Host ('Cache delta/tree: {0} passed, {1} failed; {2} assertions; {3} methods JIT-prepared; {4:N2}s.' -f
    $script:passed, $script:failed, $script:assertions, $script:prepared, $clock.Elapsed.TotalSeconds)
if ($script:failed -ne 0) {
    throw ('Cache delta/tree validation failed: {0} case(s).' -f $script:failed)
}
