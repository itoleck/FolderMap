param(
    [string]$AssemblyPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSEdition -ne 'Desktop' -or -not [Environment]::Is64BitProcess) {
    throw 'Run these tests with 64-bit Windows PowerShell and .NET Framework.'
}
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$AssemblyPath = (Resolve-Path -LiteralPath $AssemblyPath).ProviderPath
$assembly = [Reflection.Assembly]::LoadFrom($AssemblyPath)
$script:Utf8 = [Text.UTF8Encoding]::new($false, $true)
$script:Passed = 0
$script:Assertions = 0
$script:JitCount = 0
$script:Unicode = 'D' + [char]0x00e9 + [char]0x03a9 + [char]0x4e2d + [char]::ConvertFromUtf32(0x1f4c1)
$script:HighRootId = [uint64]::Parse('18446744073709551614')
$script:HighChildId = [uint64]::Parse('18446744073709551613')
$script:TestDirectory = Join-Path $PSScriptRoot ('.cache-store-tests-' + [Guid]::NewGuid().ToString('N'))
$script:GoodPath = Join-Path $script:TestDirectory 'known-good.fmc'
$script:MalformedPath = Join-Path $script:TestDirectory 'malformed.fmc'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:Assertions++
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    Assert-True ([object]::Equals($Expected, $Actual)) $Message
}

function Assert-BytesEqual {
    param([byte[]]$Expected, [byte[]]$Actual, [string]$Message)
    Assert-Equal ([Convert]::ToBase64String($Expected)) ([Convert]::ToBase64String($Actual)) $Message
}

function Assert-Throws {
    param([scriptblock]$Action, [type]$ExceptionType, [string]$MessagePattern = '')
    $script:Assertions++
    try {
        $null = & $Action
    } catch {
        $failure = $_.Exception
        while (-not $ExceptionType.IsInstanceOfType($failure) -and $null -ne $failure.InnerException) {
            $failure = $failure.InnerException
        }
        if (-not $ExceptionType.IsInstanceOfType($failure)) {
            throw "Expected $($ExceptionType.FullName), received $($failure.GetType().FullName): $($failure.Message)"
        }
        if ($MessagePattern -and $failure.Message -notmatch $MessagePattern) {
            throw "Exception did not match '$MessagePattern': $($failure.Message)"
        }
        return
    }
    throw "Expected $($ExceptionType.FullName), but the operation succeeded."
}

function Test-Case {
    param([string]$Name, [scriptblock]$Action)
    try {
        $null = & $Action
        $script:Passed++
    } catch {
        throw "FAIL: $Name`n$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    }
}

function New-Snapshot {
    $snapshot = [FolderMap.CacheSnapshot]::new()
    $snapshot.RootPath = 'C:\synthetic-' + $script:Unicode + '\scope'
    $snapshot.VolumeName = '\\?\Volume{8cdb38fa-cd90-4d52-9389-c6f76364f5e2}\'
    $snapshot.AccessContext = 'synthetic-S-1-5-21;context-' + $script:Unicode
    $snapshot.VolumeSerial = [uint32]::MaxValue
    $snapshot.RootFileId = $script:HighRootId
    $snapshot.JournalId = [uint64]::MaxValue
    $snapshot.Checkpoint = [long]9876543210
    $snapshot.SavedUtcTicks = [long]638900000000000000

    $root = [FolderMap.CacheDirectory]::new()
    $root.Name = 'root-' + $script:Unicode
    $root.FileId = $script:HighRootId
    $root.DirectBytes = 23
    $root.DirectFiles = 2
    $root.DirectIssueCount = 3
    $root.Issues.Add('Root diagnostic: ' + $script:Unicode)
    $root.Issues.Add("Diagnostic with newline`nand a tab`t.")
    $root.LinkedFiles.Add([uint64]::MaxValue)
    $root.LinkedFiles.Add([uint64]5)
    $snapshot.Directories.Add($root)

    $child = [FolderMap.CacheDirectory]::new()
    $child.ParentIndex = 0
    $child.Name = 'child-' + $script:Unicode
    $child.FileId = $script:HighChildId
    $child.DirectBytes = [long]1234567890123
    $child.DirectFiles = 4
    $child.DirectIssueCount = 2
    $child.Issues.Add('Child diagnostic: ' + $script:Unicode)
    $child.LinkedFiles.Add([uint64]::MaxValue)
    $snapshot.Directories.Add($child)

    $reparse = [FolderMap.CacheDirectory]::new()
    $reparse.ParentIndex = 0
    $reparse.Name = 'junction'
    $reparse.Reparse = $true
    $reparse.DirectIssueCount = 1
    $reparse.Issues.Add('Reparse deliberately untraversed.')
    $snapshot.Directories.Add($reparse)

    $retry = [FolderMap.CacheDirectory]::new()
    $retry.ParentIndex = 1
    $retry.Name = 'inaccessible'
    $retry.Retry = $true
    $retry.DirectIssueCount = 1
    $retry.Issues.Add('Access denied; retry this directory.')
    $snapshot.Directories.Add($retry)

    foreach ($pair in @(@('Case', 17), @('case', 18))) {
        $directory = [FolderMap.CacheDirectory]::new()
        $directory.ParentIndex = 0
        $directory.Name = $pair[0]
        $directory.FileId = [uint64]$pair[1]
        $snapshot.Directories.Add($directory)
    }
    $leaf = [FolderMap.CacheDirectory]::new()
    $leaf.ParentIndex = 1
    $leaf.Name = 'leaf'
    $leaf.FileId = [uint64]19
    $leaf.DirectBytes = 88
    $leaf.DirectFiles = 1
    $snapshot.Directories.Add($leaf)
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new([uint64]::MaxValue, $script:HighRootId))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new([uint64]::MaxValue, $script:HighChildId))
    $snapshot.PendingWrites.Add([FolderMap.PendingWrite]::new([uint64]100, [uint64]18))
    return $snapshot
}

function Assert-SnapshotEqual {
    param($Expected, $Actual)
    Assert-True ($null -ne $Actual) 'A complete snapshot must be returned.'
    foreach ($name in @('RootPath', 'VolumeName', 'AccessContext', 'VolumeSerial', 'RootFileId',
            'JournalId', 'Checkpoint', 'SavedUtcTicks')) {
        Assert-Equal $Expected.$name $Actual.$name "Snapshot field $name must roundtrip exactly."
    }
    Assert-Equal $Expected.Directories.Count $Actual.Directories.Count 'Directory count must roundtrip.'
    for ($i = 0; $i -lt $Expected.Directories.Count; $i++) {
        $left = $Expected.Directories[$i]
        $right = $Actual.Directories[$i]
        foreach ($name in @('ParentIndex', 'Name', 'FileId', 'DirectBytes', 'DirectFiles',
                'DirectIssueCount', 'Retry', 'Reparse')) {
            Assert-Equal $left.$name $right.$name "Directory $i field $name must roundtrip exactly."
        }
        Assert-Equal $left.Issues.Count $right.Issues.Count "Directory $i diagnostic count."
        for ($j = 0; $j -lt $left.Issues.Count; $j++) {
            Assert-Equal $left.Issues[$j] $right.Issues[$j] "Directory $i diagnostic $j."
        }
        Assert-Equal $left.LinkedFiles.Count $right.LinkedFiles.Count "Directory $i linked count."
        for ($j = 0; $j -lt $left.LinkedFiles.Count; $j++) {
            Assert-Equal $left.LinkedFiles[$j] $right.LinkedFiles[$j] "Directory $i linked identity $j."
        }
    }
    Assert-Equal $Expected.PendingWrites.Count $Actual.PendingWrites.Count 'Pending pair count.'
    for ($i = 0; $i -lt $Expected.PendingWrites.Count; $i++) {
        Assert-Equal $Expected.PendingWrites[$i].FileId $Actual.PendingWrites[$i].FileId 'Pending file identity.'
        Assert-Equal $Expected.PendingWrites[$i].ParentId $Actual.PendingWrites[$i].ParentId 'Pending parent identity.'
    }
}

function Write-RawText {
    param([IO.BinaryWriter]$Writer, [string]$Text)
    $bytes = $script:Utf8.GetBytes($Text)
    $Writer.Write([int]$bytes.Length)
    $Writer.Write([byte[]]$bytes)
}

function Get-UncheckedBody {
    param($Snapshot)
    $memory = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($memory, $script:Utf8, $true)
    try {
        $writer.Write([uint64]0x0045484341434d46)
        $writer.Write([uint32]1)
        Write-RawText $writer $Snapshot.RootPath
        Write-RawText $writer $Snapshot.VolumeName
        Write-RawText $writer $Snapshot.AccessContext
        $writer.Write([uint32]$Snapshot.VolumeSerial)
        $writer.Write([uint64]$Snapshot.RootFileId)
        $writer.Write([uint64]$Snapshot.JournalId)
        $writer.Write([long]$Snapshot.Checkpoint)
        $writer.Write([long]$Snapshot.SavedUtcTicks)
        $writer.Write([int]$Snapshot.Directories.Count)
        $writer.Write([int]$Snapshot.PendingWrites.Count)
        foreach ($directory in $Snapshot.Directories) {
            $writer.Write([int]$directory.ParentIndex)
            Write-RawText $writer $directory.Name
            $writer.Write([uint64]$directory.FileId)
            $writer.Write([long]$directory.DirectBytes)
            $writer.Write([long]$directory.DirectFiles)
            $writer.Write([int]$directory.DirectIssueCount)
            $writer.Write([byte](([int]$directory.Retry) -bor (([int]$directory.Reparse) -shl 1)))
            $writer.Write([int]$directory.Issues.Count)
            foreach ($issue in $directory.Issues) { Write-RawText $writer $issue }
            $writer.Write([int]$directory.LinkedFiles.Count)
            foreach ($identity in $directory.LinkedFiles) { $writer.Write([uint64]$identity) }
        }
        foreach ($pending in $Snapshot.PendingWrites) {
            $writer.Write([uint64]$pending.FileId)
            $writer.Write([uint64]$pending.ParentId)
        }
        $writer.Flush()
        return ,$memory.ToArray()
    } finally {
        $writer.Dispose()
        $memory.Dispose()
    }
}

function Set-CheckedBody {
    param([byte[]]$Body, [string]$Path = $script:MalformedPath)
    $sha = [Security.Cryptography.SHA256]::Create()
    $file = $null
    try {
        $checksum = $sha.ComputeHash($Body)
        $file = [IO.FileStream]::new($Path, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $file.Write($Body, 0, $Body.Length)
        $file.Write($checksum, 0, $checksum.Length)
    } finally {
        if ($null -ne $file) { $file.Dispose() }
        $sha.Dispose()
    }
}

function Get-Layout {
    param([byte[]]$Body)
    $memory = [IO.MemoryStream]::new($Body, $false)
    $reader = [IO.BinaryReader]::new($memory, $script:Utf8, $true)
    try {
        $layout = @{}
        $memory.Position = 12
        foreach ($name in @('RootPath', 'VolumeName', 'AccessContext')) {
            $layout[$name] = [int]$memory.Position
            $length = $reader.ReadInt32()
            $memory.Position += $length
        }
        $memory.Position += 36
        $layout.DirectoryCount = [int]$memory.Position
        $count = $reader.ReadInt32()
        $layout.PendingCount = [int]$memory.Position
        $null = $reader.ReadInt32()
        $directories = [Collections.Generic.List[object]]::new()
        for ($i = 0; $i -lt $count; $i++) {
            $entry = @{ Parent = [int]$memory.Position }
            $memory.Position += 4
            $entry.Name = [int]$memory.Position
            $length = $reader.ReadInt32()
            $memory.Position += $length
            $entry.FileId = [int]$memory.Position
            $memory.Position += 8
            $entry.DirectBytes = [int]$memory.Position
            $memory.Position += 8
            $entry.DirectFiles = [int]$memory.Position
            $memory.Position += 8
            $entry.DirectIssueCount = [int]$memory.Position
            $memory.Position += 4
            $entry.Flags = [int]$memory.Position
            $memory.Position++
            $entry.IssueCount = [int]$memory.Position
            $issues = $reader.ReadInt32()
            for ($j = 0; $j -lt $issues; $j++) {
                $length = $reader.ReadInt32()
                $memory.Position += $length
            }
            $entry.LinkedCount = [int]$memory.Position
            $links = $reader.ReadInt32()
            $memory.Position += 8 * $links
            $directories.Add($entry)
        }
        $layout.Directories = $directories
        $layout.PendingPairs = [int]$memory.Position
        return $layout
    } finally {
        $reader.Dispose()
        $memory.Dispose()
    }
}

function Assert-RejectedSnapshot {
    param($Snapshot, [string]$MessagePattern = '')
    $prior = [IO.File]::ReadAllBytes($script:GoodPath)
    Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $Snapshot, $null) } ([IO.InvalidDataException]) $MessagePattern
    Assert-BytesEqual $prior ([IO.File]::ReadAllBytes($script:GoodPath)) 'Invalid snapshots must preserve the prior cache.'
    Set-CheckedBody (Get-UncheckedBody $Snapshot)
    Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) $MessagePattern
}

function Assert-NoOwnedTemporary {
    Assert-Equal 0 ([IO.Directory]::GetFiles($script:TestDirectory, '.foldermap-*.tmp').Length) 'No owned temporary files may survive.'
}

function New-LinkedReferences {
    param([int]$Count)
    $items = [Array]::CreateInstance([uint64], $Count)
    $items[0] = [uint64]::MaxValue
    for ($filled = 1; $filled -lt $Count; $filled *= 2) {
        [Array]::Copy($items, 0, $items, $filled, [Math]::Min($filled, $Count - $filled))
    }
    return ,([Collections.Generic.List[uint64]]::new($items))
}

function Assert-RacingSaves {
    param([bool]$Existing)
    $path = Join-Path $script:TestDirectory ('race-' + $Existing + '.fmc')
    $left = New-Snapshot; $right = New-Snapshot
    $left.Checkpoint = 111; $left.Directories[0].DirectBytes = 111
    $right.Checkpoint = 222; $right.Directories[0].DirectBytes = 222
    $right.SavedUtcTicks++
    if ($Existing) { [FolderMap.CacheStore]::Save($path, (New-Snapshot), $null) }
    $gate = [Threading.ManualResetEvent]::new($false)
    $ready = [Threading.CountdownEvent]::new(2)
    $runners = [Collections.Generic.List[PowerShell]]::new()
    $handles = [Collections.Generic.List[object]]::new()
    $saved = 0
    try {
        foreach ($snapshot in @($left, $right)) {
            $runner = [PowerShell]::Create()
            $runners.Add($runner)
            $null = $runner.AddScript(@'
param($assemblyPath, $path, $snapshot, $gate, $ready)
$ErrorActionPreference = 'Stop'
$null = [Reflection.Assembly]::LoadFrom($assemblyPath)
$null = $ready.Signal()
$null = $gate.WaitOne()
try {
    [FolderMap.CacheStore]::Save($path, $snapshot, $null)
    'saved'
} catch {
    $failure = $_.Exception
    while ($null -ne $failure.InnerException) { $failure = $failure.InnerException }
    if ($failure -is [IO.IOException]) { 'IOException' } else { throw }
}
'@).AddArgument($AssemblyPath).AddArgument($path).AddArgument($snapshot).AddArgument($gate).AddArgument($ready)
            $handles.Add($runner.BeginInvoke())
        }
        Assert-True ($ready.Wait(10000)) 'Both concurrent writers must be ready.'
        $null = $gate.Set()
        for ($i = 0; $i -lt $runners.Count; $i++) {
            $output = $runners[$i].EndInvoke($handles[$i])
            Assert-True (-not $runners[$i].HadErrors) 'Concurrent writer may only fail with the documented IOException.'
            Assert-Equal 1 $output.Count 'Each writer must report one outcome.'
            $outcome = [string]$output[0]
            Assert-True ($outcome -eq 'saved' -or $outcome -eq 'IOException') 'Unexpected concurrent write result.'
            if ($outcome -eq 'saved') { $saved++ }
        }
        Assert-True ($saved -gt 0) 'At least one racing writer must commit.'
        $loaded = [FolderMap.CacheStore]::Load($path, $null)
        if ($loaded.Checkpoint -eq 111) { Assert-SnapshotEqual $left $loaded }
        elseif ($loaded.Checkpoint -eq 222) { Assert-SnapshotEqual $right $loaded }
        else { throw 'The destination must be one complete committed snapshot, not the old or a mixed checkpoint.' }
        Assert-NoOwnedTemporary
    } finally {
        $null = $gate.Set()
        foreach ($runner in $runners) { $runner.Stop(); $runner.Dispose() }
        $ready.Dispose(); $gate.Dispose()
    }
}

try {
    $null = [IO.Directory]::CreateDirectory($script:TestDirectory)
    Test-Case 'Every cache method and DTO constructor JIT-prepares' {
        $store = $assembly.GetType('FolderMap.CacheStore', $true)
        Assert-True ($store.IsAbstract -and $store.IsSealed) 'CacheStore must be a static abstract sealed class.'
        foreach ($method in $store.GetMethods([Reflection.BindingFlags]'Static,Public,NonPublic,DeclaredOnly')) {
            [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
            $script:JitCount++
        }
        [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($store.TypeInitializer.MethodHandle)
        foreach ($name in @('CacheSnapshot', 'CacheDirectory', 'PendingWrite')) {
            foreach ($ctor in $assembly.GetType('FolderMap.' + $name, $true).GetConstructors()) {
                [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($ctor.MethodHandle)
            }
        }
        $public = @($store.GetMethods([Reflection.BindingFlags]'Static,Public,DeclaredOnly').Name | Sort-Object)
        Assert-Equal 'DefaultDirectory,GetPath,Load,Save' ($public -join ',') 'The public API must be exact.'
        Assert-Equal ([FolderMap.CacheSnapshot]) $store.GetMethod('Load').ReturnType 'Load returns the shared DTO.'
        $peKind = [Reflection.PortableExecutableKinds]0
        $machine = [Reflection.ImageFileMachine]::I386
        $assembly.ManifestModule.GetPEKind([ref]$peKind, [ref]$machine)
        Assert-Equal ([Reflection.ImageFileMachine]::AMD64) $machine 'Assembly must target x64.'
        Assert-True (($peKind -band [Reflection.PortableExecutableKinds]::PE32Plus) -ne 0) 'Assembly must use PE32+.'
        foreach ($contract in @(
                @{ Name = 'DefaultDirectory'; Result = [string]; Parameters = '' },
                @{ Name = 'GetPath'; Result = [string]; Parameters = 'System.String,System.String,System.String' },
                @{ Name = 'Load'; Result = [FolderMap.CacheSnapshot]; Parameters = 'System.String,System.ComponentModel.BackgroundWorker' },
                @{ Name = 'Save'; Result = [void]; Parameters = 'System.String,FolderMap.CacheSnapshot,System.ComponentModel.BackgroundWorker' }
            )) {
            $method = $store.GetMethod($contract.Name)
            Assert-Equal $contract.Result $method.ReturnType "Return type for $($contract.Name)."
            $parameters = @($method.GetParameters() | ForEach-Object { $_.ParameterType.FullName }) -join ','
            Assert-Equal $contract.Parameters $parameters "Parameter types for $($contract.Name)."
        }
    }
    Test-Case 'Default cache directory is LocalApplicationData\FolderMap\Cache' {
        $expected = [IO.Path]::Combine([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData), 'FolderMap', 'Cache')
        Assert-Equal $expected ([FolderMap.CacheStore]::DefaultDirectory()) 'DefaultDirectory must match the documented location.'
    }
    Test-Case 'Hash keys are stable, opaque, exact-case and scoped to the requested directory' {
        $snapshot = New-Snapshot
        $cacheDirectory = Join-Path $script:TestDirectory 'not-created'
        $path = [FolderMap.CacheStore]::GetPath($cacheDirectory, $snapshot.RootPath, $snapshot.AccessContext)
        Assert-Equal $path ([FolderMap.CacheStore]::GetPath($cacheDirectory, $snapshot.RootPath, $snapshot.AccessContext)) 'Identical keys must be deterministic.'
        Assert-Equal ([IO.Path]::GetFullPath($cacheDirectory)) ([IO.Path]::GetDirectoryName($path)) 'Key must stay beneath the requested directory.'
        $filename = [IO.Path]::GetFileName($path)
        Assert-True ($filename -cmatch '^[0-9a-f]{64}\.fmc$') 'Filename must be a SHA-256 hex digest plus .fmc.'
        Assert-True (-not $filename.Contains('synthetic') -and -not $filename.Contains($script:Unicode)) 'Root and sensitive names must not leak.'
        Assert-True (-not [IO.Directory]::Exists($cacheDirectory)) 'GetPath must not create directories.'
        $keys = [Collections.Generic.Dictionary[string, bool]]::new([StringComparer]::Ordinal)
        foreach ($pair in @(
                @($snapshot.RootPath, $snapshot.AccessContext),
                @(($snapshot.RootPath + '2'), $snapshot.AccessContext),
                @($snapshot.RootPath.ToUpperInvariant(), $snapshot.AccessContext),
                @($snapshot.RootPath, ($snapshot.AccessContext + '2')),
                @($snapshot.RootPath, $snapshot.AccessContext.ToUpperInvariant()),
                @($snapshot.RootPath, ($snapshot.AccessContext + "`ncontext")))) {
            $key = [FolderMap.CacheStore]::GetPath($cacheDirectory, $pair[0], $pair[1])
            Assert-True (-not $keys.ContainsKey($key)) 'Distinct root/context/case inputs must have distinct keys.'
            $keys.Add($key, $true)
        }
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $bytes = $script:Utf8.GetBytes("FolderMap.CacheKey.v1`n" + $snapshot.RootPath + "`n" + $snapshot.AccessContext)
            $expected = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() + '.fmc'
            Assert-Equal $expected $filename 'The key must hash the documented versioned, delimited UTF-8 input.'
        } finally { $sha.Dispose() }
    }
    Test-Case 'Relative cache directory becomes absolute without treating root as output' {
        $relative = Join-Path (Split-Path -Leaf $script:TestDirectory) 'keys'
        $actual = [FolderMap.CacheStore]::GetPath($relative, 'C:\not-the-cache', 'identity')
        Assert-Equal ([IO.Path]::GetFullPath($relative)) ([IO.Path]::GetDirectoryName($actual)) 'Relative output directory must be made absolute.'
    }
    foreach ($argument in @('directory', 'root', 'context')) {
        Test-Case "Blank key $argument is rejected" {
            $directory = $script:TestDirectory; $root = 'C:\synthetic'; $context = 'identity'
            if ($argument -eq 'directory') { $directory = ' ' }
            if ($argument -eq 'root') { $root = '' }
            if ($argument -eq 'context') { $context = "`t" }
            Assert-Throws { [FolderMap.CacheStore]::GetPath($directory, $root, $context) } ([ArgumentException])
        }
    }
    Test-Case 'Root separator injection is rejected rather than colliding keys' {
        Assert-Throws { [FolderMap.CacheStore]::GetPath($script:TestDirectory, "C:\synthetic`ninjected", 'identity') } ([IO.InvalidDataException])
    }
    Test-Case 'Missing cache and missing parent directory return null' {
        Assert-True ($null -eq [FolderMap.CacheStore]::Load((Join-Path $script:TestDirectory 'missing.fmc'), $null)) 'A missing file returns null.'
        Assert-True ($null -eq [FolderMap.CacheStore]::Load((Join-Path $script:TestDirectory 'missing-parent\missing.fmc'), $null)) 'A missing parent directory returns null.'
    }
    Test-Case 'Directories and sharing failures do not masquerade as cache misses' {
        Assert-Throws { [FolderMap.CacheStore]::Load($script:TestDirectory, $null) } ([UnauthorizedAccessException])
        $lockedPath = Join-Path $script:TestDirectory 'locked.fmc'
        $locked = [IO.FileStream]::new($lockedPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try {
            Assert-Throws { [FolderMap.CacheStore]::Load($lockedPath, $null) } ([IO.IOException])
        } finally { $locked.Dispose() }
    }
    $original = New-Snapshot
    Test-Case 'Unicode, UInt64, pending associations, reparse, retry and direct diagnostics roundtrip exactly' {
        [FolderMap.CacheStore]::Save($script:GoodPath, $original, $null)
        $loaded = [FolderMap.CacheStore]::Load($script:GoodPath, $null)
        Assert-SnapshotEqual $original $loaded
        Assert-Equal 'Case' $loaded.Directories[4].Name 'Uppercase child must remain separate.'
        Assert-Equal 'case' $loaded.Directories[5].Name 'Lowercase child must remain separate.'
        Assert-Equal 3 $loaded.Directories[0].DirectIssueCount 'Direct diagnostics must not be replaced with aggregate issues.'
        Assert-NoOwnedTemporary
    }
    $script:ValidBody = Get-UncheckedBody $original
    $script:Layout = Get-Layout $script:ValidBody
    Test-Case 'Primitive schema and whole-body SHA-256 match an independent writer' {
        Set-CheckedBody $script:ValidBody
        Assert-BytesEqual ([IO.File]::ReadAllBytes($script:MalformedPath)) ([IO.File]::ReadAllBytes($script:GoodPath)) 'Independent primitive serialization must match exactly.'
        Assert-SnapshotEqual $original ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case 'Repeated writes are deterministic and atomically replace an existing snapshot' {
        $before = [IO.File]::ReadAllBytes($script:GoodPath)
        [FolderMap.CacheStore]::Save($script:GoodPath, $original, $null)
        Assert-BytesEqual $before ([IO.File]::ReadAllBytes($script:GoodPath)) 'Equal snapshots must have identical bytes.'
        $replacement = New-Snapshot
        $replacement.Checkpoint++
        $replacement.Directories[0].DirectBytes = 999
        [FolderMap.CacheStore]::Save($script:GoodPath, $replacement, $null)
        Assert-SnapshotEqual $replacement ([FolderMap.CacheStore]::Load($script:GoodPath, $null))
        Assert-NoOwnedTemporary
        [FolderMap.CacheStore]::Save($script:GoodPath, $original, $null)
    }
    Test-Case 'Save creates only the requested cache directory' {
        $directory = Join-Path $script:TestDirectory 'requested\nested'
        $path = Join-Path $directory 'snapshot.fmc'
        Assert-True (-not [IO.Directory]::Exists($directory)) 'Requested directory should begin absent.'
        [FolderMap.CacheStore]::Save($path, $original, $null)
        Assert-True ([IO.File]::Exists($path)) 'Requested file must be committed.'
        Assert-Equal 1 ([IO.Directory]::GetFiles($directory).Length) 'No extra files should be created.'
        Assert-SnapshotEqual $original ([FolderMap.CacheStore]::Load($path, $null))
    }
    Test-Case 'Initial cancellation preserves an existing cache and creates nothing' {
        $worker = [ComponentModel.BackgroundWorker]::new()
        try {
            $worker.WorkerSupportsCancellation = $true
            $worker.CancelAsync()
            $prior = [IO.File]::ReadAllBytes($script:GoodPath)
            Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $original, $worker) } ([OperationCanceledException])
            Assert-BytesEqual $prior ([IO.File]::ReadAllBytes($script:GoodPath)) 'Cancellation must preserve the old file.'
            $directory = Join-Path $script:TestDirectory 'cancelled-not-created'
            Assert-Throws { [FolderMap.CacheStore]::Save((Join-Path $directory 'cache.fmc'), $original, $worker) } ([OperationCanceledException])
            Assert-True (-not [IO.Directory]::Exists($directory)) 'An already cancelled save must not create its directory.'
            Assert-Throws { [FolderMap.CacheStore]::Load($script:GoodPath, $worker) } ([OperationCanceledException])
            Assert-NoOwnedTemporary
        } finally { $worker.Dispose() }
    }
    Test-Case 'Commit sharing failure preserves the old destination and cleans only its own temporary' {
        $prior = [IO.File]::ReadAllBytes($script:GoodPath)
        $foreign = Join-Path $script:TestDirectory '.foldermap-foreign.tmp'
        [IO.File]::WriteAllText($foreign, 'another writer owns this file')
        $locked = [IO.FileStream]::new($script:GoodPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        try {
            Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $original, $null) } ([IO.IOException])
        } finally { $locked.Dispose() }
        Assert-BytesEqual $prior ([IO.File]::ReadAllBytes($script:GoodPath)) 'Failed commit must preserve the old destination.'
        Assert-Equal 'another writer owns this file' ([IO.File]::ReadAllText($foreign)) 'Cleanup must not touch another writer.'
        Assert-Equal 1 ([IO.Directory]::GetFiles($script:TestDirectory, '.foldermap-*.tmp').Length) 'Only the foreign temporary should remain.'
        [IO.File]::Delete($foreign)
    }
    Test-Case 'Concurrent first writes commit one whole snapshot or report a move race' {
        Assert-RacingSaves $false
    }
    Test-Case 'Concurrent replacements leave one whole checkpoint and snapshot' {
        Assert-RacingSaves $true
    }

    foreach ($rootPath in @('relative', 'C:relative', '\drive-relative', '\\server', '\\?\C:relative', '\\.\C:\device', '', '   ')) {
        Test-Case "Nonabsolute or invalid root is rejected: [$rootPath]" {
            $snapshot = New-Snapshot; $snapshot.RootPath = $rootPath
            Assert-RejectedSnapshot $snapshot 'RootPath'
        }
    }
    foreach ($rootPath in @('C:\', 'C:/absolute', '\\server\share', '\\?\C:\extended',
            '\\?\UNC\server\share\extended', '\\?\Volume{8cdb38fa-cd90-4d52-9389-c6f76364f5e2}\')) {
        Test-Case "Absolute root kind roundtrips: [$rootPath]" {
            $snapshot = New-Snapshot; $snapshot.RootPath = $rootPath
            [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
            Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
        }
    }
    foreach ($field in @('VolumeName', 'AccessContext')) {
        Test-Case "Blank $field is rejected" {
            $snapshot = New-Snapshot; $snapshot.$field = " `t"
            Assert-RejectedSnapshot $snapshot $field
        }
    }
    foreach ($timestamp in @([long]-1, [long]0, [long]3155378976000000000)) {
        Test-Case "Invalid timestamp $timestamp is rejected" {
            $snapshot = New-Snapshot; $snapshot.SavedUtcTicks = $timestamp
            Assert-RejectedSnapshot $snapshot 'SavedUtcTicks'
        }
    }
    Test-Case 'Nonnegative checkpoint and DateTime.MaxValue boundaries are preserved' {
        $snapshot = New-Snapshot
        $snapshot.Checkpoint = [long]::MaxValue
        $snapshot.SavedUtcTicks = [DateTime]::MaxValue.Ticks
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
        $snapshot.Checkpoint = 0
        $snapshot.SavedUtcTicks = 1
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    foreach ($scenario in @(
            @{ Name = 'Negative checkpoint'; Edit = { param($s) $s.Checkpoint = -1 } },
            @{ Name = 'Missing root identity'; Edit = { param($s) $s.RootFileId = 0; $s.Directories[0].FileId = 0; $s.Directories[0].Retry = $true } },
            @{ Name = 'Root identity mismatch'; Edit = { param($s) $s.Directories[0].FileId = 1 } },
            @{ Name = 'Root has a parent'; Edit = { param($s) $s.Directories[0].ParentIndex = 0 } },
            @{ Name = 'Multiple roots'; Edit = { param($s) $s.Directories[1].ParentIndex = -1 } },
            @{ Name = 'Parent outside record range'; Edit = { param($s) $s.Directories[1].ParentIndex = 999 } },
            @{ Name = 'Self cycle'; Edit = { param($s) $s.Directories[1].ParentIndex = 1 } },
            @{ Name = 'Forward parent cycle'; Edit = { param($s) $s.Directories[1].ParentIndex = 3 } },
            @{ Name = 'Negative parent index'; Edit = { param($s) $s.Directories[1].ParentIndex = -2 } },
            @{ Name = 'Negative bytes'; Edit = { param($s) $s.Directories[1].DirectBytes = -1 } },
            @{ Name = 'Negative files'; Edit = { param($s) $s.Directories[1].DirectFiles = -1 } },
            @{ Name = 'Negative direct issues'; Edit = { param($s) $s.Directories[1].DirectIssueCount = -1 } },
            @{ Name = 'Int64 aggregate bytes overflow'; Edit = { param($s) $s.Directories[0].DirectBytes = [long]::MaxValue } },
            @{ Name = 'Int64 aggregate files overflow'; Edit = { param($s) $s.Directories[0].DirectFiles = [long]::MaxValue } },
            @{ Name = 'Diagnostics exceed direct issue count'; Edit = { param($s) $s.Directories[0].DirectIssueCount = 1 } },
            @{ Name = 'Duplicate non-reparse identity'; Edit = { param($s) $s.Directories[1].FileId = $s.RootFileId } },
            @{ Name = 'Zero normal directory identity'; Edit = { param($s) $s.Directories[1].FileId = 0 } },
            @{ Name = 'Duplicate ordinal child path'; Edit = { param($s) $s.Directories[5].Name = 'Case' } },
            @{ Name = 'Reparse directory has bytes'; Edit = { param($s) $s.Directories[2].DirectBytes = 1 } },
            @{ Name = 'Reparse directory has files'; Edit = { param($s) $s.Directories[2].DirectFiles = 1 } },
            @{ Name = 'Reparse directory has linked file'; Edit = { param($s) $s.Directories[2].LinkedFiles.Add([uint64]7) } },
            @{ Name = 'Reparse directory has child'; Edit = { param($s) $s.Directories[6].ParentIndex = 2 } },
            @{ Name = 'Zero linked file identity'; Edit = { param($s) $s.Directories[0].LinkedFiles[0] = 0 } },
            @{ Name = 'Zero pending file identity'; Edit = { param($s) $s.PendingWrites[0].FileId = 0 } },
            @{ Name = 'Zero pending parent identity'; Edit = { param($s) $s.PendingWrites[0].ParentId = 0 } },
            @{ Name = 'Duplicate pending association'; Edit = { param($s) $s.PendingWrites.Add([FolderMap.PendingWrite]::new($s.PendingWrites[0].FileId, $s.PendingWrites[0].ParentId)) } },
            @{ Name = 'No root records'; Edit = { param($s) $s.Directories.Clear() } }
        )) {
        Test-Case "$($scenario.Name) rejected by Save and checksum-valid Load" {
            $snapshot = New-Snapshot
            $null = & $scenario.Edit $snapshot
            Assert-RejectedSnapshot $snapshot
        }
    }
    foreach ($name in @('', '.', '..', '..\escape', '../escape', '\rooted', 'C:ads', 'a/b', 'a\b',
            'bad<name', 'bad>name', 'bad|name', 'bad?name', 'bad*name', 'bad"name', "bad`nname",
            ('bad' + [char]0 + 'name'), 'trailing.', 'trailing ', 'CON', 'nul.txt', 'COM1', 'LPT9.log',
            ('COM' + [char]0x00b9), 'CONIN$', 'CON .txt', 'LPT1 .log', ('x' * 256))) {
        Test-Case "Unsafe Windows component rejected: [$name]" {
            $snapshot = New-Snapshot; $snapshot.Directories[1].Name = $name
            Assert-RejectedSnapshot $snapshot
        }
    }
    Test-Case 'Same child name in different parents is valid' {
        $snapshot = New-Snapshot
        $snapshot.Directories[6].Name = $snapshot.Directories[4].Name
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case 'Nonzero reparse identities may alias a normal directory identity' {
        $snapshot = New-Snapshot
        $snapshot.Directories[2].FileId = $snapshot.RootFileId
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case 'Repeated linked identities represent distinct hardlink entries and are preserved' {
        $snapshot = New-Snapshot
        $snapshot.Directories[1].LinkedFiles.Add([uint64]::MaxValue)
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case 'Empty root display name is valid without weakening non-root names' {
        $snapshot = New-Snapshot; $snapshot.Directories[0].Name = ''
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case 'Exact Int64 aggregate maximum is accepted' {
        $snapshot = New-Snapshot
        foreach ($directory in $snapshot.Directories) { $directory.DirectBytes = 0; $directory.DirectFiles = 0 }
        $snapshot.Directories[1].DirectBytes = [long]::MaxValue
        $snapshot.Directories[1].DirectFiles = [long]::MaxValue
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case '255-character components and 200 diagnostics are accepted' {
        $snapshot = New-Snapshot
        $snapshot.Directories[1].Name = 'x' * 255
        $snapshot.Directories[1].Issues.Clear()
        for ($i = 0; $i -lt 200; $i++) { $snapshot.Directories[1].Issues.Add('diagnostic ' + $i) }
        $snapshot.Directories[1].DirectIssueCount = 200
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    Test-Case '201 diagnostics are rejected' {
        $snapshot = New-Snapshot
        $snapshot.Directories[1].Issues.Clear()
        for ($i = 0; $i -lt 201; $i++) { $snapshot.Directories[1].Issues.Add('diagnostic') }
        $snapshot.Directories[1].DirectIssueCount = 201
        Assert-RejectedSnapshot $snapshot
    }
    Test-Case '131072-byte UTF-8 string is accepted' {
        $snapshot = New-Snapshot
        $snapshot.Directories[1].Issues[0] = 'x' * 131072
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    foreach ($field in @('VolumeName', 'AccessContext', 'diagnostic', 'multibyte diagnostic')) {
        Test-Case "Oversized $field is rejected before writing" {
            $snapshot = New-Snapshot
            $oversized = 'x' * 131073
            if ($field -eq 'diagnostic') { $snapshot.Directories[1].Issues[0] = $oversized }
            elseif ($field -eq 'multibyte diagnostic') { $snapshot.Directories[1].Issues[0] = ([string][char]0x4e2d) * 43691 }
            else { $snapshot.$field = $oversized }
            Assert-RejectedSnapshot $snapshot
        }
    }
    Test-Case 'Unpaired UTF-16 surrogate is rejected on Save' {
        $snapshot = New-Snapshot
        $snapshot.Directories[1].Issues[0] = [string][char]0xd800
        Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $snapshot, $null) } ([IO.InvalidDataException]) 'Unicode'
    }
    Test-Case 'Root and cumulative ancestry path limits are enforced' {
        $snapshot = New-Snapshot
        $snapshot.RootPath = 'C:\' + ('r\' * 16382) + 'r'
        Assert-RejectedSnapshot $snapshot 'RootPath'
        $snapshot = New-Snapshot
        $snapshot.RootPath = 'C:\' + ('r\' * 16360) + 'r'
        $snapshot.Directories[1].Name = 'x' * 255
        Assert-RejectedSnapshot $snapshot 'cumulative'
    }
    Test-Case '32767-character cumulative path boundary is accepted' {
        $snapshot = New-Snapshot
        $snapshot.Directories.RemoveRange(1, $snapshot.Directories.Count - 1)
        $snapshot.PendingWrites.Clear()
        $snapshot.RootPath = 'C:\' + ('r\' * 16378) + 'r'
        $child = [FolderMap.CacheDirectory]::new()
        $child.ParentIndex = 0; $child.Name = 'abcdef'; $child.FileId = 7
        $snapshot.Directories.Add($child)
        Assert-Equal 32767 ($snapshot.RootPath.Length + 1 + $child.Name.Length) 'Fixture must meet the boundary exactly.'
        [FolderMap.CacheStore]::Save($script:MalformedPath, $snapshot, $null)
        Assert-SnapshotEqual $snapshot ([FolderMap.CacheStore]::Load($script:MalformedPath, $null))
    }
    foreach ($scenario in @(
            @{ Name = 'null directories'; Edit = { param($s) $s.Directories = $null } },
            @{ Name = 'null pending list'; Edit = { param($s) $s.PendingWrites = $null } },
            @{ Name = 'null directory record'; Edit = { param($s) $s.Directories[1] = $null } },
            @{ Name = 'null issue list'; Edit = { param($s) $s.Directories[1].Issues = $null } },
            @{ Name = 'null linked list'; Edit = { param($s) $s.Directories[1].LinkedFiles = $null } },
            @{ Name = 'null issue text'; Edit = { param($s) $s.Directories[1].Issues.GetType().GetProperty('Item').SetValue($s.Directories[1].Issues, $null, [object[]]@([int]0)) } },
            @{ Name = 'null root name'; Edit = { param($s) [FolderMap.CacheDirectory].GetField('Name').SetValue($s.Directories[0], $null) } },
            @{ Name = 'null child name'; Edit = { param($s) [FolderMap.CacheDirectory].GetField('Name').SetValue($s.Directories[1], $null) } },
            @{ Name = 'null pending record'; Edit = { param($s) $s.PendingWrites[1] = $null } }
        )) {
        Test-Case "$($scenario.Name) fails validation without creating a directory" {
            $snapshot = New-Snapshot
            $null = & $scenario.Edit $snapshot
            $directory = Join-Path $script:TestDirectory 'invalid-not-created'
            Assert-Throws { [FolderMap.CacheStore]::Save((Join-Path $directory 'cache.fmc'), $snapshot, $null) } ([IO.InvalidDataException])
            Assert-True (-not [IO.Directory]::Exists($directory)) 'Validation must happen before creating the output directory.'
        }
    }
    Test-Case 'Null snapshot and blank I/O paths fail explicitly' {
        Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $null, $null) } ([ArgumentNullException])
        Assert-Throws { [FolderMap.CacheStore]::Save('', $original, $null) } ([ArgumentException])
        Assert-Throws { [FolderMap.CacheStore]::Load(" `t", $null) } ([ArgumentException])
    }

    foreach ($mutation in @(
            @{ Name = 'unsupported schema'; Offset = 8; Value = 2; Pattern = 'schema version' },
            @{ Name = 'oversized root string'; Offset = $script:Layout.RootPath; Value = 131073; Pattern = 'limit' },
            @{ Name = 'negative root string'; Offset = $script:Layout.RootPath; Value = -1; Pattern = 'negative' },
            @{ Name = 'Int32.MaxValue root string'; Offset = $script:Layout.RootPath; Value = [int]::MaxValue; Pattern = 'limit' },
            @{ Name = 'root string beyond remaining payload'; Offset = $script:Layout.RootPath; Value = 131072; Pattern = 'remaining payload' },
            @{ Name = 'oversized directory count'; Offset = $script:Layout.DirectoryCount; Value = 1000001; Pattern = 'limit' },
            @{ Name = 'negative directory count'; Offset = $script:Layout.DirectoryCount; Value = -1; Pattern = 'negative' },
            @{ Name = 'Int32.MaxValue directory count'; Offset = $script:Layout.DirectoryCount; Value = [int]::MaxValue; Pattern = 'limit' },
            @{ Name = 'bounded directory count beyond payload'; Offset = $script:Layout.DirectoryCount; Value = 1000000; Pattern = 'remaining payload' },
            @{ Name = 'oversized pending count'; Offset = $script:Layout.PendingCount; Value = 1000001; Pattern = 'limit' },
            @{ Name = 'negative pending count'; Offset = $script:Layout.PendingCount; Value = -1; Pattern = 'negative' },
            @{ Name = 'Int32.MaxValue pending count'; Offset = $script:Layout.PendingCount; Value = [int]::MaxValue; Pattern = 'limit' },
            @{ Name = 'oversized issue count'; Offset = $script:Layout.Directories[0].IssueCount; Value = 201; Pattern = 'limit' },
            @{ Name = 'negative issue count'; Offset = $script:Layout.Directories[0].IssueCount; Value = -1; Pattern = 'negative' },
            @{ Name = 'oversized linked count'; Offset = $script:Layout.Directories[0].LinkedCount; Value = 1000001; Pattern = 'limit' },
            @{ Name = 'negative linked count'; Offset = $script:Layout.Directories[0].LinkedCount; Value = -1; Pattern = 'negative' },
            @{ Name = 'Int32.MaxValue linked count'; Offset = $script:Layout.Directories[0].LinkedCount; Value = [int]::MaxValue; Pattern = 'limit' },
            @{ Name = 'bounded linked count beyond payload'; Offset = $script:Layout.Directories[0].LinkedCount; Value = 1000000; Pattern = 'remaining payload' }
        )) {
        Test-Case "Checksum-valid $($mutation.Name) rejected before large allocation" {
            $body = [byte[]]$script:ValidBody.Clone()
            [BitConverter]::GetBytes([int]$mutation.Value).CopyTo($body, [int]$mutation.Offset)
            Set-CheckedBody $body
            Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) $mutation.Pattern
        }
    }
    Test-Case 'Checksum-valid malformed magic is rejected' {
        $body = [byte[]]$script:ValidBody.Clone(); $body[0] = 0
        Set-CheckedBody $body
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'magic'
    }
    Test-Case 'Checksum-valid unknown directory flags are rejected' {
        $body = [byte[]]$script:ValidBody.Clone(); $body[$script:Layout.Directories[0].Flags] = 128
        Set-CheckedBody $body
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'flag'
    }
    Test-Case 'Checksum-valid malformed UTF-8 is rejected without replacement characters' {
        $body = [byte[]]$script:ValidBody.Clone(); $body[$script:Layout.RootPath + 4] = 255
        Set-CheckedBody $body
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'UTF-8'
    }
    foreach ($offset in @(0, $script:Layout.Directories[1].DirectBytes, ([IO.File]::ReadAllBytes($script:GoodPath).Length - 1))) {
        Test-Case "Uncorrected header, payload or checksum corruption at byte $offset is rejected" {
            $bytes = [IO.File]::ReadAllBytes($script:GoodPath)
            $bytes[$offset] = [byte]($bytes[$offset] -bxor 1)
            [IO.File]::WriteAllBytes($script:MalformedPath, $bytes)
            Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'checksum'
        }
    }
    foreach ($length in @(0, 1, 12, 43, ($script:ValidBody.Length - 8), ($script:ValidBody.Length + 31))) {
        Test-Case "Truncation to $length bytes is rejected" {
            $valid = [IO.File]::ReadAllBytes($script:GoodPath)
            $bytes = [Array]::CreateInstance([byte], $length)
            [Array]::Copy($valid, $bytes, $length)
            [IO.File]::WriteAllBytes($script:MalformedPath, $bytes)
            Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException])
        }
    }
    Test-Case 'Checksum-valid truncated final pending pair is rejected' {
        $body = [Array]::CreateInstance([byte], $script:ValidBody.Length - 1)
        [Array]::Copy($script:ValidBody, $body, $body.Length)
        Set-CheckedBody $body
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'truncated|remaining'
    }
    Test-Case 'Trailing bytes after or inside the checksum envelope are rejected' {
        $bytes = [byte[]]([IO.File]::ReadAllBytes($script:GoodPath) + [byte]7)
        [IO.File]::WriteAllBytes($script:MalformedPath, $bytes)
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'checksum'
        Set-CheckedBody ([byte[]]($script:ValidBody + [byte]7))
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'trailing'
    }
    Test-Case 'File size limit is checked before reading or allocating a huge payload' {
        $hugePath = Join-Path $script:TestDirectory 'over-limit.fmc'
        $file = [IO.FileStream]::new($hugePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $file.SetLength([long]536870913) } finally { $file.Dispose() }
        try {
            Assert-Throws { [FolderMap.CacheStore]::Load($hugePath, $null) } ([IO.InvalidDataException]) '512 MiB'
        } finally { [IO.File]::Delete($hugePath) }
    }
    Test-Case 'Serialized size limit rejects shared giant diagnostics without serializing 512 MiB' {
        $snapshot = New-Snapshot
        $message = 'x' * 131072
        for ($i = 0; $i -lt 22; $i++) {
            $directory = [FolderMap.CacheDirectory]::new()
            $directory.ParentIndex = 0; $directory.Name = 'large-' + $i; $directory.FileId = [uint64](1000 + $i)
            $directory.DirectIssueCount = 200
            for ($j = 0; $j -lt 200; $j++) { $directory.Issues.Add($message) }
            $snapshot.Directories.Add($directory)
        }
        $directoryPath = Join-Path $script:TestDirectory 'oversized-not-created'
        Assert-Throws { [FolderMap.CacheStore]::Save((Join-Path $directoryPath 'cache.fmc'), $snapshot, $null) } ([IO.InvalidDataException]) '512 MiB'
        Assert-True (-not [IO.Directory]::Exists($directoryPath)) 'Size validation must precede creating the output directory.'
    }
    Test-Case 'Save rejects excessive directory count before inspecting records' {
        $snapshot = New-Snapshot
        $slots = [Array]::CreateInstance([FolderMap.CacheDirectory], 1000001)
        $snapshot.Directories = [Collections.Generic.List[FolderMap.CacheDirectory]]::new($slots)
        Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $snapshot, $null) } ([IO.InvalidDataException]) '1000000-directory'
        Assert-NoOwnedTemporary
    }
    Test-Case 'Save rejects excessive pending count before inspecting pairs' {
        $snapshot = New-Snapshot
        $slots = [Array]::CreateInstance([FolderMap.PendingWrite], 1000001)
        $snapshot.PendingWrites = [Collections.Generic.List[FolderMap.PendingWrite]]::new($slots)
        Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $snapshot, $null) } ([IO.InvalidDataException]) '1000000-pending'
        Assert-NoOwnedTemporary
    }
    Test-Case 'Cumulative linked reference count is bounded across directories' {
        $snapshot = New-Snapshot
        $links = New-LinkedReferences 500001
        $snapshot.Directories[0].LinkedFiles = $links
        $snapshot.Directories[1].LinkedFiles = $links
        Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $snapshot, $null) } ([IO.InvalidDataException]) 'total-linked'
        Set-CheckedBody (Get-UncheckedBody $snapshot)
        Assert-Throws { [FolderMap.CacheStore]::Load($script:MalformedPath, $null) } ([IO.InvalidDataException]) 'total-linked'
    }
    Test-Case 'Cancellation after temporary creation stops serialization and preserves the prior cache' {
        $snapshot = New-Snapshot
        $snapshot.Directories[0].LinkedFiles = New-LinkedReferences 800000
        $snapshot.Directories[0].DirectFiles = 800000
        $prior = [IO.File]::ReadAllBytes($script:GoodPath)
        $worker = [ComponentModel.BackgroundWorker]::new()
        $ready = [Threading.ManualResetEvent]::new($false)
        $runner = [PowerShell]::Create()
        $handle = $null
        try {
            $worker.WorkerSupportsCancellation = $true
            $null = $runner.AddScript(@'
param($directory, $worker, $ready)
$ErrorActionPreference = 'Stop'
$null = $ready.Set()
$deadline = [DateTime]::UtcNow.AddSeconds(20)
while ([DateTime]::UtcNow -lt $deadline) {
    if ([IO.Directory]::GetFiles($directory, '.foldermap-*.tmp').Length -gt 0) {
        $worker.CancelAsync()
        return
    }
    [Threading.Thread]::Sleep(1)
}
throw 'No serialization temporary was observed.'
'@).AddArgument($script:TestDirectory).AddArgument($worker).AddArgument($ready)
            $handle = $runner.BeginInvoke()
            Assert-True ($ready.WaitOne(5000)) 'Cancellation observer must be running before Save.'
            Assert-Throws { [FolderMap.CacheStore]::Save($script:GoodPath, $snapshot, $worker) } ([OperationCanceledException])
            $null = $runner.EndInvoke($handle)
            $handle = $null
            Assert-True (-not $runner.HadErrors) 'Cancellation observer must succeed.'
            Assert-True $worker.CancellationPending 'Cancellation must occur after temporary creation.'
            Assert-BytesEqual $prior ([IO.File]::ReadAllBytes($script:GoodPath)) 'Interrupted serialization must preserve the old checkpoint and payload.'
            Assert-NoOwnedTemporary
        } finally {
            if ($null -ne $handle) { $runner.Stop() }
            $runner.Dispose(); $ready.Dispose(); $worker.Dispose()
        }
    }
    Test-Case 'Valid snapshot can be read and saved after all failures' {
        Assert-SnapshotEqual $original ([FolderMap.CacheStore]::Load($script:GoodPath, $null))
        $worker = [ComponentModel.BackgroundWorker]::new()
        try {
            [FolderMap.CacheStore]::Save($script:GoodPath, $original, $worker)
            Assert-SnapshotEqual $original ([FolderMap.CacheStore]::Load($script:GoodPath, $worker))
        } finally { $worker.Dispose() }
        Assert-NoOwnedTemporary
    }
    Write-Output "PASS: $script:Passed cache-store tests; $script:Assertions assertions; $script:JitCount storage methods plus type initializer and DTO constructors JIT-prepared."
} finally {
    if ([IO.Directory]::Exists($script:TestDirectory)) {
        [IO.Directory]::Delete($script:TestDirectory, $true)
    }
}
