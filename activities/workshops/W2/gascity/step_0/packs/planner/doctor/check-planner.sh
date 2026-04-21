#!/usr/bin/env bash
# Doctor check for the actual-planner pack.
# Verifies binaries the planner needs at runtime.
set -euo pipefail

missing=()
for bin in bd gc git jq; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        missing+=("$bin")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "missing required binaries: ${missing[*]}" >&2
    exit 1
fi

echo "ok"
