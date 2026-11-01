[CmdletBinding()]
param(
    [string]$AssemblyPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not [Environment]::Is64BitProcess -or $PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run these tests with 64-bit Windows PowerShell (.NET Framework), not PowerShell Core.'
}

[AppContext]::SetSwitch('Switch.System.IO.UseLegacyPathHandling', $false)
[AppContext]::SetSwitch('Switch.System.IO.BlockLongPaths', $false)
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$assembly = [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$scanner = $assembly.GetType('FolderMap.Scanner', $true)
$nodeType = $assembly.GetType('FolderMap.FolderNode', $true)
$contextType = $assembly.GetType('FolderMap.ScanContext', $true)
$staticPrivate = [Reflection.BindingFlags]'Static,NonPublic'
$instanceInternal = [Reflection.BindingFlags]'Instance,NonPublic'
$scanMethod = $scanner.GetMethod('Scan', [Reflection.BindingFlags]'Static,Public')
$aggregateMethod = $scanner.GetMethod('Aggregate', $staticPrivate)
$recordIssueMethod = $scanner.GetMethod('RecordIssue', $staticPrivate)
$visitEntryMethod = $scanner.GetMethod('VisitEntry', $staticPrivate)
$visitDirectoryMethod = $scanner.GetMethod('VisitDirectory', $staticPrivate)
$pulseMethod = $scanner.GetMethod('Pulse', $staticPrivate)
$contextConstructor = $contextType.GetConstructors($instanceInternal)[0]
$passed = 0
$skipped = 0
$directoryLinks = [Collections.Generic.List[string]]::new()
$fileLinks = [Collections.Generic.List[string]]::new()
$deepDirectories = [Collections.Generic.List[string]]::new()
[string]$fixture = Join-Path (Split-Path -Parent $PSScriptRoot) ('.scanner-fixture-' + [Guid]::NewGuid().ToString('N'))
$environmentName = 'FOLDERMAP_TEST_' + [Guid]::NewGuid().ToString('N')

function Assert-Scan([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Get-UnderlyingException([Exception]$Exception) {
    while (($Exception -is [Reflection.TargetInvocationException] -or
        $Exception -is [Management.Automation.MethodInvocationException]) -and
        $null -ne $Exception.InnerException) {
        $Exception = $Exception.InnerException
    }
    return $Exception
}

function Assert-Throws([scriptblock]$Action, [Type]$Type, [string]$Message) {
    $caught = $null
    try { $null = & $Action }
    catch { $caught = Get-UnderlyingException $_.Exception }
    Assert-Scan ($null -ne $caught) "$Message (must throw)"
    Assert-Scan ($Type.IsInstanceOfType($caught)) "$Message (expected $($Type.FullName), got $($caught.GetType().FullName): $($caught.Message))"
    Assert-Scan (-not [string]::IsNullOrWhiteSpace($caught.Message)) "$Message (descriptive exception)"
}

function Skip-Scan([string]$Reason) {
    $script:skipped++
    Write-Host "SKIP: $Reason"
}

function Invoke-Scan([AllowNull()][string]$Path, [ComponentModel.BackgroundWorker]$Worker = $null) {
    return $scanMethod.Invoke($null, [object[]]@($Path, $Worker))
}

function New-Node([string]$Path, $Parent = $null) {
    return [Activator]::CreateInstance($nodeType, [object[]]@($Path, $Parent))
}

function New-Context($Root, [ComponentModel.BackgroundWorker]$Worker = $null) {
    return $contextConstructor.Invoke([object[]]@($Root, $Worker))
}

function Context-Field($Context, [string]$Name) {
    return $contextType.GetField($Name, $instanceInternal).GetValue($Context)
}

function Write-FixtureFile([string]$Path, [int]$Length) {
    [IO.File]::WriteAllBytes($Path, [byte[]]::new($Length))
}

function Get-Child($Node, [string]$Name) {
    $found = @($Node.Children | Where-Object { $_.Name -ceq $Name })
    Assert-Scan ($found.Count -eq 1) "one child named '$Name'"
    return $found[0]
}

function Assert-Tree($Root) {
    $nodes = [Collections.Generic.Stack[object]]::new()
    $nodes.Push($Root)
    while ($nodes.Count -gt 0) {
        $node = $nodes.Pop()
        $bytes = $node.DirectBytes
        $files = $node.DirectFiles
        [long]$folders = 0
        [int]$childIssues = 0
        for ($i = 0; $i -lt $node.Children.Count; $i++) {
            $child = $node.Children[$i]
            Assert-Scan ([object]::ReferenceEquals($child.Parent, $node)) 'child parent identity'
            Assert-Scan ($child.FullPath.StartsWith($node.FullPath + '\', [StringComparison]::OrdinalIgnoreCase)) 'child full path belongs to parent'
            $bytes += $child.TotalBytes
            $files += $child.TotalFiles
            $folders += 1 + $child.FolderCount
            $childIssues += $child.IssueCount
            $nodes.Push($child)
            if ($i -gt 0) {
                $previous = $node.Children[$i - 1]
                Assert-Scan ($previous.TotalBytes -ge $child.TotalBytes) 'children sorted by descending aggregated bytes'
                if ($previous.TotalBytes -eq $child.TotalBytes) {
                    Assert-Scan ([StringComparer]::OrdinalIgnoreCase.Compare($previous.Name, $child.Name) -le 0) 'equal-size children sorted by ordinal-ignore-case name'
                }
            }
        }
        Assert-Scan ($node.TotalBytes -eq $bytes) 'recursive bytes include own-file bytes exactly once'
        Assert-Scan ($node.TotalFiles -eq $files) 'recursive file count includes direct files'
        Assert-Scan ($node.FolderCount -eq $folders) 'folder count includes all descendants, not self'
        Assert-Scan ($node.IssueCount -ge $childIssues) 'recursive issue counts include children'
        Assert-Scan ($node.DirectBytes -ge 0 -and $node.DirectFiles -ge 0) 'direct counters are nonnegative'
    }
}

function Try-DirectoryLink([string]$Path, [string]$Target) {
    try {
        $null = New-Item -ItemType Junction -Path $Path -Target $Target
        $directoryLinks.Add($Path)
    } catch {
        Skip-Scan "Directory junction creation is unavailable: $($_.Exception.Message)"
        return $false
    }
    Assert-Scan (([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'test junction actually has the reparse-point attribute'
    return $true
}

try {
    $allMembers = [Reflection.BindingFlags]'DeclaredOnly,Public,NonPublic,Static,Instance'
    $jitCount = 0
    foreach ($typeName in @('FolderMap.FolderNode', 'FolderMap.ScanResult', 'FolderMap.ScanContext', 'FolderMap.FolderNodeComparer', 'FolderMap.Scanner')) {
        $type = $assembly.GetType($typeName, $true)
        foreach ($method in (@($type.GetConstructors($allMembers)) + @($type.GetMethods($allMembers)))) {
            [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
            Assert-Scan ($null -ne $method.GetMethodBody()) "JIT-validated IL body: $typeName.$($method.Name)"
            $jitCount++
        }
    }
    Write-Host "Scanner JIT validation: $jitCount methods and constructors prepared."
    if ([IO.Directory]::Exists($fixture) -or [IO.File]::Exists($fixture)) {
        throw "Refusing to reuse an existing fixture path: $fixture"
    }
    $null = [IO.Directory]::CreateDirectory($fixture)
    [string]$basic = Join-Path $fixture 'basic'
    $unicodeName = ([string][char]0x65E5) + [char]0x672C + '-' + [char]0x03A9 + '-' + [char]0x00E9
    foreach ($relative in @('basic', 'basic\alpha', 'basic\alpha\inner', 'basic\Beta', 'basic\empty', 'basic\zero', "basic\$unicodeName")) {
        $null = [IO.Directory]::CreateDirectory((Join-Path $fixture $relative))
    }
    Write-FixtureFile (Join-Path $basic 'own.bin') 11
    Write-FixtureFile (Join-Path $basic 'own-zero.bin') 0
    Write-FixtureFile (Join-Path $basic 'alpha\own.bin') 17
    Write-FixtureFile (Join-Path $basic 'alpha\inner\nested.bin') 29
    Write-FixtureFile (Join-Path $basic 'Beta\same-total.bin') 46
    Write-FixtureFile (Join-Path $basic 'zero\zero.bin') 0
    Write-FixtureFile (Join-Path $basic "$unicodeName\$unicodeName.bin") 7
    $result = Invoke-Scan $basic
    Assert-Scan ($result.Root.TotalBytes -eq 110) 'known nested fixture: 110 logical bytes'
    Assert-Scan ($result.Root.DirectBytes -eq 11) 'root own-file bytes are preserved'
    Assert-Scan ($result.Root.DirectFiles -eq 2 -and $result.Root.TotalFiles -eq 7) 'zero-byte files count as readable files'
    Assert-Scan ($result.Root.FolderCount -eq 6) 'known nested fixture: six descendant folders'
    Assert-Scan ($null -eq $result.Root.Parent) 'root has no parent'
    Assert-Scan ($result.IssueCount -eq 0 -and $result.Issues.Count -eq 0 -and $result.Root.IssueCount -eq 0) 'clean fixture has no diagnostics'
    Assert-Scan ($result.Root.Name -ceq 'basic' -and $result.Root.FullPath -ceq $basic) 'root name and normalized full path'
    $alpha = Get-Child $result.Root 'alpha'
    Assert-Scan ($alpha.DirectBytes -eq 17 -and $alpha.TotalBytes -eq 46) 'nested folder includes its own and child bytes'
    Assert-Scan ($alpha.DirectFiles -eq 1 -and $alpha.TotalFiles -eq 2 -and $alpha.FolderCount -eq 1) 'nested counters'
    $empty = Get-Child $result.Root 'empty'
    Assert-Scan ($empty.TotalBytes -eq 0 -and $empty.TotalFiles -eq 0 -and $empty.Children.Count -eq 0) 'empty directory is retained'
    $zero = Get-Child $result.Root 'zero'
    Assert-Scan ($zero.TotalBytes -eq 0 -and $zero.TotalFiles -eq 1) 'zero-byte file directory is retained'
    $unicode = Get-Child $result.Root $unicodeName
    Assert-Scan ($unicode.TotalBytes -eq 7 -and $unicode.FullPath.EndsWith($unicodeName, [StringComparison]::Ordinal)) 'Unicode paths survive discovery'
    Assert-Scan ($result.Root.Children[0].Name -ceq 'alpha' -and $result.Root.Children[1].Name -ceq 'Beta') 'sorting uses recursive size, then case-insensitive ordinal name'
    Assert-Tree $result.Root
    $shallow = [FolderMap.Scanner]::ScanShallow($basic, $null, $null)
    Assert-Scan ($shallow.Root.DirectBytes -eq 11 -and $shallow.Root.TotalBytes -eq 11) 'shallow scans measure only files directly in the directory'
    Assert-Scan ($shallow.Root.DirectFiles -eq 2 -and $shallow.Root.TotalFiles -eq 2) 'shallow file counts exclude descendants'
    Assert-Scan ($shallow.Root.Children.Count -eq 5 -and $shallow.Root.FolderCount -eq 5) 'shallow scans discover immediate child directories'
    Assert-Scan (@($shallow.Root.Children | Where-Object { $_.Children.Count -gt 0 -or $_.TotalBytes -ne 0 }).Count -eq 0) 'shallow scans do not enumerate child subtrees'
    $observed = [FolderMap.Scanner]::ScanObserved($basic, $null, $null)
    Assert-Scan ($observed.Root.TotalBytes -eq $result.Root.TotalBytes -and $observed.Root.TotalFiles -eq $result.Root.TotalFiles) 'the optional observer path preserves full-scan behavior'

    [Environment]::SetEnvironmentVariable($environmentName, $basic, 'Process')
    $normalized = Invoke-Scan ('  "%' + $environmentName + '%\"  ')
    Assert-Scan ($normalized.Root.FullPath -ceq $basic -and $normalized.Root.TotalBytes -eq 110) 'space/quote/environment/trailing-separator normalization'
    $dotPath = Invoke-Scan (Join-Path $basic '.\alpha\..')
    Assert-Scan ($dotPath.Root.FullPath -ceq $basic) 'relative path components are canonicalized'
    $volumeRoot = [IO.Path]::GetPathRoot($fixture)
    $driveNode = New-Node $volumeRoot
    Assert-Scan (-not [string]::IsNullOrWhiteSpace($driveNode.Name)) 'drive root constructor has a nonblank display name'

    Assert-Throws { $scanMethod.Invoke($null, [object[]]@($null, $null)) } ([ArgumentException]) 'null root rejected'
    Assert-Throws { Invoke-Scan '' } ([ArgumentException]) 'empty root rejected'
    Assert-Throws { Invoke-Scan '   ' } ([ArgumentException]) 'whitespace root rejected'
    Assert-Throws { Invoke-Scan ' "" ' } ([ArgumentException]) 'quoted blank root rejected'
    Assert-Throws { Invoke-Scan (Join-Path $fixture 'missing') } ([IO.IOException]) 'missing root rejected'
    Assert-Throws { Invoke-Scan (Join-Path $basic 'own.bin') } ([ArgumentException]) 'file root rejected'
    Assert-Throws { Invoke-Scan ($basic + [char]0 + 'invalid') } ([ArgumentException]) 'invalid root rejected'

    $cancel = [ComponentModel.BackgroundWorker]::new()
    try {
        $cancel.WorkerSupportsCancellation = $true
        $cancel.CancelAsync()
        Assert-Throws { Invoke-Scan $basic $cancel } ([OperationCanceledException]) 'pre-requested cancellation propagates'
        Assert-Throws { [FolderMap.Scanner]::ScanShallow($basic, $cancel, $null) } ([OperationCanceledException]) 'shallow scans honor cancellation'
    } finally { $cancel.Dispose() }
    $quietWorker = [ComponentModel.BackgroundWorker]::new()
    try {
        $quiet = Invoke-Scan $basic $quietWorker
        Assert-Scan ($quiet.Root.TotalBytes -eq 110) 'non-reporting non-null worker scans successfully'
    } finally { $quietWorker.Dispose() }

    $progressWorker = [ComponentModel.BackgroundWorker]::new()
    $progressEvents = [Collections.Generic.List[object]]::new()
    $progressHandler = [ComponentModel.ProgressChangedEventHandler]{
        param($sender, $eventArgs)
        $progressEvents.Add($eventArgs)
    }
    try {
        $progressWorker.WorkerReportsProgress = $true
        $progressWorker.add_ProgressChanged($progressHandler)
        $context = New-Context (New-Node $basic) $progressWorker
        $clock = Context-Field $context 'Clock'
        $clock.Stop()
        $lastProgressField = $contextType.GetField('LastProgress', $instanceInternal)
        $lastProgressField.SetValue($context, [long]($clock.ElapsedMilliseconds - 149))
        $null = $pulseMethod.Invoke($null, [object[]]@($context, $basic))
        Assert-Scan ($progressEvents.Count -eq 0) 'progress suppressed before the 150ms threshold'
        $lastProgressField.SetValue($context, [long]($clock.ElapsedMilliseconds - 150))
        $null = $pulseMethod.Invoke($null, [object[]]@($context, $basic))
        for ($i = 0; $i -lt 100; $i++) {
            $null = $pulseMethod.Invoke($null, [object[]]@($context, $basic))
        }
        Assert-Scan ($progressEvents.Count -eq 1) 'progress is throttled, not emitted per entry'
        Assert-Scan ($progressEvents[0].ProgressPercentage -eq 0 -and $progressEvents[0].UserState -ceq $basic) 'progress carries the current directory and no fake percentage'
        $progressWorker.WorkerReportsProgress = $false
        $lastProgressField.SetValue($context, [long]($clock.ElapsedMilliseconds - 150))
        $null = $pulseMethod.Invoke($null, [object[]]@($context, $basic))
        Assert-Scan ($progressEvents.Count -eq 1) 'WorkerReportsProgress=false suppresses reports'
    } finally {
        $progressWorker.remove_ProgressChanged($progressHandler)
        $progressWorker.Dispose()
    }

    $duringWorker = [ComponentModel.BackgroundWorker]::new()
    $duringHandler = [ComponentModel.ProgressChangedEventHandler]{
        param($sender, $eventArgs)
        $sender.CancelAsync()
    }
    $cancelFixture = Join-Path $fixture 'cancel-during'
    $null = [IO.Directory]::CreateDirectory($cancelFixture)
    Write-FixtureFile (Join-Path $cancelFixture 'a.bin') 3
    try {
        $duringWorker.WorkerSupportsCancellation = $true
        $duringWorker.WorkerReportsProgress = $true
        $duringWorker.add_ProgressChanged($duringHandler)
        Assert-Throws { Invoke-Scan $cancelFixture $duringWorker } ([OperationCanceledException]) 'cancellation from a progress callback unwinds directory enumeration'
    } finally {
        $duringWorker.remove_ProgressChanged($duringHandler)
        $duringWorker.Dispose()
    }
    [IO.Directory]::Delete($cancelFixture, $true)
    Assert-Scan (-not [IO.Directory]::Exists($cancelFixture)) 'canceled directory can immediately be removed'

    $sparseRoot = Join-Path $fixture 'sparse'
    $null = [IO.Directory]::CreateDirectory($sparseRoot)
    $sparseFile = Join-Path $sparseRoot 'large.bin'
    Write-FixtureFile $sparseFile 0
    $fsutil = Join-Path $env:WINDIR 'System32\fsutil.exe'
    if (Test-Path -LiteralPath $fsutil -PathType Leaf) {
        $sparseOutput = & $fsutil sparse setflag $sparseFile 2>&1
        if ($LASTEXITCODE -eq 0 -and ([IO.File]::GetAttributes($sparseFile) -band [IO.FileAttributes]::SparseFile) -ne 0) {
            $stream = [IO.File]::Open($sparseFile, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try { $stream.SetLength([long]2147483771) }
            finally { $stream.Dispose() }
            $large = Invoke-Scan $sparseRoot
            Assert-Scan ($large.Root.TotalBytes -eq [long]2147483771 -and $large.Root.DirectBytes -eq [long]2147483771) 'greater-than-2GiB sparse logical length is counted without Int32 truncation'
            Assert-Scan ($large.Root.TotalFiles -eq 1 -and $large.Root.IssueCount -eq 0) 'sparse file contributes one normal readable entry'
        } else {
            Skip-Scan "Sparse files unsupported or unavailable; large-file allocation was not attempted. fsutil: $sparseOutput"
        }
    } else { Skip-Scan 'fsutil unavailable; large-file allocation was not attempted.' }

    $hardRoot = Join-Path $fixture 'hardlinks'
    $null = [IO.Directory]::CreateDirectory($hardRoot)
    $hardSource = Join-Path $hardRoot 'source.bin'
    Write-FixtureFile $hardSource 31
    $hardLinkCreated = $false
    try {
        $null = New-Item -ItemType HardLink -Path (Join-Path $hardRoot 'second.bin') -Target $hardSource
        $hardLinkCreated = $true
    } catch { Skip-Scan "Hardlink creation is unavailable: $($_.Exception.Message)" }
    if ($hardLinkCreated) {
        $hard = Invoke-Scan $hardRoot
        Assert-Scan ($hard.Root.TotalBytes -eq 62 -and $hard.Root.TotalFiles -eq 2) 'hardlink directory entries are intentionally counted individually'
    }

    $linkRoot = Join-Path $fixture 'links'
    $null = [IO.Directory]::CreateDirectory($linkRoot)
    $null = [IO.Directory]::CreateDirectory((Join-Path $linkRoot 'nested'))
    Write-FixtureFile (Join-Path $linkRoot 'own.bin') 5
    Write-FixtureFile (Join-Path $linkRoot 'nested\own.bin') 9
    $loop = Join-Path $linkRoot 'nested\back-to-root'
    if (Try-DirectoryLink $loop $linkRoot) {
        $linked = Invoke-Scan $linkRoot
        Assert-Scan ($linked.Root.TotalBytes -eq 14 -and $linked.Root.TotalFiles -eq 2) 'junction loop is not followed or double counted'
        Assert-Scan ($linked.Root.FolderCount -eq 2) 'skipped linked directory remains a discovered folder node'
        $nested = Get-Child $linked.Root 'nested'
        $linkNode = Get-Child $nested 'back-to-root'
        Assert-Scan ($linkNode.TotalBytes -eq 0 -and $linkNode.TotalFiles -eq 0 -and $linkNode.Children.Count -eq 0) 'junction node is zero-size and unexpanded'
        Assert-Scan ($linked.IssueCount -eq 1 -and $linked.Root.IssueCount -eq 1 -and $nested.IssueCount -eq 1 -and $linkNode.IssueCount -eq 1) 'link diagnostic propagates through all ancestors exactly once'
        Assert-Scan ($linked.Issues.Count -eq 1 -and $linked.Issues[0].Contains($loop) -and $linked.Issues[0] -match 'reparse') 'link diagnostics include the skipped path and reason'
        Assert-Throws { Invoke-Scan $loop } ([NotSupportedException]) 'reparse-point root rejected'
        Assert-Throws { Invoke-Scan ($loop + '\') } ([NotSupportedException]) 'trailing separator cannot bypass root-link rejection'
        Assert-Tree $linked.Root
        $queuedLink = New-Node $loop
        $context = New-Context $queuedLink
        $null = $visitDirectoryMethod.Invoke($null, [object[]]@($queuedLink, $context))
        Assert-Scan ($queuedLink.IssueCount -eq 1 -and $queuedLink.Children.Count -eq 0) 'queued directory is rechecked for reparse-point replacement'
    }

    $fileLinkRoot = Join-Path $fixture 'file-links'
    $null = [IO.Directory]::CreateDirectory($fileLinkRoot)
    $fileTarget = Join-Path $fixture 'file-target.bin'
    Write-FixtureFile $fileTarget 23
    $fileLink = Join-Path $fileLinkRoot 'link.bin'
    $fileLinkCreated = $false
    try {
        $null = New-Item -ItemType SymbolicLink -Path $fileLink -Target $fileTarget
        $fileLinks.Add($fileLink)
        $fileLinkCreated = $true
    } catch { Skip-Scan "File symbolic links require supported privileges/developer mode: $($_.Exception.Message)" }
    if ($fileLinkCreated) {
        $symbolic = Invoke-Scan $fileLinkRoot
        Assert-Scan ($symbolic.Root.TotalBytes -eq 0 -and $symbolic.Root.TotalFiles -eq 0) 'file symbolic-link target is not counted'
        Assert-Scan ($symbolic.IssueCount -eq 1 -and $symbolic.Root.IssueCount -eq 1 -and $symbolic.Issues[0].Contains($fileLink)) 'file symbolic-link skip is diagnosed'
        Assert-Throws { Invoke-Scan $fileLink } ([NotSupportedException]) 'file symbolic-link root rejected'
    }

    $deepRoot = Join-Path $fixture 'deep'
    $null = [IO.Directory]::CreateDirectory($deepRoot)
    $depth = [Math]::Min(80, [Math]::Floor((240 - $deepRoot.Length) / 2))
    Assert-Scan ($depth -ge 32) 'fixture location leaves room for a meaningful short-path depth test'
    $leaf = $deepRoot
    for ($i = 0; $i -lt $depth; $i++) {
        $leaf += '\d'
        $null = [IO.Directory]::CreateDirectory($leaf)
        $deepDirectories.Add($leaf)
    }
    Write-FixtureFile (Join-Path $leaf 'x') 19
    $deep = Invoke-Scan $deepRoot
    Assert-Scan ($deep.Root.FolderCount -eq $depth -and $deep.Root.TotalBytes -eq 19 -and $deep.Root.TotalFiles -eq 1) "iterative traversal aggregates a $depth-level directory chain"
    $deepNode = $deep.Root
    for ($i = 0; $i -lt $depth; $i++) { $deepNode = $deepNode.Children[0] }
    Assert-Scan ($deepNode.DirectBytes -eq 19 -and $deepNode.Children.Count -eq 0) 'deep-chain leaf retains direct bytes'
    Assert-Tree $deep.Root

    $extendedRoot = '\\?\' + (Join-Path $fixture 'extended')
    $extendedLeaf = $extendedRoot
    $extendedReady = $false
    try {
        $null = [IO.Directory]::CreateDirectory($extendedRoot)
        for ($i = 0; $i -lt 320; $i++) {
            $extendedLeaf += '\d'
            $null = [IO.Directory]::CreateDirectory($extendedLeaf)
            $deepDirectories.Add($extendedLeaf)
        }
        [IO.File]::WriteAllBytes(($extendedLeaf + '\x'), [byte[]]::new(13))
        $extendedReady = $true
    } catch {
        $cause = Get-UnderlyingException $_.Exception
        if ($cause -is [IO.PathTooLongException] -or $cause -is [NotSupportedException] -or $cause -is [ArgumentException]) {
            Skip-Scan "Extended paths unsupported by this Windows PowerShell host: $($cause.Message)"
        } else { throw }
    }
    if ($extendedReady) {
        $extended = Invoke-Scan $extendedRoot
        Assert-Scan ($extended.Root.FolderCount -eq 320 -and $extended.Root.TotalBytes -eq 13 -and $extended.Root.TotalFiles -eq 1 -and $extended.IssueCount -eq 0) '320-level extended-path scan has no recursive-call-stack dependency'
    }

    $vanishedPath = Join-Path $fixture 'vanished.bin'
    Write-FixtureFile $vanishedPath 12
    $vanishedEntry = [IO.FileInfo]::new($vanishedPath)
    [IO.File]::Delete($vanishedPath)
    $diagnosticNode = New-Node $fixture
    $context = New-Context $diagnosticNode
    $null = $visitEntryMethod.Invoke($null, [object[]]@($vanishedEntry, $diagnosticNode, $context))
    $diagnosticResult = Context-Field $context 'Result'
    Assert-Scan ($diagnosticResult.IssueCount -eq 1 -and $diagnosticNode.DirectBytes -eq 0 -and $diagnosticNode.DirectFiles -eq 0) 'disappearing entry becomes a diagnostic, not stale file metadata'
    Assert-Scan ($diagnosticResult.Issues[0].Contains($vanishedPath)) 'disappearing-entry diagnostic identifies the path'
    $missingNode = New-Node (Join-Path $fixture 'vanished-directory')
    $context = New-Context $missingNode
    $null = $visitDirectoryMethod.Invoke($null, [object[]]@($missingNode, $context))
    Assert-Scan ($missingNode.IssueCount -eq 1 -and (Context-Field $context 'Result').IssueCount -eq 1) 'disappearing queued directory is retained with a diagnostic'
    $changedNode = New-Node (Join-Path $basic 'own.bin')
    $context = New-Context $changedNode
    $null = $visitDirectoryMethod.Invoke($null, [object[]]@($changedNode, $context))
    Assert-Scan ($changedNode.IssueCount -eq 1 -and $changedNode.TotalBytes -eq 0) 'queued directory replaced by a file is diagnosed'

    $diagnosticNode = New-Node $fixture
    $context = New-Context $diagnosticNode
    for ($i = 0; $i -lt 205; $i++) {
        $null = $recordIssueMethod.Invoke($null, [object[]]@($context, $diagnosticNode, $fixture, "issue-$i"))
    }
    $diagnosticResult = Context-Field $context 'Result'
    Assert-Scan ($diagnosticResult.IssueCount -eq 205 -and $diagnosticNode.IssueCount -eq 205) 'diagnostic counters include entries beyond the display cap'
    Assert-Scan ($diagnosticResult.Issues.Count -eq 200 -and $diagnosticResult.Issues[0].EndsWith('issue-0') -and $diagnosticResult.Issues[199].EndsWith('issue-199')) 'diagnostic list retains exactly the first 200 descriptions'
    $diagnosticResult.IssueCount = [int]::MaxValue
    Assert-Throws { $recordIssueMethod.Invoke($null, [object[]]@($context, $diagnosticNode, $fixture, 'overflow')) } ([OverflowException]) 'result diagnostic counter overflow propagates'

    foreach ($counter in @('TotalBytes', 'TotalFiles', 'FolderCount', 'IssueCount')) {
        $overflowRoot = New-Node $fixture
        $overflowChild = New-Node (Join-Path $fixture 'synthetic-child') $overflowRoot
        $overflowRoot.Children.Add($overflowChild)
        switch ($counter) {
            'TotalBytes' { $overflowRoot.DirectBytes = [long]::MaxValue; $overflowChild.TotalBytes = 1 }
            'TotalFiles' { $overflowRoot.DirectFiles = [long]::MaxValue; $overflowChild.TotalFiles = 1 }
            'FolderCount' { $overflowChild.FolderCount = [long]::MaxValue }
            'IssueCount' { $overflowRoot.IssueCount = [int]::MaxValue; $overflowChild.IssueCount = 1 }
        }
        Assert-Throws { $aggregateMethod.Invoke($null, [object[]]@($overflowRoot)) } ([OverflowException]) "checked recursive $counter overflow propagates"
    }
    foreach ($counter in @('DirectBytes', 'DirectFiles')) {
        $overflowRoot = New-Node $fixture
        $overflowRoot.$counter = [long]::MaxValue
        $context = New-Context $overflowRoot
        $regularEntry = [IO.FileInfo]::new((Join-Path $basic 'own.bin'))
        Assert-Throws { $visitEntryMethod.Invoke($null, [object[]]@($regularEntry, $overflowRoot, $context)) } ([OverflowException]) "checked $counter overflow is not swallowed as an I/O issue"
    }

    $stableBytes = $result.Root.TotalBytes
    $stableChildren = ($result.Root.Children | ForEach-Object Name) -join '|'
    Write-FixtureFile (Join-Path $basic 'later.bin') 99
    $later = Invoke-Scan $basic
    Assert-Scan ($later.Root.TotalBytes -eq 209 -and $later.Root.TotalFiles -eq 8) 'a later scan sees filesystem changes'
    Assert-Scan ($result.Root.TotalBytes -eq $stableBytes -and (($result.Root.Children | ForEach-Object Name) -join '|') -ceq $stableChildren) 'completed result remains a stable independent snapshot'
    Assert-Scan (-not [object]::ReferenceEquals($result.Root, $later.Root)) 'separate scans do not share result nodes'
} finally {
    [Environment]::SetEnvironmentVariable($environmentName, $null, 'Process')
    $cleanupErrors = [Collections.Generic.List[string]]::new()
    foreach ($link in $fileLinks) {
        try { [IO.File]::Delete($link) }
        catch { $cleanupErrors.Add("File-link cleanup failed for ${link}: $($_.Exception.Message)") }
    }
    foreach ($link in $directoryLinks) {
        try { [IO.Directory]::Delete($link, $false) }
        catch { $cleanupErrors.Add("Junction cleanup failed for ${link}: $($_.Exception.Message)") }
    }
    for ($i = $deepDirectories.Count - 1; $i -ge 0; $i--) {
        $directory = $deepDirectories[$i]
        try {
            [IO.File]::Delete($directory + '\x')
            [IO.Directory]::Delete($directory, $false)
        } catch { $cleanupErrors.Add("Deep-directory cleanup failed for ${directory}: $($_.Exception.Message)") }
    }
    if ([IO.Directory]::Exists($fixture)) {
        try { [IO.Directory]::Delete($fixture, $true) }
        catch { $cleanupErrors.Add("Fixture cleanup failed for ${fixture}: $($_.Exception.Message)") }
    }
    if ($cleanupErrors.Count -gt 0) { throw ($cleanupErrors -join [Environment]::NewLine) }
}

Write-Host "Scanner tests: $passed passed; $skipped skipped."
