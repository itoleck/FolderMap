.class private auto ansi sealed beforefieldinit FolderMap.ParallelScanJob
    extends [mscorlib]System.Object
{
    .field assembly int32 ChildIndex
    .field assembly class FolderMap.FolderNode Placeholder
    .field assembly class FolderMap.CacheRecorder Recorder
    .field assembly class FolderMap.ScanResult Result

    .method assembly hidebysig specialname rtspecialname instance void .ctor(
        int32 childIndex, class FolderMap.FolderNode placeholder, class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld int32 FolderMap.ParallelScanJob::ChildIndex
        ldarg.0
        ldarg.2
        stfld class FolderMap.FolderNode FolderMap.ParallelScanJob::Placeholder
        ldarg.0
        ldarg.3
        stfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        ret
    }

    .method private hidebysig instance void Failed(string detail, bool reparse) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.FolderNode node, string message, class FolderMap.CacheDirectory metadata)
        // A new node prevents stale discovery identities from being exported for a failed child.
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.ParallelScanJob::Placeholder
        ldfld string FolderMap.FolderNode::FullPath
        ldnull
        newobj instance void FolderMap.FolderNode::.ctor(string, class FolderMap.FolderNode)
        stloc node
        ldloc node
        ldc.i4.1
        stfld int32 FolderMap.FolderNode::IssueCount
        ldloc node
        ldfld string FolderMap.FolderNode::FullPath
        ldstr " : "
        ldarg.1
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc message
        ldarg.0
        ldloc node
        newobj instance void FolderMap.ScanResult::.ctor(class FolderMap.FolderNode)
        stfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
        ldc.i4.1
        stfld int32 FolderMap.ScanResult::IssueCount
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ldloc message
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
        ldarg.0
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        brfalse DONE
        ldarg.0
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        ldloc node
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc metadata
        ldloc metadata
        ldarg.2
        stfld bool FolderMap.CacheDirectory::Reparse
        ldarg.0
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        ldloc node
        ldloc message
        callvirt instance void FolderMap.CacheRecorder::Issue(class FolderMap.FolderNode, string)
        ldloc metadata
        ldc.i4.1
        stfld bool FolderMap.CacheDirectory::Retry
    DONE:
        ret
    }

    .method assembly hidebysig instance void Run(
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        .locals init (class [mscorlib]System.Exception failure, string detail, bool reparse,
            class [mscorlib]System.ArgumentException argumentFailure, class FolderMap.CacheDirectory metadata)
        .try
        {
            // Deliberately use the serial scanner: parallelism stops at this one level.
            ldarg.0
            ldarg.0
            ldfld class FolderMap.FolderNode FolderMap.ParallelScanJob::Placeholder
            ldfld string FolderMap.FolderNode::FullPath
            ldarg.1
            ldarg.0
            ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
            call class FolderMap.ScanResult FolderMap.ParallelScanner::ScanChild(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder)
            stfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
            leave SCANNED
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave IO_FAILED
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc failure
            leave IO_FAILED
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave IO_FAILED
        }
        catch [mscorlib]System.NotSupportedException
        {
            stloc failure
            // Recover only Scanner's explicit root-reparse validation, not unrelated failures.
            ldloc failure
            callvirt instance string [mscorlib]System.Exception::get_Message()
            ldstr "The scan root is a reparse point (junction or symbolic link). Choose the target folder directly."
            call bool [mscorlib]System.String::op_Equality(string, string)
            brtrue ROOT_REPARSE
            rethrow
        ROOT_REPARSE:
            ldstr "Skipped directory that became a reparse point; target was not followed."
            stloc detail
            ldc.i4.1
            stloc reparse
            leave FAILED
        }
        catch [mscorlib]System.ArgumentException
        {
            stloc argumentFailure
            // A discovered directory can become a file between discovery and root validation.
            ldloc argumentFailure
            callvirt instance string [mscorlib]System.ArgumentException::get_ParamName()
            ldstr "path"
            call bool [mscorlib]System.String::op_Equality(string, string)
            brfalse UNEXPECTED_ARGUMENT
            ldloc argumentFailure
            callvirt instance string [mscorlib]System.Exception::get_Message()
            ldstr "The scan root must be an existing directory, not a file."
            ldc.i4.4
            callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
            brtrue ROOT_FILE
        UNEXPECTED_ARGUMENT:
            rethrow
        ROOT_FILE:
            ldstr "The discovered directory is no longer a directory."
            stloc detail
            leave FAILED
        }
    IO_FAILED:
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        stloc detail
    FAILED:
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldloc detail
        ldloc reparse
        call instance void FolderMap.ParallelScanJob::Failed(string, bool)
        ret
    SCANNED:
        ldarg.0
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        brfalse DONE
        ldarg.0
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        callvirt instance class FolderMap.CacheDirectory FolderMap.CacheRecorder::Get(class FolderMap.FolderNode)
        stloc metadata
        ldloc metadata
        ldfld bool FolderMap.CacheDirectory::Reparse
        brfalse DONE
        // This job was discovered as ordinary: a later reparse replacement merits a retry.
        ldloc metadata
        ldc.i4.1
        stfld bool FolderMap.CacheDirectory::Retry
    DONE:
        ret
    }
}

.class private auto ansi sealed beforefieldinit FolderMap.ParallelScanWork
    extends [mscorlib]System.Object
{
    .field assembly class FolderMap.ParallelScanJob[] Jobs
    .field assembly class [System]System.ComponentModel.BackgroundWorker Worker
    .field assembly class [mscorlib]System.Threading.Tasks.Task[] Tasks
    .field private int64 nextJob
    .field assembly int32 StartedWorkers
    .field assembly int32 ActiveWorkers
    .field assembly int32 ActiveJobs
    .field assembly int32 PeakJobs
    .field assembly int32 CompletedJobs
    // Optional, instance-local synchronization for deterministic pool/lifecycle tests.
    .field assembly class [mscorlib]System.Action BeforeJob

    .method assembly hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.ParallelScanJob[] jobs, class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
        ldarg.0
        ldarg.2
        stfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        ldarg.0
        ldc.i4.m1
        conv.i8
        stfld int64 FolderMap.ParallelScanWork::nextJob
        ret
    }

    .method private hidebysig instance void EnterJob() cil managed
    {
        .maxstack 3
        .locals init (int32 active, int32 peak)
        ldarg.0
        ldflda int32 FolderMap.ParallelScanWork::ActiveJobs
        call int32 [mscorlib]System.Threading.Interlocked::Increment(int32&)
        stloc active
    UPDATE:
        ldarg.0
        ldflda int32 FolderMap.ParallelScanWork::PeakJobs
        ldc.i4.0
        ldc.i4.0
        call int32 [mscorlib]System.Threading.Interlocked::CompareExchange(int32&, int32, int32)
        stloc peak
        ldloc active
        ldloc peak
        ble DONE
        ldarg.0
        ldflda int32 FolderMap.ParallelScanWork::PeakJobs
        ldloc active
        ldloc peak
        call int32 [mscorlib]System.Threading.Interlocked::CompareExchange(int32&, int32, int32)
        ldloc peak
        bne.un UPDATE
    DONE:
        ret
    }

    .method private hidebysig instance void RunLane() cil managed
    {
        .maxstack 3
        .locals init (int64 index, class FolderMap.ParallelScanJob job)
        ldarg.0
        ldflda int32 FolderMap.ParallelScanWork::StartedWorkers
        call int32 [mscorlib]System.Threading.Interlocked::Increment(int32&)
        pop
        ldarg.0
        ldflda int32 FolderMap.ParallelScanWork::ActiveWorkers
        call int32 [mscorlib]System.Threading.Interlocked::Increment(int32&)
        pop
        .try
        {
        NEXT:
            ldarg.0
            ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
            call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
            // Int64 avoids wrapping a full Int32-sized queue when exhausted lanes claim once more.
            ldarg.0
            ldflda int64 FolderMap.ParallelScanWork::nextJob
            call int64 [mscorlib]System.Threading.Interlocked::Increment(int64&)
            stloc index
            ldloc index
            ldarg.0
            ldfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
            ldlen
            conv.i8
            blt CLAIMED
            leave DONE
        CLAIMED:
            ldarg.0
            ldfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
            ldloc index
            conv.ovf.i4
            ldelem.ref
            stloc job
            ldarg.0
            call instance void FolderMap.ParallelScanWork::EnterJob()
            .try
            {
                ldarg.0
                ldfld class [mscorlib]System.Action FolderMap.ParallelScanWork::BeforeJob
                brfalse RUN
                ldarg.0
                ldfld class [mscorlib]System.Action FolderMap.ParallelScanWork::BeforeJob
                callvirt instance void [mscorlib]System.Action::Invoke()
            RUN:
                ldloc job
                ldarg.0
                ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
                callvirt instance void FolderMap.ParallelScanJob::Run(class [System]System.ComponentModel.BackgroundWorker)
                ldarg.0
                ldflda int32 FolderMap.ParallelScanWork::CompletedJobs
                call int32 [mscorlib]System.Threading.Interlocked::Increment(int32&)
                pop
                leave NEXT
            }
            finally
            {
                ldarg.0
                ldflda int32 FolderMap.ParallelScanWork::ActiveJobs
                call int32 [mscorlib]System.Threading.Interlocked::Decrement(int32&)
                pop
                endfinally
            }
        }
        finally
        {
            ldarg.0
            ldflda int32 FolderMap.ParallelScanWork::ActiveWorkers
            call int32 [mscorlib]System.Threading.Interlocked::Decrement(int32&)
            pop
            endfinally
        }
    DONE:
        ret
    }

    .method assembly hidebysig instance void Start(int32 maximumWorkers) cil managed
    {
        .maxstack 4
        .locals init (int32 count, int32 index, bool allStarted, class [mscorlib]System.Action action)
        ldarg.1
        call void FolderMap.ParallelScanner::CheckLimit(int32)
        ldarg.0
        ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        brfalse NEW
        ldstr "The child worker pool has already been started."
        newobj instance void [mscorlib]System.InvalidOperationException::.ctor(string)
        throw
    NEW:
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.1
        ldarg.0
        ldfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
        ldlen
        conv.ovf.i4
        call int32 [mscorlib]System.Math::Min(int32, int32)
        stloc count
        ldarg.0
        ldloc count
        newarr [mscorlib]System.Threading.Tasks.Task
        stfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        ldarg.0
        ldftn instance void FolderMap.ParallelScanWork::RunLane()
        newobj instance void [mscorlib]System.Action::.ctor(object, native int)
        stloc action
        // Allocate every task before starting any, so allocation failure cannot orphan a lane.
        br ALLOCATION_TEST
    ALLOCATE:
        ldarg.0
        ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        ldloc index
        ldloc action
        ldc.i4.8
        newobj instance void [mscorlib]System.Threading.Tasks.Task::.ctor(class [mscorlib]System.Action, valuetype [mscorlib]System.Threading.Tasks.TaskCreationOptions)
        stelem.ref
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    ALLOCATION_TEST:
        ldloc index
        ldloc count
        blt ALLOCATE
        ldc.i4.0
        stloc index
        .try
        {
            br START_TEST
        START:
            ldarg.0
            ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
            ldloc index
            ldelem.ref
            call class [mscorlib]System.Threading.Tasks.TaskScheduler [mscorlib]System.Threading.Tasks.TaskScheduler::get_Default()
            callvirt instance void [mscorlib]System.Threading.Tasks.Task::Start(class [mscorlib]System.Threading.Tasks.TaskScheduler)
            ldloc index
            ldc.i4.1
            add.ovf
            stloc index
        START_TEST:
            ldloc index
            ldloc count
            blt START
            ldc.i4.1
            stloc allStarted
            leave DONE
        }
        finally
        {
            ldloc allStarted
            brtrue CLEAN
            // Preserve a scheduling failure, but still join any tasks already scheduled.
            ldarg.0
            ldc.i4.0
            call instance void FolderMap.ParallelScanWork::Drain(bool)
        CLEAN:
            endfinally
        }
    DONE:
        ret
    }

    .method private hidebysig instance void Drain(bool propagate) cil managed
    {
        .maxstack 2
        .locals init (
            int32 index, int32 failureIndex, class [mscorlib]System.Threading.Tasks.Task task,
            class [mscorlib]System.AggregateException aggregateFailure,
            class [mscorlib]System.Collections.ObjectModel.ReadOnlyCollection`1<class [mscorlib]System.Exception> failures,
            class [mscorlib]System.Exception failure, class [mscorlib]System.Exception unexpected,
            class [mscorlib]System.Exception canceled)
        ldarg.0
        ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        brfalse DONE
        br NEXT_TASK
    WAIT:
        ldarg.0
        ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        ldloc index
        ldelem.ref
        stloc task
        ldloc task
        brfalse ADVANCE
        ldloc task
        callvirt instance valuetype [mscorlib]System.Threading.Tasks.TaskStatus [mscorlib]System.Threading.Tasks.Task::get_Status()
        brfalse ADVANCE
        .try
        {
            ldloc task
            callvirt instance void [mscorlib]System.Threading.Tasks.Task::Wait()
            leave ADVANCE
        }
        catch [mscorlib]System.AggregateException
        {
            stloc aggregateFailure
            ldloc aggregateFailure
            callvirt instance class [mscorlib]System.AggregateException [mscorlib]System.AggregateException::Flatten()
            callvirt instance class [mscorlib]System.Collections.ObjectModel.ReadOnlyCollection`1<class [mscorlib]System.Exception> [mscorlib]System.AggregateException::get_InnerExceptions()
            stloc failures
            ldc.i4.0
            stloc failureIndex
            br NEXT_FAILURE
        FAILURE:
            ldloc failures
            ldloc failureIndex
            callvirt instance !0 class [mscorlib]System.Collections.ObjectModel.ReadOnlyCollection`1<class [mscorlib]System.Exception>::get_Item(int32)
            stloc failure
            ldloc failure
            isinst [mscorlib]System.OperationCanceledException
            brfalse UNEXPECTED
            ldloc canceled
            brtrue ADVANCE_FAILURE
            ldloc failure
            stloc canceled
            br ADVANCE_FAILURE
        UNEXPECTED:
            ldloc unexpected
            brtrue ADVANCE_FAILURE
            ldloc failure
            stloc unexpected
        ADVANCE_FAILURE:
            ldloc failureIndex
            ldc.i4.1
            add.ovf
            stloc failureIndex
        NEXT_FAILURE:
            ldloc failureIndex
            ldloc failures
            callvirt instance int32 class [mscorlib]System.Collections.ObjectModel.ReadOnlyCollection`1<class [mscorlib]System.Exception>::get_Count()
            blt FAILURE
            leave ADVANCE
        }
    ADVANCE:
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    NEXT_TASK:
        ldloc index
        ldarg.0
        ldfld class [mscorlib]System.Threading.Tasks.Task[] FolderMap.ParallelScanWork::Tasks
        ldlen
        conv.ovf.i4
        blt WAIT
        ldarg.1
        brfalse DONE
        // Every lane is finished before any exception escapes. Never mask a real fault with cancellation.
        ldloc unexpected
        brtrue THROW_UNEXPECTED
        ldloc canceled
        brfalse DONE
        ldloc canceled
        call class [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo::Capture(class [mscorlib]System.Exception)
        callvirt instance void [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo::Throw()
        br DONE
    THROW_UNEXPECTED:
        ldloc unexpected
        call class [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo::Capture(class [mscorlib]System.Exception)
        callvirt instance void [mscorlib]System.Runtime.ExceptionServices.ExceptionDispatchInfo::Throw()
    DONE:
        ret
    }

    .method assembly hidebysig instance void Join() cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        call instance void FolderMap.ParallelScanWork::Drain(bool)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.ParallelScanner
    extends [mscorlib]System.Object
{
    .method assembly hidebysig static class FolderMap.ScanResult ScanChild(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 3
        ldarg.0
        brfalse NORMAL
        ldarg.0
        ldc.i4.0
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        ldc.i4.0
        bge NORMAL
        // ScanObserved normalizes user input, but discovery paths can contain literal %VAR% names.
        ldarg.0
        callvirt instance string [mscorlib]System.String::Trim()
        ldarg.0
        call bool [mscorlib]System.String::op_Equality(string, string)
        brfalse LITERAL
        ldarg.0
        ldc.i4.s 37
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        ldc.i4.0
        blt NORMAL
    LITERAL:
        ldarg.0
        ldarg.1
        ldarg.2
        call class FolderMap.ScanResult FolderMap.ParallelScanner::ScanLiteral(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder)
        ret
    NORMAL:
        ldarg.0
        ldarg.1
        ldarg.2
        call class FolderMap.ScanResult FolderMap.Scanner::ScanObserved(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver)
        ret
    }

    // Rare literal-path fallback: bind the existing visitors rather than duplicate their I/O
    // recovery, observer, reparse, progress, and enumerator-disposal logic. Scanner stays unchanged.
    .method private hidebysig static class FolderMap.ScanResult ScanLiteral(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]System.Action`2<class FolderMap.FolderNode, class FolderMap.ScanContext> visit,
            class [mscorlib]System.Action`2<class FolderMap.ScanContext, string> pulse,
            class FolderMap.ScanContext context, class FolderMap.FolderNode node, int32 index)
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldtoken class [mscorlib]System.Action`2<class FolderMap.FolderNode, class FolderMap.ScanContext>
        call class [mscorlib]System.Type [mscorlib]System.Type::GetTypeFromHandle(valuetype [mscorlib]System.RuntimeTypeHandle)
        ldtoken FolderMap.Scanner
        call class [mscorlib]System.Type [mscorlib]System.Type::GetTypeFromHandle(valuetype [mscorlib]System.RuntimeTypeHandle)
        ldstr "VisitDirectory"
        ldc.i4.s 40
        callvirt instance class [mscorlib]System.Reflection.MethodInfo [mscorlib]System.Type::GetMethod(string, valuetype [mscorlib]System.Reflection.BindingFlags)
        call class [mscorlib]System.Delegate [mscorlib]System.Delegate::CreateDelegate(class [mscorlib]System.Type, class [mscorlib]System.Reflection.MethodInfo)
        castclass class [mscorlib]System.Action`2<class FolderMap.FolderNode, class FolderMap.ScanContext>
        stloc visit
        ldtoken class [mscorlib]System.Action`2<class FolderMap.ScanContext, string>
        call class [mscorlib]System.Type [mscorlib]System.Type::GetTypeFromHandle(valuetype [mscorlib]System.RuntimeTypeHandle)
        ldtoken FolderMap.Scanner
        call class [mscorlib]System.Type [mscorlib]System.Type::GetTypeFromHandle(valuetype [mscorlib]System.RuntimeTypeHandle)
        ldstr "Pulse"
        ldc.i4.s 40
        callvirt instance class [mscorlib]System.Reflection.MethodInfo [mscorlib]System.Type::GetMethod(string, valuetype [mscorlib]System.Reflection.BindingFlags)
        call class [mscorlib]System.Delegate [mscorlib]System.Delegate::CreateDelegate(class [mscorlib]System.Type, class [mscorlib]System.Reflection.MethodInfo)
        castclass class [mscorlib]System.Action`2<class FolderMap.ScanContext, string>
        stloc pulse
        ldarg.0
        ldnull
        newobj instance void FolderMap.FolderNode::.ctor(string, class FolderMap.FolderNode)
        ldarg.1
        newobj instance void FolderMap.ScanContext::.ctor(class FolderMap.FolderNode, class [System]System.ComponentModel.BackgroundWorker)
        stloc context
        ldloc context
        ldarg.2
        stfld class FolderMap.IScanObserver FolderMap.ScanContext::Observer
        ldloc context
        ldc.i4.1
        stfld bool FolderMap.ScanContext::Recursive
        br PENDING
    VISIT:
        ldloc visit
        ldloc context
        ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        callvirt instance !0 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Pop()
        ldloc context
        callvirt instance void class [mscorlib]System.Action`2<class FolderMap.FolderNode, class FolderMap.ScanContext>::Invoke(!0, !1)
    PENDING:
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc context
        ldfld class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> FolderMap.ScanContext::Pending
        callvirt instance int32 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::get_Count()
        brtrue VISIT
        ldloc context
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        ldc.i4.1
        sub
        stloc index
        br AGGREGATION_TEST
    AGGREGATE:
        ldloc context
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.ScanContext::Nodes
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc node
        ldloc pulse
        ldloc context
        ldloc node
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance void class [mscorlib]System.Action`2<class FolderMap.ScanContext, string>::Invoke(!0, !1)
        ldloc node
        call void FolderMap.Scanner::Aggregate(class FolderMap.FolderNode)
        ldloc index
        ldc.i4.1
        sub
        stloc index
    AGGREGATION_TEST:
        ldloc index
        ldc.i4.0
        bge AGGREGATE
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc context
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.ScanContext::Clock
        callvirt instance void [System]System.Diagnostics.Stopwatch::Stop()
        ldloc context
        ldfld class FolderMap.ScanResult FolderMap.ScanContext::Result
        ret
    }

    .method assembly hidebysig static void CheckLimit(int32 maximumWorkers) cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        blt INVALID
        ldarg.0
        ldc.i4.s 32
        ble DONE
    INVALID:
        ldstr "maximumWorkers"
        ldstr "The full-scan worker limit must be between 1 and 32."
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string, string)
        throw
    DONE:
        ret
    }

    .method private hidebysig static int32 DefaultLimit() cil managed
    {
        .maxstack 2
        call int32 [mscorlib]System.Environment::get_ProcessorCount()
        ldc.i4.4
        call int32 [mscorlib]System.Math::Min(int32, int32)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult Scan(
        string path, class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldnull
        call int32 FolderMap.ParallelScanner::DefaultLimit()
        call class FolderMap.ScanResult FolderMap.ParallelScanner::ScanWithLimit(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder, int32)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ScanObserved(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 4
        ldarg.0
        ldarg.1
        ldarg.2
        call int32 FolderMap.ParallelScanner::DefaultLimit()
        call class FolderMap.ScanResult FolderMap.ParallelScanner::ScanWithLimit(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder, int32)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ScanWithLimit(
        string path, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder, int32 maximumWorkers) cil managed
    {
        .maxstack 4
        ldarg.3
        call void FolderMap.ParallelScanner::CheckLimit(int32)
        // Root validation, root files, and discovery all stay on the calling thread.
        ldarg.0
        ldarg.1
        ldarg.2
        call class FolderMap.ScanResult FolderMap.Scanner::ScanShallow(string, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.IScanObserver)
        ldarg.1
        ldarg.2
        ldarg.3
        call class FolderMap.ScanResult FolderMap.ParallelScanner::Complete(class FolderMap.ScanResult, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder, int32)
        ret
    }

    .method assembly hidebysig static class FolderMap.ParallelScanWork CreateWork(
        class FolderMap.ScanResult shallow, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 4
        .locals init (
            int32 index, class FolderMap.FolderNode child, class FolderMap.CacheRecorder fork,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.ParallelScanJob> jobs,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> children)
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.ParallelScanJob>::.ctor()
        stloc jobs
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        stloc children
        br NEXT
    CHILD:
        ldarg.1
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldloc children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        // ScanShallow's only child-local issues are reparse skips. Never queue those nodes.
        ldloc child
        ldfld int32 FolderMap.FolderNode::IssueCount
        brtrue ADVANCE
        ldnull
        stloc fork
        ldarg.2
        brfalse ADD
        ldarg.2
        callvirt instance class FolderMap.CacheRecorder FolderMap.CacheRecorder::Fork()
        stloc fork
    ADD:
        ldloc jobs
        ldloc index
        ldloc child
        ldloc fork
        newobj instance void FolderMap.ParallelScanJob::.ctor(int32, class FolderMap.FolderNode, class FolderMap.CacheRecorder)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.ParallelScanJob>::Add(!0)
    ADVANCE:
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    NEXT:
        ldloc index
        ldloc children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt CHILD
        ldloc jobs
        callvirt instance !0[] class [mscorlib]System.Collections.Generic.List`1<class FolderMap.ParallelScanJob>::ToArray()
        ldarg.1
        newobj instance void FolderMap.ParallelScanWork::.ctor(class FolderMap.ParallelScanJob[], class [System]System.ComponentModel.BackgroundWorker)
        ret
    }

    .method assembly hidebysig static class FolderMap.ScanResult Complete(
        class FolderMap.ScanResult shallow, class [System]System.ComponentModel.BackgroundWorker worker,
        class FolderMap.CacheRecorder recorder, int32 maximumWorkers) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.ParallelScanWork work)
        ldarg.3
        call void FolderMap.ParallelScanner::CheckLimit(int32)
        ldarg.0
        ldarg.1
        ldarg.2
        call class FolderMap.ParallelScanWork FolderMap.ParallelScanner::CreateWork(class FolderMap.ScanResult, class [System]System.ComponentModel.BackgroundWorker, class FolderMap.CacheRecorder)
        stloc work
        ldloc work
        ldarg.3
        callvirt instance void FolderMap.ParallelScanWork::Start(int32)
        ldloc work
        callvirt instance void FolderMap.ParallelScanWork::Join()
        ldarg.0
        ldloc work
        ldarg.2
        call class FolderMap.ScanResult FolderMap.ParallelScanner::Merge(class FolderMap.ScanResult, class FolderMap.ParallelScanWork, class FolderMap.CacheRecorder)
        ret
    }

    .method assembly hidebysig static class FolderMap.ScanResult Merge(
        class FolderMap.ScanResult shallow, class FolderMap.ParallelScanWork work,
        class FolderMap.CacheRecorder recorder) cil managed
    {
        .maxstack 4
        .locals init (
            int32 index, int32 issueIndex, class FolderMap.FolderNode root,
            class FolderMap.ParallelScanJob job, class FolderMap.ScanResult childResult)
        ldarg.1
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        stloc root
        br DIRECT_TEST
    DIRECT:
        // Shallow already aggregated skipped child issues; Aggregate needs only direct root issues.
        ldloc root
        dup
        ldfld int32 FolderMap.FolderNode::IssueCount
        ldloc root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        ldfld int32 FolderMap.FolderNode::IssueCount
        sub.ovf
        stfld int32 FolderMap.FolderNode::IssueCount
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    DIRECT_TEST:
        ldloc index
        ldloc root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt DIRECT
        ldc.i4.0
        stloc index
        br CHILD_TEST
    CHILD:
        ldarg.1
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.1
        ldfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
        ldloc index
        ldelem.ref
        stloc job
        ldloc job
        ldfld class FolderMap.ScanResult FolderMap.ParallelScanJob::Result
        stloc childResult
        ldloc childResult
        brtrue RESULT_READY
        ldstr "A child worker finished without publishing its scan result."
        newobj instance void [mscorlib]System.InvalidOperationException::.ctor(string)
        throw
    RESULT_READY:
        ldloc childResult
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldloc root
        stfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        ldloc root
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc job
        ldfld int32 FolderMap.ParallelScanJob::ChildIndex
        ldloc childResult
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::set_Item(int32, !0)
        ldarg.0
        dup
        ldfld int32 FolderMap.ScanResult::IssueCount
        ldloc childResult
        ldfld int32 FolderMap.ScanResult::IssueCount
        add.ovf
        stfld int32 FolderMap.ScanResult::IssueCount
        ldc.i4.0
        stloc issueIndex
        br ISSUE_TEST
    ISSUE:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldc.i4 200
        bge RECORDER
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ldloc childResult
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ldloc issueIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
        ldloc issueIndex
        ldc.i4.1
        add.ovf
        stloc issueIndex
    ISSUE_TEST:
        ldloc issueIndex
        ldloc childResult
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        blt ISSUE
    RECORDER:
        ldarg.2
        brfalse ADVANCE
        ldarg.2
        ldloc job
        ldfld class FolderMap.CacheRecorder FolderMap.ParallelScanJob::Recorder
        callvirt instance void FolderMap.CacheRecorder::Merge(class FolderMap.CacheRecorder)
    ADVANCE:
        ldloc index
        ldc.i4.1
        add.ovf
        stloc index
    CHILD_TEST:
        ldloc index
        ldarg.1
        ldfld class FolderMap.ParallelScanJob[] FolderMap.ParallelScanWork::Jobs
        ldlen
        conv.ovf.i4
        blt CHILD
        ldloc root
        call void FolderMap.Scanner::Aggregate(class FolderMap.FolderNode)
        ldarg.1
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.ParallelScanWork::Worker
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ret
    }
}
