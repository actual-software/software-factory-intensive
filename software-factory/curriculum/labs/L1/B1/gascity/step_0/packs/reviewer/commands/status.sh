#!/usr/bin/env bash
set -euo pipefail
echo "── actual-reviewer ─────────────────────────────────────────────"
echo "Open review work (label=needs-review):"
bd ready --label=needs-review 2>/dev/null || echo "  (none)"
echo
echo "Recently shipped to release-gate:"
bd list --label=source:actual-reviewer --label=ready-to-ship --limit=5 2>/dev/null || echo "  (none)"
