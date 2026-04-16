#!/usr/bin/env bash
# probe.sh — list sibling tracker skills in the Claude Code skills dirs.
#
# Prints one skill name per line (its directory basename). Always
# exits 0. If no trackers are found, prints `none` and exits 0.
set -euo pipefail

# Search paths, in order. The first two match Claude Code's standard
# skill discovery; the third is for running the skill directly from
# a Gas City overlay.
search_dirs=(
    "$HOME/.claude/skills"
    ".claude/skills"
)

# Names that match the tracker contract.
is_tracker() {
    case "$1" in
        jira|linear|github-issues) return 0 ;;
        tracker-*) return 0 ;;
        *) return 1 ;;
    esac
}

found=0
for base in "${search_dirs[@]}"; do
    [ -d "$base" ] || continue
    for dir in "$base"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        # Skip our own skill.
        [ "$name" = "tracker-to-beads" ] && continue
        if is_tracker "$name"; then
            echo "$name $base/$name"
            found=1
        fi
    done
done

if [ "$found" -eq 0 ]; then
    echo "none"
fi
exit 0
