// FMCACHE\0, UInt32 version (1), three Int32-byte-length UTF-8 strings,
// UInt32 volume serial, UInt64 root/journal IDs, Int64 checkpoint/UTC ticks,
// Int32 directory/pending counts, directory records, pending UInt64 pairs,
// then SHA-256 of every preceding byte. All integers are little-endian.
// A directory is parent:Int32, name:string, id:UInt64, bytes/files:Int64,
// direct issues:Int32, flags:Byte (retry=1, reparse=2), issue strings and
// linked UInt64 IDs, each list preceded by its Int32 count.
// Limits: 512 MiB including checksum; 1000000 directories, pending pairs,
// and cumulative linked references; 200 issue strings per directory;
// 131072 UTF-8 bytes/string; 255 UTF-16 units/component; 32767 units/path.
.class public abstract auto ansi sealed beforefieldinit FolderMap.CacheStore
    extends [mscorlib]System.Object
{
    .field private static initonly class [mscorlib]System.Text.UTF8Encoding Utf8
    .field private static initonly char[] InvalidNameChars
    .field private static initonly char[] InvalidPathChars

    .method private hidebysig specialname rtspecialname static void .cctor() cil managed
    {
        .maxstack 2
        ldc.i4.0
        ldc.i4.1
        newobj instance void [mscorlib]System.Text.UTF8Encoding::.ctor(bool, bool)
        stsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
        call char[] [mscorlib]System.IO.Path::GetInvalidFileNameChars()
        stsfld char[] FolderMap.CacheStore::InvalidNameChars
        call char[] [mscorlib]System.IO.Path::GetInvalidPathChars()
        stsfld char[] FolderMap.CacheStore::InvalidPathChars
        ret
    }

    .method private hidebysig static void Require(bool condition, string message) cil managed
    {
        .maxstack 1
        ldarg.0
        brtrue REQUIRE_OK
        ldarg.1
        newobj instance void [System]System.IO.InvalidDataException::.ctor(string)
        throw
    REQUIRE_OK:
        ret
    }

    .method private hidebysig static void Argument(string 'value', string name) cil managed
    {
        .maxstack 2
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        brfalse ARGUMENT_OK
        ldstr "A nonblank path or access context is required."
        ldarg.1
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    ARGUMENT_OK:
        ret
    }

    .method private hidebysig static void Cancel(class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 1
        ldarg.0
        brfalse CANCEL_OK
        ldarg.0
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_CancellationPending()
        brfalse CANCEL_OK
        ldstr "The cache operation was cancelled."
        newobj instance void [mscorlib]System.OperationCanceledException::.ctor(string)
        throw
    CANCEL_OK:
        ret
    }

    .method private hidebysig static int32 TextBytes(string 'value') cil managed
    {
        .maxstack 3
        .locals init (int32 size, class [mscorlib]System.Text.EncoderFallbackException failure)
        ldarg.0
        ldnull
        cgt.un
        ldstr "Cache strings cannot be null."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4 131072
        cgt
        ldc.i4.0
        ceq
        ldstr "A cache string exceeds the 131072-byte UTF-8 limit."
        call void FolderMap.CacheStore::Require(bool, string)
        .try
        {
            ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
            ldarg.0
            callvirt instance int32 [mscorlib]System.Text.Encoding::GetByteCount(string)
            stloc.0
            leave TEXT_ENCODED
        }
        catch [mscorlib]System.Text.EncoderFallbackException
        {
            stloc.1
            ldstr "A cache string contains invalid Unicode."
            ldloc.1
            newobj instance void [System]System.IO.InvalidDataException::.ctor(string, class [mscorlib]System.Exception)
            throw
        }
    TEXT_ENCODED:
        ldloc.0
        ldc.i4 131072
        cgt
        ldc.i4.0
        ceq
        ldstr "A cache string exceeds the 131072-byte UTF-8 limit."
        call void FolderMap.CacheStore::Require(bool, string)
        ldloc.0
        ret
    }

    .method private hidebysig static bool DriveRoot(string 'value', int32 start) cil managed
    {
        .maxstack 3
        .locals init (int32 letter)
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldarg.1
        ldc.i4.3
        add
        blt DRIVE_NO
        ldarg.0
        ldarg.1
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc.0
        ldloc.0
        ldc.i4.s 65
        blt DRIVE_LOWER
        ldloc.0
        ldc.i4.s 90
        ble DRIVE_LETTER
    DRIVE_LOWER:
        ldloc.0
        ldc.i4.s 97
        blt DRIVE_NO
        ldloc.0
        ldc.i4.s 122
        bgt DRIVE_NO
    DRIVE_LETTER:
        ldarg.0
        ldarg.1
        ldc.i4.1
        add
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 58
        bne.un DRIVE_NO
        ldarg.0
        ldarg.1
        ldc.i4.2
        add
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        dup
        ldc.i4.s 92
        beq DRIVE_SEPARATOR
        ldc.i4.s 47
        ceq
        ret
    DRIVE_SEPARATOR:
        pop
        ldc.i4.1
        ret
    DRIVE_NO:
        ldc.i4.0
        ret
    }

    .method private hidebysig static bool UncRoot(string 'value', int32 start) cil managed
    {
        .maxstack 5
        .locals init (int32 separator, int32 shareEnd, string component)
        ldarg.0
        ldc.i4.s 92
        ldarg.1
        callvirt instance int32 [mscorlib]System.String::IndexOf(char, int32)
        stloc.0
        ldloc.0
        ldarg.1
        ble UNC_NO
        ldloc.0
        ldc.i4.1
        add
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        bge UNC_NO
        ldarg.0
        ldarg.1
        ldloc.0
        ldarg.1
        sub
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc.2
        ldloc.2
        ldstr "."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue UNC_NO
        ldloc.2
        ldstr ".."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue UNC_NO
        ldarg.0
        ldc.i4.s 92
        ldloc.0
        ldc.i4.1
        add
        callvirt instance int32 [mscorlib]System.String::IndexOf(char, int32)
        stloc.1
        ldloc.1
        ldc.i4.0
        bge UNC_SHARE_END
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc.1
    UNC_SHARE_END:
        ldloc.1
        ldloc.0
        ldc.i4.1
        add
        ble UNC_NO
        ldarg.0
        ldloc.0
        ldc.i4.1
        add
        ldloc.1
        ldloc.0
        sub
        ldc.i4.1
        sub
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc.2
        ldloc.2
        ldstr "."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue UNC_NO
        ldloc.2
        ldstr ".."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue UNC_NO
        ldc.i4.1
        ret
    UNC_NO:
        ldc.i4.0
        ret
    }

    .method private hidebysig static bool AbsoluteRoot(string 'value') cil managed
    {
        .maxstack 3
        .locals init (valuetype [mscorlib]System.Guid volumeGuid)
        ldarg.0
        ldc.i4.0
        call bool FolderMap.CacheStore::DriveRoot(string, int32)
        brtrue ROOT_YES
        ldarg.0
        ldstr "\\\\?\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse ROOT_NORMAL_UNC
        ldarg.0
        ldc.i4.4
        call bool FolderMap.CacheStore::DriveRoot(string, int32)
        brtrue ROOT_YES
        ldarg.0
        ldstr "\\\\?\\UNC\\"
        ldc.i4.5
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse ROOT_VOLUME
        ldarg.0
        ldc.i4.8
        call bool FolderMap.CacheStore::UncRoot(string, int32)
        ret
    ROOT_VOLUME:
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.s 49
        blt ROOT_NO
        ldarg.0
        ldstr "\\\\?\\Volume{"
        ldc.i4.5
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse ROOT_NO
        ldarg.0
        ldc.i4.s 48
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 92
        bne.un ROOT_NO
        ldarg.0
        ldc.i4.s 10
        ldc.i4.s 38
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        ldloca.s volumeGuid
        call bool [mscorlib]System.Guid::TryParse(string, valuetype [mscorlib]System.Guid&)
        ret
    ROOT_NORMAL_UNC:
        ldarg.0
        ldstr "\\\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse ROOT_NO
        ldarg.0
        ldc.i4.2
        call bool FolderMap.CacheStore::UncRoot(string, int32)
        ret
    ROOT_YES:
        ldc.i4.1
        ret
    ROOT_NO:
        ldc.i4.0
        ret
    }

    .method private hidebysig static void CheckRoot(string 'value') cil managed
    {
        .maxstack 3
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        ldc.i4.0
        ceq
        ldstr "Cache RootPath must be nonblank."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4 32767
        cgt
        ldc.i4.0
        ceq
        ldstr "Cache RootPath exceeds the 32767-character Windows path limit."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldsfld char[] FolderMap.CacheStore::InvalidPathChars
        callvirt instance int32 [mscorlib]System.String::IndexOfAny(char[])
        ldc.i4.0
        clt
        ldstr "Cache RootPath contains invalid Windows path characters."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        call bool FolderMap.CacheStore::AbsoluteRoot(string)
        ldstr "Cache RootPath must be an absolute Windows drive, UNC, or volume path."
        call void FolderMap.CacheStore::Require(bool, string)
        ret
    }

    .method private hidebysig static bool DeviceName(string 'value') cil managed
    {
        .maxstack 3
        .locals init (int32 dot, string stem, int32 digit)
        ldarg.0
        ldc.i4.s 46
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        stloc.0
        ldarg.0
        stloc.1
        ldloc.0
        ldc.i4.0
        blt DEVICE_STEM
        ldarg.0
        ldc.i4.0
        ldloc.0
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc.1
    DEVICE_STEM:
        ldloc.1
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc.0
        br DEVICE_TRIM_TEST
    DEVICE_TRIM:
        ldloc.1
        ldloc.0
        ldc.i4.1
        sub
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 32
        bne.un DEVICE_TRIM_DONE
        ldloc.0
        ldc.i4.1
        sub
        stloc.0
    DEVICE_TRIM_TEST:
        ldloc.0
        ldc.i4.0
        bgt DEVICE_TRIM
    DEVICE_TRIM_DONE:
        ldloc.1
        ldc.i4.0
        ldloc.0
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc.1
        ldloc.1
        callvirt instance string [mscorlib]System.String::ToUpperInvariant()
        stloc.1
        ldloc.1
        ldstr "CON"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        ldstr "PRN"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        ldstr "AUX"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        ldstr "NUL"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        ldstr "CONIN$"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        ldstr "CONOUT$"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue DEVICE_YES
        ldloc.1
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.4
        bne.un DEVICE_NO
        ldloc.1
        ldstr "COM"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brtrue DEVICE_DIGIT
        ldloc.1
        ldstr "LPT"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse DEVICE_NO
    DEVICE_DIGIT:
        ldloc.1
        ldc.i4.3
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc.2
        ldloc.2
        ldc.i4.s 49
        blt DEVICE_SUPERSCRIPT
        ldloc.2
        ldc.i4.s 57
        ble DEVICE_YES
    DEVICE_SUPERSCRIPT:
        ldloc.2
        ldc.i4 185
        beq DEVICE_YES
        ldloc.2
        ldc.i4 178
        beq DEVICE_YES
        ldloc.2
        ldc.i4 179
        beq DEVICE_YES
    DEVICE_NO:
        ldc.i4.0
        ret
    DEVICE_YES:
        ldc.i4.1
        ret
    }

    .method private hidebysig static void CheckName(string 'value') cil managed
    {
        .maxstack 3
        .locals init (int32 length, int32 last)
        ldarg.0
        call int32 FolderMap.CacheStore::TextBytes(string)
        pop
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc.0
        ldloc.0
        ldc.i4.0
        cgt
        ldstr "A non-root directory name cannot be empty."
        call void FolderMap.CacheStore::Require(bool, string)
        ldloc.0
        ldc.i4 255
        cgt
        ldc.i4.0
        ceq
        ldstr "A directory name exceeds the 255-character Windows component limit."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldsfld char[] FolderMap.CacheStore::InvalidNameChars
        callvirt instance int32 [mscorlib]System.String::IndexOfAny(char[])
        ldc.i4.0
        clt
        ldstr "A directory name contains a separator or invalid Windows filename character."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldloc.0
        ldc.i4.1
        sub
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc.1
        ldloc.1
        ldc.i4.s 46
        ceq
        ldloc.1
        ldc.i4.s 32
        ceq
        or
        ldc.i4.0
        ceq
        ldstr "Directory names cannot be dot traversal components or end in a dot or space."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        call bool FolderMap.CacheStore::DeviceName(string)
        ldc.i4.0
        ceq
        ldstr "A directory name is a reserved Windows device name."
        call void FolderMap.CacheStore::Require(bool, string)
        ret
    }

    .method private hidebysig static int64 SizeLimit(int64 size) cil managed
    {
        .maxstack 3
        ldarg.0
        ldc.i8 536870912
        cgt
        ldc.i4.0
        ceq
        ldstr "The cache exceeds the 512 MiB file limit."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ret
    }

    .method private hidebysig static int64 MetadataSize(class FolderMap.CacheSnapshot snapshot) cil managed
    {
        .maxstack 4
        .locals init (int64 size)
        ldarg.0
        brtrue METADATA_NOT_NULL
        ldstr "snapshot"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    METADATA_NOT_NULL:
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        call void FolderMap.CacheStore::CheckRoot(string)
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::VolumeName
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        ldc.i4.0
        ceq
        ldstr "Cache VolumeName must be nonblank."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::AccessContext
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        ldc.i4.0
        ceq
        ldstr "Cache AccessContext must be nonblank."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldfld uint64 FolderMap.CacheSnapshot::RootFileId
        ldc.i4.0
        conv.i8
        cgt.un
        ldstr "Cache RootFileId must be nonzero."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        ldc.i4.0
        conv.i8
        clt
        ldc.i4.0
        ceq
        ldstr "The cache journal checkpoint cannot be negative."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
        ldc.i4.0
        conv.i8
        cgt
        ldstr "Cache SavedUtcTicks must be a positive DateTime tick count."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
        ldc.i8 3155378975999999999
        cgt
        ldc.i4.0
        ceq
        ldstr "Cache SavedUtcTicks exceeds DateTime.MaxValue."
        call void FolderMap.CacheStore::Require(bool, string)
        ldc.i8 100
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        call int32 FolderMap.CacheStore::TextBytes(string)
        conv.i8
        add.ovf
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::VolumeName
        call int32 FolderMap.CacheStore::TextBytes(string)
        conv.i8
        add.ovf
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::AccessContext
        call int32 FolderMap.CacheStore::TextBytes(string)
        conv.i8
        add.ovf
        stloc.0
        ldloc.0
        ret
    }

    .method private hidebysig static void Validate(
        class FolderMap.CacheSnapshot snapshot,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 6
        .locals init (
            int64 size,
            int64 totalBytes,
            int64 totalFiles,
            int64 totalIssues,
            int64 totalLinked,
            int32 directoryCount,
            int32 i,
            int32 j,
            int32 parent,
            int32 pathLength,
            int32[] pathLengths,
            class FolderMap.CacheDirectory directory,
            class FolderMap.PendingWrite pending,
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> identities,
            class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool> names,
            class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool> pairs,
            string key,
            class [mscorlib]System.OverflowException failure)
        .try
        {
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldarg.0
            call int64 FolderMap.CacheStore::MetadataSize(class FolderMap.CacheSnapshot)
            stloc size
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
            ldnull
            cgt.un
            ldstr "Cache Directories cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
            ldnull
            cgt.un
            ldstr "Cache PendingWrites cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
            stloc directoryCount
            ldloc directoryCount
            ldc.i4.0
            cgt
            ldstr "A cache must contain exactly one root directory."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directoryCount
            ldc.i4 1000000
            cgt
            ldc.i4.0
            ceq
            ldstr "The cache exceeds the 1000000-directory limit."
            call void FolderMap.CacheStore::Require(bool, string)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
            ldc.i4 1000000
            cgt
            ldc.i4.0
            ceq
            ldstr "The cache exceeds the 1000000-pending-pair limit."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directoryCount
            newarr [mscorlib]System.Int32
            stloc pathLengths
            newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor()
            stloc identities
            call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
            newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
            stloc names
            call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
            newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
            stloc pairs
            ldc.i4.0
            stloc i
            br VALIDATE_DIRECTORY_TEST
        VALIDATE_DIRECTORY:
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
            ldloc i
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
            stloc directory
            ldloc directory
            ldnull
            cgt.un
            ldstr "Cache directory records cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld int32 FolderMap.CacheDirectory::ParentIndex
            stloc parent
            ldloc i
            brtrue VALIDATE_CHILD
            ldloc parent
            ldc.i4.m1
            ceq
            ldstr "The first cache directory must be the only root (ParentIndex=-1)."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld uint64 FolderMap.CacheDirectory::FileId
            ldarg.0
            ldfld uint64 FolderMap.CacheSnapshot::RootFileId
            ceq
            ldstr "The root directory identity does not match RootFileId."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc pathLengths
            ldc.i4.0
            ldarg.0
            ldfld string FolderMap.CacheSnapshot::RootPath
            callvirt instance int32 [mscorlib]System.String::get_Length()
            stelem.i4
            br VALIDATE_DIRECTORY_ID
        VALIDATE_CHILD:
            ldloc parent
            ldc.i4.0
            clt
            ldc.i4.0
            ceq
            ldloc parent
            ldloc i
            clt
            and
            ldstr "Directory parents must precede their children; cycles and multiple roots are invalid."
            call void FolderMap.CacheStore::Require(bool, string)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
            ldloc parent
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
            ldfld bool FolderMap.CacheDirectory::Reparse
            ldc.i4.0
            ceq
            ldstr "A reparse directory cannot have children."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld string FolderMap.CacheDirectory::Name
            call void FolderMap.CacheStore::CheckName(string)
            ldloc pathLengths
            ldloc parent
            ldelem.i4
            stloc pathLength
            ldloc parent
            brtrue VALIDATE_SEPARATOR
            ldarg.0
            ldfld string FolderMap.CacheSnapshot::RootPath
            ldloc pathLength
            ldc.i4.1
            sub
            callvirt instance char [mscorlib]System.String::get_Chars(int32)
            dup
            ldc.i4.s 92
            beq VALIDATE_NO_SEPARATOR
            ldc.i4.s 47
            beq VALIDATE_PATH_LENGTH
        VALIDATE_SEPARATOR:
            ldloc pathLength
            ldc.i4.1
            add.ovf
            stloc pathLength
            br VALIDATE_PATH_LENGTH
        VALIDATE_NO_SEPARATOR:
            pop
        VALIDATE_PATH_LENGTH:
            ldloc pathLength
            ldloc directory
            ldfld string FolderMap.CacheDirectory::Name
            callvirt instance int32 [mscorlib]System.String::get_Length()
            add.ovf
            stloc pathLength
            ldloc pathLength
            ldc.i4 32767
            cgt
            ldc.i4.0
            ceq
            ldstr "A cumulative cache directory path exceeds 32767 characters."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc pathLengths
            ldloc i
            ldloc pathLength
            stelem.i4
            ldloca parent
            call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
            call instance string [mscorlib]System.Int32::ToString(class [mscorlib]System.IFormatProvider)
            ldstr "\n"
            ldloc directory
            ldfld string FolderMap.CacheDirectory::Name
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc key
            ldloc names
            ldloc key
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::ContainsKey(!0)
            ldc.i4.0
            ceq
            ldstr "The cache contains duplicate child names under the same parent (Ordinal comparison)."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc names
            ldloc key
            ldc.i4.1
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::Add(!0, !1)
        VALIDATE_DIRECTORY_ID:
            ldloc directory
            ldfld uint64 FolderMap.CacheDirectory::FileId
            ldc.i4.0
            conv.i8
            cgt.un
            ldloc directory
            ldfld bool FolderMap.CacheDirectory::Retry
            or
            ldloc directory
            ldfld bool FolderMap.CacheDirectory::Reparse
            or
            ldstr "A zero directory identity requires Retry or Reparse."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld uint64 FolderMap.CacheDirectory::FileId
            brfalse VALIDATE_STATS
            ldloc directory
            ldfld bool FolderMap.CacheDirectory::Reparse
            brtrue VALIDATE_STATS
            ldloc identities
            ldloc directory
            ldfld uint64 FolderMap.CacheDirectory::FileId
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
            ldc.i4.0
            ceq
            ldstr "The cache contains duplicate non-reparse directory identities."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc identities
            ldloc directory
            ldfld uint64 FolderMap.CacheDirectory::FileId
            ldc.i4.1
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::Add(!0, !1)
        VALIDATE_STATS:
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectBytes
            ldc.i4.0
            conv.i8
            clt
            ldc.i4.0
            ceq
            ldstr "Direct byte counts cannot be negative."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectFiles
            ldc.i4.0
            conv.i8
            clt
            ldc.i4.0
            ceq
            ldstr "Direct file counts cannot be negative."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
            ldc.i4.0
            clt
            ldc.i4.0
            ceq
            ldstr "Direct issue counts cannot be negative."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc totalBytes
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectBytes
            add.ovf
            stloc totalBytes
            ldloc totalFiles
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectFiles
            add.ovf
            stloc totalFiles
            ldloc totalIssues
            ldloc directory
            ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
            conv.i8
            add.ovf
            stloc totalIssues
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
            ldnull
            cgt.un
            ldstr "Cache Issues lists cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            ldnull
            cgt.un
            ldstr "Cache LinkedFiles lists cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
            ldc.i4 200
            cgt
            ldc.i4.0
            ceq
            ldstr "A directory exceeds the 200-diagnostic-string limit."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
            ldloc directory
            ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
            cgt
            ldc.i4.0
            ceq
            ldstr "Stored diagnostics cannot exceed DirectIssueCount."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc totalLinked
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
            conv.i8
            add.ovf
            stloc totalLinked
            ldloc totalLinked
            ldc.i8 1000000
            cgt
            ldc.i4.0
            ceq
            ldstr "The cache exceeds the 1000000-total-linked-file-reference limit."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc directory
            ldfld bool FolderMap.CacheDirectory::Reparse
            brfalse VALIDATE_SIZE
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectBytes
            ldc.i4.0
            conv.i8
            ceq
            ldloc directory
            ldfld int64 FolderMap.CacheDirectory::DirectFiles
            ldc.i4.0
            conv.i8
            ceq
            and
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
            ldc.i4.0
            ceq
            and
            ldstr "Reparse directories must have zero direct bytes/files and no linked files."
            call void FolderMap.CacheStore::Require(bool, string)
        VALIDATE_SIZE:
            ldloc size
            ldc.i8 45
            add.ovf
            ldloc directory
            ldfld string FolderMap.CacheDirectory::Name
            call int32 FolderMap.CacheStore::TextBytes(string)
            conv.i8
            add.ovf
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
            conv.i8
            ldc.i8 8
            mul.ovf
            add.ovf
            call int64 FolderMap.CacheStore::SizeLimit(int64)
            stloc size
            ldc.i4.0
            stloc j
            br VALIDATE_ISSUE_TEST
        VALIDATE_ISSUE:
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldloc size
            ldc.i8 4
            add.ovf
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
            ldloc j
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
            call int32 FolderMap.CacheStore::TextBytes(string)
            conv.i8
            add.ovf
            call int64 FolderMap.CacheStore::SizeLimit(int64)
            stloc size
            ldloc j
            ldc.i4.1
            add
            stloc j
        VALIDATE_ISSUE_TEST:
            ldloc j
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
            blt VALIDATE_ISSUE
            ldc.i4.0
            stloc j
            br VALIDATE_LINK_TEST
        VALIDATE_LINK:
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            ldloc j
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Item(int32)
            ldc.i4.0
            conv.i8
            cgt.un
            ldstr "Linked file identities must be nonzero."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc j
            ldc.i4.1
            add
            stloc j
        VALIDATE_LINK_TEST:
            ldloc j
            ldloc directory
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
            blt VALIDATE_LINK
            ldloc i
            ldc.i4.1
            add
            stloc i
        VALIDATE_DIRECTORY_TEST:
            ldloc i
            ldloc directoryCount
            blt VALIDATE_DIRECTORY
            ldloc size
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
            conv.i8
            ldc.i8 16
            mul.ovf
            add.ovf
            call int64 FolderMap.CacheStore::SizeLimit(int64)
            stloc size
            ldc.i4.0
            stloc i
            br VALIDATE_PENDING_TEST
        VALIDATE_PENDING:
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
            ldloc i
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Item(int32)
            stloc pending
            ldloc pending
            ldnull
            cgt.un
            ldstr "Pending write records cannot be null."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc pending
            ldfld uint64 FolderMap.PendingWrite::FileId
            ldc.i4.0
            conv.i8
            cgt.un
            ldloc pending
            ldfld uint64 FolderMap.PendingWrite::ParentId
            ldc.i4.0
            conv.i8
            cgt.un
            and
            ldstr "Pending file and parent identities must both be nonzero."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc pending
            ldflda uint64 FolderMap.PendingWrite::FileId
            ldstr "X16"
            call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
            call instance string [mscorlib]System.UInt64::ToString(string, class [mscorlib]System.IFormatProvider)
            ldstr ":"
            ldloc pending
            ldflda uint64 FolderMap.PendingWrite::ParentId
            ldstr "X16"
            call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
            call instance string [mscorlib]System.UInt64::ToString(string, class [mscorlib]System.IFormatProvider)
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc key
            ldloc pairs
            ldloc key
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::ContainsKey(!0)
            ldc.i4.0
            ceq
            ldstr "The cache contains duplicate pending file/parent pairs."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc pairs
            ldloc key
            ldc.i4.1
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::Add(!0, !1)
            ldloc i
            ldc.i4.1
            add
            stloc i
        VALIDATE_PENDING_TEST:
            ldloc i
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
            callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
            blt VALIDATE_PENDING
            ldarg.1
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            leave VALIDATE_DONE
        }
        catch [mscorlib]System.OverflowException
        {
            stloc failure
            ldstr "Cache aggregate totals or serialized lengths overflow Int64."
            ldloc failure
            newobj instance void [System]System.IO.InvalidDataException::.ctor(string, class [mscorlib]System.Exception)
            throw
        }
    VALIDATE_DONE:
        ret
    }

    .method public hidebysig static string DefaultDirectory() cil managed
    {
        .maxstack 3
        ldc.i4.s 28
        call string [mscorlib]System.Environment::GetFolderPath(valuetype [mscorlib]System.Environment/SpecialFolder)
        ldstr "FolderMap"
        ldstr "Cache"
        call string [mscorlib]System.IO.Path::Combine(string, string, string)
        ret
    }

    .method public hidebysig static string GetPath(string cacheDirectory, string rootPath, string accessContext) cil managed
    {
        .maxstack 6
        .locals init (
            class [mscorlib]System.Security.Cryptography.SHA256 digest,
            uint8[] hash,
            string directory,
            string filename)
        ldarg.0
        ldstr "cacheDirectory"
        call void FolderMap.CacheStore::Argument(string, string)
        ldarg.1
        ldstr "rootPath"
        call void FolderMap.CacheStore::Argument(string, string)
        ldarg.2
        ldstr "accessContext"
        call void FolderMap.CacheStore::Argument(string, string)
        ldarg.1
        call void FolderMap.CacheStore::CheckRoot(string)
        ldarg.1
        call int32 FolderMap.CacheStore::TextBytes(string)
        pop
        ldarg.2
        call int32 FolderMap.CacheStore::TextBytes(string)
        pop
        ldarg.0
        call string [mscorlib]System.IO.Path::GetFullPath(string)
        stloc directory
        .try
        {
            call class [mscorlib]System.Security.Cryptography.SHA256 [mscorlib]System.Security.Cryptography.SHA256::Create()
            stloc digest
            ldloc digest
            ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
            // Root paths cannot contain newlines, so the separator is unambiguous.
            ldstr "FolderMap.CacheKey.v1\n"
            ldarg.1
            ldstr "\n"
            ldarg.2
            call string [mscorlib]System.String::Concat(string, string, string, string)
            callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)
            callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::ComputeHash(uint8[])
            stloc hash
            leave KEY_HASHED
        }
        finally
        {
            ldloc digest
            brfalse KEY_DISPOSED
            ldloc digest
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        KEY_DISPOSED:
            endfinally
        }
    KEY_HASHED:
        ldloc hash
        call string [mscorlib]System.BitConverter::ToString(uint8[])
        ldstr "-"
        ldstr ""
        callvirt instance string [mscorlib]System.String::Replace(string, string)
        callvirt instance string [mscorlib]System.String::ToLowerInvariant()
        ldstr ".fmc"
        call string [mscorlib]System.String::Concat(string, string)
        stloc filename
        ldloc directory
        ldloc filename
        call string [mscorlib]System.IO.Path::Combine(string, string)
        ret
    }

    .method private hidebysig static void Ensure(
        class [mscorlib]System.IO.BinaryReader reader, int64 count, int64 payloadEnd) cil managed
    {
        .maxstack 4
        ldarg.1
        ldarg.2
        ldarg.0
        callvirt instance class [mscorlib]System.IO.Stream [mscorlib]System.IO.BinaryReader::get_BaseStream()
        callvirt instance int64 [mscorlib]System.IO.Stream::get_Position()
        sub
        cgt
        ldc.i4.0
        ceq
        ldstr "The cache is truncated or a declared length exceeds the remaining payload."
        call void FolderMap.CacheStore::Require(bool, string)
        ret
    }

    .method private hidebysig static int32 ReadCount(
        class [mscorlib]System.IO.BinaryReader reader,
        int32 maximum, int32 minimumBytes, int64 payloadEnd) cil managed
    {
        .maxstack 4
        .locals init (int32 count)
        ldarg.0
        ldc.i8 4
        ldarg.3
        call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
        ldarg.0
        callvirt instance int32 [mscorlib]System.IO.BinaryReader::ReadInt32()
        stloc.0
        ldloc.0
        ldc.i4.0
        clt
        ldc.i4.0
        ceq
        ldloc.0
        ldarg.1
        cgt
        ldc.i4.0
        ceq
        and
        ldstr "A cache string/list count is negative or exceeds its supported limit."
        call void FolderMap.CacheStore::Require(bool, string)
        ldarg.0
        ldloc.0
        conv.i8
        ldarg.2
        conv.i8
        mul.ovf
        ldarg.3
        call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
        ldloc.0
        ret
    }

    .method private hidebysig static string ReadText(
        class [mscorlib]System.IO.BinaryReader reader, int64 payloadEnd,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        .locals init (int32 count, uint8[] bytes)
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldc.i4 131072
        ldc.i4.1
        ldarg.1
        call int32 FolderMap.CacheStore::ReadCount(class [mscorlib]System.IO.BinaryReader, int32, int32, int64)
        stloc.0
        ldarg.0
        ldloc.0
        callvirt instance uint8[] [mscorlib]System.IO.BinaryReader::ReadBytes(int32)
        stloc.1
        ldloc.1
        ldlen
        conv.i4
        ldloc.0
        ceq
        ldstr "A cache UTF-8 string is truncated."
        call void FolderMap.CacheStore::Require(bool, string)
        ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
        ldloc.1
        callvirt instance string [mscorlib]System.Text.Encoding::GetString(uint8[])
        ret
    }

    .method private hidebysig static void WriteText(
        class [mscorlib]System.IO.BinaryWriter writer, string 'value',
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 3
        .locals init (uint8[] bytes)
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.1
        call int32 FolderMap.CacheStore::TextBytes(string)
        pop
        ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
        ldarg.1
        callvirt instance uint8[] [mscorlib]System.Text.Encoding::GetBytes(string)
        stloc.0
        ldarg.0
        ldloc.0
        ldlen
        conv.i4
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldarg.0
        ldloc.0
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint8[])
        ret
    }

    .method private hidebysig static uint8[] HashPrefix(
        class [mscorlib]System.IO.Stream ioStream, int64 count,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 6
        .locals init (
            class [mscorlib]System.Security.Cryptography.SHA256 digest,
            uint8[] buffer,
            uint8[] result,
            int32 read)
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        .try
        {
            call class [mscorlib]System.Security.Cryptography.SHA256 [mscorlib]System.Security.Cryptography.SHA256::Create()
            stloc.0
            ldc.i4 65536
            newarr [mscorlib]System.Byte
            stloc.1
            br HASH_TEST
        HASH_CHUNK:
            ldarg.2
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldarg.0
            ldloc.1
            ldc.i4.0
            ldarg.1
            ldc.i8 65536
            call int64 [mscorlib]System.Math::Min(int64, int64)
            conv.i4
            callvirt instance int32 [mscorlib]System.IO.Stream::Read(uint8[], int32, int32)
            stloc.3
            ldloc.3
            ldc.i4.0
            cgt
            ldstr "The cache is truncated while computing SHA-256."
            call void FolderMap.CacheStore::Require(bool, string)
            ldloc.0
            ldloc.1
            ldc.i4.0
            ldloc.3
            ldloc.1
            ldc.i4.0
            callvirt instance int32 [mscorlib]System.Security.Cryptography.HashAlgorithm::TransformBlock(uint8[], int32, int32, uint8[], int32)
            pop
            ldarg.1
            ldloc.3
            conv.i8
            sub
            starg.s count
        HASH_TEST:
            ldarg.1
            ldc.i4.0
            conv.i8
            bgt HASH_CHUNK
            ldarg.2
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldloc.0
            ldc.i4.0
            newarr [mscorlib]System.Byte
            ldc.i4.0
            ldc.i4.0
            callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::TransformFinalBlock(uint8[], int32, int32)
            pop
            ldloc.0
            callvirt instance uint8[] [mscorlib]System.Security.Cryptography.HashAlgorithm::get_Hash()
            stloc.2
            leave HASH_DONE
        }
        finally
        {
            ldloc.0
            brfalse HASH_DISPOSED
            ldloc.0
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        HASH_DISPOSED:
            endfinally
        }
    HASH_DONE:
        ldloc.2
        ret
    }

    .method private hidebysig static void WriteSnapshot(
        class [mscorlib]System.IO.BinaryWriter writer, class FolderMap.CacheSnapshot snapshot,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        .locals init (int32 i, int32 j, class FolderMap.CacheDirectory directory, class FolderMap.PendingWrite pending)
        ldarg.0
        ldc.i8 0x0045484341434d46
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldarg.0
        ldc.i4.1
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint32)
        ldarg.0
        ldarg.1
        ldfld string FolderMap.CacheSnapshot::RootPath
        ldarg.2
        call void FolderMap.CacheStore::WriteText(class [mscorlib]System.IO.BinaryWriter, string, class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldarg.1
        ldfld string FolderMap.CacheSnapshot::VolumeName
        ldarg.2
        call void FolderMap.CacheStore::WriteText(class [mscorlib]System.IO.BinaryWriter, string, class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldarg.1
        ldfld string FolderMap.CacheSnapshot::AccessContext
        ldarg.2
        call void FolderMap.CacheStore::WriteText(class [mscorlib]System.IO.BinaryWriter, string, class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldarg.1
        ldfld uint32 FolderMap.CacheSnapshot::VolumeSerial
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint32)
        ldarg.0
        ldarg.1
        ldfld uint64 FolderMap.CacheSnapshot::RootFileId
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldarg.0
        ldarg.1
        ldfld uint64 FolderMap.CacheSnapshot::JournalId
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldarg.0
        ldarg.1
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int64)
        ldarg.0
        ldarg.1
        ldfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int64)
        ldarg.0
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldarg.0
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldc.i4.0
        stloc.0
        br WRITE_DIRECTORY_TEST
    WRITE_DIRECTORY:
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc.0
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc.2
        ldarg.0
        ldloc.2
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldarg.0
        ldloc.2
        ldfld string FolderMap.CacheDirectory::Name
        ldarg.2
        call void FolderMap.CacheStore::WriteText(class [mscorlib]System.IO.BinaryWriter, string, class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldloc.2
        ldfld uint64 FolderMap.CacheDirectory::FileId
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldarg.0
        ldloc.2
        ldfld int64 FolderMap.CacheDirectory::DirectBytes
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int64)
        ldarg.0
        ldloc.2
        ldfld int64 FolderMap.CacheDirectory::DirectFiles
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int64)
        ldarg.0
        ldloc.2
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldarg.0
        ldloc.2
        ldfld bool FolderMap.CacheDirectory::Retry
        ldloc.2
        ldfld bool FolderMap.CacheDirectory::Reparse
        ldc.i4.1
        shl
        or
        conv.u1
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint8)
        ldarg.0
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldc.i4.0
        stloc.1
        br WRITE_ISSUE_TEST
    WRITE_ISSUE:
        ldarg.0
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldloc.1
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        ldarg.2
        call void FolderMap.CacheStore::WriteText(class [mscorlib]System.IO.BinaryWriter, string, class [System]System.ComponentModel.BackgroundWorker)
        ldloc.1
        ldc.i4.1
        add
        stloc.1
    WRITE_ISSUE_TEST:
        ldloc.1
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        blt WRITE_ISSUE
        ldarg.0
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(int32)
        ldc.i4.0
        stloc.1
        br WRITE_LINK_TEST
    WRITE_LINK:
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        ldloc.1
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Item(int32)
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldloc.1
        ldc.i4.1
        add
        stloc.1
    WRITE_LINK_TEST:
        ldloc.1
        ldloc.2
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
        blt WRITE_LINK
        ldloc.0
        ldc.i4.1
        add
        stloc.0
    WRITE_DIRECTORY_TEST:
        ldloc.0
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        blt WRITE_DIRECTORY
        ldc.i4.0
        stloc.0
        br WRITE_PENDING_TEST
    WRITE_PENDING:
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        ldloc.0
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Item(int32)
        stloc.3
        ldarg.0
        ldloc.3
        ldfld uint64 FolderMap.PendingWrite::FileId
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldarg.0
        ldloc.3
        ldfld uint64 FolderMap.PendingWrite::ParentId
        callvirt instance void [mscorlib]System.IO.BinaryWriter::Write(uint64)
        ldloc.0
        ldc.i4.1
        add
        stloc.0
    WRITE_PENDING_TEST:
        ldloc.0
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
        blt WRITE_PENDING
        ret
    }

    .method private hidebysig static void CloseWriter(
        class [mscorlib]System.IO.BinaryWriter writer, class [mscorlib]System.IO.Stream ioStream) cil managed
    {
        .maxstack 1
        .try
        {
            ldarg.0
            brfalse CLOSE_WRITER_LEAVE
            ldarg.0
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        CLOSE_WRITER_LEAVE:
            leave CLOSE_WRITER_DONE
        }
        finally
        {
            ldarg.1
            brfalse CLOSE_WRITER_STREAM
            ldarg.1
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        CLOSE_WRITER_STREAM:
            endfinally
        }
    CLOSE_WRITER_DONE:
        ret
    }

    .method private hidebysig static void CloseReader(
        class [mscorlib]System.IO.BinaryReader reader, class [mscorlib]System.IO.Stream ioStream) cil managed
    {
        .maxstack 1
        .try
        {
            ldarg.0
            brfalse CLOSE_READER_LEAVE
            ldarg.0
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        CLOSE_READER_LEAVE:
            leave CLOSE_READER_DONE
        }
        finally
        {
            ldarg.1
            brfalse CLOSE_READER_STREAM
            ldarg.1
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        CLOSE_READER_STREAM:
            endfinally
        }
    CLOSE_READER_DONE:
        ret
    }

    .method private hidebysig static void RemoveTemporary(string filePath) cil managed
    {
        .maxstack 1
        // Cleanup must not hide the original cancellation or I/O failure.
        .try
        {
            ldarg.0
            call void [mscorlib]System.IO.File::Delete(string)
            leave REMOVE_DONE
        }
        catch [mscorlib]System.IO.IOException
        {
            pop
            leave REMOVE_DONE
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            pop
            leave REMOVE_DONE
        }
    REMOVE_DONE:
        ret
    }

    .method public hidebysig static void Save(
        string filePath, class FolderMap.CacheSnapshot snapshot,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 6
        .locals init (
            string destination,
            string directory,
            string temporary,
            valuetype [mscorlib]System.Guid token,
            class [mscorlib]System.IO.FileStream ioStream,
            class [mscorlib]System.IO.BinaryWriter writer,
            uint8[] hash,
            bool created,
            bool committed)
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldstr "filePath"
        call void FolderMap.CacheStore::Argument(string, string)
        ldarg.0
        call string [mscorlib]System.IO.Path::GetFullPath(string)
        stloc destination
        ldarg.1
        ldarg.2
        call void FolderMap.CacheStore::Validate(class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
        ldarg.2
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldloc destination
        call string [mscorlib]System.IO.Path::GetDirectoryName(string)
        stloc directory
        ldloc directory
        call class [mscorlib]System.IO.DirectoryInfo [mscorlib]System.IO.Directory::CreateDirectory(string)
        pop
        call valuetype [mscorlib]System.Guid [mscorlib]System.Guid::NewGuid()
        stloc token
        ldloc directory
        ldstr ".foldermap-"
        ldloca token
        ldstr "N"
        call instance string [mscorlib]System.Guid::ToString(string)
        ldstr ".tmp"
        call string [mscorlib]System.String::Concat(string, string, string)
        call string [mscorlib]System.IO.Path::Combine(string, string)
        stloc temporary
        .try
        {
            .try
            {
                ldarg.2
                call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
                ldloc temporary
                ldc.i4.1
                ldc.i4.3
                ldc.i4.0
                ldc.i4 65536
                ldc.i4 134217728
                newobj instance void [mscorlib]System.IO.FileStream::.ctor(string, valuetype [mscorlib]System.IO.FileMode, valuetype [mscorlib]System.IO.FileAccess, valuetype [mscorlib]System.IO.FileShare, int32, valuetype [mscorlib]System.IO.FileOptions)
                stloc ioStream
                ldc.i4.1
                stloc created
                ldloc ioStream
                ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
                ldc.i4.1
                newobj instance void [mscorlib]System.IO.BinaryWriter::.ctor(class [mscorlib]System.IO.Stream, class [mscorlib]System.Text.Encoding, bool)
                stloc writer
                ldloc writer
                ldarg.1
                ldarg.2
                call void FolderMap.CacheStore::WriteSnapshot(class [mscorlib]System.IO.BinaryWriter, class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
                ldloc writer
                callvirt instance void [mscorlib]System.IO.BinaryWriter::Flush()
                ldloc ioStream
                callvirt instance int64 [mscorlib]System.IO.Stream::get_Length()
                ldc.i8 32
                add.ovf
                call int64 FolderMap.CacheStore::SizeLimit(int64)
                pop
                ldloc ioStream
                ldc.i4.0
                conv.i8
                callvirt instance void [mscorlib]System.IO.Stream::set_Position(int64)
                ldloc ioStream
                ldloc ioStream
                callvirt instance int64 [mscorlib]System.IO.Stream::get_Length()
                ldarg.2
                call uint8[] FolderMap.CacheStore::HashPrefix(class [mscorlib]System.IO.Stream, int64, class [System]System.ComponentModel.BackgroundWorker)
                stloc hash
                ldloc ioStream
                ldloc hash
                ldc.i4.0
                ldc.i4.s 32
                callvirt instance void [mscorlib]System.IO.Stream::Write(uint8[], int32, int32)
                ldloc ioStream
                ldc.i4.1
                callvirt instance void [mscorlib]System.IO.FileStream::Flush(bool)
                leave SAVE_CLOSED
            }
            finally
            {
                ldloc writer
                ldloc ioStream
                call void FolderMap.CacheStore::CloseWriter(class [mscorlib]System.IO.BinaryWriter, class [mscorlib]System.IO.Stream)
                endfinally
            }
        SAVE_CLOSED:
            ldarg.2
            call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
            ldloc destination
            call bool [mscorlib]System.IO.File::Exists(string)
            brfalse SAVE_FIRST
            ldloc temporary
            ldloc destination
            ldnull
            call void [mscorlib]System.IO.File::Replace(string, string, string)
            br SAVE_COMMITTED
        SAVE_FIRST:
            ldloc temporary
            ldloc destination
            call void [mscorlib]System.IO.File::Move(string, string)
        SAVE_COMMITTED:
            ldc.i4.1
            stloc committed
            leave SAVE_DONE
        }
        finally
        {
            ldloc created
            brfalse SAVE_CLEAN
            ldloc committed
            brtrue SAVE_CLEAN
            ldloc temporary
            call void FolderMap.CacheStore::RemoveTemporary(string)
        SAVE_CLEAN:
            endfinally
        }
    SAVE_DONE:
        ret
    }

    .method public hidebysig static class FolderMap.CacheSnapshot Load(
        string filePath, class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 6
        .locals init (
            class [mscorlib]System.IO.FileStream ioStream,
            class [mscorlib]System.IO.BinaryReader reader,
            class FolderMap.CacheSnapshot snapshot,
            class FolderMap.CacheDirectory directory,
            int64 payloadEnd,
            uint8[] actualHash,
            uint8[] expectedHash,
            int32 difference,
            int32 directoryCount,
            int32 pendingCount,
            int32 issueCount,
            int32 linkedCount,
            int32 totalLinked,
            int32 directoryFlags,
            int32 i,
            int32 j,
            class [mscorlib]System.IO.EndOfStreamException truncated,
            class [mscorlib]System.Text.DecoderFallbackException invalidUtf8)
        ldarg.1
        call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldstr "filePath"
        call void FolderMap.CacheStore::Argument(string, string)
        .try
        {
            .try
            {
                .try
                {
                    ldarg.0
                    ldc.i4.3
                    ldc.i4.1
                    ldc.i4.1
                    ldc.i4 65536
                    ldc.i4 134217728
                    newobj instance void [mscorlib]System.IO.FileStream::.ctor(string, valuetype [mscorlib]System.IO.FileMode, valuetype [mscorlib]System.IO.FileAccess, valuetype [mscorlib]System.IO.FileShare, int32, valuetype [mscorlib]System.IO.FileOptions)
                    stloc ioStream
                    leave LOAD_OPEN
                }
                catch [mscorlib]System.IO.FileNotFoundException
                {
                    pop
                    leave LOAD_RETURN
                }
                catch [mscorlib]System.IO.DirectoryNotFoundException
                {
                    pop
                    leave LOAD_RETURN
                }
            LOAD_OPEN:
                ldloc ioStream
                callvirt instance int64 [mscorlib]System.IO.Stream::get_Length()
                call int64 FolderMap.CacheStore::SizeLimit(int64)
                ldc.i8 44
                clt
                ldc.i4.0
                ceq
                ldstr "The cache is truncated: header and SHA-256 trailer are required."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc ioStream
                callvirt instance int64 [mscorlib]System.IO.Stream::get_Length()
                ldc.i8 32
                sub
                stloc payloadEnd
                ldloc ioStream
                ldloc payloadEnd
                ldarg.1
                call uint8[] FolderMap.CacheStore::HashPrefix(class [mscorlib]System.IO.Stream, int64, class [System]System.ComponentModel.BackgroundWorker)
                stloc actualHash
                ldloc ioStream
                ldsfld class [mscorlib]System.Text.UTF8Encoding FolderMap.CacheStore::Utf8
                ldc.i4.1
                newobj instance void [mscorlib]System.IO.BinaryReader::.ctor(class [mscorlib]System.IO.Stream, class [mscorlib]System.Text.Encoding, bool)
                stloc reader
                ldloc reader
                ldc.i4.s 32
                callvirt instance uint8[] [mscorlib]System.IO.BinaryReader::ReadBytes(int32)
                stloc expectedHash
                ldloc expectedHash
                ldlen
                conv.i4
                ldc.i4.s 32
                ceq
                ldstr "The cache SHA-256 trailer is truncated."
                call void FolderMap.CacheStore::Require(bool, string)
                ldc.i4.0
                stloc i
                br LOAD_HASH_TEST
            LOAD_HASH_BYTE:
                ldloc difference
                ldloc actualHash
                ldloc i
                ldelem.u1
                ldloc expectedHash
                ldloc i
                ldelem.u1
                xor
                or
                stloc difference
                ldloc i
                ldc.i4.1
                add
                stloc i
            LOAD_HASH_TEST:
                ldloc i
                ldc.i4.s 32
                blt LOAD_HASH_BYTE
                ldloc difference
                ldc.i4.0
                ceq
                ldstr "The cache SHA-256 integrity checksum does not match."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc ioStream
                ldc.i4.0
                conv.i8
                callvirt instance void [mscorlib]System.IO.Stream::set_Position(int64)
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                ldc.i8 0x0045484341434d46
                ceq
                ldstr "The cache magic header is invalid."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc reader
                callvirt instance uint32 [mscorlib]System.IO.BinaryReader::ReadUInt32()
                ldc.i4.1
                ceq
                ldstr "The cache schema version is unsupported."
                call void FolderMap.CacheStore::Require(bool, string)
                newobj instance void FolderMap.CacheSnapshot::.ctor()
                stloc snapshot
                ldloc snapshot
                ldloc reader
                ldloc payloadEnd
                ldarg.1
                call string FolderMap.CacheStore::ReadText(class [mscorlib]System.IO.BinaryReader, int64, class [System]System.ComponentModel.BackgroundWorker)
                stfld string FolderMap.CacheSnapshot::RootPath
                ldloc snapshot
                ldloc reader
                ldloc payloadEnd
                ldarg.1
                call string FolderMap.CacheStore::ReadText(class [mscorlib]System.IO.BinaryReader, int64, class [System]System.ComponentModel.BackgroundWorker)
                stfld string FolderMap.CacheSnapshot::VolumeName
                ldloc snapshot
                ldloc reader
                ldloc payloadEnd
                ldarg.1
                call string FolderMap.CacheStore::ReadText(class [mscorlib]System.IO.BinaryReader, int64, class [System]System.ComponentModel.BackgroundWorker)
                stfld string FolderMap.CacheSnapshot::AccessContext
                ldloc reader
                ldc.i8 36
                ldloc payloadEnd
                call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
                ldloc snapshot
                ldloc reader
                callvirt instance uint32 [mscorlib]System.IO.BinaryReader::ReadUInt32()
                stfld uint32 FolderMap.CacheSnapshot::VolumeSerial
                ldloc snapshot
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                stfld uint64 FolderMap.CacheSnapshot::RootFileId
                ldloc snapshot
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                stfld uint64 FolderMap.CacheSnapshot::JournalId
                ldloc snapshot
                ldloc reader
                callvirt instance int64 [mscorlib]System.IO.BinaryReader::ReadInt64()
                stfld int64 FolderMap.CacheSnapshot::Checkpoint
                ldloc snapshot
                ldloc reader
                callvirt instance int64 [mscorlib]System.IO.BinaryReader::ReadInt64()
                stfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
                ldloc snapshot
                call int64 FolderMap.CacheStore::MetadataSize(class FolderMap.CacheSnapshot)
                pop
                ldloc reader
                ldc.i4 1000000
                ldc.i4.s 45
                ldloc payloadEnd
                call int32 FolderMap.CacheStore::ReadCount(class [mscorlib]System.IO.BinaryReader, int32, int32, int64)
                stloc directoryCount
                ldloc directoryCount
                ldc.i4.0
                cgt
                ldstr "A cache must contain exactly one root directory."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc reader
                ldc.i4 1000000
                ldc.i4.s 16
                ldloc payloadEnd
                call int32 FolderMap.CacheStore::ReadCount(class [mscorlib]System.IO.BinaryReader, int32, int32, int64)
                stloc pendingCount
                ldloc reader
                ldloc directoryCount
                conv.i8
                ldc.i8 45
                mul.ovf
                ldloc pendingCount
                conv.i8
                ldc.i8 16
                mul.ovf
                add.ovf
                ldloc payloadEnd
                call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
                ldc.i4.0
                stloc i
                br LOAD_DIRECTORY_TEST
            LOAD_DIRECTORY:
                ldarg.1
                call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
                ldloc reader
                ldc.i8 45
                ldloc payloadEnd
                call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
                newobj instance void FolderMap.CacheDirectory::.ctor()
                stloc directory
                ldloc directory
                ldloc reader
                callvirt instance int32 [mscorlib]System.IO.BinaryReader::ReadInt32()
                stfld int32 FolderMap.CacheDirectory::ParentIndex
                ldloc directory
                ldloc reader
                ldloc payloadEnd
                ldarg.1
                call string FolderMap.CacheStore::ReadText(class [mscorlib]System.IO.BinaryReader, int64, class [System]System.ComponentModel.BackgroundWorker)
                stfld string FolderMap.CacheDirectory::Name
                ldloc reader
                ldc.i8 37
                ldloc payloadEnd
                call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
                ldloc directory
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                stfld uint64 FolderMap.CacheDirectory::FileId
                ldloc directory
                ldloc reader
                callvirt instance int64 [mscorlib]System.IO.BinaryReader::ReadInt64()
                stfld int64 FolderMap.CacheDirectory::DirectBytes
                ldloc directory
                ldloc reader
                callvirt instance int64 [mscorlib]System.IO.BinaryReader::ReadInt64()
                stfld int64 FolderMap.CacheDirectory::DirectFiles
                ldloc directory
                ldloc reader
                callvirt instance int32 [mscorlib]System.IO.BinaryReader::ReadInt32()
                stfld int32 FolderMap.CacheDirectory::DirectIssueCount
                ldloc reader
                callvirt instance uint8 [mscorlib]System.IO.BinaryReader::ReadByte()
                stloc directoryFlags
                ldloc directoryFlags
                ldc.i4.s -4
                and
                ldc.i4.0
                ceq
                ldstr "A cache directory contains unsupported flag bits."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc directory
                ldloc directoryFlags
                ldc.i4.1
                and
                stfld bool FolderMap.CacheDirectory::Retry
                ldloc directory
                ldloc directoryFlags
                ldc.i4.2
                and
                ldc.i4.0
                cgt
                stfld bool FolderMap.CacheDirectory::Reparse
                ldloc reader
                ldc.i4 200
                ldc.i4.4
                ldloc payloadEnd
                call int32 FolderMap.CacheStore::ReadCount(class [mscorlib]System.IO.BinaryReader, int32, int32, int64)
                stloc issueCount
                ldloc issueCount
                ldloc directory
                ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
                cgt
                ldc.i4.0
                ceq
                ldstr "Stored diagnostics cannot exceed DirectIssueCount."
                call void FolderMap.CacheStore::Require(bool, string)
                ldc.i4.0
                stloc j
                br LOAD_ISSUE_TEST
            LOAD_ISSUE:
                ldloc directory
                ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
                ldloc reader
                ldloc payloadEnd
                ldarg.1
                call string FolderMap.CacheStore::ReadText(class [mscorlib]System.IO.BinaryReader, int64, class [System]System.ComponentModel.BackgroundWorker)
                callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
                ldloc j
                ldc.i4.1
                add
                stloc j
            LOAD_ISSUE_TEST:
                ldloc j
                ldloc issueCount
                blt LOAD_ISSUE
                ldloc reader
                ldc.i4 1000000
                ldc.i4.8
                ldloc payloadEnd
                call int32 FolderMap.CacheStore::ReadCount(class [mscorlib]System.IO.BinaryReader, int32, int32, int64)
                stloc linkedCount
                ldloc totalLinked
                ldloc linkedCount
                add
                stloc totalLinked
                ldloc totalLinked
                ldc.i4 1000000
                cgt
                ldc.i4.0
                ceq
                ldstr "The cache exceeds the 1000000-total-linked-file-reference limit."
                call void FolderMap.CacheStore::Require(bool, string)
                ldc.i4.0
                stloc j
                br LOAD_LINK_TEST
            LOAD_LINK:
                ldarg.1
                call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
                ldloc directory
                ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                callvirt instance void class [mscorlib]System.Collections.Generic.List`1<uint64>::Add(!0)
                ldloc j
                ldc.i4.1
                add
                stloc j
            LOAD_LINK_TEST:
                ldloc j
                ldloc linkedCount
                blt LOAD_LINK
                ldloc snapshot
                ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
                ldloc directory
                callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::Add(!0)
                ldloc i
                ldc.i4.1
                add
                stloc i
            LOAD_DIRECTORY_TEST:
                ldloc i
                ldloc directoryCount
                blt LOAD_DIRECTORY
                ldc.i4.0
                stloc i
                br LOAD_PENDING_TEST
            LOAD_PENDING:
                ldarg.1
                call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
                ldloc reader
                ldc.i8 16
                ldloc payloadEnd
                call void FolderMap.CacheStore::Ensure(class [mscorlib]System.IO.BinaryReader, int64, int64)
                ldloc snapshot
                ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                ldloc reader
                callvirt instance uint64 [mscorlib]System.IO.BinaryReader::ReadUInt64()
                newobj instance void FolderMap.PendingWrite::.ctor(uint64, uint64)
                callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::Add(!0)
                ldloc i
                ldc.i4.1
                add
                stloc i
            LOAD_PENDING_TEST:
                ldloc i
                ldloc pendingCount
                blt LOAD_PENDING
                ldloc ioStream
                callvirt instance int64 [mscorlib]System.IO.Stream::get_Position()
                ldloc payloadEnd
                ceq
                ldstr "The cache contains trailing data before its SHA-256 trailer."
                call void FolderMap.CacheStore::Require(bool, string)
                ldloc snapshot
                ldarg.1
                call void FolderMap.CacheStore::Validate(class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
                ldarg.1
                call void FolderMap.CacheStore::Cancel(class [System]System.ComponentModel.BackgroundWorker)
                leave LOAD_RETURN
            }
            catch [mscorlib]System.IO.EndOfStreamException
            {
                stloc truncated
                ldstr "The cache binary payload is truncated."
                ldloc truncated
                newobj instance void [System]System.IO.InvalidDataException::.ctor(string, class [mscorlib]System.Exception)
                throw
            }
            catch [mscorlib]System.Text.DecoderFallbackException
            {
                stloc invalidUtf8
                ldstr "A cache string contains invalid UTF-8."
                ldloc invalidUtf8
                newobj instance void [System]System.IO.InvalidDataException::.ctor(string, class [mscorlib]System.Exception)
                throw
            }
        }
        finally
        {
            ldloc reader
            ldloc ioStream
            call void FolderMap.CacheStore::CloseReader(class [mscorlib]System.IO.BinaryReader, class [mscorlib]System.IO.Stream)
            endfinally
        }
    LOAD_RETURN:
        ldloc snapshot
        ret
    }
}
