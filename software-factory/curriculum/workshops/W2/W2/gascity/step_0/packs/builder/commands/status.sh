#!/usr/bin/env bash
set -euo pipefail
echo "── actual-builder ──────────────────────────────────────────────"
echo "Open build work (label=ready-to-build):"
bd ready --label=ready-to-build 2>/dev/null || echo "  (none)"
echo
echo "Recently handed-off to reviewer:"
bd list --label=source:actual-builder --label=needs-review --limit=5 2>/dev/null || echo "  (none)"
