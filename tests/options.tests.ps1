[CmdletBinding()]
param([string]$AssemblyPath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
Add-Type -AssemblyName System.Drawing
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$passed = 0

function Assert-Option([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Assert-OptionThrows([scriptblock]$Action, [type]$Expected, [string]$Message) {
    $caught = $null
    try { & $Action } catch { $caught = $_.Exception.GetBaseException() }
    Assert-Option ($null -ne $caught -and $Expected.IsInstanceOfType($caught)) $Message
}

function Get-LayoutSignature($Tiles) {
    return (@($Tiles | Sort-Object { $_.Folder.FullPath }, DirectFiles | ForEach-Object {
        "$($_.Folder.FullPath):$($_.DirectFiles):$([Math]::Round($_.Bounds.X, 3)),$([Math]::Round($_.Bounds.Y, 3)),$([Math]::Round($_.Bounds.Width, 3)),$([Math]::Round($_.Bounds.Height, 3))"
    }) -join '|')
}

function Get-LinearChannel([double]$Channel) {
    $normalized = $Channel / 255
    if ($normalized -le 0.04045) { return $normalized / 12.92 }
    return [Math]::Pow(($normalized + 0.055) / 1.055, 2.4)
}

$root = [FolderMap.FolderNode]::new('C:\options', $null)
$root.TotalBytes = 20
$root.FolderCount = 7
$root.TotalFiles = 7
for ($i = 0; $i -lt 6; $i++) {
    $child = [FolderMap.FolderNode]::new("C:\options\folder-$i", $root)
    $child.DirectBytes = if ($i -eq 0) { 5 } else { 2 }
    $child.TotalBytes = if ($i -eq 0) { 10 } else { 2 }
    $child.DirectFiles = 1
    $child.TotalFiles = 1
    $root.Children.Add($child)
}
$large = $root.Children[0]
$deep = [FolderMap.FolderNode]::new('C:\options\folder-0\deep', $large)
$deep.DirectBytes = 5
$deep.TotalBytes = 5
$deep.DirectFiles = 1
$deep.TotalFiles = 1
$large.Children.Add($deep)
$large.FolderCount = 1
$large.TotalFiles = 2
$bounds = [Drawing.RectangleF]::new(0, 0, 600, 600)
$signatures = @{}

foreach ($algorithm in [Enum]::GetValues([FolderMap.TreemapAlgorithm])) {
    $tiles = [FolderMap.TreemapLayout]::Build($root, $bounds, $algorithm)
    $top = @($tiles | Where-Object Depth -eq 0)
    Assert-Option ($top.Count -eq 6) "$algorithm retains every positive top-level folder"
    Assert-Option (@($tiles | Where-Object Depth -ge 2).Count -gt 0) "$algorithm is applied recursively"
    $areaSum = 0.0
    foreach ($tile in $top) {
        $area = [double]$tile.Bounds.Width * $tile.Bounds.Height
        $expected = 360000.0 * $tile.Bytes / 20
        Assert-Option ([Math]::Abs($area - $expected) -lt 0.2) "$algorithm preserves byte-weighted areas"
        $areaSum += $area
    }
    Assert-Option ([Math]::Abs($areaSum - 360000) -lt 0.5) "$algorithm covers the available area"
    for ($i = 0; $i -lt $top.Count; $i++) {
        for ($j = $i + 1; $j -lt $top.Count; $j++) {
            $overlap = [Drawing.RectangleF]::Intersect($top[$i].Bounds, $top[$j].Bounds)
            Assert-Option (($overlap.Width * $overlap.Height) -lt 0.05) "$algorithm sibling rectangles do not overlap"
        }
    }
    foreach ($tile in @($tiles | Where-Object Depth -gt 0)) {
        $owner = if ($tile.DirectFiles) { $tile.Folder } else { $tile.Folder.Parent }
        $container = @($tiles | Where-Object { -not $_.DirectFiles -and $_.Folder -eq $owner })[0]
        Assert-Option ($tile.Bounds.X -ge $container.Bounds.X + 2.95 -and
            $tile.Bounds.Y -ge $container.Bounds.Y + 21.95 -and
            $tile.Bounds.Right -le $container.Bounds.Right - 2.95 -and
            $tile.Bounds.Bottom -le $container.Bounds.Bottom - 2.95) "$algorithm keeps descendants inside the padded parent"
        if ($tile.DirectFiles) {
            $hit = [FolderMap.TreemapLayout]::HitTest($tiles,
                $tile.Bounds.X + $tile.Bounds.Width / 2, $tile.Bounds.Y + $tile.Bounds.Height / 2)
            Assert-Option ($hit.DirectFiles -and $hit.Folder -eq $tile.Folder) "$algorithm hit testing follows the rendered geometry"
        }
    }
    $signatures[[int]$algorithm] = Get-LayoutSignature $top
}
$defaultLayout = [FolderMap.TreemapLayout]::Build($root, $bounds)
Assert-Option ((Get-LayoutSignature @($defaultLayout | Where-Object Depth -eq 0)) -eq $signatures[0]) 'the existing Build overload keeps Binary as its default'
Assert-Option ($signatures[0] -ne $signatures[1]) 'Squarified is not an alias for Binary'
Assert-Option ($signatures[0] -ne $signatures[2] -and $signatures[1] -ne $signatures[2]) 'Slice-and-dice produces its own geometry'
$empty = [FolderMap.FolderNode]::new('C:\options-empty', $null)
foreach ($algorithm in [Enum]::GetValues([FolderMap.TreemapAlgorithm])) {
    Assert-Option ([FolderMap.TreemapLayout]::Build($empty, $bounds, $algorithm).Count -eq 0) "$algorithm handles empty folders"
    Assert-Option ([FolderMap.TreemapLayout]::Build($root, [Drawing.RectangleF]::Empty, $algorithm).Count -eq 0) "$algorithm handles a zero-size viewport"
}
Assert-OptionThrows { [FolderMap.TreemapLayout]::Build($root, $bounds, [Enum]::ToObject([FolderMap.TreemapAlgorithm], -1)) } ([ArgumentOutOfRangeException]) 'negative layout modes are rejected'
Assert-OptionThrows { [FolderMap.TreemapLayout]::Build($root, $bounds, [Enum]::ToObject([FolderMap.TreemapAlgorithm], 3)) } ([ArgumentOutOfRangeException]) 'unknown layout modes are rejected'

$samples = @{}
for ($i = 0; $i -lt 128; $i++) {
    $folder = [FolderMap.FolderNode]::new("C:\palette\folder-$i", $null)
    $samples[$folder.FullPath.GetHashCode() -band 7] = $folder
}
Assert-Option ($samples.Count -eq 8) 'palette tests cover all eight folder shades'
foreach ($scheme in [Enum]::GetValues([FolderMap.ColorScheme])) {
    $colors = [Collections.Generic.HashSet[int]]::new()
    foreach ($folder in $samples.Values) {
        $color = [FolderMap.TileColors]::GetColor($folder, $scheme)
        [void]$colors.Add($color.ToArgb())
        $again = [FolderMap.TileColors]::GetColor($folder, $scheme)
        Assert-Option ($again.ToArgb() -eq $color.ToArgb() -and $color.A -eq 255) "$scheme colors are stable and opaque"
        $luminance = 0.2126 * (Get-LinearChannel $color.R) +
            0.7152 * (Get-LinearChannel $color.G) + 0.0722 * (Get-LinearChannel $color.B)
        Assert-Option ((1.05 / ($luminance + 0.05)) -ge 4.5) "$scheme maintains readable white captions"
        if ($scheme -eq [FolderMap.ColorScheme]::Classic) {
            Assert-Option ($color.ToArgb() -eq [FolderMap.Display]::ColorFor($folder).ToArgb()) 'Classic preserves the original folder colors'
        }
        if ($scheme -eq [FolderMap.ColorScheme]::Grayscale) {
            Assert-Option ($color.R -eq $color.G -and $color.G -eq $color.B) 'Grayscale is achromatic'
        }
    }
    Assert-Option ($colors.Count -eq 8) "$scheme provides eight distinguishable shades"
}
foreach ($folder in $samples.Values) {
    $distinct = [Collections.Generic.HashSet[int]]::new()
    foreach ($scheme in [Enum]::GetValues([FolderMap.ColorScheme])) {
        [void]$distinct.Add([FolderMap.TileColors]::GetColor($folder, $scheme).ToArgb())
    }
    Assert-Option ($distinct.Count -eq 5) 'each scheme changes the tile color'
}
Assert-OptionThrows { [FolderMap.TileColors]::GetColor($root, [Enum]::ToObject([FolderMap.ColorScheme], -1)) } ([ArgumentOutOfRangeException]) 'negative color schemes are rejected'
Assert-OptionThrows { [FolderMap.TileColors]::GetColor($root, [Enum]::ToObject([FolderMap.ColorScheme], 5)) } ([ArgumentOutOfRangeException]) 'unknown color schemes are rejected'
Assert-OptionThrows { [FolderMap.TileColors]::GetColor($null, [FolderMap.ColorScheme]::Classic) } ([ArgumentNullException]) 'palette lookup rejects a null folder'
Write-Host "Treemap option tests: $passed passed, 0 failed."
