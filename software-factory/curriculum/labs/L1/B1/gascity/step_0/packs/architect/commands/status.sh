#!/usr/bin/env bash
# actual-architect status — show architect work queue for the current rig.
set -euo pipefail

echo "── actual-architect ────────────────────────────────────────────"
echo "Open architecture work (label=needs-architecture):"
bd ready --label=needs-architecture 2>/dev/null || echo "  (none)"
echo
echo "Recently-closed architecture beads:"
bd list --label=source:actual-architect --status=closed --limit=5 2>/dev/null || echo "  (none)"
