# probe/

Automated CNC setup scripts for the SRcnc machine.

## Scripts

### probe-setup.py

Full automated setup for the pedalboard case top panel. Handles homing,
edge finding, center/angle computation, Z probing, G-code generation, and
gSender launch in a single run.

**Preconditions:**
- Case mounted open-side-down, centered at approximately X=110 Y=190 (machine coords)
- gSender disconnected (script owns `/dev/cnc`)
- Machine in idle state (not alarmed)

**Usage:**
```bash
python3 probe-setup.py                     # full run
python3 probe-setup.py --dry-run           # print all commands without connecting
python3 probe-setup.py --port /tmp/cnc-sim # connect to simulator instead
```

**9-step sequence:**

| Step | Action |
|------|--------|
| 1/9 | Check machine state — abort if alarm |
| 2/9 | Safe home: Z first, then X, then Y |
| 3/9 | Probe spoilboard at X=10 Y=190 (reference Z) |
| 4/9 | Probe 4 case edges (double contact each) |
| 5/9 | Compute center + rotation angle, set G54 X0 Y0, verify readback |
| 6/9 | Probe case top surface with 3D probe (reference Z for cross-check) |
| 7/9 | **PAUSE** — remove 3D probe, install cutting tool |
| 8/9 | **PAUSE** — place touch plate, probe Z (double contact), cross-check |
| 9/9 | Generate `top-panel.nc` with angle correction, launch gSender |

### XY Probing Geometry

The script uses 4 edge probes (standard technique: two points on one edge
for angle, opposing edges for center):

```
    Y
    ↑
    │
281 ┊─ ─ ─ ─ ─ ─ ─ ─ ┌───────────────────────┐
    │                │                       │
250 ┊─ ─ ─ ②·→→→→→→→→█                       │
    │       X=43     │                       │
    │                │                       │
    │                │       CENTER          │
190 ┊                │     (110, 190)        █←←←←←←←·③
    │                │                       │    X=177
    │                │                       │
130 ┊─ ─ ─ ①·→→→→→→→→█                       │
    │     X=43       │                       │
    │                │                       │
 99 ┊─ ─ ─ ─ ─ ─ ─ ─ └───────────────────────┘
    │                          ↑
    │                          ↑
 89 ┊                         ·④
    │                      X=110
    └──────────────────────────────────────────── → X
   0          43    53                  167  177   220

              You stand here (Y=0)



    Probe       Start position    Direction   Purpose
    ─────────────────────────────────────────────────────
    ① X- front   X=43,  Y=130     → +X       left edge + angle pt 1
    ② X- back    X=43,  Y=250     → +X       left edge + angle pt 2
    ③ X+ edge    X=177, Y=190     ← -X       right edge
    ④ Y- edge    X=110, Y=89      ↑ +Y       front edge

    Calculations:
      X center = (avg(①,②) + ③) / 2
      Y center = ④ + case_half_height - tip_radius
      Angle    = atan2(②_x - ①_x, 120mm)
```

All probes descend to 5mm below the case top surface before probing
sideways. Each probe uses double-contact (fast at 100mm/min, slow at
20mm/min) for accuracy.

### Z Probing

After XY is established:
1. 3D probe measures case top surface at center (reference)
2. Cutting tool + touch plate (19.25mm) measures Z at center
3. Cross-check: both measurements must agree within 2mm

**Safety features:**
- Feed hold (`!`) sent immediately on any error
- All lateral moves preceded by full Z retract to Z=0 (home)
- Safe homing: Z first to clear probe from workpiece
- Double-contact probing on all axes (fast + slow)
- Fast/slow agreement check (≤0.5mm) on every probe
- Plausibility checks: case width, center position, rotation angle
- G54 readback verification after setting offsets
- Z cross-check: 3D probe surface vs cutting tool touch plate (≤2.0mm)

**Machine configuration** (edit at top of script):
```python
PORT = "/dev/cnc"              # serial port
CASE_CENTER_X = 110.0          # expected case center (machine coords)
CASE_CENTER_Y = 190.0
PROBE_TIP_RADIUS = 2.0         # HLTNC tip radius in mm
TOUCH_PLATE_THICKNESS = 19.25  # auto-zero touch plate thickness in mm
```

---

### mock-machine.py

GRBL/grblHAL machine simulator for testing `probe-setup.py` without a real
machine. Creates a virtual serial port using Python `pty` — no external
dependencies.

Simulates:
- Homing (`$HX`, `$HY`, `$HZ`, `$H`)
- G0/G1 moves in absolute and incremental (G90/G91) modes
- G53 machine-coordinate moves
- `G38.2` probe commands with realistic contact geometry
- Case edges (with configurable rotation angle and XY offset)
- Spoilboard surface
- Case top surface (only when XY is within case footprint)
- Touch plate (auto-activated for cutting tool Z probe sequence)
- G10 L20 WCS offset setting
- `$#` coordinate offset readback
- `?` status query

**Usage:**
```bash
# Start simulator, then run setup in another terminal
python3 mock-machine.py                         # nominal case position
python3 mock-machine.py --angle 0.5             # 0.5° rotation
python3 mock-machine.py --offset-x 2.0          # case shifted 2mm right
python3 mock-machine.py --offset-y -1.0         # case shifted 1mm forward

# Connect probe-setup to simulator
python3 probe-setup.py --port /tmp/cnc-sim
```

Virtual port is symlinked to `/tmp/cnc-sim` by default.

---

## Setup

```bash
make install   # install pyserial (first time only)
make test      # run probe-setup against mock machine
```

Dependencies: `pyserial==3.5` (stdlib only for `mock-machine.py`)

## Workflow

```
1. make test                              # verify script works against simulator

2. python3 probe-setup.py                 # real run (gSender must be closed)
   # script pauses for probe swap and touch plate
   # generates pedalboard-case/top-panel.nc
   # launches gSender

3. Load top-panel.nc in gSender, run job
```
