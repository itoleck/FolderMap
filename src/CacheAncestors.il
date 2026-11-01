.class public sealed auto ansi beforefieldinit FolderMap.CacheAncestors
    extends [mscorlib]System.Object
{
    .field public class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> Ids
    .field public string Fingerprint

    .method public hidebysig specialname rtspecialname instance void .ctor(
        string rootPath, uint32 serial, class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 3
        .locals init (
            class [mscorlib]System.IO.DirectoryInfo parent,
            class FolderMap.FileIdentity identity,
            class [mscorlib]System.Text.StringBuilder text,
            uint64 fileId
        )
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldstr "unknown"
        stfld string FolderMap.CacheAncestors::Fingerprint
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheAncestors::Ids
        newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()
        stloc text
        .try
        {
            ldarg.1
            call class [mscorlib]System.IO.DirectoryInfo [mscorlib]System.IO.Directory::GetParent(string)
            stloc parent
            br CHECK
        PARENT:
            ldarg.3
            call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
            ldloc parent
            callvirt instance string [mscorlib]System.IO.FileSystemInfo::get_FullName()
            call class FolderMap.FileIdentity FolderMap.NtfsJournal::GetIdentity(string)
            stloc identity
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::VolumeSerial
            ldarg.2
            bne.un UNRESOLVED
            ldloc identity
            ldfld uint32 FolderMap.FileIdentity::Attributes
            ldc.i4 1040
            and
            ldc.i4.s 16
            bne.un UNRESOLVED
            ldloc identity
            ldfld uint64 FolderMap.FileIdentity::FileId
            stloc fileId
            ldloc fileId
            ldc.i4.0
            conv.i8
            beq UNRESOLVED
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheAncestors::Ids
            ldloc fileId
            ldc.i4.1
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool>::set_Item(!0, !1)
            ldloc text
            ldloca fileId
            ldstr "X16"
            call instance string [mscorlib]System.UInt64::ToString(string)
            callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
            ldstr ";"
            callvirt instance class [mscorlib]System.Text.StringBuilder [mscorlib]System.Text.StringBuilder::Append(string)
            pop
            ldloc parent
            callvirt instance class [mscorlib]System.IO.DirectoryInfo [mscorlib]System.IO.DirectoryInfo::get_Parent()
            stloc parent
        CHECK:
            ldloc parent
            brtrue PARENT
            ldarg.0
            ldloc text
            callvirt instance string [mscorlib]System.Object::ToString()
            stfld string FolderMap.CacheAncestors::Fingerprint
            leave DONE
        UNRESOLVED:
            leave UNKNOWN
        }
        catch [System]System.ComponentModel.Win32Exception { pop leave UNKNOWN }
        catch [mscorlib]System.IO.IOException { pop leave UNKNOWN }
        catch [mscorlib]System.UnauthorizedAccessException { pop leave UNKNOWN }
        catch [mscorlib]System.Security.SecurityException { pop leave UNKNOWN }
    UNKNOWN:
        ldarg.0
        ldnull
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<uint64, bool> FolderMap.CacheAncestors::Ids
    DONE:
        ret
    }
}
