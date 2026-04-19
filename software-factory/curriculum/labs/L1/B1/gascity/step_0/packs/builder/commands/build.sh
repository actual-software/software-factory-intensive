#!/usr/bin/env bash
# Manually dispatch mol-build-from-spec against a specific bead.
# Useful for re-running a build after fixing a self-test failure.
set -euo pipefail

bead_id="${1:-}"
if [ -z "$bead_id" ]; then
    echo "usage: $0 <bead-id>" >&2
    exit 1
fi
shift

exec gc sling "$(basename "$(pwd)")/builder" \
    --bead "$bead_id" \
    --on mol-build-from-spec "$@"
