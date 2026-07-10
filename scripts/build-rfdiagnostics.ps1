$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$exampleDir = Join-Path $PropRfRoot 'examples\rtos\CC1352P1_LAUNCHXL\prop_rf\rfDiagnostics\tirtos7\gcc'

Push-Location $exampleDir
try {
    & mingw32-make.exe
    if ($LASTEXITCODE -ne 0) {
        throw "rfDiagnostics build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
