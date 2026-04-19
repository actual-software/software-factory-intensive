#!/usr/bin/env bash
set -euo pipefail
echo "── actual-coder ────────────────────────────────────────────────"
echo "Open code work (label=ready-to-build):"
bd ready --label=ready-to-build 2>/dev/null || echo "  (none)"
echo
echo "Recently handed-off to reviewer:"
bd list --label=source:actual-coder --label=needs-review --limit=5 2>/dev/null || echo "  (none)"
