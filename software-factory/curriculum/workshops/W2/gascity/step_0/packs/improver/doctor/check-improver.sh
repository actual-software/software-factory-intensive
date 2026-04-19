#!/usr/bin/env bash
set -euo pipefail
missing=()
for bin in bd gc jq; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing required binaries: ${missing[*]}" >&2
    exit 1
fi
echo "ok"
