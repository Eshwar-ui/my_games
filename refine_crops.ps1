Add-Type -AssemblyName System.Drawing

$outDir = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer"

function GetTightCrop($path) {
    if (-not (Test-Path $path)) { return $null }
    $img = [System.Drawing.Bitmap]::FromFile($path)
    $minX = $img.Width; $maxX = 0
    $minY = $img.Height; $maxY = 0
    $found = $false
    
    for ($x = 0; $x -lt $img.Width; $x += 2) {
        for ($y = 0; $y -lt $img.Height; $y += 2) {
            $p = $img.GetPixel($x, $y)
            if (($p.R + $p.G + $p.B) -gt 40) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
                $found = $true
            }
        }
    }
    
    if ($found) {
        $w = [Math]::Min($img.Width - $minX, $maxX - $minX + 10)
        $h = [Math]::Min($img.Height - $minY, $maxY - $minY + 10)
        $rect = New-Object System.Drawing.Rectangle($minX, $minY, $w, $h)
        $bmp = $img.Clone($rect, $img.PixelFormat)
        $img.Dispose()
        return $bmp
    }
    $img.Dispose()
    return $null
}

foreach ($name in @("player_car", "enemy_car_1", "enemy_car_2", "enemy_car_3")) {
    $path = Join-Path $outDir "$name.png"
    $tightBmp = GetTightCrop($path)
    if ($tightBmp) {
        $tightBmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Refined $name to tight crop ($($tightBmp.Width) x $($tightBmp.Height))"
        $tightBmp.Dispose()
    }
}
