.assembly extern mscorlib
{
    .publickeytoken = (B7 7A 5C 56 19 34 E0 89)
    .ver 4:0:0:0
}
.assembly extern System
{
    .publickeytoken = (B7 7A 5C 56 19 34 E0 89)
    .ver 4:0:0:0
}
.assembly extern System.Drawing
{
    .publickeytoken = (B0 3F 5F 7F 11 D5 0A 3A)
    .ver 4:0:0:0
}
.assembly extern System.Windows.Forms
{
    .publickeytoken = (B7 7A 5C 56 19 34 E0 89)
    .ver 4:0:0:0
}

.assembly FolderMap
{
    .ver 1:0:0:0
    .custom instance void [mscorlib]System.Runtime.Versioning.TargetFrameworkAttribute::.ctor(string) = (
        01 00 1A 2E 4E 45 54 46 72 61 6D 65 77 6F 72 6B 2C
        56 65 72 73 69 6F 6E 3D 76 34 2E 38 00 00
    )
}
.module FolderMap.exe
.corflags 0x00000001
.subsystem 0x0002

#include "src\CacheModels.il"
#include "src\Scanner.il"
#include "src\Appearance.il"
#include "src\Tiling.il"
#include "src\Treemap.il"
#include "src\Explorer.il"
#include "src\Elevation.il"
#include "src\NtfsJournal.il"
#include "src\CacheStore.il"
#include "src\CacheTree.il"
#include "src\CacheDelta.il"
#include "src\CacheAncestors.il"
#include "src\CacheRecorder.il"
#include "src\CacheRefresh.il"
#include "src\CachePolicy.il"
#include "src\ParallelScanner.il"
#include "src\CachedScanner.il"
#include "src\MainForm.il"

.class public abstract sealed auto ansi beforefieldinit FolderMap.Program
    extends [mscorlib]System.Object
{
    .method public hidebysig static void Main(string[] args) cil managed
    {
        .entrypoint
        .custom instance void [mscorlib]System.STAThreadAttribute::.ctor() = (01 00 00 00)
        .maxstack 3
        .locals init (class FolderMap.MainForm window)

        call bool [mscorlib]System.Environment::get_Is64BitProcess()
        brtrue ARCH_OK
        ldstr "FolderMap requires a 64-bit process."
        newobj instance void [mscorlib]System.PlatformNotSupportedException::.ctor(string)
        throw
    ARCH_OK:
        call void [System.Windows.Forms]System.Windows.Forms.Application::EnableVisualStyles()
        ldc.i4.0
        call void [System.Windows.Forms]System.Windows.Forms.Application::SetCompatibleTextRenderingDefault(bool)
        newobj instance void FolderMap.MainForm::.ctor()
        stloc window
        ldarg args
        ldlen
        brfalse RUN
        ldloc window
        ldarg args
        ldc.i4.0
        ldelem.ref
        callvirt instance void FolderMap.MainForm::SetInitialPath(string)
    RUN:
        ldloc window
        call void [System.Windows.Forms]System.Windows.Forms.Application::Run(class [System.Windows.Forms]System.Windows.Forms.Form)
        ldloc window
        callvirt instance void [mscorlib]System.IDisposable::Dispose()
        ret
    }
}
