# E79 AT modem firmware

Firmware for the Ebyte E79-400DM2005S / TI CC1352P. The CC1352P runs this
firmware directly and exposes a UART radio modem to the ESP32.

Current firmware version: `0.3.2`, with selectable TX/RX hardware markers
on DIO17. Both CH340 and ESP32 variants compile. On 2026-10-01, TX COM12
and RX COM13 were flashed with the same 0.3.2 CH340 image and the full
image was verified through J-Link/cJTAG on both modules. UART readback
confirmed version 0.3.2 and the selected TX/RX marker roles. The operator
confirmed that the debugger target cable was removed. Independent local
TX and RX pulses have now been observed; the earlier RX-LOW observation
belongs to the TX-only 0.3.1 image. The five-transfer 32 B/GFSK200/+13 dBm
pilot passed with all packets received. Independent ADC integration
reproduced all ten total energies exactly, without baseline subtraction.
The 315-transfer paired 8/32/64-byte campaign completed on 2026-10-01: 315/315 accepted pairs across all seven PHYs and three power settings. Its independent audit verified all 630 TX/RX captures.

## Hardware

- UART: `1000000 8N1`, CC1352P `DIO12` = RX and `DIO13` = TX.
- Validated fallback UART rate for stress testing: `460800 8N1`.
- Logic level: 3.3 V. Do not connect 5 V TTL signals.
- Normal update path: TI ROM serial bootloader through the ESP32-C3 bridge.
- Recovery path: JTAG/cJTAG with J-Link, device `CC1352P1F3`.
- BOOT/update: `BOOT/DIO15`, active low, driven by ESP32 GPIO3 on the current
  hardware.
- RESET: `RESET_N`, active low, driven by ESP32 GPIO10 on the current hardware.
- E79 RF switch: TX = `DIO5=1,DIO6=0`, RX = `DIO5=0,DIO6=1`, standby = both
  low.
- Measurement marker: **DIO17**, also the module's JTAG TDI signal (module
  pad 19 in the bench schematic). A four-wire JTAG probe must not drive TDI
  while this image uses the marker.
- The validated CH340 fixture has UART **TX=DIO12, RX=DIO13**, opposite to
  the ESP32 default above. Select the correct build pinout explicitly.

## Independent TX and RX markers for two PPK2 instruments

Use the same 0.3.2 image on both modules. Select the marker role at runtime:

```text
AT+MARKER=TX
AT+MARKER?
+MARKER:ROLE=TX,DIO=17,SOURCE=RAT_GPO0,ACTIVE=HIGH
OK
```

On the receiver select `AT+MARKER=RX`; the query returns
`+MARKER:ROLE=RX,DIO=17,SOURCE=RAT_GPO1,ACTIVE=HIGH` followed by `OK`.
`AT+CFG?` also includes `MARKER=TX` or `RX`. The role defaults to TX on boot,
`AT+RESET`, and `AT+DEFAULT`; sleep/wake and profile changes preserve it.
`AT+TXMARKER?` remains compatible in TX role and returns `MARKER_NOT_TX`
in RX role. Queries describe configuration, not physical pulse validation.

Connect **TX DIO17 to TX PPK D0**, and **RX DIO17 to RX PPK D0**. Do not join
the two radio outputs. Connect logic-port VCC to the 3.3 V logic reference
and grounds to common signal ground. Each DUT keeps its own measured supply
path through its PPK2; do not bridge the PPK VOUT rails. Remove the debugger
target cable before measuring.

TX uses `RAT_GPO0`, high over the RF-core transmission interval. RX uses
`RAT_GPO1`, high from **sync detection to packet completion or abort**.
The RX window excludes preamble, sync acquisition, prior listening and
processing after the falling edge. It measures the whole supplied module
within that interval, not isolated internal RF energy. TX/RX pulse widths
are expected to differ. The independent PPK clocks cannot establish precise
TX-to-RX propagation delay from these separate markers.

Both signals route via RFC_GPO2 to DIO17. `RF_Params.pPowerCb` reapplies
the selected mapping after each RF setup, preserving GPO0/1/3. Init and
powerdown set the pin LOW. RX adds TI override `0x008F88B3` to a bounded,
persistent copy of the generated PHY overrides; the original pointer is
restored after RF_close. Generated files are not patched. The modern
CC13x2 CPE patches support repeating RX; `bRepeatOk/bRepeatNok=1` are retained.

See [TI signal-routing documentation](https://software-dl.ti.com/simplelink/esd/simplelink_cc13x2_26x2_sdk/3.40.00.02/exports/docs/proprietary-rf/proprietary-rf-users-guide/rf-core/signal-routing.html).
The repeat limitation in its note applies to older CC1310/CC1350/CC2640R2F
devices; repeated operation on this fixture still requires bench validation.

First validate multiple GFSK200 packets in the same continuous RX command,
then sleep/wake and role/profile changes. A missing, truncated or ambiguous
pulse fails measurement acceptance. Packet delivery and payload are checked
separately, since RX pulses may also accompany rejected packets. All seven
PHYs compile; marker behavior must be validated per PHY before campaign use.

The previous common-TX mode remains available: fanout TX DIO17 to both
PPK D0 inputs, with RX DIO17 disconnected. It measures both modules during
the TX interval and does not independently delimit reception. Its wiring
and interpretation must not be mixed with the independent-marker mode.

Build from the workspace root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1 -UartPinout CH340
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1 -UartPinout ESP32
```

The build checks generated UART pin assignments and saves versioned images,
ELF/map, generated pin definitions and SHA-256 metadata in
`firmware/e79_at_modem/artifacts/0.3.2/ch340_1000000` or `esp32_1000000`.
Choose the matching image explicitly when flashing; the generic `gcc` output
contains whichever variant was built last. The CH340 SysConfig overlay is
derived anew from the canonical configuration on each build.

## RF profiles

The firmware contains seven generated and hardware-tested 433 MHz profiles:

| Profile | AT modulation | Data rate | Main settings |
| --- | --- | ---: | --- |
| `GFSK4K8` | `2GFSK` | 4.8 kbps | 2 kHz deviation, 10.1 kHz RX bandwidth |
| `GFSK50` | `2GFSK` | 50 kbps | 25 kHz deviation, 78 kHz RX bandwidth |
| `GFSK200` | `2GFSK` | 200 kbps | 50 kHz deviation, 273 kHz RX bandwidth |
| `SLR2K5` | `2GFSK` | 2.5 kbps | SimpleLink LR, FEC 1:2, DSSS 1:4 |
| `SLR5` | `2GFSK` | 5 kbps | SimpleLink LR, FEC 1:2, DSSS 1:2 |
| `OOK4K8` | `OOK` | 4.8 kbps | OOK, 34.1 kHz RX bandwidth |
| `IEEE154G50` | `MRFSK` | 50 kbps | IEEE 802.15.4g MR-FSK framing |

`GFSK50` is the default profile. The default frequency is `433920000` Hz and
the default proprietary sync word is `0x930B51DE`.

The 100/250 kbps entries from the stock `CC1352P_4_LAUNCHXL` list are 2.4 GHz
profiles and are not used here. `GFSK200` is TI's characterized 433 MHz PHY.

### IEEE 802.15.4g profile

`IEEE154G50` is a separate IEEE 802.15.4g MR-FSK PHY, not an alias for the
proprietary `GFSK50` profile. It uses TI's `2gfsk50kbps154g433mhz` setting and
advanced proprietary RF commands with:

- 50 kbps 2-GFSK, 25 kHz deviation and 78 kHz RX bandwidth;
- 7-byte preamble and 24-bit SFD `0x55904E`;
- 16-bit IEEE 802.15.4g PHR;
- data whitening enabled;
- CRC-16 selected in the PHR;
- LSB-first PSDU byte encoding, matching TI SmartRF Studio framing.

Selecting `AT+PROFILE=IEEE154G50` or switching from `2GFSK` with
`AT+MOD=MRFSK` automatically selects the standard SFD `0x0055904E`. Sync words
in this mode are limited to 24 bits. Selecting a proprietary profile again
restores the proprietary default sync word.

The profile was tested between two E79 modules in both directions. External
interoperability with a third-party IEEE 802.15.4g implementation or SmartRF
Studio is a separate validation step.

## Runtime behavior

- RX is enabled automatically at boot and after `AT+DEFAULT` or `AT+RESET`.
- TX is enabled only for the duration of a transmitted packet, then RX resumes.
- Configuration is RAM-only and is not written to flash/NVS.
- A non-empty UART line that does not start with `AT` is sent directly as a
  text radio payload. `AT+SEND=` remains available for explicit AT operation.
- UART input accepts CR, LF, or CRLF line endings.
- The maximum radio payload is 64 bytes.

## AT commands

```text
AT
AT?
AT+HELP
AT+CFG?
AT+DEFAULT
AT+RESET
AT+VERSION?
AT+MARKER?
AT+MARKER=TX
AT+MARKER=RX
AT+TXMARKER?
AT+DEBUG?
AT+DEBUG=ON
AT+DEBUG=OFF
AT+PROFILE?
AT+PROFILE=<name>
AT+PROFILES?
AT+FREQ?
AT+FREQ=<Hz>
AT+PWR?
AT+PWR=<dBm>
AT+RATE?
AT+RATE=<bps>
AT+MOD?
AT+MOD=<name>
AT+SYNC?
AT+SYNC=<hex>
AT+ADDR?
AT+ADDR=<value>
AT+CHAN?
AT+CHAN=<n>
AT+RX=ON
AT+RX=OFF
AT+SEND=<text>
AT+SENDHEX=<hex>
AT+SLEEP
AT+WAKE
AT+RSSI?
AT+STATUS?
AT+LASTPKT?
AT+RANDOM?
AT+UPTIME?
AT+SETRADIO=FREQ,RATE,PWR,MOD,SYNC
```

Validated parameter ranges:

- `FREQ`: `431000000..500000000` Hz.
- `PROFILE`: `GFSK4K8`, `GFSK50`, `GFSK200`, `SLR2K5`, `SLR5`, `OOK4K8`, or
  `IEEE154G50`.
- `RATE`: `2500`, `4800`, `5000`, `50000`, or `200000` bps.
- `MOD`: `2GFSK`, `OOK`, or `MRFSK`.
- `PWR`: `-20,-15,-10,-5,0,1,2,3,4,5,6,7,8,9,10,11,12,13` dBm.
- `SYNC`: 1 to 8 hexadecimal digits in proprietary modes; up to 6 digits in
  `IEEE154G50` mode. The `0x` prefix is optional.
- `ADDR`: not available; generated PHYs run without address filtering.
- `CHAN`: not available; use an explicit frequency with `AT+FREQ`.

At rates shared by multiple profiles, `AT+RATE` keeps the current modulation
when possible. Use `AT+PROFILE=<name>` for an unambiguous selection. At 50 kbps,
`AT+MOD=2GFSK` selects `GFSK50` and `AT+MOD=MRFSK` selects `IEEE154G50`.

Useful evaluation sequence:

```text
AT+PROFILES?
AT+PROFILE=GFSK4K8
AT+PROFILE=GFSK50
AT+PROFILE=GFSK200
AT+PROFILE=SLR2K5
AT+PROFILE=SLR5
AT+PROFILE=OOK4K8
AT+PROFILE=IEEE154G50
AT+CFG?
```

Errors start with `#ERROR:` and end with CRLF. Explicit AT commands return
`OK\r\n` on success.

## Build

From PowerShell in the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1
```

For the `460800` fallback build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1 -UartBaud 460800
```

Build outputs:

```text
firmware\e79_at_modem\gcc\e79_at_modem.bin
firmware\e79_at_modem\gcc\e79_at_modem.hex
firmware\e79_at_modem\gcc\e79_at_modem.out
firmware\e79_at_modem\gcc\e79_at_modem.map
```

Version `0.3.0` build measurements:

```text
text: 49696 bytes
data: 2472 bytes
bss:  21480 bytes
total ELF sections: 73648 bytes
full BIN image: 360448 bytes
SHA256: E96CD23DFB8D9C5EB2AFECBA21E8063074937E6DF42371316889A3015F4A02AD
```

## Write through the ESP32 bridge

The normal path does not require J-Link or manual button presses:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM19 -EnterBootloaderFromEsp32
```

The script drives BOOT and RESET, performs a mass erase, writes the full image,
verifies it, releases BOOT, and resets the CC1352P into the AT firmware.

The `0.3.0` image was written and CRC-verified on both test modules:

```text
COM19: CRC32 0xC3EB2AAF
COM22: CRC32 0xC3EB2AAF
```

## Test with two modules

Run the rigorous suite with both bridges connected:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-rigorous-two-modules.ps1 -PortA COM19 -PortB COM22 -BridgeBaud 1000000
```

Validated result for firmware `0.3.0`:

```text
PASS: 343
FAIL: 0
```

The suite covers AT commands and validation, text and binary payloads, all
seven RF profiles in both directions, RSSI and last-packet reporting, sleep and
wake behavior, reset behavior, automatic RX startup, and the IEEE 802.15.4g
PHR/whitening/CRC framing path.

## ROM bootloader and recovery

The firmware enables the CC1352P ROM serial bootloader backdoor on `DIO15`,
active low. The expected `BL_CONFIG` value is `0xC5FE0FC5`.

J-Link remains the recovery path for a module with unknown CCFG or an image
that no longer enables the ROM bootloader backdoor:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem.ps1
```

The ROM bootloader is factory silicon code; this project only configures its
CCFG entry conditions.
