Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$outDir = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer"

$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

# Targets: [R, G, B, Name]
$targets = @(
    @{ name="player_car";  r=0;   g=255; b=255; dist=100 } # Cyan
    @{ name="enemy_car_1"; r=255; g=0;   b=0;   dist=100 } # Red
    @{ name="enemy_car_2"; r=150; g=0;   b=0;   dist=80 }  # Dark Red
    @{ name="enemy_car_3"; r=255; g=165; b=0;   dist=100 } # Orange/Yellow
)

foreach ($t in $targets) {
    $minX = $width; $maxX = 0
    $minY = $height; $maxY = 0
    $found = $false
    
    for ($y = 0; $y -lt $height; $y += 5) {
        for ($x = 0; $x -lt $width; $x += 5) {
            $p = $img.GetPixel($x, $y)
            $diff = [Math]::Abs($p.R - $t.r) + [Math]::Abs($p.G - $t.g) + [Math]::Abs($p.B - $t.b)
            if ($diff -lt $t.dist) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
                $found = $true
            }
        }
    }
    
    if ($found) {
        # Expand slightly
        $minX = [Math]::Max(0, $minX - 40)
        $minY = [Math]::Max(0, $minY - 40)
        $maxX = [Math]::Min($width - 1, $maxX + 40)
        $maxY = [Math]::Min($height - 1, $maxY + 40)
        
        $w = $maxX - $minX
        $h = $maxY - $minY
        
        $rect = New-Object System.Drawing.Rectangle($minX, $minY, $w, $h)
        $bmp = $img.Clone($rect, $img.PixelFormat)
        $path = Join-Path $outDir "$($t.name).png"
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Found $($t.name) at X=$minX, Y=$minY, W=$w, H=$h"
        $bmp.Dispose()
    } else {
        Write-Host "Could not find color for $($t.name)"
    }
}

$img.Dispose()
