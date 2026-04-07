Add-Type -AssemblyName System.Drawing

$srcPath = "d:\PERSONAL PROJECTS\my_games\assets\neon_racer\sprites.png"
$img = [System.Drawing.Bitmap]::FromFile($srcPath)
$width = $img.Width
$height = $img.Height

function IsNotBlack($color) {
    return ($color.R + $color.G + $color.B) -gt 30
}

# Scan every 5 pixels to find clusters
$clusters = @()
$visited = New-Object 'bool[,]' $width, $height

for ($x = 0; $x -lt $width; $x += 10) {
    for ($y = 0; $y -lt $height; $y += 10) {
        $pixel = $img.GetPixel($x, $y)
        if (IsNotBlack($pixel) -and -not $visited[$x, $y]) {
            # Start a flood fill or simple box expansion to find the cluster
            $minX = $x; $maxX = $x
            $minY = $y; $maxY = $y
            
            # Simple BFS/DFS would be too slow in PS, so we'll just check a large area around it
            # and expand as we find more pixels.
            $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
            $queue.Enqueue((New-Object System.Drawing.Point($x, $y)))
            $visited[$x, $y] = $true
            
            while ($queue.Count -gt 0) {
                $p = $queue.Dequeue()
                if ($p.X -lt $minX) { $minX = $p.X }
                if ($p.X -gt $maxX) { $maxX = $p.X }
                if ($p.Y -lt $minY) { $minY = $p.Y }
                if ($p.Y -gt $maxY) { $maxY = $p.Y }
                
                # Check neighbors (step 20 for speed)
                $neighbors = @(
                    (New-Object System.Drawing.Point($p.X+20, $p.Y)),
                    (New-Object System.Drawing.Point($p.X-20, $p.Y)),
                    (New-Object System.Drawing.Point($p.X, $p.Y+20)),
                    (New-Object System.Drawing.Point($p.X, $p.Y-20))
                )
                
                foreach ($n in $neighbors) {
                    if ($n.X -ge 0 -and $n.X -lt $width -and $n.Y -ge 0 -and $n.Y -lt $height) {
                        if (-not $visited[$n.X, $n.Y]) {
                            $visited[$n.X, $n.Y] = $true
                            if (IsNotBlack($img.GetPixel($n.X, $n.Y))) {
                                $queue.Enqueue($n)
                            }
                        }
                    }
                }
            }
            
            $clusters += @{ x=$minX; y=$minY; w=($maxX-$minX); h=($maxY-$minY) }
            Write-Host "Found cluster: X=$minX, Y=$minY, W=($($maxX-$minX)), H=($($maxY-$minY))"
        }
    }
}

$img.Dispose()
Write-Host "Total clusters found: $($clusters.Count)"
