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

# Optional but helpful: at least one language toolchain in PATH.
if ! command -v go >/dev/null 2>&1 && \
   ! command -v node >/dev/null 2>&1 && \
   ! command -v cargo >/dev/null 2>&1 && \
   ! command -v python3 >/dev/null 2>&1; then
    echo "warning: no language toolchain (go/node/cargo/python3) in PATH" >&2
fi

# actual CLI is optional — the actual-adr-check step skips gracefully.
if ! command -v actual >/dev/null 2>&1; then
    echo "note: actual CLI not installed — adr-check step will be skipped" >&2
fi

echo "ok"
