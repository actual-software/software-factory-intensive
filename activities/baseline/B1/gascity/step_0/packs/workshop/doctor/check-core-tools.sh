#!/usr/bin/env bash
# Doctor check: verify core CLI tools are available.
# Exit 0 = OK, 1 = warning, 2 = error.
set -euo pipefail

missing=()
for cmd in gc bd dolt tmux jq git curl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "all core tools present"
    exit 0
fi

echo "missing: ${missing[*]}"
echo "Install with: brew install gastownhall/gascity/gascity"
exit 2
