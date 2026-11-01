.class private auto ansi sealed beforefieldinit FolderMap.CacheWork
    extends [mscorlib]System.Object
{
    .field assembly string Path
    .field assembly int32 OldIndex
    .field assembly int32 ParentIndex
    .field assembly class FolderMap.FolderNode Node
    .method assembly hidebysig specialname rtspecialname instance void .ctor(
        string path, int32 oldIndex, int32 parentIndex, class FolderMap.FolderNode node) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld string FolderMap.CacheWork::Path
        ldarg.0
        ldarg.2
        stfld int32 FolderMap.CacheWork::OldIndex
        ldarg.0
        ldarg.3
        stfld int32 FolderMap.CacheWork::ParentIndex
        ldarg.0
        ldarg.s node
        stfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        ret
    }
}

.class public auto ansi sealed beforefieldinit FolderMap.CacheRefreshResult
    extends [mscorlib]System.Object
{
    .field public class FolderMap.CacheSnapshot Snapshot
    .field public class FolderMap.ScanResult Result
    .field public int64 RefreshedDirectories
    .field public int64 ReusedDirectories
    .field public int32 MetadataFailures
    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.CacheRefresh
    extends [mscorlib]System.Object
{
    .method private hidebysig static void AddReadyChildren(
        class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork> work,
        class FolderMap.FolderNode node, int32 parentIndex) cil managed
    {
        .maxstack 5
        .locals init (int32 index, class FolderMap.FolderNode child)
        br CHECK
    CHILD:
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        ldarg.0
        ldloc child
        ldfld string FolderMap.FolderNode::FullPath
        ldc.i4.m1
        ldarg.2
        ldloc child
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
        ldloc index
        ldc.i4.1
        add
        stloc index
    CHECK:
        ldloc index
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt CHILD
        ret
    }

    .method public hidebysig static class FolderMap.CacheRefreshResult Capture(
        class FolderMap.ScanResult scan, class FolderMap.CacheRecorder recorder,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 5
        .locals init (
            class FolderMap.CacheRefreshResult output, class FolderMap.CacheSnapshot snapshot,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork> work,
            class FolderMap.CacheWork current, class FolderMap.CacheDirectory entryRecord, int32 index
        )
        newobj instance void FolderMap.CacheRefreshResult::.ctor()
        stloc output
        newobj instance void FolderMap.CacheSnapshot::.ctor()
        stloc snapshot
        ldloc snapshot
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld string FolderMap.FolderNode::FullPath
        stfld string FolderMap.CacheSnapshot::RootPath
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::.ctor()
        stloc work
        ldloc work
        ldloc snapshot
        ldfld string FolderMap.CacheSnapshot::RootPath
        ldc.i4.m1
        ldc.i4.m1
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
        br CHECK
    RECORD:
        ldarg.2
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc work
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::get_Item(int32)
        stloc current
        ldarg.1
        ldloc current
        ldfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Export(class FolderMap.FolderNode)
        stloc entryRecord
        ldloc entryRecord
        ldloc current
        ldfld int32 FolderMap.CacheWork::ParentIndex
        stfld int32 FolderMap.CacheDirectory::ParentIndex
        ldloc snapshot
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc entryRecord
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::Add(!0)
        ldloc work
        ldloc current
        ldfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        ldloc index
        call void FolderMap.CacheRefresh::AddReadyChildren(class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>, class FolderMap.FolderNode, int32)
        ldloc index
        ldc.i4.1
        add
        stloc index
    CHECK:
        ldloc index
        ldloc work
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::get_Count()
        blt RECORD
        ldloc output
        ldloc snapshot
        stfld class FolderMap.CacheSnapshot FolderMap.CacheRefreshResult::Snapshot
        ldloc output
        ldarg.0
        stfld class FolderMap.ScanResult FolderMap.CacheRefreshResult::Result
        ldloc output
        ldloc index
        conv.i8
        stfld int64 FolderMap.CacheRefreshResult::RefreshedDirectories
        ldloc output
        ldarg.1
        ldfld int32 FolderMap.CacheRecorder::MetadataFailures
        stfld int32 FolderMap.CacheRefreshResult::MetadataFailures
        ldloc output
        ret
    }

    .method public hidebysig static class FolderMap.CacheRefreshResult Apply(
        class FolderMap.CacheSnapshot previous, class FolderMap.CacheDeltaPlan plan,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 7
        .locals init (
            class FolderMap.CacheRefreshResult output, class FolderMap.CacheSnapshot snapshot,
            class FolderMap.CacheRecorder recorder,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork> work,
            class [mscorlib]System.Collections.Generic.List`1<string> paths,
            class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32> byPath,
            int32[] firstChild, int32[] nextSibling,
            int32 index, int32 count, int32 parentIndex, int32 childIndex, int32 oldIndex, int32 outputIndex,
            class FolderMap.CacheWork current, class FolderMap.CacheDirectory entryRecord,
            class FolderMap.CacheDirectory oldRecord, class FolderMap.CacheDirectory childRecord,
            class FolderMap.ScanResult scanned, class FolderMap.FolderNode child,
            class [System]System.Diagnostics.Stopwatch clock, int64 lastProgress
        )
        ldarg.1
        ldfld string FolderMap.CacheDeltaPlan::FullScanReason
        brfalse START
        ldstr "This journal plan requires a full scan."
        newobj instance void [mscorlib]System.InvalidOperationException::.ctor(string)
        throw
    START:
        ldarg.2
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        call class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheTree::Paths(class FolderMap.CacheSnapshot)
        stloc paths
        ldloc paths
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        stloc count
        ldloc count
        newarr [mscorlib]System.Int32
        stloc firstChild
        ldloc count
        newarr [mscorlib]System.Int32
        stloc nextSibling
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
        stloc byPath
        br INDEX_CHECK
    INDEX_NODE:
        ldloc firstChild
        ldloc index
        ldc.i4.m1
        stelem.i4
        ldloc nextSibling
        ldloc index
        ldc.i4.m1
        stelem.i4
        ldloc byPath
        ldloc paths
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        ldloc index
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::Add(!0, !1)
        ldloc index
        ldc.i4.1
        add
        stloc index
    INDEX_CHECK:
        ldloc index
        ldloc count
        blt INDEX_NODE
        ldloc count
        ldc.i4.1
        sub
        stloc index
        br LINK_CHECK
    LINK_NODE:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        stloc parentIndex
        ldloc nextSibling
        ldloc index
        ldloc firstChild
        ldloc parentIndex
        ldelem.i4
        stelem.i4
        ldloc firstChild
        ldloc parentIndex
        ldloc index
        stelem.i4
        ldloc index
        ldc.i4.1
        sub
        stloc index
    LINK_CHECK:
        ldloc index
        ldc.i4.0
        bgt LINK_NODE

        newobj instance void FolderMap.CacheRefreshResult::.ctor()
        stloc output
        newobj instance void FolderMap.CacheSnapshot::.ctor()
        stloc snapshot
        ldloc snapshot
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        stfld string FolderMap.CacheSnapshot::RootPath
        ldloc snapshot
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::VolumeName
        stfld string FolderMap.CacheSnapshot::VolumeName
        ldloc snapshot
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::AccessContext
        stfld string FolderMap.CacheSnapshot::AccessContext
        ldloc snapshot
        ldarg.0
        ldfld uint32 FolderMap.CacheSnapshot::VolumeSerial
        stfld uint32 FolderMap.CacheSnapshot::VolumeSerial
        ldloc snapshot
        ldarg.0
        ldfld uint64 FolderMap.CacheSnapshot::RootFileId
        stfld uint64 FolderMap.CacheSnapshot::RootFileId
        ldloc snapshot
        ldarg.0
        ldfld uint64 FolderMap.CacheSnapshot::JournalId
        stfld uint64 FolderMap.CacheSnapshot::JournalId
        ldloc snapshot
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        stfld int64 FolderMap.CacheSnapshot::Checkpoint
        ldloc snapshot
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
        stfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
        ldloc snapshot
        ldarg.1
        callvirt instance class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheDeltaPlan::GetPendingWrites()
        stfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.PendingWrite> FolderMap.CacheSnapshot::PendingWrites
        ldarg.0
        ldfld uint32 FolderMap.CacheSnapshot::VolumeSerial
        newobj instance void FolderMap.CacheRecorder::.ctor(uint32)
        stloc recorder
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::.ctor()
        stloc work
        ldloc work
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        ldc.i4.0
        ldc.i4.m1
        ldnull
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
        call class [System]System.Diagnostics.Stopwatch [System]System.Diagnostics.Stopwatch::StartNew()
        stloc clock
        ldc.i4.0
        stloc index
        br WORK_CHECK

    WORK_ITEM:
        ldarg.2
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc work
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::get_Item(int32)
        stloc current
        ldloc snapshot
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        stloc outputIndex
        ldloc current
        ldfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        brtrue READY_TREE
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc current
        ldfld int32 FolderMap.CacheWork::OldIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc oldRecord
        ldloc oldRecord
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue REUSE
        ldloc oldRecord
        ldfld bool FolderMap.CacheDirectory::Retry
        brtrue REFRESH
        ldloc oldRecord
        ldfld uint64 FolderMap.CacheDirectory::FileId
        ldc.i4.0
        conv.i8
        beq REFRESH
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheDeltaPlan::DirtyIds
        ldloc oldRecord
        ldfld uint64 FolderMap.CacheDirectory::FileId
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::ContainsKey(!0)
        brtrue REFRESH
    REUSE:
        ldloc oldRecord
        ldloc current
        ldfld int32 FolderMap.CacheWork::ParentIndex
        call class FolderMap.CacheDirectory FolderMap.CacheTree::CopyDirectory(class FolderMap.CacheDirectory, int32)
        stloc entryRecord
        ldloc snapshot
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc entryRecord
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::Add(!0)
        ldloc output
        dup
        ldfld int64 FolderMap.CacheRefreshResult::ReusedDirectories
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.CacheRefreshResult::ReusedDirectories
        ldloc firstChild
        ldloc current
        ldfld int32 FolderMap.CacheWork::OldIndex
        ldelem.i4
        stloc childIndex
        br REUSED_CHILD_CHECK
    REUSED_CHILD:
        ldloc work
        ldloc paths
        ldloc childIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        ldloc childIndex
        ldloc outputIndex
        ldnull
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
        ldloc nextSibling
        ldloc childIndex
        ldelem.i4
        stloc childIndex
    REUSED_CHILD_CHECK:
        ldloc childIndex
        ldc.i4.0
        bge REUSED_CHILD
        br NEXT_WORK

    READY_TREE:
        ldloc recorder
        ldloc current
        ldfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Export(class FolderMap.FolderNode)
        stloc entryRecord
        ldloc entryRecord
        ldloc current
        ldfld int32 FolderMap.CacheWork::ParentIndex
        stfld int32 FolderMap.CacheDirectory::ParentIndex
        ldloc snapshot
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc entryRecord
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::Add(!0)
        ldloc work
        ldloc current
        ldfld class FolderMap.FolderNode FolderMap.CacheWork::Node
        ldloc outputIndex
        call void FolderMap.CacheRefresh::AddReadyChildren(class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>, class FolderMap.FolderNode, int32)
        br REFRESHED

    REFRESH:
        ldarg.2
        brfalse SHALLOW
        ldarg.2
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_WorkerReportsProgress()
        brfalse SHALLOW
        ldloc clock
        callvirt instance int64 [System]System.Diagnostics.Stopwatch::get_ElapsedMilliseconds()
        ldloc lastProgress
        sub
        ldc.i4 150
        conv.i8
        blt SHALLOW
        ldarg.2
        ldc.i4.0
        ldstr "Refreshing changed directory: "
        ldloc current
        ldfld string FolderMap.CacheWork::Path
        call string [mscorlib]System.String::Concat(string, string)
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::ReportProgress(int32, object)
        ldloc clock
        callvirt instance int64 [System]System.Diagnostics.Stopwatch::get_ElapsedMilliseconds()
        stloc lastProgress
    SHALLOW:
        ldloc current
        ldfld string FolderMap.CacheWork::Path
        ldarg.2
        ldloc recorder
        call class FolderMap.ScanResult FolderMap.Scanner::ScanShallow(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver)
        stloc scanned
        ldloc recorder
        ldloc scanned
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Export(class FolderMap.FolderNode)
        stloc entryRecord
        ldloc entryRecord
        ldloc current
        ldfld int32 FolderMap.CacheWork::ParentIndex
        stfld int32 FolderMap.CacheDirectory::ParentIndex
        ldloc snapshot
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc entryRecord
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::Add(!0)
        ldc.i4.0
        stloc childIndex
        br FRESH_CHILD_CHECK
    FRESH_CHILD:
        ldloc scanned
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc childIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        ldloc recorder
        ldloc child
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc childRecord
        ldloc childRecord
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue READY_CHILD
        ldloc byPath
        ldloc child
        ldfld string FolderMap.FolderNode::FullPath
        ldloca oldIndex
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, int32>::TryGetValue(!0, !1&)
        brfalse NEW_SUBTREE
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc oldIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc oldRecord
        ldloc oldRecord
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue NEW_SUBTREE
        ldloc childRecord
        ldfld uint64 FolderMap.CacheDirectory::FileId
        ldc.i4.0
        conv.i8
        beq NEW_SUBTREE
        ldloc childRecord
        ldfld uint64 FolderMap.CacheDirectory::FileId
        ldloc oldRecord
        ldfld uint64 FolderMap.CacheDirectory::FileId
        bne.un NEW_SUBTREE
        ldloc work
        ldloc child
        ldfld string FolderMap.FolderNode::FullPath
        ldloc oldIndex
        ldloc outputIndex
        ldnull
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
        br NEXT_FRESH_CHILD
    NEW_SUBTREE:
        ldloc child
        ldfld string FolderMap.FolderNode::FullPath
        ldarg.2
        ldloc recorder
        call class FolderMap.ScanResult FolderMap.Scanner::ScanObserved(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver)
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        stloc child
    READY_CHILD:
        ldloc work
        ldloc child
        ldfld string FolderMap.FolderNode::FullPath
        ldc.i4.m1
        ldloc outputIndex
        ldloc child
        newobj instance void FolderMap.CacheWork::.ctor(string, int32, int32, class FolderMap.FolderNode)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::Add(!0)
    NEXT_FRESH_CHILD:
        ldloc childIndex
        ldc.i4.1
        add
        stloc childIndex
    FRESH_CHILD_CHECK:
        ldloc childIndex
        ldloc scanned
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt FRESH_CHILD
    REFRESHED:
        ldloc output
        dup
        ldfld int64 FolderMap.CacheRefreshResult::RefreshedDirectories
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.CacheRefreshResult::RefreshedDirectories
    NEXT_WORK:
        ldloc index
        ldc.i4.1
        add
        stloc index
    WORK_CHECK:
        ldloc index
        ldloc work
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheWork>::get_Count()
        blt WORK_ITEM
        ldloc output
        ldloc snapshot
        stfld class FolderMap.CacheSnapshot FolderMap.CacheRefreshResult::Snapshot
        ldloc output
        ldloc snapshot
        ldarg.2
        call class FolderMap.ScanResult FolderMap.CacheTree::ToResult(class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
        stfld class FolderMap.ScanResult FolderMap.CacheRefreshResult::Result
        ldloc output
        ldloc recorder
        ldfld int32 FolderMap.CacheRecorder::MetadataFailures
        stfld int32 FolderMap.CacheRefreshResult::MetadataFailures
        ldloc output
        ret
    }
}
