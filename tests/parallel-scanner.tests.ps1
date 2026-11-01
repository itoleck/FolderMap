[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not [Environment]::Is64BitProcess -or $PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run with 64-bit Windows PowerShell (.NET Framework), not PowerShell Core.'
}
[AppContext]::SetSwitch('Switch.System.IO.UseLegacyPathHandling', $false)
[AppContext]::SetSwitch('Switch.System.IO.BlockLongPaths', $false)
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$parallelType = $assembly.GetType('FolderMap.ParallelScanner', $true)
$workType = $assembly.GetType('FolderMap.ParallelScanWork', $true)
$internalStatic = [Reflection.BindingFlags]'Static,NonPublic'
$internalInstance = [Reflection.BindingFlags]'Instance,NonPublic'
$createWork = $parallelType.GetMethod('CreateWork', $internalStatic)
$merge = $parallelType.GetMethod('Merge', $internalStatic)
$complete = $parallelType.GetMethod('Complete', $internalStatic)
$start = $workType.GetMethod('Start', $internalInstance)
$join = $workType.GetMethod('Join', $internalInstance)
$passed = 0
$skipped = 0
$links = [Collections.Generic.List[string]]::new()
$fixture = Join-Path (Split-Path -Parent $PSScriptRoot) ('.parallel-fixture-' + [Guid]::NewGuid().ToString('N'))
$activeWork = $null
$gate = $null
$cancel = $null
$aclPath = $null
$originalAcl = $null
$literalEnvironment = 'FOLDERMAP_LITERAL_' + [Guid]::NewGuid().ToString('N')
$rootEnvironment = 'FOLDERMAP_ROOT_' + [Guid]::NewGuid().ToString('N')

function Assert-Parallel([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Assert-Throws([scriptblock]$Action, [Type]$Expected, [string]$Message) {
    $caught = $null
    try { $null = & $Action }
    catch {
        $caught = $_.Exception
        while (($caught -is [Reflection.TargetInvocationException] -or
            $caught -is [Management.Automation.MethodInvocationException]) -and $caught.InnerException) {
            $caught = $caught.InnerException
        }
    }
    Assert-Parallel ($null -ne $caught) "$Message throws"
    Assert-Parallel ($Expected.IsInstanceOfType($caught)) "$Message has type $($Expected.Name), not $($caught.GetType().Name)"
    Assert-Parallel (-not [string]::IsNullOrWhiteSpace($caught.Message)) "$Message is descriptive"
}

function Skip-Parallel([string]$Reason) {
    $script:skipped++
    Write-Host "SKIP: $Reason"
}

function Work-Field($Work, [string]$Name) {
    return ,$workType.GetField($Name, $internalInstance).GetValue($Work)
}

function Job-Field($Job, [string]$Name) {
    return ,$Job.GetType().GetField($Name, $internalInstance).GetValue($Job)
}

function New-Work($Shallow, $Recorder = $null, $Worker = $null) {
    return $createWork.Invoke($null, [object[]]@($Shallow, $Worker, $Recorder))
}

function Run-Work($Shallow, $Recorder, [int]$Limit) {
    return $complete.Invoke($null, [object[]]@($Shallow, $null, $Recorder, $Limit))
}

function Assert-Drained($Work) {
    Assert-Parallel ((Work-Field $Work 'ActiveWorkers') -eq 0) 'all lanes have exited'
    Assert-Parallel ((Work-Field $Work 'ActiveJobs') -eq 0) 'no worker still owns a subtree'
    foreach ($task in (Work-Field $Work 'Tasks')) {
        Assert-Parallel $task.IsCompleted 'task finished before join returned/threw'
    }
}

function Wait-ForJobs($Work, [int]$Count) {
    # This is a synchronization timeout, not a scan-duration/speedup assertion.
    $clock = [Diagnostics.Stopwatch]::StartNew()
    while ((Work-Field $Work 'ActiveJobs') -ne $Count) {
        if ($clock.Elapsed.TotalSeconds -gt 45) { throw "Workers did not reach the test gate ($Count jobs)." }
        [Threading.Thread]::Sleep(10)
    }
}

function Tree-Signature($Root, $Recorder = $null) {
    $pending = [Collections.Generic.Stack[object]]::new()
    $rows = [Collections.Generic.List[string]]::new()
    $pending.Push($Root)
    while ($pending.Count) {
        $node = $pending.Pop()
        $children = [Collections.Generic.List[string]]::new()
        foreach ($child in $node.Children) {
            Assert-Parallel ([object]::ReferenceEquals($child.Parent, $node)) 'parent references are repaired during serial merge'
            $children.Add($child.Name)
            $pending.Push($child)
        }
        $row = "$($node.FullPath)|$($node.DirectBytes)|$($node.TotalBytes)|$($node.DirectFiles)|$($node.TotalFiles)|$($node.FolderCount)|$($node.IssueCount)|$([string]::Join(',', $children))"
        if ($null -ne $Recorder) {
            $entry = $Recorder.Export($node)
            $row += "|$($entry.FileId)|$($entry.DirectBytes)|$($entry.DirectFiles)|$($entry.DirectIssueCount)|$($entry.Retry)|$($entry.Reparse)|$($entry.Issues -join ';')|$($entry.LinkedFiles -join ',')"
        }
        $rows.Add($row)
    }
    $rows.Sort([StringComparer]::Ordinal)
    return [string]::Join("`n", $rows)
}

function New-Junction([string]$Path, [string]$Target) {
    try { $null = New-Item -ItemType Junction -Path $Path -Target $Target }
    catch {
        Skip-Parallel "Junction creation unavailable: $($_.Exception.Message)"
        return $false
    }
    $links.Add($Path)
    return $true
}

function Restore-FixtureAcl {
    if ($null -ne $script:originalAcl) {
        $script:originalAcl.SetSecurityDescriptorBinaryForm(
            $script:originalAcl.GetSecurityDescriptorBinaryForm(), [Security.AccessControl.AccessControlSections]::Access)
        [IO.Directory]::SetAccessControl($script:aclPath, $script:originalAcl)
        $script:originalAcl = $null
    }
}

try {
    $jit = 0
    $members = [Reflection.BindingFlags]'DeclaredOnly,Public,NonPublic,Static,Instance'
    foreach ($name in @('FolderMap.ParallelScanner', 'FolderMap.ParallelScanWork', 'FolderMap.ParallelScanJob', 'FolderMap.CacheRecorder')) {
        $type = $assembly.GetType($name, $true)
        foreach ($method in @($type.GetMethods($members)) + @($type.GetConstructors($members))) {
            [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
            $jit++
        }
    }
    Assert-Parallel ($assembly.GetName().ProcessorArchitecture -eq 'Amd64') 'validation assembly targets AMD64'
    Write-Host "Parallel scanner JIT validation: $jit methods/constructors."
    if (Test-Path -LiteralPath $fixture) { throw "Refusing to reuse fixture: $fixture" }
    $null = [IO.Directory]::CreateDirectory($fixture)
    $root = Join-Path $fixture 'wide'
    $null = [IO.Directory]::CreateDirectory($root)
    [IO.File]::WriteAllBytes("$root\own.bin", [byte[]]::new(11))
    [IO.File]::WriteAllBytes("$root\zero.bin", [byte[]]::new(0))
    [long]$knownBytes = 11
    [long]$knownFiles = 2
    for ($i = 0; $i -lt 128; $i++) {
        $child = Join-Path $root ('child-{0:D3}' -f $i)
        $null = [IO.Directory]::CreateDirectory($child)
        for ($j = 0; $j -lt 16; $j++) {
            $size = 1 + ($i % 13) + $j
            [IO.File]::WriteAllBytes("$child\$j.bin", [byte[]]::new($size))
            $knownBytes += $size
            $knownFiles++
        }
    }
    $deep = "$root\child-000"
    $depth = [Math]::Min(55, [int][Math]::Floor((240 - $deep.Length) / 2))
    Assert-Parallel ($depth -ge 30) 'deep fixture has at least thirty nested directories'
    for ($i = 0; $i -lt $depth; $i++) {
        $deep += '\d'
        $null = [IO.Directory]::CreateDirectory($deep)
    }
    [IO.File]::WriteAllBytes("$deep\x", [byte[]]::new(19))
    $knownBytes += 19
    $knownFiles++
    [IO.File]::SetAttributes("$root\child-001\0.bin", [IO.FileAttributes]'Hidden,System')
    $legacy = [FolderMap.Scanner]::Scan($root, $null)
    $signature = Tree-Signature $legacy.Root
    Assert-Parallel ($legacy.Root.TotalBytes -eq $knownBytes -and $legacy.Root.TotalFiles -eq $knownFiles) 'fixture totals are independently known'
    Assert-Parallel ($legacy.Root.FolderCount -eq 128 + $depth) 'all immediate/deep folders are counted'
    foreach ($limit in @(1, 2, 4, 32)) {
        $result = [FolderMap.ParallelScanner]::ScanWithLimit($root, $null, $null, $limit)
        Assert-Parallel ((Tree-Signature $result.Root) -ceq $signature) "limit $limit matches legacy totals, sorted structure, direct counts, hidden/system files"
        Assert-Parallel ($result.Root.DirectBytes -eq 11 -and $result.Root.DirectFiles -eq 2) 'root own files counted once'
        Assert-Parallel ($result.IssueCount -eq 0 -and $result.Issues.Count -eq 0) 'readable wide tree has no false diagnostics'
    }
    Assert-Parallel ((Tree-Signature ([FolderMap.ParallelScanner]::Scan($root, $null)).Root) -ceq $signature) 'default Scan matches sequential scanner'
    $defaultLimit = $parallelType.GetMethod('DefaultLimit', $internalStatic).Invoke($null, @())
    Assert-Parallel ($defaultLimit -eq [Math]::Min([Environment]::ProcessorCount, 4)) 'default worker limit is min(processors, 4)'
    foreach ($badLimit in @(0, -1, 33, [int]::MinValue, [int]::MaxValue)) {
        Assert-Throws { [FolderMap.ParallelScanner]::ScanWithLimit($root, $null, $null, $badLimit) } ([ArgumentOutOfRangeException]) "invalid limit $badLimit"
    }
    foreach ($badPath in @('', '   ', "$fixture\missing", "$root\own.bin")) {
        $expected = if ($badPath -eq "$fixture\missing") { [IO.IOException] } else { [ArgumentException] }
        Assert-Throws { [FolderMap.ParallelScanner]::Scan($badPath, $null) } $expected 'invalid root remains a fatal error'
    }
    $empty = "$fixture\empty"
    $null = [IO.Directory]::CreateDirectory($empty)
    $emptyResult = [FolderMap.ParallelScanner]::ScanWithLimit($empty, $null, $null, 32)
    Assert-Parallel ($emptyResult.Root.TotalBytes -eq 0 -and $emptyResult.Root.FolderCount -eq 0) 'empty root is supported'
    foreach ($childCount in @(0, 1)) {
        if ($childCount) {
            $null = [IO.Directory]::CreateDirectory("$empty\only")
            [IO.File]::WriteAllBytes("$empty\only\data", [byte[]]::new(7))
        } else { [IO.File]::WriteAllBytes("$empty\own", [byte[]]::new(3)) }
        $shallow = [FolderMap.Scanner]::ScanShallow($empty, $null, $null)
        $work = New-Work $shallow
        $null = $start.Invoke($work, [object[]]@(32))
        $null = $join.Invoke($work, @())
        $result = $merge.Invoke($null, [object[]]@($shallow, $work, $null))
        Assert-Drained $work
        Assert-Parallel ((Work-Field $work 'Tasks').Length -eq $childCount) 'actual lane count never exceeds eligible child count'
        Assert-Parallel ($result.Root.TotalBytes -eq 3 + 7 * $childCount) 'zero/one-child root counts own files correctly'
    }

    $identity = [FolderMap.NtfsJournal]::GetIdentity($root)
    $literalRoot = "$fixture\literal"
    $literalChild = "$literalRoot\%$literalEnvironment%"
    $null = [IO.Directory]::CreateDirectory("$literalChild\deep")
    $null = [IO.Directory]::CreateDirectory("$literalRoot\replacement")
    [IO.File]::WriteAllBytes("$literalChild\own", [byte[]]::new(41))
    [IO.File]::WriteAllBytes("$literalChild\deep\own", [byte[]]::new(43))
    [IO.File]::WriteAllBytes("$literalRoot\replacement\own", [byte[]]::new(47))
    [Environment]::SetEnvironmentVariable($literalEnvironment, 'replacement', 'Process')
    $literalLegacyRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $literalLegacy = [FolderMap.Scanner]::ScanObserved($literalRoot, $null, $literalLegacyRecorder)
    $literalSignature = Tree-Signature $literalLegacy.Root $literalLegacyRecorder
    foreach ($limit in @(1, 4)) {
        $literalRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
        $literal = [FolderMap.ParallelScanner]::ScanWithLimit($literalRoot, $null, $literalRecorder, $limit)
        Assert-Parallel ((Tree-Signature $literal.Root $literalRecorder) -ceq $literalSignature) 'literal environment-variable child names are never expanded a second time'
        Assert-Parallel ($literal.Root.TotalBytes -eq 131 -and $literal.IssueCount -eq 0) 'literal-path fallback preserves logical totals and metadata'
    }
    [Environment]::SetEnvironmentVariable($rootEnvironment, $literalChild, 'Process')
    $aliased = [FolderMap.ParallelScanner]::Scan("%$rootEnvironment%", $null)
    Assert-Parallel ($aliased.Root.TotalBytes -eq 84 -and $aliased.Root.FullPath -ceq $literalChild -and $aliased.IssueCount -eq 0) 'an expanded root containing literal percent names is not re-expanded by child jobs'

    $legacyRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $observedLegacy = [FolderMap.Scanner]::ScanObserved($root, $null, $legacyRecorder)
    $metadataSignature = Tree-Signature $observedLegacy.Root $legacyRecorder
    foreach ($limit in @(1, 4, 32)) {
        $recorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
        $observed = [FolderMap.ParallelScanner]::ScanWithLimit($root, $null, $recorder, $limit)
        Assert-Parallel ((Tree-Signature $observed.Root $recorder) -ceq $metadataSignature) "limit $limit preserves per-node identities and recorder metadata"
        Assert-Parallel ($recorder.MetadataFailures -eq 0) 'parallel metadata collection is uncorrupted'
    }
    $recorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $observed = [FolderMap.ParallelScanner]::ScanObserved($root, $null, $recorder)
    Assert-Parallel ((Tree-Signature $observed.Root $recorder) -ceq $metadataSignature) 'default observed API records the same metadata'

    # Instance-scoped gate uses a native delegate, never a PowerShell callback on pool threads.
    $poolRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $poolRecorder)
    $recordsField = $poolRecorder.GetType().GetField('records', $internalInstance)
    $discoveryRecords = $recordsField.GetValue($poolRecorder).Count
    $activeWork = New-Work $shallow $poolRecorder
    $uniqueRecorders = [Collections.Generic.HashSet[object]]::new()
    foreach ($job in (Work-Field $activeWork 'Jobs')) {
        $childRecorder = Job-Field $job 'Recorder'
        Assert-Parallel (-not [object]::ReferenceEquals($poolRecorder, $childRecorder) -and $uniqueRecorders.Add($childRecorder)) 'every child has a distinct recorder, separate from the parent'
        Assert-Parallel ($recordsField.GetValue($childRecorder).Count -eq 0) 'fork does not share the parent dictionary'
    }
    $gate = [Threading.ManualResetEventSlim]::new($false)
    $waitAction = [Delegate]::CreateDelegate([Action], $gate, $gate.GetType().GetMethod('Wait', [type[]]@()))
    $workType.GetField('BeforeJob', $internalInstance).SetValue($activeWork, $waitAction)
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Wait-ForJobs $activeWork 4
    Assert-Parallel ((Work-Field $activeWork 'Tasks').Length -eq 4) '128 child jobs use exactly four pool tasks'
    Assert-Parallel ((Work-Field $activeWork 'PeakJobs') -eq 4) 'four independent subtree jobs are owned concurrently'
    $gate.Set()
    $null = $join.Invoke($activeWork, @())
    Assert-Drained $activeWork
    Assert-Parallel ($recordsField.GetValue($poolRecorder).Count -eq $discoveryRecords) 'worker scans never mutate the parent recorder'
    Assert-Parallel ((Work-Field $activeWork 'CompletedJobs') -eq 128) 'the fixed lanes drain every immediate child exactly once'
    $result = $merge.Invoke($null, [object[]]@($shallow, $activeWork, $poolRecorder))
    Assert-Parallel ((Tree-Signature $result.Root) -ceq $signature) 'instrumented pool preserves full traversal semantics'
    Assert-Parallel ((Tree-Signature $result.Root $poolRecorder) -ceq $metadataSignature) 'serial metadata merge exports only the completed result nodes'
    Write-Host "Concurrency: 128 immediate children, 4 tasks, peak 4 concurrent child jobs; no nested parallelism."
    $activeWork = $null
    $gate.Dispose()
    $gate = $null

    $cancel = [ComponentModel.BackgroundWorker]::new()
    $cancel.WorkerSupportsCancellation = $true
    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $null)
    $activeWork = New-Work $shallow $null $cancel
    $gate = [Threading.ManualResetEventSlim]::new($false)
    $workType.GetField('BeforeJob', $internalInstance).SetValue($activeWork,
        [Delegate]::CreateDelegate([Action], $gate, $gate.GetType().GetMethod('Wait', [type[]]@())))
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Wait-ForJobs $activeWork 4
    $cancel.CancelAsync()
    $gate.Set()
    Assert-Throws { $join.Invoke($activeWork, @()) } ([OperationCanceledException]) 'cancellation in all active lanes is unwrapped'
    Assert-Drained $activeWork
    Assert-Parallel ((Work-Field $activeWork 'CompletedJobs') -eq 0) 'cancelled gated jobs never publish success'
    Assert-Throws { [FolderMap.ParallelScanner]::Scan($root, $cancel) } ([OperationCanceledException]) 'pre-requested cancellation is honored'
    $activeWork = $null
    $gate.Dispose()
    $gate = $null
    $cancel.Dispose()
    $cancel = $null

    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $null)
    $activeWork = New-Work $shallow
    $gate = [Threading.ManualResetEventSlim]::new($false)
    $workType.GetField('BeforeJob', $internalInstance).SetValue($activeWork,
        [Delegate]::CreateDelegate([Action], $gate, $gate.GetType().GetMethod('Wait', [type[]]@())))
    $gate.Dispose()
    $gate = $null
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Assert-Throws { $join.Invoke($activeWork, @()) } ([ObjectDisposedException]) 'unexpected worker failures propagate as their original type'
    Assert-Drained $activeWork
    $activeWork = $null

    $cancel = [ComponentModel.BackgroundWorker]::new()
    $cancel.WorkerSupportsCancellation = $true
    $cancel.WorkerReportsProgress = $true
    # A handwritten IL callback is safe on pool threads (a PowerShell scriptblock is not).
    $callback = [Reflection.Emit.DynamicMethod]::new('CancelFromScanProgress', [void],
        [type[]]@([object], [ComponentModel.ProgressChangedEventArgs]))
    $code = $callback.GetILGenerator()
    $code.Emit([Reflection.Emit.OpCodes]::Ldarg_0)
    $code.Emit([Reflection.Emit.OpCodes]::Castclass, [ComponentModel.BackgroundWorker])
    $code.Emit([Reflection.Emit.OpCodes]::Callvirt, [ComponentModel.BackgroundWorker].GetMethod('CancelAsync'))
    $code.Emit([Reflection.Emit.OpCodes]::Ret)
    $handler = $callback.CreateDelegate([ComponentModel.ProgressChangedEventHandler])
    $cancel.add_ProgressChanged($handler)
    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $null)
    $activeWork = New-Work $shallow $null $cancel
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Assert-Throws { $join.Invoke($activeWork, @()) } ([OperationCanceledException]) 'cancellation from inside real scanner traversal disposes enumerators'
    Assert-Drained $activeWork
    $activeWork = $null
    $cancel.remove_ProgressChanged($handler)
    $cancel.Dispose()
    $cancel = $null

    $overflowAction = [Reflection.Emit.DynamicMethod]::new('CheckedWorkerOverflow', [void], [type[]]@())
    $code = $overflowAction.GetILGenerator()
    $code.Emit([Reflection.Emit.OpCodes]::Ldc_I8, [long]::MaxValue)
    $code.Emit([Reflection.Emit.OpCodes]::Ldc_I4_1)
    $code.Emit([Reflection.Emit.OpCodes]::Conv_I8)
    $code.Emit([Reflection.Emit.OpCodes]::Add_Ovf)
    $code.Emit([Reflection.Emit.OpCodes]::Pop)
    $code.Emit([Reflection.Emit.OpCodes]::Ret)
    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $null)
    $activeWork = New-Work $shallow
    $workType.GetField('BeforeJob', $internalInstance).SetValue($activeWork, $overflowAction.CreateDelegate([Action]))
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Assert-Throws { $join.Invoke($activeWork, @()) } ([OverflowException]) 'checked overflow inside a worker is not reduced to a partial scan'
    Assert-Drained $activeWork
    $activeWork = $null

    $shallow = [FolderMap.Scanner]::ScanShallow($root, $null, $null)
    $activeWork = New-Work $shallow
    (Job-Field (Work-Field $activeWork 'Jobs')[0] 'Placeholder').FullPath += [char]0
    $null = $start.Invoke($activeWork, [object[]]@(4))
    Assert-Throws { $join.Invoke($activeWork, @()) } ([ArgumentException]) 'unrelated child argument errors are not swallowed by root-replacement recovery'
    Assert-Drained $activeWork
    Assert-Parallel ((Work-Field $activeWork 'CompletedJobs') -eq 127) 'unrelated lanes are drained before an unexpected child error escapes'
    $activeWork = $null

    $race = "$fixture\races"
    $null = [IO.Directory]::CreateDirectory("$race\live")
    [IO.File]::WriteAllBytes("$race\own", [byte[]]::new(5))
    [IO.File]::WriteAllBytes("$race\live\own", [byte[]]::new(9))
    for ($i = 0; $i -lt 205; $i++) { $null = [IO.Directory]::CreateDirectory(("$race\gone-{0:D3}" -f $i)) }
    $hasLink = New-Junction "$race\skip-link" $root
    $nestedLink = New-Junction "$race\live\loop" $race
    if ($hasLink) {
        Assert-Throws { [FolderMap.ParallelScanner]::Scan("$race\skip-link", $null) } ([NotSupportedException]) 'reparse root is rejected'
    }
    $recorder1 = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $recorder4 = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $shallow1 = [FolderMap.Scanner]::ScanShallow($race, $null, $recorder1)
    $shallow4 = [FolderMap.Scanner]::ScanShallow($race, $null, $recorder4)
    Assert-Parallel ((Work-Field (New-Work $shallow4) 'Jobs').Length -eq 206) 'discovered reparse children are never scheduled'
    for ($i = 0; $i -lt 205; $i++) { [IO.Directory]::Delete(("$race\gone-{0:D3}" -f $i)) }
    $race1 = Run-Work $shallow1 $recorder1 1
    $race4 = Run-Work $shallow4 $recorder4 4
    Assert-Parallel ((Tree-Signature $race1.Root $recorder1) -ceq (Tree-Signature $race4.Root $recorder4)) 'deterministically vanished children preserve identical partial trees/metadata across limits'
    Assert-Parallel ($race4.Root.TotalBytes -eq 14 -and $race4.Root.TotalFiles -eq 2) 'vanished branches do not abort unrelated readable files'
    Assert-Parallel ($race4.IssueCount -eq 205 + [int]$hasLink + [int]$nestedLink -and $race4.Root.IssueCount -eq $race4.IssueCount) 'shallow and nested child reparse issues are not double aggregated'
    Assert-Parallel ($race4.Issues.Count -eq 200 -and ($race4.Issues -join '|') -ceq ($race1.Issues -join '|')) 'first-200 diagnostics are stable in original child order'
    $firstMissing = [int]$hasLink
    Assert-Parallel ($race4.Issues[$firstMissing].Contains('gone-000') -and $race4.Issues[199].Contains(('gone-{0:D3}' -f (199 - $firstMissing)))) 'diagnostic samples are not completion-order dependent'
    Assert-Parallel ($recorder4.Export($race4.Root).DirectIssueCount -eq 0) 'root observer diagnostics remain direct, not aggregated'
    foreach ($node in $race4.Root.Children) {
        if ($node.Name.StartsWith('gone-')) {
            $entry = $recorder4.Export($node)
            Assert-Parallel ($entry.Retry -and $entry.FileId -eq 0 -and $entry.DirectIssueCount -eq 1 -and $entry.Issues.Count -eq 1) 'failed child uses fresh incomplete metadata rather than its stale discovery placeholder'
        }
    }
    $changed = "$fixture\changed"
    $null = [IO.Directory]::CreateDirectory("$changed\was-folder")
    $changedRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $shallow = [FolderMap.Scanner]::ScanShallow($changed, $null, $changedRecorder)
    [IO.Directory]::Delete("$changed\was-folder")
    [IO.File]::WriteAllBytes("$changed\was-folder", [byte[]]::new(23))
    $result = Run-Work $shallow $changedRecorder 4
    Assert-Parallel ($result.Root.TotalBytes -eq 0 -and $result.IssueCount -eq 1 -and $result.Issues[0].Contains('no longer a directory')) 'child replaced by a file remains an incomplete directory, not a fatal root error'
    Assert-Parallel $changedRecorder.Export($result.Root.Children[0]).Retry 'file replacement has retry metadata'
    [IO.File]::Delete("$changed\was-folder")
    $null = [IO.Directory]::CreateDirectory("$changed\was-folder")
    $changedRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $shallow = [FolderMap.Scanner]::ScanShallow($changed, $null, $changedRecorder)
    [IO.Directory]::Delete("$changed\was-folder")
    if (New-Junction "$changed\was-folder" $root) {
        $result = Run-Work $shallow $changedRecorder 4
        $entry = $changedRecorder.Export($result.Root.Children[0])
        Assert-Parallel ($result.Root.TotalBytes -eq 0 -and $result.IssueCount -eq 1 -and $result.Issues[0].Contains('reparse')) 'child replaced by a junction is not followed'
        Assert-Parallel ($entry.Reparse -and $entry.Retry -and $entry.DirectIssueCount -eq 1) 'reparse replacement has matching retryable metadata'
    }

    $deniedRoot = "$fixture\denied"
    $aclPath = "$deniedRoot\blocked"
    $null = [IO.Directory]::CreateDirectory($aclPath)
    $null = [IO.Directory]::CreateDirectory("$deniedRoot\readable")
    [IO.File]::WriteAllBytes("$aclPath\unread.bin", [byte[]]::new(17))
    [IO.File]::WriteAllBytes("$deniedRoot\readable\ok.bin", [byte[]]::new(13))
    $deniedReady = $false
    try {
        $originalAcl = [IO.Directory]::GetAccessControl($aclPath)
        $deniedAcl = [IO.Directory]::GetAccessControl($aclPath)
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            [Security.Principal.WindowsIdentity]::GetCurrent().User,
            [Security.AccessControl.FileSystemRights]::ListDirectory,
            [Security.AccessControl.AccessControlType]::Deny)
        $deniedAcl.AddAccessRule($rule)
        [IO.Directory]::SetAccessControl($aclPath, $deniedAcl)
        try { $null = [IO.Directory]::GetFileSystemEntries($aclPath) }
        catch { $deniedReady = $true }
    } catch { Skip-Parallel "Directory ACL denial could not be configured: $($_.Exception.Message)" }
    if ($deniedReady) {
        $deniedRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
        $result = [FolderMap.ParallelScanner]::ScanWithLimit($deniedRoot, $null, $deniedRecorder, 4)
        Assert-Parallel ($result.Root.TotalBytes -eq 13 -and $result.IssueCount -eq 1) 'unreadable child is partial while other lanes continue'
        $blocked = @($result.Root.Children | Where-Object Name -eq 'blocked')[0]
        Assert-Parallel ($deniedRecorder.Export($blocked).Retry -and $blocked.IssueCount -eq 1) 'unreadable child is retryable'
    } else { Skip-Parallel 'Current token bypasses the fixture ListDirectory denial.' }
    Restore-FixtureAcl

    $hardRoot = "$fixture\hardlinks"
    $null = [IO.Directory]::CreateDirectory("$hardRoot\a")
    $null = [IO.Directory]::CreateDirectory("$hardRoot\b")
    [IO.File]::WriteAllBytes("$hardRoot\a\source", [byte[]]::new(31))
    $hardReady = $false
    try {
        $null = New-Item -ItemType HardLink -Path "$hardRoot\b\second" -Target "$hardRoot\a\source"
        $hardReady = $true
    } catch { Skip-Parallel "Hardlink creation unavailable: $($_.Exception.Message)" }
    if ($hardReady) {
        $hardRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
        $result = [FolderMap.ParallelScanner]::ScanWithLimit($hardRoot, $null, $hardRecorder, 4)
        Assert-Parallel ($result.Root.TotalBytes -eq 62 -and $result.Root.TotalFiles -eq 2) 'hardlinks in separate lanes are counted by path'
        $a = $hardRecorder.Export($result.Root.Children[0])
        $b = $hardRecorder.Export($result.Root.Children[1])
        Assert-Parallel ($a.LinkedFiles.Count -eq 1 -and $b.LinkedFiles.Count -eq 1 -and $a.LinkedFiles[0] -eq $b.LinkedFiles[0]) 'each worker preserves hardlink metadata for its own parent'
    }

    $largeRoot = "$fixture\large"
    $null = [IO.Directory]::CreateDirectory("$largeRoot\child")
    [IO.File]::WriteAllBytes("$largeRoot\own", [byte[]]::new(3))
    $largeFile = "$largeRoot\child\sparse"
    [IO.File]::WriteAllBytes($largeFile, [byte[]]::new(0))
    $fsutil = Join-Path $env:WINDIR 'System32\fsutil.exe'
    if (Test-Path -LiteralPath $fsutil -PathType Leaf) {
        $sparseOutput = & $fsutil sparse setflag $largeFile 2>&1
        if ($LASTEXITCODE -eq 0 -and ([IO.File]::GetAttributes($largeFile) -band [IO.FileAttributes]::SparseFile)) {
            $stream = [IO.File]::OpenWrite($largeFile)
            try { $stream.SetLength([long]2147483771) } finally { $stream.Dispose() }
            $result = [FolderMap.ParallelScanner]::ScanWithLimit($largeRoot, $null, $null, 4)
            Assert-Parallel ($result.Root.TotalBytes -eq [long]2147483774 -and $result.Root.TotalFiles -eq 2) 'greater-than-2GiB logical lengths survive worker publication and aggregation'
        } else { Skip-Parallel "Sparse files unavailable; no large allocation attempted: $sparseOutput" }
    } else { Skip-Parallel 'fsutil is unavailable; no large allocation attempted.' }

    $parentRecorder = [FolderMap.CacheRecorder]::new($identity.VolumeSerial)
    $fork = $parentRecorder.Fork()
    $synthetic = [FolderMap.FolderNode]::new("$fixture\synthetic", $null)
    $fork.Issue($synthetic, 'first issue')
    $fork.MetadataFailures = 2
    $fork.FirstMetadataFailure = 'first metadata failure'
    $parentRecorder.FirstMetadataFailure = ''
    $parentRecorder.Merge($fork)
    $fork.Issue($synthetic, 'later independent issue')
    Assert-Parallel ($parentRecorder.Export($synthetic).DirectIssueCount -eq 1) 'merged recorders do not alias mutable per-node metadata'
    Assert-Parallel ($parentRecorder.MetadataFailures -eq 2 -and $parentRecorder.FirstMetadataFailure -ceq 'first metadata failure') 'merge keeps first nonempty failure and checked count'
    $nextFork = $parentRecorder.Fork()
    $nextFork.MetadataFailures = 3
    $nextFork.FirstMetadataFailure = 'second metadata failure'
    $parentRecorder.Merge($nextFork)
    Assert-Parallel ($parentRecorder.MetadataFailures -eq 5 -and $parentRecorder.FirstMetadataFailure -ceq 'first metadata failure') 'later failure does not overwrite first'
    Assert-Throws { $parentRecorder.Merge($null) } ([ArgumentNullException]) 'null recorder merge'
    Assert-Throws { $parentRecorder.Merge($parentRecorder) } ([ArgumentException]) 'self recorder merge'
    $different = [FolderMap.CacheRecorder]::new($identity.VolumeSerial -bxor 1)
    Assert-Throws { $parentRecorder.Merge($different) } ([ArgumentException]) 'different-volume recorder merge'
    $parentRecorder.MetadataFailures = [int]::MaxValue
    Assert-Throws { $parentRecorder.Merge($nextFork) } ([OverflowException]) 'metadata failure overflow'
    foreach ($counter in @('TotalBytes', 'TotalFiles', 'FolderCount', 'IssueCount')) {
        $overflowRoot = [FolderMap.FolderNode]::new($fixture, $null)
        $placeholder = [FolderMap.FolderNode]::new("$fixture\overflow", $overflowRoot)
        $overflowRoot.Children.Add($placeholder)
        $shallow = [FolderMap.ScanResult]::new($overflowRoot)
        $work = New-Work $shallow
        $child = [FolderMap.FolderNode]::new("$fixture\overflow", $null)
        $childResult = [FolderMap.ScanResult]::new($child)
        switch ($counter) {
            'TotalBytes' { $overflowRoot.DirectBytes = [long]::MaxValue; $child.TotalBytes = 1 }
            'TotalFiles' { $overflowRoot.DirectFiles = [long]::MaxValue; $child.TotalFiles = 1 }
            'FolderCount' { $child.FolderCount = [long]::MaxValue }
            'IssueCount' { $shallow.IssueCount = [int]::MaxValue; $overflowRoot.IssueCount = [int]::MaxValue; $childResult.IssueCount = 1; $child.IssueCount = 1 }
        }
        $job = (Work-Field $work 'Jobs')[0]
        $job.GetType().GetField('Result', $internalInstance).SetValue($job, $childResult)
        Assert-Throws { $merge.Invoke($null, [object[]]@($shallow, $work, $null)) } ([OverflowException]) "checked $counter merge overflow"
    }

    $measurements = [Collections.Generic.List[string]]::new()
    foreach ($mode in @('legacy', '1', '2', '4', '32')) {
        $clock = [Diagnostics.Stopwatch]::StartNew()
        if ($mode -eq 'legacy') { $bench = [FolderMap.Scanner]::Scan($root, $null) }
        else { $bench = [FolderMap.ParallelScanner]::ScanWithLimit($root, $null, $null, [int]$mode) }
        $clock.Stop()
        Assert-Parallel ($bench.Root.TotalBytes -eq $knownBytes -and $bench.Root.TotalFiles -eq $knownFiles) 'benchmark remains correct'
        $measurements.Add(('{0}={1:N1}ms' -f $mode, $clock.Elapsed.TotalMilliseconds))
    }
    Write-Host "Benchmark (128 children, $knownFiles files, $knownBytes bytes; warm filesystem, no speed assertion): $($measurements -join ', ')"
} finally {
    [Environment]::SetEnvironmentVariable($literalEnvironment, $null, 'Process')
    [Environment]::SetEnvironmentVariable($rootEnvironment, $null, 'Process')
    if ($null -ne $gate) { $gate.Set() }
    if ($null -ne $activeWork) {
        try { $null = $join.Invoke($activeWork, @()) } catch { Write-Verbose "Joined failing test lanes: $_" }
    }
    if ($null -ne $gate) { $gate.Dispose() }
    if ($null -ne $cancel) { $cancel.Dispose() }
    Restore-FixtureAcl
    foreach ($link in $links) { [IO.Directory]::Delete($link, $false) }
    if ([IO.File]::Exists("$fixture\wide\child-001\0.bin")) {
        [IO.File]::SetAttributes("$fixture\wide\child-001\0.bin", [IO.FileAttributes]::Normal)
    }
    if ([IO.Directory]::Exists($fixture)) { [IO.Directory]::Delete($fixture, $true) }
}
Write-Host "Parallel scanner tests: $passed passed; $skipped skipped."
