#!/usr/bin/env bash
set -euo pipefail
echo "── actual-validator ────────────────────────────────────────────"
echo "Open validation work (label=needs-tests):"
bd ready --label=needs-tests 2>/dev/null || echo "  (none)"
echo
echo "Recently handed off to builder:"
bd list --label=source:actual-validator --label=ready-to-build --limit=5 2>/dev/null || echo "  (none)"
