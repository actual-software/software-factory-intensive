#!/usr/bin/env bash
set -euo pipefail

# Wrapper for factory_activity_agent.py install
# Usage: install.sh <activity> [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Resolve through symlinks to find the real SFI repo root
REAL_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")" && pwd)"
SFI_DIR="$(cd "$REAL_SCRIPT_DIR/../../.." && pwd)"
AGENT_SCRIPT="$SFI_DIR/scripts/factory_activity_agent.py"

VALID_ACTIVITIES="W1 W2 W3 W4 L1 L2 L3 L4 C1 B1"

usage() {
    echo "Usage: $0 <activity> [--dry-run]"
    echo ""
    echo "Activities: $VALID_ACTIVITIES"
    echo ""
    echo "Options:"
    echo "  --dry-run    Print commands without executing"
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

ACTIVITY="$1"
DRY_RUN=""

if [[ $# -ge 2 && "$2" == "--dry-run" ]]; then
    DRY_RUN="--mode dry-run"
fi

# Validate activity
if ! echo "$VALID_ACTIVITIES" | grep -qw "$ACTIVITY"; then
    echo "Error: Invalid activity '$ACTIVITY'"
    echo "Valid activities: $VALID_ACTIVITIES"
    exit 1
fi

# Pre-flight checks
if ! command -v gc &>/dev/null; then
    echo "Error: 'gc' (Gas City CLI) not found on PATH."
    echo "Install: brew install gastownhall/gascity/gascity"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Error: 'python3' not found on PATH."
    exit 1
fi

if [[ ! -f "$AGENT_SCRIPT" ]]; then
    echo "Error: factory_activity_agent.py not found at $AGENT_SCRIPT"
    exit 1
fi

echo "==> Installing activity $ACTIVITY"
echo "    SFI directory: $SFI_DIR"
echo "    gc version: $(gc version 2>/dev/null || echo 'unknown')"
echo ""

# shellcheck disable=SC2086
python3 "$AGENT_SCRIPT" install "$ACTIVITY" $DRY_RUN

echo ""
echo "==> Install complete for $ACTIVITY"
