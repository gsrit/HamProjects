Add-Type -AssemblyName System.Windows.Forms

# Force classic console look
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# Resize window (large console)
$size = $Host.UI.RawUI.WindowSize
$size.Width = 100
$size.Height = 30
$Host.UI.RawUI.WindowSize = $size

$buffer = $Host.UI.RawUI.BufferSize
$buffer.Width = 100
$buffer.Height = 3000
$Host.UI.RawUI.BufferSize = $buffer

$history = @()

function DrawUI {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "         HAM RADIO QRZ LOOKUP TERMINAL" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "ENTER CALLSIGN (e.g. VU33OM)" -ForegroundColor Green
    Write-Host ""
    Write-Host "-----------------------------------------------"
    Write-Host "Last 10 Lookups:" -ForegroundColor Green
    Write-Host "-----------------------------------------------"

    if ($history.Count -eq 0) {
        Write-Host "None yet..."
    } else {
        $history | ForEach-Object { Write-Host $_ }
    }

    Write-Host ""
    Write-Host "-----------------------------------------------"
    Write-Host ""
    Write-Host "CALLSIGN >> " -NoNewline -ForegroundColor Green
}

function Open-QRZ($call) {
    $url = "https://www.qrz.com/db/$call"

    # Open in background Chrome tab
    Start-Process "chrome.exe" "--new-tab $url" -WindowStyle Minimized
}

while ($true) {
    DrawUI

    # Large text entry (fake "big font")
    $call = Read-Host

    if ($call -eq "") { continue }

    $call = $call.ToUpper()

    # Save history
    $history = ,$call + $history
    if ($history.Count -gt 10) { $history = $history[0..9] }

    # Open QRZ
    Open-QRZ $call
}
