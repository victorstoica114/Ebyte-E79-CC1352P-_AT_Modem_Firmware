$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$hex = Join-Path $PropRfRoot 'examples\rtos\CC1352P1_LAUNCHXL\prop_rf\rfDiagnostics\tirtos7\gcc\rfDiagnostics.hex'
$cmdFile = Join-Path $RepoRoot 'build\jlink-rfdiagnostics.jlink'

if (-not (Test-Path -LiteralPath $JLinkExe)) {
    throw "Missing J-Link executable: $JLinkExe"
}
if (-not (Test-Path -LiteralPath $hex)) {
    throw "Build rfDiagnostics first. Missing HEX: $hex"
}

New-Item -ItemType Directory -Force -Path (Split-Path $cmdFile) | Out-Null
@"
jtagconf -1 -1
connect
r
h
loadfile $hex
r
g
q
"@ | Set-Content -LiteralPath $cmdFile -Encoding ASCII

& $JLinkExe -device CC1352P1F3 -if cJTAG -speed 4000 -jtagconf -1,-1 -autoconnect 1 -CommanderScript $cmdFile
if ($LASTEXITCODE -ne 0) {
    throw "J-Link flash failed with exit code $LASTEXITCODE"
}
