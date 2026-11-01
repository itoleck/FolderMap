.class public abstract sealed auto ansi beforefieldinit FolderMap.CacheTree
    extends [mscorlib]System.Object
{
    .method private hidebysig static void Invalid(string detail) cil managed
    {
        .maxstack 1
        ldarg.0
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string)
        throw
    }

    .method private hidebysig static void Poll(
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 1
        ldarg.0
        brfalse DONE
        ldarg.0
        call void FolderMap.Scanner::CheckCancellation(class [System]System.ComponentModel.BackgroundWorker)
    DONE:
        ret
    }

    .method private hidebysig static void ValidateName(string component) cil managed
    {
        .maxstack 3
        .locals init (int32 pos, int32 ch, int32 dot, string stem)
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue BAD
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4 255
        bgt BAD
        ldarg.0
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.1
        sub
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc ch
        ldloc ch
        ldc.i4.s 32
        beq BAD
        ldloc ch
        ldc.i4.s 46
        beq BAD
        ldc.i4.0
        stloc pos
        br CHAR_TEST
    CHAR_LOOP:
        ldarg.0
        ldloc pos
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc ch
        ldloc ch
        ldc.i4.s 32
        blt BAD
        ldstr "<>:\"/\\|?*"
        ldloc ch
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        ldc.i4.0
        bge BAD
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    CHAR_TEST:
        ldloc pos
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        blt CHAR_LOOP
        ldarg.0
        ldc.i4.s 46
        callvirt instance int32 [mscorlib]System.String::IndexOf(char)
        stloc dot
        ldarg.0
        stloc stem
        ldloc dot
        ldc.i4.0
        blt STEM_READY
        ldarg.0
        ldc.i4.0
        ldloc dot
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc stem
    STEM_READY:
        ldloc stem
        callvirt instance string [mscorlib]System.String::ToUpperInvariant()
        stloc stem
        ldloc stem
        ldstr "CON"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        ldstr "PRN"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        ldstr "AUX"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        ldstr "NUL"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        ldstr "CONIN$"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        ldstr "CONOUT$"
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue BAD
        ldloc stem
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.4
        bne.un DONE
        ldloc stem
        ldstr "COM"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brtrue PORT_NAME
        ldloc stem
        ldstr "LPT"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse DONE
    PORT_NAME:
        ldloc stem
        ldc.i4.3
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc ch
        ldloc ch
        ldc.i4.s 49
        blt SPECIAL_DIGIT
        ldloc ch
        ldc.i4.s 57
        ble BAD
    SPECIAL_DIGIT:
        ldloc ch
        ldc.i4 185
        beq BAD
        ldloc ch
        ldc.i4 178
        beq BAD
        ldloc ch
        ldc.i4 179
        beq BAD
    DONE:
        ret
    BAD:
        ldstr "A cache directory name must be a safe, nonempty Windows name component."
        call void FolderMap.CacheTree::Invalid(string)
        ret
    }

    .method assembly hidebysig static void ValidateDirectory(
        class FolderMap.CacheDirectory item) cil managed
    {
        .maxstack 2
        .locals init (int32 pos)
        ldarg.0
        brfalse BAD
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectBytes
        ldc.i4.0
        conv.i8
        blt BAD
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectFiles
        ldc.i4.0
        conv.i8
        blt BAD
        ldarg.0
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        ldc.i4.0
        blt BAD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        brfalse BAD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        brfalse BAD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldarg.0
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        bgt BAD
        ldarg.0
        ldfld uint64 FolderMap.CacheDirectory::FileId
        brtrue ID_OK
        ldarg.0
        ldfld bool FolderMap.CacheDirectory::Retry
        brtrue ID_OK
        ldarg.0
        ldfld bool FolderMap.CacheDirectory::Reparse
        brfalse BAD
    ID_OK:
        ldarg.0
        ldfld bool FolderMap.CacheDirectory::Reparse
        brfalse ISSUE_TEST
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectBytes
        brtrue BAD
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectFiles
        brtrue BAD
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<uint64>::get_Count()
        brtrue BAD
        br ISSUE_TEST
    ISSUE_LOOP:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        brfalse BAD
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    ISSUE_TEST:
        ldloc pos
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        blt ISSUE_LOOP
        ret
    BAD:
        ldstr "The cache contains a null directory/list, invalid identity, negative counts, or nonempty reparse directory."
        call void FolderMap.CacheTree::Invalid(string)
        ret
    }

    // Normalize lexically, without drive-current-directory state or legacy MAX_PATH APIs.
    .method private hidebysig static string NormalizeRoot(string rootPath) cil managed
    {
        .maxstack 5
        .locals init (
            string text, string prefix, string server, string share,
            string component, string normalized, int32 offset, int32 start,
            int32 serverEnd, int32 shareEnd, int32 pos, int32 ch,
            string[] pieces,
            class [mscorlib]System.Collections.Generic.List`1<string> components)
        ldarg.0
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue BAD
        ldarg.0
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4 32766
        bgt TOO_LONG
        ldarg.0
        ldc.i4.s 47
        ldc.i4.s 92
        callvirt instance string [mscorlib]System.String::Replace(char, char)
        stloc text
        ldloc text
        ldstr "\\\\?\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse ORDINARY_ROOT
        ldc.i4.4
        stloc offset
        ldloc text
        ldstr "\\\\?\\UNC\\"
        ldc.i4.5
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse DRIVE_ROOT
        ldc.i4.8
        stloc offset
        br UNC_ROOT
    ORDINARY_ROOT:
        ldloc text
        ldstr "\\\\"
        ldc.i4.4
        callvirt instance bool [mscorlib]System.String::StartsWith(string, valuetype [mscorlib]System.StringComparison)
        brfalse DRIVE_ROOT
        ldc.i4.2
        stloc offset
    UNC_ROOT:
        ldloc text
        ldc.i4.s 92
        ldloc offset
        callvirt instance int32 [mscorlib]System.String::IndexOf(char, int32)
        stloc serverEnd
        ldloc serverEnd
        ldloc offset
        ble BAD
        ldloc text
        ldc.i4.s 92
        ldloc serverEnd
        ldc.i4.1
        add.ovf
        callvirt instance int32 [mscorlib]System.String::IndexOf(char, int32)
        stloc shareEnd
        ldloc shareEnd
        ldc.i4.0
        bge HAVE_SHARE_END
        ldloc text
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc shareEnd
    HAVE_SHARE_END:
        ldloc text
        ldloc offset
        ldloc serverEnd
        ldloc offset
        sub.ovf
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc server
        ldloc text
        ldloc serverEnd
        ldc.i4.1
        add.ovf
        ldloc shareEnd
        ldloc serverEnd
        sub.ovf
        ldc.i4.1
        sub.ovf
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        stloc share
        ldloc server
        call void FolderMap.CacheTree::ValidateName(string)
        ldloc share
        call void FolderMap.CacheTree::ValidateName(string)
        ldstr "\\\\"
        stloc prefix
        ldloc offset
        ldc.i4.8
        bne.un UNC_PREFIX_READY
        ldstr "\\\\?\\UNC\\"
        stloc prefix
    UNC_PREFIX_READY:
        ldloc prefix
        ldloc server
        ldstr "\\"
        ldloc share
        call string [mscorlib]System.String::Concat(string, string, string, string)
        ldstr "\\"
        call string [mscorlib]System.String::Concat(string, string)
        stloc prefix
        ldloc shareEnd
        stloc start
        ldloc start
        ldloc text
        callvirt instance int32 [mscorlib]System.String::get_Length()
        bge SPLIT
        ldloc start
        ldc.i4.1
        add.ovf
        stloc start
        br SPLIT
    DRIVE_ROOT:
        ldloc text
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldloc offset
        ldc.i4.3
        add.ovf
        blt BAD
        ldloc text
        ldloc offset
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        stloc ch
        ldloc ch
        ldc.i4.s 65
        blt BAD
        ldloc ch
        ldc.i4.s 90
        ble DRIVE_LETTER_OK
        ldloc ch
        ldc.i4.s 97
        blt BAD
        ldloc ch
        ldc.i4.s 122
        bgt BAD
    DRIVE_LETTER_OK:
        ldloc text
        ldloc offset
        ldc.i4.1
        add.ovf
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 58
        bne.un BAD
        ldloc text
        ldloc offset
        ldc.i4.2
        add.ovf
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 92
        bne.un BAD
        ldloc text
        ldloc offset
        ldc.i4.1
        callvirt instance string [mscorlib]System.String::Substring(int32, int32)
        callvirt instance string [mscorlib]System.String::ToUpperInvariant()
        ldstr ":\\"
        call string [mscorlib]System.String::Concat(string, string)
        stloc prefix
        ldloc offset
        brfalse DRIVE_PREFIX_READY
        ldstr "\\\\?\\"
        ldloc prefix
        call string [mscorlib]System.String::Concat(string, string)
        stloc prefix
    DRIVE_PREFIX_READY:
        ldloc offset
        ldc.i4.3
        add.ovf
        stloc start
    SPLIT:
        ldloc text
        ldloc start
        callvirt instance string [mscorlib]System.String::Substring(int32)
        ldc.i4.1
        newarr [mscorlib]System.Char
        dup
        ldc.i4.0
        ldc.i4.s 92
        stelem.i2
        callvirt instance string[] [mscorlib]System.String::Split(char[])
        stloc pieces
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()
        stloc components
        br COMPONENT_TEST
    COMPONENT_LOOP:
        ldloc pieces
        ldloc pos
        ldelem.ref
        stloc component
        ldloc component
        callvirt instance int32 [mscorlib]System.String::get_Length()
        brfalse NEXT_COMPONENT
        ldloc component
        ldstr "."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brtrue NEXT_COMPONENT
        ldloc component
        ldstr ".."
        call bool [mscorlib]System.String::op_Equality(string, string)
        brfalse NORMAL_COMPONENT
        ldloc components
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        brfalse BAD
        ldloc components
        ldloc components
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldc.i4.1
        sub.ovf
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::RemoveAt(int32)
        br NEXT_COMPONENT
    NORMAL_COMPONENT:
        ldloc component
        call void FolderMap.CacheTree::ValidateName(string)
        ldloc components
        ldloc component
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
    NEXT_COMPONENT:
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    COMPONENT_TEST:
        ldloc pos
        ldloc pieces
        ldlen
        conv.i4
        blt COMPONENT_LOOP
        ldloc prefix
        ldstr "\\"
        ldloc components
        callvirt instance !0[] class [mscorlib]System.Collections.Generic.List`1<string>::ToArray()
        call string [mscorlib]System.String::Join(string, string[])
        call string [mscorlib]System.String::Concat(string, string)
        stloc normalized
        ldloc normalized
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4 32766
        bgt TOO_LONG
        ldloc normalized
        ret
    BAD:
        ldstr "The cache root must be an absolute drive or UNC directory path without device names or anchor traversal."
        call void FolderMap.CacheTree::Invalid(string)
        ldnull
        ret
    TOO_LONG:
        ldstr "A cache path exceeds the 32766-character limit."
        call void FolderMap.CacheTree::Invalid(string)
        ldnull
        ret
    }

    .method public hidebysig static class [mscorlib]System.Collections.Generic.List`1<string>
        Paths(class FolderMap.CacheSnapshot snapshot) cil managed
    {
        .maxstack 2
        ldarg.0
        ldnull
        call class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheTree::BuildPaths(
            class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
        ret
    }

    .method private hidebysig static class [mscorlib]System.Collections.Generic.List`1<string>
        BuildPaths(class FolderMap.CacheSnapshot snapshot,
            class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 4
        .locals init (
            class [mscorlib]System.Collections.Generic.List`1<string> paths,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> dirs,
            class [mscorlib]System.Collections.Generic.Dictionary`2<int32, class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>> siblings,
            class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool> names,
            class FolderMap.CacheDirectory item,
            string root, string path, string parentPath,
            int32[] lengths,
            int32 pos, int32 parentIndex, int32 separator, int32 pathLength)
        ldarg.1
        call void FolderMap.CacheTree::Poll(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        brtrue SNAPSHOT_OK
        ldstr "snapshot"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    SNAPSHOT_OK:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        stloc dirs
        ldloc dirs
        brfalse BAD_SHAPE
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        brfalse BAD_SHAPE
        ldarg.0
        ldfld string FolderMap.CacheSnapshot::RootPath
        call string FolderMap.CacheTree::NormalizeRoot(string)
        stloc root
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        newarr [mscorlib]System.Int32
        stloc lengths
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<int32, class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>>::.ctor()
        stloc siblings
        br LOOP_TEST
    LOOP:
        ldarg.1
        call void FolderMap.CacheTree::Poll(class [System]System.ComponentModel.BackgroundWorker)
        ldloc dirs
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc item
        ldloc item
        call void FolderMap.CacheTree::ValidateDirectory(class FolderMap.CacheDirectory)
        ldloc item
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        stloc parentIndex
        ldloc pos
        brtrue CHILD
        ldloc parentIndex
        ldc.i4.m1
        bne.un BAD_SHAPE
        ldloc root
        callvirt instance int32 [mscorlib]System.String::get_Length()
        stloc pathLength
        br STORE_LENGTH
    CHILD:
        ldloc parentIndex
        ldc.i4.0
        blt BAD_SHAPE
        ldloc parentIndex
        ldloc pos
        bge BAD_SHAPE
        ldloc dirs
        ldloc parentIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        ldfld bool FolderMap.CacheDirectory::Reparse
        brtrue BAD_SHAPE
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        call void FolderMap.CacheTree::ValidateName(string)
        ldloc siblings
        ldloc parentIndex
        ldloca names
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<int32, class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>>::TryGetValue(!0, !1&)
        brtrue HAVE_NAMES
        call class [mscorlib]System.StringComparer [mscorlib]System.StringComparer::get_Ordinal()
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::.ctor(class [mscorlib]System.Collections.Generic.IEqualityComparer`1<!0>)
        stloc names
        ldloc siblings
        ldloc parentIndex
        ldloc names
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<int32, class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>>::Add(!0, !1)
    HAVE_NAMES:
        ldloc names
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::ContainsKey(!0)
        brtrue BAD_SHAPE
        ldloc names
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        ldc.i4.1
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<string, bool>::Add(!0, !1)
        ldc.i4.1
        stloc separator
        ldloc parentIndex
        brtrue LENGTH
        ldloc root
        ldloc root
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.1
        sub.ovf
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 92
        bne.un LENGTH
        ldc.i4.0
        stloc separator
    LENGTH:
        ldloc lengths
        ldloc parentIndex
        ldelem.i4
        ldloc separator
        add.ovf
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        callvirt instance int32 [mscorlib]System.String::get_Length()
        add.ovf
        stloc pathLength
        ldloc pathLength
        ldc.i4 32766
        bgt TOO_LONG
    STORE_LENGTH:
        ldloc lengths
        ldloc pos
        ldloc pathLength
        stelem.i4
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    LOOP_TEST:
        ldloc pos
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        blt LOOP
        // Complete the length/shape preflight before allocating any descendant paths.
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(int32)
        stloc paths
        ldloc paths
        ldloc root
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
        ldc.i4.1
        stloc pos
        br MATERIALIZE_TEST
    MATERIALIZE_LOOP:
        ldarg.1
        call void FolderMap.CacheTree::Poll(class [System]System.ComponentModel.BackgroundWorker)
        ldloc dirs
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc item
        ldloc paths
        ldloc item
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        stloc parentPath
        ldloc parentPath
        ldloc parentPath
        callvirt instance int32 [mscorlib]System.String::get_Length()
        ldc.i4.1
        sub.ovf
        callvirt instance char [mscorlib]System.String::get_Chars(int32)
        ldc.i4.s 92
        beq NO_SEPARATOR
        ldloc parentPath
        ldstr "\\"
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc path
        br ADD_PATH
    NO_SEPARATOR:
        ldloc parentPath
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        call string [mscorlib]System.String::Concat(string, string)
        stloc path
    ADD_PATH:
        ldloc paths
        ldloc path
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    MATERIALIZE_TEST:
        ldloc pos
        ldloc dirs
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Count()
        blt MATERIALIZE_LOOP
        ldloc paths
        ret
    BAD_SHAPE:
        ldstr "The cache must contain one root and unique ordinal siblings in parent-before-child order; reparse nodes cannot have children."
        call void FolderMap.CacheTree::Invalid(string)
        ldnull
        ret
    TOO_LONG:
        ldstr "A cumulative cache path exceeds the 32766-character limit."
        call void FolderMap.CacheTree::Invalid(string)
        ldnull
        ret
    }

    .method public hidebysig static class FolderMap.CacheDirectory CopyDirectory(
        class FolderMap.CacheDirectory source, int32 parentIndex) cil managed
    {
        .maxstack 2
        .locals init (class FolderMap.CacheDirectory copy)
        ldarg.0
        brtrue SOURCE_OK
        ldstr "source"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    SOURCE_OK:
        ldarg.0
        call void FolderMap.CacheTree::ValidateDirectory(class FolderMap.CacheDirectory)
        ldarg.1
        ldc.i4.m1
        bge PARENT_OK
        ldstr "A copied directory parent index cannot be less than -1."
        call void FolderMap.CacheTree::Invalid(string)
    PARENT_OK:
        newobj instance void FolderMap.CacheDirectory::.ctor()
        stloc copy
        ldloc copy
        ldarg.1
        stfld int32 FolderMap.CacheDirectory::ParentIndex
        ldloc copy
        ldarg.0
        ldfld string FolderMap.CacheDirectory::Name
        stfld string FolderMap.CacheDirectory::Name
        ldloc copy
        ldarg.0
        ldfld uint64 FolderMap.CacheDirectory::FileId
        stfld uint64 FolderMap.CacheDirectory::FileId
        ldloc copy
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectBytes
        stfld int64 FolderMap.CacheDirectory::DirectBytes
        ldloc copy
        ldarg.0
        ldfld int64 FolderMap.CacheDirectory::DirectFiles
        stfld int64 FolderMap.CacheDirectory::DirectFiles
        ldloc copy
        ldarg.0
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        stfld int32 FolderMap.CacheDirectory::DirectIssueCount
        ldloc copy
        ldarg.0
        ldfld bool FolderMap.CacheDirectory::Retry
        stfld bool FolderMap.CacheDirectory::Retry
        ldloc copy
        ldarg.0
        ldfld bool FolderMap.CacheDirectory::Reparse
        stfld bool FolderMap.CacheDirectory::Reparse
        ldloc copy
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
        stfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldloc copy
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<uint64>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)
        stfld class [mscorlib]System.Collections.Generic.List`1<uint64> FolderMap.CacheDirectory::LinkedFiles
        ldloc copy
        ret
    }

    // Check additions before delegating aggregation/sorting to the shared scanner.
    .method private hidebysig static void AggregateChecked(class FolderMap.FolderNode node) cil managed
    {
        .maxstack 3
        .locals init (
            int64 bytes, int64 files, int64 folders, int32 issues, int32 pos,
            class FolderMap.FolderNode child)
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectBytes
        stloc bytes
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectFiles
        stloc files
        ldarg.0
        ldfld int32 FolderMap.FolderNode::IssueCount
        stloc issues
        br LOOP_TEST
    LOOP:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        ldloc bytes
        ldloc child
        ldfld int64 FolderMap.FolderNode::TotalBytes
        add.ovf
        stloc bytes
        ldloc files
        ldloc child
        ldfld int64 FolderMap.FolderNode::TotalFiles
        add.ovf
        stloc files
        ldloc issues
        ldloc child
        ldfld int32 FolderMap.FolderNode::IssueCount
        add.ovf
        stloc issues
        ldloc folders
        ldloc child
        ldfld int64 FolderMap.FolderNode::FolderCount
        add.ovf
        ldc.i4.1
        conv.i8
        add.ovf
        stloc folders
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    LOOP_TEST:
        ldloc pos
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt LOOP
        ldarg.0
        call void FolderMap.Scanner::Aggregate(class FolderMap.FolderNode)
        ret
    }

    .method public hidebysig static class FolderMap.ScanResult ToResult(
        class FolderMap.CacheSnapshot snapshot,
        class [System]System.ComponentModel.BackgroundWorker worker) cil managed
    {
        .maxstack 3
        .locals init (
            class [mscorlib]System.Collections.Generic.List`1<string> paths,
            class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> nodes,
            class FolderMap.ScanResult result,
            class FolderMap.CacheDirectory item,
            class FolderMap.FolderNode node, class FolderMap.FolderNode parent,
            int32 pos, int32 parentIndex, int32 issuePos)
        ldarg.0
        ldarg.1
        call class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheTree::BuildPaths(
            class FolderMap.CacheSnapshot, class [System]System.ComponentModel.BackgroundWorker)
        stloc paths
        ldloc paths
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        newobj instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::.ctor(int32)
        stloc nodes
        br NODE_TEST
    NODE_LOOP:
        ldarg.1
        call void FolderMap.CacheTree::Poll(class [System]System.ComponentModel.BackgroundWorker)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory> FolderMap.CacheSnapshot::Directories
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.CacheDirectory>::get_Item(int32)
        stloc item
        ldloc item
        ldfld int32 FolderMap.CacheDirectory::ParentIndex
        stloc parentIndex
        ldnull
        stloc parent
        ldloc parentIndex
        ldc.i4.0
        blt PARENT_READY
        ldloc nodes
        ldloc parentIndex
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc parent
    PARENT_READY:
        ldloc paths
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        ldloc parent
        newobj instance void FolderMap.FolderNode::.ctor(string, class FolderMap.FolderNode)
        stloc node
        ldloc node
        ldloc item
        ldfld int64 FolderMap.CacheDirectory::DirectBytes
        stfld int64 FolderMap.FolderNode::DirectBytes
        ldloc node
        ldloc item
        ldfld int64 FolderMap.CacheDirectory::DirectFiles
        stfld int64 FolderMap.FolderNode::DirectFiles
        ldloc node
        ldloc item
        ldfld int32 FolderMap.CacheDirectory::DirectIssueCount
        stfld int32 FolderMap.FolderNode::IssueCount
        ldloc parent
        brfalse ROOT_NODE
        ldloc node
        ldloc item
        ldfld string FolderMap.CacheDirectory::Name
        stfld string FolderMap.FolderNode::Name
        ldloc parent
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc node
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Add(!0)
        br ADD_NODE
    ROOT_NODE:
        ldloc node
        newobj instance void FolderMap.ScanResult::.ctor(class FolderMap.FolderNode)
        stloc result
    ADD_NODE:
        ldloc nodes
        ldloc node
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::Add(!0)
        ldc.i4.0
        stloc issuePos
        br ISSUE_TEST
    ISSUE_LOOP:
        ldloc result
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        ldloc item
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        ldloc issuePos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<string>::get_Item(int32)
        callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)
        ldloc issuePos
        ldc.i4.1
        add.ovf
        stloc issuePos
    ISSUE_TEST:
        ldloc result
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        ldc.i4 200
        bge NEXT_NODE
        ldloc issuePos
        ldloc item
        ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.CacheDirectory::Issues
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        blt ISSUE_LOOP
    NEXT_NODE:
        ldloc pos
        ldc.i4.1
        add.ovf
        stloc pos
    NODE_TEST:
        ldloc pos
        ldloc paths
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<string>::get_Count()
        blt NODE_LOOP
        ldloc nodes
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        ldc.i4.1
        sub.ovf
        stloc pos
        br AGGREGATE_TEST
    AGGREGATE_LOOP:
        ldarg.1
        call void FolderMap.CacheTree::Poll(class [System]System.ComponentModel.BackgroundWorker)
        ldloc nodes
        ldloc pos
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        call void FolderMap.CacheTree::AggregateChecked(class FolderMap.FolderNode)
        ldloc pos
        ldc.i4.1
        sub.ovf
        stloc pos
    AGGREGATE_TEST:
        ldloc pos
        ldc.i4.0
        bge AGGREGATE_LOOP
        ldloc result
        ldloc result
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld int32 FolderMap.FolderNode::IssueCount
        stfld int32 FolderMap.ScanResult::IssueCount
        ldloc result
        ret
    }
}
