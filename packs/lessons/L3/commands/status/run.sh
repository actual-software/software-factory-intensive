#!/usr/bin/env bash
set -euo pipefail

echo "Feature-delivery factory"
echo
echo "Formula: mol-feature-delivery"
echo "Agents:  factory.planner, factory.architect, factory.designer, factory.builder"
echo
echo "Artifacts:"
for dir in docs/plans docs/architecture docs/designs; do
  echo "  $(basename "$dir"):"
  find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | sed 's/^/    /' || true
done
echo
echo "Recent work:"
bd list --limit 5 2>/dev/null || echo "  (no beads yet)"
echo
echo "Active sessions:"
gc session list 2>/dev/null | head -10 || echo "  (none)"
