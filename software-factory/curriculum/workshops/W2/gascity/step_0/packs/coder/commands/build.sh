#!/usr/bin/env bash
# Manually dispatch mol-code-from-spec against a specific bead.
# Useful for re-running coder work after fixing a self-test failure.
set -euo pipefail

bead_id="${1:-}"
if [ -z "$bead_id" ]; then
    echo "usage: $0 <bead-id>" >&2
    exit 1
fi
shift

exec gc sling "$(basename "$(pwd)")/coder" \
    --bead "$bead_id" \
    --on mol-code-from-spec "$@"
