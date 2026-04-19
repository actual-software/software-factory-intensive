#!/usr/bin/env bash
# actual-architect rules — list architectural rule files in the current rig.
set -euo pipefail

if [ ! -d .actual/rules ]; then
    echo "no rules yet — .actual/rules/ does not exist"
    exit 0
fi

echo "── .actual/rules ──────────────────────────────────────────────"
for f in .actual/rules/*.md; do
    [ -e "$f" ] || continue
    title=$(head -n1 "$f" | sed 's/^# *//')
    status=$(grep -m1 '^\*\*Status:\*\*' "$f" 2>/dev/null | sed 's/\*\*Status:\*\* *//' || echo "unknown")
    printf "%-40s %s\n" "$title" "$status"
done
