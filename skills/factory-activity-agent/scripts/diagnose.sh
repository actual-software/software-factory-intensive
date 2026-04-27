#!/usr/bin/env bash
set -euo pipefail

# Full environment diagnostic for factory_activity_agent
# Checks all prerequisites, registered cities, and factory health

FACTORY_ROOT="$HOME/Projects/factory"
EXPECTED_GC_VERSION="0.14.1"

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; }
info() { echo "  INFO  $1"; }
section() { echo ""; echo "--- $1 ---"; }

echo "=== Factory Activity Agent — Environment Diagnostic ==="

# Section 1: gc binary
section "Gas City CLI (gc)"
if command -v gc &>/dev/null; then
    pass "gc found at $(which gc)"
    GC_VER="$(gc version 2>/dev/null || echo 'unknown')"
    if echo "$GC_VER" | grep -q "$EXPECTED_GC_VERSION"; then
        pass "gc version: $GC_VER (matches expected $EXPECTED_GC_VERSION)"
    else
        fail "gc version: $GC_VER (expected $EXPECTED_GC_VERSION)"
    fi
else
    fail "gc not found on PATH"
    info "Install: brew install gastownhall/gascity/gascity"
fi

# Section 2: Python
section "Python"
if command -v python3 &>/dev/null; then
    pass "python3 found at $(which python3)"
    info "python3 version: $(python3 --version 2>&1)"
else
    fail "python3 not found on PATH"
fi

# Section 3: bd (beads)
section "Beads CLI (bd)"
if command -v bd &>/dev/null; then
    pass "bd found at $(which bd)"
else
    fail "bd not found on PATH"
fi

# Section 4: factory_activity_agent.py
section "Factory Activity Agent Script"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Resolve through symlinks to find the real SFI repo root
REAL_SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")" && pwd)"
SFI_DIR="$(cd "$REAL_SCRIPT_DIR/../../.." && pwd)"
AGENT_SCRIPT="$SFI_DIR/scripts/factory_activity_agent.py"
if [[ -f "$AGENT_SCRIPT" ]]; then
    pass "factory_activity_agent.py found at $AGENT_SCRIPT"
else
    fail "factory_activity_agent.py not found at $AGENT_SCRIPT"
fi

# Section 5: Registered cities
section "Registered Cities"
if command -v gc &>/dev/null; then
    CITIES="$(gc cities 2>/dev/null || echo '')"
    if [[ -n "$CITIES" ]]; then
        info "Registered cities:"
        echo "$CITIES" | sed 's/^/    /'
    else
        info "No cities currently registered"
    fi
fi

# Section 6: Factory directories
section "Factory Directories"
if [[ -d "$FACTORY_ROOT" ]]; then
    pass "Factory root exists: $FACTORY_ROOT"
    ACTIVITY_SLUGS=(
        "W1:workshop_w1:w1" "W2:workshop_w2:w2" "W3:workshop_w3:w3" "W4:workshop_w4:w4"
        "L1:lab_l1:l1" "L2:lab_l2:l2" "L3:lab_l3:l3" "L4:lab_l4:l4"
        "C1:capstone_c1:c1"
        "B1:baseline_b1:b1"
    )
    for entry in "${ACTIVITY_SLUGS[@]}"; do
        IFS=: read -r activity slug alias <<< "$entry"
        factory_dir="$FACTORY_ROOT/$slug/${alias}-gc-factory"
        project_dir="$FACTORY_ROOT/$slug/${alias}-project"
        if [[ -d "$factory_dir" ]]; then
            pass "$activity: factory=$factory_dir"
            if [[ -d "$project_dir" ]]; then
                pass "$activity: project=$project_dir"
            else
                fail "$activity: project dir missing at $project_dir"
            fi
        else
            info "$activity: not installed"
        fi
    done
else
    info "Factory root does not exist: $FACTORY_ROOT (no activities installed)"
fi

# Section 7: Activity packs
section "Activity Packs (source)"
for activity in W1 W2 W3 W4 L1 L2 L3 L4 C1 B1; do
    case "$activity" in
        W*) category="workshops" ;;
        L*) category="labs" ;;
        C*) category="capstone" ;;
        B*) category="baseline" ;;
    esac
    packs_dir="$SFI_DIR/activities/$category/$activity/gascity/step_0/packs"
    if [[ -d "$packs_dir" ]]; then
        pass "$activity: packs found at $packs_dir"
    else
        info "$activity: no packs yet at $packs_dir"
    fi
done

echo ""
echo "=== Diagnostic Complete ==="
