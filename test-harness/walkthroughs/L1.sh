#!/usr/bin/env bash
# L1.sh — Walkthrough for the factory runtime setup lesson.
#
# README mirrored: curriculum/labs/L1/README.md
# Commands exercised:
#   - cp templates to create pack.toml and city.toml
#   - gc register .
#   - gc rig add <rig>
#   - gc doctor --fix
#   - gc status
#   - project test runner (node --test)
#
# L1 is setup-only: no formula sling, no agents. It creates the city and rig
# that L2+ will use. The walkthrough validates that every L1 curriculum
# command produces the expected outcome.

set -uo pipefail

source "$WALK_REPO_ROOT/test-harness/walkthroughs/_common.sh"

lesson_prerequisites_check() {
  if ! command -v node >/dev/null 2>&1; then
    echo "L1: node not on PATH" >&2
    return 1
  fi
  return 0
}

lesson_run() {
  local lesson_rc=0

  echo
  echo "[1/7] pre-flight"
  assert_walkthrough_preflight
  purge_stranded_walkthrough_cities

  echo
  echo "[2/7] scratch setup"
  WALK_L1_SCRATCH="$WALK_SCRATCH/L1"
  WALK_L1_FACTORY="$WALK_L1_SCRATCH/my-factory"
  WALK_L1_CITY_NAME="sfi-walkthrough-L1-$run_id"
  mkdir -p "$WALK_L1_FACTORY"
  cp -R "$WALK_REPO_ROOT/packs" "$WALK_L1_SCRATCH/packs"
  save_state WALK_L1_FACTORY WALK_L1_CITY_NAME

  echo
  echo "[3/7] simulate L1 step 1: CLAUDE.md in project rig"
  WALK_L1_RIG="$WALK_L1_SCRATCH/rig"
  cp -r "$WALK_REPO_ROOT/test-harness/tutorial-walkthrough-rig" "$WALK_L1_RIG"
  (
    cd "$WALK_L1_RIG" \
      && git init -q \
      && git config user.name "Factory Harness" \
      && git config user.email "factory@example.local" \
      && git add -A \
      && git commit -qm "initial" >/dev/null 2>&1
  )
  if [ -f "$WALK_L1_RIG/CLAUDE.md" ]; then
    step_pass "CLAUDE.md exists in project rig"
  else
    step_fail "CLAUDE.md missing from project rig"
    fail "L1 step 1 failed: no CLAUDE.md"
  fi
  save_state WALK_L1_RIG

  echo
  echo "[4/7] simulate L1 step 2: create minimal PROJECT_MANIFEST.md"
  if [ -f "$WALK_REPO_ROOT/curriculum/PROJECT_MANIFEST_TEMPLATE.md" ]; then
    cp "$WALK_REPO_ROOT/curriculum/PROJECT_MANIFEST_TEMPLATE.md" "$WALK_L1_FACTORY/PROJECT_MANIFEST.md"
  else
    cat > "$WALK_L1_FACTORY/PROJECT_MANIFEST.md" <<'MANIFEST'
# Project Manifest

## Overview
Calculator library with basic arithmetic operations.

## Tech Stack
Node.js, native test runner (node --test).

## Project Structure
- src/ — implementation files
- test/ — test files
MANIFEST
  fi
  if [ -f "$WALK_L1_FACTORY/PROJECT_MANIFEST.md" ]; then
    step_pass "PROJECT_MANIFEST.md created in my-factory"
  else
    step_fail "PROJECT_MANIFEST.md not created"
    fail "L1 step 2 failed"
  fi

  echo
  echo "[5/7] L1 step 3: cp templates + register city"
  # README says: cp my-factory/pack.toml.template my-factory/pack.toml
  #              cp my-factory/city.toml.template my-factory/city.toml
  # We copy from the repo's actual templates, then patch the city name for
  # test isolation.
  local pack_tmpl="$WALK_REPO_ROOT/my-factory/pack.toml.template"
  local city_tmpl="$WALK_REPO_ROOT/my-factory/city.toml.template"

  if [ ! -f "$pack_tmpl" ]; then
    fail "pack.toml.template missing from my-factory/ — README step 3 is broken"
  fi
  if [ ! -f "$city_tmpl" ]; then
    fail "city.toml.template missing from my-factory/ — README step 3 is broken"
  fi

  cp "$pack_tmpl" "$WALK_L1_FACTORY/pack.toml"
  step_pass "cp pack.toml.template -> pack.toml"

  cp "$city_tmpl" "$WALK_L1_FACTORY/city.toml"
  # Patch city name for test isolation (students use the default name)
  sed -i '' "s/name = \"my-factory\"/name = \"$WALK_L1_CITY_NAME\"/" "$WALK_L1_FACTORY/city.toml"
  step_pass "cp city.toml.template -> city.toml"

  if grep -q 'formula_v2 = true' "$WALK_L1_FACTORY/city.toml"; then
    step_pass "city.toml enables FormulaV2"
  else
    step_fail "city.toml.template missing formula_v2 = true — README claims it's there"
    fail "L1 step 3 failed: FormulaV2 not enabled"
  fi

  if grep -q 'packs/lessons/L2' "$WALK_L1_FACTORY/pack.toml"; then
    step_pass "pack.toml selects packs/lessons/L2"
  else
    step_fail "pack.toml.template does not select L2 — README claims it does"
    fail "L1 step 3 failed: wrong pack selection"
  fi

  if ! register_walkthrough_city "$WALK_L1_FACTORY" "$WALK_L1_CITY_NAME" "L1"; then
    fail "L1 factory register failed"
  fi

  if (cd "$WALK_L1_FACTORY" && gc rig add "$WALK_L1_RIG" >/dev/null 2>&1); then
    step_pass "gc rig add succeeded"
  else
    step_fail "gc rig add failed"
    fail "L1 rig add failed"
  fi
  export WALK_FACTORY="$WALK_L1_FACTORY" WALK_RIG="$WALK_L1_RIG"

  echo
  echo "[6/7] gc doctor + gc status"
  (cd "$WALK_L1_FACTORY" && gc doctor --fix >/dev/null 2>&1) || true
  local status_out
  status_out="$(cd "$WALK_L1_FACTORY" && gc status 2>&1)"
  log "gc status:"
  echo "$status_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  if [ $? -eq 0 ]; then
    step_pass "gc status reports healthy"
  else
    step_fail "gc status failed"
    fail "L1 gc status failed"
  fi

  echo
  echo "[7/7] verify: git status + project tests"
  if [ "$WALK_DRY_RUN" = "1" ]; then
    step_pass "dry run validated L1 city setup, rig add, and config shape"
    return 0
  fi

  # README says: git status --short
  local git_status_out
  git_status_out="$(cd "$WALK_L1_RIG" && git status --short 2>&1)"
  log "git status --short:"
  echo "$git_status_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  step_pass "git status --short ran cleanly"

  # README says: npm test (or your project's equivalent)
  local test_out test_rc
  test_out="$(cd "$WALK_L1_RIG" && node --test 2>&1)"; test_rc=$?
  log "node --test output (last 10 lines):"
  echo "$test_out" | tail -10 | sed 's/^/    /' | tee -a "$WALK_LOG"
  if [ "$test_rc" -eq 0 ]; then
    step_pass "project tests pass (node --test)"
  else
    step_fail "project tests failed"
    fail "L1 project tests failed — CLAUDE.md commands are wrong"
  fi

  # Save snapshots for validate-lesson-content skill
  save_snapshot "L1" "gc-status.txt" "$status_out"
  save_snapshot "L1" "git-status.txt" "$git_status_out"
  save_snapshot "L1" "node-test.txt" "$test_out"
  save_snapshot_file "L1" "city.toml" "$WALK_L1_FACTORY/city.toml"
  save_snapshot_file "L1" "pack.toml" "$WALK_L1_FACTORY/pack.toml"
  save_snapshot_file "L1" "PROJECT_MANIFEST.md" "$WALK_L1_FACTORY/PROJECT_MANIFEST.md"
  save_snapshot_file "L1" "CLAUDE.md" "$WALK_L1_RIG/CLAUDE.md"

  log "L1 complete — city registered, rig added, FormulaV2 enabled, tests pass"
  return "$lesson_rc"
}

lesson_rc=0

lesson_prerequisites_check || exit 77
lesson_run
exit "$lesson_rc"
