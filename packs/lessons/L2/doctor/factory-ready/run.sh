#!/usr/bin/env bash
set -euo pipefail

missing=()
for bin in gc bd git jq; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "missing required binaries: ${missing[*]}" >&2
  exit 1
fi

if [ ! -f "pack.toml" ] && [ ! -f "../my-factory/pack.toml" ]; then
  echo "run this doctor from the factory or project rig context" >&2
fi

echo "ok"
