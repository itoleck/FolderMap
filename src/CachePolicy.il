.class private sealed auto ansi beforefieldinit FolderMap.CachePolicyEntry
    extends [mscorlib]System.Object
{
    .field assembly int32 Failures
    .field assembly string DisabledReason
    .method assembly hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.CachePolicy
    extends [mscorlib]System.Object
{
    .field private static initonly object gate
    .field private static initonly class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> entries

    .method private specialname rtspecialname static void .cctor() cil managed
    {
        .maxstack 1
        newobj instance void [mscorlib]System.Object::.ctor()
        stsfld object FolderMap.CachePolicy::gate
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
        stsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
        ret
    }

    .method public hidebysig static string Key(string rootPath, string cacheDirectory) cil managed
    {
        .maxstack 3
        ldarg.1
        call string [mscorlib]System.IO.Path::GetFullPath(string)
        ldstr "\n"
        ldarg.0
        call string FolderMap.Scanner::Normalize(string)
        call string [mscorlib]System.String::Concat(string, string, string)
        ret
    }

    .method public hidebysig static string BypassReason(string key) cil managed
    {
        .maxstack 3
        .locals init (bool locked, class FolderMap.CachePolicyEntry state, string reason)
        .try
        {
            ldsfld object FolderMap.CachePolicy::gate
            ldloca locked
            call void [mscorlib]System.Threading.Monitor::Enter(object, bool&)
            ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
            ldarg.0
            ldloca state
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::TryGetValue(!0, !1&)
            brfalse EMPTY
            ldloc state
            ldfld string FolderMap.CachePolicyEntry::DisabledReason
            stloc reason
        EMPTY:
            leave DONE
        }
        finally
        {
            ldloc locked
            brfalse RELEASED
            ldsfld object FolderMap.CachePolicy::gate
            call void [mscorlib]System.Threading.Monitor::Exit(object)
        RELEASED:
            endfinally
        }
    DONE:
        ldloc reason
        ret
    }

    .method public hidebysig static void RecordOutcome(
        string key, bool considered, int64 reusedDirectories, string reason) cil managed
    {
        .maxstack 4
        .locals init (bool locked, class FolderMap.CachePolicyEntry state)
        ldarg.2
        ldc.i4.0
        conv.i8
        bge VALID
        ldstr "reusedDirectories"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID:
        .try
        {
            ldsfld object FolderMap.CachePolicy::gate
            ldloca locked
            call void [mscorlib]System.Threading.Monitor::Enter(object, bool&)
            ldarg.2
            ldc.i4.0
            conv.i8
            ble NO_REUSE
            ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
            ldarg.0
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::Remove(!0)
            pop
            leave DONE
        NO_REUSE:
            ldarg.1
            brtrue COUNT_ATTEMPT
            leave DONE
        COUNT_ATTEMPT:
            ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
            ldarg.0
            ldloca state
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::TryGetValue(!0, !1&)
            brtrue FOUND
            newobj instance void FolderMap.CachePolicyEntry::.ctor()
            stloc state
            ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
            ldarg.0
            ldloc state
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::Add(!0, !1)
        FOUND:
            ldloc state
            ldfld int32 FolderMap.CachePolicyEntry::Failures
            ldc.i4.2
            bge DISABLE
            ldloc state
            dup
            ldfld int32 FolderMap.CachePolicyEntry::Failures
            ldc.i4.1
            add
            stfld int32 FolderMap.CachePolicyEntry::Failures
            ldloc state
            ldfld int32 FolderMap.CachePolicyEntry::Failures
            ldc.i4.2
            bge DISABLE
            leave DONE
        DISABLE:
            ldloc state
            ldstr "Two consecutive cache attempts reused no directories. Last result: "
            ldarg.3
            call string [mscorlib]System.String::Concat(string, string)
            stfld string FolderMap.CachePolicyEntry::DisabledReason
            leave DONE
        }
        finally
        {
            ldloc locked
            brfalse RELEASED
            ldsfld object FolderMap.CachePolicy::gate
            call void [mscorlib]System.Threading.Monitor::Exit(object)
        RELEASED:
            endfinally
        }
    DONE:
        ret
    }

    .method public hidebysig static void Reset(string key) cil managed
    {
        .maxstack 2
        .locals init (bool locked)
        .try
        {
            ldsfld object FolderMap.CachePolicy::gate
            ldloca locked
            call void [mscorlib]System.Threading.Monitor::Enter(object, bool&)
            ldsfld class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry> FolderMap.CachePolicy::entries
            ldarg.0
            callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, class FolderMap.CachePolicyEntry>::Remove(!0)
            pop
            leave DONE
        }
        finally
        {
            ldloc locked
            brfalse RELEASED
            ldsfld object FolderMap.CachePolicy::gate
            call void [mscorlib]System.Threading.Monitor::Exit(object)
        RELEASED:
            endfinally
        }
    DONE:
        ret
    }
}
