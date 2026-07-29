#!/bin/bash
# Apply grblHAL settings to Flexi-HAL controller
# Usage: ./apply-settings.sh [port]
# Default port: /dev/cnc

set -euo pipefail

PORT="${1:-/dev/cnc}"
SETTINGS="$(dirname "$0")/settings.txt"

if [ ! -c "$PORT" ] && [ ! -L "$PORT" ]; then
    echo "ERROR: Port $PORT not found. Is the Flexi-HAL connected?"
    exit 1
fi

echo "Applying grblHAL settings to $PORT..."
echo "Settings file: $SETTINGS"
echo ""

# Configure serial port
stty -F "$PORT" 115200 raw -echo

# Send each setting line
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*\; ]] && continue

    echo "  > $line"
    echo "$line" > "$PORT"
    sleep 0.1

    # Read response
    timeout 1 cat "$PORT" 2>/dev/null | head -1 || true
done < "$SETTINGS"

echo ""
echo "Done. Verify with: echo '$$' > $PORT"
