#!/usr/bin/env bash
# actual-planner status — show planner work queue for the current rig.
set -euo pipefail

echo "── actual-planner ───────────────────────────────────────────"
echo "Open planning work (label=needs-plan):"
bd ready --label=needs-plan 2>/dev/null || echo "  (none)"
echo
echo "Recently-closed planning beads:"
bd list --label=source:actual-planner --status=closed --limit=5 2>/dev/null || echo "  (none)"
