.class public sealed auto ansi beforefieldinit FolderMap.FileIdentity extends [mscorlib]System.Object
{
    .field public unsigned int64 FileId
    .field public unsigned int32 VolumeSerial
    .field public unsigned int32 LinkCount
    .field public unsigned int32 Attributes
    .field public int64 Length

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

.class public sealed auto ansi beforefieldinit FolderMap.UsnCheckpoint extends [mscorlib]System.Object
{
    .field public unsigned int64 JournalId
    .field public int64 FirstUsn
    .field public int64 NextUsn
    .field public int64 LowestValidUsn

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

.class public sealed auto ansi beforefieldinit FolderMap.UsnChange extends [mscorlib]System.Object
{
    .field public unsigned int64 FileId
    .field public unsigned int64 ParentId
    .field public unsigned int32 Reason
    .field public unsigned int32 Attributes
    .field public int64 Usn

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

// BY_HANDLE_FILE_INFORMATION contains thirteen DWORDs, including the three FILETIMEs.
.class private sequential ansi sealed beforefieldinit FolderMap.NativeFileInformation extends [mscorlib]System.ValueType
{
    .pack 4
    .size 52
    .field public unsigned int32 Attributes
    .field public unsigned int32 CreationLow
    .field public unsigned int32 CreationHigh
    .field public unsigned int32 AccessLow
    .field public unsigned int32 AccessHigh
    .field public unsigned int32 WriteLow
    .field public unsigned int32 WriteHigh
    .field public unsigned int32 VolumeSerial
    .field public unsigned int32 FileSizeHigh
    .field public unsigned int32 FileSizeLow
    .field public unsigned int32 LinkCount
    .field public unsigned int32 FileIndexHigh
    .field public unsigned int32 FileIndexLow
}

.class private sequential ansi sealed beforefieldinit FolderMap.NativeLuid extends [mscorlib]System.ValueType
{
    .pack 4
    .size 8
    .field public unsigned int32 LowPart
    .field public int32 HighPart
}

// winnt.h, x64 default packing: pointer fields are aligned to eight bytes.
.class private sequential ansi sealed beforefieldinit FolderMap.NativeTokenAccessInformation extends [mscorlib]System.ValueType
{
    .pack 8
    .size 88
    .field public native int SidHash
    .field public native int RestrictedSidHash
    .field public native int Privileges
    .field public valuetype FolderMap.NativeLuid AuthenticationId
    .field public int32 TokenType
    .field public int32 ImpersonationLevel
    .field public unsigned int32 MandatoryPolicy
    .field public unsigned int32 Flags
    .field public unsigned int32 AppContainerNumber
    .field public native int PackageSid
    .field public native int CapabilitiesHash
    .field public native int TrustLevelSid
    .field public native int SecurityAttributes
}

.class private sequential ansi sealed beforefieldinit FolderMap.AuthzAttributeCounts extends [mscorlib]System.ValueType
{
    .pack 4
    .size 12
    .field public unsigned int32 SecurityAttributes
    .field public unsigned int32 UserClaims
    .field public unsigned int32 DeviceClaims
}

.class private sealed auto ansi beforefieldinit FolderMap.AuthzAttributeSnapshot extends [mscorlib]System.Object
{
    .field public valuetype FolderMap.AuthzAttributeCounts Counts
    .field public string SecurityAttributes
    .field public string UserClaims
    .field public string DeviceClaims
    .field public bool HasCanonicalData

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

.class private sequential ansi sealed beforefieldinit FolderMap.NativeAuthzSecurityAttributeV1 extends [mscorlib]System.ValueType
{
    .pack 8
    .size 32
    .field public native int Name
    .field public unsigned int16 ValueType
    .field public unsigned int16 Reserved
    .field public unsigned int32 Flags
    .field public unsigned int32 ValueCount
    .field public native int Values
}

.class private sequential ansi sealed beforefieldinit FolderMap.NativeAuthzFqbnValue extends [mscorlib]System.ValueType
{
    .pack 8
    .size 16
    .field public unsigned int64 Version
    .field public native int Name
}

.class private sequential ansi sealed beforefieldinit FolderMap.NativeAuthzOctetValue extends [mscorlib]System.ValueType
{
    .pack 8
    .size 16
    .field public native int Value
    .field public unsigned int32 Length
}

.class private sealed auto ansi beforefieldinit FolderMap.AuthzResourceManagerHandle
    extends [mscorlib]Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid
{
    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        call instance void [mscorlib]Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid::.ctor(bool)
        ret
    }

    .method family hidebysig virtual instance bool ReleaseHandle() cil managed
    {
        .override method instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::ReleaseHandle()
        .maxstack 2
        ldarg.0
        ldfld native int [mscorlib]System.Runtime.InteropServices.SafeHandle::handle
        call int32 FolderMap.NtfsJournal::AuthzFreeResourceManager(native int)
        ldc.i4.0
        cgt.un
        ret
    }
}

.class private sealed auto ansi beforefieldinit FolderMap.AuthzClientContextHandle
    extends [mscorlib]Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid
{
    .field private class FolderMap.AuthzResourceManagerHandle _manager

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        call instance void [mscorlib]Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid::.ctor(bool)
        ret
    }

    // Keep the native manager alive even if its SafeHandle is finalized before this context.
    .method assembly hidebysig instance void KeepManagerAlive(class FolderMap.AuthzResourceManagerHandle manager) cil managed
    {
        .maxstack 2
        .locals init (bool added)
        ldarg.0
        ldfld class FolderMap.AuthzResourceManagerHandle FolderMap.AuthzClientContextHandle::_manager
        brfalse authzManagerNotAttached
        ldstr "An Authz context already owns its resource-manager reference."
        newobj instance void [mscorlib]System.InvalidOperationException::.ctor(string)
        throw
    authzManagerNotAttached:
        call void [mscorlib]System.Runtime.CompilerServices.RuntimeHelpers::PrepareConstrainedRegions()
        .try
        {
            leave authzManagerAttached
        }
        finally
        {
            ldarg.1
            ldloca added
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::DangerousAddRef(bool&)
            ldarg.0
            ldarg.1
            stfld class FolderMap.AuthzResourceManagerHandle FolderMap.AuthzClientContextHandle::_manager
            endfinally
        }
    authzManagerAttached:
        ret
    }

    .method family hidebysig virtual instance bool ReleaseHandle() cil managed
    {
        .override method instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::ReleaseHandle()
        .maxstack 2
        .locals init (bool result)
        .try
        {
            ldarg.0
            ldfld native int [mscorlib]System.Runtime.InteropServices.SafeHandle::handle
            call int32 FolderMap.NtfsJournal::AuthzFreeContext(native int)
            ldc.i4.0
            cgt.un
            stloc result
            leave authzContextReleased
        }
        finally
        {
            ldarg.0
            ldfld class FolderMap.AuthzResourceManagerHandle FolderMap.AuthzClientContextHandle::_manager
            brfalse authzManagerReferenceReleased
            ldarg.0
            ldfld class FolderMap.AuthzResourceManagerHandle FolderMap.AuthzClientContextHandle::_manager
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::DangerousRelease()
        authzManagerReferenceReleased:
            endfinally
        }
    authzContextReleased:
        ldloc result
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.NtfsJournal extends [mscorlib]System.Object
{
    .method private hidebysig static pinvokeimpl("kernel32.dll" as "CreateFileW" unicode winapi lasterr)
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle CreateFileW(
            string marshal(lpwstr) path,
            unsigned int32 desiredAccess,
            unsigned int32 shareMode,
            native int securityAttributes,
            unsigned int32 creationDisposition,
            unsigned int32 flagsAndAttributes,
            native int templateFile) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetFileInformationByHandle" winapi lasterr)
        int32 GetFileInformationByHandle(
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle handle,
            [out] valuetype FolderMap.NativeFileInformation& information) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetVolumePathNameW" unicode winapi lasterr)
        int32 GetVolumePathNameW(
            string marshal(lpwstr) path,
            [out] class [mscorlib]System.Text.StringBuilder volumePath,
            unsigned int32 capacity) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetVolumeNameForVolumeMountPointW" unicode winapi lasterr)
        int32 GetVolumeNameForVolumeMountPointW(
            string marshal(lpwstr) mountPoint,
            [out] class [mscorlib]System.Text.StringBuilder volumeName,
            unsigned int32 capacity) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetVolumeInformationW" unicode winapi lasterr)
        int32 GetVolumeInformationW(
            string marshal(lpwstr) volumePath,
            [out] class [mscorlib]System.Text.StringBuilder volumeLabel,
            unsigned int32 labelCapacity,
            [out] unsigned int32& serial,
            [out] unsigned int32& maximumComponentLength,
            [out] unsigned int32& fileSystemFlags,
            [out] class [mscorlib]System.Text.StringBuilder fileSystemName,
            unsigned int32 fileSystemCapacity) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetDriveTypeW" unicode winapi lasterr)
        unsigned int32 GetDriveTypeW(string marshal(lpwstr) volumePath) cil managed preservesig
    {
    }

    .method assembly hidebysig static pinvokeimpl("kernel32.dll" as "DeviceIoControl" winapi lasterr)
        int32 DeviceIoControl(
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle handle,
            unsigned int32 controlCode,
            [in] unsigned int8[] marshal([]) inputBuffer,
            unsigned int32 inputSize,
            [out] unsigned int8[] marshal([]) outputBuffer,
            unsigned int32 outputSize,
            [out] unsigned int32& bytesReturned,
            native int overlapped) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetCurrentProcess" winapi)
        native int GetCurrentProcess() cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("kernel32.dll" as "GetCurrentThread" winapi)
        native int GetCurrentThread() cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("advapi32.dll" as "OpenProcessToken" winapi lasterr)
        int32 OpenProcessToken(native int process, unsigned int32 access,
            [out] class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle& token) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("advapi32.dll" as "OpenThreadToken" winapi lasterr)
        int32 OpenThreadToken(native int thread, unsigned int32 access, int32 openAsSelf,
            [out] class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle& token) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("advapi32.dll" as "GetTokenInformation" winapi lasterr)
        int32 GetTokenInformation(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            int32 informationClass, native int buffer, int32 capacity, [out] int32& returned) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("authz.dll" as "AuthzInitializeResourceManager" unicode winapi lasterr)
        int32 AuthzInitializeResourceManager(unsigned int32 initializationFlags, native int accessCheckCallback,
            native int groupsCallback, native int freeGroupsCallback, string marshal(lpwstr) name,
            [out] class FolderMap.AuthzResourceManagerHandle& manager) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("authz.dll" as "AuthzInitializeContextFromToken" winapi lasterr)
        int32 AuthzInitializeContextFromToken(unsigned int32 initializationFlags,
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            class FolderMap.AuthzResourceManagerHandle manager, native int expiration,
            valuetype FolderMap.NativeLuid identifier, native int groupArguments,
            [out] class FolderMap.AuthzClientContextHandle& context) cil managed preservesig
    {
    }

    .method private hidebysig static pinvokeimpl("authz.dll" as "AuthzGetInformationFromContext" winapi lasterr)
        int32 AuthzGetInformationFromContext(class FolderMap.AuthzClientContextHandle context,
            int32 informationClass, unsigned int32 bufferSize, [out] unsigned int32& required,
            native int buffer) cil managed preservesig
    {
    }

    .method assembly hidebysig static pinvokeimpl("authz.dll" as "AuthzFreeContext" winapi lasterr)
        int32 AuthzFreeContext(native int context) cil managed preservesig
    {
    }

    .method assembly hidebysig static pinvokeimpl("authz.dll" as "AuthzFreeResourceManager" winapi lasterr)
        int32 AuthzFreeResourceManager(native int manager) cil managed preservesig
    {
    }

    .method private hidebysig static void ThrowTokenWin32(int32 errorCode, string message) cil managed
    {
        .maxstack 3
        ldarg.1
        ldarg.0
        ldarg.1
        newobj instance void [System]System.ComponentModel.Win32Exception::.ctor(int32, string)
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string, class [mscorlib]System.Exception)
        throw
    }

    .method private hidebysig static void RequireTokenSize(int32 actual, int32 minimum) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        bge tokenSizeValid
        ldstr "Incomplete token authorization information; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    tokenSizeValid:
        ret
    }

    .method private hidebysig static void RejectThreadToken() cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            int32 nativeError)
        .try
        {
            call native int FolderMap.NtfsJournal::GetCurrentThread()
            ldc.i4.8
            ldc.i4.1
            ldloca token
            call int32 FolderMap.NtfsJournal::OpenThreadToken(native int, unsigned int32, int32, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle&)
            brfalse threadTokenFailure
            ldstr "Impersonation tokens are not supported for persistent cache reuse; use a full scan."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        threadTokenFailure:
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            stloc nativeError
            ldloc nativeError
            ldc.i4 1008
            beq threadTokenAbsent
            ldloc nativeError
            ldstr "OpenThreadToken could not exclude impersonation; persistent cache reuse is unsafe."
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        threadTokenAbsent:
            leave threadTokenDone
        }
        finally
        {
            ldloc token
            brfalse threadTokenReleased
            ldloc token
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        threadTokenReleased:
            endfinally
        }
    threadTokenDone:
        ret
    }

    .method private hidebysig static class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle OpenSecurityToken() cil managed
    {
        .maxstack 3
        .locals init (
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle result)
        .try
        {
            call native int FolderMap.NtfsJournal::GetCurrentProcess()
            ldc.i4.8
            ldloca token
            call int32 FolderMap.NtfsJournal::OpenProcessToken(native int, unsigned int32, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle&)
            brtrue securityTokenOpened
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "OpenProcessToken(TOKEN_QUERY) failed; persistent cache reuse is unsafe."
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        securityTokenOpened:
            ldloc token
            stloc result
            ldnull
            stloc token
            leave securityTokenDone
        }
        finally
        {
            ldloc token
            brfalse securityTokenReleased
            ldloc token
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        securityTokenReleased:
            endfinally
        }
    securityTokenDone:
        ldloc result
        ret
    }

    .method private hidebysig static native int GetTokenBuffer(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
        int32 informationClass, int32& length) cil managed
    {
        .maxstack 5
        .locals init (int32 capacity, int32 nativeError, native int buffer, native int result)
        ldarg.0
        ldarg.1
        ldc.i4.0
        conv.i
        ldc.i4.0
        ldloca capacity
        call int32 FolderMap.NtfsJournal::GetTokenInformation(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, native int, int32, int32&)
        brfalse tokenBufferSizeFailure
        ldstr "GetTokenInformation returned an unexpected empty-buffer success."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    tokenBufferSizeFailure:
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
        stloc nativeError
        ldloc nativeError
        ldc.i4 122
        beq tokenBufferAllocate
        ldloc nativeError
        ldstr "GetTokenInformation({0}) could not determine the token authorization buffer size."
        ldarg.1
        box [mscorlib]System.Int32
        call string [mscorlib]System.String::Format(string, object)
        call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
    tokenBufferAllocate:
        ldloc capacity
        ldc.i4.1
        blt tokenBufferInvalid
        ldloc capacity
        ldc.i4 1048576
        bgt tokenBufferInvalid
        .try
        {
            ldloc capacity
            call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
            stloc buffer
            ldarg.0
            ldarg.1
            ldloc buffer
            ldloc capacity
            ldarg.2
            call int32 FolderMap.NtfsJournal::GetTokenInformation(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, native int, int32, int32&)
            brtrue tokenBufferRead
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "GetTokenInformation({0}) failed or the token changed while reading authorization information."
            ldarg.1
            box [mscorlib]System.Int32
            call string [mscorlib]System.String::Format(string, object)
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        tokenBufferRead:
            ldarg.2
            ldind.i4
            ldc.i4.1
            blt tokenBufferReadInvalid
            ldarg.2
            ldind.i4
            ldloc capacity
            bgt tokenBufferReadInvalid
            ldloc buffer
            stloc result
            ldc.i4.0
            conv.i
            stloc buffer
            leave tokenBufferDone
        tokenBufferReadInvalid:
            ldstr "GetTokenInformation returned an invalid authorization buffer extent."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc buffer
            brfalse tokenBufferReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenBufferReleased:
            endfinally
        }
    tokenBufferDone:
        ldloc result
        ret
    tokenBufferInvalid:
        ldstr "Unsupported token authorization buffer size for class {0}: {1}; persistent cache reuse is unsafe."
        ldarg.1
        box [mscorlib]System.Int32
        ldloc capacity
        box [mscorlib]System.Int32
        call string [mscorlib]System.String::Format(string, object, object)
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static unsigned int32 TokenUInt32(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token, int32 informationClass) cil managed
    {
        .maxstack 5
        .locals init (native int buffer, int32 length, unsigned int32 result)
        .try
        {
            // Fixed-width classes need no zero-length size probe.
            ldc.i4.4
            call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
            stloc buffer
            ldloc buffer
            ldc.i4.0
            call void [mscorlib]System.Runtime.InteropServices.Marshal::WriteInt32(native int, int32)
            ldarg.0
            ldarg.1
            ldloc buffer
            ldc.i4.4
            ldloca length
            call int32 FolderMap.NtfsJournal::GetTokenInformation(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, native int, int32, int32&)
            brtrue tokenNumberRead
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "GetTokenInformation({0}) failed reading fixed-width authorization state."
            ldarg.1
            box [mscorlib]System.Int32
            call string [mscorlib]System.String::Format(string, object)
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        tokenNumberRead:
            ldloc length
            ldc.i4.4
            ble.un tokenNumberSized
            ldstr "GetTokenInformation returned oversized fixed-width authorization state."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        tokenNumberSized:
            // Boolean information classes can use native BOOLEAN rather than the documented DWORD.
            // A one-byte numeric enum, policy, or session identifier is still rejected as incomplete.
            ldloc length
            ldc.i4.1
            bne.un tokenNumberDword
            ldarg.1
            ldc.i4.s 15
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 20
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 21
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 23
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 24
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 26
            beq tokenNumberBoolean
            ldarg.1
            ldc.i4.s 29
            bne.un tokenNumberDword
        tokenNumberBoolean:
            ldloc buffer
            call unsigned int8 [mscorlib]System.Runtime.InteropServices.Marshal::ReadByte(native int)
            stloc result
            leave tokenNumberDone
        tokenNumberDword:
            ldloc length
            ldc.i4.4
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc buffer
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
            stloc result
            leave tokenNumberDone
        }
        finally
        {
            ldloc buffer
            brfalse tokenNumberReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenNumberReleased:
            endfinally
        }
    tokenNumberDone:
        ldloc result
        ret
    }

    .method private hidebysig static string TokenHex32(unsigned int32 number) cil managed
    {
        .maxstack 3
        ldarga.s number
        ldstr "X8"
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.UInt32::ToString(string, class [mscorlib]System.IFormatProvider)
        ret
    }

    .method private hidebysig static string TokenHex64(unsigned int64 number) cil managed
    {
        .maxstack 3
        ldarga.s number
        ldstr "X16"
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.UInt64::ToString(string, class [mscorlib]System.IFormatProvider)
        ret
    }

    .method private hidebysig static void AppendTokenField(
        class [mscorlib]System.Text.StringBuilder text, string key, string data) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        pop
        ldarg.0
        ldstr "="
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        pop
        ldarg.0
        ldarg.2
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        pop
        ldarg.0
        ldstr "\n"
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        pop
        ret
    }

    .method private hidebysig static void AppendTokenNumber(
        class [mscorlib]System.Text.StringBuilder text,
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
        int32 informationClass, string key) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.3
        ldarg.1
        ldarg.2
        call unsigned int32 FolderMap.NtfsJournal::TokenUInt32(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ret
    }

    // SID pointers are bounds-checked, then only the self-contained SID bytes are copied.
    .method private hidebysig static string CanonicalSid(native int buffer, int32 length, native int sid) cil managed
    {
        .maxstack 4
        .locals init (unsigned int64 offset, int32 sidLength, unsigned int8[] bytes)
        ldarg.1
        ldc.i4.8
        call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
        ldarg.0
        brfalse sidInvalid
        ldarg.2
        brfalse sidInvalid
        ldarg.2
        conv.u8
        ldarg.0
        conv.u8
        sub
        stloc offset
        ldloc offset
        ldarg.1
        ldc.i4.8
        sub
        conv.u8
        bgt.un sidInvalid
        ldarg.2
        call unsigned int8 [mscorlib]System.Runtime.InteropServices.Marshal::ReadByte(native int)
        ldc.i4.1
        bne.un sidInvalid
        ldarg.2
        ldc.i4.1
        call unsigned int8 [mscorlib]System.Runtime.InteropServices.Marshal::ReadByte(native int, int32)
        stloc sidLength
        ldloc sidLength
        ldc.i4.s 15
        bgt sidInvalid
        ldloc sidLength
        ldc.i4.4
        mul
        ldc.i4.8
        add
        stloc sidLength
        ldloc sidLength
        ldarg.1
        ldloc offset
        conv.i4
        sub
        bgt sidInvalid
        ldloc sidLength
        newarr [mscorlib]System.Byte
        stloc bytes
        ldarg.2
        ldloc bytes
        ldc.i4.0
        ldloc sidLength
        call void [mscorlib]System.Runtime.InteropServices.Marshal::Copy(native int, unsigned int8[], int32, int32)
        ldloc bytes
        ldc.i4.0
        newobj instance void [mscorlib]System.Security.Principal.SecurityIdentifier::.ctor(unsigned int8[], int32)
        callvirt instance string [mscorlib]System.Security.Principal.SecurityIdentifier::get_Value()
        ret
    sidInvalid:
        ldstr "Invalid SID extent in token authorization information; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string TokenSidText(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
        int32 informationClass, bool attributes) cil managed
    {
        .maxstack 8
        .locals init (native int buffer, int32 length, string result)
        .try
        {
            ldarg.0
            ldarg.1
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc length
            ldc.i4.8
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc buffer
            ldloc length
            ldloc buffer
            call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int)
            call string FolderMap.NtfsJournal::CanonicalSid(native int, int32, native int)
            stloc result
            ldarg.2
            brfalse tokenSidComplete
            ldloc length
            ldc.i4.s 16
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc result
            ldstr ":"
            ldloc buffer
            ldc.i4.8
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
            call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc result
        tokenSidComplete:
            leave tokenSidDone
        }
        finally
        {
            ldloc buffer
            brfalse tokenSidReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenSidReleased:
            endfinally
        }
    tokenSidDone:
        ldloc result
        ret
    }

    // TOKEN_GROUPS is an aligned DWORD count followed by 16-byte SID_AND_ATTRIBUTES entries on x64.
    .method private hidebysig static string CanonicalGroups(native int buffer, int32 length) cil managed
    {
        .maxstack 5
        .locals init (
            unsigned int32 count, int32 index, int32 position,
            string[] entries, string sid, string entry)
        ldarg.1
        ldc.i4.4
        call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
        ldarg.0
        brfalse groupsInvalid
        ldarg.0
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
        stloc count
        ldloc count
        brtrue groupsNonempty
        ldstr ""
        ret
    groupsNonempty:
        ldarg.1
        ldc.i4.8
        call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
        ldloc count
        ldarg.1
        ldc.i4.8
        sub
        ldc.i4.s 16
        div
        bgt.un groupsInvalid
        ldloc count
        newarr [mscorlib]System.String
        stloc entries
    groupsLoop:
        ldloc index
        ldloc count
        bge.un groupsDone
        ldloc index
        ldc.i4.s 16
        mul
        ldc.i4.8
        add
        stloc position
        ldarg.0
        ldarg.1
        ldarg.0
        ldloc position
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        call string FolderMap.NtfsJournal::CanonicalSid(native int, int32, native int)
        stloc sid
        ldloc sid
        ldstr ":"
        ldarg.0
        ldloc position
        ldc.i4.8
        add
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc entry
        ldloc entries
        ldloc index
        ldloc entry
        stelem.ref
        ldloc index
        ldc.i4.1
        add
        stloc index
        br groupsLoop
    groupsDone:
        ldloc entries
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        call void [mscorlib]System.Array::Sort<string>(!!0[], class [mscorlib]System.Collections.Generic.IComparer`1<!!0>)
        ldstr ";"
        ldloc entries
        call string [mscorlib]System.String::Join(string, string[])
        ret
    groupsInvalid:
        ldstr "Invalid group array in token authorization information; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string TokenGroupsText(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
        int32 informationClass, bool requireEmpty) cil managed
    {
        .maxstack 3
        .locals init (native int buffer, int32 length, string result)
        .try
        {
            ldarg.0
            ldarg.1
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc length
            ldc.i4.4
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldarg.2
            brfalse tokenGroupsCanonical
            ldloc buffer
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
            brfalse tokenGroupsCanonical
            ldstr "Restricted, capability, or device-group tokens are not supported for persistent cache reuse; use a full scan."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        tokenGroupsCanonical:
            ldloc buffer
            ldloc length
            call string FolderMap.NtfsJournal::CanonicalGroups(native int, int32)
            stloc result
            leave tokenGroupsDone
        }
        finally
        {
            ldloc buffer
            brfalse tokenGroupsReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenGroupsReleased:
            endfinally
        }
    tokenGroupsDone:
        ldloc result
        ret
    }

    // LUID_AND_ATTRIBUTES has no pointers: canonicalize its two integer fields, not native padding.
    .method private hidebysig static string CanonicalPrivileges(native int buffer, int32 length) cil managed
    {
        .maxstack 5
        .locals init (unsigned int32 count, int32 index, int32 position, string[] entries, string entry)
        ldarg.1
        ldc.i4.4
        call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
        ldarg.0
        brfalse privilegesInvalid
        ldarg.0
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int)
        stloc count
        ldloc count
        ldarg.1
        ldc.i4.4
        sub
        ldc.i4.s 12
        div
        bgt.un privilegesInvalid
        ldloc count
        newarr [mscorlib]System.String
        stloc entries
    privilegesLoop:
        ldloc index
        ldloc count
        bge.un privilegesDone
        ldloc index
        ldc.i4.s 12
        mul
        ldc.i4.4
        add
        stloc position
        ldarg.0
        ldloc position
        call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
        ldstr ":"
        ldarg.0
        ldloc position
        ldc.i4.8
        add
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc entry
        ldloc entries
        ldloc index
        ldloc entry
        stelem.ref
        ldloc index
        ldc.i4.1
        add
        stloc index
        br privilegesLoop
    privilegesDone:
        ldloc entries
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        call void [mscorlib]System.Array::Sort<string>(!!0[], class [mscorlib]System.Collections.Generic.IComparer`1<!!0>)
        ldstr ";"
        ldloc entries
        call string [mscorlib]System.String::Join(string, string[])
        ret
    privilegesInvalid:
        ldstr "Invalid privilege array in token authorization information; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string TokenPrivilegesText(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token) cil managed
    {
        .maxstack 3
        .locals init (native int buffer, int32 length, string result)
        .try
        {
            ldarg.0
            ldc.i4.3
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc buffer
            ldloc length
            call string FolderMap.NtfsJournal::CanonicalPrivileges(native int, int32)
            stloc result
            leave tokenPrivilegesDone
        }
        finally
        {
            ldloc buffer
            brfalse tokenPrivilegesReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenPrivilegesReleased:
            endfinally
        }
    tokenPrivilegesDone:
        ldloc result
        ret
    }

    .method private hidebysig static unsigned int32 ReadTokenClaimCount(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token, int32 informationClass) cil managed
    {
        .maxstack 3
        .locals init (native int buffer, int32 length, unsigned int32 result)
        .try
        {
            ldarg.0
            ldarg.1
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc length
            ldc.i4.s 16
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc buffer
            call int16 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt16(native int)
            ldc.i4.1
            bne.un tokenClaimsUnsupported
            ldloc buffer
            ldc.i4.2
            call int16 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt16(native int, int32)
            brtrue tokenClaimsUnsupported
            ldloc buffer
            ldc.i4.4
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
            stloc result
            leave tokenClaimsDone
        tokenClaimsUnsupported:
            ldstr "Token claim metadata has an unsupported header; use a full scan."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc buffer
            brfalse tokenClaimsReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenClaimsReleased:
            endfinally
        }
    tokenClaimsDone:
        ldloc result
        ret
    }

    // AUTHZ_SECURITY_ATTRIBUTES_INFORMATION is a documented 16-byte x64 header.
    // Version and AttributeCount are meaningful. Reserved and the unused array pointer are not
    // evidence of attributes when AttributeCount is zero; neither is read into the cache key.
    .method private hidebysig static unsigned int32 ReadAuthzAttributeHeaderCount(native int buffer, int32 length) cil managed
    {
        .maxstack 2
        ldarg.1
        ldc.i4.s 16
        call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
        ldarg.0
        brfalse authzHeaderInvalid
        ldarg.0
        call int16 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt16(native int)
        ldc.i4.1
        bne.un authzHeaderInvalid
        ldarg.0
        ldc.i4.4
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        ret
    authzHeaderInvalid:
        ldstr "Unsupported or invalid Authz security-attribute header; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static int32 AttributeOffset(
        native int buffer, int32 length, native int pointer, int32 byteCount) cil managed
    {
        .maxstack 3
        .locals init (unsigned int64 offset)
        ldarg.0
        brfalse attributeRangeInvalid
        ldarg.2
        brfalse attributeRangeInvalid
        ldarg.3
        ldc.i4.0
        blt attributeRangeInvalid
        ldarg.1
        ldarg.3
        blt attributeRangeInvalid
        ldarg.2
        conv.u8
        ldarg.0
        conv.u8
        sub
        stloc offset
        ldloc offset
        ldarg.1
        ldarg.3
        sub
        conv.u8
        bgt.un attributeRangeInvalid
        ldloc offset
        conv.i4
        ret
    attributeRangeInvalid:
        ldstr "An Authz attribute pointer or extent is outside its returned buffer; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static int32 AttributeArrayOffset(
        native int buffer, int32 length, native int pointer, unsigned int32 count, int32 stride) cil managed
    {
        .maxstack 5
        ldarg.1
        ldc.i4.0
        blt attributeArrayInvalid
        ldarg.s stride
        ldc.i4.0
        ble attributeArrayInvalid
        ldarg.3
        ldarg.1
        ldarg.s stride
        div
        bgt.un attributeArrayInvalid
        ldarg.3
        brtrue attributeArrayNonempty
        ldc.i4.0
        ret
    attributeArrayNonempty:
        ldarg.0
        ldarg.1
        ldarg.2
        ldarg.3
        ldarg.s stride
        mul
        call int32 FolderMap.NtfsJournal::AttributeOffset(native int, int32, native int, int32)
        ret
    attributeArrayInvalid:
        ldstr "An Authz attribute array count or extent is invalid; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    // Per-set canonicalization budget also bounds amplification through aliased native pointers.
    .method private hidebysig static void ChargeAttributeBudget(int32& budget, int32 amount) cil managed
    {
        .maxstack 3
        ldarg.1
        ldc.i4.0
        blt attributeBudgetExceeded
        ldarg.0
        ldind.i4
        ldarg.1
        blt attributeBudgetExceeded
        ldarg.0
        dup
        ldind.i4
        ldarg.1
        sub
        stind.i4
        ret
    attributeBudgetExceeded:
        ldstr "Authz attribute canonicalization exceeds its bounded size budget; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static void AppendAttributePart(
        class [mscorlib]System.Text.StringBuilder text, string data) cil managed
    {
        .maxstack 4
        .locals init (int32 amount, string prefix)
        ldarg.1
        brfalse attributePartInvalid
        ldarg.1
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc amount
        ldloc amount
        ldc.i4 4194304
        bgt attributePartInvalid
        ldloca amount
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.Int32::ToString(class [mscorlib]System.IFormatProvider)
        stloc prefix
        ldarg.0
        callvirt instance int32 [mscorlib]System.Text.StringBuilder::get_Length()
        ldloc amount
        add
        ldloc prefix
        callvirt instance int32 [mscorlib]System.String::get_Length()
        add
        ldc.i4.1
        add
        ldc.i4 4194304
        bgt attributePartInvalid
        ldarg.0
        ldloc prefix
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        ldstr ":"
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        ldarg.1
        callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
        pop
        ret
    attributePartInvalid:
        ldstr "Invalid or oversized canonical Authz attribute part; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string AttributeBytesHex(
        native int buffer, int32 length, native int pointer, int32 byteCount, int32& budget) cil managed
    {
        .maxstack 4
        .locals init (unsigned int8[] bytes)
        ldarg.3
        brtrue attributeBytesNonempty
        ldstr ""
        ret
    attributeBytesNonempty:
        ldarg.0
        ldarg.1
        ldarg.2
        ldarg.3
        call int32 FolderMap.NtfsJournal::AttributeOffset(native int, int32, native int, int32)
        pop
        ldarg.3
        ldc.i4 1048576
        bgt attributeBytesInvalid
        ldarg.s budget
        ldarg.3
        ldc.i4.2
        mul
        call void FolderMap.NtfsJournal::ChargeAttributeBudget(int32&, int32)
        ldarg.3
        newarr [mscorlib]System.Byte
        stloc bytes
        ldarg.2
        ldloc bytes
        ldc.i4.0
        ldarg.3
        call void [mscorlib]System.Runtime.InteropServices.Marshal::Copy(native int, unsigned int8[], int32, int32)
        ldloc bytes
        call string [mscorlib]System.BitConverter::ToString(unsigned int8[])
        ldstr "-"
        ldstr ""
        callvirt instance string [mscorlib]System.String::Replace(string, string)
        ret
    attributeBytesInvalid:
        ldstr "An Authz attribute byte value exceeds the supported bound; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    // Validate UTF-16 and its terminator in bounds, then encode exact code units as ASCII hex.
    // This avoids lossy UTF-8 replacement and delimiter ambiguities. Names/values are never logged.
    .method private hidebysig static string AttributeUtf16(
        native int buffer, int32 length, native int pointer, int32& budget) cil managed
    {
        .maxstack 5
        .locals init (int32 available, int32 position, int32 codeUnit, bool highSurrogate)
        ldarg.2
        conv.u8
        ldc.i4.1
        conv.u8
        and
        brtrue attributeStringInvalid
        ldarg.1
        ldarg.0
        ldarg.1
        ldarg.2
        ldc.i4.2
        call int32 FolderMap.NtfsJournal::AttributeOffset(native int, int32, native int, int32)
        sub
        stloc available
    attributeStringLoop:
        ldloc position
        ldloc available
        ldc.i4.2
        sub
        bgt attributeStringInvalid
        ldarg.2
        ldloc position
        call int16 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt16(native int, int32)
        ldc.i4 65535
        and
        stloc codeUnit
        ldloc codeUnit
        brfalse attributeStringDone
        ldloc highSurrogate
        brfalse attributeStringOrdinary
        ldloc codeUnit
        ldc.i4 56320
        blt attributeStringInvalid
        ldloc codeUnit
        ldc.i4 57343
        bgt attributeStringInvalid
        ldc.i4.0
        stloc highSurrogate
        br attributeStringAdvance
    attributeStringOrdinary:
        ldloc codeUnit
        ldc.i4 55296
        blt attributeStringAdvance
        ldloc codeUnit
        ldc.i4 57343
        bgt attributeStringAdvance
        ldloc codeUnit
        ldc.i4 56319
        bgt attributeStringInvalid
        ldc.i4.1
        stloc highSurrogate
    attributeStringAdvance:
        ldloc position
        ldc.i4.2
        add
        stloc position
        br attributeStringLoop
    attributeStringDone:
        ldloc highSurrogate
        brtrue attributeStringInvalid
        ldarg.0
        ldarg.1
        ldarg.2
        ldloc position
        ldarg.3
        call string FolderMap.NtfsJournal::AttributeBytesHex(native int, int32, native int, int32, int32&)
        ret
    attributeStringInvalid:
        ldstr "An Authz attribute contains an invalid, unterminated, or out-of-bounds UTF-16 string."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static int32 AttributeValueStride(int32 valueType) cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        beq attributeStride8
        ldarg.0
        ldc.i4.2
        beq attributeStride8
        ldarg.0
        ldc.i4.3
        beq attributeStride8
        ldarg.0
        ldc.i4.6
        beq attributeStride8
        ldarg.0
        ldc.i4.4
        beq attributeStride16
        ldarg.0
        ldc.i4.5
        beq attributeStride16
        ldarg.0
        ldc.i4.s 16
        beq attributeStride16
        ldstr "Unsupported Authz security-attribute value type {0}; use a full scan."
        ldarg.0
        box [mscorlib]System.Int32
        call string [mscorlib]System.String::Format(string, object)
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    attributeStride8:
        ldc.i4.8
        ret
    attributeStride16:
        ldc.i4.s 16
        ret
    }

    // Documented V1 values: INT64/UINT64/BOOLEAN are 8 bytes; STRING is PWSTR;
    // FQBN is {UINT64, PWSTR}; SID/OCTET use {PVOID, ULONG} with a 16-byte x64 stride.
    .method private hidebysig static string CanonicalAttributeValue(
        native int buffer, int32 length, int32 valueType, int32 position, int32& budget) cil managed
    {
        .maxstack 6
        .locals init (
            unsigned int64 number, native int pointer, unsigned int32 byteCount,
            int32 sidLength, class [mscorlib]System.Text.StringBuilder text)
        ldarg.s budget
        ldc.i4.s 32
        call void FolderMap.NtfsJournal::ChargeAttributeBudget(int32&, int32)
        ldarg.0
        ldarg.1
        ldarg.0
        ldarg.3
        call native int [mscorlib]System.IntPtr::Add(native int, int32)
        ldarg.2
        call int32 FolderMap.NtfsJournal::AttributeValueStride(int32)
        call int32 FolderMap.NtfsJournal::AttributeOffset(native int, int32, native int, int32)
        pop
        ldarg.2
        ldc.i4.3
        beq attributeValueString
        ldarg.2
        ldc.i4.4
        beq attributeValueFqbn
        ldarg.2
        ldc.i4.5
        beq attributeValueOctet
        ldarg.2
        ldc.i4.s 16
        beq attributeValueOctet
        ldarg.0
        ldarg.3
        call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
        stloc number
        ldarg.2
        ldc.i4.6
        bne.un attributeValueNumber
        ldloc number
        ldc.i4.1
        conv.u8
        bgt.un attributeValueInvalid
    attributeValueNumber:
        ldarg.s budget
        ldc.i4.s 16
        call void FolderMap.NtfsJournal::ChargeAttributeBudget(int32&, int32)
        ldloc number
        call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
        ret
    attributeValueString:
        ldarg.0
        ldarg.1
        ldarg.0
        ldarg.3
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        ldarg.s budget
        call string FolderMap.NtfsJournal::AttributeUtf16(native int, int32, native int, int32&)
        ret
    attributeValueFqbn:
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
        stloc text
        ldloc text
        ldarg.0
        ldarg.3
        call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc text
        ldarg.0
        ldarg.1
        ldarg.0
        ldarg.3
        ldc.i4.8
        add
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        ldarg.s budget
        call string FolderMap.NtfsJournal::AttributeUtf16(native int, int32, native int, int32&)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc text
        callvirt instance string [mscorlib]System.Object::ToString()
        ret
    attributeValueOctet:
        ldarg.0
        ldarg.3
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        stloc pointer
        ldarg.0
        ldarg.3
        ldc.i4.8
        add
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        stloc byteCount
        ldloc byteCount
        ldarg.1
        bgt.un attributeValueInvalid
        ldarg.2
        ldc.i4.5
        beq attributeValueSid
        ldarg.0
        ldarg.1
        ldloc pointer
        ldloc byteCount
        conv.i4
        ldarg.s budget
        call string FolderMap.NtfsJournal::AttributeBytesHex(native int, int32, native int, int32, int32&)
        ret
    attributeValueSid:
        ldloc byteCount
        ldc.i4.8
        blt.un attributeValueInvalid
        ldarg.0
        ldarg.1
        ldloc pointer
        ldloc byteCount
        conv.i4
        call int32 FolderMap.NtfsJournal::AttributeOffset(native int, int32, native int, int32)
        pop
        ldloc pointer
        ldc.i4.1
        call unsigned int8 [mscorlib]System.Runtime.InteropServices.Marshal::ReadByte(native int, int32)
        ldc.i4.4
        mul
        ldc.i4.8
        add
        stloc sidLength
        ldloc sidLength
        ldloc byteCount
        bne.un attributeValueInvalid
        ldarg.s budget
        ldc.i4 256
        call void FolderMap.NtfsJournal::ChargeAttributeBudget(int32&, int32)
        ldarg.0
        ldarg.1
        ldloc pointer
        call string FolderMap.NtfsJournal::CanonicalSid(native int, int32, native int)
        ret
    attributeValueInvalid:
        ldstr "An Authz attribute value has an invalid Boolean, SID, or byte extent; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    // Every field is encoded, including all 32 flag bits and duplicate values. Values and
    // attributes are unordered sets for access comparisons, so sort without discarding entries.
    // Length prefixes make boundaries unambiguous; exact UTF-16 bytes avoid case/Unicode loss.
    .method private hidebysig static string CanonicalAuthzAttributes(native int buffer, int32 length) cil managed
    {
        .maxstack 8
        .locals init (
            unsigned int32 count, int32 arrayOffset, int32 index, int32 position,
            int32 valueType, unsigned int32 valueCount, int32 stride, int32 valuesOffset,
            int32 valueIndex, int32 budget, string[] entries, string[] values,
            class [mscorlib]System.Text.StringBuilder entry,
            class [mscorlib]System.Text.StringBuilder text, string name,
            native int namePointer, string nameKey,
            class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool> names)
        ldarg.1
        ldc.i4 1048576
        ble attributesWithinLimit
        ldstr "Authz attribute input exceeds its bounded size limit; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    attributesWithinLimit:
        ldarg.0
        ldarg.1
        call unsigned int32 FolderMap.NtfsJournal::ReadAuthzAttributeHeaderCount(native int, int32)
        stloc count
        ldarg.0
        ldarg.1
        ldarg.0
        ldc.i4.8
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        ldloc count
        ldc.i4.s 32
        call int32 FolderMap.NtfsJournal::AttributeArrayOffset(native int, int32, native int, unsigned int32, int32)
        stloc arrayOffset
        ldloc count
        newarr [mscorlib]System.String
        stloc entries
        ldc.i4 4194304
        stloc budget
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_OrdinalIgnoreCase()
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
        stloc names
    attributesLoop:
        ldloc index
        ldloc count
        bge.un attributesSorted
        ldloca budget
        ldc.i4 128
        call void FolderMap.NtfsJournal::ChargeAttributeBudget(int32&, int32)
        ldloc arrayOffset
        ldloc index
        ldc.i4.s 32
        mul
        add
        stloc position
        ldarg.0
        ldloc position
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        stloc namePointer
        ldarg.0
        ldarg.1
        ldloc namePointer
        ldloca budget
        call string FolderMap.NtfsJournal::AttributeUtf16(native int, int32, native int, int32&)
        stloc name
        ldloc name
        callvirt instance int32 [mscorlib]System.String::get_Length()
        brfalse attributesInvalidName
        // Reject ambiguous duplicate names rather than assuming record order is insignificant.
        // The name was already bounds/UTF-16 validated; this decoded form is never logged or hashed.
        ldloc namePointer
        ldloc name
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.4
        div
        call string [mscorlib]System.Runtime.InteropServices.Marshal::PtrToStringUni(native int, int32)
        stloc nameKey
        ldloc names
        ldloc nameKey
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::ContainsKey(!0)
        brtrue attributesDuplicateName
        ldloc names
        ldloc nameKey
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::Add(!0, !1)
        ldarg.0
        ldloc position
        ldc.i4.8
        add
        call int16 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt16(native int, int32)
        ldc.i4 65535
        and
        stloc valueType
        ldloc valueType
        call int32 FolderMap.NtfsJournal::AttributeValueStride(int32)
        stloc stride
        ldarg.0
        ldloc position
        ldc.i4.s 16
        add
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        stloc valueCount
        ldarg.0
        ldarg.1
        ldarg.0
        ldloc position
        ldc.i4.s 24
        add
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        ldloc valueCount
        ldloc stride
        call int32 FolderMap.NtfsJournal::AttributeArrayOffset(native int, int32, native int, unsigned int32, int32)
        stloc valuesOffset
        ldloc valueCount
        newarr [mscorlib]System.String
        stloc values
        ldc.i4.0
        stloc valueIndex
    attributesValueLoop:
        ldloc valueIndex
        ldloc valueCount
        bge.un attributesValuesSorted
        ldloc values
        ldloc valueIndex
        ldarg.0
        ldarg.1
        ldloc valueType
        ldloc valuesOffset
        ldloc valueIndex
        ldloc stride
        mul
        add
        ldloca budget
        call string FolderMap.NtfsJournal::CanonicalAttributeValue(native int, int32, int32, int32, int32&)
        stelem.ref
        ldloc valueIndex
        ldc.i4.1
        add
        stloc valueIndex
        br attributesValueLoop
    attributesValuesSorted:
        ldloc values
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        call void [mscorlib]System.Array::Sort<string>(!!0[], class [mscorlib]System.Collections.Generic.IComparer`1<!!0>)
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
        stloc entry
        ldloc entry
        ldloc name
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc entry
        ldloc valueType
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc entry
        ldarg.0
        ldloc position
        ldc.i4.s 12
        add
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc entry
        ldloc valueCount
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldc.i4.0
        stloc valueIndex
    attributesAppendValues:
        ldloc valueIndex
        ldloc valueCount
        bge.un attributesStore
        ldloc entry
        ldloc values
        ldloc valueIndex
        ldelem.ref
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc valueIndex
        ldc.i4.1
        add
        stloc valueIndex
        br attributesAppendValues
    attributesStore:
        ldloc entries
        ldloc index
        ldloc entry
        callvirt instance string [mscorlib]System.Object::ToString()
        stelem.ref
        ldloc index
        ldc.i4.1
        add
        stloc index
        br attributesLoop
    attributesSorted:
        ldloc entries
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        call void [mscorlib]System.Array::Sort<string>(!!0[], class [mscorlib]System.Collections.Generic.IComparer`1<!!0>)
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
        stloc text
        ldloc text
        ldstr "AUTHZ1"
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc text
        ldloc count
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldc.i4.0
        stloc index
    attributesAppend:
        ldloc index
        ldloc count
        bge.un attributesDone
        ldloc text
        ldloc entries
        ldloc index
        ldelem.ref
        call void FolderMap.NtfsJournal::AppendAttributePart(class [mscorlib]System.Text.StringBuilder, string)
        ldloc index
        ldc.i4.1
        add
        stloc index
        br attributesAppend
    attributesDone:
        ldloc text
        callvirt instance string [mscorlib]System.Object::ToString()
        ret
    attributesInvalidName:
        ldstr "An Authz security attribute has an empty name; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    attributesDuplicateName:
        ldstr "Authz contains duplicate attribute names with ambiguous ordering; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string ReadAuthzAttributeSet(
        class FolderMap.AuthzClientContextHandle context, int32 informationClass,
        bool canonicalize, unsigned int32& count) cil managed
    {
        .maxstack 5
        .locals init (
            unsigned int32 required, unsigned int32 capacity, int32 nativeError,
            native int buffer, string result)
        ldarg.0
        ldarg.1
        ldc.i4.0
        ldloca required
        ldc.i4.0
        conv.i
        call int32 FolderMap.NtfsJournal::AuthzGetInformationFromContext(class FolderMap.AuthzClientContextHandle, int32, unsigned int32, unsigned int32&, native int)
        // A successful sizing call is only an allocation hint, never proof of empty attributes.
        brtrue authzAllocate
    authzSizeFailure:
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
        stloc nativeError
        ldloc nativeError
        ldc.i4 122
        beq authzAllocate
        ldloc nativeError
        ldstr "AuthzGetInformationFromContext({0}) could not size the attribute information."
        ldarg.1
        box [mscorlib]System.Int32
        call string [mscorlib]System.String::Format(string, object)
        call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
    authzAllocate:
        ldloc required
        ldc.i4.s 16
        blt.un authzExtentInvalid
        ldloc required
        ldc.i4 1048576
        bgt.un authzExtentInvalid
        ldloc required
        stloc capacity
        .try
        {
            ldloc capacity
            conv.i4
            call native int [mscorlib]System.Runtime.InteropServices.Marshal::AllocHGlobal(int32)
            stloc buffer
            ldarg.0
            ldarg.1
            ldloc capacity
            ldloca required
            ldloc buffer
            call int32 FolderMap.NtfsJournal::AuthzGetInformationFromContext(class FolderMap.AuthzClientContextHandle, int32, unsigned int32, unsigned int32&, native int)
            brtrue authzReadHeader
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "AuthzGetInformationFromContext({0}) failed while reading attribute information."
            ldarg.1
            box [mscorlib]System.Int32
            call string [mscorlib]System.String::Format(string, object)
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        authzReadHeader:
            ldloc required
            ldloc capacity
            bgt.un authzReturnedInvalid
            ldarg.3
            ldloc buffer
            ldloc required
            conv.i4
            call unsigned int32 FolderMap.NtfsJournal::ReadAuthzAttributeHeaderCount(native int, int32)
            stind.i4
            ldarg.2
            brfalse authzCountOnly
            ldloc buffer
            ldloc required
            conv.i4
            call string FolderMap.NtfsJournal::CanonicalAuthzAttributes(native int, int32)
            stloc result
            leave authzCountDone
        authzCountOnly:
            ldstr ""
            stloc result
            leave authzCountDone
        authzReturnedInvalid:
            ldstr "Authz returned an attribute buffer extent larger than its allocation."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc buffer
            brfalse authzBufferReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        authzBufferReleased:
            endfinally
        }
    authzCountDone:
        ldloc result
        ret
    authzExtentInvalid:
        ldstr "Unsupported Authz attribute buffer extent; persistent cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    // Documented read-only projection of a TOKEN_QUERY handle. No auditing privilege, S4U,
    // dynamic-group callbacks, token modification, or access-check bypass flags are requested.
    // Authz exposes typed security/user/device attribute headers instead of the opaque pointer
    // in TOKEN_ACCESS_INFORMATION:
    // https://learn.microsoft.com/windows/win32/api/authz/nf-authz-authzinitializecontextfromtoken
    // https://learn.microsoft.com/windows/win32/api/authz/ne-authz-authz_context_information_class
    .method private hidebysig static class FolderMap.AuthzAttributeSnapshot CaptureAuthzAttributes(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token, bool canonicalize) cil managed
    {
        .maxstack 7
        .locals init (
            class FolderMap.AuthzResourceManagerHandle manager,
            class FolderMap.AuthzClientContextHandle context,
            valuetype FolderMap.NativeLuid identifier,
            valuetype FolderMap.AuthzAttributeCounts counts,
            class FolderMap.AuthzAttributeSnapshot result)
        .try
        {
            ldc.i4.1
            ldc.i4.0
            conv.i
            ldc.i4.0
            conv.i
            ldc.i4.0
            conv.i
            ldnull
            ldloca manager
            call int32 FolderMap.NtfsJournal::AuthzInitializeResourceManager(unsigned int32, native int, native int, native int, string, class FolderMap.AuthzResourceManagerHandle&)
            brtrue authzManagerOpened
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "AuthzInitializeResourceManager(NO_AUDIT) failed; attributes could not be verified."
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        authzManagerOpened:
            ldloc manager
            callvirt instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::get_IsInvalid()
            brtrue authzHandleInvalid
            ldc.i4.0
            ldarg.0
            ldloc manager
            ldc.i4.0
            conv.i
            ldloc identifier
            ldc.i4.0
            conv.i
            ldloca context
            call int32 FolderMap.NtfsJournal::AuthzInitializeContextFromToken(unsigned int32, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, class FolderMap.AuthzResourceManagerHandle, native int, valuetype FolderMap.NativeLuid, native int, class FolderMap.AuthzClientContextHandle&)
            brtrue authzContextOpened
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
            ldstr "AuthzInitializeContextFromToken(TOKEN_QUERY) failed; attributes could not be verified."
            call void FolderMap.NtfsJournal::ThrowTokenWin32(int32, string)
        authzContextOpened:
            ldloc context
            callvirt instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::get_IsInvalid()
            brtrue authzHandleInvalid
            ldloc context
            ldloc manager
            call instance void FolderMap.AuthzClientContextHandle::KeepManagerAlive(class FolderMap.AuthzResourceManagerHandle)
            newobj instance void FolderMap.AuthzAttributeSnapshot::.ctor()
            stloc result
            ldloc result
            ldloc context
            ldc.i4.s 11
            ldarg.1
            ldloca counts
            ldflda unsigned int32 FolderMap.AuthzAttributeCounts::SecurityAttributes
            call string FolderMap.NtfsJournal::ReadAuthzAttributeSet(class FolderMap.AuthzClientContextHandle, int32, bool, unsigned int32&)
            stfld string FolderMap.AuthzAttributeSnapshot::SecurityAttributes
            ldloc result
            ldloc context
            ldc.i4.s 13
            ldarg.1
            ldloca counts
            ldflda unsigned int32 FolderMap.AuthzAttributeCounts::UserClaims
            call string FolderMap.NtfsJournal::ReadAuthzAttributeSet(class FolderMap.AuthzClientContextHandle, int32, bool, unsigned int32&)
            stfld string FolderMap.AuthzAttributeSnapshot::UserClaims
            ldloc result
            ldloc context
            ldc.i4.s 14
            ldarg.1
            ldloca counts
            ldflda unsigned int32 FolderMap.AuthzAttributeCounts::DeviceClaims
            call string FolderMap.NtfsJournal::ReadAuthzAttributeSet(class FolderMap.AuthzClientContextHandle, int32, bool, unsigned int32&)
            stfld string FolderMap.AuthzAttributeSnapshot::DeviceClaims
            ldloc result
            ldloc counts
            stfld valuetype FolderMap.AuthzAttributeCounts FolderMap.AuthzAttributeSnapshot::Counts
            ldloc result
            ldarg.1
            stfld bool FolderMap.AuthzAttributeSnapshot::HasCanonicalData
            leave authzCaptureDone
        authzHandleInvalid:
            ldstr "Authz returned an invalid ownership handle; attributes could not be verified."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc context
            brfalse authzCaptureContextReleased
            ldloc context
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        authzCaptureContextReleased:
            ldloc manager
            brfalse authzCaptureManagerReleased
            ldloc manager
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        authzCaptureManagerReleased:
            endfinally
        }
    authzCaptureDone:
        ldloc result
        ret
    }

    .method private hidebysig static valuetype FolderMap.AuthzAttributeCounts CaptureAuthzAttributeCounts(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token) cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.0
        call class FolderMap.AuthzAttributeSnapshot FolderMap.NtfsJournal::CaptureAuthzAttributes(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, bool)
        ldfld valuetype FolderMap.AuthzAttributeCounts FolderMap.AuthzAttributeSnapshot::Counts
        ret
    }

    // Bit 0: short/null header; bit 1: nonprimary; bit 2: app-container number;
    // bit 3: package SID present; bit 4: opaque attribute container present (not an attribute count).
    .method private hidebysig static unsigned int32 TokenAccessConditions(native int buffer, int32 length) cil managed
    {
        .maxstack 2
        .locals init (unsigned int32 conditions)
        ldarg.0
        brfalse accessConditionsShort
        ldarg.1
        ldc.i4.s 88
        bge accessConditionsType
    accessConditionsShort:
        ldc.i4.1
        ret
    accessConditionsType:
        ldarg.0
        ldc.i4.s 32
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        ldc.i4.1
        beq accessConditionsContainer
        ldc.i4.2
        stloc conditions
    accessConditionsContainer:
        ldarg.0
        ldc.i4.s 48
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        brfalse accessConditionsPackage
        ldloc conditions
        ldc.i4.4
        or
        stloc conditions
    accessConditionsPackage:
        ldarg.0
        ldc.i4.s 56
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        brfalse accessConditionsOpaque
        ldloc conditions
        ldc.i4.8
        or
        stloc conditions
    accessConditionsOpaque:
        ldarg.0
        ldc.i4.s 80
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        brfalse accessConditionsDone
        ldloc conditions
        ldc.i4.s 16
        or
        stloc conditions
    accessConditionsDone:
        ldloc conditions
        ret
    }

    .method private hidebysig static void RequireSupportedTokenAccess(unsigned int32 conditions) cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.s 15
        and
        brfalse accessConditionsSupported
        ldstr "Unsupported token access conditions (flags {0}); cache reuse is unsafe. Bits: 1=short header, 2=nonprimary, 4=app container, 8=package SID."
        ldarg.0
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call string [mscorlib]System.String::Format(string, object)
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    accessConditionsSupported:
        ret
    }

    .method private hidebysig static void RequireCanonicalAuthzAttributes(class FolderMap.AuthzAttributeSnapshot snapshot) cil managed
    {
        .maxstack 1
        ldarg.0
        brfalse authzAttributesIncomplete
        ldarg.0
        ldfld bool FolderMap.AuthzAttributeSnapshot::HasCanonicalData
        brfalse authzAttributesIncomplete
        ldarg.0
        ldfld string FolderMap.AuthzAttributeSnapshot::SecurityAttributes
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue authzAttributesIncomplete
        ldarg.0
        ldfld string FolderMap.AuthzAttributeSnapshot::UserClaims
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue authzAttributesIncomplete
        ldarg.0
        ldfld string FolderMap.AuthzAttributeSnapshot::DeviceClaims
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue authzAttributesIncomplete
        ret
    authzAttributesIncomplete:
        ldstr "Authz attribute data was not fully canonicalized; cache reuse is unsafe."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    }

    .method private hidebysig static string CanonicalTokenAccess(
        native int buffer, int32 length, class FolderMap.AuthzAttributeSnapshot snapshot) cil managed
    {
        .maxstack 8
        .locals init (native int sid, class [mscorlib]System.Text.StringBuilder text)
        ldarg.0
        ldarg.1
        call unsigned int32 FolderMap.NtfsJournal::TokenAccessConditions(native int, int32)
        call void FolderMap.NtfsJournal::RequireSupportedTokenAccess(unsigned int32)
        ldarg.2
        call void FolderMap.NtfsJournal::RequireCanonicalAuthzAttributes(class FolderMap.AuthzAttributeSnapshot)
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
        stloc text
        ldloc text
        ldstr "authentication"
        ldarg.0
        ldc.i4.s 24
        call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldloc text
        ldstr "flags"
        ldarg.0
        ldc.i4.s 44
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldloc text
        ldstr "mandatory"
        ldarg.0
        ldc.i4.s 40
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
        call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldarg.0
        ldc.i4.s 72
        call native int [mscorlib]System.Runtime.InteropServices.Marshal::ReadIntPtr(native int, int32)
        stloc sid
        ldloc sid
        brfalse tokenAccessNoTrustSid
        ldloc text
        ldstr "trust"
        ldarg.0
        ldarg.1
        ldloc sid
        call string FolderMap.NtfsJournal::CanonicalSid(native int, int32, native int)
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        br tokenAccessAttributes
    tokenAccessNoTrustSid:
        ldloc text
        ldstr "trust"
        ldstr "-"
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
    tokenAccessAttributes:
        ldloc text
        ldstr "security-attributes"
        ldarg.2
        ldfld string FolderMap.AuthzAttributeSnapshot::SecurityAttributes
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldloc text
        ldstr "user-claims"
        ldarg.2
        ldfld string FolderMap.AuthzAttributeSnapshot::UserClaims
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldloc text
        ldstr "device-claims"
        ldarg.2
        ldfld string FolderMap.AuthzAttributeSnapshot::DeviceClaims
        call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
        ldloc text
        callvirt instance string [mscorlib]System.Object::ToString()
        ret
    }

    .method private hidebysig static string TokenAccessText(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
        unsigned int32 nativeUserClaims, unsigned int32 nativeDeviceClaims) cil managed
    {
        .maxstack 3
        .locals init (
            native int buffer, int32 length,
            class FolderMap.AuthzAttributeSnapshot snapshot,
            valuetype FolderMap.AuthzAttributeCounts counts, string result)
        .try
        {
            ldarg.0
            ldc.i4.s 22
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc buffer
            ldloc length
            call unsigned int32 FolderMap.NtfsJournal::TokenAccessConditions(native int, int32)
            call void FolderMap.NtfsJournal::RequireSupportedTokenAccess(unsigned int32)
            // Always obtain typed counts, even when the opaque pointer happens to be null.
            ldarg.0
            ldc.i4.1
            call class FolderMap.AuthzAttributeSnapshot FolderMap.NtfsJournal::CaptureAuthzAttributes(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, bool)
            stloc snapshot
            ldloc snapshot
            ldfld valuetype FolderMap.AuthzAttributeCounts FolderMap.AuthzAttributeSnapshot::Counts
            stloc counts
            ldloca counts
            ldfld unsigned int32 FolderMap.AuthzAttributeCounts::UserClaims
            ldarg.1
            bne.un tokenClaimProjectionMismatch
            ldloca counts
            ldfld unsigned int32 FolderMap.AuthzAttributeCounts::DeviceClaims
            ldarg.2
            bne.un tokenClaimProjectionMismatch
            ldloc buffer
            ldloc length
            ldloc snapshot
            call string FolderMap.NtfsJournal::CanonicalTokenAccess(native int, int32, class FolderMap.AuthzAttributeSnapshot)
            stloc result
            leave tokenAccessDone
        tokenClaimProjectionMismatch:
            ldstr "Authz user/device claim counts differ from the queried token; cache reuse is unsafe."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc buffer
            brfalse tokenAccessReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        tokenAccessReleased:
            endfinally
        }
    tokenAccessDone:
        ldloc result
        ret
    }

    // Diagnostic only: condition bits and documented attribute counts, never SIDs, claim values,
    // authentication IDs, or pointer addresses. This does not return an authorization/cache key.
    .method public hidebysig static string SecurityContextDiagnostics() cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            native int buffer, int32 length,
            valuetype FolderMap.AuthzAttributeCounts counts,
            class [mscorlib]System.Text.StringBuilder text, string result)
        call void FolderMap.NtfsJournal::RejectThreadToken()
        .try
        {
            call class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle FolderMap.NtfsJournal::OpenSecurityToken()
            stloc token
            ldloc token
            ldc.i4.s 22
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc buffer
            ldloc token
            call valuetype FolderMap.AuthzAttributeCounts FolderMap.NtfsJournal::CaptureAuthzAttributeCounts(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle)
            stloc counts
            newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
            stloc text
            ldloc text
            ldstr "access-conditions"
            ldloc buffer
            ldloc length
            call unsigned int32 FolderMap.NtfsJournal::TokenAccessConditions(native int, int32)
            call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "security-attribute-count"
            ldloca counts
            ldfld unsigned int32 FolderMap.AuthzAttributeCounts::SecurityAttributes
            call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "user-claim-count"
            ldloca counts
            ldfld unsigned int32 FolderMap.AuthzAttributeCounts::UserClaims
            call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "device-claim-count"
            ldloca counts
            ldfld unsigned int32 FolderMap.AuthzAttributeCounts::DeviceClaims
            call string FolderMap.NtfsJournal::TokenHex32(unsigned int32)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            callvirt instance string [mscorlib]System.Object::ToString()
            ldstr "\n"
            ldstr ";"
            callvirt instance string [mscorlib]System.String::Replace(string, string)
            stloc result
            leave securityDiagnosticDone
        }
        finally
        {
            ldloc buffer
            brfalse securityDiagnosticBufferReleased
            ldloc buffer
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        securityDiagnosticBufferReleased:
            ldloc token
            brfalse securityDiagnosticTokenReleased
            ldloc token
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        securityDiagnosticTokenReleased:
            endfinally
        }
    securityDiagnosticDone:
        ldloc result
        ret
    }

    .method private hidebysig static string HashTokenContext(string canonical) cil managed
    {
        .maxstack 8
        .locals init (class [mscorlib]System.Security.Cryptography.SHA256 hash, string result)
        .try
        {
            call class [mscorlib]System.Security.Cryptography.SHA256 [mscorlib]System.Security.Cryptography.SHA256::Create()
            stloc hash
            ldloc hash
            brfalse tokenHashUnavailable
            ldloc hash
            callvirt instance int32 [mscorlib]System.Security.Cryptography.HashAlgorithm::get_HashSize()
            ldc.i4 256
            bne.un tokenHashUnavailable
            ldstr "ntfs-token-v3:"
            ldloc hash
            call class [mscorlib]System.Text.Encoding [mscorlib]System.Text.Encoding::get_UTF8()
            ldarg.0
            callvirt instance unsigned int8[] [mscorlib]System.Text.Encoding::GetBytes(string)
            callvirt instance unsigned int8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::ComputeHash(unsigned int8[])
            call string [mscorlib]System.BitConverter::ToString(unsigned int8[])
            ldstr "-"
            ldstr ""
            callvirt instance string [mscorlib]System.String::Replace(string, string)
            callvirt instance string [mscorlib]System.String::ToLowerInvariant()
            call string [mscorlib]System.String::Concat(string, string)
            stloc result
            leave tokenHashDone
        tokenHashUnavailable:
            ldstr "SHA-256 is unavailable for token authorization fingerprinting."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc hash
            brfalse tokenHashReleased
            ldloc hash
            callvirt instance void [mscorlib]System.Security.Cryptography.HashAlgorithm::Dispose()
        tokenHashReleased:
            endfinally
        }
    tokenHashDone:
        ldloc result
        ret
    }

    // A read-authorization fingerprint, not a token-instance fingerprint. AuthenticationId is
    // logon-scoped; TokenId/ModifiedId are used only to detect replacement/mutation during capture.
    // DefaultDacl, source identifiers, allocator state, native hashes, and pointers are never hashed.
    // Filter history includes UAC-filtered tokens. Those tokens deliberately fall back to full scans.
    .method public hidebysig static string SecurityContext() cil managed
    {
        .maxstack 8
        .locals init (
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle token,
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle currentToken,
            native int statistics,
            int32 length,
            unsigned int64 tokenId,
            unsigned int64 modifiedId,
            unsigned int64 authenticationId,
            unsigned int64 expiration,
            unsigned int32 nativeUserClaims,
            unsigned int32 nativeDeviceClaims,
            class [mscorlib]System.Text.StringBuilder text,
            string result)

        call int32 [mscorlib]System.IntPtr::get_Size()
        ldc.i4.8
        beq securityContextStart
        ldstr "Token fingerprinting requires the supported x64 token layout; use a full scan."
        newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
        throw
    securityContextStart:
        call void FolderMap.NtfsJournal::RejectThreadToken()
        .try
        {
            call class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle FolderMap.NtfsJournal::OpenSecurityToken()
            stloc token
            ldloc token
            ldc.i4.s 10
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc statistics
            ldloc length
            ldc.i4.s 56
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc statistics
            ldc.i4.s 24
            call int32 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt32(native int, int32)
            ldc.i4.1
            bne.un securityContextUnsupported
            ldloc statistics
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
            stloc tokenId
            ldloc statistics
            ldc.i4.s 48
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
            stloc modifiedId
            ldloc statistics
            ldc.i4.8
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
            stloc authenticationId
            ldloc statistics
            ldc.i4.s 16
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
            stloc expiration
            ldloc statistics
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
            ldc.i4.0
            conv.i
            stloc statistics
            ldloc token
            ldc.i4.8
            call unsigned int32 FolderMap.NtfsJournal::TokenUInt32(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
            ldc.i4.1
            bne.un securityContextUnsupported
            ldloc token
            ldc.i4.s 29
            call unsigned int32 FolderMap.NtfsJournal::TokenUInt32(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
            brtrue securityContextUnsupported
            ldloc token
            ldc.i4.s 21
            call unsigned int32 FolderMap.NtfsJournal::TokenUInt32(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
            brtrue securityContextFiltered

            // No restricted SID access checks, capabilities, device groups, or opaque claims are approximated.
            // Filtered tokens are rejected before querying supported group classes; the documented
            // RestrictedDeviceGroups query is not implemented on all Windows versions.
            ldloc token
            ldc.i4.s 11
            ldc.i4.1
            call string FolderMap.NtfsJournal::TokenGroupsText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            pop
            ldloc token
            ldc.i4.s 30
            ldc.i4.1
            call string FolderMap.NtfsJournal::TokenGroupsText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            pop
            ldloc token
            ldc.i4.s 37
            ldc.i4.1
            call string FolderMap.NtfsJournal::TokenGroupsText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            pop
            ldloc token
            ldc.i4.s 33
            call unsigned int32 FolderMap.NtfsJournal::ReadTokenClaimCount(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
            stloc nativeUserClaims
            ldloc token
            ldc.i4.s 34
            call unsigned int32 FolderMap.NtfsJournal::ReadTokenClaimCount(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32)
            stloc nativeDeviceClaims

            newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
            stloc text
            ldloc text
            ldstr "schema"
            ldstr "FolderMap.read-authorization.v3"
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "authentication"
            ldloc authenticationId
            call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "expiration"
            ldloc expiration
            call string FolderMap.NtfsJournal::TokenHex64(unsigned int64)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "user"
            ldloc token
            ldc.i4.1
            ldc.i4.1
            call string FolderMap.NtfsJournal::TokenSidText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "owner"
            ldloc token
            ldc.i4.4
            ldc.i4.0
            call string FolderMap.NtfsJournal::TokenSidText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "primary-group"
            ldloc token
            ldc.i4.5
            ldc.i4.0
            call string FolderMap.NtfsJournal::TokenSidText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "groups"
            ldloc token
            ldc.i4.2
            ldc.i4.0
            call string FolderMap.NtfsJournal::TokenGroupsText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "logon-sids"
            ldloc token
            ldc.i4.s 28
            ldc.i4.0
            call string FolderMap.NtfsJournal::TokenGroupsText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "privileges"
            ldloc token
            call string FolderMap.NtfsJournal::TokenPrivilegesText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "integrity"
            ldloc token
            ldc.i4.s 25
            ldc.i4.1
            call string FolderMap.NtfsJournal::TokenSidText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, bool)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)
            ldloc text
            ldstr "access"
            ldloc token
            ldloc nativeUserClaims
            ldloc nativeDeviceClaims
            call string FolderMap.NtfsJournal::TokenAccessText(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, unsigned int32, unsigned int32)
            call void FolderMap.NtfsJournal::AppendTokenField(class [mscorlib]System.Text.StringBuilder, string, string)

            ldloc text
            ldloc token
            ldc.i4.s 12
            ldstr "session"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 18
            ldstr "elevation-type"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 20
            ldstr "elevated"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 21
            ldstr "has-filter-history"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 15
            ldstr "sandbox-inert"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 23
            ldstr "virtualization-allowed"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 24
            ldstr "virtualization-enabled"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 26
            ldstr "ui-access"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)
            ldloc text
            ldloc token
            ldc.i4.s 27
            ldstr "mandatory-policy"
            call void FolderMap.NtfsJournal::AppendTokenNumber(class [mscorlib]System.Text.StringBuilder, class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, string)

            ldloc text
            callvirt instance string [mscorlib]System.Object::ToString()
            call string FolderMap.NtfsJournal::HashTokenContext(string)
            stloc result
            call void FolderMap.NtfsJournal::RejectThreadToken()
            call class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle FolderMap.NtfsJournal::OpenSecurityToken()
            stloc currentToken
            ldloc currentToken
            ldc.i4.s 10
            ldloca length
            call native int FolderMap.NtfsJournal::GetTokenBuffer(class [mscorlib]Microsoft.Win32.SafeHandles.SafeAccessTokenHandle, int32, int32&)
            stloc statistics
            ldloc length
            ldc.i4.s 56
            call void FolderMap.NtfsJournal::RequireTokenSize(int32, int32)
            ldloc statistics
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int)
            ldloc tokenId
            bne.un securityContextChanged
            ldloc statistics
            ldc.i4.s 48
            call int64 [mscorlib]System.Runtime.InteropServices.Marshal::ReadInt64(native int, int32)
            ldloc modifiedId
            bne.un securityContextChanged
            call void FolderMap.NtfsJournal::RejectThreadToken()
            leave securityContextDone
        securityContextUnsupported:
            ldstr "App-container and impersonation token contexts are unsupported for persistent cache reuse; use a full scan."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        securityContextFiltered:
            ldstr "Filtered or restricted Windows tokens cannot be fingerprinted completely by the supported token APIs; use a full scan."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        securityContextChanged:
            ldstr "The Windows token was replaced or modified during fingerprinting; persistent cache reuse is unsafe."
            newobj instance void [mscorlib]System.Security.SecurityException::.ctor(string)
            throw
        }
        finally
        {
            ldloc statistics
            brfalse securityContextStatisticsReleased
            ldloc statistics
            call void [mscorlib]System.Runtime.InteropServices.Marshal::FreeHGlobal(native int)
        securityContextStatisticsReleased:
            ldloc currentToken
            brfalse securityContextCurrentReleased
            ldloc currentToken
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        securityContextCurrentReleased:
            ldloc token
            brfalse securityContextTokenReleased
            ldloc token
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        securityContextTokenReleased:
            endfinally
        }
    securityContextDone:
        ldloc result
        ret
    }

    .method assembly hidebysig static void ThrowLastWin32(string message) cil managed
    {
        .maxstack 2
        call int32 [mscorlib]System.Runtime.InteropServices.Marshal::GetLastWin32Error()
        ldarg.0
        newobj instance void [System]System.ComponentModel.Win32Exception::.ctor(int32, string)
        throw
    }

    .method assembly hidebysig static void CheckCancellation(class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 1
        ldarg.0
        brfalse cancellationDone
        ldarg.0
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_CancellationPending()
        brfalse cancellationDone
        ldstr "The NTFS journal operation was canceled."
        newobj instance void [mscorlib]System.OperationCanceledException::.ctor(string)
        throw
    cancellationDone:
        ret
    }

    .method public hidebysig static class FolderMap.FileIdentity GetIdentity(string path) cil managed
    {
        .maxstack 7
        .locals init (
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle nativeHandle,
            valuetype FolderMap.NativeFileInformation fileInfo,
            class FolderMap.FileIdentity result)

        ldarg.0
        brtrue identityNotNull
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    identityNotNull:
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        brtrue identityOpen
        ldstr "A file or directory path is required."
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    identityOpen:
        .try
        {
            ldarg.0
            ldc.i4.0
            ldc.i4.7
            ldc.i4.0
            conv.i
            ldc.i4.3
            ldc.i4 0x02200000
            ldc.i4.0
            conv.i
            call class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.NtfsJournal::CreateFileW(string, unsigned int32, unsigned int32, native int, unsigned int32, unsigned int32, native int)
            stloc nativeHandle
            ldloc nativeHandle
            callvirt instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::get_IsInvalid()
            brfalse identityInformation
            ldstr "CreateFileW failed while opening a metadata-only, non-following identity handle."
            call void FolderMap.NtfsJournal::ThrowLastWin32(string)
        identityInformation:
            ldloc nativeHandle
            ldloca fileInfo
            call int32 FolderMap.NtfsJournal::GetFileInformationByHandle(class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle, valuetype FolderMap.NativeFileInformation&)
            brtrue identityLength
            ldstr "GetFileInformationByHandle failed while reading file identity metadata."
            call void FolderMap.NtfsJournal::ThrowLastWin32(string)
        identityLength:
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::FileSizeHigh
            ldc.i4 0x80000000
            and
            brfalse identityConstruct
            ldstr "The logical file length exceeds the nonnegative Int64 range."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        identityConstruct:
            newobj instance void FolderMap.FileIdentity::.ctor()
            stloc result
            ldloc result
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::FileIndexHigh
            conv.u8
            ldc.i4.s 32
            shl
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::FileIndexLow
            conv.u8
            or
            stfld unsigned int64 FolderMap.FileIdentity::FileId
            ldloc result
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::VolumeSerial
            stfld unsigned int32 FolderMap.FileIdentity::VolumeSerial
            ldloc result
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::LinkCount
            stfld unsigned int32 FolderMap.FileIdentity::LinkCount
            ldloc result
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::Attributes
            stfld unsigned int32 FolderMap.FileIdentity::Attributes
            ldloc result
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::FileSizeHigh
            conv.u8
            ldc.i4.s 32
            shl
            ldloca fileInfo
            ldfld unsigned int32 FolderMap.NativeFileInformation::FileSizeLow
            conv.u8
            or
            conv.ovf.i8.un
            stfld int64 FolderMap.FileIdentity::Length
            leave identityDone
        }
        finally
        {
            ldloc nativeHandle
            brfalse identityReleased
            ldloc nativeHandle
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        identityReleased:
            endfinally
        }
    identityDone:
        ldloc result
        ret
    }

    .method private hidebysig static void ValidateLocalPath(string rootPath) cil managed
    {
        .maxstack 3
        .locals init (string drivePath)
        ldarg.0
        brtrue pathNotNull
        ldstr "rootPath"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    pathNotNull:
        ldarg.0
        stloc drivePath
        ldarg.0
        ldstr "\\\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse pathDrive
        ldarg.0
        ldstr "\\\\?\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse pathRemote
        ldarg.0
        ldstr "\\\\?\\UNC\\"
        ldc.i4.5
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brtrue pathRemote
        ldarg.0
        ldstr "\\\\?\\Volume{"
        ldc.i4.5
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brtrue pathValid
        ldarg.0
        ldc.i4.4
        callvirt instance string [mscorlib]System.String::Substring(int32)
        stloc drivePath
    pathDrive:
        ldloc drivePath
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.3
        blt pathInvalid
        ldloc drivePath
        ldc.i4.0
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        call bool [mscorlib]System.Char::IsLetter(char)
        brfalse pathInvalid
        ldloc drivePath
        ldc.i4.1
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 58
        bne.un pathInvalid
        ldloc drivePath
        ldc.i4.2
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 92
        bne.un pathInvalid
        // Reject mapped network drives before attempting a metadata handle on the remote root.
        ldloc drivePath
        ldc.i4.0
        ldc.i4.3
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        call unsigned int32 FolderMap.NtfsJournal::GetDriveTypeW(string)
        ldc.i4.4
        beq pathRemote
        br pathValid
    pathRemote:
        ldstr "USN journal access supports local NTFS volumes only; UNC and network paths are not supported."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    pathInvalid:
        ldstr "A normalized, absolute local directory path is required."
        ldstr "rootPath"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    pathValid:
        ret
    }

    .method public hidebysig static class FolderMap.JournalSession Open(string rootPath) cil managed
    {
        .maxstack 8
        .locals init (
            class FolderMap.FileIdentity identity,
            class FolderMap.FileIdentity checkedIdentity,
            class [mscorlib]System.Text.StringBuilder volumePathBuffer,
            class [mscorlib]System.Text.StringBuilder volumeNameBuffer,
            class [mscorlib]System.Text.StringBuilder fileSystemBuffer,
            string mountPoint,
            string volumeName,
            string deviceName,
            unsigned int32 serial,
            unsigned int32 maximumComponentLength,
            unsigned int32 fileSystemFlags,
            unsigned int32 driveType,
            class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle nativeHandle,
            class FolderMap.JournalSession result)

        ldarg.0
        call void FolderMap.NtfsJournal::ValidateLocalPath(string)
        ldarg.0
        call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
        stloc identity
        ldloc identity
        ldfld unsigned int32 FolderMap.FileIdentity::Attributes
        ldc.i4 0x400
        and
        brfalse openDirectory
        ldstr "A reparse-point scan root is not supported; select a non-reparse directory on the target volume."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    openDirectory:
        ldloc identity
        ldfld unsigned int32 FolderMap.FileIdentity::Attributes
        ldc.i4.s 16
        and
        brtrue openMountPoint
        ldstr "The scan root must be a directory."
        ldstr "rootPath"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    openMountPoint:
        ldc.i4 32768
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(int32)
        stloc volumePathBuffer
        ldarg.0
        ldloc volumePathBuffer
        ldc.i4 32768
        call int32 FolderMap.NtfsJournal::GetVolumePathNameW(string, class [mscorlib]System.Text.StringBuilder, unsigned int32)
        brtrue openDriveType
        ldstr "GetVolumePathNameW failed while resolving the scan root's actual volume mount point."
        call void FolderMap.NtfsJournal::ThrowLastWin32(string)
    openDriveType:
        ldloc volumePathBuffer
        callvirt instance string [mscorlib]System.Object::ToString()
        stloc mountPoint
        ldloc mountPoint
        call unsigned int32 FolderMap.NtfsJournal::GetDriveTypeW(string)
        stloc driveType
        ldloc driveType
        ldc.i4.2
        beq openVolumeName
        ldloc driveType
        ldc.i4.3
        beq openVolumeName
        ldloc driveType
        ldc.i4.6
        beq openVolumeName
        ldstr "The scan root is not on a supported local disk; remote and unknown drive types are not supported."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    openVolumeName:
        ldc.i4 1024
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(int32)
        stloc volumeNameBuffer
        ldloc mountPoint
        ldloc volumeNameBuffer
        ldc.i4 1024
        call int32 FolderMap.NtfsJournal::GetVolumeNameForVolumeMountPointW(string, class [mscorlib]System.Text.StringBuilder, unsigned int32)
        brtrue openFileSystem
        ldstr "GetVolumeNameForVolumeMountPointW failed while resolving a stable local volume GUID."
        call void FolderMap.NtfsJournal::ThrowLastWin32(string)
    openFileSystem:
        ldloc volumeNameBuffer
        callvirt instance string [mscorlib]System.Object::ToString()
        stloc volumeName
        ldc.i4 128
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(int32)
        stloc fileSystemBuffer
        ldloc volumeName
        ldnull
        ldc.i4.0
        ldloca serial
        ldloca maximumComponentLength
        ldloca fileSystemFlags
        ldloc fileSystemBuffer
        ldc.i4 128
        call int32 FolderMap.NtfsJournal::GetVolumeInformationW(string, class [mscorlib]System.Text.StringBuilder, unsigned int32, unsigned int32&, unsigned int32&, unsigned int32&, class [mscorlib]System.Text.StringBuilder, unsigned int32)
        brtrue openNtfs
        ldstr "GetVolumeInformationW failed while checking the volume filesystem and serial number."
        call void FolderMap.NtfsJournal::ThrowLastWin32(string)
    openNtfs:
        ldloc fileSystemBuffer
        callvirt instance string [mscorlib]System.Object::ToString()
        ldstr "NTFS"
        ldc.i4.5
        call bool [mscorlib]System.String::Equals(string, string, valuetype [mscorlib]System.StringComparison)
        brtrue openSerial
        ldstr "USN journal access supports NTFS only; other filesystems require a full scan."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    openSerial:
        ldloc identity
        ldfld unsigned int32 FolderMap.FileIdentity::VolumeSerial
        ldloc serial
        beq openDeviceName
        ldstr "The scan root and resolved volume have different serial numbers; the root may have changed."
        newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
        throw
    openDeviceName:
        ldloc volumeName
        ldstr "\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::EndsWith(string, valuetype [mscorlib]System.StringComparison)
        brtrue openTrimName
        ldstr "The volume mount manager returned an invalid volume GUID path."
        newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
        throw
    openTrimName:
        ldloc volumeName
        ldc.i4.0
        ldloc volumeName
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.1
        sub
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc deviceName
        .try
        {
            ldloc deviceName
            ldc.i4 0x80000000
            ldc.i4.7
            ldc.i4.0
            conv.i
            ldc.i4.3
            ldc.i4.0
            ldc.i4.0
            conv.i
            call class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.NtfsJournal::CreateFileW(string, unsigned int32, unsigned int32, native int, unsigned int32, unsigned int32, native int)
            stloc nativeHandle
            ldloc nativeHandle
            callvirt instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::get_IsInvalid()
            brfalse openRecheck
            ldstr "CreateFileW failed while opening the NTFS volume read-only. Volume access may require user-initiated elevation."
            call void FolderMap.NtfsJournal::ThrowLastWin32(string)
        openRecheck:
            ldarg.0
            call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
            stloc checkedIdentity
            ldloc checkedIdentity
            ldfld unsigned int32 FolderMap.FileIdentity::Attributes
            ldc.i4 0x410
            and
            ldc.i4.s 16
            bne.un openChanged
            ldloc checkedIdentity
            ldfld unsigned int64 FolderMap.FileIdentity::FileId
            ldloc identity
            ldfld unsigned int64 FolderMap.FileIdentity::FileId
            bne.un openChanged
            ldloc checkedIdentity
            ldfld unsigned int32 FolderMap.FileIdentity::VolumeSerial
            ldloc serial
            bne.un openChanged
            ldloc nativeHandle
            ldloc volumeName
            ldarg.0
            ldloc identity
            ldfld unsigned int64 FolderMap.FileIdentity::FileId
            ldloc serial
            newobj instance void FolderMap.JournalSession::.ctor(class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle, string, string, unsigned int64, unsigned int32)
            stloc result
            ldnull
            stloc nativeHandle
            leave openDone
        openChanged:
            ldstr "The scan root changed while opening the NTFS journal; a full scan is required."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        }
        finally
        {
            ldloc nativeHandle
            brfalse openReleased
            ldloc nativeHandle
            callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
        openReleased:
            endfinally
        }
    openDone:
        ldloc result
        ret
    }

    .method assembly hidebysig static void WriteInt64(unsigned int8[] buffer, int32 offset, int64 number) cil managed
    {
        .maxstack 5
        ldarg.2
        call unsigned int8[] [mscorlib]System.BitConverter::GetBytes(int64)
        ldc.i4.0
        ldarg.0
        ldarg.1
        ldc.i4.8
        call void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)
        ret
    }

    .method assembly hidebysig static void WriteInt32(unsigned int8[] buffer, int32 offset, int32 number) cil managed
    {
        .maxstack 5
        ldarg.2
        call unsigned int8[] [mscorlib]System.BitConverter::GetBytes(int32)
        ldc.i4.0
        ldarg.0
        ldarg.1
        ldc.i4.4
        call void [mscorlib]System.Buffer::BlockCopy(class [mscorlib]System.Array, int32, class [mscorlib]System.Array, int32, int32)
        ret
    }

    .method public hidebysig static int64 ParseBuffer(
        unsigned int8[] buffer,
        int32 bytesReturned,
        int64 minimumUsn,
        int64 maximumUsn,
        class [mscorlib]System.Action`1<class FolderMap.UsnChange> receiver,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 7
        .locals init (int64 recordCount)
        ldarg.0
        ldarg.1
        ldarg.2
        ldarg.3
        ldarg.s receiver
        ldarg.s worker
        ldloca recordCount
        call int64 FolderMap.NtfsJournal::ParseBufferCore(unsigned int8[], int32, int64, int64, class [mscorlib]System.Action`1<class FolderMap.UsnChange>, class [System]System.ComponentModel.BackgroundWorker, int64&)
        ret
    }

    .method assembly hidebysig static int64 ParseBufferCore(
        unsigned int8[] buffer,
        int32 bytesReturned,
        int64 minimumUsn,
        int64 maximumUsn,
        class [mscorlib]System.Action`1<class FolderMap.UsnChange> receiver,
        class [System]System.ComponentModel.BackgroundWorker worker,
        int64& recordCount) cil managed
    {
        .maxstack 5
        .locals init (
            int64 continuation,
            int32 position,
            int32 remaining,
            unsigned int32 recordLength,
            int32 nameLength,
            int32 nameOffset,
            int64 recordUsn,
            int64 previousUsn,
            class FolderMap.UsnChange change)

        ldarg.0
        brtrue parseReceiver
        ldstr "buffer"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    parseReceiver:
        ldarg.s receiver
        brtrue parseByteCount
        ldstr "receiver"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    parseByteCount:
        ldarg.1
        ldc.i4.0
        blt parseBadByteCount
        ldarg.1
        ldarg.0
        ldlen
        conv.i4
        ble parseMinimum
    parseBadByteCount:
        ldstr "bytesReturned"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    parseMinimum:
        ldarg.2
        ldc.i4.0
        conv.i8
        bge parseMaximum
        ldstr "minimumUsn"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    parseMaximum:
        ldarg.3
        ldarg.2
        bge parseStart
        ldstr "maximumUsn"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    parseStart:
        ldarg.s worker
        call void FolderMap.NtfsJournal::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.s recordCount
        ldc.i4.0
        conv.i8
        stind.i8
        ldarg.1
        ldc.i4.8
        blt parseMalformed
        ldarg.0
        ldc.i4.0
        call int64 [mscorlib]System.BitConverter::ToInt64(unsigned int8[], int32)
        stloc continuation
        ldloc continuation
        ldc.i4.0
        conv.i8
        blt parseMalformed
        ldc.i4.8
        stloc position
        ldc.i4.m1
        conv.i8
        stloc previousUsn
    parseLoop:
        ldarg.s worker
        call void FolderMap.NtfsJournal::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc position
        ldarg.1
        beq parseDone
        ldarg.1
        ldloc position
        sub
        stloc remaining
        ldloc remaining
        ldc.i4.8
        blt parseMalformed
        ldarg.0
        ldloc position
        call unsigned int32 [mscorlib]System.BitConverter::ToUInt32(unsigned int8[], int32)
        stloc recordLength
        ldloc recordLength
        ldc.i4.8
        blt.un parseMalformed
        ldloc recordLength
        ldc.i4.7
        and
        brtrue parseMalformed
        ldloc recordLength
        ldloc remaining
        bgt.un parseMalformed
        ldarg.0
        ldloc position
        ldc.i4.4
        add
        call unsigned int16 [mscorlib]System.BitConverter::ToUInt16(unsigned int8[], int32)
        ldc.i4.2
        bne.un parseUnsupported
        ldarg.0
        ldloc position
        ldc.i4.6
        add
        call unsigned int16 [mscorlib]System.BitConverter::ToUInt16(unsigned int8[], int32)
        brtrue parseUnsupported
        ldloc recordLength
        ldc.i4.s 60
        blt.un parseMalformed

        // Only validate the UTF-16 extent. Journal filename bytes are never read or decoded.
        ldarg.0
        ldloc position
        ldc.i4.s 56
        add
        call unsigned int16 [mscorlib]System.BitConverter::ToUInt16(unsigned int8[], int32)
        stloc nameLength
        ldarg.0
        ldloc position
        ldc.i4.s 58
        add
        call unsigned int16 [mscorlib]System.BitConverter::ToUInt16(unsigned int8[], int32)
        stloc nameOffset
        ldloc nameLength
        ldc.i4.1
        and
        brtrue parseMalformed
        ldloc nameOffset
        ldc.i4.1
        and
        brtrue parseMalformed
        ldloc nameOffset
        ldc.i4.s 60
        blt parseMalformed
        ldloc nameOffset
        ldloc recordLength
        bgt.un parseMalformed
        ldloc nameLength
        ldloc recordLength
        ldloc nameOffset
        sub
        bgt.un parseMalformed
        ldarg.0
        ldloc position
        ldc.i4.s 24
        add
        call int64 [mscorlib]System.BitConverter::ToInt64(unsigned int8[], int32)
        stloc recordUsn
        ldloc recordUsn
        ldc.i4.0
        conv.i8
        blt parseMalformed
        ldloc recordUsn
        ldloc previousUsn
        ble parseMalformed
        ldloc recordUsn
        ldloc continuation
        bge parseMalformed
        ldloc recordUsn
        stloc previousUsn
        ldloc recordUsn
        ldarg.2
        blt parseAdvance
        ldloc recordUsn
        ldarg.3
        bge parseAdvance
        newobj instance void FolderMap.UsnChange::.ctor()
        stloc change
        ldloc change
        ldarg.0
        ldloc position
        ldc.i4.8
        add
        call unsigned int64 [mscorlib]System.BitConverter::ToUInt64(unsigned int8[], int32)
        stfld unsigned int64 FolderMap.UsnChange::FileId
        ldloc change
        ldarg.0
        ldloc position
        ldc.i4.s 16
        add
        call unsigned int64 [mscorlib]System.BitConverter::ToUInt64(unsigned int8[], int32)
        stfld unsigned int64 FolderMap.UsnChange::ParentId
        ldloc change
        ldarg.0
        ldloc position
        ldc.i4.s 40
        add
        call unsigned int32 [mscorlib]System.BitConverter::ToUInt32(unsigned int8[], int32)
        stfld unsigned int32 FolderMap.UsnChange::Reason
        ldloc change
        ldarg.0
        ldloc position
        ldc.i4.s 52
        add
        call unsigned int32 [mscorlib]System.BitConverter::ToUInt32(unsigned int8[], int32)
        stfld unsigned int32 FolderMap.UsnChange::Attributes
        ldloc change
        ldloc recordUsn
        stfld int64 FolderMap.UsnChange::Usn
        ldarg.s receiver
        ldloc change
        callvirt instance void class [mscorlib]System.Action`1<class FolderMap.UsnChange>::Invoke(!0)
        ldarg.s recordCount
        dup
        ldind.i8
        ldc.i4.1
        conv.i8
        add.ovf
        stind.i8
    parseAdvance:
        ldloc position
        ldloc recordLength
        conv.i4
        add.ovf
        stloc position
        br parseLoop
    parseUnsupported:
        ldstr "Unsupported USN record version: only USN_RECORD_V2 version 2.0 is supported; a full scan is required."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    parseMalformed:
        ldstr "Malformed USN read buffer: invalid length, alignment, numeric ordering, continuation, or filename extent."
        newobj instance void [System]System.IO.InvalidDataException::.ctor(string)
        throw
    parseDone:
        ldloc continuation
        ret
    }
}

.class public sealed auto ansi beforefieldinit FolderMap.JournalSession extends [mscorlib]System.Object implements [mscorlib]System.IDisposable
{
    .field public string VolumeName
    .field public string RootPath
    .field public unsigned int64 RootFileId
    .field public unsigned int32 VolumeSerial
    .field private class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle _handle

    .method assembly hidebysig specialname rtspecialname instance void .ctor(
        class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle handle,
        string volumeName,
        string rootPath,
        unsigned int64 rootFileId,
        unsigned int32 volumeSerial) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.JournalSession::_handle
        ldarg.0
        ldarg.2
        stfld string FolderMap.JournalSession::VolumeName
        ldarg.0
        ldarg.3
        stfld string FolderMap.JournalSession::RootPath
        ldarg.0
        ldarg.s rootFileId
        stfld unsigned int64 FolderMap.JournalSession::RootFileId
        ldarg.0
        ldarg.s volumeSerial
        stfld unsigned int32 FolderMap.JournalSession::VolumeSerial
        ret
    }

    .method public hidebysig newslot virtual final instance void Dispose() cil managed
    {
        .maxstack 2
        .locals init (class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle nativeHandle)
        ldarg.0
        ldflda class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.JournalSession::_handle
        ldnull
        call !!0 [mscorlib]System.Threading.Interlocked::Exchange<class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle>(!!0&, !!0)
        stloc nativeHandle
        ldloc nativeHandle
        brfalse disposeDone
        ldloc nativeHandle
        callvirt instance void [mscorlib]System.Runtime.InteropServices.SafeHandle::Dispose()
    disposeDone:
        ret
    }

    .method private hidebysig instance class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle GetHandle() cil managed
    {
        .maxstack 1
        .locals init (class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle nativeHandle)
        ldarg.0
        ldfld class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.JournalSession::_handle
        stloc nativeHandle
        ldloc nativeHandle
        brfalse handleDisposed
        ldloc nativeHandle
        callvirt instance bool [mscorlib]System.Runtime.InteropServices.SafeHandle::get_IsClosed()
        brtrue handleDisposed
        ldloc nativeHandle
        ret
    handleDisposed:
        ldstr "FolderMap.JournalSession"
        newobj instance void [mscorlib]System.ObjectDisposedException::.ctor(string)
        throw
    }

    .method public hidebysig instance class FolderMap.UsnCheckpoint Query() cil managed
    {
        .maxstack 8
        .locals init (
            unsigned int8[] outputBuffer,
            unsigned int32 returned,
            class FolderMap.UsnCheckpoint result)
        ldc.i4 128
        newarr [mscorlib]System.Byte
        stloc outputBuffer
        ldarg.0
        call instance class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.JournalSession::GetHandle()
        ldc.i4 0x000900f4
        ldnull
        ldc.i4.0
        ldloc outputBuffer
        ldloc outputBuffer
        ldlen
        conv.u4
        ldloca returned
        ldc.i4.0
        conv.i
        call int32 FolderMap.NtfsJournal::DeviceIoControl(class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle, unsigned int32, unsigned int8[], unsigned int32, unsigned int8[], unsigned int32, unsigned int32&, native int)
        brtrue queryLength
        ldstr "FSCTL_QUERY_USN_JOURNAL failed; the journal may be unavailable or volume access may be denied."
        call void FolderMap.NtfsJournal::ThrowLastWin32(string)
    queryLength:
        ldloc returned
        ldc.i4.s 56
        blt.un queryMalformed
        ldloc returned
        ldloc outputBuffer
        ldlen
        conv.u4
        bgt.un queryMalformed
        newobj instance void FolderMap.UsnCheckpoint::.ctor()
        stloc result
        ldloc result
        ldloc outputBuffer
        ldc.i4.0
        call unsigned int64 [mscorlib]System.BitConverter::ToUInt64(unsigned int8[], int32)
        stfld unsigned int64 FolderMap.UsnCheckpoint::JournalId
        ldloc result
        ldloc outputBuffer
        ldc.i4.8
        call int64 [mscorlib]System.BitConverter::ToInt64(unsigned int8[], int32)
        stfld int64 FolderMap.UsnCheckpoint::FirstUsn
        ldloc result
        ldloc outputBuffer
        ldc.i4.s 16
        call int64 [mscorlib]System.BitConverter::ToInt64(unsigned int8[], int32)
        stfld int64 FolderMap.UsnCheckpoint::NextUsn
        ldloc result
        ldloc outputBuffer
        ldc.i4.s 24
        call int64 [mscorlib]System.BitConverter::ToInt64(unsigned int8[], int32)
        stfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        ldc.i4.0
        conv.i8
        blt queryMalformed
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        ldc.i4.0
        conv.i8
        blt queryMalformed
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        blt queryMalformed
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        ldloc result
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        blt queryMalformed
        ldloc result
        ret
    queryMalformed:
        ldstr "FSCTL_QUERY_USN_JOURNAL returned an incomplete or inconsistent USN_JOURNAL_DATA structure."
        newobj instance void [System]System.IO.InvalidDataException::.ctor(string)
        throw
    }

    .method private hidebysig static void ValidateRange(
        class FolderMap.UsnCheckpoint checkpoint,
        int64 startUsn,
        unsigned int64 journalId,
        int64 stopUsn) cil managed
    {
        .maxstack 2
        ldarg.0
        ldfld unsigned int64 FolderMap.UsnCheckpoint::JournalId
        ldarg.2
        bne.un rangeLost
        ldarg.1
        ldarg.0
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        blt rangeLost
        ldarg.1
        ldarg.0
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        blt rangeLost
        ldarg.1
        ldarg.3
        bgt rangeLost
        ldarg.3
        ldarg.0
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        bgt rangeLost
        ret
    rangeLost:
        ldstr "USN journal continuity is unavailable for the requested finite range (ID, retention, or end boundary changed); a full scan is required."
        newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
        throw
    }

    .method public hidebysig instance int64 ReadChanges(
        int64 startUsn,
        unsigned int64 journalId,
        int64 stopUsn,
        class [mscorlib]System.Action`1<class FolderMap.UsnChange> receiver,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 8
        .locals init (
            class FolderMap.UsnCheckpoint initialCheckpoint,
            class FolderMap.UsnCheckpoint finalCheckpoint,
            unsigned int8[] inputBuffer,
            unsigned int8[] outputBuffer,
            unsigned int32 returned,
            int64 position,
            int64 continuation,
            int64 count,
            int64 bufferCount)

        ldarg.s receiver
        brtrue readStartArgument
        ldstr "receiver"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    readStartArgument:
        ldarg.1
        ldc.i4.0
        conv.i8
        bge readStopArgument
        ldstr "startUsn"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    readStopArgument:
        ldarg.3
        ldarg.1
        bge readInitialQuery
        ldstr "stopUsn"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    readInitialQuery:
        ldarg.s worker
        call void FolderMap.NtfsJournal::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        call instance class FolderMap.UsnCheckpoint FolderMap.JournalSession::Query()
        stloc initialCheckpoint
        ldloc initialCheckpoint
        ldarg.1
        ldarg.2
        ldarg.3
        call void FolderMap.JournalSession::ValidateRange(class FolderMap.UsnCheckpoint, int64, unsigned int64, int64)
        ldarg.1
        stloc position

        // The V0 request is exactly 40 bytes. Its zeroed timeout and wait threshold never wait for future writes.
        ldc.i4.s 40
        newarr [mscorlib]System.Byte
        stloc inputBuffer
        ldloc inputBuffer
        ldc.i4.8
        ldc.i4.m1
        call void FolderMap.NtfsJournal::WriteInt32(unsigned int8[], int32, int32)
        ldloc inputBuffer
        ldc.i4.s 32
        ldarg.2
        conv.i8
        call void FolderMap.NtfsJournal::WriteInt64(unsigned int8[], int32, int64)
        ldc.i4 65536
        newarr [mscorlib]System.Byte
        stloc outputBuffer
    readLoop:
        ldarg.s worker
        call void FolderMap.NtfsJournal::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc position
        ldarg.3
        bge readFinalQuery
        ldloc inputBuffer
        ldc.i4.0
        ldloc position
        call void FolderMap.NtfsJournal::WriteInt64(unsigned int8[], int32, int64)
        ldarg.0
        call instance class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle FolderMap.JournalSession::GetHandle()
        ldc.i4 0x000900bb
        ldloc inputBuffer
        ldc.i4.s 40
        ldloc outputBuffer
        ldc.i4 65536
        ldloca returned
        ldc.i4.0
        conv.i
        call int32 FolderMap.NtfsJournal::DeviceIoControl(class [mscorlib]Microsoft.Win32.SafeHandles.SafeFileHandle, unsigned int32, unsigned int8[], unsigned int32, unsigned int8[], unsigned int32, unsigned int32&, native int)
        brtrue readParse
        ldstr "FSCTL_READ_USN_JOURNAL failed; journal access, retention, or continuity was lost."
        call void FolderMap.NtfsJournal::ThrowLastWin32(string)
    readParse:
        ldloc outputBuffer
        ldloc returned
        conv.i4
        ldloc position
        ldarg.3
        ldarg.s receiver
        ldarg.s worker
        ldloca bufferCount
        call int64 FolderMap.NtfsJournal::ParseBufferCore(unsigned int8[], int32, int64, int64, class [mscorlib]System.Action`1<class FolderMap.UsnChange>, class [System]System.ComponentModel.BackgroundWorker, int64&)
        stloc continuation
        ldloc continuation
        ldloc position
        bgt readProgress
        ldstr "The USN journal read made no forward progress before the requested stop; a full scan is required."
        newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
        throw
    readProgress:
        ldloc count
        ldloc bufferCount
        add.ovf
        stloc count
        ldloc continuation
        ldarg.3
        ble readUseContinuation
        ldarg.3
        stloc position
        br readLoop
    readUseContinuation:
        ldloc continuation
        stloc position
        br readLoop
    readFinalQuery:
        ldarg.0
        call instance class FolderMap.UsnCheckpoint FolderMap.JournalSession::Query()
        stloc finalCheckpoint
        ldarg.s worker
        call void FolderMap.NtfsJournal::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc finalCheckpoint
        ldarg.1
        ldarg.2
        ldarg.3
        call void FolderMap.JournalSession::ValidateRange(class FolderMap.UsnCheckpoint, int64, unsigned int64, int64)
        // Even retention movement below start is conservatively treated as a wrap, not a successful incremental update.
        ldloc finalCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        ldloc initialCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        bne.un readContinuityLost
        ldloc finalCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        ldloc initialCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        bne.un readContinuityLost
        ldloc finalCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        ldloc initialCheckpoint
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        blt readContinuityLost
        ldloc count
        ret
    readContinuityLost:
        ldstr "USN journal retention or continuity changed during the read; a full scan is required."
        newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
        throw
    }
}
