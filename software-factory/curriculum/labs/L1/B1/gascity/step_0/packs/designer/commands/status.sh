#!/usr/bin/env bash
set -euo pipefail
echo "── actual-designer ─────────────────────────────────────────────"
echo "Open design work (label=needs-design):"
bd ready --label=needs-design 2>/dev/null || echo "  (none)"
echo
echo "Design artifacts:"
if [ -d .actual/designs ]; then
    ls -1 .actual/designs/*.md 2>/dev/null | sed 's|^|  |' || echo "  (none)"
else
    echo "  (none)"
fi
