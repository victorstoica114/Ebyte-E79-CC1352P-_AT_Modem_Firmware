# Firmware changes

## 0.3.2 — 2026-10-03

- Select independent TX or RX hardware markers on DIO17 with
  `AT+MARKER=TX|RX`, and inspect the role with `AT+MARKER?` or `AT+CFG?`.
- Use the same firmware image on both radios for a given UART pinout.
- TX uses RAT_GPO0; RX uses RAT_GPO1 from sync detection through packet
  completion or abort. Each radio drives its own PPK2 D0 input.
- Preserve marker routing across RF power and PHY changes, with LOW at
  initialization and RF powerdown.
- Build verified ESP32 and CH340 UART pinouts separately, with versioned
  firmware artifacts and SHA-256 build metadata.
- Retain compatibility with the TX-only `AT+TXMARKER?` query in TX role.

The source and binary version is 0.3.2. The release date is 3 October;
the firmware was built and validated on the bench earlier.
