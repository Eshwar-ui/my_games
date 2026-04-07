Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$outDir = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer"
$img = [System.Drawing.Image]::FromFile($srcPath)

$w = 768
$h = 512

$quads = @(
    @{ name="player_car";  x=0;   y=0 }
    @{ name="enemy_car_1"; x=768; y=0 }
    @{ name="enemy_car_2"; x=0;   y=512 }
    @{ name="enemy_car_3"; x=768; y=512 }
)

foreach ($q in $quads) {
    $rect = New-Object System.Drawing.Rectangle($q.x, $q.y, $w, $h)
    $bmp = ([System.Drawing.Bitmap]$img).Clone($rect, $img.PixelFormat)
    $outPath = Join-Path $outDir "$($q.name).png"
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Saved quadrant: $outPath"
    $bmp.Dispose()
}

$img.Dispose()
