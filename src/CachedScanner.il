.class public abstract sealed auto ansi beforefieldinit FolderMap.CachedScanner
    extends [mscorlib]System.Object
{
    .method assembly hidebysig static void ReportPhase(
        class [System]System.ComponentModel.BackgroundWorker worker,
        valuetype FolderMap.ScanCacheMode mode, string detail) cil managed
    {
        .maxstack 4
        ldarg.0
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        brfalse DONE
        ldarg.0
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_WorkerReportsProgress()
        brfalse DONE
        ldarg.0
        ldc.i4.0
        ldarg.1
        ldarg.2
        newobj instance void FolderMap.ScanProgressUpdate::.ctor(valuetype FolderMap.ScanCacheMode, string)
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::ReportProgress(int32, object)
    DONE:
        ret
    }

    .method public hidebysig static string AccessContext() cil managed
    {
        .maxstack 1
        call string FolderMap.NtfsJournal::SecurityContext()
        ret
    }

    .method public hidebysig static string CacheFileContext() cil managed
    {
        .maxstack 3
        .locals init (class [mscorlib]System.Security.Principal.WindowsIdentity identity, bool elevated, string result)
        call class [mscorlib]System.Security.Principal.WindowsIdentity [mscorlib]System.Security.Principal.WindowsIdentity::GetCurrent()
        stloc identity
        .try
        {
            call bool FolderMap.Elevation::IsAdministrator()
            stloc elevated
            ldloc identity
            callvirt instance class [mscorlib]System.Security.Principal.SecurityIdentifier [mscorlib]System.Security.Principal.WindowsIdentity::get_User()
            callvirt instance string [mscorlib]System.Security.Principal.IdentityReference::get_Value()
            ldstr "|cache-file-v1|administrator="
            ldloca elevated
            call instance string [mscorlib]System.Boolean::ToString()
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc result
            leave DONE
        }
        finally
        {
            ldloc identity
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
            endfinally
        }
    DONE:
        ldloc result
        ret
    }

    .method private hidebysig static class FolderMap.CacheSnapshot Load(
        string path, class [System]System.ComponentModel.BackgroundWorker worker, string& explanation) cil managed
    {
        .maxstack 2
        .locals init (class FolderMap.CacheSnapshot snapshot, class [mscorlib]System.Exception failure)
        .try
        {
            ldarg.0
            ldarg.1
            call class FolderMap.CacheSnapshot FolderMap.CacheStore::Load(string, class [System]System.ComponentModel.BackgroundWorker)
            stloc snapshot
            leave DONE
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [System]System.IO.InvalidDataException
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
        ldarg.2
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        stind.ref
    DONE:
        ldloc snapshot
        ret
    }

    .method private hidebysig static string Save(
        string path, class FolderMap.CacheSnapshot snapshot,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 3
        .locals init (string explanation, class [mscorlib]System.Exception failure)
        .try
        {
            ldarg.0
            ldarg.1
            ldarg.2
            call void FolderMap.CacheStore::Save(string, class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
            leave DONE
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [System]System.IO.InvalidDataException
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
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        stloc explanation
    DONE:
        ldloc explanation
        ret
    }

    .method private hidebysig static bool Matches(
        class FolderMap.CacheSnapshot snapshot, class FolderMap.JournalSession session,
        class FolderMap.UsnCheckpoint head, string context) cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        ldarg.1
        ldfld string FolderMap.JournalSession::RootPath
        ldc.i4.4
        call bool [mscorlib]System.String::Equals(string, string, valuetype [mscorlib]System.StringComparison)
        brfalse NO
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::VolumeName
        ldarg.1
        ldfld string FolderMap.JournalSession::VolumeName
        ldc.i4.5
        call bool [mscorlib]System.String::Equals(string, string, valuetype [mscorlib]System.StringComparison)
        brfalse NO
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::AccessContext
        ldarg.3
        call bool [mscorlib]System.String::op_Equality(string, string)
        brfalse NO
        ldarg.0
        ldfld uint32 FolderMap.CacheSnapshot::VolumeSerial
        ldarg.1
        ldfld uint32 FolderMap.JournalSession::VolumeSerial
        bne.un NO
        ldarg.0
        ldfld uint64 FolderMap.CacheSnapshot::RootFileId
        ldarg.1
        ldfld uint64 FolderMap.JournalSession::RootFileId
        bne.un NO
        ldarg.0
        ldfld uint64 FolderMap.CacheSnapshot::JournalId
        ldarg.2
        ldfld uint64 FolderMap.UsnCheckpoint::JournalId
        bne.un NO
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        ldarg.2
        ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
        blt NO
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        ldarg.2
        ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
        blt NO
        ldarg.0
        ldfld int64 FolderMap.CacheSnapshot::Checkpoint
        ldarg.2
        ldfld int64 FolderMap.UsnCheckpoint::NextUsn
        bgt NO
        ldc.i4.1
        ret
    NO:
        ldc.i4.0
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult Scan(
        string path, class [System]System.ComponentModel.BackgroundWorker worker, bool forceFull) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldarg.2
        call string FolderMap.CacheStore::DefaultDirectory()
        call class FolderMap.ScanResult FolderMap.CachedScanner::ScanWithDirectory(string, class [System]System.ComponentModel.BackgroundWorker, bool, string)
        ret
    }

    .method public hidebysig static void RetryCache(string path, string cacheDirectory) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        call string FolderMap.CachePolicy::Key(string, string)
        call void FolderMap.CachePolicy::Reset(string)
        ret
    }

    .method private hidebysig static void TrackPolicy(
        string key, bool forceFull, class FolderMap.ScanResult result) cil managed
    {
        .maxstack 4
        .locals init (string bypass)
        ldarg.1
        brtrue DONE
        ldarg.0
        ldarg.2
        ldfld bool FolderMap.ScanResult::CacheConsidered
        ldarg.2
        ldfld int64 FolderMap.ScanResult::ReusedDirectories
        ldarg.2
        ldfld string FolderMap.ScanResult::CacheInfo
        call void FolderMap.CachePolicy::RecordOutcome(string, bool, int64, string)
        ldarg.0
        call string FolderMap.CachePolicy::BypassReason(string)
        stloc bypass
        ldloc bypass
        brfalse DONE
        ldarg.2
        ldarg.2
        ldfld string FolderMap.ScanResult::CacheInfo
        ldstr "\r\nUSN cache paused for this path after repeated unsuccessful attempts. File > Retry USN cache re-enables it."
        call string [mscorlib]System.String::Concat(string, string)
        stfld string FolderMap.ScanResult::CacheInfo
    DONE:
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ScanWithDirectory(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        bool forceFull, string cacheDirectory) cil managed
    {
        .maxstack 5
        .locals init (string normalized, string policyKey, string bypass, class FolderMap.ScanResult result, class FolderMap.ScanResult freshFull, class [mscorlib]System.Exception failure)
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        call string FolderMap.Scanner::Normalize(string)
        stloc normalized
        ldloc normalized
        ldarg.3
        call string FolderMap.CachePolicy::Key(string, string)
        stloc policyKey
        ldloc policyKey
        call string FolderMap.CachePolicy::BypassReason(string)
        stloc bypass
        ldloc bypass
        brfalse CACHE_ENABLED
        ldarg.1
        ldc.i4.1
        ldstr "USN cache paused for this path; scanning without journal or cache-metadata overhead."
        call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
        ldloc normalized
        ldarg.1
        call class FolderMap.ScanResult FolderMap.ParallelScanner::Scan(string, class [System]System.ComponentModel.BackgroundWorker)
        stloc result
        ldloc result
        ldloc result
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld int64 FolderMap.FolderNode::FolderCount
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.ScanResult::RefreshedDirectories
        ldloc result
        ldstr "Full scan; USN cache paused for this path. "
        ldloc bypass
        ldstr " File > Retry USN cache re-enables it."
        call string [mscorlib]System.String::Concat(string, string, string)
        stfld string FolderMap.ScanResult::CacheInfo
        ldloc result
        ret
    CACHE_ENABLED:
        ldarg.2
        brfalse CHECK_CACHE
        ldarg.1
        ldc.i4.1
        ldstr "Preparing a forced full scan."
        call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
        br SCAN_START
    CHECK_CACHE:
        ldarg.1
        ldc.i4.0
        ldstr "Validating snapshot and journal access."
        call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
    SCAN_START:
        .try
        {
            ldloc normalized
            ldarg.1
            ldarg.2
            ldarg.3
            ldloca freshFull
            call class FolderMap.ScanResult FolderMap.CachedScanner::ScanJournal(string, class [System]System.ComponentModel.BackgroundWorker, bool, string, class FolderMap.ScanResult&)
            stloc result
            ldloc policyKey
            ldarg.2
            ldloc result
            call void FolderMap.CachedScanner::TrackPolicy(string, bool, class FolderMap.ScanResult)
            leave DONE
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            leave FULL
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FULL
        }
        catch [System]System.IO.InvalidDataException
        {
            stloc failure
            leave FULL
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc failure
            leave FULL
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave FULL
        }
        catch [mscorlib]System.NotSupportedException
        {
            stloc failure
            leave FULL
        }
        catch [mscorlib]System.ArgumentException
        {
            stloc failure
            leave FULL
        }
    FULL:
        ldarg.1
        ldc.i4.1
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc freshFull
        stloc result
        ldloc result
        brtrue FULL_READY
        ldloc normalized
        ldarg.1
        call class FolderMap.ScanResult FolderMap.ParallelScanner::Scan(string, class [System]System.ComponentModel.BackgroundWorker)
        stloc result
    FULL_READY:
        ldloc result
        ldloc result
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld int64 FolderMap.FolderNode::FolderCount
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.ScanResult::RefreshedDirectories
        ldloc result
        ldstr "Full scan; USN cache unavailable: "
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        call string [mscorlib]System.String::Concat(string, string)
        stfld string FolderMap.ScanResult::CacheInfo
        ldloc result
        ldc.i4.1
        stfld bool FolderMap.ScanResult::CacheConsidered
        ldloc policyKey
        ldarg.2
        ldloc result
        call void FolderMap.CachedScanner::TrackPolicy(string, bool, class FolderMap.ScanResult)
    DONE:
        ldloc result
        ret
    }

    .method private hidebysig static class FolderMap.ScanResult ScanJournal(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        bool forceFull, string cacheDirectory, class FolderMap.ScanResult& freshFull) cil managed
    {
        .maxstack 8
        .locals init (
            class FolderMap.JournalSession session, class FolderMap.UsnCheckpoint head,
            class FolderMap.CacheSnapshot snapshot, class FolderMap.CacheDeltaPlan plan,
            class FolderMap.CacheRecorder recorder, class FolderMap.CacheRefreshResult refreshed,
            class FolderMap.ScanResult result, class FolderMap.FileIdentity identity,
            class FolderMap.CacheAncestors ancestors,
            string context, string cachePath, string reason, string saveFailure, string info,
            bool incremental, bool considered, int64 recordsRead, valuetype [mscorlib]System.DateTime now
        )
        ldarg.s freshFull
        ldnull
        stind.ref
        call string FolderMap.CachedScanner::AccessContext()
        stloc context
        ldarg.3
        ldarg.0
        // Stable file partitioning does not authorize reuse; Matches checks the full token fingerprint.
        call string FolderMap.CachedScanner::CacheFileContext()
        call string FolderMap.CacheStore::GetPath(string, string, string)
        stloc cachePath
        ldarg.0
        call class FolderMap.JournalSession FolderMap.NtfsJournal::Open(string)
        stloc session
        .try
        {
            ldarg.0
            ldloc session
            ldfld uint32 FolderMap.JournalSession::VolumeSerial
            ldarg.1
            newobj instance void FolderMap.CacheAncestors::.ctor(string, uint32, class [System]System.ComponentModel.BackgroundWorker)
            stloc ancestors
            ldloc context
            ldstr "|ancestors="
            ldloc ancestors
            ldfld string FolderMap.CacheAncestors::Fingerprint
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc context
            ldloc session
            callvirt instance class FolderMap.UsnCheckpoint FolderMap.JournalSession::Query()
            stloc head
            ldarg.2
            brtrue FORCE_FULL
            ldloc cachePath
            ldarg.1
            ldloca reason
            call class FolderMap.CacheSnapshot FolderMap.CachedScanner::Load(string, class [System]System.ComponentModel.BackgroundWorker, string&)
            stloc snapshot
            ldloc snapshot
            brtrue CHECK_SNAPSHOT
            ldloc reason
            brfalse NO_SNAPSHOT
            ldc.i4.1
            stloc considered
            br BASELINE
        NO_SNAPSHOT:
            ldstr "No cached snapshot."
            stloc reason
            br BASELINE
        CHECK_SNAPSHOT:
            ldc.i4.1
            stloc considered
            ldloc snapshot
            ldloc session
            ldloc head
            ldloc context
            call bool FolderMap.CachedScanner::Matches(class FolderMap.CacheSnapshot, class FolderMap.JournalSession, class FolderMap.UsnCheckpoint, string)
            brtrue DELTA
            ldstr "The saved identity, access context, or journal checkpoint is no longer valid."
            stloc reason
            br BASELINE
        FORCE_FULL:
            ldstr "Full rescan requested."
            stloc reason
            br BASELINE
        DELTA:
            ldarg.1
            ldc.i4.0
            ldstr "Checking the NTFS change journal."
            call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
        READ_DELTA:
            ldloc snapshot
            newobj instance void FolderMap.CacheDeltaPlan::.ctor(class FolderMap.CacheSnapshot)
            stloc plan
            ldloc ancestors
            ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheAncestors::Ids
            brfalse ANCESTORS_READY
            ldloc plan
            ldloc ancestors
            ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheAncestors::Ids
            callvirt instance void FolderMap.CacheDeltaPlan::SetAncestors(class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>)
        ANCESTORS_READY:
            ldloc session
            ldloc snapshot
            ldfld int64 FolderMap.CacheSnapshot::Checkpoint
            ldloc snapshot
            ldfld uint64 FolderMap.CacheSnapshot::JournalId
            ldloc head
            ldfld int64 FolderMap.UsnCheckpoint::NextUsn
            ldloc plan
            ldftn instance void FolderMap.CacheDeltaPlan::Observe(class FolderMap.UsnChange)
            newobj instance void class [mscorlib]System.Action`1<class FolderMap.UsnChange>::.ctor(object, native int)
            ldarg.1
            callvirt instance int64 FolderMap.JournalSession::ReadChanges(int64, uint64, int64, class [mscorlib]System.Action`1<class FolderMap.UsnChange>, class [System]System.ComponentModel.BackgroundWorker)
            stloc recordsRead
            ldloc plan
            ldfld string FolderMap.CacheDeltaPlan::FullScanReason
            stloc reason
            ldloc reason
            brtrue BASELINE
            ldarg.1
            ldc.i4.2
            ldstr "Refreshing changed directories and reusing unchanged sizes."
            call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
            ldloc snapshot
            ldloc plan
            ldarg.1
            call class FolderMap.CacheRefreshResult FolderMap.CacheRefresh::Apply(class FolderMap.CacheSnapshot, class FolderMap.CacheDeltaPlan, class [System]System.ComponentModel.BackgroundWorker)
            stloc refreshed
            ldc.i4.1
            stloc incremental
            br SNAPSHOT_READY

        BASELINE:
            ldarg.1
            ldc.i4.1
            ldloc reason
            call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
            ldloc session
            callvirt instance class FolderMap.UsnCheckpoint FolderMap.JournalSession::Query()
            stloc head
            ldloc session
            ldfld uint32 FolderMap.JournalSession::VolumeSerial
            newobj instance void FolderMap.CacheRecorder::.ctor(uint32)
            stloc recorder
            ldarg.0
            ldarg.1
            ldloc recorder
            call class FolderMap.ScanResult FolderMap.ParallelScanner::ScanObserved(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder)
            stloc result
            ldarg.s freshFull
            ldloc result
            stind.ref
            ldloc result
            ldloc recorder
            ldarg.1
            call class FolderMap.CacheRefreshResult FolderMap.CacheRefresh::Capture(class FolderMap.ScanResult, class FolderMap.CacheRecorder, class [System]System.ComponentModel.BackgroundWorker)
            stloc refreshed
        SNAPSHOT_READY:
            ldloc refreshed
            ldfld class FolderMap.CacheSnapshot FolderMap.CacheRefreshResult::Snapshot
            stloc snapshot
            ldloc refreshed
            ldfld class FolderMap.ScanResult FolderMap.CacheRefreshResult::Result
            stloc result
            ldloc snapshot
            ldloc session
            ldfld string FolderMap.JournalSession::VolumeName
            stfld string FolderMap.CacheSnapshot::VolumeName
            ldloc snapshot
            ldloc context
            stfld string FolderMap.CacheSnapshot::AccessContext
            ldloc snapshot
            ldloc session
            ldfld uint32 FolderMap.JournalSession::VolumeSerial
            stfld uint32 FolderMap.CacheSnapshot::VolumeSerial
            ldloc snapshot
            ldloc snapshot
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
            ldc.i4.0
            callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
            ldfld uint64 FolderMap.CacheDirectory::FileId
            stfld uint64 FolderMap.CacheSnapshot::RootFileId
            ldloc snapshot
            ldloc head
            ldfld uint64 FolderMap.UsnCheckpoint::JournalId
            stfld uint64 FolderMap.CacheSnapshot::JournalId
            // Use the boundary taken BEFORE disk reads; concurrent changes remain for the next refresh.
            ldloc snapshot
            ldloc head
            ldfld int64 FolderMap.UsnCheckpoint::NextUsn
            stfld int64 FolderMap.CacheSnapshot::Checkpoint
            ldarg.0
            call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
            stloc identity
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            ldloc snapshot
            ldfld uint64 FolderMap.CacheSnapshot::RootFileId
            bne.un IDENTITY_LOST
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::VolumeSerial
            ldloc snapshot
            ldfld uint32 FolderMap.CacheSnapshot::VolumeSerial
            bne.un IDENTITY_LOST
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::Attributes
            ldc.i4 1040
            and
            ldc.i4.s 16
            bne.un IDENTITY_LOST
            ldarg.0
            ldloc session
            ldfld uint32 FolderMap.JournalSession::VolumeSerial
            ldarg.1
            newobj instance void FolderMap.CacheAncestors::.ctor(string, uint32, class [System]System.ComponentModel.BackgroundWorker)
            ldfld string FolderMap.CacheAncestors::Fingerprint
            ldloc ancestors
            ldfld string FolderMap.CacheAncestors::Fingerprint
            call bool [mscorlib]System.String::op_Equality(string, string)
            brfalse IDENTITY_LOST
            ldloc session
            callvirt instance class FolderMap.UsnCheckpoint FolderMap.JournalSession::Query()
            stloc head
            ldloc snapshot
            ldfld uint64 FolderMap.CacheSnapshot::JournalId
            ldloc head
            ldfld uint64 FolderMap.UsnCheckpoint::JournalId
            bne.un JOURNAL_LOST
            ldloc snapshot
            ldfld int64 FolderMap.CacheSnapshot::Checkpoint
            ldloc head
            ldfld int64 FolderMap.UsnCheckpoint::FirstUsn
            blt JOURNAL_LOST
            ldloc snapshot
            ldfld int64 FolderMap.CacheSnapshot::Checkpoint
            ldloc head
            ldfld int64 FolderMap.UsnCheckpoint::LowestValidUsn
            blt JOURNAL_LOST
            ldloc snapshot
            ldfld int64 FolderMap.CacheSnapshot::Checkpoint
            ldloc head
            ldfld int64 FolderMap.UsnCheckpoint::NextUsn
            bgt JOURNAL_LOST
            br COMMIT
        IDENTITY_LOST:
            ldstr "The root identity changed or could not be verified; the cache was not updated."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        JOURNAL_LOST:
            ldstr "Journal continuity was lost during the scan; the cache was not updated."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        COMMIT:
            ldarg.1
            ldloc incremental
            brfalse SAVING_FULL
            ldc.i4.2
            br SAVING_MODE
        SAVING_FULL:
            ldc.i4.1
        SAVING_MODE:
            ldstr "Saving the size-cache snapshot."
            call void FolderMap.CachedScanner::ReportPhase(class [System]System.ComponentModel.BackgroundWorker, valuetype FolderMap.ScanCacheMode, string)
            call valuetype [mscorlib]System.DateTime [mscorlib]System.DateTime::get_UtcNow()
            stloc now
            ldloc snapshot
            ldloca now
            call instance int64 [mscorlib]System.DateTime::get_Ticks()
            stfld int64 FolderMap.CacheSnapshot::SavedUtcTicks
            ldarg.1
            call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
            ldloc cachePath
            ldloc snapshot
            ldarg.1
            call string FolderMap.CachedScanner::Save(string, class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
            stloc saveFailure
            ldloc result
            ldloc refreshed
            ldfld int64 FolderMap.CacheRefreshResult::RefreshedDirectories
            stfld int64 FolderMap.ScanResult::RefreshedDirectories
            ldloc result
            ldloc refreshed
            ldfld int64 FolderMap.CacheRefreshResult::ReusedDirectories
            stfld int64 FolderMap.ScanResult::ReusedDirectories
            ldloc incremental
            brfalse FULL_INFO
            ldstr "USN refresh: {0} folders refreshed, {1} reused; {2} journal records checked."
            ldloc result
            ldfld int64 FolderMap.ScanResult::RefreshedDirectories
            box [mscorlib]System.Int64
            ldloc result
            ldfld int64 FolderMap.ScanResult::ReusedDirectories
            box [mscorlib]System.Int64
            ldloc recordsRead
            box [mscorlib]System.Int64
            call string [mscorlib]System.String::Format(string, object, object, object)
            ldstr "\r\nCached / last-observed sizes; open writers can be newer. Ctrl+F5 forces a full scan."
            call string [mscorlib]System.String::Concat(string, string)
            stloc info
            br EXTRA_INFO
        FULL_INFO:
            ldstr "Full scan: "
            ldloc reason
            call string [mscorlib]System.String::Concat(string, string)
            stloc info
        EXTRA_INFO:
            ldloc refreshed
            ldfld int32 FolderMap.CacheRefreshResult::MetadataFailures
            brfalse SAVE_INFO
            ldloc info
            ldstr " Some cache identities were unavailable; affected directories will be refreshed again."
            call string [mscorlib]System.String::Concat(string, string)
            stloc info
        SAVE_INFO:
            ldloc saveFailure
            brfalse SAVED
            ldc.i4.1
            stloc considered
            ldloc info
            ldstr " Cache not saved: "
            ldloc saveFailure
            call string [mscorlib]System.String::Concat(string, string, string)
            stloc info
            br SET_INFO
        SAVED:
            ldloc info
            ldstr " Snapshot saved."
            call string [mscorlib]System.String::Concat(string, string)
            stloc info
        SET_INFO:
            ldloc result
            ldloc considered
            stfld bool FolderMap.ScanResult::CacheConsidered
            ldloc result
            ldloc info
            stfld string FolderMap.ScanResult::CacheInfo
            leave DONE
        }
        finally
        {
            ldloc session
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
            endfinally
        }
    DONE:
        ldloc result
        ret
    }
}
