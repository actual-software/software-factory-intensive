#!/usr/bin/env bash
set -euo pipefail
echo "── actual-planner ──────────────────────────────────────────────"
echo "Open planning work (label=needs-plan):"
bd ready --label=needs-plan 2>/dev/null || echo "  (none)"
echo
echo "Active plans:"
if [ -d .actual/plans ]; then
    ls -1 .actual/plans/*.md 2>/dev/null | sed 's|^|  |' || echo "  (none)"
else
    echo "  (none)"
fi
echo
if [ -f .actual/planner/tracker-sync.json ]; then
    COUNT=$(jq '.mappings | length' .actual/planner/tracker-sync.json 2>/dev/null || echo 0)
    echo "Tracker-sync manifest: $COUNT issues mapped"
else
    echo "Tracker-sync manifest: (not yet run)"
fi
