$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Resolve-ToolPath {
    param(
        [string]$Name,
        [string]$EnvName,
        [string]$LocalFallback,
        [string]$RequiredChild = ''
    )

    $value = [Environment]::GetEnvironmentVariable($EnvName)
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = Join-Path $RepoRoot $LocalFallback
    }

    if (-not [System.IO.Path]::IsPathRooted($value)) {
        $value = Join-Path $RepoRoot $value
    }

    $checkPath = $value
    if ($RequiredChild -ne '') {
        $checkPath = Join-Path $value $RequiredChild
    }

    if (-not (Test-Path -LiteralPath $checkPath)) {
        throw "Missing $Name. Set $EnvName or place it at: $value"
    }

    return (Resolve-Path $value).Path
}

$SdkRoot = Resolve-ToolPath `
    -Name 'TI SimpleLink Low Power F2 SDK' `
    -EnvName 'SIMPLELINK_CC13XX_CC26XX_SDK_INSTALL_DIR' `
    -LocalFallback 'sdk\simplelink-lowpower-f2-sdk' `
    -RequiredChild '.metadata\product.json'

$PropRfRoot = Resolve-ToolPath `
    -Name 'TI SimpleLink Proprietary RF examples' `
    -EnvName 'SIMPLELINK_PROP_RF_EXAMPLES_DIR' `
    -LocalFallback 'sdk\simplelink-prop_rf-examples' `
    -RequiredChild 'README.md'

$GccRoot = Resolve-ToolPath `
    -Name 'GNU Arm Embedded toolchain' `
    -EnvName 'GCC_ARMCOMPILER' `
    -LocalFallback 'tools\gcc-arm-none-eabi-9-2019-q4-major' `
    -RequiredChild 'bin\arm-none-eabi-gcc.exe'

$SysConfigTool = [Environment]::GetEnvironmentVariable('SYSCONFIG_TOOL')
if ([string]::IsNullOrWhiteSpace($SysConfigTool)) {
    $SysConfigTool = Join-Path $RepoRoot 'tools\sysconfig_1.21.1\sysconfig_cli.bat'
}
if (-not [System.IO.Path]::IsPathRooted($SysConfigTool)) {
    $SysConfigTool = Join-Path $RepoRoot $SysConfigTool
}
if (-not (Test-Path -LiteralPath $SysConfigTool)) {
    throw "Missing TI SysConfig CLI. Set SYSCONFIG_TOOL or place it at: $SysConfigTool"
}
$SysConfigTool = (Resolve-Path $SysConfigTool).Path

$JLinkExe = [Environment]::GetEnvironmentVariable('JLINK_EXE')
if ([string]::IsNullOrWhiteSpace($JLinkExe)) {
    $JLinkExe = Join-Path $RepoRoot 'tools\SEGGER\JLink_V954\JLink.exe'
}
if (-not [System.IO.Path]::IsPathRooted($JLinkExe)) {
    $JLinkExe = Join-Path $RepoRoot $JLinkExe
}

$env:SIMPLELINK_CC13XX_CC26XX_SDK_INSTALL_DIR = ($SdkRoot -replace '\\', '/')
$env:GCC_ARMCOMPILER = ($GccRoot -replace '\\', '/')
$env:SYSCONFIG_TOOL = ($SysConfigTool -replace '\\', '/')
$env:TICLANG_ARMCOMPILER = ''
$env:IAR_ARMCOMPILER = ''

if ([string]::IsNullOrWhiteSpace($env:CMAKE)) {
    $env:CMAKE = 'cmake'
}
if ([string]::IsNullOrWhiteSpace($env:PYTHON)) {
    $env:PYTHON = 'python'
}
