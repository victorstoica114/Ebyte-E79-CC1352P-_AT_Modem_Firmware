$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

Push-Location $SdkRoot
try {
    & mingw32-make.exe build-gcc
    if ($LASTEXITCODE -ne 0) {
        throw "SDK GCC build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

$grlibDir = Join-Path $SdkRoot 'source\ti\grlib\lib\gcc\m4f'
Push-Location $grlibDir
try {
    & mingw32-make.exe
    if ($LASTEXITCODE -ne 0) {
        throw "grlib m4f build failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
