#!/usr/bin/env bash
set -euo pipefail

# Run gc doctor with auto-fix for all installed factories
# Usage: doctor.sh [factory-dir]

FACTORY_ROOT="$HOME/Projects/factory"

if ! command -v gc &>/dev/null; then
    echo "Error: 'gc' (Gas City CLI) not found on PATH."
    echo "Install: brew install gastownhall/gascity/gascity"
    exit 1
fi

echo "=== Gas City Doctor ==="
echo ""

if [[ $# -ge 1 ]]; then
    # Run doctor for a specific factory
    echo "Running gc doctor --fix for: $1"
    gc doctor --fix --city "$1"
    exit $?
fi

# Run doctor for all installed factories
ACTIVITY_SLUGS=(
    "workshop_w1:w1" "workshop_w2:w2" "workshop_w3:w3" "workshop_w4:w4"
    "lab_l1:l1" "lab_l2:l2" "lab_l3:l3" "lab_l4:l4"
    "capstone_c1:c1"
    "baseline_b1:b1"
)

found=0
for entry in "${ACTIVITY_SLUGS[@]}"; do
    IFS=: read -r slug alias <<< "$entry"
    factory_dir="$FACTORY_ROOT/$slug/${alias}-gc-factory"
    if [[ -d "$factory_dir" ]]; then
        found=1
        echo "--- [$alias] $factory_dir ---"
        gc doctor --fix --city "$factory_dir" 2>&1 || true
        echo ""
    fi
done

if [[ $found -eq 0 ]]; then
    echo "No installed factories found under $FACTORY_ROOT"
    echo "Run gc doctor in a specific factory directory instead."
fi
