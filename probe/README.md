# probe/

Automated CNC setup scripts for the SRcnc machine.

## Scripts

### probe-setup.py

Full automated setup for the pedalboard case top panel. Handles homing,
edge finding, center/angle computation, Z probing, G-code generation, and
UGS launch in a single run.

**Preconditions:**
- Case mounted open-side-down, centered at approximately X=110 Y=190 (machine coords)
- UGS disconnected (script owns `/dev/cnc`)
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
| 3/9 | Probe spoilboard at X5 Y5 (reference Z) |
| 4/9 | Probe 4 case edges: X-, X+, Y- left, Y- right (double contact each) |
| 5/9 | Compute center + rotation angle, set G54 X0 Y0, verify readback |
| 6/9 | Probe case top surface with 3D probe (reference Z for cross-check) |
| 7/9 | **PAUSE** — remove 3D probe, install cutting tool |
| 8/9 | **PAUSE** — place touch plate, probe Z (double contact), cross-check |
| 9/9 | Generate `top-panel.nc` with angle correction, launch UGS |

**Safety features:**
- Feed hold (`!`) sent immediately on any error
- All descents use `G38.3` (probe toward, stop on contact) instead of blind `G0`
- All lateral moves preceded by full Z retract to Z home (`G53 G0 Z0`)
- Safe homing: Z first to clear probe from workpiece
- Double-contact probing on all axes (fast + slow)
- Fast/slow agreement check (≤0.5mm) on every probe
- Plausibility checks: case width, center position, rotation angle
- G54 readback verification after setting offsets
- Z cross-check: 3D probe surface vs cutting tool touch plate (≤2.0mm)

**Machine configuration** (edit at top of script):
```python
PORT = "/dev/cnc"           # serial port
CASE_CENTER_X = 110.0       # expected case center (machine coords)
CASE_CENTER_Y = 190.0
PROBE_TIP_RADIUS = 2.0      # HLTNC tip radius in mm
TOUCH_PLATE_THICKNESS = 19.25  # auto-zero touch plate thickness in mm
```

---

### mock-machine.py

GRBL/FluidNC machine simulator for testing `probe-setup.py` without a real
machine. Creates a virtual serial port using Python `pty` — no external
dependencies.

Simulates:
- Homing (`$HX`, `$HY`, `$HZ`, `$H`)
- G0/G1 moves in absolute and incremental (G90/G91) modes
- G53 machine-coordinate moves
- `G38.2/G38.3` probe commands with realistic contact geometry
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
python3 mock-machine.py --case-height 3.0        # thicker case walls
python3 mock-machine.py --touch-plate 20.0       # different touch plate

# Connect probe-setup to simulator
python3 probe-setup.py --port /tmp/cnc-sim
```

Virtual port is symlinked to `/tmp/cnc-sim` by default.

---

## Setup

```bash
make install   # install pyserial (first time only)
```

Dependencies: `pyserial==3.5` (stdlib only for `mock-machine.py`)

## Workflow

```
1. python3 mock-machine.py --angle 0.3    # test first
2. python3 probe-setup.py --port /tmp/cnc-sim

3. python3 probe-setup.py                 # real run (UGS disconnected)
   # script pauses for probe swap and touch plate
   # generates pedalboard-case/top-panel.nc
   # launches UGS

4. Load top-panel.nc in UGS, run job
```

## Visualizing the setup path

Record all probe moves as a G-code file, then load in UGS visualizer:

```bash
# Terminal 1
python3 mock-machine.py --angle 0.3 --save-gcode /tmp/setup-path.nc

# Terminal 2
python3 probe-setup.py --port /tmp/cnc-sim

# Then load /tmp/setup-path.nc in UGS visualizer
```

The recorded file replaces `G38.x` probe moves with `G0` rapids and strips
feed rates — safe to visualize without connecting to a machine.

## TODO

- Add `--check` mode to generator for air-trace visual verification before cutting
