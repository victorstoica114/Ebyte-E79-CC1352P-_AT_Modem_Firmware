# Firmware 0.3.2 validation

Release publication: 3 October 2026.

Both UART variants were compiled and their generated UART pins checked.
Before publication, every artifact was rechecked against its recorded
SHA-256, the source hash was matched, and every Intel HEX data record was
compared with the corresponding BIN image. Both BIN images are 360,448 bytes.
No firmware was rebuilt or programmed during release publication.

Source `firmware/e79_at_modem/e79_at_modem.c` SHA-256:
`85537623c0b2cb3d39c648522254bd5a1b915bf4327422b02a43e4690bf3167f`.

| Variant | UART TX / RX | BIN SHA-256 |
| --- | --- | --- |
| CH340, 1,000,000 baud | DIO12 / DIO13 | `6a369175134d5fe9d3647767ee26061b42c9a2275da4cb111e11719c61f0ddb6` |
| ESP32, 1,000,000 baud | DIO13 / DIO12 | `9d1773e6769269fcaaed65de04ddd54e6e4cdcabcb2d70aecf55bb1821e41c96` |

The CH340 image was programmed and fully read back on both radios through
J-Link/cJTAG on 1 October 2026. UART queries verified firmware 0.3.2 and
the selected marker roles. The debugger was detached for measurements.

The paired 8/32/64-byte campaign completed on 1 October: **315/315 accepted
transfers**, seven PHYs and three power settings. Its independent audit
verified **630/630 captures**, ADC conversion, total energy and marker
durations without mismatches. This is numerical verification of the saved
measurements; it is not an independent analog calibration of the PPK2.

Each radio drives its own PPK2 D0 from DIO17. PPK logic VCC is 3.3 V, with
common signal ground. The radio supply is measured in series at 3.3 V.
RX marks sync detection to completion/abort; prior listening, preamble,
sync acquisition and work after the marker are outside that interval.

Release ZIP bundles contain BIN, HEX, ELF (`.out`), linker map, generated
UART pin definitions, build metadata and an internal SHA256SUMS.txt.
The top-level SHA256SUMS.txt covers both ZIP bundles and standalone BINs.
