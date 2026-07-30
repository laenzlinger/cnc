# G-code Senders

Configuration for the SRcnc machine.

## Active: gSender (Flexi-HAL / grblHAL)

### Connection

| Method | Address | Notes |
|--------|---------|-------|
| USB serial | `/dev/cnc` @ 115200 baud | Udev symlink to STM32 CDC (ttyACM0) |

### Setup

```bash
# Config symlinked from ~/.config/gSender → gsender/
gsender  # launch
```

### Settings

- Firmware: **grblHAL**
- Port: `/dev/cnc`
- Baud: **115200**
- Units: **mm**
- Safe retract height: **15mm**
- Machine profile: SRcnc (220×380×95mm)

### Macros

Source of truth: [`gsender/macros.json`](gsender/macros.json)

| # | Name | G-code |
|---|------|--------|
| 1 | Go to XY zero | `G90 G0 X0 Y0` |
| 2 | Probe Z (touch plate) | `G91 G38.2 Z-30 F100; G0 Z2; G38.2 Z-5 F20; G90 G10 L20 P1 Z19.25; G0 Z25` |
| 3 | Load Workpiece | `G90 G53 G0 Z0; G53 G0 X-218 Y0` |
| 4 | Park | `G90 G53 G0 Z0; G53 G0 X-218 Y-378` |
| 5 | Tool Change | `G90 G53 G0 Z0; G53 G0 X-110 Y-378` |
| 6 | Center | `G90 G53 G0 Z0; G53 G0 X-110 Y-190` |

### Probe Z workflow
1. Jog spindle to within 30mm above the touch plate
2. Place touch plate on workpiece surface
3. Clip ground wire to bit
4. Run macro 2
5. Wait for Z to lift clear, then remove touch plate
6. G54 Z0 is now at workpiece surface (plate thickness: 19.25mm)

### Machine Coordinates

After homing (`$H`): X=0, Y=0, Z=0 at home switches.
Travel is in the **negative** direction:
- X: 0 to -220 (right)
- Y: 0 to -380 (back)
- Z: 0 to -95 (down)

## Legacy: UGS (FluidNC / MKS DLC32 MAX)

### Connection

| Method | Address | Notes |
|--------|---------|-------|
| USB serial | `/dev/cnc` @ 115200 baud | Udev symlink to CH340 (ttyUSB0) |
| WiFi | `fluidnc.home:80` (WebSocket) | TCPDriver, port `fluidnc.home`, baud `23` |

### Setup

```bash
make setup   # symlink ugs/ → ~/.config/ugs
make ugs     # launch UGS
```

### Settings

- Firmware: **FluidNC**
- Connection driver: **JSERIALCOMM**
- Port: **cnc**
- Baud: **115200**

### Macros

Same as gSender (macros 1-6 above).

## Machine Parameters

| Parameter | X | Y | Z |
|-----------|---|---|---|
| Steps/mm | 400 | 400 | 400 |
| Max rate (mm/min) | 3000 | 3000 | 1000 |
| Acceleration (mm/s²) | 100 | 100 | 50 |
| Max travel (mm) | 220 | 380 | 95 |
| Homing direction | -X | -Y | +Z |

Spindle: 0–12000 RPM (manual router, no VFD)

## Top Panel Setup (pedalboard case)

For full automated setup (center finding, angle correction, Z probe, G-code generation):

```bash
cd probe/
make install   # first time only
python3 probe-setup.py
```

The sender must be disconnected before running. The script runs 9 steps:

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
13. Launch sender automatically

Options:
```bash
python3 probe-setup.py --dry-run          # print commands without connecting
python3 probe-setup.py --port /dev/ttyUSB0  # override serial port
```

### Testing with simulator

```bash
# Terminal 1 — start simulator
python3 mock-machine.py --angle 0.3 --offset-x 1.5

# Terminal 2 — run setup against simulator
python3 probe-setup.py --port /tmp/cnc-sim
```
