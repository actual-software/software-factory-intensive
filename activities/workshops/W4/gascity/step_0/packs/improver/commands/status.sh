#!/usr/bin/env bash
set -euo pipefail
echo "── actual-improver ─────────────────────────────────────────────"
echo "Open improve work (label=needs-improve):"
bd ready --label=needs-improve 2>/dev/null || echo "  (none)"
echo
echo "Recent feedback summaries:"
if [ -d .actual/feedback ]; then
    ls -1 .actual/feedback/*.md 2>/dev/null | tail -5 | sed 's|^|  |'
else
    echo "  (none)"
fi
echo
echo "Beads filed by improver in the last 10:"
bd list --label=source:actual-improver --limit=10 2>/dev/null || echo "  (none)"
