#!/usr/bin/env bash
# Show the wireframe + a11y section of a design file (or list all).
set -euo pipefail
slug="${1:-}"
if [ -z "$slug" ]; then
    ls -1 .actual/designs/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' || echo "(none)"
    exit 0
fi
cat ".actual/designs/$slug.md"
