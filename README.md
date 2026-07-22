# CC1352P / E79-400DM2005S firmware

Source repository for the firmware that runs on the TI CC1352P inside the
Ebyte E79-400DM2005S module. The E79 is not used as a simple SPI transceiver:
the CC1352P runs the modem firmware and exposes a UART interface to the ESP32.

Current modem firmware version: `0.3.0`.

## Repository roles

This is the public, source-focused repository. It contains firmware source,
SysConfig input and generated radio configuration, build files, the ESP32-C3
bridge source, and update/test scripts. It does not contain the TI SDK,
toolchains, or local build cache.

The companion
`Ebyte-E79-CC1352P-_AT_Modem_Firmware-Full` repository is a complete recovery
snapshot with the same source plus the local SDK, toolchain, SysConfig,
J-Link utilities, and useful build artifacts. Ready-to-write binaries are also
published as GitHub Release assets.

## Validated update path

1. The ESP32-C3 runs the USB CDC to CC1352P UART bridge.
2. ESP32 GPIO3 drives `BOOT/DIO15`; GPIO10 drives `RESET_N`.
3. The bridge enters the CC1352P TI ROM serial bootloader automatically.
4. The firmware image is erased, written, verified, and reset through UART.

J-Link remains available for recovery and CCFG inspection, but is not required
for normal updates.

## Local build dependencies

The helper scripts look for these paths in the full workspace or equivalent
environment variables:

- `sdk/simplelink-lowpower-f2-sdk`
- `sdk/simplelink-prop_rf-examples`
- `tools/gcc-arm-none-eabi-9-2019-q4-major`
- `tools/sysconfig_1.21.1`
- `tools/SEGGER/JLink_V954` for recovery only

Build the modem firmware from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-e79-at-modem.ps1
```

Build and write the ESP32-C3 bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-esp32-cc1352-bridge.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\flash-esp32-cc1352-bridge.ps1 -Port COM19
```

## Write the E79 firmware

Probe ROM bootloader entry without erasing flash:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\probe-e79-bootloader-auto-via-esp32.ps1 -Port COM19
```

Expected sync response:

```text
ACK: 00 CC
```

Write and verify the CC1352P image through the bridge:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem-via-esp32.ps1 -Port COM19 -EnterBootloaderFromEsp32
```

The current `0.3.0` image was verified on both modules:

```text
COM19: CRC32 0xC3EB2AAF
COM22: CRC32 0xC3EB2AAF
BIN size: 360448 bytes
SHA256: E96CD23DFB8D9C5EB2AFECBA21E8063074937E6DF42371316889A3015F4A02AD
```

## Modem behavior

- UART to ESP32: `1000000 8N1`.
- RX starts automatically at boot, after `AT+DEFAULT`, and after `AT+RESET`.
- Any non-AT line is transmitted directly; `AT+SEND=` is optional.
- Transparent TX does not emit an `OK` response.
- With debug disabled, received payloads are forwarded without status prefixes.
- Explicit AT commands retain normal `OK` and `#ERROR:` responses.
- Default frequency: `433920000` Hz.
- Supported range: `431000000..500000000` Hz.
- E79 RF switch: DIO5/DIO6.
- ROM bootloader backdoor: `BOOT/DIO15`, active low.

Seven RF profiles are available:

| Profile | Rate | Mode |
| --- | ---: | --- |
| `GFSK4K8` | 4.8 kbps | narrowband 2-GFSK |
| `GFSK50` | 50 kbps | 2-GFSK, default |
| `GFSK200` | 200 kbps | 2-GFSK |
| `SLR2K5` | 2.5 kbps | SimpleLink Long Range |
| `SLR5` | 5 kbps | SimpleLink Long Range |
| `OOK4K8` | 4.8 kbps | OOK |
| `IEEE154G50` | 50 kbps | IEEE 802.15.4g MR-FSK |

`IEEE154G50` uses a 16-bit PHR, whitening, CRC-16, LSB-first payload bytes,
and the standard 24-bit SFD `0x55904E`. It was tested between two E79 modules
in both directions.

See [firmware/e79_at_modem/README.md](firmware/e79_at_modem/README.md) for the
full AT command reference, RF parameters, build measurements, and IEEE
802.15.4g framing details.

## Hardware test

Run the full two-module suite:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-e79-at-rigorous-two-modules.ps1 -PortA COM19 -PortB COM22 -BridgeBaud 1000000
```

Latest validated result:

```text
PASS: 343
FAIL: 0
```

The suite covers AT validation, automatic RX, transparent text TX, explicit
text and binary TX, all seven RF profiles in both directions, RSSI and packet
status, sleep/wake, reset, and the IEEE 802.15.4g advanced command path.

## GitHub Release assets

Useful release assets are:

- `.bin`: full image for the ESP32 bridge / TI ROM SBL;
- `.hex`: Intel HEX for compatible programming tools;
- `.out`: ELF image with symbols for debugging;
- `.map`: linker map;
- `SHA256SUMS.txt`: release integrity checks.

The public repository stays source-focused; the full repository keeps local
recovery materials and build outputs.

## ROM bootloader and recovery

The CC1352P ROM serial bootloader is factory silicon code. This firmware only
configures its CCFG entry conditions. The expected current configuration is:

```text
BL_CONFIG = 0xC5FE0FC5
```

That value enables the ROM bootloader backdoor on `DIO15`, active low. A module
with unknown CCFG or a firmware image that disables the backdoor may require
J-Link recovery:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flash-e79-at-modem.ps1
```

Physical bootloader access can permit flash read or erase operations. Revisit
the backdoor policy before locking a production firmware image.
