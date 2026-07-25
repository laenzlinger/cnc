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
| 2 | Probe Z (touch plate) | `G91 G38.2 Z-30 F100; G0 Z2; G38.2 Z-5 F20; G90 G10 L20 P1 Z19.25; G0 Z10` |
| 3 | Load Workpiece | `G90 G53 G0 Z0; G53 G0 X0 Y380` |
| 4 | Park | `G90 G53 G0 Z0; G53 G0 X0 Y0` |

### Probe Z workflow
1. Jog spindle to within 30mm above the touch plate
2. Place touch plate on workpiece surface
3. Clip ground wire to bit
4. Run macro 2
5. Wait for Z to lift clear, then remove touch plate
6. G54 Z0 is now at workpiece surface (plate thickness: 19.25mm)

## Top Panel Setup (pedalboard case)

For full automated setup (center finding, angle correction, Z probe, G-code generation):

```bash
cd probe/
make install   # first time only
python3 probe-setup.py
```

UGS must be disconnected before running. The script runs 9 steps:

1. Check machine state (no alarm)
2. Safe home Z→X→Y, move to tool change position
3. **PAUSE** — install 3D probe (HLTNC)
4. Probe spoilboard at X5 Y5 (reference surface)
5. Probe X-, X+, Y- left, Y- right edges (double contact each)
6. Compute case center + rotation angle, set G54 X0 Y0
7. Probe case top surface with 3D probe
8. **PAUSE** — remove 3D probe, install cutting tool
9. **PAUSE** — place touch plate, clip wire to tool
10. Probe Z (double contact), cross-check against 3D probe reference
11. Retract, **PAUSE** — remove touch plate
12. Generate `top-panel.nc` with angle correction
13. Launch UGS automatically

Options:
```bash
python3 probe-setup.py --dry-run          # print commands without connecting
python3 probe-setup.py --port /dev/ttyUSB0  # override serial port
```

### Testing with simulator

Test the full probe sequence without a machine:

```bash
# Terminal 1 — start simulator (0.3° rotation, 1.5mm X offset)
python3 mock-machine.py --angle 0.3 --offset-x 1.5

# Terminal 2 — run setup against simulator
python3 probe-setup.py --port /tmp/cnc-sim
```

Simulator options: `--angle`, `--offset-x`, `--offset-y`, `--case-height`, `--touch-plate`

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
