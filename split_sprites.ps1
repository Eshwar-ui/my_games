Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$outDir = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer"

$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

function GetTightBox($minX, $maxX, $minY, $maxY) {
    # Scan within these bounds and find the tighter non-black box
    $realMinX = $maxX; $realMaxX = $minX
    $realMinY = $maxY; $realMaxY = $minY
    $found = $false
    for ($y = $minY; $y -lt $maxY; $y += 3) {
        for ($x = $minX; $x -lt $maxX; $x += 3) {
            $p = $img.GetPixel($x, $y)
            if (($p.R + $p.G + $p.B) -gt 40) {
                if ($x -lt $realMinX) { $realMinX = $x }
                if ($x -gt $realMaxX) { $realMaxX = $x }
                if ($y -lt $realMinY) { $realMinY = $y }
                if ($y -gt $realMaxY) { $realMaxY = $y }
                $found = $true
            }
        }
    }
    if ($found) {
        # Padding
        $pad = 10
        $x = [Math]::Max(0, $realMinX - $pad); $y = [Math]::Max(0, $realMinY - $pad)
        $w = [Math]::Min($width - $x, $realMaxX - $realMinX + 2*$pad)
        $h = [Math]::Min($height - $y, $realMaxY - $realMinY + 2*$pad)
        return New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    }
    return $null
}

$tasks = @(
    @{ name="player_car";  box=(0, 600, 0, 1024) }
    @{ name="enemy_car_1"; box=(600, 1080, 0, 512) }
    @{ name="enemy_car_2"; box=(600, 1080, 512, 1024) }
    @{ name="enemy_car_3"; box=(1080, 1536, 0, 1024) }
)

foreach ($t in $tasks) {
    $rect = GetTightBox $t.box[0] $t.box[1] $t.box[2] $t.box[3]
    if ($rect) {
        $bmp = $img.Clone($rect, $img.PixelFormat)
        $path = Join-Path $outDir "$($t.name).png"
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Success: $($t.name) at X=$($rect.X), Y=$($rect.Y), $($rect.Width)x$($rect.Height)"
        $bmp.Dispose()
    } else {
        Write-Host "FAIL: No content for $($t.name) in zone $($t.box)"
    }
}

$img.Dispose()
