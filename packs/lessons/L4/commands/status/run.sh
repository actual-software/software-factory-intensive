#!/usr/bin/env bash
set -euo pipefail

echo "Delivery-review factory"
echo
echo "Formula: mol-delivery-review"
echo "Agents:  factory.planner, factory.architect, factory.designer, factory.builder, factory.reviewer, factory.release-gate"
echo
echo "Artifacts:"
for dir in docs/plans docs/architecture docs/designs docs/reviews docs/releases; do
  echo "  $(basename "$dir"):"
  find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | sed 's/^/    /' || true
done
echo
echo "Recent work:"
bd list --limit 5 2>/dev/null || echo "  (no beads yet)"
echo
echo "Active sessions:"
gc session list 2>/dev/null | head -10 || echo "  (none)"
