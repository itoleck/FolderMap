.class public auto ansi beforefieldinit FolderMap.FolderNode
    extends [mscorlib]System.Object
{
    .field public string Name
    .field public string FullPath
    .field public class FolderMap.FolderNode Parent
    .field public class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> Children
    .field public int64 DirectBytes
    .field public int64 TotalBytes
    .field public int64 DirectFiles
    .field public int64 TotalFiles
    .field public int64 FolderCount
    .field public int32 IssueCount

    .method public hidebysig specialname rtspecialname instance void .ctor(
        string fullPath, class FolderMap.FolderNode parent) cil managed
    {
        .maxstack 3
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld string FolderMap.FolderNode::FullPath
        ldarg.0
        ldarg.2
        stfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldarg.0
        ldarg.1
        newobj instance void [mscorlib]System.IO.DirectoryInfo::.ctor(string)
        callvirt instance string [mscorlib]System.IO.FileSystemInfo::get_Name()
        stfld string FolderMap.FolderNode::Name
        ldarg.0
        ldfld string FolderMap.FolderNode::Name
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brfalse DONE
        ldarg.0
        ldarg.1
        stfld string FolderMap.FolderNode::Name
    DONE:
        ret
    }
}

.class public auto ansi beforefieldinit FolderMap.ScanResult
    extends [mscorlib]System.Object
{
    .field public class FolderMap.FolderNode Root
    .field public class [mscorlib]System.Collections.Generic.List`1<string> Issues
    .field public int32 IssueCount
    .field public string CacheInfo
    .field public int64 RefreshedDirectories
    .field public int64 ReusedDirectories
    .field public bool CacheConsidered

    .method public hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.FolderNode root) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ret
    }
}

.class private auto ansi sealed beforefieldinit FolderMap.ScanContext
    extends [mscorlib]System.Object
{
    .field assembly class FolderMap.ScanResult Result
    .field assembly class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> Nodes
    .field assembly class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> Pending
    .field assembly class [System]System.ComponentModel.BackgroundWorker Worker
    .field assembly class [System]System.Diagnostics.Stopwatch Clock
    .field assembly int64 LastProgress
    .field assembly class FolderMap.IScanObserver Observer
    .field assembly bool Recursive

    .method assembly hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.FolderNode root,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 3
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        newobj instance void FolderMap.ScanResult::.ctor(class FolderMap.FolderNode)
        stfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        ldarg.1
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Add(!0)
        ldarg.0
        newobj instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::.ctor()
        stfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        ldarg.0
        ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        ldarg.1
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Push(!0)
        ldarg.0
        ldarg.2
        stfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
        ldarg.0
        call class [System]System.Diagnostics.Stopwatch [System]System.Diagnostics.Stopwatch::StartNew()
        stfld class [System]System.Diagnostics.Stopwatch FolderMap.ScanContext::Clock
        ldarg.0
        ldc.i4 -150
        conv.i8
        stfld int64 FolderMap.ScanContext::LastProgress
        ret
    }
}

.class private auto ansi sealed beforefieldinit FolderMap.FolderNodeComparer
    extends [mscorlib]System.Object
    implements class [mscorlib]System.Collections.Generic.IComparer`1<class FolderMap.FolderNode>
{
    .method assembly hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }

    .method public final hidebysig newslot virtual instance int32 Compare(
        class FolderMap.FolderNode left, class FolderMap.FolderNode right) cil managed
    {
        .maxstack 3
        ldarg.1
        ldarg.2
        bne.un DIFFERENT
        ldc.i4.0
        ret
    DIFFERENT:
        ldarg.1
        brtrue LEFT_NOT_NULL
        ldc.i4.1
        ret
    LEFT_NOT_NULL:
        ldarg.2
        brtrue BOTH_NOT_NULL
        ldc.i4.m1
        ret
    BOTH_NOT_NULL:
        ldarg.2
        ldflda int64 FolderMap.FolderNode::TotalBytes
        ldarg.1
        ldfld int64 FolderMap.FolderNode::TotalBytes
        call instance int32 [mscorlib]System.Int64::CompareTo(int64)
        dup
        brfalse NAME_ORDER
        ret
    NAME_ORDER:
        pop
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_OrdinalIgnoreCase()
        ldarg.1
        ldfld string FolderMap.FolderNode::Name
        ldarg.2
        ldfld string FolderMap.FolderNode::Name
        callvirt instance int32 [mscorlib]System.StringComparer::Compare(string, string)
        dup
        brfalse EXACT_ORDER
        ret
    EXACT_ORDER:
        // A final ordinal tie-break makes case-sensitive directories deterministic too.
        pop
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        ldarg.1
        ldfld string FolderMap.FolderNode::Name
        ldarg.2
        ldfld string FolderMap.FolderNode::Name
        callvirt instance int32 [mscorlib]System.StringComparer::Compare(string, string)
        ret
    }
}

.class public abstract sealed auto ansi FolderMap.Scanner
    extends [mscorlib]System.Object
{
    .field private static initonly class FolderMap.FolderNodeComparer Comparer

    .method private hidebysig specialname rtspecialname static void .cctor() cil managed
    {
        .maxstack 1
        newobj instance void FolderMap.FolderNodeComparer::.ctor()
        stsfld class FolderMap.FolderNodeComparer FolderMap.Scanner::Comparer
        ret
    }

    .method assembly hidebysig static string Normalize(string path) cil managed
    {
        .maxstack 4
        .locals init (string normalized, int32 rootLength, int32 length, char last)
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        brtrue BLANK
        ldarg.0
        callvirt instance string [mscorlib]System.String::Trim()
        stloc normalized
        ldloc normalized
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.2
        blt EXPAND
        ldloc normalized
        ldc.i4.0
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 34
        bne.un EXPAND
        ldloc normalized
        ldloc normalized
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.1
        sub
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 34
        bne.un EXPAND
        ldloc normalized
        ldc.i4.1
        ldloc normalized
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.2
        sub
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        callvirt instance string [mscorlib]System.String::Trim()
        stloc normalized
    EXPAND:
        // ExpandEnvironmentVariables uses native strings and can otherwise truncate at NUL.
        ldloc normalized
        ldc.i4.0
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        ldc.i4.0
        blt EXPAND_VALID
        ldstr "The folder path contains a NUL character."
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    EXPAND_VALID:
        ldloc normalized
        call string [mscorlib]System.Environment::ExpandEnvironmentVariables(string)
        stloc normalized
        ldloc normalized
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        brtrue BLANK
        ldloc normalized
        call char[] [mscorlib]System.IO.Path::GetInvalidPathChars()
        callvirt instance int32 [mscorlib]System.String::IndexOfAny(char[])
        ldc.i4.0
        blt VALID_CHARACTERS
        ldstr "The folder path contains invalid characters."
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    VALID_CHARACTERS:
        ldloc normalized
        call string [mscorlib]System.IO.Path::GetFullPath(string)
        stloc normalized
        ldloc normalized
        call string [mscorlib]System.IO.Path::GetPathRoot(string)
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc rootLength
    TRIM_SEPARATOR:
        ldloc normalized
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc length
        ldloc length
        ldloc rootLength
        ble NORMALIZED
        ldloc normalized
        ldloc length
        ldc.i4.1
        sub
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc last
        ldloc last
        ldc.i4.s 92
        beq REMOVE_SEPARATOR
        ldloc last
        ldc.i4.s 47
        bne.un NORMALIZED
    REMOVE_SEPARATOR:
        ldloc normalized
        ldc.i4.0
        ldloc length
        ldc.i4.1
        sub
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc normalized
        br TRIM_SEPARATOR
    BLANK:
        ldstr "Choose a non-empty folder path."
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    NORMALIZED:
        ldloc normalized
        ret
    }

    .method assembly hidebysig static void CheckCancellation(
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 1
        ldarg.0
        brfalse DONE
        ldarg.0
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_CancellationPending()
        brfalse DONE
        ldstr "The folder scan was canceled."
        newobj instance void [mscorlib]System.OperationCanceledException::.ctor(string)
        throw
    DONE:
        ret
    }

    .method private hidebysig static void Pulse(
        class FolderMap.ScanContext context, string path) cil managed
    {
        .maxstack 3
        .locals init (int64 elapsed)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
        brfalse DONE
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_WorkerReportsProgress()
        brfalse DONE
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.ScanContext::Clock
        callvirt instance int64 [System]System.Diagnostics.Stopwatch::get_ElapsedMilliseconds()
        stloc elapsed
        ldloc elapsed
        ldarg.0
        ldfld int64 FolderMap.ScanContext::LastProgress
        sub
        ldc.i4 150
        conv.i8
        blt DONE
        ldarg.0
        ldloc elapsed
        stfld int64 FolderMap.ScanContext::LastProgress
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
        ldc.i4.0
        ldarg.1
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::ReportProgress(int32, object)
    DONE:
        ret
    }

    .method private hidebysig static void RecordIssue(
        class FolderMap.ScanContext context, class FolderMap.FolderNode node,
        string path, string message) cil managed
    {
        .maxstack 5
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        dup
        ldfld int32 FolderMap.ScanResult::IssueCount
        ldc.i4.1
        add.ovf
        stfld int32 FolderMap.ScanResult::IssueCount
        ldarg.1
        dup
        ldfld int32 FolderMap.FolderNode::IssueCount
        ldc.i4.1
        add.ovf
        stfld int32 FolderMap.FolderNode::IssueCount
        ldarg.0
        ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
        brfalse GLOBAL_ISSUE
        ldarg.0
        ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
        ldarg.1
        ldarg.2
        ldstr " : "
        ldarg.3
        call string [mscorlib]System.String::Concat(string, string, string)
        callvirt instance void FolderMap.IScanObserver::Issue(class FolderMap.FolderNode, string)
    GLOBAL_ISSUE:
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldc.i4 200
        bge DONE
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ldarg.2
        ldstr " : "
        ldarg.3
        call string [mscorlib]System.String::Concat(string, string, string)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    DONE:
        ret
    }

    .method private hidebysig static void VisitEntry(
        class [mscorlib]System.IO.FileSystemInfo entry, class FolderMap.FolderNode parent,
        class FolderMap.ScanContext context) cil managed
    {
        .maxstack 4
        .locals init (
            string path, valuetype [mscorlib]System.IO.FileAttributes attributes,
            class FolderMap.FolderNode child, int64 length, class [mscorlib]System.Exception caughtException)
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        stloc path
        .try
        {
            ldarg.0
            callvirt instance string [mscorlib]System.IO.FileSystemInfo::get_FullName()
            stloc path
            // Re-read attributes: enumeration may contain metadata for an entry that has disappeared.
            ldloc path
            call valuetype [mscorlib]System.IO.FileAttributes [mscorlib]System.IO.File::GetAttributes(string)
            stloc attributes
            ldloc attributes
            ldc.i4.s 16
            and
            brfalse FILE_ENTRY
            ldloc path
            ldarg.1
            newobj instance void FolderMap.FolderNode::.ctor(string, class FolderMap.FolderNode)
            stloc child
            ldarg.1
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
            ldloc child
            callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Add(!0)
            ldarg.2
            ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
            ldloc child
            callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Add(!0)
            ldloc attributes
            ldc.i4 1024
            and
            brfalse QUEUE_CHILD
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            brfalse LINK_ISSUE
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            ldloc child
            ldloc attributes
            callvirt instance void FolderMap.IScanObserver::Directory(class FolderMap.FolderNode, uint32)
        LINK_ISSUE:
            ldarg.2
            ldloc child
            ldloc path
            ldstr "Skipped reparse-point directory (junction or symbolic link); target was not followed."
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        QUEUE_CHILD:
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            brfalse CHILD_OBSERVED
            ldarg.2
            ldfld bool FolderMap.ScanContext::Recursive
            brtrue CHILD_OBSERVED
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            ldloc child
            ldloc attributes
            callvirt instance void FolderMap.IScanObserver::Directory(class FolderMap.FolderNode, uint32)
        CHILD_OBSERVED:
            ldarg.2
            ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
            ldloc child
            callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Push(!0)
            leave DONE
        FILE_ENTRY:
            ldloc attributes
            ldc.i4 1024
            and
            brfalse REGULAR_FILE
            ldarg.2
            ldarg.1
            ldloc path
            ldstr "Skipped reparse-point file (symbolic link); target was not followed."
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        REGULAR_FILE:
            ldloc attributes
            ldc.i4.s 64
            and
            brfalse FILE_LENGTH
            ldarg.2
            ldarg.1
            ldloc path
            ldstr "Skipped non-regular device entry."
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        FILE_LENGTH:
            ldloc path
            newobj instance void [mscorlib]System.IO.FileInfo::.ctor(string)
            callvirt instance int64 [mscorlib]System.IO.FileInfo::get_Length()
            stloc length
            ldloc length
            ldc.i4.0
            conv.i8
            bge ADD_FILE
            ldstr "File metadata returned a negative logical length."
            newobj instance void [mscorlib]System.IO.IOException::.ctor(string)
            throw
        ADD_FILE:
            ldarg.1
            dup
            ldfld int64 FolderMap.FolderNode::DirectBytes
            ldloc length
            add.ovf
            stfld int64 FolderMap.FolderNode::DirectBytes
            ldarg.1
            dup
            ldfld int64 FolderMap.FolderNode::DirectFiles
            ldc.i4.1
            conv.i8
            add.ovf
            stfld int64 FolderMap.FolderNode::DirectFiles
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            brfalse FILE_OBSERVED
            ldarg.2
            ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
            ldarg.1
            ldloc path
            callvirt instance void FolderMap.IScanObserver::File(class FolderMap.FolderNode, string)
        FILE_OBSERVED:
            leave DONE
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc caughtException
            ldarg.2
            ldarg.1
            ldloc path
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc caughtException
            ldarg.2
            ldarg.1
            ldloc path
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc caughtException
            ldarg.2
            ldarg.1
            ldloc path
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
    DONE:
        ret
    }

    .method private hidebysig static void VisitDirectory(
        class FolderMap.FolderNode node, class FolderMap.ScanContext context) cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]System.Collections.Generic.IEnumerator`1<class [mscorlib]System.IO.FileSystemInfo> entries,
            valuetype [mscorlib]System.IO.FileAttributes attributes,
            class [mscorlib]System.Exception caughtException)
        .try
        {
            .try
            {
                ldarg.1
                ldarg.0
                ldfld string FolderMap.FolderNode::FullPath
                call void FolderMap.Scanner::Pulse(class FolderMap.ScanContext, string)
                // A queued directory can be replaced by a link before it is visited.
                ldarg.0
                ldfld string FolderMap.FolderNode::FullPath
                call valuetype [mscorlib]System.IO.FileAttributes [mscorlib]System.IO.File::GetAttributes(string)
                stloc attributes
                ldarg.1
                ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
                brfalse DIRECTORY_OBSERVED
                ldarg.1
                ldfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
                ldarg.0
                ldloc attributes
                callvirt instance void FolderMap.IScanObserver::Directory(class FolderMap.FolderNode, uint32)
            DIRECTORY_OBSERVED:
                ldloc attributes
                ldc.i4 1024
                and
                brfalse CHECK_DIRECTORY
                ldarg.1
                ldarg.0
                ldarg.0
                ldfld string FolderMap.FolderNode::FullPath
                ldstr "Skipped directory that became a reparse point; target was not followed."
                call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
                leave ENUMERATION_DONE
            CHECK_DIRECTORY:
                ldloc attributes
                ldc.i4.s 16
                and
                brtrue ENUMERATE
                ldstr "The discovered directory is no longer a directory."
                newobj instance void [mscorlib]System.IO.DirectoryNotFoundException::.ctor(string)
                throw
            ENUMERATE:
                ldarg.0
                ldfld string FolderMap.FolderNode::FullPath
                newobj instance void [mscorlib]System.IO.DirectoryInfo::.ctor(string)
                callvirt instance class [mscorlib]System.Collections.Generic.IEnumerable`1<class [mscorlib]System.IO.FileSystemInfo> [mscorlib]System.IO.DirectoryInfo::EnumerateFileSystemInfos()
                callvirt instance class [mscorlib]System.Collections.Generic.IEnumerator`1<!0> class [mscorlib]System.Collections.Generic.IEnumerable`1<class [mscorlib]System.IO.FileSystemInfo>::GetEnumerator()
                stloc entries
            NEXT_ENTRY:
                ldarg.1
                ldarg.0
                ldfld string FolderMap.FolderNode::FullPath
                call void FolderMap.Scanner::Pulse(class FolderMap.ScanContext, string)
                ldloc entries
                callvirt instance bool [mscorlib]System.Collections.IEnumerator::MoveNext()
                brfalse END_ENTRIES
                ldarg.1
                ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ScanContext::Worker
                call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
                ldloc entries
                callvirt instance !0 class [mscorlib]System.Collections.Generic.IEnumerator`1<class [mscorlib]System.IO.FileSystemInfo>::get_Current()
                ldarg.0
                ldarg.1
                call void FolderMap.Scanner::VisitEntry(class [mscorlib]System.IO.FileSystemInfo, class FolderMap.FolderNode, class FolderMap.ScanContext)
                br NEXT_ENTRY
            END_ENTRIES:
                leave ENUMERATION_DONE
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
        ENUMERATION_DONE:
            leave DONE
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc caughtException
            ldarg.1
            ldarg.0
            ldarg.0
            ldfld string FolderMap.FolderNode::FullPath
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc caughtException
            ldarg.1
            ldarg.0
            ldarg.0
            ldfld string FolderMap.FolderNode::FullPath
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc caughtException
            ldarg.1
            ldarg.0
            ldarg.0
            ldfld string FolderMap.FolderNode::FullPath
            ldloc caughtException
            callvirt instance string [mscorlib]System.Exception::get_Message()
            call void FolderMap.Scanner::RecordIssue(class FolderMap.ScanContext, class FolderMap.FolderNode, string, string)
            leave DONE
        }
    DONE:
        ret
    }

    .method assembly hidebysig static void Aggregate(class FolderMap.FolderNode node) cil managed
    {
        .maxstack 4
        .locals init (int32 index, class FolderMap.FolderNode child)
        ldarg.0
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectBytes
        stfld int64 FolderMap.FolderNode::TotalBytes
        ldarg.0
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectFiles
        stfld int64 FolderMap.FolderNode::TotalFiles
        ldarg.0
        ldc.i4.0
        conv.i8
        stfld int64 FolderMap.FolderNode::FolderCount
        br CHECK_CHILD
    ADD_CHILD:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        ldarg.0
        dup
        ldfld int64 FolderMap.FolderNode::TotalBytes
        ldloc child
        ldfld int64 FolderMap.FolderNode::TotalBytes
        add.ovf
        stfld int64 FolderMap.FolderNode::TotalBytes
        ldarg.0
        dup
        ldfld int64 FolderMap.FolderNode::TotalFiles
        ldloc child
        ldfld int64 FolderMap.FolderNode::TotalFiles
        add.ovf
        stfld int64 FolderMap.FolderNode::TotalFiles
        ldarg.0
        dup
        ldfld int64 FolderMap.FolderNode::FolderCount
        ldloc child
        ldfld int64 FolderMap.FolderNode::FolderCount
        add.ovf
        ldc.i4.1
        conv.i8
        add.ovf
        stfld int64 FolderMap.FolderNode::FolderCount
        ldarg.0
        dup
        ldfld int32 FolderMap.FolderNode::IssueCount
        ldloc child
        ldfld int32 FolderMap.FolderNode::IssueCount
        add.ovf
        stfld int32 FolderMap.FolderNode::IssueCount
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    CHECK_CHILD:
        ldloc index
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt ADD_CHILD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldsfld class FolderMap.FolderNodeComparer FolderMap.Scanner::Comparer
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Sort(class [mscorlib]System.Collections.Generic.IComparer`1<!0>)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult Scan(
        string path, class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldnull
        ldc.i4.1
        call class FolderMap.ScanResult FolderMap.Scanner::ScanCore(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver, bool)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ScanObserved(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.IScanObserver observer) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldarg.2
        ldc.i4.1
        call class FolderMap.ScanResult FolderMap.Scanner::ScanCore(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver, bool)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ScanShallow(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.IScanObserver observer) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldarg.2
        ldc.i4.0
        call class FolderMap.ScanResult FolderMap.Scanner::ScanCore(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver, bool)
        ret
    }

    .method private hidebysig static class FolderMap.ScanResult ScanCore(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.IScanObserver observer, bool recursive) cil managed
    {
        .maxstack 3
        .locals init (
            string normalized, valuetype [mscorlib]System.IO.FileAttributes attributes,
            class FolderMap.ScanContext context, class FolderMap.FolderNode node, int32 index)
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        call string FolderMap.Scanner::Normalize(string)
        stloc normalized
        // Root validation deliberately happens outside per-directory recovery.
        ldloc normalized
        call valuetype [mscorlib]System.IO.FileAttributes [mscorlib]System.IO.File::GetAttributes(string)
        stloc attributes
        ldloc attributes
        ldc.i4 1024
        and
        brfalse ROOT_TYPE
        ldstr "The scan root is a reparse point (junction or symbolic link). Choose the target folder directly."
        newobj instance void [mscorlib]System.NotSupportedException::.ctor(string)
        throw
    ROOT_TYPE:
        ldloc attributes
        ldc.i4.s 16
        and
        brtrue CREATE_CONTEXT
        ldstr "The scan root must be an existing directory, not a file."
        ldstr "path"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    CREATE_CONTEXT:
        ldloc normalized
        ldnull
        newobj instance void FolderMap.FolderNode::.ctor(string, class FolderMap.FolderNode)
        ldarg.1
        newobj instance void FolderMap.ScanContext::.ctor(class FolderMap.FolderNode, class [System]System.ComponentModel.BackgroundWorker)
        stloc context
        ldloc context
        ldarg.2
        stfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
        ldloc context
        ldarg.3
        stfld bool FolderMap.ScanContext::Recursive
        br CHECK_PENDING
    VISIT:
        ldloc context
        ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        callvirt instance !0 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Pop()
        ldloc context
        call void FolderMap.Scanner::VisitDirectory(class FolderMap.FolderNode, class FolderMap.ScanContext)
        ldarg.3
        brfalse START_AGGREGATION
    CHECK_PENDING:
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc context
        ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        callvirt instance int32 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::get_Count()
        brtrue VISIT
    START_AGGREGATION:
        // Parents are discovered before children; reverse discovery order is a postorder.
        ldloc context
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        ldc.i4.1
        sub
        stloc index
        br CHECK_AGGREGATION
    AGGREGATE_NODE:
        ldloc context
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc node
        ldloc context
        ldloc node
        ldfld string FolderMap.FolderNode::FullPath
        call void FolderMap.Scanner::Pulse(class FolderMap.ScanContext, string)
        ldloc node
        call void FolderMap.Scanner::Aggregate(class FolderMap.FolderNode)
        ldloc index
        ldc.i4.1
        sub
        stloc index
    CHECK_AGGREGATION:
        ldloc index
        ldc.i4.0
        bge AGGREGATE_NODE
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc context
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.ScanContext::Clock
        callvirt instance void [System]System.Diagnostics.Stopwatch::Stop()
        ldloc context
        ldfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        ret
    }
}
