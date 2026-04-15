#!/usr/bin/env bash
# Print the rollback plan recorded in a bead's notes.
set -euo pipefail
bead="${1:-}"
if [ -z "$bead" ]; then
    echo "usage: $0 <bead-id>" >&2
    exit 1
fi
bd show "$bead" --json 2>/dev/null \
    | jq -r '.notes' \
    | awk '/^rollback_plan:/,/^[a-z_]+:/' \
    | head -20
