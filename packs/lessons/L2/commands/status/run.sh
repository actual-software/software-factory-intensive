#!/usr/bin/env bash
set -euo pipefail

echo "Feature-intake factory"
echo
echo "Formula: mol-feature-intake"
echo "Agents:  factory.planner, factory.architect"
echo
echo "Artifacts:"
echo "  Plans:"
find docs/plans -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | sed 's/^/    /' || true
echo "  Architecture:"
find docs/architecture -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | sed 's/^/    /' || true
echo
echo "Recent work:"
bd list --limit 5 2>/dev/null || echo "  (no beads yet)"
echo
echo "Active sessions:"
gc session list 2>/dev/null | head -10 || echo "  (none)"
