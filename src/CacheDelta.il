.class public auto ansi sealed beforefieldinit FolderMap.CacheDeltaPlan
    extends [mscorlib]System.Object
{
    .field public class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> DirtyIds
    .field public string FullScanReason
    .field public int64 RecordsSeen
    .field private uint64 RootId
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> KnownIds
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> AncestorIds
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> LinkParents
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> PendingByFile

    .method public hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.CacheSnapshot snapshot) cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> dirs,
            class FolderMap.CacheDirectory item,
            class FolderMap.PendingWrite pending,
            int32 pos, int32 linkPos, int32 parentIndex)
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.1
        brtrue SNAPSHOT_OK
        ldstr "snapshot"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    SNAPSHOT_OK:
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        stloc dirs
        ldloc dirs
        brfalse BAD
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        brfalse BAD
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        brfalse BAD
        ldarg.0
        ldarg.1
        ldfld uint64 FolderMap.CacheSnapshot::RootFileId
        stfld uint64 FolderMap.CacheDeltaPlan::RootId
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::DirtyIds
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::LinkParents
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        br DIRECTORY_TEST
    DIRECTORY_LOOP:
        ldloc dirs
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc item
        ldloc item
        call void FolderMap.CacheTree::ValidateDirectory(class FolderMap.CacheDirectory)
        ldloc item
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        stloc parentIndex
        ldloc pos
        brtrue CHECK_PARENT
        ldloc parentIndex
        ldc.i4.m1
        bne.un BAD
        br PARENT_OK
    CHECK_PARENT:
        ldloc parentIndex
        ldc.i4.0
        blt BAD
        ldloc parentIndex
        ldloc pos
        bge BAD
        ldloc dirs
        ldloc parentIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue BAD
    PARENT_OK:
        ldloc item
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue NEXT_DIRECTORY
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        brfalse NEXT_DIRECTORY
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brtrue BAD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::Add(!0, !1)
        ldloc item
        ldfld bool FolderMap.CacheDirectory::Retry
        brfalse NEXT_DIRECTORY
        ldarg.0
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        call instance void FolderMap.CacheDeltaPlan::MarkKnown(uint64)
    NEXT_DIRECTORY:
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    DIRECTORY_TEST:
        ldloc pos
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        blt DIRECTORY_LOOP
        ldc.i4.0
        stloc pos
        br LINKS_DIRECTORY_TEST
    LINKS_DIRECTORY_LOOP:
        ldloc dirs
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc item
        ldloc item
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue NEXT_LINKS_DIRECTORY
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        brfalse NEXT_LINKS_DIRECTORY
        ldc.i4.0
        stloc linkPos
        br LINK_TEST
    LINK_LOOP:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::LinkParents
        ldloc item
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        ldloc linkPos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Item(int32)
        ldloc item
        ldfld uint64 FolderMap.CacheDirectory::FileId
        call void FolderMap.CacheDeltaPlan::AddPair(
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>,
            uint64, uint64)
        ldloc linkPos
        ldc.i4.1
        add.ovf
        stloc linkPos
    LINK_TEST:
        ldloc linkPos
        ldloc item
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
        blt LINK_LOOP
    NEXT_LINKS_DIRECTORY:
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    LINKS_DIRECTORY_TEST:
        ldloc pos
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        blt LINKS_DIRECTORY_LOOP
        ldc.i4.0
        stloc pos
        br PENDING_TEST
    PENDING_LOOP:
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Item(int32)
        stloc pending
        ldloc pending
        brfalse BAD
        ldarg.0
        ldloc pending
        ldfld uint64 FolderMap.PendingWrite::ParentId
        call instance void FolderMap.CacheDeltaPlan::MarkKnown(uint64)
        ldarg.0
        ldloc pending
        ldfld uint64 FolderMap.PendingWrite::FileId
        ldloc pending
        ldfld uint64 FolderMap.PendingWrite::ParentId
        call instance void FolderMap.CacheDeltaPlan::AddKnownPending(uint64, uint64)
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    PENDING_TEST:
        ldloc pos
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::get_Count()
        blt PENDING_LOOP
        ret
    BAD:
        ldstr "The delta snapshot must have valid parent-ordered directories, unique non-reparse identities, and nonnull pending pairs."
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string)
        throw
    }

    .method private hidebysig static void AddPair(
        class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> pairs,
        uint64 fileId, uint64 parentId) cil managed
    {
        .maxstack 3
        .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents)
        ldarg.0
        ldarg.1
        ldloca parents
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::TryGetValue(!0, !1&)
        brtrue HAVE_PARENTS
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor()
        stloc parents
        ldarg.0
        ldarg.1
        ldloc parents
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::Add(!0, !1)
    HAVE_PARENTS:
        ldloc parents
        ldarg.2
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::set_Item(!0, !1)
        ret
    }

    .method private hidebysig instance void MarkKnown(uint64 directoryId) cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldarg.1
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brfalse DONE
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::DirtyIds
        ldarg.1
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::set_Item(!0, !1)
    DONE:
        ret
    }

    .method private hidebysig instance void MarkParents(
        class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents) cil managed
    {
        .maxstack 3
        .locals init (class [mscorlib]System.Collections.IDictionaryEnumerator cursor)
        ldarg.1
        callvirt instance class [mscorlib]System.Collections.IDictionaryEnumerator [mscorlib]System.Collections.IDictionary::GetEnumerator()
        stloc cursor
        br LOOP_TEST
    LOOP:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::DirtyIds
        ldloc cursor
        callvirt instance object [mscorlib]System.Collections.IDictionaryEnumerator::get_Key()
        unbox.any [mscorlib]System.UInt64
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::set_Item(!0, !1)
    LOOP_TEST:
        ldloc cursor
        callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        brtrue LOOP
        ret
    }

    .method private hidebysig instance void AddKnownPending(uint64 fileId, uint64 parentId) cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldarg.2
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brfalse DONE
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        ldarg.1
        ldarg.2
        call void FolderMap.CacheDeltaPlan::AddPair(
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>,
            uint64, uint64)
    DONE:
        ret
    }

    .method private hidebysig instance void TrackWrite(uint64 fileId, uint64 parentId) cil managed
    {
        .maxstack 3
        .locals init (
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents,
            class [mscorlib]System.Collections.IDictionaryEnumerator cursor)
        ldarg.0
        ldarg.1
        ldarg.2
        call instance void FolderMap.CacheDeltaPlan::AddKnownPending(uint64, uint64)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::LinkParents
        ldarg.1
        ldloca parents
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::TryGetValue(!0, !1&)
        brfalse DONE
        ldloc parents
        callvirt instance class [mscorlib]System.Collections.IDictionaryEnumerator [mscorlib]System.Collections.IDictionary::GetEnumerator()
        stloc cursor
        br LOOP_TEST
    LOOP:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        ldarg.1
        ldloc cursor
        callvirt instance object [mscorlib]System.Collections.IDictionaryEnumerator::get_Key()
        unbox.any [mscorlib]System.UInt64
        call void FolderMap.CacheDeltaPlan::AddPair(
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>,
            uint64, uint64)
    LOOP_TEST:
        ldloc cursor
        callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        brtrue LOOP
    DONE:
        ret
    }

    .method private hidebysig instance void FinishWrite(uint64 fileId) cil managed
    {
        .maxstack 3
        .locals init (class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        ldarg.1
        ldloca parents
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::TryGetValue(!0, !1&)
        brfalse DONE
        ldarg.0
        ldloc parents
        call instance void FolderMap.CacheDeltaPlan::MarkParents(class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        ldarg.1
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::Remove(!0)
        pop
    DONE:
        ret
    }

    .method private hidebysig instance void RequireFullScan(string detail) cil managed
    {
        .maxstack 2
        ldarg.0
        ldfld string FolderMap.CacheDeltaPlan::FullScanReason
        brtrue DONE
        ldarg.0
        ldarg.1
        stfld string FolderMap.CacheDeltaPlan::FullScanReason
    DONE:
        ret
    }

    .method public hidebysig instance void SetAncestors(
        class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> ancestors) cil managed
    {
        .maxstack 2
        ldarg.1
        brtrue VALID
        ldstr "ancestors"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    VALID:
        ldarg.0
        ldarg.1
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor(class [mscorlib]System.Collections.Generic.IDictionary`2<!0, !1>)
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::AncestorIds
        ret
    }

    .method public hidebysig instance void Observe(class FolderMap.UsnChange change) cil managed
    {
        .maxstack 4
        .locals init (
            uint64 fileId, uint64 parentId, uint32 reasons, uint32 unknownBits,
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents)
        ldarg.1
        brtrue RECORD_OK
        ldstr "change"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    RECORD_OK:
        ldarg.0
        ldarg.0
        ldfld int64 FolderMap.CacheDeltaPlan::RecordsSeen
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.CacheDeltaPlan::RecordsSeen
        ldarg.1
        ldfld uint64 FolderMap.UsnChange::FileId
        stloc fileId
        ldarg.1
        ldfld uint64 FolderMap.UsnChange::ParentId
        stloc parentId
        ldarg.1
        ldfld uint32 FolderMap.UsnChange::Reason
        stloc reasons
        // Current Windows SDK also defines DESIRED_STORAGE_CLASS_CHANGE (0x01000000).
        ldloc reasons
        ldc.i4 0x81ffff77
        not
        and
        stloc unknownBits
        ldloc unknownBits
        brfalse CHECK_HARDLINK
        ldarg.0
        ldstr "Unsupported USN reason bits 0x{0:X8} (record flags 0x{1:X8}) were observed on the volume; a conservative full scan is required."
        ldloc unknownBits
        box [mscorlib]System.UInt32
        ldloc reasons
        box [mscorlib]System.UInt32
        call string [mscorlib]System.String::Format(string, object, object)
        call instance void FolderMap.CacheDeltaPlan::RequireFullScan(string)
    CHECK_HARDLINK:
        ldloc reasons
        ldc.i4 0x00010000
        and
        brfalse CHECK_SECURITY
        ldarg.0
        ldstr "USN hard-link topology changed on the volume; a full scan is required."
        call instance void FolderMap.CacheDeltaPlan::RequireFullScan(string)
    CHECK_SECURITY:
        ldloc reasons
        ldc.i4 0x00000800
        and
        brfalse CHECK_ROOT
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::AncestorIds
        brfalse SECURITY_RELEVANT
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::AncestorIds
        ldloc fileId
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brtrue SECURITY_RELEVANT
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldloc fileId
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brtrue SECURITY_RELEVANT
        ldarg.1
        ldfld uint32 FolderMap.UsnChange::Attributes
        ldc.i4.s 16
        and
        brfalse CHECK_ROOT
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::KnownIds
        ldloc parentId
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brfalse CHECK_ROOT
    SECURITY_RELEVANT:
        ldarg.0
        ldstr "USN security/permission or inheritance changes require a conservative full scan."
        call instance void FolderMap.CacheDeltaPlan::RequireFullScan(string)
    CHECK_ROOT:
        ldloc fileId
        ldarg.0
        ldfld uint64 FolderMap.CacheDeltaPlan::RootId
        bne.un CHECK_FINISH
        ldloc reasons
        ldc.i4 0x00103200
        and
        brfalse CHECK_FINISH
        ldarg.0
        ldstr "The scanned root was deleted, renamed, or changed reparse state; a full scan is required."
        call instance void FolderMap.CacheDeltaPlan::RequireFullScan(string)
    CHECK_FINISH:
        ldloc reasons
        ldc.i4 0x80000200
        and
        brfalse CHECK_ORDINARY
        ldarg.0
        ldloc fileId
        call instance void FolderMap.CacheDeltaPlan::FinishWrite(uint64)
    CHECK_ORDINARY:
        ldloc reasons
        ldc.i4 0x7fffffff
        and
        brfalse DONE
        ldarg.0
        ldloc parentId
        call instance void FolderMap.CacheDeltaPlan::MarkKnown(uint64)
        ldarg.0
        ldloc fileId
        call instance void FolderMap.CacheDeltaPlan::MarkKnown(uint64)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::LinkParents
        ldloc fileId
        ldloca parents
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>>::TryGetValue(!0, !1&)
        brfalse CHECK_WRITE
        ldarg.0
        ldloc parents
        call instance void FolderMap.CacheDeltaPlan::MarkParents(class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>)
    CHECK_WRITE:
        ldloc reasons
        ldc.i4 0x00000107
        and
        brfalse DONE
        ldloc reasons
        ldc.i4 0x80000200
        and
        brtrue DONE
        ldarg.0
        ldloc fileId
        ldloc parentId
        call instance void FolderMap.CacheDeltaPlan::TrackWrite(uint64, uint64)
    DONE:
        ret
    }

    .method private hidebysig static int32 ComparePending(
        class FolderMap.PendingWrite left, class FolderMap.PendingWrite right) cil managed
    {
        .maxstack 2
        ldarg.0
        ldfld uint64 FolderMap.PendingWrite::FileId
        ldarg.1
        ldfld uint64 FolderMap.PendingWrite::FileId
        blt.un LESS
        ldarg.0
        ldfld uint64 FolderMap.PendingWrite::FileId
        ldarg.1
        ldfld uint64 FolderMap.PendingWrite::FileId
        bgt.un GREATER
        ldarg.0
        ldfld uint64 FolderMap.PendingWrite::ParentId
        ldarg.1
        ldfld uint64 FolderMap.PendingWrite::ParentId
        blt.un LESS
        ldarg.0
        ldfld uint64 FolderMap.PendingWrite::ParentId
        ldarg.1
        ldfld uint64 FolderMap.PendingWrite::ParentId
        bgt.un GREATER
        ldc.i4.0
        ret
    LESS:
        ldc.i4.m1
        ret
    GREATER:
        ldc.i4.1
        ret
    }

    .method public hidebysig instance class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>
        GetPendingWrites() cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> result,
            class [mscorlib]System.Collections.IDictionaryEnumerator filesCursor,
            class [mscorlib]System.Collections.IDictionaryEnumerator parentsCursor,
            class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> parents,
            uint64 fileId)
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::.ctor()
        stloc result
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>> FolderMap.CacheDeltaPlan::PendingByFile
        callvirt instance class [mscorlib]System.Collections.IDictionaryEnumerator [mscorlib]System.Collections.IDictionary::GetEnumerator()
        stloc filesCursor
        br FILE_TEST
    FILE_LOOP:
        ldloc filesCursor
        callvirt instance object [mscorlib]System.Collections.IDictionaryEnumerator::get_Key()
        unbox.any [mscorlib]System.UInt64
        stloc fileId
        ldloc filesCursor
        callvirt instance object [mscorlib]System.Collections.IDictionaryEnumerator::get_Value()
        castclass class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>
        stloc parents
        ldloc parents
        callvirt instance class [mscorlib]System.Collections.IDictionaryEnumerator [mscorlib]System.Collections.IDictionary::GetEnumerator()
        stloc parentsCursor
        br PARENT_TEST
    PARENT_LOOP:
        ldloc result
        ldloc fileId
        ldloc parentsCursor
        callvirt instance object [mscorlib]System.Collections.IDictionaryEnumerator::get_Key()
        unbox.any [mscorlib]System.UInt64
        newobj instance void FolderMap.PendingWrite::.ctor(uint64, uint64)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::Add(!0)
    PARENT_TEST:
        ldloc parentsCursor
        callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        brtrue PARENT_LOOP
    FILE_TEST:
        ldloc filesCursor
        callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
        brtrue FILE_LOOP
        ldloc result
        ldnull
        ldftn int32 FolderMap.CacheDeltaPlan::ComparePending(class FolderMap.PendingWrite, class FolderMap.PendingWrite)
        newobj instance void class [mscorlib]System.Comparison`1<class FolderMap.PendingWrite>::.ctor(object, native int)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite>::Sort(class [mscorlib]System.Comparison`1<!0>)
        ldloc result
        ret
    }
}
