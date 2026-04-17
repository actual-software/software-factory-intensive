#!/usr/bin/env bash
# Manually trigger the feedback-harvest formula outside the cooldown.
set -euo pipefail
since="${1:-24h}"
exec gc sling "$(basename "$(pwd)")/improver" \
    --on mol-feedback-harvest \
    --var since="$since"
