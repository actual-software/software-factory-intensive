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

# actual CLI is optional — the improver formula skips adr-sync when
# it's absent. Warn but do not fail.
if ! command -v actual >/dev/null 2>&1; then
    echo "note: actual CLI not installed — adr-sync step will be skipped" >&2
fi

echo "ok"
