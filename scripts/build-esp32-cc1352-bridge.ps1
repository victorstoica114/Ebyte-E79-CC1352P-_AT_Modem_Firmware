$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$project = Join-Path $RepoRoot 'firmware\esp32_cc1352_bridge'

& pio run -d $project
if ($LASTEXITCODE -ne 0) {
    throw "ESP32 CC1352 bridge build failed with exit code $LASTEXITCODE"
}
