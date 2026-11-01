.class public auto ansi sealed beforefieldinit FolderMap.Tile
    extends [mscorlib]System.Object
    implements [mscorlib]System.IComparable
{
    .field public class FolderMap.FolderNode Folder
    .field public bool DirectFiles
    .field public int64 Bytes
    .field public int32 Depth
    .field public valuetype [System.Drawing]System.Drawing.RectangleF Bounds

    .method public hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.FolderNode folder, bool direct, int32 depth) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldarg.0
        ldarg.2
        stfld bool FolderMap.Tile::DirectFiles
        ldarg.0
        ldarg.3
        stfld int32 FolderMap.Tile::Depth
        ldarg.0
        ldarg.2
        brfalse FOLDER_BYTES
        ldarg.1
        ldfld int64 FolderMap.FolderNode::DirectBytes
        br STORE_BYTES
    FOLDER_BYTES:
        ldarg.1
        ldfld int64 FolderMap.FolderNode::TotalBytes
    STORE_BYTES:
        stfld int64 FolderMap.Tile::Bytes
        ret
    }

    .method public hidebysig newslot virtual final instance int32 CompareTo(object other) cil managed
    {
        .maxstack 2
        .locals init (class FolderMap.Tile tile, int32 order)
        ldarg.1
        castclass FolderMap.Tile
        stloc tile
        ldloc tile
        ldflda int64 FolderMap.Tile::Bytes
        ldarg.0
        ldfld int64 FolderMap.Tile::Bytes
        call instance int32 [mscorlib]System.Int64::CompareTo(int64)
        stloc order
        ldloc order
        brtrue RETURN_ORDER
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldfld string FolderMap.FolderNode::Name
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldfld string FolderMap.FolderNode::Name
        call int32 [mscorlib]System.String::CompareOrdinal(string, string)
        ret
    RETURN_ORDER:
        ldloc order
        ret
    }
}

.class private auto ansi sealed beforefieldinit FolderMap.LayoutFrame
    extends [mscorlib]System.Object
{
    .field public class FolderMap.FolderNode Folder
    .field public valuetype [System.Drawing]System.Drawing.RectangleF Bounds
    .field public int32 Depth

    .method public hidebysig specialname rtspecialname instance void .ctor(
        class FolderMap.FolderNode folder,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds,
        int32 depth) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldarg.0
        ldarg.2
        stfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        ldarg.0
        ldarg.3
        stfld int32 FolderMap.LayoutFrame::Depth
        ret
    }
}

.class private auto ansi sealed beforefieldinit FolderMap.Partition
    extends [mscorlib]System.Object
{
    .field public int32 First
    .field public int32 Count
    .field public int64 Bytes
    .field public valuetype [System.Drawing]System.Drawing.RectangleF Bounds

    .method public hidebysig specialname rtspecialname instance void .ctor(
        int32 first, int32 count, int64 bytes,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds) cil managed
    {
        .maxstack 2
        ldarg.0
        call instance void [mscorlib]System.Object::.ctor()
        ldarg.0
        ldarg.1
        stfld int32 FolderMap.Partition::First
        ldarg.0
        ldarg.2
        stfld int32 FolderMap.Partition::Count
        ldarg.0
        ldarg.3
        stfld int64 FolderMap.Partition::Bytes
        ldarg.0
        ldarg.s bounds
        stfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.TreemapLayout
    extends [mscorlib]System.Object
{
    .method public hidebysig static class [mscorlib]System.Collections.ArrayList Build(
        class FolderMap.FolderNode root,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds) cil managed
    {
        .maxstack 3
        ldarg.0
        ldarg.1
        ldc.i4.0
        call class [mscorlib]System.Collections.ArrayList FolderMap.TreemapLayout::Build(class FolderMap.FolderNode, valuetype [System.Drawing]System.Drawing.RectangleF, valuetype FolderMap.TreemapAlgorithm)
        ret
    }

    // Every tiler shares the same iterative nesting, captions, and hit-test tiles.
    .method public hidebysig static class [mscorlib]System.Collections.ArrayList Build(
        class FolderMap.FolderNode root,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds,
        valuetype FolderMap.TreemapAlgorithm layoutMode) cil managed
    {
        .maxstack 10
        .locals init (
            class [mscorlib]System.Collections.ArrayList output,
            class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame> folders,
            class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition> partitions,
            class FolderMap.LayoutFrame frame,
            class FolderMap.Partition part,
            class [mscorlib]System.Collections.ArrayList items,
            class FolderMap.FolderNode child,
            class FolderMap.Tile tile,
            int32 index,
            int32 leftCount,
            int64 leftBytes,
            int64 nextBytes,
            int64 half,
            float32 x, float32 y, float32 width, float32 height, float32 extent,
            valuetype [System.Drawing]System.Drawing.RectangleF firstBounds,
            valuetype [System.Drawing]System.Drawing.RectangleF secondBounds
        )

        ldarg.0
        brtrue VALID_ROOT
        ldstr "root"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    VALID_ROOT:
        ldarg.2
        ldc.i4.2
        ble.un VALID_ALGORITHM
        ldstr "layoutMode"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID_ALGORITHM:
        newobj instance void [mscorlib]System.Collections.ArrayList::.ctor()
        stloc output
        newobj instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame>::.ctor()
        stloc folders
        newobj instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::.ctor()
        stloc partitions
        ldloc folders
        ldarg.0
        ldarg.1
        ldc.i4.0
        newobj instance void FolderMap.LayoutFrame::.ctor(class FolderMap.FolderNode, valuetype [System.Drawing]System.Drawing.RectangleF, int32)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame>::Push(!0)
        br NEXT_FOLDER

    FOLDER:
        ldloc folders
        callvirt instance !0 class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame>::Pop()
        stloc frame
        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldfld int64 FolderMap.FolderNode::TotalBytes
        ldc.i4.0
        conv.i8
        ble NEXT_FOLDER
        ldloc frame
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        ldc.r4 1
        blt.un NEXT_FOLDER
        ldloc frame
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        ldc.r4 1
        blt.un NEXT_FOLDER
        newobj instance void [mscorlib]System.Collections.ArrayList::.ctor()
        stloc items
        ldc.i4.0
        stloc index
        br NEXT_CHILD

    CHILD:
        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        stloc child
        ldloc child
        ldfld int64 FolderMap.FolderNode::TotalBytes
        ldc.i4.0
        conv.i8
        ble SKIP_CHILD
        ldloc items
        ldloc child
        ldc.i4.0
        ldloc frame
        ldfld int32 FolderMap.LayoutFrame::Depth
        newobj instance void FolderMap.Tile::.ctor(class FolderMap.FolderNode, bool, int32)
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::Add(object)
        pop
    SKIP_CHILD:
        ldloc index
        ldc.i4.1
        add
        stloc index
    NEXT_CHILD:
        ldloc index
        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt CHILD

        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldfld int64 FolderMap.FolderNode::DirectBytes
        ldc.i4.0
        conv.i8
        ble HAVE_ITEMS
        ldloc items
        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldc.i4.1
        ldloc frame
        ldfld int32 FolderMap.LayoutFrame::Depth
        newobj instance void FolderMap.Tile::.ctor(class FolderMap.FolderNode, bool, int32)
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::Add(object)
        pop
    HAVE_ITEMS:
        ldloc items
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        brfalse NEXT_FOLDER
        ldloc items
        callvirt instance void [mscorlib]System.Collections.ArrayList::Sort()
        ldarg.2
        brfalse BINARY
        ldarg.2
        ldc.i4.1
        bne.un SLICE_AND_DICE
        ldloc items
        ldloc frame
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        call void FolderMap.AlternativeLayouts::Squarified(class [mscorlib]System.Collections.ArrayList, valuetype [System.Drawing]System.Drawing.RectangleF)
        br ASSIGNED
    SLICE_AND_DICE:
        ldloc items
        ldloc frame
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        ldloc frame
        ldfld int32 FolderMap.LayoutFrame::Depth
        call void FolderMap.AlternativeLayouts::SliceAndDice(class [mscorlib]System.Collections.ArrayList, valuetype [System.Drawing]System.Drawing.RectangleF, int32)
    ASSIGNED:
        ldloc items
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        ldc.i4.1
        sub
        stloc index
    ASSIGNED_ITEM:
        ldloc items
        ldloc index
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        stloc tile
        ldloc partitions
        ldloc index
        ldc.i4.1
        ldloc tile
        ldfld int64 FolderMap.Tile::Bytes
        ldloc tile
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Tile::Bounds
        newobj instance void FolderMap.Partition::.ctor(int32, int32, int64, valuetype [System.Drawing]System.Drawing.RectangleF)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::Push(!0)
        ldloc index
        ldc.i4.1
        sub
        stloc index
        ldloc index
        ldc.i4.0
        bge ASSIGNED_ITEM
        br NEXT_PART
    BINARY:
        ldloc partitions
        ldc.i4.0
        ldloc items
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        ldloc frame
        ldfld class FolderMap.FolderNode FolderMap.LayoutFrame::Folder
        ldfld int64 FolderMap.FolderNode::TotalBytes
        ldloc frame
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.LayoutFrame::Bounds
        newobj instance void FolderMap.Partition::.ctor(int32, int32, int64, valuetype [System.Drawing]System.Drawing.RectangleF)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::Push(!0)
        br NEXT_PART

    PART:
        ldloc partitions
        callvirt instance !0 class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::Pop()
        stloc part
        ldloc part
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_X()
        stloc x
        ldloc part
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Y()
        stloc y
        ldloc part
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        stloc width
        ldloc part
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        stloc height
        ldloc width
        ldc.r4 1
        blt.un NEXT_PART
        ldloc height
        ldc.r4 1
        blt.un NEXT_PART
        ldloc part
        ldfld int32 FolderMap.Partition::Count
        ldc.i4.1
        bne.un SPLIT
        ldloc items
        ldloc part
        ldfld int32 FolderMap.Partition::First
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        stloc tile
        ldloc tile
        ldloc part
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Partition::Bounds
        stfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Tile::Bounds
        ldloc output
        ldloc tile
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::Add(object)
        pop
        ldloc tile
        ldfld bool FolderMap.Tile::DirectFiles
        brtrue NEXT_PART
        ldloc width
        ldc.r4 12
        ble NEXT_PART
        ldloc height
        ldc.r4 32
        ble NEXT_PART
        ldloc folders
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldloc x
        ldc.r4 3
        add
        ldloc y
        ldc.r4 22
        add
        ldloc width
        ldc.r4 6
        sub
        ldloc height
        ldc.r4 25
        sub
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        ldloc frame
        ldfld int32 FolderMap.LayoutFrame::Depth
        ldc.i4.1
        add
        newobj instance void FolderMap.LayoutFrame::.ctor(class FolderMap.FolderNode, valuetype [System.Drawing]System.Drawing.RectangleF, int32)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame>::Push(!0)
        br NEXT_PART

    SPLIT:
        ldc.i4.1
        stloc leftCount
        ldloc items
        ldloc part
        ldfld int32 FolderMap.Partition::First
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        ldfld int64 FolderMap.Tile::Bytes
        stloc leftBytes
        ldloc part
        ldfld int64 FolderMap.Partition::Bytes
        ldc.i4.2
        conv.i8
        div
        stloc half
        br BALANCE_TEST
    BALANCE:
        ldloc items
        ldloc part
        ldfld int32 FolderMap.Partition::First
        ldloc leftCount
        add
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        ldfld int64 FolderMap.Tile::Bytes
        stloc nextBytes
        ldloc half
        ldloc leftBytes
        ldloc nextBytes
        add.ovf
        sub
        call int64 [mscorlib]System.Math::Abs(int64)
        ldloc half
        ldloc leftBytes
        sub
        call int64 [mscorlib]System.Math::Abs(int64)
        bgt BALANCED
        ldloc leftBytes
        ldloc nextBytes
        add.ovf
        stloc leftBytes
        ldloc leftCount
        ldc.i4.1
        add
        stloc leftCount
    BALANCE_TEST:
        ldloc leftCount
        ldloc part
        ldfld int32 FolderMap.Partition::Count
        ldc.i4.1
        sub
        bge BALANCED
        ldloc leftBytes
        ldloc half
        blt BALANCE
    BALANCED:
        ldloc width
        ldloc height
        blt HORIZONTAL
        ldloc width
        conv.r8
        ldloc leftBytes
        conv.r8
        mul
        ldloc part
        ldfld int64 FolderMap.Partition::Bytes
        conv.r8
        div
        conv.r4
        stloc extent
        ldloc x
        ldloc y
        ldloc extent
        ldloc height
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        stloc firstBounds
        ldloc x
        ldloc extent
        add
        ldloc y
        ldloc width
        ldloc extent
        sub
        ldloc height
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        stloc secondBounds
        br PUSH_PARTS
    HORIZONTAL:
        ldloc height
        conv.r8
        ldloc leftBytes
        conv.r8
        mul
        ldloc part
        ldfld int64 FolderMap.Partition::Bytes
        conv.r8
        div
        conv.r4
        stloc extent
        ldloc x
        ldloc y
        ldloc width
        ldloc extent
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        stloc firstBounds
        ldloc x
        ldloc y
        ldloc extent
        add
        ldloc width
        ldloc height
        ldloc extent
        sub
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        stloc secondBounds
    PUSH_PARTS:
        ldloc partitions
        ldloc part
        ldfld int32 FolderMap.Partition::First
        ldloc leftCount
        add
        ldloc part
        ldfld int32 FolderMap.Partition::Count
        ldloc leftCount
        sub
        ldloc part
        ldfld int64 FolderMap.Partition::Bytes
        ldloc leftBytes
        sub
        ldloc secondBounds
        newobj instance void FolderMap.Partition::.ctor(int32, int32, int64, valuetype [System.Drawing]System.Drawing.RectangleF)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::Push(!0)
        ldloc partitions
        ldloc part
        ldfld int32 FolderMap.Partition::First
        ldloc leftCount
        ldloc leftBytes
        ldloc firstBounds
        newobj instance void FolderMap.Partition::.ctor(int32, int32, int64, valuetype [System.Drawing]System.Drawing.RectangleF)
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::Push(!0)
    NEXT_PART:
        ldloc partitions
        callvirt instance int32 class [System]System.Collections.Generic.Stack`1<class FolderMap.Partition>::get_Count()
        brtrue PART
    NEXT_FOLDER:
        ldloc folders
        callvirt instance int32 class [System]System.Collections.Generic.Stack`1<class FolderMap.LayoutFrame>::get_Count()
        brtrue FOLDER
        ldloc output
        ret
    }

    .method public hidebysig static class FolderMap.Tile HitTest(
        class [mscorlib]System.Collections.ArrayList tiles, float32 x, float32 y) cil managed
    {
        .maxstack 3
        .locals init (int32 index, class FolderMap.Tile tile)
        ldarg.0
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        ldc.i4.1
        sub
        stloc index
        br CHECK
    ITEM:
        ldarg.0
        ldloc index
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        stloc tile
        ldloc tile
        ldflda valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Tile::Bounds
        ldarg.1
        ldarg.2
        call instance bool [System.Drawing]System.Drawing.RectangleF::Contains(float32, float32)
        brfalse NEXT
        ldloc tile
        ret
    NEXT:
        ldloc index
        ldc.i4.1
        sub
        stloc index
    CHECK:
        ldloc index
        ldc.i4.0
        bge ITEM
        ldnull
        ret
    }
}

.class public abstract sealed auto ansi beforefieldinit FolderMap.Display
    extends [mscorlib]System.Object
{
    .method public hidebysig static string Elapsed(int64 milliseconds) cil managed
    {
        .maxstack 3
        .locals init (float64 seconds)
        ldarg.0
        ldc.i4.0
        conv.i8
        bge VALID
        ldstr "milliseconds"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID:
        ldarg.0
        conv.r8
        ldc.r8 1000
        div
        stloc seconds
        ldloca seconds
        ldstr "0.000"
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.Double::ToString(string, class [mscorlib]System.IFormatProvider)
        ldstr " s"
        call string [mscorlib]System.String::Concat(string, string)
        ret
    }

    .method public hidebysig static string CacheModeLabel(valuetype FolderMap.ScanCacheMode mode) cil managed
    {
        .maxstack 1
        ldarg.0
        switch (CHECKING, FULL, CACHED)
        ldstr "mode"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    CHECKING:
        ldstr "Checking cache"
        ret
    FULL:
        ldstr "Full scan (cache not used)"
        ret
    CACHED:
        ldstr "Using cache"
        ret
    }

    .method public hidebysig static string Number(int64 bytes) cil managed
    {
        .maxstack 3
        ldarga.s bytes
        ldstr "N0"
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.Int64::ToString(string, class [mscorlib]System.IFormatProvider)
        ret
    }

    .method public hidebysig static string Compact(int64 bytes) cil managed
    {
        .maxstack 4
        .locals init (float64 size, int32 unit, string[] units)
        ldc.i4.7
        newarr [mscorlib]System.String
        dup
        ldc.i4.0
        ldstr "B"
        stelem.ref
        dup
        ldc.i4.1
        ldstr "KiB"
        stelem.ref
        dup
        ldc.i4.2
        ldstr "MiB"
        stelem.ref
        dup
        ldc.i4.3
        ldstr "GiB"
        stelem.ref
        dup
        ldc.i4.4
        ldstr "TiB"
        stelem.ref
        dup
        ldc.i4.5
        ldstr "PiB"
        stelem.ref
        dup
        ldc.i4.6
        ldstr "EiB"
        stelem.ref
        stloc units
        ldarg.0
        conv.r8
        stloc size
        ldc.i4.0
        stloc unit
        br CHECK_SIZE
    DIVIDE:
        ldloc size
        ldc.r8 1024
        div
        stloc size
        ldloc unit
        ldc.i4.1
        add
        stloc unit
    CHECK_SIZE:
        ldloc unit
        ldc.i4.6
        bge FORMAT_SIZE
        ldloc size
        ldc.r8 1024
        bge DIVIDE
    FORMAT_SIZE:
        ldloca size
        ldstr "0.##"
        call class [mscorlib]System.Globalization.CultureInfo [mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()
        call instance string [mscorlib]System.Double::ToString(string, class [mscorlib]System.IFormatProvider)
        ldstr " "
        ldloc units
        ldloc unit
        ldelem.ref
        call string [mscorlib]System.String::Concat(string, string, string)
        ret
    }

    .method public hidebysig static string Summary(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 5
        ldstr "{0} bytes ({1})  |  {2} files  |  {3} subfolders  |  {4} skipped/errors"
        ldc.i4.5
        newarr [mscorlib]System.Object
        dup
        ldc.i4.0
        ldarg.0
        ldfld int64 FolderMap.FolderNode::TotalBytes
        call string FolderMap.Display::Number(int64)
        stelem.ref
        dup
        ldc.i4.1
        ldarg.0
        ldfld int64 FolderMap.FolderNode::TotalBytes
        call string FolderMap.Display::Compact(int64)
        stelem.ref
        dup
        ldc.i4.2
        ldarg.0
        ldfld int64 FolderMap.FolderNode::TotalFiles
        call string FolderMap.Display::Number(int64)
        stelem.ref
        dup
        ldc.i4.3
        ldarg.0
        ldfld int64 FolderMap.FolderNode::FolderCount
        call string FolderMap.Display::Number(int64)
        stelem.ref
        dup
        ldc.i4.4
        ldarg.0
        ldfld int32 FolderMap.FolderNode::IssueCount
        conv.i8
        call string FolderMap.Display::Number(int64)
        stelem.ref
        call string [mscorlib]System.String::Format(string, object[])
        ret
    }

    .method public hidebysig static string SelectionDetails(class FolderMap.FolderNode folder, bool directFiles) cil managed
    {
        .maxstack 5
        .locals init (string summary)
        ldarg.1
        brtrue DIRECT
        ldstr "Folder | "
        ldarg.0
        call string FolderMap.Display::Summary(class FolderMap.FolderNode)
        call string [mscorlib]System.String::Concat(string, string)
        stloc summary
        br WITH_PATH
    DIRECT:
        ldstr "[Files here] | {0} bytes ({1}) | {2} files directly in this folder"
        ldc.i4.3
        newarr [mscorlib]System.Object
        dup
        ldc.i4.0
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectBytes
        call string FolderMap.Display::Number(int64)
        stelem.ref
        dup
        ldc.i4.1
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectBytes
        call string FolderMap.Display::Compact(int64)
        stelem.ref
        dup
        ldc.i4.2
        ldarg.0
        ldfld int64 FolderMap.FolderNode::DirectFiles
        call string FolderMap.Display::Number(int64)
        stelem.ref
        call string [mscorlib]System.String::Format(string, object[])
        stloc summary
        ldarg.0
        ldfld int32 FolderMap.FolderNode::IssueCount
        brfalse WITH_PATH
        ldloc summary
        ldstr " | folder tree has skipped/errors"
        call string [mscorlib]System.String::Concat(string, string)
        stloc summary
    WITH_PATH:
        ldloc summary
        ldstr "\r\n"
        ldarg.0
        ldfld string FolderMap.FolderNode::FullPath
        call string [mscorlib]System.String::Concat(string, string, string)
        ret
    }

    .method public hidebysig static string NodeLabel(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 3
        .locals init (string label)
        ldarg.0
        ldfld string FolderMap.FolderNode::Name
        ldstr "   "
        ldarg.0
        ldfld int64 FolderMap.FolderNode::TotalBytes
        call string FolderMap.Display::Number(int64)
        call string [mscorlib]System.String::Concat(string, string, string)
        ldstr " bytes"
        call string [mscorlib]System.String::Concat(string, string)
        stloc label
        ldarg.0
        ldfld int32 FolderMap.FolderNode::IssueCount
        brfalse DONE
        ldloc label
        ldstr " [partial]"
        call string [mscorlib]System.String::Concat(string, string)
        stloc label
    DONE:
        ldloc label
        ret
    }

    .method public hidebysig static valuetype [System.Drawing]System.Drawing.Color ColorFor(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance int32 [mscorlib]System.Object::GetHashCode()
        ldc.i4.7
        and
        switch (BLUE, TEAL, PURPLE, CYAN, ORANGE, GREEN, INDIGO)
        ldc.i4 159
        ldc.i4 65
        ldc.i4 107
        br COLOR
    BLUE:
        ldc.i4 39
        ldc.i4 94
        ldc.i4 156
        br COLOR
    TEAL:
        ldc.i4 15
        ldc.i4 111
        ldc.i4 112
        br COLOR
    PURPLE:
        ldc.i4 109
        ldc.i4 74
        ldc.i4 163
        br COLOR
    CYAN:
        ldc.i4 28
        ldc.i4 105
        ldc.i4 142
        br COLOR
    ORANGE:
        ldc.i4 155
        ldc.i4 85
        ldc.i4 34
        br COLOR
    GREEN:
        ldc.i4 56
        ldc.i4 111
        ldc.i4 70
        br COLOR
    INDIGO:
        ldc.i4 73
        ldc.i4 82
        ldc.i4 159
    COLOR:
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        ret
    }
}

.class public auto ansi beforefieldinit FolderMap.TreemapView
    extends [System.Windows.Forms]System.Windows.Forms.Control
{
    .field public class FolderMap.FolderNode Root
    .field public class FolderMap.FolderNode ActivatedFolder
    .field public class [mscorlib]System.EventHandler FolderActivated
    .field public class FolderMap.Tile SelectedTile
    .field public class [mscorlib]System.EventHandler SelectionChanged
    .field public class FolderMap.Tile ContextTile
    .field public class [System.Windows.Forms]System.Windows.Forms.MouseEventHandler ContextRequested
    .field private class [mscorlib]System.Collections.ArrayList tiles
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolTip tip
    .field private class FolderMap.Tile hovered
    .field private bool dirty
    .field private valuetype FolderMap.TreemapAlgorithm tilingMode
    .field private valuetype FolderMap.ColorScheme colorScheme

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 4
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::.ctor()
        ldarg.0
        ldc.i4 143378
        ldc.i4.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::SetStyle(valuetype [System.Windows.Forms]System.Windows.Forms.ControlStyles, bool)
        ldarg.0
        ldc.i4.s 15
        ldc.i4.s 23
        ldc.i4.s 42
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldstr "Recursive byte-weighted treemap"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_AccessibleName(string)
        ldarg.0
        newobj instance void [mscorlib]System.Collections.ArrayList::.ctor()
        stfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldc.i4 200
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::set_InitialDelay(int32)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldc.i4 15000
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::set_AutoPopDelay(int32)
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.TreemapView::dirty
        ret
    }

    .method public hidebysig specialname instance valuetype FolderMap.TreemapAlgorithm get_Algorithm() cil managed
    {
        .maxstack 1
        ldarg.0
        ldfld valuetype FolderMap.TreemapAlgorithm FolderMap.TreemapView::tilingMode
        ret
    }

    .method public hidebysig specialname instance void set_Algorithm(valuetype FolderMap.TreemapAlgorithm option) cil managed
    {
        .maxstack 2
        ldarg.1
        ldc.i4.2
        ble.un VALID
        ldstr "option"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID:
        ldarg.0
        ldfld valuetype FolderMap.TreemapAlgorithm FolderMap.TreemapView::tilingMode
        ldarg.1
        beq DONE
        ldarg.0
        ldarg.1
        stfld valuetype FolderMap.TreemapAlgorithm FolderMap.TreemapView::tilingMode
        ldarg.0
        call instance void FolderMap.TreemapView::ClearHover()
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.TreemapView::dirty
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::Invalidate()
    DONE:
        ret
    }

    .property instance valuetype FolderMap.TreemapAlgorithm Algorithm()
    {
        .get instance valuetype FolderMap.TreemapAlgorithm FolderMap.TreemapView::get_Algorithm()
        .set instance void FolderMap.TreemapView::set_Algorithm(valuetype FolderMap.TreemapAlgorithm)
    }

    .method public hidebysig specialname instance valuetype FolderMap.ColorScheme get_ColorScheme() cil managed
    {
        .maxstack 1
        ldarg.0
        ldfld valuetype FolderMap.ColorScheme FolderMap.TreemapView::colorScheme
        ret
    }

    .method public hidebysig specialname instance void set_ColorScheme(valuetype FolderMap.ColorScheme scheme) cil managed
    {
        .maxstack 2
        ldarg.1
        ldc.i4.4
        ble.un VALID
        ldstr "scheme"
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string)
        throw
    VALID:
        ldarg.0
        ldfld valuetype FolderMap.ColorScheme FolderMap.TreemapView::colorScheme
        ldarg.1
        beq DONE
        ldarg.0
        ldarg.1
        stfld valuetype FolderMap.ColorScheme FolderMap.TreemapView::colorScheme
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::Invalidate()
    DONE:
        ret
    }

    .property instance valuetype FolderMap.ColorScheme ColorScheme()
    {
        .get instance valuetype FolderMap.ColorScheme FolderMap.TreemapView::get_ColorScheme()
        .set instance void FolderMap.TreemapView::set_ColorScheme(valuetype FolderMap.ColorScheme)
    }

    .method private hidebysig instance void ClearHover() cil managed
    {
        .maxstack 3
        ldarg.0
        ldnull
        stfld class FolderMap.Tile FolderMap.TreemapView::hovered
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldarg.0
        ldstr ""
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::SetToolTip(class [System.Windows.Forms]System.Windows.Forms.Control, string)
        ret
    }

    .method public hidebysig instance void ShowFolder(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 3
        ldarg.0
        ldarg.1
        stfld class FolderMap.FolderNode FolderMap.TreemapView::Root
        ldarg.0
        ldnull
        stfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        ldarg.0
        ldnull
        stfld class FolderMap.Tile FolderMap.TreemapView::ContextTile
        ldarg.0
        call instance void FolderMap.TreemapView::ClearHover()
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.TreemapView::dirty
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::Invalidate()
        ret
    }

    .method family hidebysig virtual instance void OnResize(class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.TreemapView::dirty
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnResize(class [mscorlib]System.EventArgs)
        ret
    }

    .method private hidebysig instance void EnsureLayout() cil managed
    {
        .maxstack 7
        ldarg.0
        ldfld bool FolderMap.TreemapView::dirty
        brfalse DONE
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.TreemapView::Root
        brfalse EMPTY
        ldarg.0
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.TreemapView::Root
        ldc.r4 6
        ldc.r4 6
        ldarg.0
        call instance int32 [System.Windows.Forms]System.Windows.Forms.Control::get_Width()
        ldc.i4.s 12
        sub
        conv.r4
        ldarg.0
        call instance int32 [System.Windows.Forms]System.Windows.Forms.Control::get_Height()
        ldc.i4.s 12
        sub
        conv.r4
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        ldarg.0
        ldfld valuetype FolderMap.TreemapAlgorithm FolderMap.TreemapView::tilingMode
        call class [mscorlib]System.Collections.ArrayList FolderMap.TreemapLayout::Build(class FolderMap.FolderNode, valuetype [System.Drawing]System.Drawing.RectangleF, valuetype FolderMap.TreemapAlgorithm)
        stfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        br CLEAN
    EMPTY:
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        callvirt instance void [mscorlib]System.Collections.ArrayList::Clear()
    CLEAN:
        ldarg.0
        ldc.i4.0
        stfld bool FolderMap.TreemapView::dirty
    DONE:
        ret
    }

    .method family hidebysig virtual instance void OnPaint(class [System.Windows.Forms]System.Windows.Forms.PaintEventArgs e) cil managed
    {
        .maxstack 8
        .locals init (
            class [System.Drawing]System.Drawing.Graphics graphics,
            int32 index,
            class FolderMap.Tile tile,
            class [System.Drawing]System.Drawing.SolidBrush brush,
            valuetype [System.Drawing]System.Drawing.Rectangle rect,
            valuetype [System.Drawing]System.Drawing.Rectangle selectionBounds,
            string text
        )
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnPaint(class [System.Windows.Forms]System.Windows.Forms.PaintEventArgs)
        ldarg.0
        call instance void FolderMap.TreemapView::EnsureLayout()
        ldarg.1
        callvirt instance class [System.Drawing]System.Drawing.Graphics [System.Windows.Forms]System.Windows.Forms.PaintEventArgs::get_Graphics()
        stloc graphics
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        brtrue PAINT_TILES
        ldstr "Choose a folder and click Scan.\r\n\r\nFolder sizes and the recursive treemap will appear here."
        stloc text
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.TreemapView::Root
        brfalse PAINT_EMPTY
        ldstr "No readable file bytes in this folder.\r\n\r\nEmpty folders remain visible in the folder tree.\r\nCheck Skipped / errors if this scan is partial."
        stloc text
    PAINT_EMPTY:
        ldloc graphics
        ldloc text
        ldarg.0
        call instance class [System.Drawing]System.Drawing.Font [System.Windows.Forms]System.Windows.Forms.Control::get_Font()
        ldarg.0
        call instance valuetype [System.Drawing]System.Drawing.Rectangle [System.Windows.Forms]System.Windows.Forms.Control::get_ClientRectangle()
        ldc.i4 148
        ldc.i4 163
        ldc.i4 184
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        ldc.i4 2069
        call void [System.Windows.Forms]System.Windows.Forms.TextRenderer::DrawText(class [System.Drawing]System.Drawing.IDeviceContext, string, class [System.Drawing]System.Drawing.Font, valuetype [System.Drawing]System.Drawing.Rectangle, valuetype [System.Drawing]System.Drawing.Color, valuetype [System.Windows.Forms]System.Windows.Forms.TextFormatFlags)
        ret
    PAINT_TILES:
        ldc.i4.0
        stloc index
        br CHECK_TILE
    PAINT_TILE:
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        ldloc index
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        stloc tile
        ldloc tile
        ldfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Tile::Bounds
        call valuetype [System.Drawing]System.Drawing.Rectangle [System.Drawing]System.Drawing.Rectangle::Round(valuetype [System.Drawing]System.Drawing.RectangleF)
        stloc rect
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldarg.0
        ldfld valuetype FolderMap.ColorScheme FolderMap.TreemapView::colorScheme
        call valuetype [System.Drawing]System.Drawing.Color FolderMap.TileColors::GetColor(class FolderMap.FolderNode, valuetype FolderMap.ColorScheme)
        newobj instance void [System.Drawing]System.Drawing.SolidBrush::.ctor(valuetype [System.Drawing]System.Drawing.Color)
        stloc brush
        .try
        {
            ldloc graphics
            ldloc brush
            ldloc rect
            callvirt instance void [System.Drawing]System.Drawing.Graphics::FillRectangle(class [System.Drawing]System.Drawing.Brush, valuetype [System.Drawing]System.Drawing.Rectangle)
            leave FILLED
        }
        finally
        {
            ldloc brush
            callvirt instance void [System.Drawing]System.Drawing.Brush::Dispose()
            endfinally
        }
    FILLED:
        ldloc graphics
        call class [System.Drawing]System.Drawing.Pen [System.Drawing]System.Drawing.Pens::get_Black()
        ldloc rect
        callvirt instance void [System.Drawing]System.Drawing.Graphics::DrawRectangle(class [System.Drawing]System.Drawing.Pen, valuetype [System.Drawing]System.Drawing.Rectangle)
        ldarg.0
        ldfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        brfalse LABEL
        ldarg.0
        ldfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        bne.un LABEL
        ldarg.0
        ldfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        ldfld bool FolderMap.Tile::DirectFiles
        ldloc tile
        ldfld bool FolderMap.Tile::DirectFiles
        bne.un LABEL
        ldloca rect
        call instance int32 [System.Drawing]System.Drawing.Rectangle::get_Width()
        ldc.i4.4
        blt LABEL
        ldloca rect
        call instance int32 [System.Drawing]System.Drawing.Rectangle::get_Height()
        ldc.i4.4
        blt LABEL
        ldloc rect
        stloc selectionBounds
        ldloca selectionBounds
        ldc.i4.m1
        ldc.i4.m1
        call instance void [System.Drawing]System.Drawing.Rectangle::Inflate(int32, int32)
        ldloc graphics
        call class [System.Drawing]System.Drawing.Pen [System.Drawing]System.Drawing.Pens::get_White()
        ldloc selectionBounds
        callvirt instance void [System.Drawing]System.Drawing.Graphics::DrawRectangle(class [System.Drawing]System.Drawing.Pen, valuetype [System.Drawing]System.Drawing.Rectangle)
    LABEL:
        ldloca rect
        call instance int32 [System.Drawing]System.Drawing.Rectangle::get_Width()
        ldc.i4.s 48
        blt NEXT_TILE
        ldloca rect
        call instance int32 [System.Drawing]System.Drawing.Rectangle::get_Height()
        ldc.i4.s 18
        blt NEXT_TILE
        ldloc tile
        ldfld bool FolderMap.Tile::DirectFiles
        brfalse FOLDER_LABEL
        ldstr "[Files here]  "
        ldloc tile
        ldfld int64 FolderMap.Tile::Bytes
        call string FolderMap.Display::Compact(int64)
        call string [mscorlib]System.String::Concat(string, string)
        stloc text
        br LABEL_BOUNDS
    FOLDER_LABEL:
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldfld string FolderMap.FolderNode::Name
        ldstr "  "
        ldloc tile
        ldfld int64 FolderMap.Tile::Bytes
        call string FolderMap.Display::Compact(int64)
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc text
    LABEL_BOUNDS:
        ldloca rect
        ldc.i4.s -4
        ldc.i4.0
        call instance void [System.Drawing]System.Drawing.Rectangle::Inflate(int32, int32)
        ldloca rect
        ldc.i4.s 20
        call instance void [System.Drawing]System.Drawing.Rectangle::set_Height(int32)
        ldloc graphics
        ldloc text
        ldarg.0
        call instance class [System.Drawing]System.Drawing.Font [System.Windows.Forms]System.Windows.Forms.Control::get_Font()
        ldloc rect
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::get_White()
        ldc.i4 34852
        call void [System.Windows.Forms]System.Windows.Forms.TextRenderer::DrawText(class [System.Drawing]System.Drawing.IDeviceContext, string, class [System.Drawing]System.Drawing.Font, valuetype [System.Drawing]System.Drawing.Rectangle, valuetype [System.Drawing]System.Drawing.Color, valuetype [System.Windows.Forms]System.Windows.Forms.TextFormatFlags)
    NEXT_TILE:
        ldloc index
        ldc.i4.1
        add
        stloc index
    CHECK_TILE:
        ldloc index
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        blt PAINT_TILE
        ret
    }

    .method family hidebysig virtual instance void OnMouseClick(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs e) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.Tile tile)
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnMouseClick(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs)
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 1048576
        beq HIT_TEST
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 2097152
        bne.un DONE
    HIT_TEST:
        ldarg.0
        call instance void FolderMap.TreemapView::EnsureLayout()
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_X()
        conv.r4
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Y()
        conv.r4
        call class FolderMap.Tile FolderMap.TreemapLayout::HitTest(class [mscorlib]System.Collections.ArrayList, float32, float32)
        stloc tile
        ldloc tile
        brfalse DONE
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 2097152
        beq CONTEXT
        ldarg.0
        ldloc tile
        stfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::Invalidate()
        ldarg.0
        ldfld class [mscorlib]System.EventHandler FolderMap.TreemapView::SelectionChanged
        brfalse DONE
        ldarg.0
        ldfld class [mscorlib]System.EventHandler FolderMap.TreemapView::SelectionChanged
        ldarg.0
        ldsfld class [mscorlib]System.EventArgs [mscorlib]System.EventArgs::Empty
        callvirt instance void [mscorlib]System.EventHandler::Invoke(object, class [mscorlib]System.EventArgs)
        br DONE
    CONTEXT:
        ldarg.0
        ldloc tile
        stfld class FolderMap.Tile FolderMap.TreemapView::ContextTile
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.MouseEventHandler FolderMap.TreemapView::ContextRequested
        brfalse DONE
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.MouseEventHandler FolderMap.TreemapView::ContextRequested
        ldarg.0
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.MouseEventHandler::Invoke(object, class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs)
    DONE:
        ret
    }

    .method family hidebysig virtual instance void OnMouseMove(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs e) cil managed
    {
        .maxstack 5
        .locals init (class FolderMap.Tile tile, string text)
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnMouseMove(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs)
        ldarg.0
        call instance void FolderMap.TreemapView::EnsureLayout()
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_X()
        conv.r4
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Y()
        conv.r4
        call class FolderMap.Tile FolderMap.TreemapLayout::HitTest(class [mscorlib]System.Collections.ArrayList, float32, float32)
        stloc tile
        ldloc tile
        ldarg.0
        ldfld class FolderMap.Tile FolderMap.TreemapView::hovered
        beq DONE
        ldarg.0
        ldloc tile
        stfld class FolderMap.Tile FolderMap.TreemapView::hovered
        ldstr ""
        stloc text
        ldloc tile
        brfalse SET_TIP
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldfld string FolderMap.FolderNode::FullPath
        ldstr "\r\n"
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        call string FolderMap.Display::Summary(class FolderMap.FolderNode)
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc text
        ldloc tile
        ldfld bool FolderMap.Tile::DirectFiles
        brfalse TIP_HINT
        ldloc text
        ldstr "\r\nFiles directly here: "
        ldloc tile
        ldfld int64 FolderMap.Tile::Bytes
        call string FolderMap.Display::Number(int64)
        ldstr " bytes (not a subfolder)"
        call string [mscorlib]System.String::Concat(string, string, string, string)
        stloc text
    TIP_HINT:
        ldloc text
        ldstr "\r\nDouble-click to view this folder."
        call string [mscorlib]System.String::Concat(string, string)
        stloc text
    SET_TIP:
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldarg.0
        ldloc text
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::SetToolTip(class [System.Windows.Forms]System.Windows.Forms.Control, string)
    DONE:
        ret
    }

    .method family hidebysig virtual instance void OnMouseLeave(class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 3
        ldarg.0
        ldnull
        stfld class FolderMap.Tile FolderMap.TreemapView::hovered
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        ldarg.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolTip::Hide(class [System.Windows.Forms]System.Windows.Forms.IWin32Window)
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnMouseLeave(class [mscorlib]System.EventArgs)
        ret
    }

    .method family hidebysig virtual instance void OnMouseDoubleClick(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs e) cil managed
    {
        .maxstack 4
        .locals init (class FolderMap.Tile tile)
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnMouseDoubleClick(class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs)
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 1048576
        bne.un DONE
        ldarg.0
        call instance void FolderMap.TreemapView::EnsureLayout()
        ldarg.0
        ldfld class [mscorlib]System.Collections.ArrayList FolderMap.TreemapView::tiles
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_X()
        conv.r4
        ldarg.1
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Y()
        conv.r4
        call class FolderMap.Tile FolderMap.TreemapLayout::HitTest(class [mscorlib]System.Collections.ArrayList, float32, float32)
        stloc tile
        ldloc tile
        brfalse DONE
        ldarg.0
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        stfld class FolderMap.FolderNode FolderMap.TreemapView::ActivatedFolder
        ldarg.0
        ldfld class [mscorlib]System.EventHandler FolderMap.TreemapView::FolderActivated
        brfalse DONE
        ldarg.0
        ldfld class [mscorlib]System.EventHandler FolderMap.TreemapView::FolderActivated
        ldarg.0
        ldsfld class [mscorlib]System.EventArgs [mscorlib]System.EventArgs::Empty
        callvirt instance void [mscorlib]System.EventHandler::Invoke(object, class [mscorlib]System.EventArgs)
    DONE:
        ret
    }

    .method family hidebysig virtual instance void Dispose(bool disposing) cil managed
    {
        .maxstack 2
        ldarg.1
        brfalse BASE
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        brfalse BASE
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolTip FolderMap.TreemapView::tip
        callvirt instance void [System]System.ComponentModel.Component::Dispose()
    BASE:
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::Dispose(bool)
        ret
    }
}
