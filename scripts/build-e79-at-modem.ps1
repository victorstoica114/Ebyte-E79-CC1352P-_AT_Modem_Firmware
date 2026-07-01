param(
    [int]$UartBaud = 1000000
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$supportedBauds = @(9600, 38400, 57600, 115200, 230400, 460800, 500000, 921600, 1000000)
if ($supportedBauds -notcontains $UartBaud) {
    throw "Unsupported UART baud $UartBaud. Supported: $($supportedBauds -join ', ')"
}

$firmwareDir = Join-Path $RepoRoot 'firmware\e79_at_modem\gcc'

Push-Location $firmwareDir
try {
    Write-Host "Building e79_at_modem with UART baud $UartBaud..."
    & mingw32-make.exe -B "E79_UART_BAUD=$UartBaud"
    if ($LASTEXITCODE -ne 0) {
        throw "e79_at_modem build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
