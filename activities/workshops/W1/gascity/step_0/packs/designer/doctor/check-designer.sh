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

# actual CLI is optional — the designer formula skips adr-sync when
# it's absent. Warn but do not fail.
if ! command -v actual >/dev/null 2>&1; then
    echo "note: actual CLI not installed — adr-sync step will be skipped" >&2
fi

# Excalidraw binaries are required for visual wireframing.
# See docs/excalidraw-prerequisites.md for install instructions.
excalidraw_missing=()
command -v excalidraw-mcp >/dev/null 2>&1 || excalidraw_missing+=("excalidraw-mcp")
command -v excalidraw-export >/dev/null 2>&1 || excalidraw_missing+=("excalidraw-export-cli")
if [ ${#excalidraw_missing[@]} -gt 0 ]; then
    echo "missing Excalidraw binaries: ${excalidraw_missing[*]}" >&2
    echo "Install with: npm install -g ${excalidraw_missing[*]}" >&2
    echo "See docs/excalidraw-prerequisites.md for details." >&2
    exit 1
fi

echo "ok"
