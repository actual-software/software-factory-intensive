#!/usr/bin/env bash
# List test files that came from actual-validator handoffs.
# Reads notes of beads labelled source:actual-validator and prints the
# test_files entries.
set -euo pipefail
bd list --label=source:actual-validator --json 2>/dev/null \
    | jq -r '.[] | "\(.id)\t\(.title)"' \
    || echo "(none)"
