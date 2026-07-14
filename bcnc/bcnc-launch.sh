#!/bin/bash
# Launch bCNC with proper DPI scaling for Sway 1.5x
export TK_SCALING=2.0
exec /home/laenzi/projects/gh/laenzlinger/cnc/bcnc/.venv/bin/bCNC "$@"
