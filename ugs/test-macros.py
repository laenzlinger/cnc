#!/usr/bin/env python3
"""
test-macros.py — Simulate UGS macros against the mock machine to catch crashes.

Runs each macro through a simulated machine state and checks for:
- Z position going below touch plate surface during execution
- Probe not triggering (probe too far from surface)
- Any GRBL errors

Usage:
    python3 test-macros.py
    python3 test-macros.py --touch-plate-z -50  # simulate plate at Z=-50 machine coords
"""

import argparse
import json
import math
import re
import sys
from pathlib import Path

# === CONFIGURATION ===

REPO_ROOT = Path(__file__).parent.parent
UGS_CONFIG = REPO_ROOT / "ugs" / "UniversalGcodeSender.json"

TOUCH_PLATE_THICKNESS = 19.25  # mm
PROBE_TIP_RADIUS = 2.0


class SimMachine:
    """Minimal G-code interpreter for macro validation."""

    def __init__(self, touch_plate_z=-30.0, touch_plate_thickness=TOUCH_PLATE_THICKNESS):
        self.pos = [0.0, 0.0, 0.0]  # X, Y, Z in G54 coords
        self.incremental = False
        self.g54 = [0.0, 0.0, 0.0]  # WCS offsets
        self.touch_plate_z = touch_plate_z          # Z machine coord of touch plate top
        self.workpiece_z = touch_plate_z - touch_plate_thickness  # Z machine coord of workpiece
        self.min_z_reached = 0.0   # track lowest Z in G54 coords
        self.errors = []
        self.warnings = []
        self.history = []  # (cmd, z_machine) tuples

    def machine_z(self):
        """Current Z in machine coordinates."""
        return self.pos[2] + self.g54[2]

    def process(self, cmd):
        cmd = cmd.strip()
        if not cmd or cmd.startswith(';') or cmd.startswith('('):
            return

        self.history.append(cmd)

        # Handle G91/G90 modal codes even if combined with other codes
        if re.search(r'\bG91\b', cmd, re.I):
            self.incremental = True
        if re.search(r'\bG90\b', cmd, re.I):
            self.incremental = False

        # G10 L20 — set WCS
        m = re.match(r'.*G10\s+L20\s+P\d+\s+(.*)', cmd, re.I)
        if m:
            for am in re.finditer(r'([XYZ])([+-]?\d+\.?\d*)', m.group(1), re.I):
                axis = am.group(1).upper()
                val = float(am.group(2))
                idx = ['X','Y','Z'].index(axis)
                self.g54[idx] = self.pos[idx] + self.g54[idx] - val
                if axis == 'Z':
                    self.pos[2] = self.machine_z() - self.g54[2]
            return

        # G38.x probe
        if re.search(r'G38\.[2345]', cmd, re.I):
            m = re.search(r'G38\.[2345]\s+Z([+-]?\d+\.?\d*)', cmd, re.I)
            if m:
                travel = float(m.group(1))
                if self.incremental:
                    target_z_g54 = self.pos[2] + travel
                else:
                    target_z_g54 = travel
                target_z_machine = target_z_g54 + self.g54[2]

                current_z_machine = self.pos[2] + self.g54[2]
                if travel < 0 and target_z_machine <= self.touch_plate_z:
                    contact_z_g54 = self.touch_plate_z - self.g54[2]
                    self.pos[2] = contact_z_g54
                    self.min_z_reached = min(self.min_z_reached, self.pos[2])
                else:
                    self.pos[2] = target_z_g54
                    self.min_z_reached = min(self.min_z_reached, self.pos[2])
                    if re.search(r'G38\.2', cmd, re.I):
                        self.errors.append(
                            f"Probe did not trigger: {cmd} "
                            f"(target Z_machine={target_z_machine:.2f}, "
                            f"plate at Z_machine={self.touch_plate_z:.2f}, "
                            f"current Z_machine={current_z_machine:.2f})")
            return

        # G0/G1 move
        if re.search(r'\bG[01]\b', cmd, re.I):
            # G53 overrides WCS — use machine coords directly
            is_g53 = bool(re.search(r'\bG53\b', cmd, re.I))
            for am in re.finditer(r'([XYZ])([+-]?\d+\.?\d*)', cmd, re.I):
                axis = am.group(1).upper()
                val = float(am.group(2))
                idx = ['X','Y','Z'].index(axis)
                if is_g53:
                    # G53: value is machine coord, convert to G54
                    self.pos[idx] = val - self.g54[idx]
                elif self.incremental:
                    self.pos[idx] += val
                else:
                    self.pos[idx] = val
            self.min_z_reached = min(self.min_z_reached, self.pos[2])

            # Check: did Z go below workpiece surface?
            z_machine = self.machine_z()
            workpiece_z_g54 = self.workpiece_z - self.g54[2]
            if self.pos[2] < workpiece_z_g54 - 0.1:
                self.errors.append(
                    f"CRASH: Z={self.pos[2]:.3f} (G54) = {z_machine:.3f} (machine), "
                    f"below workpiece {workpiece_z_g54:.3f} (G54): {cmd}"
                )
            plate_top_g54 = self.touch_plate_z - self.g54[2]
            if workpiece_z_g54 < self.pos[2] < plate_top_g54:
                self.errors.append(
                    f"CRASH: Z={self.pos[2]:.3f} (G54) moves into touch plate "
                    f"(plate occupies {workpiece_z_g54:.3f} to {plate_top_g54:.3f} G54): {cmd}"
                )


def run_macro(name, gcode, touch_plate_z):
    """Run a macro and return (errors, warnings)."""
    sim = SimMachine(touch_plate_z=touch_plate_z)

    # For probe macros, start tool 25mm above touch plate (as per workflow)
    # This simulates the user jogging to within 30mm of the plate
    if any(c for c in gcode.split(';') if 'G38' in c.upper()):
        sim.pos[2] = (touch_plate_z + 25.0) - sim.g54[2]  # 25mm above plate in G54

    # Split on semicolons (UGS macro separator)
    commands = [c.strip() for c in gcode.split(';') if c.strip()]

    for cmd in commands:
        sim.process(cmd)

    return sim.errors, sim.warnings, sim


def main():
    p = argparse.ArgumentParser(description="Test UGS macros against mock machine")
    p.add_argument("--touch-plate-z", type=float, default=-30.0,
                   help="Touch plate top Z in machine coords (default: -30.0)")
    p.add_argument("--config", type=str, default=str(UGS_CONFIG),
                   help=f"UGS config file (default: {UGS_CONFIG})")
    args = p.parse_args()

    config_path = Path(args.config)
    if not config_path.exists():
        print(f"ERROR: Config not found: {config_path}", file=sys.stderr)
        sys.exit(1)

    with open(config_path) as f:
        # UGS JSON may contain NaN — handle it
        content = f.read().replace(': NaN', ': null')
        config = json.loads(content)

    macros = config.get("macros", {})
    if not macros:
        print("No macros found in config.")
        sys.exit(0)

    print(f"Testing {len(macros)} macros (touch plate Z={args.touch_plate_z}mm)")
    print(f"  Touch plate thickness: {TOUCH_PLATE_THICKNESS}mm")
    print(f"  Workpiece surface Z: {args.touch_plate_z - TOUCH_PLATE_THICKNESS:.2f}mm (machine coords)")
    print()

    all_ok = True
    for key in sorted(macros.keys()):
        macro = macros[key]
        name = macro.get("name", f"Macro {key}")
        gcode = macro.get("gcode", "")

        errors, warnings, sim = run_macro(name, gcode, args.touch_plate_z)

        status = "✓" if not errors else "✗"
        print(f"  {status} Macro {key}: {name}")
        print(f"    G-code: {gcode}")
        print(f"    Final Z (G54): {sim.pos[2]:.3f}mm  Min Z reached: {sim.min_z_reached:.3f}mm")

        for w in warnings:
            print(f"    ⚠ {w}")
        for e in errors:
            print(f"    ✗ {e}")
            all_ok = False
        print()

    if all_ok:
        print("All macros passed ✓")
        sys.exit(0)
    else:
        print("Some macros FAILED ✗", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
