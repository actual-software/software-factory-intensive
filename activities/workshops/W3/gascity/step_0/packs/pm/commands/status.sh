#!/usr/bin/env bash
set -euo pipefail
echo "── actual-pm ──────────────────────────────────────────────"
echo "Open planning work (label=needs-pm):"
bd ready --label=needs-pm 2>/dev/null || echo "  (none)"
echo
echo "Active plans:"
if [ -d .actual/plans ]; then
    ls -1 .actual/plans/*.md 2>/dev/null | sed 's|^|  |' || echo "  (none)"
else
    echo "  (none)"
fi
echo
if [ -f .actual/pm/tracker-sync.json ]; then
    COUNT=$(jq '.mappings | length' .actual/pm/tracker-sync.json 2>/dev/null || echo 0)
    echo "Tracker-sync manifest: $COUNT issues mapped"
else
    echo "Tracker-sync manifest: (not yet run)"
fi
