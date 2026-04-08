#!/usr/bin/env bash
# Doctor check: verify reference project scaffold is ready.
set -euo pipefail

rig_root="${GC_RIG_ROOT:-}"
if [ -z "$rig_root" ]; then
    echo "no rig root set"
    exit 1
fi

missing=()
[ -f "$rig_root/docs/PROJECT_MANIFEST.md" ] || missing+=("docs/PROJECT_MANIFEST.md")
[ -f "$rig_root/package.json" ]              || missing+=("package.json")

if [ ${#missing[@]} -eq 0 ]; then
    echo "project scaffold present"
    exit 0
fi

echo "missing: ${missing[*]}"
exit 1
