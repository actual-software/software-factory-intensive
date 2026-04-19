#!/usr/bin/env bash
set -euo pipefail
missing=()
for bin in bd gc git jq; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing required binaries: ${missing[*]}" >&2
    exit 1
fi
if ! command -v gh >/dev/null 2>&1; then
    echo "note: gh not installed — GitHub CI check will be skipped" >&2
fi
echo "ok"
