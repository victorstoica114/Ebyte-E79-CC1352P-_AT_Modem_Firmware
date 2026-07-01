# Ebyte E79 CC1352P AT Modem Firmware

Firmware pentru modulul Ebyte E79-400DM2005S, bazat pe TI CC1352P. Modulul nu
este tratat ca radio SPI/UART simplu: CC1352P ruleaza firmware propriu si
expune catre host un modem radio UART cu comenzi AT.

## Continut

- `firmware/e79_at_modem` - firmware-ul CC1352P AT radio modem.
- `firmware/esp32_cc1352_bridge` - bridge ESP32-C3 USB CDC <-> UART CC1352P,
  util pentru test si update prin TI ROM serial bootloader.
- `scripts` - build, flash, probe, teste automate si stress test.
- `.vscode/tasks.json` - task-uri VSCode pentru fluxul uzual.

SDK-ul TI, toolchain-ul GCC, SysConfig, J-Link, datasheet-urile si cache-urile
de build nu sunt incluse in repo-ul public.

## Dependinte

- TI SimpleLink Low Power F2 SDK 8.33.00.16 sau compatibil.
- GNU Arm Embedded `gcc-arm-none-eabi` 9-2019-q4-major.
- TI SysConfig 1.21.1.
- `mingw32-make.exe`, de obicei instalat cu pachetul TI/GCC folosit pentru
  exemple.
- SEGGER J-Link pentru recovery cJTAG/JTAG.
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

- UART modem: `1000000 8N1`.
- Fallback validat pentru stress: `460800 8N1`.
- E79/CC1352P logic: 3.3 V, nu 5 V TTL.
- CC1352P `DIO12` = UART RX, `DIO13` = UART TX.
- ESP32 `GPIO20` = RX from CC1352P TX.
- ESP32 `GPIO21` = TX to CC1352P RX.
- ESP32 `GPIO3` -> E79 `BOOT` / CC1352P `DIO15`, active-low.
- ESP32 `GPIO10` -> CC1352P `RESET_N`, active-low.
- ROM serial bootloader backdoor: `BOOT/DIO15`, active-low, configurat in CCFG
  de firmware.

## ESP32 Bridge Baud

Bridge-ul ESP32-C3 porneste implicit UART-ul intern catre CC1352P la
`1000000`, prin `CC1352_BRIDGE_HOST_BAUD`, identic cu firmware-ul AT.

Baud-ul USB CDC ales pe PC nu este viteza fizica importanta aici. Legatura
relevanta este UART-ul intern ESP32-C3 -> CC1352P pe `GPIO20/GPIO21`.

`460800` ramane fallback-ul recomandat daca apar timeout-uri rare in teste de
stress foarte agresive.

Comanda `~CC1352P_BAUD=<baud>` ramane disponibila pentru teste si fallback:

```text
9600,38400,57600,115200,230400,460800,500000,921600,1000000
```

## ESP32 BOOT + RESET Control

Bridge-ul poate controla intrarea in TI ROM bootloader cand hardware-ul leaga:

- ESP32 `GPIO3` -> E79 `BOOT` / CC1352P `DIO15`, active-low.
- ESP32 `GPIO10` -> CC1352P `RESET_N`, active-low.

Comenzi locale consumate de bridge:

```text
~CC1352P_RESET
~CC1352P_BOOT=LOW
~CC1352P_BOOT=HIGH
~CC1352P_ENTER_BOOTLOADER
~CC1352P_BAUD=<baud>
```

Test non-distructiv:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\probe-e79-bootloader-auto-via-esp32.ps1 -Port COM22
```

Succesul asteptat este:

```text
ACK: 00 CC
```

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1
```

Pentru fallback-ul stabil la `460800`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1 -UartBaud 460800
```

Rezultatele apar in:

```text
firmware\e79_at_modem\gcc\e79_at_modem.hex
firmware\e79_at_modem\gcc\e79_at_modem.bin
```

## Flash prin ESP32 bridge

Flux normal, fara J-Link si fara butoane, cand ESP32 controleaza BOOT + RESET:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM22 -EnterBootloaderFromEsp32
```

## Flash prin J-Link fallback

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem.ps1
```

## Test cu doua module

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-rigorous-two-modules.ps1 -PortA COM19 -PortB COM22 -BridgeBaud 1000000
```

Ultima validare hardware locala:

```text
Verified (match: 0x29bd3083)
PASS: 150
FAIL: 0
```

Validarea a inclus:

- primul `AT` dupa deschiderea portului raspunde direct `OK`, fara
  `~CC1352P_BAUD`;
- configurare frecventa/putere/rata/sync;
- validare erori `#ERROR:`;
- TX/RX text si hex intre doua module;
- `RSSI`, `LASTPKT`, `SLEEP`, `WAKE`, `AT+RESET`;
- stress test pentru baud-uri mari cu `scripts/stress-e79-at-high-baud-two-modules.ps1`.

Detaliile comenzilor AT si plajele validate sunt in
`firmware/e79_at_modem/README.md`.
