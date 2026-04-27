#!/usr/bin/env bash
# behavioral-smoke.sh — non-LLM smoke checks for the lesson-pack architecture.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

echo "== behavioral-smoke =="
echo "repo: $repo_root"
echo

echo "[1] static content architecture lint"
test-harness/lesson-pack-lint.py --lesson L2 --lesson L3 --lesson L4 --lesson C1

echo
echo "[2] PackV2 structure checks"
bash test-harness/migration-check.sh

echo
echo "[3] student command flow dry-run"
TUTORIAL_WALKTHROUGH_DRY_RUN=1 bash test-harness/tutorial-walkthrough.sh L1 L2 L3 L4 C1

echo
echo "[4] walkthrough cleanup ownership"
bash test-harness/walkthrough-cleanup-test.sh

echo
echo "✓ behavioral smoke passes"
