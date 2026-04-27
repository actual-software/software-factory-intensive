#!/usr/bin/env bash
# tutorial-check.sh — dry-run the student walkthrough command flow.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

lessons=( "$@" )
if [ "${#lessons[@]}" -eq 0 ]; then
  lessons=(L2 L3 L4 C1)
fi

TUTORIAL_WALKTHROUGH_DRY_RUN=1 bash test-harness/tutorial-walkthrough.sh "${lessons[@]}"
