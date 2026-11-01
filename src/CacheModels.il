.class public auto ansi sealed FolderMap.ScanCacheMode
    extends [mscorlib]System.Enum
{
    .field public specialname rtspecialname int32 value__
    .field public static literal valuetype FolderMap.ScanCacheMode Checking = int32(0)
    .field public static literal valuetype FolderMap.ScanCacheMode FullScan = int32(1)
    .field public static literal valuetype FolderMap.ScanCacheMode UsingCache = int32(2)
}

.class public auto ansi sealed beforefieldinit FolderMap.ScanProgressUpdate
    extends [mscorlib]System.Object
{
    .field public valuetype FolderMap.ScanCacheMode Mode
    .field public string Detail
    .method public hidebysig specialname rtspecialname instance void .ctor(
        valuetype FolderMap.ScanCacheMode mode, string detail) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.1
        ldc.i4.2
        ble.un VALID
        ldstr "mode"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID:
        ldarg.0
        ldarg.1
        stfld valuetype FolderMap.ScanCacheMode FolderMap.ScanProgressUpdate::Mode
        ldarg.0
        ldarg.2
        stfld string FolderMap.ScanProgressUpdate::Detail
        ret
    }
}

.class public auto ansi sealed beforefieldinit FolderMap.CacheDirectory
    extends [mscorlib]System.Object
{
    .field public int32 ParentIndex
    .field public string Name
    .field public uint64 FileId
    .field public int64 DirectBytes
    .field public int64 DirectFiles
    .field public int32 DirectIssueCount
    .field public bool Retry
    .field public bool Reparse
    .field public class [mscorlib]System.Collections.Generic.List`1<string> Issues
    .field public class [mscorlib]System.Collections.Generic.List`1<uint64> LinkedFiles

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldc.i4.m1
        stfld int32 FolderMap.CacheDirectory::ParentIndex
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<uint64>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        ret
    }
}

.class public auto ansi sealed beforefieldinit FolderMap.PendingWrite
    extends [mscorlib]System.Object
{
    .field public uint64 FileId
    .field public uint64 ParentId

    .method public hidebysig specialname rtspecialname instance void .ctor(uint64 fileId, uint64 parentId) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld uint64 FolderMap.PendingWrite::FileId
        ldarg.0
        ldarg.2
        stfld uint64 FolderMap.PendingWrite::ParentId
        ret
    }
}

.class public auto ansi sealed beforefieldinit FolderMap.CacheSnapshot
    extends [mscorlib]System.Object
{
    .field public string RootPath
    .field public string VolumeName
    .field public string AccessContext
    .field public uint32 VolumeSerial
    .field public uint64 RootFileId
    .field public uint64 JournalId
    .field public int64 Checkpoint
    .field public int64 SavedUtcTicks
    .field public class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> Directories
    .field public class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> PendingWrites

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        ret
    }
}

.class interface public abstract auto ansi FolderMap.IScanObserver
{
    .method public hidebysig newslot abstract virtual instance void Directory(
        class FolderMap.FolderNode node, uint32 attributes) cil managed {}
    .method public hidebysig newslot abstract virtual instance void File(
        class FolderMap.FolderNode parent, string path) cil managed {}
    .method public hidebysig newslot abstract virtual instance void Issue(
        class FolderMap.FolderNode node, string detail) cil managed {}
}

.class public auto ansi sealed beforefieldinit FolderMap.ScanRequest
    extends [mscorlib]System.Object
{
    .field public string Path
    .field public bool ForceFull
    .field public bool RetryCache
    .field public string CacheDirectory

    .method public hidebysig specialname rtspecialname instance void .ctor(string path, bool forceFull) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld string FolderMap.ScanRequest::Path
        ldarg.0
        ldarg.2
        stfld bool FolderMap.ScanRequest::ForceFull
        ret
    }
}
