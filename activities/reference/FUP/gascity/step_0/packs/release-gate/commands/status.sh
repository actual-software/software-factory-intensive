#!/usr/bin/env bash
set -euo pipefail
echo "── actual-release-gate ─────────────────────────────────────────"
echo "Open release work (label=ready-to-ship):"
bd ready --label=ready-to-ship 2>/dev/null || echo "  (none)"
echo
echo "Recent releases:"
if [ -d .actual/releases ]; then
    ls -1 .actual/releases/*.md 2>/dev/null | tail -5 | sed 's|^|  |'
else
    echo "  (none)"
fi
