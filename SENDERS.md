# UGS (Universal Gcode Sender)

G-code sender configuration for the SRcnc machine.

## Connection

| Method | Address | Notes |
|--------|---------|-------|
| USB serial | `/dev/cnc` @ 115200 baud | Default. Udev symlink to CH340 adapter |
| WiFi | `fluidnc.home:80` (WebSocket) | TCPDriver, port `fluidnc.home`, baud `23` |

USB is preferred — lower latency and more reliable for real-time control.

## Setup

```bash
make setup   # symlink ugs/ → ~/.config/ugs
make ugs     # launch UGS
```

## Settings

- Firmware: **FluidNC** (switch to **GRBL** for Flexi-HAL/grblHAL)
- Connection driver: **JSERIALCOMM**
- Port: **cnc** (udev symlink, no `/dev/` prefix)
- Baud: **115200**
- Units: **mm**
- Safety height: **5mm**

## Macros

| # | Name | G-code |
|---|------|--------|
| 1 | Go to XY zero | `G90 G0 X0 Y0` |
| 2 | Probe Z (touch plate) | `G91 G38.2 Z-20 F100; G90; G10 L20 P1 Z0` |
| 3 | Park | `G90 G53 G0 Z0; G53 G0 X0 Y380` |

## WiFi Connection (alternative)

1. Tools → Options → UGS → Sender Options
2. Connection Driver: **TCPDriver**
3. Port: `fluidnc.home`
4. Baud: `23` (Telnet port for FluidNC)

## Machine Parameters

| Parameter | X | Y | Z |
|-----------|---|---|---|
| Steps/mm | 400 | 400 | 400 |
| Max rate (mm/min) | 3000 | 3000 | 1000 |
| Acceleration (mm/s²) | 100 | 100 | 50 |
| Max travel (mm) | 220 | 380 | 95 |
| Homing direction | -X | +Y | +Z |

Spindle: 0–12000 RPM (manual router, PWM signal only)
