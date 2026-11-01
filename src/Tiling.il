.class public abstract auto ansi sealed beforefieldinit FolderMap.AlternativeLayouts
    extends [mscorlib]System.Object
{
    .method private hidebysig static void CheckComponent(float32 coordinate, string component) cil managed
    {
        .maxstack 2
        ldarg.0
        call bool [mscorlib]System.Single::IsNaN(float32)
        brtrue Component_Invalid
        ldarg.0
        call bool [mscorlib]System.Single::IsInfinity(float32)
        brtrue Component_Invalid
        ldarg.0
        ldc.r4 0.0
        blt Component_Invalid
        ret
    Component_Invalid:
        ldarg.1
        ldstr "Bounds components must be finite and nonnegative."
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string, string)
        throw
    }

    .method private hidebysig static int64 Validate(
        class [mscorlib]System.Collections.ArrayList items,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds) cil managed
    {
        .maxstack 3
        .locals init (int32 index, int32 count, int64 total, class FolderMap.Tile tile, int64 weight)
        ldarg.0
        brtrue Validate_Bounds
        ldstr "items"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    Validate_Bounds:
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_X()
        ldstr "bounds.X"
        call void FolderMap.AlternativeLayouts::CheckComponent(float32, string)
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Y()
        ldstr "bounds.Y"
        call void FolderMap.AlternativeLayouts::CheckComponent(float32, string)
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        ldstr "bounds.Width"
        call void FolderMap.AlternativeLayouts::CheckComponent(float32, string)
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        ldstr "bounds.Height"
        call void FolderMap.AlternativeLayouts::CheckComponent(float32, string)
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_X()
        conv.r8
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        conv.r8
        add
        ldc.r8 3.4028234663852886e38
        bgt Validate_EdgeInvalid
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Y()
        conv.r8
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        conv.r8
        add
        ldc.r8 3.4028234663852886e38
        bgt Validate_EdgeInvalid
        ldarg.0
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        stloc.1
        br Validate_Test
    Validate_Loop:
        ldarg.0
        ldloc.0
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        isinst FolderMap.Tile
        stloc.3
        ldloc.3
        brtrue Validate_Weight
        ldstr "Every item must be a non-null FolderMap.Tile."
        ldstr "items"
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string, string)
        throw
    Validate_Weight:
        ldloc.3
        ldfld int64 FolderMap.Tile::Bytes
        stloc.s weight
        ldloc.s weight
        ldc.i4.0
        conv.i8
        bgt Validate_Add
        ldstr "items"
        ldstr "Tile weights must be positive."
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string, string)
        throw
    Validate_Add:
        ldloc.2
        ldloc.s weight
        add.ovf
        stloc.2
        ldloc.0
        ldc.i4.1
        add
        stloc.0
    Validate_Test:
        ldloc.0
        ldloc.1
        blt Validate_Loop
        ldloc.2
        ret
    Validate_EdgeInvalid:
        ldstr "bounds"
        ldstr "The right and bottom edges must be finite RectangleF coordinates."
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string, string)
        throw
    }

    // Bruls' worst aspect, factored into dimensionless ratios rather than squared areas.
    .method private hidebysig static float64 Worst(
        int64 rowWeight, int64 minimum, int64 maximum, int64 remainingWeight,
        float64 shortSide, float64 longSide) cil managed
    {
        .maxstack 4
        .locals init (float64 scale)
        ldarg.s longSide
        ldarg.s shortSide
        div
        ldarg.0
        conv.r8
        ldarg.3
        conv.r8
        div
        mul
        stloc.0
        ldloc.0
        ldarg.0
        conv.r8
        ldarg.1
        conv.r8
        div
        mul
        ldarg.2
        conv.r8
        ldarg.0
        conv.r8
        div
        ldloc.0
        div
        call float64 [mscorlib]System.Math::Max(float64, float64)
        ret
    }

    .method private hidebysig static float32 FiniteExtent(float64 length, float32 origin) cil managed
    {
        .maxstack 2
        .locals init (float32 extent)
        ldarg.0
        conv.r4
        stloc.0
        ldarg.1
        ldloc.0
        add
        conv.r4
        call bool [mscorlib]System.Single::IsInfinity(float32)
        brtrue Extent_RoundedOverflow
        ldloc.0
        ret
    Extent_RoundedOverflow:
        // Independently rounded origin and extent can overflow even a valid viewport's far edge.
        ldc.r8 3.4028234663852886e38
        ldarg.1
        conv.r8
        sub
        conv.r4
        ret
    }

    .method private hidebysig static void SetBounds(
        class FolderMap.Tile tile, valuetype [System.Drawing]System.Drawing.RectangleF viewport,
        float64 left, float64 top, float64 right, float64 bottom) cil managed
    {
        .maxstack 7
        .locals init (float32 x, float32 y)
        // Keep spans viewport-relative: subtracting large absolute coordinates loses small areas.
        ldarga.s viewport
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_X()
        conv.r8
        ldarg.2
        add
        conv.r4
        stloc.0
        ldarga.s viewport
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Y()
        conv.r8
        ldarg.3
        add
        conv.r4
        stloc.1
        ldarg.0
        ldloc.0
        ldloc.1
        ldarg.s right
        ldarg.2
        sub
        ldloc.0
        call float32 FolderMap.AlternativeLayouts::FiniteExtent(float64, float32)
        ldarg.s bottom
        ldarg.3
        sub
        ldloc.1
        call float32 FolderMap.AlternativeLayouts::FiniteExtent(float64, float32)
        newobj instance void [System.Drawing]System.Drawing.RectangleF::.ctor(float32, float32, float32, float32)
        stfld valuetype [System.Drawing]System.Drawing.RectangleF FolderMap.Tile::Bounds
        ret
    }

    .method private hidebysig static void Strip(
        class [mscorlib]System.Collections.ArrayList items, int32 startIndex, int32 endIndex,
        int64 total, bool columns, valuetype [System.Drawing]System.Drawing.RectangleF viewport,
        float64 left, float64 top, float64 right, float64 bottom) cil managed
    {
        .maxstack 6
        .locals init (
            int32 index, int64 prefix, float64 origin, float64 limit, float64 extent,
            float64 cursor, float64 next, class FolderMap.Tile tile)
        ldarg.1
        stloc.0
        ldarg.s columns
        brfalse Strip_Horizontal
        ldarg.s left
        stloc.2
        ldarg.s right
        stloc.3
        br Strip_Start
    Strip_Horizontal:
        ldarg.s top
        stloc.2
        ldarg.s bottom
        stloc.3
    Strip_Start:
        ldloc.3
        ldloc.2
        sub
        stloc.s extent
        ldloc.2
        stloc.s cursor
        br Strip_Test
    Strip_Loop:
        ldarg.0
        ldloc.0
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        stloc.s tile
        ldloc.1
        ldloc.s tile
        ldfld int64 FolderMap.Tile::Bytes
        add.ovf
        stloc.1
        ldloc.0
        ldc.i4.1
        add
        ldarg.2
        beq Strip_Last
        ldloc.2
        ldloc.s extent
        ldloc.1
        conv.r8
        ldarg.3
        conv.r8
        div
        mul
        add
        ldloc.s cursor
        call float64 [mscorlib]System.Math::Max(float64, float64)
        ldloc.3
        call float64 [mscorlib]System.Math::Min(float64, float64)
        stloc.s next
        br Strip_Assign
    Strip_Last:
        ldloc.3
        stloc.s next
    Strip_Assign:
        ldarg.s columns
        brfalse Strip_AssignHorizontal
        ldloc.s tile
        ldarg.s viewport
        ldloc.s cursor
        ldarg.s top
        ldloc.s next
        ldarg.s bottom
        call void FolderMap.AlternativeLayouts::SetBounds(
            class FolderMap.Tile, valuetype [System.Drawing]System.Drawing.RectangleF,
            float64, float64, float64, float64)
        br Strip_Advance
    Strip_AssignHorizontal:
        ldloc.s tile
        ldarg.s viewport
        ldarg.s left
        ldloc.s cursor
        ldarg.s right
        ldloc.s next
        call void FolderMap.AlternativeLayouts::SetBounds(
            class FolderMap.Tile, valuetype [System.Drawing]System.Drawing.RectangleF,
            float64, float64, float64, float64)
    Strip_Advance:
        ldloc.s next
        stloc.s cursor
        ldloc.0
        ldc.i4.1
        add
        stloc.0
    Strip_Test:
        ldloc.0
        ldarg.2
        blt Strip_Loop
        ret
    }

    .method public hidebysig static void SliceAndDice(
        class [mscorlib]System.Collections.ArrayList items,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds, int32 depth) cil managed
    {
        .maxstack 10
        .locals init (int64 total, int32 count)
        ldarg.2
        ldc.i4.0
        bge Slice_Validate
        ldstr "depth"
        ldstr "Depth must be nonnegative."
        newobj instance void [mscorlib]System.ArgumentOutOfRangeException::.ctor(string, string)
        throw
    Slice_Validate:
        ldarg.0
        ldarg.1
        call int64 FolderMap.AlternativeLayouts::Validate(
            class [mscorlib]System.Collections.ArrayList, valuetype [System.Drawing]System.Drawing.RectangleF)
        stloc.0
        ldarg.0
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        stloc.1
        ldloc.1
        brfalse Slice_Done
        ldarg.0
        ldc.i4.0
        ldloc.1
        ldloc.0
        ldarg.2
        ldc.i4.1
        and
        ldc.i4.0
        ceq
        ldarg.1
        ldc.r8 0.0
        ldc.r8 0.0
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        conv.r8
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        conv.r8
        call void FolderMap.AlternativeLayouts::Strip(
            class [mscorlib]System.Collections.ArrayList, int32, int32, int64, bool,
            valuetype [System.Drawing]System.Drawing.RectangleF, float64, float64, float64, float64)
    Slice_Done:
        ret
    }

    .method public hidebysig static void Squarified(
        class [mscorlib]System.Collections.ArrayList items,
        valuetype [System.Drawing]System.Drawing.RectangleF bounds) cil managed
    {
        .maxstack 10
        .locals init (
            int64 remaining, int32 count, int32 startIndex, int32 endIndex,
            float64 left, float64 top, float64 right, float64 bottom,
            float64 width, float64 height, bool wide, float64 shortSide, float64 longSide,
            int64 rowWeight, int64 minimum, int64 maximum, float64 best,
            int64 candidateWeight, int64 candidateMinimum, int64 candidateMaximum,
            int64 weight, float64 candidateWorst, float64 split)
        ldarg.0
        ldarg.1
        call int64 FolderMap.AlternativeLayouts::Validate(
            class [mscorlib]System.Collections.ArrayList, valuetype [System.Drawing]System.Drawing.RectangleF)
        stloc.0
        ldarg.0
        callvirt instance int32 [mscorlib]System.Collections.ArrayList::get_Count()
        stloc.1
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Width()
        conv.r8
        stloc.s right
        ldarga.s bounds
        call instance float32 [System.Drawing]System.Drawing.RectangleF::get_Height()
        conv.r8
        stloc.s bottom
        br Square_Test
    Square_Loop:
        ldloc.s right
        ldloc.s left
        sub
        stloc.s width
        ldloc.s bottom
        ldloc.s top
        sub
        stloc.s height
        ldloc.s width
        ldloc.s height
        clt
        ldc.i4.0
        ceq
        stloc.s wide
        ldloc.s width
        ldc.r8 0.0
        beq Square_Degenerate
        ldloc.s height
        ldc.r8 0.0
        beq Square_Degenerate
        ldloc.s wide
        brfalse Square_Tall
        ldloc.s height
        stloc.s shortSide
        ldloc.s width
        stloc.s longSide
        br Square_First
    Square_Tall:
        ldloc.s width
        stloc.s shortSide
        ldloc.s height
        stloc.s longSide
    Square_First:
        ldarg.0
        ldloc.2
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        ldfld int64 FolderMap.Tile::Bytes
        stloc.s rowWeight
        ldloc.s rowWeight
        stloc.s minimum
        ldloc.s rowWeight
        stloc.s maximum
        ldloc.2
        ldc.i4.1
        add
        stloc.3
        ldloc.s rowWeight
        ldloc.s minimum
        ldloc.s maximum
        ldloc.0
        ldloc.s shortSide
        ldloc.s longSide
        call float64 FolderMap.AlternativeLayouts::Worst(int64, int64, int64, int64, float64, float64)
        stloc.s best
        br Square_CandidateTest
    Square_Candidate:
        ldarg.0
        ldloc.3
        callvirt instance object [mscorlib]System.Collections.ArrayList::get_Item(int32)
        castclass FolderMap.Tile
        ldfld int64 FolderMap.Tile::Bytes
        stloc.s weight
        ldloc.s rowWeight
        ldloc.s weight
        add.ovf
        stloc.s candidateWeight
        ldloc.s minimum
        ldloc.s weight
        call int64 [mscorlib]System.Math::Min(int64, int64)
        stloc.s candidateMinimum
        ldloc.s maximum
        ldloc.s weight
        call int64 [mscorlib]System.Math::Max(int64, int64)
        stloc.s candidateMaximum
        ldloc.s candidateWeight
        ldloc.s candidateMinimum
        ldloc.s candidateMaximum
        ldloc.0
        ldloc.s shortSide
        ldloc.s longSide
        call float64 FolderMap.AlternativeLayouts::Worst(int64, int64, int64, int64, float64, float64)
        stloc.s candidateWorst
        ldloc.s candidateWorst
        ldloc.s best
        bgt Square_Emit
        ldloc.s candidateWeight
        stloc.s rowWeight
        ldloc.s candidateMinimum
        stloc.s minimum
        ldloc.s candidateMaximum
        stloc.s maximum
        ldloc.s candidateWorst
        stloc.s best
        ldloc.3
        ldc.i4.1
        add
        stloc.3
    Square_CandidateTest:
        ldloc.3
        ldloc.1
        blt Square_Candidate
    Square_Emit:
        ldloc.s wide
        brfalse Square_EmitRow
        ldloc.s right
        stloc.s split
        ldloc.3
        ldloc.1
        beq Square_ColumnReady
        ldloc.s left
        ldloc.s width
        ldloc.s rowWeight
        conv.r8
        ldloc.0
        conv.r8
        div
        mul
        add
        ldloc.s left
        call float64 [mscorlib]System.Math::Max(float64, float64)
        ldloc.s right
        call float64 [mscorlib]System.Math::Min(float64, float64)
        stloc.s split
    Square_ColumnReady:
        ldarg.0
        ldloc.2
        ldloc.3
        ldloc.s rowWeight
        ldc.i4.0
        ldarg.1
        ldloc.s left
        ldloc.s top
        ldloc.s split
        ldloc.s bottom
        call void FolderMap.AlternativeLayouts::Strip(
            class [mscorlib]System.Collections.ArrayList, int32, int32, int64, bool,
            valuetype [System.Drawing]System.Drawing.RectangleF, float64, float64, float64, float64)
        ldloc.s split
        stloc.s left
        br Square_Advance
    Square_EmitRow:
        ldloc.s bottom
        stloc.s split
        ldloc.3
        ldloc.1
        beq Square_RowReady
        ldloc.s top
        ldloc.s height
        ldloc.s rowWeight
        conv.r8
        ldloc.0
        conv.r8
        div
        mul
        add
        ldloc.s top
        call float64 [mscorlib]System.Math::Max(float64, float64)
        ldloc.s bottom
        call float64 [mscorlib]System.Math::Min(float64, float64)
        stloc.s split
    Square_RowReady:
        ldarg.0
        ldloc.2
        ldloc.3
        ldloc.s rowWeight
        ldc.i4.1
        ldarg.1
        ldloc.s left
        ldloc.s top
        ldloc.s right
        ldloc.s split
        call void FolderMap.AlternativeLayouts::Strip(
            class [mscorlib]System.Collections.ArrayList, int32, int32, int64, bool,
            valuetype [System.Drawing]System.Drawing.RectangleF, float64, float64, float64, float64)
        ldloc.s split
        stloc.s top
    Square_Advance:
        ldloc.0
        ldloc.s rowWeight
        sub.ovf
        stloc.0
        ldloc.3
        stloc.2
    Square_Test:
        ldloc.2
        ldloc.1
        blt Square_Loop
        ret
    Square_Degenerate:
        // A representable remainder can collapse to zero after a near-Int64.MaxValue tile.
        ldarg.0
        ldloc.2
        ldloc.1
        ldloc.0
        ldloc.s wide
        ldc.i4.0
        ceq
        ldarg.1
        ldloc.s left
        ldloc.s top
        ldloc.s right
        ldloc.s bottom
        call void FolderMap.AlternativeLayouts::Strip(
            class [mscorlib]System.Collections.ArrayList, int32, int32, int64, bool,
            valuetype [System.Drawing]System.Drawing.RectangleF, float64, float64, float64, float64)
        ret
    }
}
