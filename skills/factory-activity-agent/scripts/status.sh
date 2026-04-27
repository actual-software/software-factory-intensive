#!/usr/bin/env bash
set -euo pipefail

# Show status of all registered Gas City factories and installed activities
# Usage: status.sh [--list]

FACTORY_ROOT="$HOME/Projects/factory"

ACTIVITY_MAP=(
    "W1:workshops:workshop_w1:w1"
    "W2:workshops:workshop_w2:w2"
    "W3:workshops:workshop_w3:w3"
    "W4:workshops:workshop_w4:w4"
    "L1:labs:lab_l1:l1"
    "L2:labs:lab_l2:l2"
    "L3:labs:lab_l3:l3"
    "L4:labs:lab_l4:l4"
    "C1:capstone:capstone_c1:c1"
    "B1:baseline:baseline_b1:b1"
)

echo "=== Gas City Factory Status ==="
echo ""

# gc version
if command -v gc &>/dev/null; then
    echo "gc version: $(gc version 2>/dev/null || echo 'unknown')"
else
    echo "gc: NOT FOUND (install with: brew install gastownhall/gascity/gascity)"
    exit 1
fi
echo ""

# Activity install status
echo "--- Installed Activities ---"
printf "%-10s %-12s %-10s %s\n" "Activity" "Category" "Installed" "Factory Dir"
echo "------------------------------------------------------------------------"
for entry in "${ACTIVITY_MAP[@]}"; do
    IFS=: read -r activity category slug alias <<< "$entry"
    factory_dir="$FACTORY_ROOT/$slug/${alias}-gc-factory"
    if [[ -d "$factory_dir" ]]; then
        installed="YES"
    else
        installed="no"
    fi
    printf "%-10s %-12s %-10s %s\n" "$activity" "$category" "$installed" "$factory_dir"
done
echo ""

# Registered cities
echo "--- Registered Cities ---"
gc cities 2>/dev/null || echo "(none or gc not available)"
echo ""

# Status for each installed factory
if [[ "$*" != *"--list"* ]]; then
    echo "--- Factory Agent Status ---"
    for entry in "${ACTIVITY_MAP[@]}"; do
        IFS=: read -r activity category slug alias <<< "$entry"
        factory_dir="$FACTORY_ROOT/$slug/${alias}-gc-factory"
        if [[ -d "$factory_dir" ]]; then
            echo ""
            echo "[$activity] $factory_dir"
            gc status --city "$factory_dir" 2>/dev/null || echo "  (unable to get status)"
        fi
    done
fi

echo ""
echo "Dashboard: http://localhost:8080 (if running)"
