param(
    [Parameter(Mandatory = $true)]
    [string]$Port,

    [int]$Baud = 115200,

    [int]$PreSyncDelaySeconds = 8,

    [switch]$EnterBootloaderFromEsp32,

    [switch]$PulseResetFromEsp32
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$sbl = Join-Path $RepoRoot 'scripts\ti-python-sbl-esp32-bridge.py'
$bin = Join-Path $RepoRoot 'firmware\e79_at_modem\gcc\e79_at_modem.bin'

if (-not (Test-Path -LiteralPath $sbl)) {
    throw "Missing TI serial bootloader script: $sbl"
}
if (-not (Test-Path -LiteralPath $bin)) {
    throw "Build e79_at_modem first. Missing BIN: $bin"
}

Write-Host "Using ESP32 bridge on $Port at CC1352P UART baud $Baud."
if ($Baud -ne 115200) {
    Write-Host "Setting ESP32 bridge target UART baud to $Baud..."
}
else {
    Write-Host "Using bridge default target UART baud 115200; no baud command needed."
}

$serial = [System.IO.Ports.SerialPort]::new($Port, 115200, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$serial.Handshake = [System.IO.Ports.Handshake]::None
$serial.DtrEnable = $false
$serial.RtsEnable = $false
$serial.ReadTimeout = 500
$serial.WriteTimeout = 500

try {
    $serial.Open()
    Start-Sleep -Milliseconds 300
    $serial.DiscardInBuffer()
    if ($Baud -ne 115200) {
        $serial.Write("~CC1352P_BAUD=$Baud`n")
        Start-Sleep -Milliseconds 600
    }
    if ($EnterBootloaderFromEsp32) {
        Write-Host "Entering CC1352P ROM bootloader through ESP32 GPIO3/GPIO10..."
        $serial.Write("~CC1352P_ENTER_BOOTLOADER`n")
        $serial.BaseStream.Flush()
        Start-Sleep -Milliseconds 650
    }
    elseif ($PulseResetFromEsp32) {
        Write-Host "Sending reset pulse command through the ESP32 bridge..."
        $serial.Write("~CC1352P_RESET`n")
        $serial.BaseStream.Flush()
        Start-Sleep -Milliseconds 250
    }
}
finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
    $serial.Dispose()
}

if (-not $PulseResetFromEsp32 -and -not $EnterBootloaderFromEsp32) {
    Write-Host "Hold CC1352P BOOT low now (E79 BOOT = DIO15 active-low)."
    Write-Host "During the next $PreSyncDelaySeconds seconds, pulse RESET manually, then keep BOOT held."
    Start-Sleep -Seconds $PreSyncDelaySeconds
}

Write-Host "Starting TI ROM serial bootloader flash through ESP32 bridge..."

& python $sbl -d CC13X2 -p $Port -b $Baud --no-invoke-bootloader -f -e -w -v -a 0x0 $bin
if ($LASTEXITCODE -ne 0) {
    throw "ESP32 bridge UART serial bootloader flash failed with exit code $LASTEXITCODE"
}
