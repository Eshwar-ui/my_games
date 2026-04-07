Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$outDir = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer"
$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

function IsNotBlack($color) {
    return ($color.R + $color.G + $color.B) -gt 40
}

# Scan and find all non-overlapping bounding boxes of clusters
$rects = @()
$visited = New-Object 'bool[,]' $width, $height

# Scan in 20px steps for finding seeds
for ($y = 0; $y -lt $height; $y += 20) {
    for ($x = 0; $x -lt $width; $x += 20) {
        if (-not $visited[$x, $y] -and (IsNotBlack($img.GetPixel($x, $y)))) {
            # Found a new cluster! Find its bounds.
            $minX = $x; $maxX = $x
            $minY = $y; $maxY = $y
            
            # Simple box expansion
            $changed = $true
            while ($changed) {
                $changed = $false
                # Expand box slightly and check if more pixels are found
                $testMinX = [Math]::Max(0, $minX - 20)
                $testMaxX = [Math]::Min($width - 1, $maxX + 20)
                $testMinY = [Math]::Max(0, $minY - 20)
                $testMaxY = [Math]::Min($height - 1, $maxY + 20)
                
                # Scan borders of the expanded box
                for ($tx = $testMinX; $tx -le $testMaxX; $tx += 10) {
                   if (IsNotBlack($img.GetPixel($tx, $testMinY)) -or IsNotBlack($img.GetPixel($tx, $testMaxY))) {
                        if ($testMinY -lt $minY) { $minY = $testMinY; $changed = $true }
                        if ($testMaxY -gt $maxY) { $maxY = $testMaxY; $changed = $true }
                   }
                }
                for ($ty = $testMinY; $ty -le $testMaxY; $ty += 10) {
                   if (IsNotBlack($img.GetPixel($testMinX, $ty)) -or IsNotBlack($img.GetPixel($testMaxX, $ty))) {
                        if ($testMinX -lt $minX) { $minX = $testMinX; $changed = $true }
                        if ($testMaxX -gt $maxX) { $maxX = $testMaxX; $changed = $true }
                   }
                }
            }
            
            # Add final padding and save
            $w = $maxX - $minX
            $h = $maxY - $minY
            if ($w -gt 50 -and $h -gt 50) { # Ignore noise
                $rects += New-Object System.Drawing.Rectangle($minX, $minY, $w, $h)
                # Mark as visited in a coarse way
                for ($vx = $minX; $vx -le $maxX; $vx += 20) {
                    for ($vy = $minY; $vy -le $maxY; $vy += 20) {
                        if ($vx -lt $width -and $vy -lt $height) { $visited[$vx, $vy] = $true }
                    }
                }
                Write-Host "Found cluster: X=$minX, Y=$minY, W=$w, H=$h"
            }
        }
    }
}

$img.Dispose()

# Re-open safely for cloning
$img = [System.Drawing.Image]::FromFile($srcPath)
$i = 0
foreach ($r in $rects) {
    if ($i -ge 4) { break }
    $names = @("player_car", "enemy_car_1", "enemy_car_2", "enemy_car_3")
    $name = $names[$i]
    $bmp = ([System.Drawing.Bitmap]$img).Clone($r, $img.PixelFormat)
    $path = Join-Path $outDir "$name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Extracted $name from cluster at $($r.X), $($r.Y)"
    $bmp.Dispose()
    $i++
}
$img.Dispose()
