.class public auto ansi sealed FolderMap.TreemapAlgorithm
    extends [mscorlib]System.Enum
{
    .field public specialname rtspecialname int32 value__
    .field public static literal valuetype FolderMap.TreemapAlgorithm Binary = int32(0)
    .field public static literal valuetype FolderMap.TreemapAlgorithm Squarified = int32(1)
    .field public static literal valuetype FolderMap.TreemapAlgorithm SliceAndDice = int32(2)
}

.class public auto ansi sealed FolderMap.ColorScheme
    extends [mscorlib]System.Enum
{
    .field public specialname rtspecialname int32 value__
    .field public static literal valuetype FolderMap.ColorScheme Classic = int32(0)
    .field public static literal valuetype FolderMap.ColorScheme Ocean = int32(1)
    .field public static literal valuetype FolderMap.ColorScheme Forest = int32(2)
    .field public static literal valuetype FolderMap.ColorScheme Sunset = int32(3)
    .field public static literal valuetype FolderMap.ColorScheme Grayscale = int32(4)
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.TileColors
    extends [mscorlib]System.Object
{
    .method public hidebysig static valuetype [System.Drawing]System.Drawing.Color GetColor(
        class FolderMap.FolderNode folder, valuetype FolderMap.ColorScheme scheme) cil managed
    {
        .maxstack 4
        .locals init (int32 shade)
        ldarg.0
        brtrue CHECK_SCHEME
        ldstr "folder"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    CHECK_SCHEME:
        ldarg.1
        ldc.i4.4
        bgt.un INVALID
        ldarg.1
        brtrue PALETTE
        ldarg.0
        call valuetype [System.Drawing]System.Drawing.Color FolderMap.Display::ColorFor(class FolderMap.FolderNode)
        ret
    PALETTE:
        ldarg.0
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance int32 [mscorlib]System.Object::GetHashCode()
        ldc.i4.7
        and
        stloc shade
        ldarg.1
        ldc.i4.1
        sub
        switch (OCEAN, FOREST, SUNSET, GRAYSCALE)
        br INVALID

    // All eight shades of each palette retain readable white captions.
    OCEAN:
        ldloc shade
        ldc.i4.4
        mul
        ldc.i4.s 20
        add
        ldloc shade
        ldc.i4.7
        mul
        ldc.i4.s 54
        add
        ldloc shade
        ldc.i4.s 9
        mul
        ldc.i4.s 91
        add
        br COLOR
    FOREST:
        ldloc shade
        ldc.i4.5
        mul
        ldc.i4.s 25
        add
        ldloc shade
        ldc.i4.8
        mul
        ldc.i4.s 58
        add
        ldloc shade
        ldc.i4.5
        mul
        ldc.i4.s 35
        add
        br COLOR
    SUNSET:
        ldloc shade
        ldc.i4.s 10
        mul
        ldc.i4.s 101
        add
        ldloc shade
        ldc.i4.7
        mul
        ldc.i4.s 33
        add
        ldloc shade
        ldc.i4.3
        mul
        ldc.i4.s 43
        add
        br COLOR
    GRAYSCALE:
        ldloc shade
        ldc.i4.s 9
        mul
        ldc.i4.s 45
        add
        dup
        dup
    COLOR:
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        ret
    INVALID:
        ldstr "scheme"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    }
}
