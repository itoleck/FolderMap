.class public abstract sealed auto ansi beforefieldinit FolderMap.Explorer
    extends [mscorlib]System.Object
{
    .method public hidebysig static class [System]System.Diagnostics.ProcessStartInfo CreateStartInfo(string folderPath) cil managed
    {
        .maxstack 2
        .locals init (
            string fullPath,
            class [System]System.Diagnostics.ProcessStartInfo info
        )
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        brfalse NORMALIZE
        ldstr "A folder path is required."
        ldstr "folderPath"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    NORMALIZE:
        ldarg.0
        call string [mscorlib]System.IO.Path::GetFullPath(string)
        stloc fullPath
        ldloc fullPath
        call valuetype [mscorlib]System.IO.FileAttributes [mscorlib]System.IO.File::GetAttributes(string)
        ldc.i4.s 16
        and
        brtrue FOLDER
        ldstr "The selected path is not a folder: "
        ldloc fullPath
        call string [mscorlib]System.String::Concat(string, string)
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string)
        throw
    FOLDER:
        // Pass the directory as a shell target, never as executable command-line text.
        ldloc fullPath
        newobj instance void [System]System.Diagnostics.ProcessStartInfo::.ctor(string)
        stloc info
        ldloc info
        ldc.i4.1
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_UseShellExecute(bool)
        ldloc info
        ldstr "explore"
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_Verb(string)
        ldloc info
        ret
    }

    .method public hidebysig static void Open(string folderPath) cil managed
    {
        .maxstack 1
        .locals init (class [System]System.Diagnostics.Process process)
        ldarg.0
        call class [System]System.Diagnostics.ProcessStartInfo FolderMap.Explorer::CreateStartInfo(string)
        call class [System]System.Diagnostics.Process [System]System.Diagnostics.Process::Start(class [System]System.Diagnostics.ProcessStartInfo)
        stloc process
        // Shell activation can reuse Explorer without returning a new process.
        ldloc process
        brfalse DONE
        ldloc process
        callvirt instance void [System]System.ComponentModel.Component::Dispose()
    DONE:
        ret
    }
}
