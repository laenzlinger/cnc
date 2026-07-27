#!/usr/bin/env python3
"""
Generate G-code for surfacing the SRcnc wasteboard.

Skim pass to flatten the MDF wasteboard and establish a true Z reference.
Run this after tramming the spindle.

Origin: machine center X110 Y190, Z0 = current wasteboard surface.
Uses G53 machine coordinates — no workpiece setup needed, just home the machine.

Usage:
    python3 surfacing.py > surfacing.nc
    python3 surfacing.py --depth 0.3 --feed 1500 > surfacing.nc
"""

import argparse
import math


def parse_args():
    p = argparse.ArgumentParser(description="Wasteboard surfacing G-code generator")
    p.add_argument("--tool-dia", type=float, default=20.2,
                   help="Endmill diameter in mm (default: 20.2)")
    p.add_argument("--stepover", type=float, default=0.4,
                   help="Stepover as fraction of tool diameter (default: 0.4)")
    p.add_argument("--depth", type=float, default=0.5,
                   help="Depth of cut in mm (default: 0.5)")
    p.add_argument("--feed", type=float, default=2000,
                   help="Feed rate in mm/min (default: 2000)")
    p.add_argument("--feed-z", type=float, default=200,
                   help="Plunge feed rate in mm/min (default: 200)")
    p.add_argument("--spindle-rpm", type=int, default=10000,
                   help="Spindle speed in RPM (default: 10000)")
    p.add_argument("--width", type=float, default=210,
                   help="Surfacing width in mm (default: 210, X axis)")
    p.add_argument("--length", type=float, default=370,
                   help="Surfacing length in mm (default: 370, Y axis)")
    p.add_argument("--safe-z", type=float, default=5.0,
                   help="Safe Z height in mm (default: 5.0)")
    return p.parse_args()


def generate(args):
    tool_r = args.tool_dia / 2.0
    stepover_mm = args.tool_dia * args.stepover

    # Machine center
    cx = 110.0
    cy = 190.0

    # Surfacing area — use full machine travel
    # Tool center must stay within travel limits
    # Cutting edge extends tool_r beyond center, reaching the physical edges
    x_min = 0.0
    x_max = cx * 2       # = 220mm (full X travel)
    y_min = 0.0
    y_max = cy * 2       # = 380mm (full Y travel)

    # Toolpath starts at y_min, tool center offset by tool_r
    y_start = y_min + tool_r
    y_end   = y_max - tool_r
    x_start = x_min + tool_r
    x_end   = x_max - tool_r

    # Number of passes along X
    n_passes = math.ceil((x_end - x_start) / stepover_mm) + 1
    actual_stepover = (x_end - x_start) / max(n_passes - 1, 1)

    lines = []
    def emit(line=""):
        lines.append(line)

    emit(f"(Wasteboard surfacing — SRcnc)")
    emit(f"(Tool: {args.tool_dia}mm endmill, {args.stepover*100:.0f}% stepover = {stepover_mm:.1f}mm)")
    emit(f"(Area: full machine travel {cx*2:.0f}x{cy*2:.0f}mm in G53 coords)")
    emit(f"(Depth: {args.depth}mm, Feed: {args.feed}mm/min)")
    emit(f"(Passes: {n_passes}, actual stepover: {actual_stepover:.2f}mm)")
    emit(f"(Precondition: probe Z with touch plate on wasteboard before running)")
    emit(f"(  G54 Z0 = wasteboard surface, XY in machine coords via G53)")
    emit()
    emit("G21 (mm)")
    emit("G90 (absolute)")
    emit()
    emit(f"M3 S{args.spindle_rpm}")
    emit("G4 P2 (spindle spin-up)")
    emit()

    # Move to start position
    emit(f"G53 G0 Z0")
    emit(f"G53 G0 X{x_start:.3f} Y{y_start:.3f}")
    emit(f"G1 Z-{args.depth:.3f} F{args.feed_z} (cut depth relative to probed wasteboard surface)")
    emit()

    # Boustrophedon (zigzag) passes along Y, stepping in X
    for i in range(n_passes):
        x = x_start + i * actual_stepover
        if i % 2 == 0:
            y_from, y_to = y_start, y_end
        else:
            y_from, y_to = y_end, y_start

        if i == 0:
            emit(f"G53 G1 Y{y_to:.3f} F{args.feed}")
        else:
            emit(f"G53 G1 X{x:.3f} F{args.feed}  (pass {i+1}/{n_passes})")
            emit(f"G53 G1 Y{y_to:.3f} F{args.feed}")

    emit()
    emit(f"G0 Z{args.safe_z} (retract to safe height)")
    emit(f"G53 G0 Z0")
    emit("M5")
    emit("G53 G0 X0 Y0")
    emit("M2")

    return "\n".join(lines)


if __name__ == "__main__":
    args = parse_args()
    print(generate(args))
