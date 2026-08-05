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

Scripts live in the `pedalboard-case` repo under `cnc/`.
The sender must be disconnected before running (scripts own the serial port).

### 1. Cut holes — probe-setup.py

```bash
cd /path/to/pedalboard-case/cnc
make install          # first time only (pip install pyserial)
python3 probe-setup.py
```

Steps: home → install 3D probe → spoilboard Z ref → 5 edge probes (centre +
angle) → per-feature Z at 12 points → swap to cutting tool → touch plate Z →
generate `top-panel.nc`.

```bash
# Then in gSender: load top-panel.nc, dial 1, WD-40, run at 150% feed
```

### 2. Engrave labels — engrave-setup.py

Runs independently — no need to run probe-setup.py first.

```bash
python3 engrave-setup.py
```

Steps: home → install 3D probe → spoilboard Z ref → 5 edge probes (centre +
angle) → 6×10 surface height map (38 points, skips all holes) → generate
`engraving.nc` via plates.py → swap to V-bit → touch plate Z.

```bash
# Then in gSender: load engraving.nc, run
```

Options:
```bash
python3 probe-setup.py --dry-run           # print commands without connecting
python3 engrave-setup.py --dry-run
python3 probe-setup.py --port /tmp/cnc-sim # test with simulator
python3 engrave-setup.py --port /tmp/cnc-sim
```

### Testing with simulator

```bash
# Terminal 1 — start simulator
python3 mock-machine.py --angle 0.3 --crown 0.3

# Terminal 2 — run setup
python3 probe-setup.py --port /tmp/cnc-sim
python3 engrave-setup.py --port /tmp/cnc-sim

# Or use the test runner:
make test           # probe-setup against simulator
make test-engrave   # engrave-setup with 0.3mm crown
```
