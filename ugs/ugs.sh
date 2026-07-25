#!/usr/bin/env bash
set -euo pipefail

# Launch UGS Platform for SRcnc
# Workarounds for Java/Swing under Sway/Wayland

# Java AWT doesn't handle Wayland window reparenting
export _JAVA_AWT_WM_NONREPARENTING=1

# Force X11 backend via XWayland
export GDK_BACKEND=x11

# UGS requires Java 17+ (using 21 LTS)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# Font rendering: enable LCD subpixel antialiasing and hinting
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true"

exec /usr/share/java/ugsplatform/bin/ugsplatform --jdkhome "$JAVA_HOME" "$@"
