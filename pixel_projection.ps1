Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

function IsNotBlack($color) {
    return ($color.R + $color.G + $color.B) -gt 40
}

Write-Host "Vertical Projection (Column-wise density):"
$xDensity = New-Object 'int[]' $width
for ($x = 0; $x -lt $width; $x += 1) {
    $count = 0
    for ($y = 0; $y -lt $height; $y += 5) { # speed
        if (IsNotBlack($img.GetPixel($x, $y))) {
            $count++
        }
    }
    $xDensity[$x] = $count
}

# Print xDensity in compressed chunks
for ($i = 0; $i -lt $width; $i += 32) {
    $avg = 0
    for ($j = 0; $j -lt 32; $j++) { $avg += $xDensity[$i+$j] }
    $avg = $avg / 32
    Write-Host ("Col {0:D4}: {1}" -f $i, ("#" * ($avg / 2)))
}

Write-Host "`nHorizontal Projection (Row-wise density):"
$yDensity = New-Object 'int[]' $height
for ($y = 0; $y -lt $height; $y += 1) {
    $count = 0
    for ($x = 0; $x -lt $width; $x += 10) { # speed
        if (IsNotBlack($img.GetPixel($x, $y))) {
            $count++
        }
    }
    $yDensity[$y] = $count
}

for ($i = 0; $i -lt $height; $i += 32) {
    $avg = 0
    for ($j = 0; $j -lt 32; $j++) { $avg += $yDensity[$i+$j] }
    $avg = $avg / 32
    Write-Host ("Row {0:D4}: {1}" -f $i, ("#" * ($avg / 2)))
}

$img.Dispose()
