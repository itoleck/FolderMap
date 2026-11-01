.class public abstract sealed auto ansi beforefieldinit FolderMap.Elevation
    extends [mscorlib]System.Object
{
    .method public hidebysig static bool IsAdministrator() cil managed
    {
        .maxstack 2
        .locals init (class [mscorlib]System.Security.Principal.WindowsIdentity identity, bool elevated)
        call class [mscorlib]System.Security.Principal.WindowsIdentity [mscorlib]System.Security.Principal.WindowsIdentity::GetCurrent()
        stloc identity
        .try
        {
            ldloc identity
            newobj instance void [mscorlib]System.Security.Principal.WindowsPrincipal::.ctor(class [mscorlib]System.Security.Principal.WindowsIdentity)
            ldc.i4 544
            callvirt instance bool [mscorlib]System.Security.Principal.WindowsPrincipal::IsInRole(valuetype [mscorlib]System.Security.Principal.WindowsBuiltInRole)
            stloc elevated
            leave DONE
        }
        finally
        {
            ldloc identity
            callvirt instance void [mscorlib]System.IDisposable::Dispose()
            endfinally
        }
    DONE:
        ldloc elevated
        ret
    }

    .method public hidebysig static class [System]System.Diagnostics.ProcessStartInfo CreateStartInfo(string path) cil managed
    {
        .maxstack 4
        .locals init (string executable, string normalized, class [System]System.Diagnostics.ProcessStartInfo info)
        call class [mscorlib]System.Reflection.Assembly [mscorlib]System.Reflection.Assembly::GetExecutingAssembly()
        callvirt instance string [mscorlib]System.Reflection.Assembly::get_Location()
        stloc executable
        ldloc executable
        newobj instance void [System]System.Diagnostics.ProcessStartInfo::.ctor(string)
        stloc info
        ldloc info
        ldc.i4.1
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_UseShellExecute(bool)
        ldloc info
        ldstr "runas"
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_Verb(string)
        ldloc info
        ldloc executable
        call string [mscorlib]System.IO.Path::GetDirectoryName(string)
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_WorkingDirectory(string)
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrWhiteSpace(string)
        brtrue DONE
        ldarg.0
        call string FolderMap.Scanner::Normalize(string)
        stloc normalized
        ldloc normalized
        ldstr "\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::EndsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse QUOTE
        // Escape the final separator of drive/UNC roots before the closing quote.
        ldloc normalized
        ldstr "\\"
        call string [mscorlib]System.String::Concat(string, string)
        stloc normalized
    QUOTE:
        ldloc info
        ldstr "\""
        ldloc normalized
        ldstr "\""
        call string [mscorlib]System.String::Concat(string, string, string)
        callvirt instance void [System]System.Diagnostics.ProcessStartInfo::set_Arguments(string)
    DONE:
        ldloc info
        ret
    }

    .method public hidebysig static bool Restart(string path) cil managed
    {
        .maxstack 2
        .locals init (class [System]System.Diagnostics.Process process, class [System]System.ComponentModel.Win32Exception failure, bool started)
        .try
        {
            ldarg.0
            call class [System]System.Diagnostics.ProcessStartInfo FolderMap.Elevation::CreateStartInfo(string)
            call class [System]System.Diagnostics.Process [System]System.Diagnostics.Process::Start(class [System]System.Diagnostics.ProcessStartInfo)
            stloc process
            ldloc process
            brtrue STARTED
            ldstr "Windows did not return a process for the administrator restart."
            newobj instance void [mscorlib]System.InvalidOperationException::.ctor(string)
            throw
        STARTED:
            ldloc process
            callvirt instance void [System]System.ComponentModel.Component::Dispose()
            ldc.i4.1
            stloc started
            leave DONE
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            ldloc failure
            callvirt instance int32 [System]System.ComponentModel.Win32Exception::get_NativeErrorCode()
            ldc.i4 1223
            beq CANCELLED
            rethrow
        CANCELLED:
            ldc.i4.0
            stloc started
            leave DONE
        }
    DONE:
        ldloc started
        ret
    }
}
