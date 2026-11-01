.class public auto ansi sealed beforefieldinit FolderMap.CacheRecorder
    extends [mscorlib]System.Object
    implements FolderMap.IScanObserver
{
    .field private uint32 volumeSerial
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> records
    .field public int32 MetadataFailures
    .field public string FirstMetadataFailure

    .method public hidebysig specialname rtspecialname instance void .ctor(uint32 serial) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld uint32 FolderMap.CacheRecorder::volumeSerial
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> FolderMap.CacheRecorder::records
        ret
    }

    .method public hidebysig instance class FolderMap.CacheRecorder Fork() cil managed
    {
        .maxstack 1
        ldarg.0
        ldfld uint32 FolderMap.CacheRecorder::volumeSerial
        newobj instance void FolderMap.CacheRecorder::.ctor(uint32)
        ret
    }

    // Only called after the contributing scanner has stopped. Copy its values so
    // neither recorder can subsequently mutate the other's observer state.
    .method public hidebysig instance void Merge(class FolderMap.CacheRecorder other) cil managed
    {
        .maxstack 4
        .locals init (
            int32 failures,
            class [mscorlib]System.Collections.Generic.IEnumerator`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>> entries,
            valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> item)
        ldarg.1
        brtrue NOT_NULL
        ldstr "other"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    NOT_NULL:
        ldarg.0
        ldarg.1
        beq INVALID
        ldarg.0
        ldfld uint32 FolderMap.CacheRecorder::volumeSerial
        ldarg.1
        ldfld uint32 FolderMap.CacheRecorder::volumeSerial
        beq COMPATIBLE
    INVALID:
        ldstr "Merge requires a different recorder for the same volume."
        ldstr "other"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    COMPATIBLE:
        ldarg.0
        ldfld int32 FolderMap.CacheRecorder::MetadataFailures
        ldarg.1
        ldfld int32 FolderMap.CacheRecorder::MetadataFailures
        add.ovf
        stloc failures
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> FolderMap.CacheRecorder::records
        callvirt instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>>::GetEnumerator()
        stloc entries
        .try
        {
            br NEXT
        COPY:
            ldloc entries
            callvirt instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>>::get_Current()
            stloc item
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> FolderMap.CacheRecorder::records
            ldloca item
            call instance !0 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::get_Key()
            ldloca item
            call instance !1 valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::get_Value()
            ldc.i4.m1
            call class FolderMap.CacheDirectory FolderMap.CacheTree::CopyDirectory(class FolderMap.CacheDirectory, int32)
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::Add(!0, !1)
        NEXT:
            ldloc entries
            callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
            brtrue COPY
            leave COPIED
        }
        finally
        {
            ldloc entries
            brfalse DISPOSED
            ldloc entries
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
        DISPOSED:
            endfinally
        }
    COPIED:
        ldarg.0
        ldloc failures
        stfld int32 FolderMap.CacheRecorder::MetadataFailures
        ldarg.0
        ldfld string FolderMap.CacheRecorder::FirstMetadataFailure
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brfalse DONE
        ldarg.1
        ldfld string FolderMap.CacheRecorder::FirstMetadataFailure
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue DONE
        ldarg.0
        ldarg.1
        ldfld string FolderMap.CacheRecorder::FirstMetadataFailure
        stfld string FolderMap.CacheRecorder::FirstMetadataFailure
    DONE:
        ret
    }

    .method public hidebysig instance class FolderMap.CacheDirectory Get(class FolderMap.FolderNode node) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.CacheDirectory entryRecord)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> FolderMap.CacheRecorder::records
        ldarg.1
        ldloca entryRecord
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::TryGetValue(!0, !1&)
        brtrue DONE
        newobj instance void FolderMap.CacheDirectory::.ctor()
        stloc entryRecord
        ldloc entryRecord
        ldarg.1
        ldfld string FolderMap.FolderNode::Name
        stfld string FolderMap.CacheDirectory::Name
        ldloc entryRecord
        ldc.i4.1
        stfld bool FolderMap.CacheDirectory::Retry
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory> FolderMap.CacheRecorder::records
        ldarg.1
        ldloc entryRecord
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class FolderMap.CacheDirectory>::Add(!0, !1)
    DONE:
        ldloc entryRecord
        ret
    }

    .method private hidebysig instance void RecordFailure(
        class FolderMap.CacheDirectory entryRecord, string path, class [mscorlib]System.Exception failure) cil managed
    {
        .maxstack 4
        ldarg.1
        ldc.i4.1
        stfld bool FolderMap.CacheDirectory::Retry
        ldarg.0
        dup
        ldfld int32 FolderMap.CacheRecorder::MetadataFailures
        ldc.i4.1
        add.ovf
        stfld int32 FolderMap.CacheRecorder::MetadataFailures
        ldarg.0
        ldfld string FolderMap.CacheRecorder::FirstMetadataFailure
        brtrue DONE
        ldarg.0
        ldarg.2
        ldstr " : "
        ldarg.3
        callvirt instance string [mscorlib]System.Exception::get_Message()
        call string [mscorlib]System.String::Concat(string, string, string)
        stfld string FolderMap.CacheRecorder::FirstMetadataFailure
    DONE:
        ret
    }

    .method public final hidebysig newslot virtual instance void Directory(
        class FolderMap.FolderNode node, uint32 attributes) cil managed
    {
        .maxstack 4
        .locals init (
            class FolderMap.CacheDirectory entryRecord, class FolderMap.FileIdentity identity,
            class [mscorlib]System.Exception failure
        )
        ldarg.0
        ldarg.1
        call instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc entryRecord
        ldloc entryRecord
        ldarg.2
        ldc.i4 1024
        and
        ldc.i4.0
        cgt.un
        stfld bool FolderMap.CacheDirectory::Reparse
        ldloc entryRecord
        ldc.i4.0
        conv.i8
        stfld uint64 FolderMap.CacheDirectory::FileId
        ldloc entryRecord
        ldc.i4.0
        stfld bool FolderMap.CacheDirectory::Retry
        ldloc entryRecord
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue DONE
        .try
        {
            ldarg.1
            ldfld string FolderMap.FolderNode::FullPath
            call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
            stloc identity
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::VolumeSerial
            ldarg.0
            ldfld uint32 FolderMap.CacheRecorder::volumeSerial
            bne.un CHANGED
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::Attributes
            ldc.i4 1040
            and
            ldc.i4.s 16
            bne.un CHANGED
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            ldc.i4.0
            conv.i8
            beq CHANGED
            ldloc entryRecord
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            stfld uint64 FolderMap.CacheDirectory::FileId
            leave DONE
        CHANGED:
            ldstr "Directory identity or volume changed while collecting cache metadata."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave FAILED
        }
    FAILED:
        ldarg.0
        ldloc entryRecord
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        ldloc failure
        call instance void FolderMap.CacheRecorder::RecordFailure(class FolderMap.CacheDirectory, string, class [mscorlib]System.Exception)
    DONE:
        ret
    }

    .method public final hidebysig newslot virtual instance void File(
        class FolderMap.FolderNode parent, string path) cil managed
    {
        .maxstack 4
        .locals init (
            class FolderMap.CacheDirectory entryRecord, class FolderMap.FileIdentity identity,
            class [mscorlib]System.Exception failure
        )
        ldarg.0
        ldarg.1
        call instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc entryRecord
        .try
        {
            ldarg.2
            call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
            stloc identity
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::VolumeSerial
            ldarg.0
            ldfld uint32 FolderMap.CacheRecorder::volumeSerial
            bne.un CHANGED
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::Attributes
            ldc.i4 1104
            and
            brtrue CHANGED
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::LinkCount
            brfalse CHANGED
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::LinkCount
            ldc.i4.1
            ble.un NO_LINK
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            ldc.i4.0
            conv.i8
            beq CHANGED
            ldloc entryRecord
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            callvirt instance bool class [mscorlib]System.Collections.Generic.List`1<uint64>::Contains(!0)
            brtrue NO_LINK
            ldloc entryRecord
            ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            callvirt instance void class [mscorlib]System.Collections.Generic.List`1<uint64>::Add(!0)
        NO_LINK:
            leave DONE
        CHANGED:
            ldstr "File identity, type, or volume changed while collecting cache metadata."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave FAILED
        }
    FAILED:
        ldarg.0
        ldloc entryRecord
        ldarg.2
        ldloc failure
        call instance void FolderMap.CacheRecorder::RecordFailure(class FolderMap.CacheDirectory, string, class [mscorlib]System.Exception)
    DONE:
        ret
    }

    .method public final hidebysig newslot virtual instance void Issue(
        class FolderMap.FolderNode node, string detail) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.CacheDirectory entryRecord)
        ldarg.0
        ldarg.1
        call instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc entryRecord
        ldloc entryRecord
        dup
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        ldc.i4.1
        add.ovf
        stfld int32 FolderMap.CacheDirectory::DirectIssueCount
        ldloc entryRecord
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue DETAILS
        ldloc entryRecord
        ldc.i4.1
        stfld bool FolderMap.CacheDirectory::Retry
    DETAILS:
        ldloc entryRecord
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldc.i4 200
        bge DONE
        ldloc entryRecord
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldarg.2
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    DONE:
        ret
    }

    .method public hidebysig instance class FolderMap.CacheDirectory Export(class FolderMap.FolderNode node) cil managed
    {
        .maxstack 2
        .locals init (class FolderMap.CacheDirectory entryRecord)
        ldarg.0
        ldarg.1
        call instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        ldc.i4.m1
        call class FolderMap.CacheDirectory FolderMap.CacheTree::CopyDirectory(class FolderMap.CacheDirectory, int32)
        stloc entryRecord
        ldloc entryRecord
        ldarg.1
        ldfld int64 FolderMap.FolderNode::DirectBytes
        stfld int64 FolderMap.CacheDirectory::DirectBytes
        ldloc entryRecord
        ldarg.1
        ldfld int64 FolderMap.FolderNode::DirectFiles
        stfld int64 FolderMap.CacheDirectory::DirectFiles
        ldloc entryRecord
        ret
    }
}
