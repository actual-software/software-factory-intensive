#!/usr/bin/env bash
# Print the work-breakdown graph for a plan slug (or all plans).
set -euo pipefail
slug="${1:-}"
if [ -z "$slug" ]; then
    if [ ! -d .actual/plans ]; then
        echo "no plans yet"
        exit 0
    fi
    ls -1 .actual/plans/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//'
    exit 0
fi
if [ -f ".actual/plans/$slug.md" ]; then
    cat ".actual/plans/$slug.md"
else
    echo "no plan at .actual/plans/$slug.md" >&2
    exit 1
fi
