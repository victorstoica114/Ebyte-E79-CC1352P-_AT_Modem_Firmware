# ESP32-C3 CC1352P UART Bootloader Bridge

This temporary firmware turns the ESP32-C3 into a mostly transparent USB CDC to
CC1352P UART bridge for testing the TI ROM serial bootloader.

Connections used by the current schematic:

- ESP32 `GPIO20` = RX from CC1352P TX
- ESP32 `GPIO21` = TX to CC1352P RX
- ESP32 `GPIO10` = reset pulse into CC1352P `RESET_N` through the 100 nF capacitor
- CC1352P bootloader backdoor pin = `DIO15` / BOOT button, active low

Current hardware note: the GPIO10 reset pulse path was tested and did not reset
the CC1352P. This was repeated with J-Link physically disconnected: manual reset
brought the AT firmware back, but `~CC1352P_RESET` did not drop `AT+UPTIME?`.
With J-Link connected, readback of `AON_PMCTL:RESETCTL` also stayed at
`RESET_SRC=SYSRESET` instead of changing to `PIN_RESET`. Keep using manual RESET
or J-Link reset for now.

The bridge normally forwards bytes unchanged at 500000 baud. For the AT
application UART, set it to 115200 first with `~CC1352P_BAUD=115200\n`.
The only local
commands it consumes are:

```text
~CC1352P_RESET\n
~CC1352P_BAUD=<baud>\n
```

`RESET` pulses `GPIO10`, then the bridge returns to transparent mode.
`BAUD` changes the ESP32 UART baud rate toward CC1352P. Supported values are
`9600`, `38400`, `57600`, `115200`, `230400`, `460800`, `500000`, `921600`, and
`1000000`.

## Build

```powershell
.\scripts\build-esp32-cc1352-bridge.ps1
```

## Flash ESP32 Bridge

Pick the ESP32 native USB COM port from `pio device list`, then:

```powershell
.\scripts\flash-esp32-cc1352-bridge.ps1 -Port COM19
```

## Flash CC1352P Through ESP32

The CC1352P application must already have the TI ROM bootloader/backdoor enabled
in CCFG. For the current dev firmware that means one initial J-Link flash of
`e79_at_modem` after the bootloader-backdoor SysConfig change.

Hold BOOT, run:

```powershell
.\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM19
```

Keep BOOT held until the TI serial bootloader has started syncing. The default
script path assumes manual CC1352P reset during the printed countdown and uses
115200 baud, which was validated as stable through the ESP32 bridge. If the
reset pulse through `GPIO10` is fixed on a later board, add
`-PulseResetFromEsp32`.
