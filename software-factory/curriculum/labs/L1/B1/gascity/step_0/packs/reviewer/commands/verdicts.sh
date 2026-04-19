#!/usr/bin/env bash
# Print recent review verdicts extracted from bead notes.
set -euo pipefail
bd list --label=source:actual-reviewer --json 2>/dev/null \
    | jq -r '.[] | "\(.id)\t\(.title)"' \
    || echo "(none)"
