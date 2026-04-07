Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

$blockSizeX = 16
$blockSizeY = 16

Write-Host "Scanning $width x $height image in $blockSizeX x $blockSizeY blocks..."

for ($y = 0; $y -lt $height; $y += $blockSizeY) {
    if ($y + $blockSizeY -gt $height) { break }
    $line = ""
    for ($x = 0; $x -lt $width; $x += $blockSizeX) {
        if ($x + $blockSizeX -gt $width) { break }
        
        $hasData = $false
        # Check center pixel and corners of the block
        $pixels = @(
            $img.GetPixel($x + 8, $y + 8),
            $img.GetPixel($x + 2, $y + 2),
            $img.GetPixel($x + 14, $y + 14)
        )
        foreach ($p in $pixels) {
            if (($p.R + $p.G + $p.B) -gt 40) {
                $hasData = $true
                break
            }
        }
        $line += if ($hasData) { "#" } else { "." }
    }
    Write-Host $line
}

$img.Dispose()
