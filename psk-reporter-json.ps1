$myCall = "VU33OM"
$myGrid = "MK68"
$refreshInterval = 240
$alertThreshold = 5000

function GridToLatLon($grid){
    $lon = (([int][char]$grid[0] - 65) * 20) + ([int]$grid[2] * 2) - 180 + 1
    $lat = (([int][char]$grid[1] - 65) * 10) + ([int]$grid[3]) - 90 + 0.5
    return @($lat,$lon)
}

function DistanceKm($g1,$g2){
    $p1 = GridToLatLon $g1
    $p2 = GridToLatLon $g2
    $R = 6371
    $dLat = ($p2[0]-$p1[0]) * [math]::PI/180
    $dLon = ($p2[1]-$p1[1]) * [math]::PI/180
    $a = [math]::Sin($dLat/2)*[math]::Sin($dLat/2) +
         [math]::Cos($p1[0]*[math]::PI/180) *
         [math]::Cos($p2[0]*[math]::PI/180) *
         [math]::Sin($dLon/2)*[math]::Sin($dLon/2)
    $c = 2 * [math]::Atan2([math]::Sqrt($a),[math]::Sqrt(1-$a))
    return [math]::Round($R*$c)
}

while ($true){
    Clear-Host
    $now = Get-Date

    Write-Host "PSKReporter Dashboard | " -NoNewline
    Write-Host $now.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------"

    try{
        $url = "https://retrieve.pskreporter.info/query?senderCallsign=$myCall"
        [xml]$data = Invoke-WebRequest $url -UseBasicParsing

        $records = @()
        $alertTriggered = $false

        foreach($r in $data.receptionReports.receptionReport){
            if($r.receiverLocator){
                $km = DistanceKm $myGrid $r.receiverLocator
                $freqMHz = if($r.frequency){ [math]::Round(([double]$r.frequency)/1000000,3) } else {0}
                $country = if($r.receiverDXCC){ $r.receiverDXCC } else { "Unknown" }
                
                # Calculate time difference
                $epoch = New-Object DateTime 1970, 1, 1, 0, 0, 0, 0, ([DateTimeKind]::Utc)
                $reportTime = $epoch.AddSeconds($r.flowStartSeconds).ToLocalTime()
                $diff = New-TimeSpan -Start $reportTime -End $now
                $minutesAgo = [math]::Max(0, [math]::Round($diff.TotalMinutes))

                $records += [PSCustomObject]@{
                    call    = $r.receiverCallsign
                    km      = $km
                    freq    = $freqMHz
                    country = $country
                    ago     = $minutesAgo
                    rawTime = $r.flowStartSeconds
                }

                # Alert if DX is fresh (within last 5 mins) and far
                if($km -ge $alertThreshold -and $minutesAgo -le 5){
                    $alertTriggered = $true
                }
            }
        }

        if($records.Count -gt 0){
            # --- SECTION 1: TOP 5 BY DISTANCE (Last 30 Mins) ---
            Write-Host "[ 1. Top 5 DX - Last 30 Mins ]" -ForegroundColor Yellow
            $dx = $records | Where-Object { $_.ago -le 30 } | Sort-Object km -Descending | Select-Object -First 5
            if($dx) {
                $dx | ForEach-Object {
                    Write-Host "$($_.call.PadRight(8)) - " -NoNewline
                    Write-Host "$($_.km) Km".PadRight(8) -ForegroundColor Green -NoNewline
                    Write-Host " - $($_.freq) MHz - " -NoNewline
                    Write-Host "$($_.ago) Mins Ago - " -NoNewline
                    Write-Host "$($_.country)" -ForegroundColor Gray
                }
            } else { Write-Host "No DX records found in last 30 minutes." -ForegroundColor DarkGray }

            # --- SECTION 2: TOP 10 MOST RECENT ---
            Write-Host "`n[ 2. Top 10 Most Recent Results ]" -ForegroundColor Magenta
            $records | Sort-Object rawTime -Descending | Select-Object -First 10 | ForEach-Object {
                Write-Host "$($_.call.PadRight(8)) - " -NoNewline
                Write-Host "$($_.km) Km - " -NoNewline
                Write-Host "$($_.freq) MHz - " -NoNewline
                
                if ($_.ago -le 3) {
                    Write-Host "$($_.ago) Mins Ago [NEW]" -ForegroundColor Red -NoNewline
                } else {
                    Write-Host "$($_.ago) Mins Ago" -ForegroundColor White -NoNewline
                }
                Write-Host " - $($_.country)" -ForegroundColor Gray
            }
        }

        if($alertTriggered){
            Write-Host "`n*** DX ALERT OVER $alertThreshold KM ***" -ForegroundColor White -BackgroundColor Red
            [console]::Beep(800,400); [console]::Beep(1200,500)
        }
    }
    catch{
        Write-Host "API Connection Error." -ForegroundColor Red
    }

    Write-Host "`n--------------------------------------------------------"
    # Countdown visual
    for ($i = $refreshInterval; $i -gt 0; $i--) {
        Write-Progress -Activity "Monitoring VU33OM" -Status "Next Update in $i seconds..." -PercentComplete (($i / $refreshInterval) * 100)
        Start-Sleep -Seconds 1
    }
}
