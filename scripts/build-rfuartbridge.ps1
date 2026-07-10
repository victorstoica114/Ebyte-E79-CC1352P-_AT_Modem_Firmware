$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$exampleDir = Join-Path $PropRfRoot 'examples\nortos\CC1352P1_LAUNCHXL\prop_rf\rfUARTBridge\gcc'

Push-Location $exampleDir
try {
    & mingw32-make.exe
    if ($LASTEXITCODE -ne 0) {
        throw "rfUARTBridge build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
