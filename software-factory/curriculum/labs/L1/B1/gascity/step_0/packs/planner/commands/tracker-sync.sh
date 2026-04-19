#!/usr/bin/env bash
# Manual trigger for the tracker → beads import, bypassing the formula.
# Useful for bootstrapping an existing tracker workflow into the factory.
set -euo pipefail

script_candidates=(
    "$HOME/.claude/skills/tracker-to-beads/scripts/import.sh"
    ".claude/skills/tracker-to-beads/scripts/import.sh"
)

for s in "${script_candidates[@]}"; do
    if [ -x "$s" ]; then
        exec "$s" "$@"
    fi
done

echo "tracker-to-beads skill not found in:" >&2
printf '  %s\n' "${script_candidates[@]}" >&2
echo "install it by running the planner agent at least once, or symlink" >&2
echo "the planner's overlay skills dir into your Claude Code skills dir." >&2
exit 1
