param(
    [Parameter(Mandatory = $true)]
    [string]$Port
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$project = Join-Path $RepoRoot 'firmware\esp32_cc1352_bridge'

& pio run -d $project -t upload --upload-port $Port
if ($LASTEXITCODE -ne 0) {
    throw "ESP32 CC1352 bridge upload failed with exit code $LASTEXITCODE"
}
