# CC1352P / E79-400DM2005S Workspace

Acest workspace este pentru firmware-ul separat care ruleaza pe MCU-ul TI
CC1352P din modulul Ebyte E79-400DM2005S. E79 nu este tratat ca radio SPI
simplu: CC1352P ruleaza firmware propriu si expune catre ESP32 un modem radio
UART cu comenzi AT.

Fluxul normal validat acum este:

1. ESP32-C3 ruleaza bridge-ul USB CDC -> UART CC1352P.
2. ESP32 controleaza `BOOT/DIO15` prin GPIO3 si `RESET_N` prin GPIO10.
3. CC1352P intra automat in TI ROM serial bootloader.
4. Firmware-ul E79 AT modem se scrie prin UART, fara J-Link.

J-Link ramane util ca plasa de siguranta pentru recovery, citire registre sau
module cu CCFG necunoscut, dar nu mai este necesar in fluxul normal de update.

## Ce este instalat local

- TI SimpleLink Low Power F2 SDK: `sdk/simplelink-lowpower-f2-sdk`
- TI Proprietary RF examples: `sdk/simplelink-prop_rf-examples`
- ARM GCC 9-2019-q4-major: `tools/gcc-arm-none-eabi-9-2019-q4-major`
- TI SysConfig 1.21.1: `tools/sysconfig_1.21.1`
- SEGGER J-Link V9.54: `tools/SEGGER/JLink_V954` (fallback/recovery)

## Build testat

Au fost compilate cu succes:

- `rfDiagnostics` pentru `CC1352P1_LAUNCHXL`
- `rfUARTBridge` pentru `CC1352P1_LAUNCHXL`
- `e79_at_modem` pentru E79/CC1352P, derivat din configuratia TI
  `CC1352P_4_LAUNCHXL` la 433 MHz
- bridge-ul ESP32-C3 din `firmware/esp32_cc1352_bridge`

Firmware-ul util curent este in `firmware/e79_at_modem`.

## Flash validat

Validarea hardware curenta:

- ESP32 GPIO3 -> E79 `BOOT/DIO15`, active-low.
- ESP32 GPIO10 -> E79 `RESET_N`, active-low.
- ESP32 GPIO20/GPIO21 -> UART CC1352P la `1000000` baud.
- TI ROM SBL raspunde la sync cu `ACK: 00 CC` pe ambele module testate.
- Flash prin ESP32 bridge: mass erase + write + verify OK pe `COM19` si `COM22`.
- Imagine scrisa: `firmware\e79_at_modem\gcc\e79_at_modem.bin`, 360448 bytes.
- Verify CRC pe ambele module: `0x29bd3083`.
- Test AT/RF complet dupa flash: `PASS: 150`, `FAIL: 0`.

Baud-ul USB CDC PC -> ESP32 nu este viteza fizica importanta. Legatura critica
este UART-ul intern ESP32-C3 -> CC1352P, iar bridge-ul porneste implicit la
`1000000`, identic cu firmware-ul AT. `460800` ramane fallback-ul recomandat
daca apar timeout-uri rare in teste de stress foarte agresive.

## Comenzi rapide

Din PowerShell, in radacina workspace-ului.

Build firmware E79:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1
```

Build si flash ESP32 bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-esp32-cc1352-bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\flash-esp32-cc1352-bridge.ps1 -Port COM19
```

Proba non-distructiva pentru intrare automata in ROM bootloader:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\probe-e79-bootloader-auto-via-esp32.ps1 -Port COM19
```

Succesul asteptat:

```text
ACK: 00 CC
```

Flash CC1352P prin ESP32 bridge, fara butoane si fara J-Link:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM19 -EnterBootloaderFromEsp32
```

Dupa verify, scriptul elibereaza BOOT si pulseaza RESET prin ESP32, astfel incat
modulul revine automat in firmware-ul AT. Pentru debug se poate adauga
`-NoResetAfterFlash`.

Verificare AT rapida:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-sequence-via-esp32.ps1 -Port COM19 -Baud 1000000 -Commands AT+VERSION?
```

Test riguros cu doua module:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-rigorous-two-modules.ps1 -PortA COM19 -PortB COM22 -BridgeBaud 1000000
```

In VSCode sunt disponibile aceleasi comenzi in `Terminal > Run Task`.

## Module noi si backdoor

- CC1352P are ROM serial bootloader in silicon; nu il flashuim noi.
- Daca nu exista imagine valida in flash, ROM-ul poate intra in serial
  bootloader, dar depinde de starea CCFG/factory state.
- Dupa ce exista o imagine valida in flash, intrarea prin `BOOT` + `RESET`
  cere bootloader backdoor activ in CCFG.
- Firmware-ul `e79_at_modem` activeaza backdoor-ul pe `BOOT/DIO15`, active-low.
- Un modul testat fara backdoor avea `BL_CONFIG = 0xC5FFFFFF`: ROM bootloader
  enabled, backdoor disabled, pin BOOT neselectat.
- Imaginea curenta seteaza `BL_CONFIG = 0xC5FE0FC5`: ROM bootloader enabled +
  backdoor enabled pe pinul `0x0F` (`DIO15`), active-low.

Pentru module noi/blank, merita incercat direct fluxul UART prin ESP32. Daca
ROM-ul nu intra in SBL din cauza CCFG sau daca modulul este intr-o stare
necunoscuta, J-Link ramane metoda de recuperare.

## Fallback J-Link

J-Link/cJTAG ramane disponibil pentru recovery:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem.ps1
```

Scripturile vechi pentru `rfDiagnostics`, `rfUARTBridge`, citire `BL_CONFIG` si
reset/debug prin J-Link sunt pastrate pentru diagnostic.

## Firmware E79 AT modem

Firmware-ul foloseste TI Proprietary RF / 2-GFSK 50 kbps la 433 MHz si
configureaza explicit pinii reali ai modulului E79:

- UART catre ESP32 la `1000000 8N1`.
- RF switch E79 pe DIO5/DIO6.
- Frecventa implicita: `433920000` Hz.
- Plaja acceptata: `431000000..500000000` Hz.
- ROM serial bootloader backdoor activ pe `BOOT/DIO15`, active-low.

Detalii despre comenzi, plaje validate si testul cu doua module sunt in
`firmware\e79_at_modem\README.md`.

## Directia urmatoare

- persistenta config in flash/NVS;
- mapare optionala `AT+CHAN` daca alegem pasul de canal;
- address filtering daca protocolul final are nevoie;
- integrare finala in proiectul ESP32 prin driver UART.
