param([string]$AssemblyPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 5 -or
    ($PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -ne 'Desktop')) {
    throw 'Run these tests with Windows PowerShell 5.x and .NET Framework, not PowerShell Core.'
}
if (-not [Environment]::Is64BitProcess) {
    throw 'Run these tests in x64 Windows PowerShell.'
}
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
$AssemblyPath = (Resolve-Path -LiteralPath $AssemblyPath).Path
Add-Type -AssemblyName System.Drawing
$assembly = [Reflection.Assembly]::LoadFrom($AssemblyPath)
$layoutType = $assembly.GetType('FolderMap.AlternativeLayouts', $true)

$script:passed = 0
$script:failed = 0
$script:assertions = 0
$script:prepared = 0
$clock = [Diagnostics.Stopwatch]::StartNew()

function Assert-True([bool]$Condition, [string]$Message) {
    $script:assertions++
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Near([double]$Actual, [double]$Expected, [double]$Tolerance, [string]$Message) {
    Assert-True (-not [double]::IsNaN($Actual) -and
        -not [double]::IsInfinity($Actual) -and
        [Math]::Abs($Actual - $Expected) -le $Tolerance) (
        '{0}: expected {1:R}, actual {2:R}, tolerance {3:R}' -f $Message, $Expected, $Actual, $Tolerance)
}

function Assert-Throws([scriptblock]$Action, [type]$ExceptionType) {
    try {
        & $Action
    }
    catch {
        $cause = $_.Exception
        while ($null -ne $cause.InnerException) {
            $cause = $cause.InnerException
        }
        Assert-True ($ExceptionType.IsInstanceOfType($cause)) (
            'Expected {0}, got {1}: {2}' -f $ExceptionType.FullName, $cause.GetType().FullName, $cause.Message)
        return
    }
    throw ('Expected {0}, but the call succeeded.' -f $ExceptionType.FullName)
}

function Invoke-Case([string]$Name, [scriptblock]$Body) {
    try {
        & $Body
        $script:passed++
    }
    catch {
        $script:failed++
        Write-Host ('FAIL: {0}' -f $Name) -ForegroundColor Red
        Write-Host ($_ | Out-String)
        Write-Host $_.ScriptStackTrace
    }
}

function New-Tiles([AllowEmptyCollection()][long[]]$Weights) {
    $items = New-Object System.Collections.ArrayList
    $index = 0
    foreach ($weight in ($Weights | Sort-Object -Descending)) {
        $node = [FolderMap.FolderNode]::new(('synthetic-{0:D5}' -f $index), $null)
        $node.TotalBytes = $weight
        $node.DirectBytes = $weight
        [void]$items.Add([FolderMap.Tile]::new($node, (($index % 2) -eq 0), 0))
        $index++
    }
    return ,$items
}

function Invoke-Layout([string]$Algorithm, [AllowNull()][AllowEmptyCollection()][System.Collections.ArrayList]$Items,
    [System.Drawing.RectangleF]$Bounds) {
    switch ($Algorithm) {
        'Squarified' { [FolderMap.AlternativeLayouts]::Squarified($Items, $Bounds) }
        'SliceEven' { [FolderMap.AlternativeLayouts]::SliceAndDice($Items, $Bounds, 0) }
        'SliceOdd' { [FolderMap.AlternativeLayouts]::SliceAndDice($Items, $Bounds, 1) }
        default { throw "Unknown test algorithm: $Algorithm" }
    }
}

function Get-BoundsKey([System.Drawing.RectangleF]$Bounds) {
    $culture = [Globalization.CultureInfo]::InvariantCulture
    return (($Bounds.X.ToString('R', $culture), $Bounds.Y.ToString('R', $culture),
        $Bounds.Width.ToString('R', $culture), $Bounds.Height.ToString('R', $culture)) -join ',')
}

function Get-WorstAspect([System.Collections.ArrayList]$Items) {
    $worst = 1.0
    foreach ($item in $Items) {
        $r = $item.Bounds
        if ($r.Width -le 0 -or $r.Height -le 0) {
            return [double]::PositiveInfinity
        }
        $worst = [Math]::Max($worst, [Math]::Max(
            [double]$r.Width / [double]$r.Height, [double]$r.Height / [double]$r.Width))
    }
    return $worst
}

function Assert-Layout([AllowEmptyCollection()][System.Collections.ArrayList]$Items,
    [System.Drawing.RectangleF]$Bounds, [string]$Label) {
    $area = [double]$Bounds.Width * [double]$Bounds.Height
    $total = [decimal]0
    foreach ($item in $Items) {
        $total += [decimal]$item.Bytes
    }
    $xTolerance = [Math]::Max(
        ([Math]::Abs([double]$Bounds.X) + [double]$Bounds.Width) * 9.5367431640625e-7,
        [double][single]::Epsilon * 8)
    $yTolerance = [Math]::Max(
        ([Math]::Abs([double]$Bounds.Y) + [double]$Bounds.Height) * 9.5367431640625e-7,
        [double][single]::Epsilon * 8)
    $areaFloor = [double][single]::Epsilon *
        ([double]$Bounds.Width + [double]$Bounds.Height) * 8
    $sum = 0.0
    $widthSum = 0.0
    $heightSum = 0.0
    $rectangles = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $r = $Items[$i].Bounds
        foreach ($value in @($r.X, $r.Y, $r.Width, $r.Height, $r.Right, $r.Bottom)) {
            Assert-True (-not [single]::IsNaN($value) -and -not [single]::IsInfinity($value)) (
                "$Label tile $i has a nonfinite rectangle: $r")
        }
        Assert-True ($r.Width -ge 0 -and $r.Height -ge 0) "$Label tile $i has negative size: $r"
        $left = [double]$r.X
        $top = [double]$r.Y
        $right = $left + [double]$r.Width
        $bottom = $top + [double]$r.Height
        Assert-True ($left -ge [double]$Bounds.X - $xTolerance -and
            $top -ge [double]$Bounds.Y - $yTolerance -and
            $right -le [double]$Bounds.X + [double]$Bounds.Width + $xTolerance -and
            $bottom -le [double]$Bounds.Y + [double]$Bounds.Height + $yTolerance) (
            "$Label tile $i escapes $Bounds : $r")
        $tileArea = [double]$r.Width * [double]$r.Height
        $expected = $area * ([double]$Items[$i].Bytes / [double]$total)
        $tileTolerance = [Math]::Max([Math]::Max($expected * 2e-5, $area * 4e-7), $areaFloor)
        Assert-Near $tileArea $expected $tileTolerance "$Label tile $i area"
        $sum += $tileArea
        $widthSum += [double]$r.Width
        $heightSum += [double]$r.Height
        [void]$rectangles.Add([pscustomobject]@{
            Index = $i; Left = $left; Top = $top; Right = $right; Bottom = $bottom
        })
    }
    if ($Items.Count -eq 0) {
        return
    }
    Assert-Near $sum $area ([Math]::Max($area * 5e-6, $areaFloor)) "$Label total area"
    if ($area -eq 0) {
        return
    }

    # Sweep on the less crowded axis, keeping the 2,048-sibling checks practical in PowerShell.
    $sweepX = $widthSum / [double]$Bounds.Width -le $heightSum / [double]$Bounds.Height
    $axisTolerance = $yTolerance
    $sortProperty = 'Top'
    if ($sweepX) {
        $axisTolerance = $xTolerance
        $sortProperty = 'Left'
    }
    $active = New-Object System.Collections.ArrayList
    foreach ($current in ($rectangles | Sort-Object -Property $sortProperty)) {
        $position = $current.Top
        if ($sweepX) { $position = $current.Left }
        for ($j = $active.Count - 1; $j -ge 0; $j--) {
            $other = $active[$j]
            $end = $other.Bottom
            if ($sweepX) { $end = $other.Right }
            if ($end -le $position + $axisTolerance) {
                $active.RemoveAt($j)
                continue
            }
            $overlapX = [Math]::Min($current.Right, $other.Right) - [Math]::Max($current.Left, $other.Left)
            $overlapY = [Math]::Min($current.Bottom, $other.Bottom) - [Math]::Max($current.Top, $other.Top)
            if ($overlapX -gt $xTolerance -and $overlapY -gt $yTolerance) {
                throw ('{0}: tiles {1} and {2} overlap by {3:R} x {4:R}.' -f
                    $Label, $current.Index, $other.Index, $overlapX, $overlapY)
            }
        }
        [void]$active.Add($current)
    }
    Assert-True $true "$Label has no overlaps"
}

$algorithms = @('Squarified', 'SliceEven', 'SliceOdd')
$ordinary = [System.Drawing.RectangleF]::new(17.25, 29.5, 900.5, 610.25)

Invoke-Case 'Exact public surface and JIT of every declared method' {
    Assert-True ($layoutType.IsAbstract -and $layoutType.IsSealed) 'AlternativeLayouts must be a static class.'
    $public = @($layoutType.GetMethods([Reflection.BindingFlags]'Public,Static,DeclaredOnly'))
    Assert-True ($public.Count -eq 2) 'Exactly two public static methods are expected.'
    $square = $layoutType.GetMethod('Squarified')
    $slice = $layoutType.GetMethod('SliceAndDice')
    Assert-True ($null -ne $square -and $null -ne $slice) 'Both specified public methods must exist.'
    foreach ($method in @($square, $slice)) {
        Assert-True ($method.ReturnType -eq [void]) "$($method.Name) must return void."
        $parameters = $method.GetParameters()
        Assert-True ($parameters[0].ParameterType -eq [System.Collections.ArrayList]) 'ArrayList parameter required.'
        Assert-True ($parameters[1].ParameterType -eq [System.Drawing.RectangleF]) 'RectangleF parameter required.'
    }
    Assert-True ($square.GetParameters().Count -eq 2) 'Squarified must have two parameters.'
    Assert-True ($slice.GetParameters().Count -eq 3 -and
        $slice.GetParameters()[2].ParameterType -eq [int]) 'SliceAndDice requires an Int32 depth.'
    foreach ($method in $layoutType.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Static,DeclaredOnly')) {
        [System.Runtime.CompilerServices.RuntimeHelpers]::PrepareMethod($method.MethodHandle)
        $script:prepared++
    }
}

$fixtures = @(
    @{ Name = 'unequal landscape'; Weights = [long[]]@(500, 300, 100, 70, 30); Bounds = $ordinary },
    @{ Name = 'unequal portrait'; Weights = [long[]]@(500, 300, 100, 70, 30);
        Bounds = [System.Drawing.RectangleF]::new(31.75, 7.125, 410.5, 1200.25) },
    @{ Name = 'fractional square'; Weights = [long[]]@(31, 17, 13, 11, 7, 5, 3, 2, 1);
        Bounds = [System.Drawing.RectangleF]::new(0.125, 0.625, 0.875, 0.875) },
    @{ Name = 'very thin landscape'; Weights = [long[]]@(37, 19, 5, 2, 1);
        Bounds = [System.Drawing.RectangleF]::new(3, 5, 1000000, 0.0001) },
    @{ Name = 'very thin portrait'; Weights = [long[]]@(37, 19, 5, 2, 1);
        Bounds = [System.Drawing.RectangleF]::new(3, 5, 0.0001, 1000000) },
    @{ Name = 'large finite coordinates'; Weights = [long[]]@(9, 7, 5, 3, 1);
        Bounds = [System.Drawing.RectangleF]::new(1e30, 2e30, 7e30, 9e30) },
    @{ Name = 'large origin with small extents'; Weights = [long[]]@(9, 7, 5, 3, 1);
        Bounds = [System.Drawing.RectangleF]::new(1e30, 2e30, 1, 2) },
    @{ Name = 'large finite area'; Weights = [long[]]@(9, 7, 5, 3, 1);
        Bounds = [System.Drawing.RectangleF]::new(1e38, 2e37, 2e38, 1e38) },
    @{ Name = 'extreme dimension ratio'; Weights = [long[]]@(9, 7, 5, 3, 1);
        Bounds = [System.Drawing.RectangleF]::new(0, 0, 1e-35, 1e35) },
    @{ Name = 'single maximum weight'; Weights = [long[]]@([long]::MaxValue); Bounds = $ordinary },
    @{ Name = 'near maximum versus one'; Weights = [long[]]@(([long]::MaxValue - [long]1), 1); Bounds = $ordinary },
    @{ Name = 'near maximum with a small tail';
        Weights = [long[]]@(([long]::MaxValue - [long]1024), 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 1);
        Bounds = $ordinary },
    @{ Name = 'large unequal Int64 weights';
        Weights = [long[]]@(4000000000000000000, 3000000000000000000, 2000000000000000000);
        Bounds = $ordinary },
    @{ Name = 'subnormal dimensions'; Weights = [long[]]@(1);
        Bounds = [System.Drawing.RectangleF]::new(0, 0, [single]::Epsilon, [single]::Epsilon) }
)
foreach ($algorithm in $algorithms) {
    foreach ($fixture in $fixtures) {
        Invoke-Case "$algorithm / $($fixture.Name)" {
            $items = New-Tiles $fixture.Weights
            Invoke-Layout $algorithm $items $fixture.Bounds
            Assert-Layout $items $fixture.Bounds "$algorithm / $($fixture.Name)"
        }
    }
}

Invoke-Case 'Sixteen equal items become sixteen compact squares' {
    $items = New-Tiles ([long[]](1..16 | ForEach-Object { 1 }))
    $bounds = [System.Drawing.RectangleF]::new(7, 11, 400, 400)
    [FolderMap.AlternativeLayouts]::Squarified($items, $bounds)
    Assert-Layout $items $bounds 'equal squares'
    foreach ($item in $items) {
        Assert-Near $item.Bounds.Width 100 0.0001 'equal-square width'
        Assert-Near $item.Bounds.Height 100 0.0001 'equal-square height'
    }
    Assert-Near (Get-WorstAspect $items) 1 0.00001 'equal-square aspect'
}

Invoke-Case 'Greedy row grouping is the Bruls worst-aspect choice' {
    $items = New-Tiles ([long[]]@(6, 6, 4, 3, 2, 2, 1))
    $bounds = [System.Drawing.RectangleF]::new(11, 23, 600, 400)
    [FolderMap.AlternativeLayouts]::Squarified($items, $bounds)
    Assert-Layout $items $bounds 'known greedy grouping'
    Assert-Near $items[0].Bounds.X 11 0.0001 'first column x'
    Assert-Near $items[1].Bounds.X 11 0.0001 'second item remains in first column'
    Assert-Near $items[0].Bounds.Width 300 0.0001 'first column width'
    Assert-Near $items[1].Bounds.Width 300 0.0001 'first column shared width'
    Assert-Near $items[0].Bounds.Height 200 0.0001 'first column first height'
    Assert-Near $items[1].Bounds.Y 223 0.0001 'first column second y'
    Assert-Near $items[2].Bounds.X 311 0.0001 'third item starts a new row'
    Assert-Near $items[2].Bounds.Height (400.0 * 7 / 12) 0.0001 'next row groups weights four and three'
}

Invoke-Case 'Squarification improves worst aspect over slice-and-dice' {
    $weights = [long[]]@(40, 30, 25, 20, 18, 16, 14, 12, 10, 8, 6, 4, 2)
    $bounds = [System.Drawing.RectangleF]::new(0, 0, 720, 480)
    $squares = New-Tiles $weights
    $slices = New-Tiles $weights
    [FolderMap.AlternativeLayouts]::Squarified($squares, $bounds)
    [FolderMap.AlternativeLayouts]::SliceAndDice($slices, $bounds, 0)
    Assert-Layout $squares $bounds 'aspect squarified'
    Assert-Layout $slices $bounds 'aspect slice'
    $squareWorst = Get-WorstAspect $squares
    $sliceWorst = Get-WorstAspect $slices
    Assert-True ($squareWorst -lt $sliceWorst * 0.5) (
        "Expected substantial improvement: squarified=$squareWorst, slice=$sliceWorst")
}

foreach ($algorithm in $algorithms) {
    Invoke-Case "$algorithm / deterministic, identity, order and Bytes preserved" {
        $weights = [long[]]@(97, 83, 61, 61, 43, 29, 17, 7, 2, 1)
        $items = New-Tiles $weights
        $original = @($items.ToArray())
        $originalBytes = @($items | ForEach-Object { $_.Bytes })
        Invoke-Layout $algorithm $items $ordinary
        $keys = @($items | ForEach-Object { Get-BoundsKey $_.Bounds })
        Invoke-Layout $algorithm $items $ordinary
        $fresh = New-Tiles $weights
        Invoke-Layout $algorithm $fresh $ordinary
        Assert-True ($items.Count -eq $original.Count) 'Item count changed.'
        for ($i = 0; $i -lt $items.Count; $i++) {
            Assert-True ([object]::ReferenceEquals($items[$i], $original[$i])) "Identity/order changed at $i."
            Assert-True ($items[$i].Bytes -eq $originalBytes[$i]) "Bytes changed at $i."
            Assert-True ((Get-BoundsKey $items[$i].Bounds) -ceq $keys[$i]) "Repeated layout differs at $i."
            Assert-True ((Get-BoundsKey $fresh[$i].Bounds) -ceq $keys[$i]) "Fresh layout differs at $i."
        }
    }
}

foreach ($depth in @(0, 2, 20, 1, 3, 17, [int]::MaxValue)) {
    Invoke-Case "Slice orientation at depth $depth" {
        $items = New-Tiles ([long[]]@(6, 3, 1))
        $bounds = [System.Drawing.RectangleF]::new(11, 19, 200, 120)
        [FolderMap.AlternativeLayouts]::SliceAndDice($items, $bounds, $depth)
        Assert-Layout $items $bounds "depth $depth"
        $offset = 0.0
        for ($i = 0; $i -lt $items.Count; $i++) {
            $fraction = [double]$items[$i].Bytes / 10
            if (($depth % 2) -eq 0) {
                Assert-Near $items[$i].Bounds.X (11 + $offset * 200) 0.0001 'column x'
                Assert-Near $items[$i].Bounds.Width ($fraction * 200) 0.0001 'column width'
                Assert-Near $items[$i].Bounds.Y 19 0 'column y'
                Assert-Near $items[$i].Bounds.Height 120 0 'column height'
            }
            else {
                Assert-Near $items[$i].Bounds.Y (19 + $offset * 120) 0.0001 'row y'
                Assert-Near $items[$i].Bounds.Height ($fraction * 120) 0.0001 'row height'
                Assert-Near $items[$i].Bounds.X 11 0 'row x'
                Assert-Near $items[$i].Bounds.Width 200 0 'row width'
            }
            $offset += $fraction
        }
        if (($depth % 2) -eq 0) {
            Assert-Near $items[2].Bounds.Right $bounds.Right 0 'last column edge'
        }
        else {
            Assert-Near $items[2].Bounds.Bottom $bounds.Bottom 0 'last row edge'
        }
    }
}

foreach ($algorithm in $algorithms) {
    Invoke-Case "$algorithm / empty list" {
        $items = New-Tiles ([long[]]@())
        Invoke-Layout $algorithm $items $ordinary
        Assert-True ($items.Count -eq 0) 'Empty list changed.'
    }
    foreach ($zero in @(
        [System.Drawing.RectangleF]::new(13, 27, 0, 100),
        [System.Drawing.RectangleF]::new(13, 27, 100, 0),
        [System.Drawing.RectangleF]::new(13, 27, 0, 0))) {
        Invoke-Case "$algorithm / zero-size $zero" {
            $items = New-Tiles ([long[]]@(9, 3, 1))
            Invoke-Layout $algorithm $items $zero
            Assert-Layout $items $zero 'zero-size bounds'
        }
    }
    Invoke-Case "$algorithm / null list" {
        Assert-Throws { Invoke-Layout $algorithm $null $ordinary } ([ArgumentNullException])
    }
    foreach ($invalid in @('null', 'wrong type', 'zero', 'negative', 'minimum', 'overflow')) {
        Invoke-Case "$algorithm / rejects $invalid without mutation" {
            $items = New-Tiles ([long[]]@(7))
            $expectedException = [ArgumentException]
            switch ($invalid) {
                'null' { [void]$items.Add($null) }
                'wrong type' { [void]$items.Add('not a Tile') }
                'zero' { [void]$items.Add((New-Tiles ([long[]]@(0)))[0]); $expectedException = [ArgumentOutOfRangeException] }
                'negative' { [void]$items.Add((New-Tiles ([long[]]@(-1)))[0]); $expectedException = [ArgumentOutOfRangeException] }
                'minimum' { [void]$items.Add((New-Tiles ([long[]]@([long]::MinValue)))[0]); $expectedException = [ArgumentOutOfRangeException] }
                'overflow' {
                    $items = New-Tiles ([long[]]@([long]::MaxValue, 1))
                    $expectedException = [OverflowException]
                }
            }
            $sentinel = [System.Drawing.RectangleF]::new(91, 82, 73, 64)
            foreach ($item in $items) {
                if ($item -is [FolderMap.Tile]) { $item.Bounds = $sentinel }
            }
            Assert-Throws { Invoke-Layout $algorithm $items $ordinary } $expectedException
            foreach ($item in $items) {
                if ($item -is [FolderMap.Tile]) {
                    Assert-True ($item.Bounds.Equals($sentinel)) 'Invalid input caused a partial mutation.'
                }
            }
        }
    }
    foreach ($component in @('X', 'Y', 'Width', 'Height')) {
        foreach ($badValue in @([single]-1, [single]::NaN, [single]::PositiveInfinity, [single]::NegativeInfinity)) {
            Invoke-Case "$algorithm / invalid $component=$badValue" {
                $badBounds = [System.Drawing.RectangleF]::new(1, 2, 3, 4)
                $badBounds.$component = $badValue
                $items = New-Tiles ([long[]]@(3, 2, 1))
                Assert-Throws { Invoke-Layout $algorithm $items $badBounds } ([ArgumentOutOfRangeException])
            }
        }
    }
    foreach ($badBounds in @(
        [System.Drawing.RectangleF]::new([single]::MaxValue, 0, [single]::MaxValue, 1),
        [System.Drawing.RectangleF]::new(0, [single]::MaxValue, 1, [single]::MaxValue))) {
        Invoke-Case "$algorithm / unrepresentable far edge" {
            $items = New-Tiles ([long[]]@(1))
            Assert-Throws { Invoke-Layout $algorithm $items $badBounds } ([ArgumentOutOfRangeException])
        }
    }
}

foreach ($depth in @(-1, [int]::MinValue)) {
    Invoke-Case "Slice rejects negative depth $depth" {
        $items = New-Tiles ([long[]]@(3, 2, 1))
        Assert-Throws { [FolderMap.AlternativeLayouts]::SliceAndDice($items, $ordinary, $depth) } (
            [ArgumentOutOfRangeException])
    }
}

$random = [Random]::new(73129)
for ($sample = 0; $sample -lt 24; $sample++) {
    $count = $random.Next(2, 65)
    $weights = [long[]]::new($count)
    for ($i = 0; $i -lt $count; $i++) {
        $weights[$i] = $random.Next(1, 1000000)
    }
    $bounds = [System.Drawing.RectangleF]::new(
        $random.NextDouble() * 100, $random.NextDouble() * 100,
        1 + $random.NextDouble() * 2048, 1 + $random.NextDouble() * 2048)
    foreach ($algorithm in $algorithms) {
        Invoke-Case "$algorithm / seeded geometry sample $sample" {
            $items = New-Tiles $weights
            Invoke-Layout $algorithm $items $bounds
            Assert-Layout $items $bounds "seeded sample $sample"
        }
    }
}

foreach ($algorithm in $algorithms) {
    Invoke-Case "$algorithm / 2048 sibling stress" {
        $weights = [long[]]::new(2048)
        for ($i = 0; $i -lt $weights.Length; $i++) {
            $weights[$i] = [long](2048 - $i) * [long](2048 - $i) + 1
        }
        $items = New-Tiles $weights
        $bounds = [System.Drawing.RectangleF]::new(13.75, 27.5, 1920, 1080)
        Invoke-Layout $algorithm $items $bounds
        Assert-Layout $items $bounds "$algorithm stress"
    }
}

$clock.Stop()
Write-Host ('Tiling tests: {0} passed, {1} failed; {2} assertions; {3} methods JIT-prepared ({4:N2}s).' -f
    $script:passed, $script:failed, $script:assertions, $script:prepared, $clock.Elapsed.TotalSeconds)
if ($script:failed -ne 0) {
    exit 1
}
