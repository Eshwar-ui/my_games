Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

# Threshold for "non-black" (sum of R+G+B > 30)
function IsNotBlack($color) {
    return ($color.R + $color.G + $color.B) -gt 30
}

# Define search zones (to avoid merging adjacent cars)
# Zones: [x_start, x_end, y_start, y_end]
$zones = @(
    @{ name="player"; x=0; x2=450; y=0; y2=700 },
    @{ name="enemy1"; x=450; x2=750; y=0; y2=700 },
    @{ name="enemy2"; x=750; x2=1050; y=0; y2=700 },
    @{ name="enemy3"; x=1050; x2=1536; y=0; y2=700 }
)

foreach ($zone in $zones) {
    $minX = $zone.x2; $maxX = $zone.x
    $minY = $zone.y2; $maxY = $zone.y
    $found = $false

    for ($x = $zone.x; $x -lt $zone.x2; $x += 2) {
        for ($y = $zone.y; $y -lt $zone.y2; $y += 2) {
            $pixel = $img.GetPixel($x, $y)
            if (IsNotBlack($pixel)) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
                $found = $true
            }
        }
    }

    if ($found) {
        # Add some padding
        $minX = [Math]::Max(0, $minX - 5)
        $minY = [Math]::Max(0, $minY - 5)
        $maxX = [Math]::Min($width - 1, $maxX + 5)
        $maxY = [Math]::Min($height - 1, $maxY + 5)
        
        $w = $maxX - $minX
        $h = $maxY - $minY
        Write-Host "Zone $($zone.name): Found car at X=$minX, Y=$minY, W=$w, H=$h"
    } else {
        Write-Host "Zone $($zone.name): No car found"
    }
}

$img.Dispose()
