param(
    [int]$UartBaud = 1000000,
    [ValidateSet('ESP32', 'CH340')]
    [string]$UartPinout = 'ESP32'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$supportedBauds = @(9600, 38400, 57600, 115200, 230400, 460800, 500000, 921600, 1000000)
if ($supportedBauds -notcontains $UartBaud) {
    throw "Unsupported UART baud $UartBaud. Supported: $($supportedBauds -join ', ')"
}

$firmwareDir = Join-Path $RepoRoot 'firmware\e79_at_modem\gcc'
$syscfgFile = '../e79_at_modem.syscfg'
if ($UartPinout -eq 'CH340') {
    # Derive from the canonical source on every build. No manual patches to
    # generated ti_drivers_config files, and no change to the ESP32 default.
    $baseConfig = [System.IO.File]::ReadAllText((Join-Path $firmwareDir $syscfgFile))
    $pinoutOverride = @'

/* Validated CH340 fixture: E79 UART TX=DIO12, RX=DIO13. */
UART_USB.$hardware = null;
UART_USB.uart.$assign = "UART0";
UART_USB.uart.txPin.$assign = "DIO_12";
UART_USB.uart.rxPin.$assign = "DIO_13";
'@
    $syscfgFile = 'e79_at_modem_ch340.syscfg'
    [System.IO.File]::WriteAllText((Join-Path $firmwareDir $syscfgFile),
        $baseConfig + $pinoutOverride, (New-Object System.Text.UTF8Encoding($false)))
}

Push-Location $firmwareDir
try {
    Write-Host "Building e79_at_modem with UART baud $UartBaud, pinout $UartPinout..."
    & mingw32-make.exe -B "E79_UART_BAUD=$UartBaud" "E79_SYSCFG=$syscfgFile"
    if ($LASTEXITCODE -ne 0) {
        throw "e79_at_modem build failed with exit code $LASTEXITCODE"
    }
    $headerText = [System.IO.File]::ReadAllText((Join-Path $firmwareDir 'ti_drivers_config.h'))
    $expectedTx = if ($UartPinout -eq 'CH340') { 12 } else { 13 }
    $expectedRx = if ($UartPinout -eq 'CH340') { 13 } else { 12 }
    if ($headerText -notmatch "(?m)^#define CONFIG_PIN_UART_TX\s+$expectedTx\s*$" -or
        $headerText -notmatch "(?m)^#define CONFIG_PIN_UART_RX\s+$expectedRx\s*$") {
        throw "Generated UART pins do not match $UartPinout; do not flash this image"
    }
    $sourceFile = Join-Path $firmwareDir '../e79_at_modem.c'
    $sourceText = [System.IO.File]::ReadAllText($sourceFile)
    $versionMatch = [regex]::Match($sourceText, '(?m)^#define\s+FW_VERSION\s+"([0-9.]+)"')
    if (-not $versionMatch.Success) { throw 'Cannot identify firmware version' }
    $version = $versionMatch.Groups[1].Value
    $artifactDir = Join-Path $firmwareDir ("../artifacts/$version/$($UartPinout.ToLower())_$UartBaud")
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    $hashes = [ordered]@{}
    foreach ($name in @('e79_at_modem.bin', 'e79_at_modem.hex', 'e79_at_modem.out',
                         'e79_at_modem.map', 'ti_drivers_config.h')) {
        $artifact = Join-Path $artifactDir $name
        Copy-Item -LiteralPath (Join-Path $firmwareDir $name) -Destination $artifact
        $hashes[$name] = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLower()
    }
    $buildInfo = [ordered]@{
        firmware_version = $version
        uart_pinout = $UartPinout
        uart_baud = $UartBaud
        uart_tx_dio = $expectedTx
        uart_rx_dio = $expectedRx
        source_sha256 = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLower()
        syscfg_sha256 = (Get-FileHash -LiteralPath (Join-Path $firmwareDir $syscfgFile) -Algorithm SHA256).Hash.ToLower()
        artifact_sha256 = $hashes
        validation = 'Compiled and generated UART mapping checked; RF marker requires bench validation'
    }
    [System.IO.File]::WriteAllText((Join-Path $artifactDir 'build-info.json'),
        ($buildInfo | ConvertTo-Json -Depth 5) + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Verified $UartPinout UART pinout; artifacts: $artifactDir"
}
finally {
    Pop-Location
}
