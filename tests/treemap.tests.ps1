[CmdletBinding()]
param(
    [string]$AssemblyPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssemblyPath)) {
    $AssemblyPath = Join-Path $PSScriptRoot '..\bin\FolderMap.exe'
}
Add-Type -AssemblyName System.Drawing
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$passed = 0

function Assert-Map([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function New-MapFolder($Parent, [string]$Name, [long]$OwnBytes) {
    $path = if ($null -eq $Parent) { "C:\fixture\$Name" } else { "$($Parent.FullPath)\$Name" }
    $node = [FolderMap.FolderNode]::new($path, $Parent)
    $node.DirectBytes = $OwnBytes
    $node.TotalBytes = $OwnBytes
    if ($OwnBytes -gt 0) {
        $node.DirectFiles = 1
        $node.TotalFiles = 1
    }
    if ($null -ne $Parent) { $Parent.Children.Add($node) }
    return $node
}

$root = New-MapFolder $null 'root' 100
$alpha = New-MapFolder $root 'alpha' 200
$beta = New-MapFolder $root 'beta' 250
$gamma = New-MapFolder $root 'gamma' 100
$empty = New-MapFolder $root 'empty' 0
$deep = New-MapFolder $alpha 'deep' 350
$alpha.TotalBytes = 550
$root.TotalBytes = 1000
$bounds = [Drawing.RectangleF]::new(10, 20, 1000, 600)
$tiles = [FolderMap.TreemapLayout]::Build($root, $bounds)
$top = @($tiles | Where-Object Depth -eq 0)
Assert-Map ($top.Count -eq 4) 'positive folders and direct files each receive a top-level tile'
Assert-Map (@($tiles | Where-Object { $_.Folder -eq $empty }).Count -eq 0) 'empty folders have no area'
Assert-Map (@($tiles | Where-Object { $_.Depth -ge 2 }).Count -gt 0) 'layout renders descendants recursively'

$areaSum = 0.0
foreach ($tile in $top) {
    $area = [double]$tile.Bounds.Width * $tile.Bounds.Height
    $expected = 600000.0 * $tile.Bytes / $root.TotalBytes
    Assert-Map ([Math]::Abs($area - $expected) -lt 0.2) "sibling area is proportional to bytes: $($tile.Folder.Name)"
    Assert-Map ($tile.Bounds.X -ge $bounds.X -and $tile.Bounds.Y -ge $bounds.Y -and
        $tile.Bounds.Right -le $bounds.Right + 0.01 -and $tile.Bounds.Bottom -le $bounds.Bottom + 0.01) 'tile stays inside the requested viewport'
    $areaSum += $area
}
Assert-Map ([Math]::Abs($areaSum - 600000) -lt 0.2) 'top-level tiles cover the full area without duplicating direct bytes'
for ($i = 0; $i -lt $top.Count; $i++) {
    for ($j = $i + 1; $j -lt $top.Count; $j++) {
        $intersection = [Drawing.RectangleF]::Intersect($top[$i].Bounds, $top[$j].Bounds)
        Assert-Map (($intersection.Width * $intersection.Height) -le 0.001) 'sibling rectangles do not overlap'
    }
}
foreach ($tile in @($tiles | Where-Object { $_.Depth -gt 0 })) {
    $owner = if ($tile.DirectFiles) { $tile.Folder } else { $tile.Folder.Parent }
    $parent = @($tiles | Where-Object { -not $_.DirectFiles -and $_.Folder -eq $owner })[0]
    Assert-Map ($tile.Bounds.X -ge $parent.Bounds.X -and $tile.Bounds.Y -ge $parent.Bounds.Y + 21.99 -and
        $tile.Bounds.Right -le $parent.Bounds.Right + 0.01 -and $tile.Bounds.Bottom -le $parent.Bounds.Bottom + 0.01) 'descendant tiles stay inside their parent below its caption'
}

$leafTile = @($tiles | Where-Object { $_.DirectFiles -and $_.Folder -eq $deep })[0]
$hit = [FolderMap.TreemapLayout]::HitTest($tiles,
    $leafTile.Bounds.X + $leafTile.Bounds.Width / 2,
    $leafTile.Bounds.Y + $leafTile.Bounds.Height / 2)
Assert-Map ([object]::ReferenceEquals($hit, $leafTile)) 'hit testing chooses the deepest visible tile'
Assert-Map ($null -eq [FolderMap.TreemapLayout]::HitTest($tiles, -1, -1)) 'hit testing outside the map returns no tile'

$ownOnly = New-MapFolder $null 'files-only' 4096
$ownTiles = [FolderMap.TreemapLayout]::Build($ownOnly, $bounds)
Assert-Map ($ownTiles.Count -eq 1 -and $ownTiles[0].DirectFiles) 'a files-only folder fills the map with a direct-files bucket'
Assert-Map ($ownTiles[0].Bounds.Equals($bounds)) 'a single bucket occupies exactly the requested bounds'
$zeroRoot = New-MapFolder $null 'zero' 0
Assert-Map ([FolderMap.TreemapLayout]::Build($zeroRoot, $bounds).Count -eq 0) 'an empty scan produces an empty layout'
Assert-Map ([FolderMap.TreemapLayout]::Build($root, [Drawing.RectangleF]::new(0, 0, 0, 0)).Count -eq 0) 'zero-size viewports are safe'
Assert-Map ([FolderMap.TreemapLayout]::Build($root, [Drawing.RectangleF]::new(0, 0, 0.5, 100)).Count -eq 0) 'subpixel viewports are suppressed'

$wide = New-MapFolder $null 'wide' 0
$random = [Random]::new(42)
for ($i = 0; $i -lt 257; $i++) {
    $child = New-MapFolder $wide "f$i" ($random.Next(1, 10000))
    $wide.TotalBytes += $child.TotalBytes
}
$wideTiles = [FolderMap.TreemapLayout]::Build($wide, [Drawing.RectangleF]::new(0, 0, 1600, 1000))
$wideTop = @($wideTiles | Where-Object Depth -eq 0)
Assert-Map ($wideTop.Count -eq 257) 'an unsorted wide directory is fully partitioned'
$wideArea = 0.0
foreach ($tile in $wideTop) {
    $area = [double]$tile.Bounds.Width * $tile.Bounds.Height
    $expected = 1600000.0 * $tile.Bytes / $wide.TotalBytes
    Assert-Map ([Math]::Abs($area - $expected) -le [Math]::Max(0.1, $expected * 0.0001)) 'wide-directory area ratios remain accurate'
    $wideArea += $area
}
Assert-Map ([Math]::Abs($wideArea - 1600000) -lt 2) 'wide-directory total area is conserved'

$huge = New-MapFolder $null 'huge' ([long]::MaxValue - 100)
[void](New-MapFolder $huge 'tiny' 100)
$huge.TotalBytes = [long]::MaxValue
$hugeTiles = [FolderMap.TreemapLayout]::Build($huge, $bounds)
Assert-Map ($hugeTiles.Count -gt 0) 'Int64-scale weights do not overflow layout arithmetic'
foreach ($tile in $hugeTiles) {
    Assert-Map (-not [float]::IsNaN($tile.Bounds.Width) -and -not [float]::IsInfinity($tile.Bounds.Height)) 'extreme ratios remain finite'
}

$chain = New-MapFolder $null 'chain' 0
$chain.TotalBytes = 1
$parent = $chain
for ($i = 0; $i -lt 2000; $i++) {
    $next = New-MapFolder $parent 'd' 0
    $next.TotalBytes = 1
    $parent = $next
}
$parent.DirectBytes = 1
$chainTiles = [FolderMap.TreemapLayout]::Build($chain, [Drawing.RectangleF]::new(0, 0, 50000, 100000))
Assert-Map ($chainTiles.Count -eq 2001) '2,000 levels lay out without recursive stack growth'
Assert-Map ($chainTiles[$chainTiles.Count - 1].Depth -eq 2000) 'deepest layout level is retained when there is room'
Assert-Map ([FolderMap.Display]::Number([long]::MaxValue) -eq '9,223,372,036,854,775,807') 'exact byte formatting never rounds through floating point'
Assert-Map ([FolderMap.Display]::Compact(1024) -eq '1 KiB') 'compact units are binary and explicitly labelled'
Assert-Map ([FolderMap.Display]::Compact(0) -eq '0 B') 'zero-byte formatting is explicit'
Assert-Map ([FolderMap.Display]::Elapsed(0) -eq '0.000 s') 'zero duration is explicit'
Assert-Map ([FolderMap.Display]::Elapsed(1234) -eq '1.234 s') 'scan durations preserve milliseconds'
Assert-Map ([FolderMap.Display]::Elapsed(90061002) -eq '90061.002 s') 'long scans report total time without day rollover'
$oldCulture = [Threading.Thread]::CurrentThread.CurrentCulture
try {
    [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('de-DE')
    Assert-Map ([FolderMap.Display]::Elapsed(1234) -eq '1.234 s') 'duration formatting is culture-independent'
} finally { [Threading.Thread]::CurrentThread.CurrentCulture = $oldCulture }
$empty.IssueCount = 1
Assert-Map ([FolderMap.Display]::NodeLabel($empty).EndsWith('[partial]')) 'incomplete folder totals are visibly marked'

$folderDetails = [FolderMap.Display]::SelectionDetails($alpha, $false)
Assert-Map ($folderDetails.StartsWith('Folder | ') -and $folderDetails.Contains('550 bytes')) 'folder selection details use the recursive total'
Assert-Map ($folderDetails.EndsWith("`r`n$($alpha.FullPath)")) 'the full path is displayed separately from the size and counts'
$groupDetails = [FolderMap.Display]::SelectionDetails($alpha, $true)
Assert-Map ($groupDetails.StartsWith('[Files here] | ') -and $groupDetails.Contains('200 bytes') -and
    $groupDetails.Contains('1 files directly in this folder')) 'group details exclude child folder bytes and file counts'
$emptyDetails = [FolderMap.Display]::SelectionDetails($empty, $false)
Assert-Map ($emptyDetails.Contains('0 bytes') -and $emptyDetails.Contains('1 skipped/errors')) 'empty partial folders retain their diagnostic count in selection details'
$emptyGroupDetails = [FolderMap.Display]::SelectionDetails($empty, $true)
Assert-Map ($emptyGroupDetails.Contains('0 bytes') -and $emptyGroupDetails.Contains('0 files directly in this folder')) 'zero-byte group details do not use descendant counts'
Assert-Map ($emptyGroupDetails.Contains('folder tree has skipped/errors')) 'group details preserve the scope of recursive diagnostics'
$hugeDetails = [FolderMap.Display]::SelectionDetails($huge, $false)
Assert-Map ($hugeDetails.Contains('9,223,372,036,854,775,807 bytes')) 'selection details preserve exact Int64 totals'
$chainDetails = [FolderMap.Display]::SelectionDetails($parent, $false)
Assert-Map ($chainDetails.EndsWith($parent.FullPath)) 'selection detail text retains long paths without truncating the backing string'

Write-Host "Treemap tests: $passed passed, 0 failed."
