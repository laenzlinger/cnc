#!/usr/bin/env python3
"""
probe-setup.py — Full CNC setup for pedalboard case top panel.

Workflow:
  1. Home machine
  2. Pause: install 3D probe
  3. Probe X-, X+, Y- (two points) to find case center and rotation angle
  4. Set G54 X0 Y0 at case center
  5. Move to tool change position
  6. Pause: remove 3D probe, install cutting tool
  7. Move over workpiece center
  8. Pause: place touch plate on workpiece, clip wire to tool
  9. Probe Z (double contact)
  10. Retract to safe Z
  11. Pause: remove touch plate
  12. Generate top-panel.nc with computed angle
  13. Launch UGS

Usage:
    python3 probe-setup.py
    python3 probe-setup.py --port /dev/ttyUSB0
    python3 probe-setup.py --dry-run   # print commands without connecting

Preconditions:
    - UGS must be disconnected (script owns the serial port)
    - Case mounted open-side-down, centered on spoilboard
    - Machine in idle state (not alarmed)
"""

import argparse
import math
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    print("ERROR: pyserial not installed. Run: make install", file=sys.stderr)
    sys.exit(1)

# === MACHINE CONFIGURATION ===

PORT = "/dev/cnc"
BAUD = 115200
TIMEOUT = 30.0          # seconds to wait for probe response

# Safe heights and speeds
SAFE_Z = 10.0           # mm — safe Z for rapids
PROBE_Z_START = 2.0     # mm — Z height before probing Z (above touch plate)
FEED_FAST = 100.0       # mm/min — fast probe feed
FEED_SLOW = 20.0        # mm/min — slow probe feed
FEED_RAPID = 1000.0     # mm/min — approach moves

# Probe geometry
PROBE_TIP_RADIUS = 2.0  # mm — HLTNC 3D probe tip radius
TOUCH_PLATE_THICKNESS = 19.25  # mm

# Case geometry (Hammond 1590DD, long axis along Y)
# Case centered at machine X=110 Y=190
CASE_CENTER_X = 110.0
CASE_CENTER_Y = 190.0
CASE_HALF_WIDTH = 113.8 / 2.0   # X half-extent (short axis)
CASE_HALF_HEIGHT = 181.8 / 2.0  # Y half-extent (long axis)
CASE_HEIGHT_NOMINAL = 30.0      # mm — case wall height (open-side-down)
XY_PROBE_BELOW_SURFACE = 5.0    # mm — probe this far below case top for XY edges

# Probe approach positions (10mm outside case edge)
APPROACH_CLEARANCE = 10.0
PROBE_TRAVEL_XY = 25.0  # mm — max probe travel for X/Y edge finding
PROBE_TRAVEL_Z = 80.0   # mm — max probe travel for Z (must reach spoilboard)

# Y positions for angle measurement (probe Y- edge at two X positions)
ANGLE_PROBE_X_LEFT = CASE_CENTER_X - 60.0
ANGLE_PROBE_X_RIGHT = CASE_CENTER_X + 60.0

# Tool change position (X near home, Y front, Z top)
TOOL_CHANGE_X = 5.0
TOOL_CHANGE_Y = 5.0

# Spoilboard probe position (bare spot, front-left corner near home)
SPOILBOARD_PROBE_X = 5.0
SPOILBOARD_PROBE_Y = 5.0

# Paths
SCRIPT_DIR = Path(__file__).parent
CNS_REPO = SCRIPT_DIR.parent
PEDALBOARD_REPO = CNS_REPO.parent.parent / "pedalboard" / "pedalboard-case"
GCODE_GENERATOR = PEDALBOARD_REPO / "parts" / "top-panel-gcode.py"
GCODE_OUTPUT = PEDALBOARD_REPO / "top-panel.nc"
SENDER_LAUNCH = "/usr/sbin/gsender"


# === GRBL PROTOCOL ===

class GrblConnection:
    """Minimal GRBL/FluidNC serial protocol handler."""

    def __init__(self, port, baud, dry_run=False):
        self.dry_run = dry_run
        self.conn = None
        if not dry_run:
            self.conn = serial.Serial(port, baud, timeout=1)
            time.sleep(2)  # wait for controller reset
            self.conn.flushInput()
            # consume startup message
            self._read_startup()

    def _read_startup(self):
        """Consume controller startup messages."""
        deadline = time.time() + 3.0
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line:
                print(f"  < {line}")

    def send(self, cmd):
        """Send a G-code command, wait for 'ok' or 'error'."""
        print(f"  > {cmd}")
        if self.dry_run:
            return
        self.conn.write((cmd + "\n").encode("ascii"))
        deadline = time.time() + TIMEOUT
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line:
                print(f"  < {line}")
            if line.startswith("ok"):
                return
            if line.startswith("error"):
                raise RuntimeError(f"GRBL error in response to '{cmd}': {line}")
        raise TimeoutError(f"Timeout waiting for 'ok' after '{cmd}'")

    def probe(self, cmd):
        """Send a probe command, return (x, y, z) of contact point.

        Parses [PRB:x,y,z:1] response. Raises on probe failure (:0).
        """
        print(f"  > {cmd}")
        if self.dry_run:
            print("  < [PRB:0.000,0.000,0.000:1] (dry-run)")
            return (0.0, 0.0, 0.0)

        self.conn.write((cmd + "\n").encode("ascii"))
        prb = None
        ok_received = False
        deadline = time.time() + TIMEOUT
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line:
                print(f"  < {line}")
            m = re.match(r"\[PRB:([^:]+):(\d)\]", line)
            if m:
                if m.group(2) == "0":
                    raise RuntimeError(f"Probe did not trigger: {line}")
                coords = [float(v) for v in m.group(1).split(",")]
                prb = tuple(coords[:3])
                if ok_received:
                    return prb  # got PRB after ok — done
            if line.startswith("ok"):
                ok_received = True
                if prb is not None:
                    return prb  # normal order: PRB then ok
                # PRB not yet received — wait a bit longer (mock/hardware latency)
                deadline = time.time() + 0.5
            if line.startswith("error"):
                raise RuntimeError(f"GRBL error during probe: {line}")
        if ok_received and prb is None:
            raise RuntimeError("Got 'ok' but no [PRB:] response — probe input may not be connected")
        raise TimeoutError("Timeout waiting for probe response")

    def feed_hold(self):
        """Send feed hold (!) immediately — no waiting for ok."""
        print("  > ! (FEED HOLD)")
        if self.dry_run:
            return
        self.conn.write(b"!")

    def safe_descend(self, z_depth, feed=None):
        """Descend to z_depth using G38.3 (probe toward, no error if no contact).

        Stops immediately if anything unexpected is in the way.
        Use instead of G0 Z for all downward moves near the workpiece.

        Args:
            z_depth: absolute machine Z target (negative = below home)
            feed: feed rate in mm/min (default: FEED_FAST)
        """
        if feed is None:
            feed = FEED_FAST
        cmd = f"G53 G38.3 Z{z_depth:.3f} F{feed}"
        print(f"  > {cmd}  (safe descent)")
        if self.dry_run:
            return
        self.conn.write((cmd + "\n").encode("ascii"))
        deadline = time.time() + TIMEOUT
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line:
                print(f"  < {line}")
            if line.startswith("ok"):
                return
            if line.startswith("error"):
                raise RuntimeError(f"Safe descent stopped unexpectedly: {line}")
        raise TimeoutError(f"Timeout during safe descent to Z{z_depth}")

    def read_g54(self):
        """Query $# and return G54 (x, y, z) offsets, or None on failure."""
        if self.dry_run:
            return (0.0, 0.0, 0.0)
        self.conn.write(b"$#\n")
        deadline = time.time() + 5.0
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line:
                print(f"  < {line}")
            m = re.match(r"\[G54:([^\]]+)\]", line)
            if m:
                coords = [float(v) for v in m.group(1).split(",")]
                return tuple(coords[:3])
        return None

    def check_state(self):
        """Query machine state, raise if alarmed."""
        if self.dry_run:
            return
        self.conn.write(b"?\n")
        deadline = time.time() + 5.0
        while time.time() < deadline:
            line = self.conn.readline().decode("ascii", errors="replace").strip()
            if line.startswith("<"):
                if "Alarm" in line:
                    raise RuntimeError(
                        f"Machine is in alarm state: {line}\n"
                        "Send $X to clear alarm or home the machine first."
                    )
                return
        raise TimeoutError("Timeout waiting for machine state response")

    def close(self):
        if self.conn:
            self.conn.close()


# Plausibility tolerances
EXPECTED_CASE_WIDTH = 113.8   # mm — expected X span (case short axis)
EXPECTED_CASE_HEIGHT = 181.8  # mm — expected Y span (case long axis)
MAX_WIDTH_ERROR = 10.0        # mm — tolerate ±10mm sizing error
MAX_ANGLE_DEG = 5.0           # degrees — abort if angle exceeds this
MAX_CENTER_ERROR = 30.0       # mm — center must be within 30mm of expected


def check_plausibility(label, value, expected, tolerance):
    """Raise if value is outside expected ± tolerance."""
    error = abs(value - expected)
    if error > tolerance:
        raise RuntimeError(
            f"Plausibility check failed: {label}\n"
            f"  Expected: {expected:.3f} ± {tolerance:.1f}\n"
            f"  Got:      {value:.3f}  (error: {error:.3f})"
        )

def probe_edge_double(grbl, axis, direction, label):
    """Probe an edge with fast then slow approach.

    Args:
        axis: 'X' or 'Y'
        direction: +1 or -1
        label: description for logging

    Returns:
        contact position along axis (machine coordinate, float)
    """
    travel = PROBE_TRAVEL_XY * direction
    retract = 2.0 * -direction

    print(f"\n--- Probing {label} ---")

    # Fast probe
    grbl.send("G91")  # incremental
    fast_result = grbl.probe(f"G38.2 {axis}{travel:.3f} F{FEED_FAST}")

    # Retract
    grbl.send(f"G0 {axis}{retract:.3f}")

    # Slow probe
    slow_travel = (PROBE_TRAVEL_XY / 5.0) * direction
    slow_result = grbl.probe(f"G38.2 {axis}{slow_travel:.3f} F{FEED_SLOW}")

    grbl.send("G90")  # back to absolute

    idx = {"X": 0, "Y": 1, "Z": 2}[axis]
    fast_contact = fast_result[idx]
    slow_contact = slow_result[idx]

    # Fast/slow agreement check
    agreement = abs(fast_contact - slow_contact)
    if agreement > 0.5:
        raise RuntimeError(
            f"Probe fast/slow disagreement on {label}: "
            f"fast={fast_contact:.4f}, slow={slow_contact:.4f}, diff={agreement:.4f}mm\n"
            "Check probe connection and ensure probe tip is clean."
        )

    print(f"    {label} contact: {axis}={slow_contact:.4f} (fast/slow agreement: {agreement:.4f}mm)")
    return slow_contact


def probe_z_surface(grbl):
    """Probe case top surface with 3D probe (while 3D probe is installed).

    Returns machine Z coordinate of case top surface contact.
    """
    print("\n--- Probing case top surface (Z) ---")
    grbl.send("G91")

    fast_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z:.3f} F{FEED_FAST}")
    grbl.send("G0 Z2.0")
    slow_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z / 5.0:.3f} F{FEED_SLOW}")
    grbl.send("G90")

    fast_z = fast_result[2]
    slow_z = slow_result[2]
    agreement = abs(fast_z - slow_z)
    if agreement > 0.5:
        raise RuntimeError(
            f"Z surface probe fast/slow disagreement: "
            f"fast={fast_z:.4f}, slow={slow_z:.4f}, diff={agreement:.4f}mm"
        )

    # The [PRB:] Z coordinate is where the probe tip contacted — this IS the
    # surface reference point (probe tip center at contact, tip radius already
    # embedded in the mock/real measurement). Use directly.
    surface_z = slow_z
    print(f"    Case top surface: Z={surface_z:.4f} (machine coords)")
    return surface_z


def probe_spoilboard(grbl):
    """Probe the spoilboard surface at the fixed reference position.

    Returns machine Z coordinate of spoilboard surface.
    Used together with surface_z_machine to compute absolute case height.
    """
    print("\n--- Probing spoilboard surface ---")
    grbl.send("G91")

    fast_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z:.3f} F{FEED_FAST}")
    grbl.send("G0 Z2.0")
    slow_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z / 5.0:.3f} F{FEED_SLOW}")
    grbl.send("G90")

    fast_z = fast_result[2]
    slow_z = slow_result[2]
    agreement = abs(fast_z - slow_z)
    if agreement > 0.5:
        raise RuntimeError(
            f"Spoilboard probe fast/slow disagreement: "
            f"fast={fast_z:.4f}, slow={slow_z:.4f}, diff={agreement:.4f}mm"
        )

    # The [PRB:] Z coordinate is the probe tip contact point — use directly
    spoilboard_z = slow_z
    print(f"    Spoilboard surface: Z={spoilboard_z:.4f} (machine coords)")
    return spoilboard_z


def probe_z_double(grbl):
    """Probe Z with fast then slow approach. Sets G54 Z0.

    Returns machine Z coordinate of contact point.
    """
    print("\n--- Probing Z ---")

    grbl.send("G91")

    # Fast probe
    fast_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z:.3f} F{FEED_FAST}")

    # Retract
    grbl.send("G0 Z2.0")

    # Slow probe
    slow_result = grbl.probe(f"G38.2 Z-{PROBE_TRAVEL_Z / 5.0:.3f} F{FEED_SLOW}")

    grbl.send("G90")

    fast_z = fast_result[2]
    slow_z = slow_result[2]
    agreement = abs(fast_z - slow_z)
    if agreement > 0.5:
        raise RuntimeError(
            f"Z probe fast/slow disagreement: "
            f"fast={fast_z:.4f}, slow={slow_z:.4f}, diff={agreement:.4f}mm"
        )

    # Set G54 Z0 at workpiece surface (account for touch plate thickness)
    grbl.send(f"G10 L20 P1 Z{TOUCH_PLATE_THICKNESS:.3f}")
    print(f"    G54 Z0 set (touch plate: {TOUCH_PLATE_THICKNESS}mm)")
    return slow_z


# === MAIN ===

def pause(msg, dry_run=False):
    """Print message and wait for user confirmation."""
    print(f"\n{'='*60}")
    print(f"  ACTION REQUIRED: {msg}")
    print(f"{'='*60}")
    if dry_run:
        print("  [dry-run: skipping]")
        return
    input("  Press Enter to continue...")


def run(args):
    grbl = GrblConnection(args.port, BAUD, dry_run=args.dry_run)

    try:
        # Verify machine state
        print("\n[1/9] Checking machine state...")

        # Check gSender is not running (it would hold the serial port)
        if not args.dry_run:
            result = subprocess.run(["pgrep", "-f", "gsender"], capture_output=True)
            if result.returncode == 0:
                print("ERROR: gSender is running. Close it first (it holds the serial port).", file=sys.stderr)
                sys.exit(1)

        grbl.check_state()

        # Safe home: Z first to clear workpiece, then X and Y
        print("\n[2/9] Homing machine (Z first for safety)...")
        grbl.send("$HZ")  # home Z first — clears probe from workpiece
        grbl.send("$HX")  # home X
        grbl.send("$HY")  # home Y

        # Probe spoilboard at reference position (3D probe not yet installed —
        # use touch plate clipped to a known conductive surface, or install probe first)
        # NOTE: spoilboard probe uses 3D probe, so do it after install pause below.

        # Move to tool change position
        grbl.send(f"G53 G0 Z0")
        grbl.send(f"G53 G0 X{TOOL_CHANGE_X} Y{TOOL_CHANGE_Y}")

        pause("Install 3D probe (HLTNC). Ensure probe is connected to probe input.", dry_run=args.dry_run)

        # Raise to safe Z
        grbl.send("G90")
        grbl.send(f"G53 G0 Z0")

        # === SPOILBOARD PROBE ===
        print("\n[3/9] Probing spoilboard reference surface...")
        grbl.send(f"G53 G0 X{SPOILBOARD_PROBE_X:.3f} Y{SPOILBOARD_PROBE_Y:.3f}")
        grbl.safe_descend(-(SAFE_Z + 5))  # lower to probing height safely
        spoilboard_z = probe_spoilboard(grbl)
        grbl.send(f"G53 G0 Z0")

        # === XY PROBING ===
        print("\n[4/9] Probing case edges for center and angle...")

        # Compute XY probe Z: 5mm below expected case top surface
        # spoilboard_z is probe tip contact on spoilboard (machine coords, negative)
        # case top = spoilboard_z + CASE_HEIGHT_NOMINAL (less negative = closer to Z home)
        xy_probe_z = spoilboard_z + CASE_HEIGHT_NOMINAL - XY_PROBE_BELOW_SURFACE
        print(f"    XY probe Z: {xy_probe_z:.3f}mm (spoilboard={spoilboard_z:.3f} + case={CASE_HEIGHT_NOMINAL}mm - {XY_PROBE_BELOW_SURFACE}mm)")

        # Probe X- edge
        grbl.send(f"G53 G0 X{CASE_CENTER_X - CASE_HALF_WIDTH - APPROACH_CLEARANCE:.3f} Y{CASE_CENTER_Y:.3f}")
        grbl.safe_descend(xy_probe_z)  # lower to probing height safely
        x_minus = probe_edge_double(grbl, "X", +1, "X- edge")
        grbl.send(f"G53 G0 Z0")

        # Probe X+ edge
        grbl.send(f"G53 G0 X{CASE_CENTER_X + CASE_HALF_WIDTH + APPROACH_CLEARANCE:.3f} Y{CASE_CENTER_Y:.3f}")
        grbl.safe_descend(xy_probe_z)  # lower to probing height safely
        x_plus = probe_edge_double(grbl, "X", -1, "X+ edge")
        grbl.send(f"G53 G0 Z0")

        # Probe Y- edge left (for angle)
        grbl.send(f"G53 G0 X{ANGLE_PROBE_X_LEFT:.3f} Y{CASE_CENTER_Y - CASE_HALF_HEIGHT - APPROACH_CLEARANCE:.3f}")
        grbl.safe_descend(xy_probe_z)  # lower to probing height safely
        y_minus_left = probe_edge_double(grbl, "Y", +1, "Y- edge (left)")
        grbl.send(f"G53 G0 Z0")

        # Probe Y- edge right (for angle)
        grbl.send(f"G53 G0 X{ANGLE_PROBE_X_RIGHT:.3f} Y{CASE_CENTER_Y - CASE_HALF_HEIGHT - APPROACH_CLEARANCE:.3f}")
        grbl.safe_descend(xy_probe_z)  # lower to probing height safely
        y_minus_right = probe_edge_double(grbl, "Y", +1, "Y- edge (right)")
        grbl.send(f"G53 G0 Z0")

        # === COMPUTE CENTER AND ANGLE ===
        print("\n[5/9] Computing center and angle...")

        # Account for probe tip radius and case geometry
        # X: probed both sides, center is midpoint (tip radius cancels out)
        center_x = (x_minus + x_plus) / 2.0
        # Y: only probed Y- edge from below (+Y direction)
        # contact = center_y - CASE_HALF_HEIGHT + PROBE_TIP_RADIUS
        # → center_y = contact + CASE_HALF_HEIGHT - PROBE_TIP_RADIUS
        y_minus_avg = (y_minus_left + y_minus_right) / 2.0
        center_y = y_minus_avg + CASE_HALF_HEIGHT - PROBE_TIP_RADIUS

        # Angle from Y- edge (two points at known X separation)
        dx = ANGLE_PROBE_X_RIGHT - ANGLE_PROBE_X_LEFT
        dy = y_minus_right - y_minus_left
        angle_deg = math.degrees(math.atan2(dy, dx))

        print(f"    Case center: X={center_x:.4f} Y={center_y:.4f}")
        print(f"    Rotation angle: {angle_deg:.4f}°")

        # Plausibility checks
        if not args.dry_run:
            # X- must be left of X+
            if x_minus >= x_plus:
                raise RuntimeError(
                    f"X- edge ({x_minus:.4f}) is not left of X+ edge ({x_plus:.4f}). "
                    "Check case position and probe approach directions."
                )

            measured_width = abs(x_plus - x_minus) - 2 * PROBE_TIP_RADIUS
            check_plausibility("case X width", measured_width, EXPECTED_CASE_WIDTH, MAX_WIDTH_ERROR)
            check_plausibility("case center X", center_x, CASE_CENTER_X, MAX_CENTER_ERROR)
            check_plausibility("case center Y", center_y, CASE_CENTER_Y, MAX_CENTER_ERROR)
            check_plausibility("rotation angle", angle_deg, 0.0, MAX_ANGLE_DEG)
            print("    Plausibility checks passed ✓")
        else:
            print("    Plausibility checks skipped (dry-run)")

        # Set G54 X0 Y0 at case center
        grbl.send(f"G10 L20 P1 X{center_x:.4f} Y{center_y:.4f}")

        # Verify G54 was accepted — $# must return a parseable G54 entry
        if not args.dry_run:
            g54 = grbl.read_g54()
            if g54 is None:
                raise RuntimeError("G54 readback failed — $# returned no G54 entry")
            print(f"    G54 readback confirmed: offset X={g54[0]:.4f} Y={g54[1]:.4f} Z={g54[2]:.4f} ✓")
        print("    G54 X0 Y0 set at case center")

        # === Z SURFACE PROBE (3D probe still installed) ===
        print("\n[6/9] Probing case top surface with 3D probe...")
        grbl.send(f"G53 G0 Z0")  # full Z retract before lateral move
        grbl.send(f"G53 G0 X{center_x:.3f} Y{center_y:.3f}")
        grbl.safe_descend(-(SAFE_Z + 5))  # lower to probing height safely
        surface_z_machine = probe_z_surface(grbl)
        grbl.send(f"G53 G0 Z0")  # retract to Z home before tool change

        # Case height plausibility check
        if not args.dry_run:
            case_height = surface_z_machine - spoilboard_z
            print(f"    Measured case height: {case_height:.3f}mm (expected {CASE_HEIGHT_NOMINAL}mm)")
            check_plausibility("case height", case_height, CASE_HEIGHT_NOMINAL, 3.0)

        # === TOOL CHANGE ===
        print("\n[7/9] Moving to tool change position...")
        grbl.send(f"G53 G0 X{TOOL_CHANGE_X} Y{TOOL_CHANGE_Y}")

        pause("Remove 3D probe. Install cutting tool (4mm single flute).", dry_run=args.dry_run)

        # === Z PROBING ===
        print("\n[8/9] Probing Z...")

        # Full Z retract before lateral move (unknown tool length after change)
        grbl.send(f"G53 G0 Z0")
        grbl.send(f"G53 G0 X{center_x:.3f} Y{center_y:.3f}")
        grbl.safe_descend(-(SAFE_Z + 5))  # lower to probing height safely

        pause(f"Place touch plate ({TOUCH_PLATE_THICKNESS}mm) on workpiece at case center. Clip ground wire to cutting tool.", dry_run=args.dry_run)

        cutting_tool_z = probe_z_double(grbl)

        # Retract BEFORE asking to remove touch plate
        grbl.send(f"G53 G0 Z0")

        pause("Remove touch plate and ground wire.", dry_run=args.dry_run)

        # Cross-check: 3D probe surface Z vs cutting tool Z
        # The touch plate sits ON TOP of the case surface.
        # surface_z_machine = case_top_z (probe tip center at contact)
        # cutting_tool_z = touch_plate_top_z (tool tip center at contact)
        # touch_plate_top = surface_z_machine + TOUCH_PLATE_THICKNESS
        # (higher = less negative in machine coords = closer to Z home)
        if not args.dry_run:
            expected_tool_z = surface_z_machine + TOUCH_PLATE_THICKNESS
            z_discrepancy = abs(cutting_tool_z - expected_tool_z)
            print(f"\n    Z cross-check:")
            print(f"      3D probe surface Z:    {surface_z_machine:.4f}")
            print(f"      Expected tool contact: {expected_tool_z:.4f}")
            print(f"      Actual tool contact:   {cutting_tool_z:.4f}")
            print(f"      Discrepancy:           {z_discrepancy:.4f}mm")
            if z_discrepancy > 2.0:
                raise RuntimeError(
                    f"Z cross-check failed: discrepancy {z_discrepancy:.4f}mm > 2.0mm\n"
                    "Possible causes: touch plate on wrong surface, wrong plate thickness, "
                    "tool not seated in collet, or 3D probe tip radius incorrect."
                )
            print(f"      Z cross-check passed ✓")

        # === GENERATE G-CODE ===
        print("\n[9/9] Generating G-code...")
        cmd = [
            sys.executable,
            str(GCODE_GENERATOR),
            "--origin", "center",
            "--angle", f"{angle_deg:.4f}",
        ]
        print(f"    Running: {' '.join(cmd)}")
        if not args.dry_run:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"ERROR generating G-code:\n{result.stderr}", file=sys.stderr)
                sys.exit(1)
            GCODE_OUTPUT.write_text(result.stdout)
            print(f"    Written: {GCODE_OUTPUT}")

        print("\n" + "="*60)
        print("  SETUP COMPLETE")
        print(f"  Angle: {angle_deg:.4f}°")
        print(f"  G-code: {GCODE_OUTPUT}")
        print("="*60)

        # Launch gSender
        if not args.dry_run and Path(SENDER_LAUNCH).exists():
            print(f"\nLaunching gSender...")
            subprocess.Popen([SENDER_LAUNCH])

    except Exception as e:
        print(f"\n{'!'*60}", file=sys.stderr)
        print(f"  ERROR: {e}", file=sys.stderr)
        print(f"  Sending feed hold...", file=sys.stderr)
        grbl.feed_hold()
        print(f"{'!'*60}", file=sys.stderr)
        sys.exit(1)
    finally:
        grbl.close()


def parse_args():
    p = argparse.ArgumentParser(description="Probe setup for pedalboard case top panel")
    p.add_argument("--port", default=PORT,
                   help=f"Serial port (default: {PORT})")
    p.add_argument("--dry-run", action="store_true",
                   help="Print commands without connecting to machine")
    return p.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run(args)
