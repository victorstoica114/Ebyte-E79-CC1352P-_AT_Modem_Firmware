# Ebyte E79 CC1352P AT Modem Firmware

Firmware pentru modulul Ebyte E79-400DM2005S, bazat pe TI CC1352P. Modulul nu este tratat ca radio SPI/UART simplu: CC1352P ruleaza firmware propriu si expune catre host un modem radio UART cu comenzi AT.

## Continut

- `firmware/e79_at_modem` - firmware-ul CC1352P AT radio modem.
- `firmware/esp32_cc1352_bridge` - bridge ESP32-C3 USB CDC <-> UART CC1352P, util pentru test si update prin bootloader.
- `scripts` - build, flash, probe si teste automate.
- `.vscode/tasks.json` - task-uri VSCode pentru fluxul uzual.

SDK-ul TI, toolchain-ul GCC, SysConfig si J-Link nu sunt incluse in repo.

## Dependinte

- TI SimpleLink Low Power F2 SDK 8.33.00.16 sau compatibil.
- GNU Arm Embedded `gcc-arm-none-eabi` 9-2019-q4-major.
- TI SysConfig 1.21.1.
- `mingw32-make.exe`, de obicei instalat cu pachetul TI/GCC folosit pentru exemple.
- SEGGER J-Link pentru flash cJTAG/JTAG.
- PlatformIO, doar pentru `firmware/esp32_cc1352_bridge`.

Scripturile accepta dependintele fie in layout local:

```text
sdk/simplelink-lowpower-f2-sdk
tools/gcc-arm-none-eabi-9-2019-q4-major
tools/sysconfig_1.21.1
tools/SEGGER/JLink_V954
```

fie prin variabile de mediu:

```powershell
$env:SIMPLELINK_CC13XX_CC26XX_SDK_INSTALL_DIR = "D:\path\simplelink-lowpower-f2-sdk"
$env:GCC_ARMCOMPILER = "D:\path\gcc-arm-none-eabi-9-2019-q4-major"
$env:SYSCONFIG_TOOL = "D:\path\sysconfig_1.21.1\sysconfig_cli.bat"
$env:JLINK_EXE = "D:\path\JLink.exe"
```

## Hardware

- UART modem: 115200 8N1.
- E79/CC1352P logic: 3.3 V, nu 5 V TTL.
- CC1352P `DIO12` = UART RX, `DIO13` = UART TX.
- Programare initiala: J-Link cJTAG/JTAG, device `CC1352P1F3`.
- ROM serial bootloader backdoor: `BOOT/DIO15`, active-low, configurat in CCFG de firmware.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1
```

Rezultatele apar in:

```text
firmware\e79_at_modem\gcc\e79_at_modem.hex
firmware\e79_at_modem\gcc\e79_at_modem.bin
```

## Flash prin J-Link

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem.ps1
```

## Flash prin USB-UART / ROM bootloader

Dupa ce imaginea cu CCFG backdoor a fost scrisa macar o data, se poate face update prin ROM serial bootloader:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-uart.ps1 -Port COM5
```

Prin ESP32-C3 bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM22
```

## Test cu doua module

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-rigorous-two-modules.ps1 -PortA COM19 -PortB COM22 -BridgeBaud 115200
```

Ultima validare hardware locala a trecut cu `PASS: 150`, `FAIL: 0`, inclusiv:

- primul `AT` dupa deschiderea portului raspunde direct `OK`;
- configurare frecventa/putere/rata/sync;
- validare erori `#ERROR:`;
- TX/RX text si hex intre doua module;
- `RSSI`, `LASTPKT`, `SLEEP`, `WAKE`, `AT+RESET`.

Detaliile comenzilor AT si plajele validate sunt in `firmware/e79_at_modem/README.md`.
