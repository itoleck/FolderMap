param(
    [string]$AssemblyPath,
    [switch]$Live,
    [switch]$SyntheticOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($Live -and $SyntheticOnly) { throw '-Live and -SyntheticOnly cannot be combined.' }

if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'bin\FolderMap.exe'
}
$AssemblyPath = [IO.Path]::GetFullPath($AssemblyPath)
if (-not [Environment]::Is64BitProcess -or [Environment]::Version.Major -ne 4) {
    throw 'Run these tests with x64 Windows PowerShell and .NET Framework 4.x.'
}
if (-not [IO.File]::Exists($AssemblyPath)) {
    throw "Assembly not found: $AssemblyPath. Build FolderMap or supply -AssemblyPath."
}
$assembly = [Reflection.Assembly]::LoadFrom($AssemblyPath)
$script:checks = 0
$script:skips = 0

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) {
        throw "$Message (expected $Expected, actual $Actual)"
    }
}

function Assert-Throws([type]$ExceptionType, [scriptblock]$Body, [string]$Message) {
    $caught = $null
    try { & $Body | Out-Null }
    catch { $caught = Get-OperationException $_.Exception }
    if ($null -eq $caught) { throw "$Message (no exception)" }
    if (-not $ExceptionType.IsInstanceOfType($caught)) {
        throw "$Message (expected $($ExceptionType.FullName), actual $($caught.GetType().FullName): $($caught.Message))"
    }
    return $caught
}

function Get-OperationException([Exception]$Exception) {
    while ($null -ne $Exception.InnerException -and
        ($Exception -is [Reflection.TargetInvocationException] -or
         $Exception -is [Management.Automation.RuntimeException])) {
        $Exception = $Exception.InnerException
    }
    return $Exception
}

function Test-Case([string]$Name, [scriptblock]$Body) {
    & $Body
    $script:checks++
    Write-Output "PASS $Name"
}

function Write-Skip([string]$Message) {
    $script:skips++
    Write-Output "SKIP $Message"
}

function Invoke-OptionalTokenDiagnostics([scriptblock]$Reader) {
    try {
        $diagnostics = & $Reader
        Assert-True ($diagnostics -cmatch '^access-conditions=[0-9A-F]{8};security-attribute-count=[0-9A-F]{8};user-claim-count=[0-9A-F]{8};device-claim-count=[0-9A-F]{8};$') 'Diagnostics must contain only condition flags and counts.'
        Write-Output "TOKEN DIAGNOSTICS (hex flags/counts only): $diagnostics"
    }
    catch {
        $failure = Get-OperationException $_.Exception
        if ($failure -isnot [Security.SecurityException] -and $failure -isnot [NotSupportedException]) { throw }
        Write-Output "TOKEN DIAGNOSTICS UNAVAILABLE: $($failure.Message)"
    }
}

function Put-U16([byte[]]$Buffer, [int]$Offset, [uint16]$Number) {
    [Buffer]::BlockCopy([BitConverter]::GetBytes($Number), 0, $Buffer, $Offset, 2)
}

function Put-U32([byte[]]$Buffer, [int]$Offset, [uint32]$Number) {
    [Buffer]::BlockCopy([BitConverter]::GetBytes($Number), 0, $Buffer, $Offset, 4)
}

function Put-U64([byte[]]$Buffer, [int]$Offset, [uint64]$Number) {
    [Buffer]::BlockCopy([BitConverter]::GetBytes($Number), 0, $Buffer, $Offset, 8)
}

function Put-I64([byte[]]$Buffer, [int]$Offset, [int64]$Number) {
    [Buffer]::BlockCopy([BitConverter]::GetBytes($Number), 0, $Buffer, $Offset, 8)
}

function New-UsnRecord(
    [int64]$Usn = 1024,
    [uint64]$FileId = 17,
    [uint64]$ParentId = 11,
    [uint32]$Reason = 256,
    [uint32]$Attributes = 32
) {
    $record = New-Object byte[] 64
    Put-U32 $record 0 64
    Put-U16 $record 4 2
    Put-U16 $record 6 0
    Put-U64 $record 8 $FileId
    Put-U64 $record 16 $ParentId
    Put-I64 $record 24 $Usn
    Put-U32 $record 40 $Reason
    Put-U32 $record 52 $Attributes
    Put-U16 $record 56 2
    Put-U16 $record 58 60
    # Synthetic, deliberately opaque UTF-16 bytes; the adapter must not interpret them.
    $record[60] = 255
    $record[61] = 216
    return ,$record
}

function New-UsnBuffer([object[]]$Records = @(), [int64]$Continuation = 2048) {
    $length = 8
    foreach ($record in $Records) { $length += $record.Length }
    $buffer = New-Object byte[] $length
    Put-I64 $buffer 0 $Continuation
    $position = 8
    foreach ($record in $Records) {
        [Buffer]::BlockCopy($record, 0, $buffer, $position, $record.Length)
        $position += $record.Length
    }
    return ,$buffer
}

$noReceiver = [Action[FolderMap.UsnChange]] { param($change) }
$flags = [Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly'
$typeNames = @(
    'FolderMap.FileIdentity', 'FolderMap.UsnCheckpoint', 'FolderMap.UsnChange',
    'FolderMap.NativeFileInformation', 'FolderMap.NtfsJournal', 'FolderMap.JournalSession',
    'FolderMap.NativeLuid', 'FolderMap.NativeTokenAccessInformation', 'FolderMap.AuthzAttributeCounts',
    'FolderMap.AuthzResourceManagerHandle', 'FolderMap.AuthzClientContextHandle',
    'FolderMap.AuthzAttributeSnapshot', 'FolderMap.NativeAuthzSecurityAttributeV1',
    'FolderMap.NativeAuthzFqbnValue', 'FolderMap.NativeAuthzOctetValue'
)

Test-Case 'Assembly is PE32+ AMD64 targeting CLR v4' {
    $peKind = [Reflection.PortableExecutableKinds]0
    $machine = [Reflection.ImageFileMachine]::I386
    $assembly.ManifestModule.GetPEKind([ref]$peKind, [ref]$machine)
    Assert-Equal ([Reflection.ImageFileMachine]::AMD64) $machine 'Native machine type.'
    Assert-True (($peKind -band [Reflection.PortableExecutableKinds]::PE32Plus) -ne 0) 'PE32+ image is required.'
    Assert-Equal 'v4.0.30319' $assembly.ImageRuntimeVersion 'CLR runtime version.'
}

Test-Case 'Every adapter method and native stub JIT-prepares' {
    $prepared = 0
    $bodies = 0
    foreach ($name in $typeNames) {
        $type = $assembly.GetType($name, $true)
        foreach ($method in @($type.GetMethods($flags)) + @($type.GetConstructors($flags))) {
            if ($method.IsAbstract) { continue }
            Assert-True (-not $method.ContainsGenericParameters) 'Unexpected open generic adapter method.'
            [Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
            $prepared++
            if ($null -ne $method.GetMethodBody()) { $bodies++ }
        }
    }
    Write-Output "JIT prepared $prepared methods ($bodies CIL bodies and $($prepared - $bodies) native stubs)."
}

Test-Case 'Exact unsigned DTO field contracts and default constructors' {
    $contracts = @{
        'FolderMap.FileIdentity' = @{ FileId = [uint64]; VolumeSerial = [uint32]; LinkCount = [uint32]; Attributes = [uint32]; Length = [int64] }
        'FolderMap.UsnCheckpoint' = @{ JournalId = [uint64]; FirstUsn = [int64]; NextUsn = [int64]; LowestValidUsn = [int64] }
        'FolderMap.UsnChange' = @{ FileId = [uint64]; ParentId = [uint64]; Reason = [uint32]; Attributes = [uint32]; Usn = [int64] }
    }
    foreach ($name in $contracts.Keys) {
        $type = $assembly.GetType($name, $true)
        $instance = [Activator]::CreateInstance($type)
        $fields = $type.GetFields([Reflection.BindingFlags]'Public,Instance,DeclaredOnly')
        Assert-Equal $contracts[$name].Count $fields.Count 'Unexpected public DTO fields.'
        foreach ($field in $fields) {
            Assert-Equal $contracts[$name][$field.Name] $field.FieldType 'DTO numeric field type.'
            Assert-Equal 0 $field.GetValue($instance) 'DTO fields must default to zero.'
        }
    }
    $sizeOfType = [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [type[]]@([type]))
    Assert-Equal 52 ($sizeOfType.Invoke($null, @($assembly.GetType('FolderMap.NativeFileInformation')))) 'Native identity structure size.'
}

function New-SyntheticTokenGroups([object[]]$Entries) {
    $sids = @()
    $length = 8 + 16 * $Entries.Count
    foreach ($entry in $Entries) {
        $sid = [Security.Principal.SecurityIdentifier]::new([string]$entry.Sid)
        $bytes = New-Object byte[] $sid.BinaryLength
        $sid.GetBinaryForm($bytes, 0)
        $sids += ,$bytes
        $length += $bytes.Length
    }
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal($length)
    try {
        [Runtime.InteropServices.Marshal]::Copy((New-Object byte[] $length), 0, $pointer, $length)
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, $Entries.Count)
        $sidOffset = 8 + 16 * $Entries.Count
        for ($i = 0; $i -lt $Entries.Count; $i++) {
            $entryOffset = 8 + 16 * $i
            $sidPointer = [IntPtr]::Add($pointer, $sidOffset)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($pointer, $entryOffset, $sidPointer)
            $attributes = [BitConverter]::GetBytes([uint32]$Entries[$i].Attributes)
            [Runtime.InteropServices.Marshal]::Copy($attributes, 0, [IntPtr]::Add($pointer, $entryOffset + 8), 4)
            [Runtime.InteropServices.Marshal]::Copy($sids[$i], 0, $sidPointer, $sids[$i].Length)
            $sidOffset += $sids[$i].Length
        }
        return [pscustomobject]@{ Pointer = $pointer; Length = $length }
    }
    catch {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer)
        throw
    }
}

Test-Case 'Canonical group keys ignore pointers, padding, and enumeration order but retain attributes' {
    $method = [FolderMap.NtfsJournal].GetMethod('CanonicalGroups', [Reflection.BindingFlags]'NonPublic,Static')
    $first = $null
    $second = $null
    try {
        $first = New-SyntheticTokenGroups @(
            @{ Sid = 'S-1-5-32-544'; Attributes = [uint32]7 },
            @{ Sid = 'S-1-5-11'; Attributes = [uint32]::Parse('3221225472') }
        )
        $second = New-SyntheticTokenGroups @(
            @{ Sid = 'S-1-5-11'; Attributes = [uint32]::Parse('3221225472') },
            @{ Sid = 'S-1-5-32-544'; Attributes = [uint32]7 }
        )
        Assert-True ($first.Pointer -ne $second.Pointer) 'Synthetic buffers must have different pointer addresses.'
        [Runtime.InteropServices.Marshal]::WriteInt32($second.Pointer, 4, -1)
        [Runtime.InteropServices.Marshal]::WriteInt32($second.Pointer, 20, -1)
        [Runtime.InteropServices.Marshal]::WriteInt32($second.Pointer, 36, -1)
        $one = $method.Invoke($null, [object[]]@($first.Pointer, [int]$first.Length))
        $two = $method.Invoke($null, [object[]]@($second.Pointer, [int]$second.Length))
        Assert-Equal 'S-1-5-11:C0000000;S-1-5-32-544:00000007' $one 'Canonical SID attributes.'
        Assert-Equal $one $two 'Pointer relocation, native padding, and order must not change canonical groups.'
        [Runtime.InteropServices.Marshal]::WriteInt32($second.Pointer, 32, 16)
        $denied = $method.Invoke($null, [object[]]@($second.Pointer, [int]$second.Length))
        Assert-True ($denied -cne $one) 'Deny-only versus enabled group attributes must change the key input.'
        [Runtime.InteropServices.Marshal]::WriteIntPtr($second.Pointer, 8, [IntPtr]::Add($second.Pointer, $second.Length))
        [void](Assert-Throws ([Security.SecurityException]) {
            $method.Invoke($null, [object[]]@($second.Pointer, [int]$second.Length))
        } 'Out-of-buffer SID pointers must fail closed before dereferencing.')
        [Runtime.InteropServices.Marshal]::WriteInt32($first.Pointer, [int]::MaxValue)
        [void](Assert-Throws ([Security.SecurityException]) {
            $method.Invoke($null, [object[]]@($first.Pointer, [int]$first.Length))
        } 'Oversized native group count.')
    }
    finally {
        if ($null -ne $second) { [Runtime.InteropServices.Marshal]::FreeHGlobal($second.Pointer) }
        if ($null -ne $first) { [Runtime.InteropServices.Marshal]::FreeHGlobal($first.Pointer) }
    }
}

Test-Case 'Canonical privileges preserve unsigned LUIDs and every attribute bit' {
    $method = [FolderMap.NtfsJournal].GetMethod('CanonicalPrivileges', [Reflection.BindingFlags]'NonPublic,Static')
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(28)
    try {
        $buffer = New-Object byte[] 28
        Put-U32 $buffer 0 2
        Put-U64 $buffer 4 ([uint64]::MaxValue)
        Put-U32 $buffer 12 ([uint32]::Parse('2147483651'))
        Put-U64 $buffer 16 23
        Put-U32 $buffer 24 2
        [Runtime.InteropServices.Marshal]::Copy($buffer, 0, $pointer, $buffer.Length)
        $one = $method.Invoke($null, [object[]]@($pointer, [int]28))
        Assert-Equal '0000000000000017:00000002;FFFFFFFFFFFFFFFF:80000003' $one 'Canonical privilege fields.'
        $reordered = New-Object byte[] 28
        Put-U32 $reordered 0 2
        [Buffer]::BlockCopy($buffer, 16, $reordered, 4, 12)
        [Buffer]::BlockCopy($buffer, 4, $reordered, 16, 12)
        [Runtime.InteropServices.Marshal]::Copy($reordered, 0, $pointer, 28)
        Assert-Equal $one ($method.Invoke($null, [object[]]@($pointer, [int]28))) 'Privilege order must not affect canonicalization.'
        Put-U32 $reordered 12 0
        [Runtime.InteropServices.Marshal]::Copy($reordered, 0, $pointer, 28)
        Assert-True ($one -cne $method.Invoke($null, [object[]]@($pointer, [int]28))) 'Enabled versus disabled privileges must change the key input.'
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, [int]::MaxValue)
        [void](Assert-Throws ([Security.SecurityException]) {
            $method.Invoke($null, [object[]]@($pointer, [int]28))
        } 'Oversized native privilege count.')
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

Test-Case 'Token fingerprints use a versioned SHA-256 digest' {
    $hash = [FolderMap.NtfsJournal].GetMethod('HashTokenContext', [Reflection.BindingFlags]'NonPublic,Static')
    $expected = 'ntfs-token-v3:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
    Assert-Equal $expected ($hash.Invoke($null, [object[]]@('abc'))) 'SHA-256 known-answer vector.'
}

function New-SyntheticAttributeSnapshot(
    [string]$Security = '6:AUTHZ18:00000000',
    [string]$User = '6:AUTHZ18:00000000',
    [string]$Device = '6:AUTHZ18:00000000',
    [switch]$CountsOnly
) {
    $type = $assembly.GetType('FolderMap.AuthzAttributeSnapshot', $true)
    $snapshot = [Activator]::CreateInstance($type)
    $type.GetField('SecurityAttributes').SetValue($snapshot, $Security)
    $type.GetField('UserClaims').SetValue($snapshot, $User)
    $type.GetField('DeviceClaims').SetValue($snapshot, $Device)
    $type.GetField('HasCanonicalData').SetValue($snapshot, -not $CountsOnly)
    return $snapshot
}

Test-Case 'TOKEN_ACCESS_INFORMATION and LUID use the documented x64 offsets' {
    $layout = $assembly.GetType('FolderMap.NativeTokenAccessInformation', $true)
    $luid = $assembly.GetType('FolderMap.NativeLuid', $true)
    $sizeOf = [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [type[]]@([type]))
    $offsetOf = [Runtime.InteropServices.Marshal].GetMethod('OffsetOf', [type[]]@([type], [string]))
    Assert-Equal 88 ($sizeOf.Invoke($null, @($layout))) 'TOKEN_ACCESS_INFORMATION x64 size.'
    Assert-Equal 8 ($sizeOf.Invoke($null, @($luid))) 'LUID size.'
    $offsets = @{
        SidHash = 0; RestrictedSidHash = 8; Privileges = 16; AuthenticationId = 24
        TokenType = 32; ImpersonationLevel = 36; MandatoryPolicy = 40; Flags = 44
        AppContainerNumber = 48; PackageSid = 56; CapabilitiesHash = 64
        TrustLevelSid = 72; SecurityAttributes = 80
    }
    foreach ($name in $offsets.Keys) {
        $offset = $offsetOf.Invoke($null, @($layout, $name))
        Assert-Equal $offsets[$name] $offset.ToInt32() "SDK offset for $name."
    }
    Assert-Equal 4 ($offsetOf.Invoke($null, @($luid, 'HighPart'))).ToInt32() 'LUID high-part offset.'
}

Test-Case 'Documented empty Authz headers tolerate unused pointers and reserved bytes' {
    $read = [FolderMap.NtfsJournal].GetMethod('ReadAuthzAttributeHeaderCount', [Reflection.BindingFlags]'NonPublic,Static')
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(16)
    try {
        $header = New-Object byte[] 16
        Put-U16 $header 0 1
        [Runtime.InteropServices.Marshal]::Copy($header, 0, $pointer, 16)
        Assert-Equal 0 ($read.Invoke($null, [object[]]@($pointer, [int]16))) 'Empty header with a null array pointer.'
        [Runtime.InteropServices.Marshal]::WriteInt16($pointer, 2, [int16]-1)
        [Runtime.InteropServices.Marshal]::WriteIntPtr($pointer, 8, [IntPtr]1234)
        Assert-Equal 0 ($read.Invoke($null, [object[]]@($pointer, [int]16))) 'Unused reserved/array-pointer fields are not an attribute count.'
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, 4, 1)
        Assert-Equal 1 ($read.Invoke($null, [object[]]@($pointer, [int]16))) 'Nonempty count must be preserved without reading claim values.'
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, 4, -1)
        Assert-Equal ([uint32]::MaxValue) ($read.Invoke($null, [object[]]@($pointer, [int]16))) 'Attribute count must not be sign-truncated.'
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

Test-Case 'Unknown, null, and truncated Authz headers fail closed' {
    $read = [FolderMap.NtfsJournal].GetMethod('ReadAuthzAttributeHeaderCount', [Reflection.BindingFlags]'NonPublic,Static')
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(16)
    try {
        $header = New-Object byte[] 16
        Put-U16 $header 0 1
        [Runtime.InteropServices.Marshal]::Copy($header, 0, $pointer, 16)
        foreach ($length in @(-1, 0, 1, 8, 15)) {
            [void](Assert-Throws ([Security.SecurityException]) {
                $read.Invoke($null, [object[]]@($pointer, [int]$length))
            } 'A complete typed attribute header is required.')
        }
        [void](Assert-Throws ([Security.SecurityException]) {
            $read.Invoke($null, [object[]]@([IntPtr]::Zero, [int]16))
        } 'A null native buffer is not proof of empty attributes.')
        foreach ($version in @(0, 2, -1)) {
            [Runtime.InteropServices.Marshal]::WriteInt16($pointer, [int16]$version)
            [void](Assert-Throws ([Security.SecurityException]) {
                $read.Invoke($null, [object[]]@($pointer, [int]16))
            } 'Unsupported attribute-header version must fail closed.')
        }
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

Test-Case 'Validated empty opaque containers produce the same key as null containers' {
    $canonical = [FolderMap.NtfsJournal].GetMethod('CanonicalTokenAccess', [Reflection.BindingFlags]'NonPublic,Static')
    $conditions = [FolderMap.NtfsJournal].GetMethod('TokenAccessConditions', [Reflection.BindingFlags]'NonPublic,Static')
    $hash = [FolderMap.NtfsJournal].GetMethod('HashTokenContext', [Reflection.BindingFlags]'NonPublic,Static')
    $empty = (New-SyntheticAttributeSnapshot).PSObject.BaseObject
    $first = [Runtime.InteropServices.Marshal]::AllocHGlobal(88)
    $second = [Runtime.InteropServices.Marshal]::AllocHGlobal(88)
    try {
        $header = New-Object byte[] 88
        Put-U64 $header 24 ([uint64]::MaxValue)
        Put-U32 $header 32 1
        Put-U32 $header 40 1
        [Runtime.InteropServices.Marshal]::Copy($header, 0, $first, 88)
        [Runtime.InteropServices.Marshal]::Copy($header, 0, $second, 88)
        [Runtime.InteropServices.Marshal]::WriteInt32($second, 52, -1)
        foreach ($offset in @(0, 8, 16, 64, 80)) {
            [Runtime.InteropServices.Marshal]::WriteIntPtr($second, $offset, [IntPtr](1234 + $offset))
        }
        Assert-Equal 0 ($conditions.Invoke($null, [object[]]@($first, [int]88))) 'Null opaque container condition flags.'
        Assert-Equal 16 ($conditions.Invoke($null, [object[]]@($second, [int]88))) 'A nonnull opaque pointer reports presence, not nonemptiness.'
        $one = $canonical.Invoke($null, [object[]]@($first, [int]88, $empty))
        $two = $canonical.Invoke($null, [object[]]@($second, [int]88, $empty))
        Assert-Equal $one $two 'Empty-container allocation, pointer values, and padding must not enter the key.'
        Assert-Equal ($hash.Invoke($null, [object[]]@($one))) ($hash.Invoke($null, [object[]]@($two))) 'Canonical fingerprint after pointer relocation.'
        Assert-True ($one.Contains("security-attributes=6:AUTHZ18:00000000`n") -and $one.Contains("user-claims=6:AUTHZ18:00000000`n") -and $one.Contains("device-claims=6:AUTHZ18:00000000`n")) 'All verified-empty sets must be represented in the versioned key.'
        [Runtime.InteropServices.Marshal]::WriteInt32($second, 40, 2)
        Assert-True ($one -cne $canonical.Invoke($null, [object[]]@($second, [int]88, $empty))) 'Mandatory authorization policy must still affect the key.'
    }
    finally {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($second)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($first)
    }
}

Test-Case 'Counts-only and incomplete snapshots cannot bypass canonical value validation' {
    $canonical = [FolderMap.NtfsJournal].GetMethod('CanonicalTokenAccess', [Reflection.BindingFlags]'NonPublic,Static')
    $snapshotType = $assembly.GetType('FolderMap.AuthzAttributeSnapshot', $true)
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(88)
    try {
        $header = New-Object byte[] 88
        Put-U32 $header 32 1
        foreach ($opaque in @([IntPtr]::Zero, [IntPtr]1234)) {
            [Runtime.InteropServices.Marshal]::Copy($header, 0, $pointer, 88)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($pointer, 80, $opaque)
            $countsOnly = (New-SyntheticAttributeSnapshot -CountsOnly).PSObject.BaseObject
            [void](Assert-Throws ([Security.SecurityException]) {
                $canonical.Invoke($null, [object[]]@($pointer, [int]88, $countsOnly))
            } 'Counts-only diagnostics are not authorization fingerprints.')
            foreach ($name in @('SecurityAttributes', 'UserClaims', 'DeviceClaims')) {
                $incomplete = (New-SyntheticAttributeSnapshot).PSObject.BaseObject
                $snapshotType.GetField($name).SetValue($incomplete, $null)
                [void](Assert-Throws ([Security.SecurityException]) {
                    $canonical.Invoke($null, [object[]]@($pointer, [int]88, $incomplete))
                } 'All three attribute sets must be fully serialized.')
            }
        }
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

Test-Case 'Primary-token, app-container, package, and extent checks remain mandatory' {
    $canonical = [FolderMap.NtfsJournal].GetMethod('CanonicalTokenAccess', [Reflection.BindingFlags]'NonPublic,Static')
    $conditions = [FolderMap.NtfsJournal].GetMethod('TokenAccessConditions', [Reflection.BindingFlags]'NonPublic,Static')
    $empty = (New-SyntheticAttributeSnapshot).PSObject.BaseObject
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(88)
    try {
        $header = New-Object byte[] 88
        Put-U32 $header 32 1
        foreach ($case in @(@(32, 2, 2), @(48, 1, 4), @(56, 1, 8))) {
            [Runtime.InteropServices.Marshal]::Copy($header, 0, $pointer, 88)
            [Runtime.InteropServices.Marshal]::WriteInt32($pointer, $case[0], $case[1])
            Assert-Equal $case[2] ($conditions.Invoke($null, [object[]]@($pointer, [int]88))) 'Distinct numeric diagnostic condition.'
            [void](Assert-Throws ([Security.SecurityException]) {
                $canonical.Invoke($null, [object[]]@($pointer, [int]88, $empty))
            } 'Unsupported native token identity state.')
        }
        Assert-Equal 1 ($conditions.Invoke($null, [object[]]@($pointer, [int]87))) 'Truncated header condition.'
        [void](Assert-Throws ([Security.SecurityException]) {
            $canonical.Invoke($null, [object[]]@($pointer, [int]87, $empty))
        } 'Truncated token access header.')
        [void](Assert-Throws ([Security.SecurityException]) {
            $canonical.Invoke($null, [object[]]@([IntPtr]::Zero, [int]88, $empty))
        } 'Null token access header.')
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer) }
}

function Reserve-SyntheticAttributeBytes($State, [int]$Size, [int]$Alignment = 8) {
    $offset = [int](($State.Next + $Alignment - 1) -band (-$Alignment))
    if ($Size -lt 0 -or ([int64]$offset + $Size) -gt $State.Data.Length) { throw 'Synthetic attribute fixture exceeds its allocation.' }
    $State.Next = $offset + $Size
    return $offset
}

function Add-SyntheticAttributeString($State, [string]$Text) {
    $encoding = [Text.UnicodeEncoding]::new($false, $false, $true)
    $bytes = $encoding.GetBytes($Text + [char]0)
    $offset = Reserve-SyntheticAttributeBytes $State $bytes.Length 2
    [Buffer]::BlockCopy($bytes, 0, $State.Data, $offset, $bytes.Length)
    return $offset
}

function Put-SyntheticAttributePointer($State, [int]$Field, [int]$Target) {
    Put-I64 $State.Data $Field ($State.Pointer.ToInt64() + $Target)
}

function New-SyntheticAuthzSet([object[]]$Attributes = @(), [int]$Padding = 0) {
    $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal(65536)
    try {
        $state = [pscustomobject]@{ Pointer = $pointer; Data = (New-Object byte[] 65536); Next = 16 + $Padding }
        $records = New-Object 'System.Collections.Generic.List[object]'
        Put-U16 $state.Data 0 1
        Put-U32 $state.Data 4 $Attributes.Count
        $table = Reserve-SyntheticAttributeBytes $state (32 * $Attributes.Count)
        if ($Attributes.Count -gt 0) { Put-SyntheticAttributePointer $state 8 $table }
        for ($i = 0; $i -lt $Attributes.Count; $i++) {
            $attribute = $Attributes[$i]
            $record = $table + 32 * $i
            $name = Add-SyntheticAttributeString $state ([string]$attribute.Name)
            Put-SyntheticAttributePointer $state $record $name
            Put-U16 $state.Data ($record + 8) $attribute.Type
            $attributeFlags = [uint32]0
            if ($attribute.ContainsKey('Flags')) { $attributeFlags = [uint32]$attribute.Flags }
            Put-U32 $state.Data ($record + 12) $attributeFlags
            $items = @($attribute.Values)
            Put-U32 $state.Data ($record + 16) $items.Count
            $stride = 8
            if ([int]$attribute.Type -in @(4, 5, 16)) { $stride = 16 }
            $values = Reserve-SyntheticAttributeBytes $state ($stride * $items.Count)
            if ($items.Count -gt 0) { Put-SyntheticAttributePointer $state ($record + 24) $values }
            $payloads = New-Object 'System.Collections.Generic.List[int]'
            for ($j = 0; $j -lt $items.Count; $j++) {
                $item = $items[$j]
                $position = $values + $stride * $j
                switch ([int]$attribute.Type) {
                    1 { Put-I64 $state.Data $position ([int64]$item); $payloads.Add($position) }
                    2 { Put-U64 $state.Data $position ([uint64]$item); $payloads.Add($position) }
                    3 {
                        $payload = Add-SyntheticAttributeString $state ([string]$item)
                        Put-SyntheticAttributePointer $state $position $payload
                        $payloads.Add($payload)
                    }
                    4 {
                        Put-U64 $state.Data $position ([uint64]$item.Version)
                        $payload = Add-SyntheticAttributeString $state ([string]$item.Name)
                        Put-SyntheticAttributePointer $state ($position + 8) $payload
                        $payloads.Add($payload)
                    }
                    5 {
                        $sid = [Security.Principal.SecurityIdentifier]::new([string]$item)
                        $bytes = New-Object byte[] $sid.BinaryLength
                        $sid.GetBinaryForm($bytes, 0)
                        $payload = Reserve-SyntheticAttributeBytes $state $bytes.Length
                        [Buffer]::BlockCopy($bytes, 0, $state.Data, $payload, $bytes.Length)
                        Put-SyntheticAttributePointer $state $position $payload
                        Put-U32 $state.Data ($position + 8) $bytes.Length
                        $payloads.Add($payload)
                    }
                    6 { Put-U64 $state.Data $position ([uint64]$item); $payloads.Add($position) }
                    16 {
                        $bytes = [byte[]]$item.Bytes
                        $payload = Reserve-SyntheticAttributeBytes $state $bytes.Length
                        if ($bytes.Length -gt 0) {
                            [Buffer]::BlockCopy($bytes, 0, $state.Data, $payload, $bytes.Length)
                            Put-SyntheticAttributePointer $state $position $payload
                        }
                        Put-U32 $state.Data ($position + 8) $bytes.Length
                        $payloads.Add($payload)
                    }
                    default { $payloads.Add($position) }
                }
            }
            $records.Add([pscustomobject]@{ Record = $record; Name = $name; Values = $values; Stride = $stride; Payloads = $payloads })
        }
        $length = [Math]::Max(16, $state.Next)
        [Runtime.InteropServices.Marshal]::Copy($state.Data, 0, $pointer, $length)
        return [pscustomobject]@{ Pointer = $pointer; Length = $length; Records = $records; Capacity = 65536 }
    }
    catch {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($pointer)
        throw
    }
}

function Get-SyntheticAuthzCanonical($Fixture) {
    $method = [FolderMap.NtfsJournal].GetMethod('CanonicalAuthzAttributes', [Reflection.BindingFlags]'NonPublic,Static')
    return $method.Invoke($null, [object[]]@([IntPtr]$Fixture.Pointer, [int]$Fixture.Length))
}

function Read-CanonicalAttributeParts([string]$Text) {
    $parts = New-Object 'System.Collections.Generic.List[string]'
    $position = 0
    while ($position -lt $Text.Length) {
        $colon = $Text.IndexOf(':', $position)
        if ($colon -lt $position) { throw 'Invalid synthetic canonical prefix.' }
        $length = [int]::Parse($Text.Substring($position, $colon - $position), [Globalization.CultureInfo]::InvariantCulture)
        $position = $colon + 1
        if ($length -lt 0 -or $length -gt $Text.Length - $position) { throw 'Invalid synthetic canonical part extent.' }
        $parts.Add($Text.Substring($position, $length))
        $position += $length
    }
    return ,$parts.ToArray()
}

function Get-SyntheticUtf16Hex([string]$Text) {
    return [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes($Text)).Replace('-', '')
}

$typedAttributes = @(
    @{ Name = 'Signed'; Type = 1; Flags = [uint32]0; Values = @([int64]::MinValue, [int64]-1, [int64]0, [int64]::MaxValue) },
    @{ Name = 'Unsigned'; Type = 2; Flags = [uint32]::MaxValue; Values = @([uint64]0, [uint64]::MaxValue) },
    @{ Name = 'String:attribute'; Type = 3; Flags = [uint32]2; Values = @('', "a:b`n=c;", 'zeta', [char]::ConvertFromUtf32(128578)) },
    @{ Name = 'BinaryName'; Type = 4; Flags = [uint32]0; Values = @(@{ Version = [uint64]::MaxValue; Name = 'Publisher\Product\File' }, @{ Version = [uint64]1; Name = 'Other' }) },
    @{ Name = 'Sid'; Type = 5; Flags = [uint32]0; Values = @('S-1-5-32-544', 'S-1-5-11') },
    @{ Name = 'Boolean'; Type = 6; Flags = [uint32]0; Values = @([uint64]0, [uint64]1) },
    @{ Name = 'Bytes'; Type = 16; Flags = [uint32]0; Values = @(@{ Bytes = [byte[]]@(0, 1, 255, 0) }, @{ Bytes = [byte[]]@() }) }
)

Test-Case 'Authz V1, FQBN, and octet layouts match documented x64 fields' {
    $sizeOf = [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [type[]]@([type]))
    $offsetOf = [Runtime.InteropServices.Marshal].GetMethod('OffsetOf', [type[]]@([type], [string]))
    $cases = @(
        @{ Type = 'FolderMap.NativeAuthzSecurityAttributeV1'; Size = 32; Offsets = @{ Name = 0; ValueType = 8; Reserved = 10; Flags = 12; ValueCount = 16; Values = 24 } },
        @{ Type = 'FolderMap.NativeAuthzFqbnValue'; Size = 16; Offsets = @{ Version = 0; Name = 8 } },
        @{ Type = 'FolderMap.NativeAuthzOctetValue'; Size = 16; Offsets = @{ Value = 0; Length = 8 } }
    )
    foreach ($case in $cases) {
        $type = $assembly.GetType($case.Type, $true)
        Assert-Equal $case.Size ($sizeOf.Invoke($null, @($type))) 'Native attribute structure size.'
        foreach ($field in $case.Offsets.Keys) {
            Assert-Equal $case.Offsets[$field] ($offsetOf.Invoke($null, @($type, $field))).ToInt32() 'Native attribute field offset.'
        }
    }
}

Test-Case 'Nonempty Authz sets encode all seven documented types and every field' {
    $fixture = New-SyntheticAuthzSet $typedAttributes
    try {
        $canonical = Get-SyntheticAuthzCanonical $fixture
        $parts = Read-CanonicalAttributeParts $canonical
        Assert-Equal 'AUTHZ1' $parts[0] 'Typed representation version.'
        Assert-Equal '00000007' $parts[1] 'Attribute count is encoded.'
        Assert-Equal 9 $parts.Count 'All attributes are encoded.'
        $entries = @{}
        foreach ($part in $parts[2..8]) {
            $entry = Read-CanonicalAttributeParts $part
            $entries[$entry[0]] = $entry
        }
        $signed = $entries[(Get-SyntheticUtf16Hex 'Signed')]
        Assert-Equal '00000001' $signed[1] 'Signed type tag.'
        Assert-Equal '00000004' $signed[3] 'Signed value count.'
        Assert-Equal '0000000000000000,7FFFFFFFFFFFFFFF,8000000000000000,FFFFFFFFFFFFFFFF' ($signed[4..7] -join ',') 'All signed 64-bit patterns.'
        $unsigned = $entries[(Get-SyntheticUtf16Hex 'Unsigned')]
        Assert-Equal 'FFFFFFFF' $unsigned[2] 'Every flag bit is retained.'
        Assert-Equal '0000000000000000,FFFFFFFFFFFFFFFF' ($unsigned[4..5] -join ',') 'Unsigned 64-bit patterns.'
        $strings = $entries[(Get-SyntheticUtf16Hex 'String:attribute')]
        Assert-True ($strings -contains (Get-SyntheticUtf16Hex "a:b`n=c;")) 'String code units and separators are preserved.'
        Assert-True ($strings -contains (Get-SyntheticUtf16Hex ([char]::ConvertFromUtf32(128578)))) 'Valid supplementary Unicode is preserved.'
        $fqbn = $entries[(Get-SyntheticUtf16Hex 'BinaryName')]
        $fqbnParts = Read-CanonicalAttributeParts $fqbn[5]
        Assert-Equal 'FFFFFFFFFFFFFFFF' $fqbnParts[0] 'FQBN version bits.'
        Assert-Equal (Get-SyntheticUtf16Hex 'Publisher\Product\File') $fqbnParts[1] 'FQBN name code units.'
        $sid = $entries[(Get-SyntheticUtf16Hex 'Sid')]
        Assert-Equal 'S-1-5-11,S-1-5-32-544' ($sid[4..5] -join ',') 'SID values are canonical, not pointer addresses.'
        $boolean = $entries[(Get-SyntheticUtf16Hex 'Boolean')]
        Assert-Equal '0000000000000000,0000000000000001' ($boolean[4..5] -join ',') 'Boolean values.'
        $octets = $entries[(Get-SyntheticUtf16Hex 'Bytes')]
        Assert-Equal '' $octets[4] 'Zero-length null octet value.'
        Assert-Equal '0001FF00' $octets[5] 'Octet bytes including embedded NUL.'
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
}

Test-Case 'Nonempty attribute keys ignore native pointers, padding, and semantic set ordering' {
    $reordered = @()
    for ($i = $typedAttributes.Count - 1; $i -ge 0; $i--) {
        $copy = @{}
        foreach ($key in $typedAttributes[$i].Keys) { $copy[$key] = $typedAttributes[$i][$key] }
        $copy.Values = @($copy.Values)
        [Array]::Reverse($copy.Values)
        $reordered += $copy
    }
    $first = New-SyntheticAuthzSet $typedAttributes
    $second = $null
    try {
        $second = New-SyntheticAuthzSet $reordered 24
        [Runtime.InteropServices.Marshal]::WriteInt16($second.Pointer, 2, [int16]-1)
        foreach ($record in $second.Records) {
            [Runtime.InteropServices.Marshal]::WriteInt16($second.Pointer, $record.Record + 10, [int16]-1)
            [Runtime.InteropServices.Marshal]::WriteInt32($second.Pointer, $record.Record + 20, -1)
        }
        Assert-True ($first.Pointer -ne $second.Pointer) 'Fixtures must have different base addresses.'
        Assert-Equal (Get-SyntheticAuthzCanonical $first) (Get-SyntheticAuthzCanonical $second) 'Relocation, reserved bytes, and attribute/value reordering must not change the canonical set.'
        $culture = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            $before = Get-SyntheticAuthzCanonical $first
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('ar-SA')
            Assert-Equal $before (Get-SyntheticAuthzCanonical $first) 'Length prefixes and numeric values must use invariant formatting.'
        }
        finally { [Threading.Thread]::CurrentThread.CurrentCulture = $culture }
    }
    finally {
        if ($null -ne $second) { [Runtime.InteropServices.Marshal]::FreeHGlobal($second.Pointer) }
        [Runtime.InteropServices.Marshal]::FreeHGlobal($first.Pointer)
    }
}

Test-Case 'Names, types, all flag bits, value counts, and scalar/string values affect the key' {
    $fixture = New-SyntheticAuthzSet @(@{ Name = 'Name'; Type = 3; Flags = [uint32]0; Values = @('value') })
    try {
        $baseline = Get-SyntheticAuthzCanonical $fixture
        $record = $fixture.Records[0]
        for ($bit = 0; $bit -lt 32; $bit++) {
            $mask = [uint32]([int64]1 -shl $bit)
            $bytes = [BitConverter]::GetBytes($mask)
            [Runtime.InteropServices.Marshal]::Copy($bytes, 0, [IntPtr]::Add($fixture.Pointer, $record.Record + 12), 4)
            Assert-True ($baseline -cne (Get-SyntheticAuthzCanonical $fixture)) 'Every flag bit must affect authorization comparison.'
        }
        [Runtime.InteropServices.Marshal]::WriteInt32($fixture.Pointer, $record.Record + 12, 0)
        [Runtime.InteropServices.Marshal]::WriteInt16($fixture.Pointer, $record.Name, [int16]77)
        Assert-True ($baseline -cne (Get-SyntheticAuthzCanonical $fixture)) 'Attribute names must affect the key.'
        [Runtime.InteropServices.Marshal]::WriteInt16($fixture.Pointer, $record.Name, [int16]78)
        [Runtime.InteropServices.Marshal]::WriteInt16($fixture.Pointer, $record.Payloads[0], [int16]86)
        Assert-True ($baseline -cne (Get-SyntheticAuthzCanonical $fixture)) 'String value case must not be discarded.'
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    $cases = @(
        @{ Name = 'Number'; Type = 1; Flags = [uint32]0; Values = @([int64]1) },
        @{ Name = 'Number'; Type = 2; Flags = [uint32]0; Values = @([uint64]1) },
        @{ Name = 'Number'; Type = 2; Flags = [uint32]0; Values = @([uint64]2) },
        @{ Name = 'Number'; Type = 2; Flags = [uint32]0; Values = @([uint64]1, [uint64]1) }
    )
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($case in $cases) {
        $fixture = New-SyntheticAuthzSet @($case)
        try { Assert-True ($seen.Add((Get-SyntheticAuthzCanonical $fixture))) 'Type, value, and duplicate/value-count changes must remain distinct.' }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    }
}

Test-Case 'Length prefixes prevent value-boundary and delimiter collisions' {
    $first = New-SyntheticAuthzSet @(@{ Name = "edge:;=`n"; Type = 3; Values = @('ab', 'c') })
    $second = $null
    try {
        $second = New-SyntheticAuthzSet @(@{ Name = "edge:;=`n"; Type = 3; Values = @('a', 'bc') })
        Assert-True ((Get-SyntheticAuthzCanonical $first) -cne (Get-SyntheticAuthzCanonical $second)) 'Equal concatenated strings with different boundaries must not collide.'
    }
    finally {
        if ($null -ne $second) { [Runtime.InteropServices.Marshal]::FreeHGlobal($second.Pointer) }
        [Runtime.InteropServices.Marshal]::FreeHGlobal($first.Pointer)
    }
}

Test-Case 'FQBN versions/names, SID identities, booleans, and octet bytes affect the key' {
    $pairs = @(
        @(
            @{ Name = 'Value'; Type = 4; Values = @(@{ Version = [uint64]1; Name = 'Publisher\Product\File' }) },
            @{ Name = 'Value'; Type = 4; Values = @(@{ Version = [uint64]2; Name = 'Publisher\Product\File' }) }
        ),
        @(
            @{ Name = 'Value'; Type = 4; Values = @(@{ Version = [uint64]1; Name = 'Publisher\Product\File' }) },
            @{ Name = 'Value'; Type = 4; Values = @(@{ Version = [uint64]1; Name = 'Publisher\Product\Other' }) }
        ),
        @(
            @{ Name = 'Value'; Type = 5; Values = @('S-1-5-11') },
            @{ Name = 'Value'; Type = 5; Values = @('S-1-5-32-544') }
        ),
        @(
            @{ Name = 'Value'; Type = 6; Values = @([uint64]0) },
            @{ Name = 'Value'; Type = 6; Values = @([uint64]1) }
        ),
        @(
            @{ Name = 'Value'; Type = 16; Values = @(@{ Bytes = [byte[]]@(0, 1, 255) }) },
            @{ Name = 'Value'; Type = 16; Values = @(@{ Bytes = [byte[]]@(0, 2, 255) }) }
        )
    )
    foreach ($pair in $pairs) {
        $first = New-SyntheticAuthzSet @($pair[0])
        $second = $null
        try {
            $second = New-SyntheticAuthzSet @($pair[1])
            Assert-True ((Get-SyntheticAuthzCanonical $first) -cne (Get-SyntheticAuthzCanonical $second)) 'Every documented value component must remain distinct.'
        }
        finally {
            if ($null -ne $second) { [Runtime.InteropServices.Marshal]::FreeHGlobal($second.Pointer) }
            [Runtime.InteropServices.Marshal]::FreeHGlobal($first.Pointer)
        }
    }
}

Test-Case 'Zero-value attributes remain represented without dereferencing unused storage' {
    $attributes = @()
    foreach ($type in @(1, 2, 3, 4, 5, 6, 16)) {
        $attributes += @{ Name = "Empty$type"; Type = $type; Values = @() }
    }
    $fixture = New-SyntheticAuthzSet $attributes
    try {
        $baseline = Get-SyntheticAuthzCanonical $fixture
        foreach ($record in $fixture.Records) {
            [Runtime.InteropServices.Marshal]::WriteIntPtr($fixture.Pointer, $record.Record + 24, [IntPtr]1234)
        }
        Assert-Equal $baseline (Get-SyntheticAuthzCanonical $fixture) 'A zero count makes its values pointer unused, not a value.'
        $parts = Read-CanonicalAttributeParts $baseline
        Assert-Equal '00000007' $parts[1] 'Empty value sets are not dropped as absent attributes.'
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
}

Test-Case 'Local, user, and device nonempty sets all participate in the authorization fingerprint' {
    $fixture = New-SyntheticAuthzSet @(@{ Name = 'Claim'; Type = 3; Values = @('nonempty') })
    $access = [Runtime.InteropServices.Marshal]::AllocHGlobal(88)
    try {
        $serialized = Get-SyntheticAuthzCanonical $fixture
        $header = New-Object byte[] 88
        Put-U32 $header 32 1
        [Runtime.InteropServices.Marshal]::Copy($header, 0, $access, 88)
        [Runtime.InteropServices.Marshal]::WriteIntPtr($access, 80, [IntPtr]1234)
        $method = [FolderMap.NtfsJournal].GetMethod('CanonicalTokenAccess', [Reflection.BindingFlags]'NonPublic,Static')
        $empty = (New-SyntheticAttributeSnapshot).PSObject.BaseObject
        $baseline = $method.Invoke($null, [object[]]@($access, [int]88, $empty))
        $seen = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($parameter in @('Security', 'User', 'Device')) {
            $parameters = @{}
            $parameters[$parameter] = $serialized
            $snapshot = (New-SyntheticAttributeSnapshot @parameters).PSObject.BaseObject
            $canonical = $method.Invoke($null, [object[]]@($access, [int]88, $snapshot))
            Assert-True ($canonical -cne $baseline) 'A nonempty set must affect authorization.'
            Assert-True ($seen.Add($canonical)) 'Local/user/device namespaces must not be interchangeable.'
        }
    }
    finally {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($access)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer)
    }
}

Test-Case 'Unsupported versions and value types fail closed even for zero-value attributes' {
    foreach ($type in @(0, 7, 15, 17, 65535)) {
        $fixture = New-SyntheticAuthzSet @(@{ Name = 'Unknown'; Type = $type; Values = @() })
        try {
            [void](Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Unknown type must never be silently omitted.')
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    }
    $fixture = New-SyntheticAuthzSet @(@{ Name = 'Known'; Type = 2; Values = @([uint64]1) })
    try {
        [Runtime.InteropServices.Marshal]::WriteInt16($fixture.Pointer, [int16]2)
        [void](Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Unknown structure version.')
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
}

Test-Case 'Duplicate attribute names cannot conceal order-dependent authorization data' {
    foreach ($secondName in @('duplicate', 'DUPLICATE')) {
        $fixture = New-SyntheticAuthzSet @(
            @{ Name = 'duplicate'; Type = 2; Values = @([uint64]1) },
            @{ Name = $secondName; Type = 2; Values = @([uint64]2) }
        )
        try {
            [void](Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Ambiguous duplicate attribute names must fail closed.')
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    }
}

Test-Case 'Malformed attribute arrays, name pointers, strings, and value extents are rejected' {
    $mutations = @(
        { param($f) [Runtime.InteropServices.Marshal]::WriteInt32($f.Pointer, 4, -1) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, 8, [IntPtr]::Zero) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, 8, [IntPtr]::Add($f.Pointer, $f.Length - 31)) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Record, [IntPtr]::Zero) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Record, [IntPtr]::Add($f.Pointer, $f.Length - 1)) },
        {
            param($f)
            [Runtime.InteropServices.Marshal]::WriteInt16($f.Pointer, $f.Length - 2, [int16]65)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Record, [IntPtr]::Add($f.Pointer, $f.Length - 2))
        },
        { param($f) [Runtime.InteropServices.Marshal]::WriteInt16($f.Pointer, $f.Records[0].Name, [int16]0) },
        {
            param($f)
            [Runtime.InteropServices.Marshal]::WriteInt16($f.Pointer, $f.Records[0].Name, [int16]-10240)
            [Runtime.InteropServices.Marshal]::WriteInt16($f.Pointer, $f.Records[0].Name + 2, [int16]0)
        },
        { param($f) [Runtime.InteropServices.Marshal]::WriteInt16($f.Pointer, $f.Records[0].Name, [int16]-9216) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteInt32($f.Pointer, $f.Records[0].Record + 16, -1) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Record + 24, [IntPtr]::Zero) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Record + 24, [IntPtr]::Add($f.Pointer, $f.Length - 7)) },
        { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Values, [IntPtr]::Zero) }
    )
    foreach ($mutate in $mutations) {
        $fixture = New-SyntheticAuthzSet @(@{ Name = 'Valid'; Type = 3; Values = @('text') })
        try {
            & $mutate $fixture
            [void](Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Malformed native pointer/extent/UTF-16 must fail before unsafe reads.')
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    }
}

Test-Case 'Invalid booleans, SIDs, FQBN names, and octet bounds fail closed' {
    $cases = @(
        @{ Attribute = @{ Name = 'Bool'; Type = 6; Values = @([uint64]2) }; Mutate = { param($f) } },
        @{ Attribute = @{ Name = 'Bool'; Type = 6; Values = @([uint64]::MaxValue) }; Mutate = { param($f) } },
        @{ Attribute = @{ Name = 'Sid'; Type = 5; Values = @('S-1-5-11') }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteInt32($f.Pointer, $f.Records[0].Values + 8, 8) } },
        @{ Attribute = @{ Name = 'Sid'; Type = 5; Values = @('S-1-5-11') }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteByte($f.Pointer, $f.Records[0].Payloads[0], [byte]2) } },
        @{ Attribute = @{ Name = 'Fqbn'; Type = 4; Values = @(@{ Version = [uint64]1; Name = 'Valid' }) }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Values + 8, [IntPtr]::Zero) } },
        @{ Attribute = @{ Name = 'Octet'; Type = 16; Values = @(@{ Bytes = [byte[]]@(1) }) }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteInt32($f.Pointer, $f.Records[0].Values + 8, -1) } },
        @{ Attribute = @{ Name = 'Octet'; Type = 16; Values = @(@{ Bytes = [byte[]]@(1) }) }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Values, [IntPtr]::Zero) } },
        @{ Attribute = @{ Name = 'Octet'; Type = 16; Values = @(@{ Bytes = [byte[]]@(1) }) }; Mutate = { param($f) [Runtime.InteropServices.Marshal]::WriteIntPtr($f.Pointer, $f.Records[0].Values, [IntPtr]::Subtract($f.Pointer, 1)) } }
    )
    foreach ($case in $cases) {
        $fixture = New-SyntheticAuthzSet @($case.Attribute)
        try {
            & $case.Mutate $fixture
            [void](Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Malformed typed value must fail closed.')
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
    }
}

Test-Case 'Aliased attribute pointers cannot cause unbounded canonical expansion' {
    $fixture = New-SyntheticAuthzSet @(@{ Name = 'Budget'; Type = 3; Values = @(('x' * 4096)) })
    try {
        $array = [int](($fixture.Length + 7) -band -8)
        $count = 2000
        $length = $array + 8 * $count
        Assert-True ($length -lt $fixture.Capacity) 'Amplification fixture must remain inside its allocation.'
        for ($i = 0; $i -lt $count; $i++) {
            [Runtime.InteropServices.Marshal]::WriteIntPtr($fixture.Pointer, $array + 8 * $i, [IntPtr]::Add($fixture.Pointer, $fixture.Records[0].Payloads[0]))
        }
        [Runtime.InteropServices.Marshal]::WriteInt32($fixture.Pointer, $fixture.Records[0].Record + 16, $count)
        [Runtime.InteropServices.Marshal]::WriteIntPtr($fixture.Pointer, $fixture.Records[0].Record + 24, [IntPtr]::Add($fixture.Pointer, $array))
        $fixture.Length = $length
        $failure = Assert-Throws ([Security.SecurityException]) { Get-SyntheticAuthzCanonical $fixture } 'Canonicalization must be bounded even when pointers alias.'
        Assert-True ($failure.Message -match 'budget|size') 'Amplification must fail through a deliberate bound.'
    }
    finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($fixture.Pointer) }
}

Test-Case 'Explicitly unsupported diagnostics do not abort later live journal work' {
    foreach ($reader in @(
        { throw [Security.SecurityException]::new('Synthetic unsupported security context.') },
        { throw [NotSupportedException]::new('Synthetic unsupported context backend.') }
    )) {
        $continued = $false
        $output = @(Invoke-OptionalTokenDiagnostics $reader)
        $continued = $true
        Assert-True $continued 'Journal test flow must remain reachable.'
        Assert-True (($output -join '') -like 'TOKEN DIAGNOSTICS UNAVAILABLE:*') 'Unsupported diagnostics must be explicit.'
    }
    [void](Assert-Throws ([InvalidOperationException]) {
        Invoke-OptionalTokenDiagnostics { throw [InvalidOperationException]::new('Synthetic unexpected bug.') }
    } 'Unexpected diagnostic bugs must not be silently swallowed.')
}

if (-not $SyntheticOnly) {
    Test-Case 'Fixed-width token queries use a real buffer instead of a size probe' {
        $nativeType = $assembly.GetType('FolderMap.NtfsJournal')
        $nativeFlags = [Reflection.BindingFlags]'Static,NonPublic'
        $tokenHandle = $nativeType.GetMethod('OpenSecurityToken', $nativeFlags).Invoke($null, @())
        try {
            $readNumber = $nativeType.GetMethod('TokenUInt32', $nativeFlags)
            foreach ($informationClass in @(8, 12, 15, 18, 20, 21, 23, 24, 26, 27, 29)) {
                $number = $readNumber.Invoke($null, [object[]]@($tokenHandle, [int]$informationClass))
                Assert-True ($number -is [uint32]) 'A fixed-width token query must return its actual unsigned value.'
                if ($informationClass -in @(15, 20, 21, 23, 24, 26, 29)) {
                    Assert-True ($number -le 1) 'Token boolean classes must remain boolean.'
                }
            }
        } finally { $tokenHandle.Dispose() }
    }
    $fingerprint = $null
    try { $fingerprint = [FolderMap.NtfsJournal]::SecurityContext() }
    catch {
        $cause = Get-OperationException $_.Exception
        if ($cause -isnot [Security.SecurityException] -and $cause -isnot [NotSupportedException]) { throw }
        Test-Case 'Unsupported current token fails closed consistently' {
            [void](Assert-Throws ($cause.GetType()) {
                [FolderMap.NtfsJournal]::SecurityContext()
            } 'Unsupported authorization contexts must not produce reusable cache keys.')
        }
        $nativeCode = ''
        if ($cause.InnerException -is [ComponentModel.Win32Exception]) {
            $nativeCode = " (Win32 $($cause.InnerException.NativeErrorCode))"
        }
        Write-Skip "Token fingerprint unavailable; a full scan is required$nativeCode`: $($cause.Message)"
    }
    if ($null -ne $fingerprint) {
        Test-Case 'Same-token fingerprints are nonempty, canonical, and stable without querying a journal' {
            Assert-True ($fingerprint -cmatch '^ntfs-token-v3:[0-9a-f]{64}$') 'Canonical versioned SHA-256 key format.'
            for ($i = 0; $i -lt 3; $i++) {
                Assert-True ($fingerprint -ceq [FolderMap.NtfsJournal]::SecurityContext()) 'The unchanged Windows token must have a stable fingerprint.'
            }
        }
        Test-Case 'Token fingerprints are independent of the managed thread culture' {
            $culture = [Threading.Thread]::CurrentThread.CurrentCulture
            $uiCulture = [Threading.Thread]::CurrentThread.CurrentUICulture
            try {
                [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('ar-SA')
                [Threading.Thread]::CurrentThread.CurrentUICulture = [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
                Assert-True ($fingerprint -ceq [FolderMap.NtfsJournal]::SecurityContext()) 'Locale changes must not alter authorization fingerprints.'
            }
            finally {
                [Threading.Thread]::CurrentThread.CurrentCulture = $culture
                [Threading.Thread]::CurrentThread.CurrentUICulture = $uiCulture
            }
        }
        Test-Case 'Process restarts produce valid fingerprints without assuming equivalent authorization attributes' {
            $escapedAssembly = $AssemblyPath.Replace("'", "''")
            $childCode = '$ErrorActionPreference = "Stop"; [void][Reflection.Assembly]::LoadFrom(' +
                "'$escapedAssembly'" + '); [FolderMap.NtfsJournal]::SecurityContext()'
            $encodedChild = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCode))
            $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            for ($i = 0; $i -lt 2; $i++) {
                $childOutput = @(& $powershell -NoProfile -NonInteractive -EncodedCommand $encodedChild)
                Assert-Equal 0 $LASTEXITCODE 'Read-only child token fingerprinting must succeed.'
                Assert-Equal 1 $childOutput.Count 'Child fingerprint output count.'
                Assert-True ([string]$childOutput[0] -cmatch '^ntfs-token-v3:[0-9a-f]{64}$') 'A child must return a valid authorization fingerprint; per-process security attributes may legitimately differ.'
            }
        }
    }
    if ($Live) {
        Invoke-OptionalTokenDiagnostics { [FolderMap.NtfsJournal]::SecurityContextDiagnostics() }
    }
}

$highId = [uint64]::Parse('18364758544493064720')
$highParent = [uint64]::MaxValue
$closeReason = [uint32]::Parse('2147483648')
$highAttributes = [uint32]::Parse('2147483680')
$single = New-UsnBuffer -Records @(New-UsnRecord -FileId $highId -ParentId $highParent -Reason $closeReason -Attributes $highAttributes)

Test-Case 'Numeric extraction preserves unsigned 64-bit references and high reason bits' {
    $received = New-Object 'System.Collections.Generic.List[FolderMap.UsnChange]'
    $receiver = [Action[FolderMap.UsnChange]] { param($change) $received.Add($change) }.GetNewClosure()
    $continuation = [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length, 0, 2048, $receiver, $null)
    Assert-Equal 2048 $continuation 'Continuation USN.'
    Assert-Equal 1 $received.Count 'Selected record count.'
    Assert-Equal $highId $received[0].FileId 'Unsigned file reference.'
    Assert-Equal $highParent $received[0].ParentId 'Unsigned parent reference.'
    Assert-Equal $closeReason $received[0].Reason 'Unsigned reason mask.'
    Assert-Equal $highAttributes $received[0].Attributes 'Unsigned attributes.'
    Assert-Equal 1024 $received[0].Usn 'Record USN.'
}

$reasons = @([uint32]1, [uint32]2, [uint32]4, [uint32]256, [uint32]512, [uint32]4096, [uint32]8192, $closeReason)
$manyRecords = @()
for ($i = 0; $i -lt $reasons.Count; $i++) {
    $manyRecords += ,(New-UsnRecord -Usn (1024 + 128 * $i) -Reason $reasons[$i])
}
$many = New-UsnBuffer -Records $manyRecords -Continuation 2048

Test-Case 'Multiple records preserve data/create/delete/rename/close reasons' {
    $received = New-Object 'System.Collections.Generic.List[FolderMap.UsnChange]'
    $receiver = [Action[FolderMap.UsnChange]] { param($change) $received.Add($change) }.GetNewClosure()
    Assert-Equal 2048 ([FolderMap.NtfsJournal]::ParseBuffer($many, $many.Length, 0, 2048, $receiver, $null)) 'Multiple-record continuation.'
    Assert-Equal $reasons.Count $received.Count 'Multiple-record count.'
    for ($i = 0; $i -lt $reasons.Count; $i++) {
        Assert-Equal $reasons[$i] $received[$i].Reason 'Reason value and order.'
        Assert-Equal (1024 + 128 * $i) $received[$i].Usn 'USN order.'
    }
}

Test-Case 'Half-open range excludes old and late records without changing continuation' {
    $received = New-Object 'System.Collections.Generic.List[FolderMap.UsnChange]'
    $receiver = [Action[FolderMap.UsnChange]] { param($change) $received.Add($change) }.GetNewClosure()
    Assert-Equal 2048 ([FolderMap.NtfsJournal]::ParseBuffer($many, $many.Length, 1280, 1664, $receiver, $null)) 'Unclipped parser continuation.'
    Assert-Equal 3 $received.Count 'Half-open range count.'
    Assert-Equal 1280 $received[0].Usn 'Inclusive minimum.'
    Assert-Equal 1536 $received[2].Usn 'Exclusive maximum.'
    $received.Clear()
    [void][FolderMap.NtfsJournal]::ParseBuffer($many, $many.Length, 1280, 1280, $receiver, $null)
    Assert-Equal 0 $received.Count 'Empty range must not deliver records.'
}

Test-Case 'Empty output, zero USN, and unused capacity are accepted correctly' {
    $empty = New-UsnBuffer -Continuation 0
    Assert-Equal 0 ([FolderMap.NtfsJournal]::ParseBuffer($empty, 8, 0, 0, $noReceiver, $null)) 'Empty-buffer continuation.'
    $zero = New-UsnBuffer -Records @(New-UsnRecord -Usn 0) -Continuation 64
    Assert-Equal 64 ([FolderMap.NtfsJournal]::ParseBuffer($zero, $zero.Length, 0, 64, $noReceiver, $null)) 'Zero is a valid record USN.'
    $capacity = New-Object byte[] 65536
    [Buffer]::BlockCopy($single, 0, $capacity, 0, $single.Length)
    $capacity[$single.Length] = 255
    Assert-Equal 2048 ([FolderMap.NtfsJournal]::ParseBuffer($capacity, $single.Length, 0, 2048, $noReceiver, $null)) 'Only bytesReturned may be parsed.'
}

Test-Case 'Parser invalid arguments are rejected' {
    [void](Assert-Throws ([ArgumentNullException]) { [FolderMap.NtfsJournal]::ParseBuffer($null, 8, 0, 2048, $noReceiver, $null) } 'Null buffer.')
    [void](Assert-Throws ([ArgumentNullException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length, 0, 2048, $null, $null) } 'Null receiver.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, -1, 0, 2048, $noReceiver, $null) } 'Negative byte count.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length + 1, 0, 2048, $noReceiver, $null) } 'Oversized byte count.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length, -1, 2048, $noReceiver, $null) } 'Negative minimum USN.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length, 20, 19, $noReceiver, $null) } 'Reversed range.')
}

foreach ($length in @([uint32]0, [uint32]8, [uint32]56, [uint32]60, [uint32]63, [uint32]72, [uint32]::MaxValue, [uint32]::Parse('2147483648'))) {
    Test-Case "Malformed record length $length" {
        $bad = [byte[]]$single.Clone()
        Put-U32 $bad 8 $length
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Invalid record length/alignment must fail.')
    }
}

foreach ($extent in @(@(3, 60), @(2, 0), @(2, 58), @(2, 59), @(2, 61), @(2, 66), @(4, 62), @(65534, 60))) {
    Test-Case "Malformed filename extent length=$($extent[0]) offset=$($extent[1])" {
        $bad = [byte[]]$single.Clone()
        Put-U16 $bad (8 + 56) $extent[0]
        Put-U16 $bad (8 + 58) $extent[1]
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Invalid UTF-16 extent must fail without decoding.')
    }
}

foreach ($version in @(@(1, 0), @(3, 0), @(4, 0), @(65535, 0), @(2, 1))) {
    Test-Case "Unsupported record version $($version[0]).$($version[1])" {
        $bad = [byte[]]$single.Clone()
        Put-U16 $bad (8 + 4) $version[0]
        Put-U16 $bad (8 + 6) $version[1]
        [void](Assert-Throws ([NotSupportedException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Unsupported record version must explicitly fail.')
    }
}

Test-Case 'Truncated continuation and every incomplete trailing header are rejected' {
    for ($length = 0; $length -lt 8; $length++) {
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $length, 0, 2048, $noReceiver, $null) } 'Truncated continuation.')
    }
    for ($tail = 1; $tail -lt 8; $tail++) {
        $bad = New-Object byte[] ($single.Length + $tail)
        [Buffer]::BlockCopy($single, 0, $bad, 0, $single.Length)
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Incomplete trailing record header.')
    }
    [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length - 1, 0, 2048, $noReceiver, $null) } 'Incomplete trailing record body.')
}

Test-Case 'Negative, duplicate, descending, and non-continuing USNs are rejected' {
    foreach ($usn in @([int64]-1, [int64]2048, [int64]2049)) {
        $bad = [byte[]]$single.Clone()
        Put-I64 $bad (8 + 24) $usn
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Record USN must be nonnegative and precede continuation.')
    }
    foreach ($usn in @([int64]1024, [int64]1023)) {
        $bad = New-UsnBuffer -Records @((New-UsnRecord -Usn 1024), (New-UsnRecord -Usn $usn))
        [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Record USNs must strictly increase.')
    }
    $bad = [byte[]]$single.Clone()
    Put-I64 $bad 0 -1
    [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 2048, $noReceiver, $null) } 'Negative continuation.')
}

Test-Case 'Filtered-out malformed and unsupported records still fail' {
    $bad = [byte[]]$single.Clone()
    Put-U16 $bad (8 + 58) 59
    [void](Assert-Throws ([IO.InvalidDataException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 2048, 4096, $noReceiver, $null) } 'Old records must still be validated.')
    $bad = [byte[]]$single.Clone()
    Put-U16 $bad (8 + 4) 3
    [void](Assert-Throws ([NotSupportedException]) { [FolderMap.NtfsJournal]::ParseBuffer($bad, $bad.Length, 0, 1, $noReceiver, $null) } 'Late records must still be validated.')
}

Test-Case 'Cancellation interrupts empty buffers and long record streams' {
    $worker = New-Object ComponentModel.BackgroundWorker
    $worker.WorkerSupportsCancellation = $true
    $worker.CancelAsync()
    $empty = New-UsnBuffer
    [void](Assert-Throws ([OperationCanceledException]) { [FolderMap.NtfsJournal]::ParseBuffer($empty, 8, 0, 2048, $noReceiver, $worker) } 'Already-canceled worker.')
    $worker.Dispose()
    $worker = New-Object ComponentModel.BackgroundWorker
    $worker.WorkerSupportsCancellation = $true
    try {
        $records = @()
        for ($i = 0; $i -lt 1024; $i++) { $records += ,(New-UsnRecord -Usn (128 * $i)) }
        $longBuffer = New-UsnBuffer -Records $records -Continuation 131072
        $received = New-Object 'System.Collections.Generic.List[FolderMap.UsnChange]'
        $receiver = [Action[FolderMap.UsnChange]] {
            param($change)
            $received.Add($change)
            if ($received.Count -eq 3) { $worker.CancelAsync() }
        }.GetNewClosure()
        [void](Assert-Throws ([OperationCanceledException]) { [FolderMap.NtfsJournal]::ParseBuffer($longBuffer, $longBuffer.Length, 0, 131072, $receiver, $worker) } 'Cancellation between records.')
        Assert-Equal 3 $received.Count 'Cancellation must interrupt the same buffer.'
    }
    finally { $worker.Dispose() }
}

Test-Case 'Receiver exceptions propagate without a success-shaped result' {
    $receiver = [Action[FolderMap.UsnChange]] { param($change) throw [InvalidOperationException]::new('Synthetic receiver failure.') }
    [void](Assert-Throws ([InvalidOperationException]) { [FolderMap.NtfsJournal]::ParseBuffer($single, $single.Length, 0, 2048, $receiver, $null) } 'Receiver exception must propagate.')
}

Test-Case 'Synthetic checkpoint validation enforces ID, both retention bounds, and finite stop' {
    $validateRange = [FolderMap.JournalSession].GetMethod('ValidateRange', [Reflection.BindingFlags]'NonPublic,Static')
    $checkpoint = [FolderMap.UsnCheckpoint]::new()
    $checkpoint.JournalId = $highId
    $checkpoint.FirstUsn = 64
    $checkpoint.LowestValidUsn = 128
    $checkpoint.NextUsn = 1024
    $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]128, $highId, [int64]1024))
    $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]1024, $highId, [int64]1024))
    [void](Assert-Throws ([IO.IOException]) { $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]128, [uint64]1, [int64]1024)) } 'Journal ID mismatch.')
    [void](Assert-Throws ([IO.IOException]) { $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]64, $highId, [int64]1024)) } 'LowestValidUsn is a retention boundary.')
    $checkpoint.FirstUsn = 256
    [void](Assert-Throws ([IO.IOException]) { $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]128, $highId, [int64]1024)) } 'FirstUsn is independently a retention boundary.')
    [void](Assert-Throws ([IO.IOException]) { $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]256, $highId, [int64]1025)) } 'Stop cannot reach future changes.')
    [void](Assert-Throws ([IO.IOException]) { $validateRange.Invoke($null, [object[]]@($checkpoint, [int64]512, $highId, [int64]256)) } 'Reversed checkpoint range.')
}

Test-Case 'Disposed session and invalid arguments require no volume journal access' {
    $session = [Runtime.Serialization.FormatterServices]::GetUninitializedObject([FolderMap.JournalSession])
    $session.Dispose()
    $session.Dispose()
    [void](Assert-Throws ([ObjectDisposedException]) { $session.Query() } 'Disposed query.')
    [void](Assert-Throws ([ObjectDisposedException]) { $session.ReadChanges(0, 1, 0, $noReceiver, $null) } 'Disposed read.')
    [void](Assert-Throws ([ArgumentNullException]) { $session.ReadChanges(0, 1, 0, $null, $null) } 'Null read receiver.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { $session.ReadChanges(-1, 1, 0, $noReceiver, $null) } 'Negative read start.')
    [void](Assert-Throws ([ArgumentOutOfRangeException]) { $session.ReadChanges(2, 1, 1, $noReceiver, $null) } 'Reversed read range.')
    $worker = New-Object ComponentModel.BackgroundWorker
    $worker.WorkerSupportsCancellation = $true
    $worker.CancelAsync()
    try {
        [void](Assert-Throws ([OperationCanceledException]) { $session.ReadChanges(0, 1, 0, $noReceiver, $worker) } 'Read cancellation before a native call.')
    }
    finally { $worker.Dispose() }
    [void](Assert-Throws ([ArgumentNullException]) { [FolderMap.NtfsJournal]::GetIdentity([NullString]::Value) } 'Null identity path.')
    [void](Assert-Throws ([ArgumentException]) { [FolderMap.NtfsJournal]::GetIdentity('') } 'Empty identity path.')
    [void](Assert-Throws ([ArgumentNullException]) { [FolderMap.NtfsJournal]::Open([NullString]::Value) } 'Null root.')
    foreach ($path in @('', 'relative', '\rooted', 'C:relative')) {
        [void](Assert-Throws ([ArgumentException]) { [FolderMap.NtfsJournal]::Open($path) } 'Non-absolute root.')
    }
    foreach ($path in @('\\invalid.example\share\folder', '\\?\UNC\invalid.example\share\folder')) {
        [void](Assert-Throws ([NotSupportedException]) { [FolderMap.NtfsJournal]::Open($path) } 'UNC paths must be rejected without network access.')
    }
}

if ($SyntheticOnly) {
    Write-Output "USN SYNTHETIC TESTS PASSED: $script:checks checks; no current token, native identity fixture, or volume journal was opened."
    return
}

# Keep the unique disposable fixture in the project, not in a shared system temporary directory.
$fixtureRoot = Join-Path $PSScriptRoot ('.usn-fixture-' + [Guid]::NewGuid().ToString('N'))
$ownedFiles = New-Object 'System.Collections.Generic.List[string]'
$ownedDirectories = New-Object 'System.Collections.Generic.List[string]'
$ownedDirectoryLinks = New-Object 'System.Collections.Generic.List[string]'
$journalSession = $null
[void][IO.Directory]::CreateDirectory($fixtureRoot)
try {
    $filePath = Join-Path $fixtureRoot 'identity.bin'
    $ownedFiles.Add($filePath)
    [IO.File]::WriteAllBytes($filePath, (New-Object byte[] 257))
    $directoryPath = Join-Path $fixtureRoot 'directory'
    $ownedDirectories.Add($directoryPath)
    [void][IO.Directory]::CreateDirectory($directoryPath)
    $rootIdentity = [FolderMap.NtfsJournal]::GetIdentity($fixtureRoot)
    $fileIdentity = [FolderMap.NtfsJournal]::GetIdentity($filePath)
    $directoryIdentity = [FolderMap.NtfsJournal]::GetIdentity($directoryPath)

    Test-Case 'Native file and directory identity, lengths, and volume serials' {
        Assert-True (($rootIdentity.Attributes -band 16) -ne 0) 'Fixture root directory attribute.'
        Assert-True (($directoryIdentity.Attributes -band 16) -ne 0) 'Child directory attribute.'
        Assert-True (($fileIdentity.Attributes -band 16) -eq 0) 'File must not be reported as a directory.'
        Assert-Equal 257 $fileIdentity.Length 'Native logical file length.'
        Assert-True ($fileIdentity.FileId -ne 0 -and $directoryIdentity.FileId -ne 0) 'Native file IDs must not be defaults.'
        Assert-True ($rootIdentity.FileId -ne $directoryIdentity.FileId -and $fileIdentity.FileId -ne $directoryIdentity.FileId) 'Distinct objects must have distinct references.'
        Assert-Equal $rootIdentity.VolumeSerial $fileIdentity.VolumeSerial 'File volume serial.'
        Assert-Equal $rootIdentity.VolumeSerial $directoryIdentity.VolumeSerial 'Directory volume serial.'
        Assert-True ($fileIdentity.LinkCount -ge 1) 'File hardlink count.'
        Assert-Equal $fileIdentity.FileId ([FolderMap.NtfsJournal]::GetIdentity($filePath)).FileId 'Identity stability.'
        [void](Assert-Throws ([ArgumentException]) { [FolderMap.NtfsJournal]::Open($filePath) } 'File cannot be a scan root.')
        $missing = Join-Path $fixtureRoot 'never-created.bin'
        $error = Assert-Throws ([ComponentModel.Win32Exception]) { [FolderMap.NtfsJournal]::GetIdentity($missing) } 'Missing file must return a native failure.'
        Assert-Equal 2 $error.NativeErrorCode 'ERROR_FILE_NOT_FOUND must be preserved.'
    }

    $hardlinkPath = Join-Path $fixtureRoot 'hardlink.bin'
    $ownedFiles.Add($hardlinkPath)
    $hardlinkCreated = $false
    try {
        New-Item -ItemType HardLink -Path $hardlinkPath -Target $filePath -ErrorAction Stop | Out-Null
        $hardlinkCreated = $true
    }
    catch { Write-Skip "Hardlink fixture is unsupported or unavailable: $($_.Exception.GetBaseException().Message)" }
    if ($hardlinkCreated) {
        Test-Case 'Native hardlinks share the full reference and link count' {
            $original = [FolderMap.NtfsJournal]::GetIdentity($filePath)
            $linked = [FolderMap.NtfsJournal]::GetIdentity($hardlinkPath)
            Assert-Equal $original.FileId $linked.FileId 'Hardlink identity.'
            Assert-Equal $original.VolumeSerial $linked.VolumeSerial 'Hardlink volume.'
            Assert-True ($original.LinkCount -ge 2) 'Native hardlink count includes both names.'
            Assert-Equal $original.LinkCount $linked.LinkCount 'Hardlink counts agree.'
            Assert-Equal $original.Length $linked.Length 'Hardlink logical lengths agree.'
        }
    }

    $sparsePath = Join-Path $fixtureRoot 'sparse.bin'
    $ownedFiles.Add($sparsePath)
    [IO.File]::WriteAllBytes($sparsePath, (New-Object byte[] 0))
    $sparseEnabled = $false
    try {
        $sparseOutput = @(& (Join-Path $env:SystemRoot 'System32\fsutil.exe') sparse setflag $sparsePath 2>&1)
        if ($LASTEXITCODE -eq 0) { $sparseEnabled = $true }
        else { Write-Skip "Sparse fixture flag is unavailable (fsutil exit $LASTEXITCODE); no large file was allocated." }
    }
    catch { Write-Skip "Sparse fixture flag is unavailable: $($_.Exception.GetBaseException().Message)" }
    if ($sparseEnabled) {
        Test-Case 'Native sparse logical length exceeds 32 bits without content reads' {
            $length = [int64]7516192891
            $stream = [IO.File]::Open($sparsePath, [IO.FileMode]::Open, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
            try { $stream.SetLength($length) }
            finally { $stream.Dispose() }
            $identity = [FolderMap.NtfsJournal]::GetIdentity($sparsePath)
            Assert-True (($identity.Attributes -band 512) -ne 0) 'Sparse attribute.'
            Assert-Equal $length $identity.Length 'Full high/low logical length.'
        }
    }

    $junctionPath = Join-Path $fixtureRoot 'junction'
    $ownedDirectoryLinks.Add($junctionPath)
    $junctionCreated = $false
    try {
        New-Item -ItemType Junction -Path $junctionPath -Target $directoryPath -ErrorAction Stop | Out-Null
        $junctionCreated = $true
    }
    catch { Write-Skip "Directory junction fixture is unavailable: $($_.Exception.GetBaseException().Message)" }
    if ($junctionCreated) {
        Test-Case 'Final directory reparse handle identifies the link and root opening rejects it' {
            $linkIdentity = [FolderMap.NtfsJournal]::GetIdentity($junctionPath)
            Assert-True (($linkIdentity.Attributes -band 1024) -ne 0) 'Junction handle must retain the reparse attribute.'
            Assert-True ($linkIdentity.FileId -ne $directoryIdentity.FileId) 'Final reparse handle must not identify its target.'
            [void](Assert-Throws ([NotSupportedException]) { [FolderMap.NtfsJournal]::Open($junctionPath) } 'Reparse root must be rejected before opening a volume journal.')
        }
        Test-Case 'Trailing directory separators do not follow a final reparse target' {
            $linkIdentity = [FolderMap.NtfsJournal]::GetIdentity($junctionPath)
            $trailingIdentity = [FolderMap.NtfsJournal]::GetIdentity($junctionPath + '\')
            Assert-Equal $linkIdentity.FileId $trailingIdentity.FileId 'Trailing separator must preserve non-following identity.'
            Assert-True (($trailingIdentity.Attributes -band 1024) -ne 0) 'Trailing separator must preserve the reparse attribute.'
            [void](Assert-Throws ([NotSupportedException]) { [FolderMap.NtfsJournal]::Open($junctionPath + '\') } 'Trailing separator must not bypass reparse-root rejection.')
        }
    }

    $symlinkPath = Join-Path $fixtureRoot 'symlink.bin'
    $ownedFiles.Add($symlinkPath)
    $symlinkCreated = $false
    try {
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $filePath -ErrorAction Stop | Out-Null
        $symlinkCreated = $true
    }
    catch { Write-Skip "File symbolic-link fixture requires unavailable privilege or support: $($_.Exception.GetBaseException().Message)" }
    if ($symlinkCreated) {
        Test-Case 'Final file reparse handle identifies the link rather than its target' {
            $identity = [FolderMap.NtfsJournal]::GetIdentity($symlinkPath)
            Assert-True (($identity.Attributes -band 1024) -ne 0) 'Symbolic link attribute.'
            Assert-True ($identity.FileId -ne $fileIdentity.FileId) 'File symbolic link must not be followed.'
        }
    }

    if ($Live) {
        $liveAvailable = $false
        try {
            $journalSession = [FolderMap.NtfsJournal]::Open($fixtureRoot)
            $before = $journalSession.Query()
            $liveAvailable = $true
        }
        catch {
            $cause = $_.Exception.GetBaseException()
            if ($cause -is [ComponentModel.Win32Exception] -and $cause.NativeErrorCode -in @(1, 5, 50, 1178, 1179, 1181)) {
                Write-Skip "Live read-only USN journal unavailable (Win32 $($cause.NativeErrorCode)): $($cause.Message)"
            }
            elseif ($cause -is [NotSupportedException]) { Write-Skip "Live read-only USN journal unsupported: $($cause.Message)" }
            else { throw }
        }
        if ($liveAvailable) {
            Test-Case 'Live session reports stable volume and fixture identity' {
                Assert-True ($journalSession.VolumeName.StartsWith('\\?\Volume{', [StringComparison]::OrdinalIgnoreCase)) 'Stable volume GUID path.'
                Assert-Equal $fixtureRoot $journalSession.RootPath 'Session root path.'
                Assert-Equal $rootIdentity.FileId $journalSession.RootFileId 'Session root ID.'
                Assert-Equal $rootIdentity.VolumeSerial $journalSession.VolumeSerial 'Session volume serial.'
                Assert-True ($before.NextUsn -ge $before.FirstUsn -and $before.NextUsn -ge $before.LowestValidUsn) 'Checkpoint bounds.'
            }
            $liveOriginal = Join-Path $fixtureRoot 'live-original.bin'
            $liveRenamed = Join-Path $fixtureRoot 'live-renamed.bin'
            $latePath = Join-Path $fixtureRoot 'live-after-stop.bin'
            $ownedFiles.Add($liveOriginal)
            $ownedFiles.Add($liveRenamed)
            $ownedFiles.Add($latePath)
            [IO.File]::WriteAllBytes($liveOriginal, [byte[]]@(1, 2, 3))
            $liveIdentity = [FolderMap.NtfsJournal]::GetIdentity($liveOriginal)
            $stream = [IO.File]::Open($liveOriginal, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
            try { $stream.WriteByte(4) }
            finally { $stream.Dispose() }
            [IO.File]::Move($liveOriginal, $liveRenamed)
            [IO.File]::Delete($liveRenamed)
            $stop = $journalSession.Query()
            [IO.File]::WriteAllBytes($latePath, [byte[]]@(5))
            $lateIdentity = [FolderMap.NtfsJournal]::GetIdentity($latePath)
            $selectedIds = New-Object 'System.Collections.Generic.HashSet[UInt64]'
            [void]$selectedIds.Add($liveIdentity.FileId)
            [void]$selectedIds.Add($lateIdentity.FileId)
            $fixtureChanges = New-Object 'System.Collections.Generic.List[FolderMap.UsnChange]'
            $receiver = [Action[FolderMap.UsnChange]] {
                param($change)
                # Unrelated numeric records are immediately discarded, never stored or printed.
                if ($selectedIds.Contains($change.FileId)) { $fixtureChanges.Add($change) }
            }.GetNewClosure()
            $readSucceeded = $false
            try {
                $count = $journalSession.ReadChanges($before.NextUsn, $before.JournalId, $stop.NextUsn, $receiver, $null)
                $readSucceeded = $true
            }
            catch {
                $cause = $_.Exception.GetBaseException()
                if ($cause -is [ComponentModel.Win32Exception] -and $cause.NativeErrorCode -in @(1, 5, 50, 1178, 1179, 1181)) {
                    Write-Skip "Live journal lost availability during read (Win32 $($cause.NativeErrorCode)): $($cause.Message)"
                }
                elseif ($cause -is [NotSupportedException]) { Write-Skip "Live journal has an unsupported record version: $($cause.Message)" }
                else { throw }
            }
            if ($readSucceeded) {
                Test-Case 'Live finite replay delivers fixture create/write/rename/delete/close and excludes late writes' {
                    Assert-True ($count -ge $fixtureChanges.Count) 'Streaming record count.'
                    Assert-True ($fixtureChanges.Count -gt 0) 'Fixture events must be observed.'
                    $mask = [uint32]0
                    foreach ($change in $fixtureChanges) {
                        Assert-Equal $liveIdentity.FileId $change.FileId 'After-stop fixture must not be delivered.'
                        Assert-True ($change.Usn -ge $before.NextUsn -and $change.Usn -lt $stop.NextUsn) 'Every delivered fixture event must be in range.'
                        $mask = $mask -bor $change.Reason
                    }
                    foreach ($reason in @([uint32]256, [uint32]512, [uint32]4096, [uint32]8192, $closeReason)) {
                        Assert-True (($mask -band $reason) -ne 0) 'Expected fixture journal reason is missing.'
                    }
                    Assert-True (($mask -band 7) -ne 0) 'Expected fixture data change.'
                    Write-Output "Live verified $($fixtureChanges.Count) fixture-only records; no unrelated records were retained or printed."
                }
                Test-Case 'Live zero-length range, mismatched ID, future boundary, and cancellation' {
                    Assert-Equal 0 ($journalSession.ReadChanges($stop.NextUsn, $stop.JournalId, $stop.NextUsn, $noReceiver, $null)) 'Zero-length replay.'
                    $wrongId = [uint64]0
                    if ($stop.JournalId -eq 0) { $wrongId = [uint64]1 }
                    [void](Assert-Throws ([IO.IOException]) { $journalSession.ReadChanges($stop.NextUsn, $wrongId, $stop.NextUsn, $noReceiver, $null) } 'Mismatched journal ID.')
                    [void](Assert-Throws ([IO.IOException]) { $journalSession.ReadChanges($stop.NextUsn, $stop.JournalId, [int64]::MaxValue, $noReceiver, $null) } 'Never wait for a future stop boundary.')
                    $worker = New-Object ComponentModel.BackgroundWorker
                    $worker.WorkerSupportsCancellation = $true
                    $worker.CancelAsync()
                    try {
                        [void](Assert-Throws ([OperationCanceledException]) { $journalSession.ReadChanges($stop.NextUsn, $stop.JournalId, $stop.NextUsn, $noReceiver, $worker) } 'Live cancellation before a native call.')
                    }
                    finally { $worker.Dispose() }
                }
            }
        }
    }
    else {
        Write-Output 'LIVE NOT REQUESTED: no real volume journal was queried or read.'
    }
}
finally {
    if ($null -ne $journalSession) { $journalSession.Dispose() }
    # Delete only registered exact paths. Never recursively traverse a junction or an unrelated directory.
    foreach ($path in $ownedDirectoryLinks) {
        if ([IO.Directory]::Exists($path)) { [IO.Directory]::Delete($path, $false) }
    }
    foreach ($path in $ownedFiles) { [IO.File]::Delete($path) }
    for ($i = $ownedDirectories.Count - 1; $i -ge 0; $i--) {
        if ([IO.Directory]::Exists($ownedDirectories[$i])) { [IO.Directory]::Delete($ownedDirectories[$i], $false) }
    }
    [IO.Directory]::Delete($fixtureRoot, $false)
}

Assert-True (-not [IO.Directory]::Exists($fixtureRoot)) 'The exact fixture directory must be removed.'
Write-Output "USN TESTS PASSED: $script:checks checks; $script:skips explicit skips; fixture cleaned."
