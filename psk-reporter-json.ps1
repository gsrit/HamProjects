$myCall = "VU33OM"
$myGrid = "MK68"

$url = "https://retrieve.pskreporter.info/query?senderCallsign=$myCall"

[xml]$data = Invoke-WebRequest $url

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

$records = @()

foreach($r in $data.receptionReports.receptionReport){

    if($r.receiverLocator){

        $km = DistanceKm $myGrid $r.receiverLocator

        $records += [PSCustomObject]@{
            call = $r.receiverCallsign
            km   = $km
        }
    }
}

$top = $records | Sort km -Descending | Select -First 5

$result = @{
    max_km = ($top | Measure km -Maximum).Maximum
    top5   = $top
}

$result | ConvertTo-Json -Depth 3
