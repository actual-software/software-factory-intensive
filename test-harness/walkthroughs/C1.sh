#!/usr/bin/env bash
# C1.sh — FormulaV2 walkthrough for the release-delivery factory.

set -uo pipefail

source "$WALK_REPO_ROOT/test-harness/walkthroughs/_common.sh"

lesson_prerequisites_check() {
  if ! command -v node >/dev/null 2>&1; then
    echo "C1: node not on PATH" >&2
    return 1
  fi
  local node_major
  node_major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
  if [ "${node_major:-0}" -lt 18 ]; then
    echo "C1: node $node_major too old (need 18+)" >&2
    return 1
  fi
  return 0
}

write_c1_factory_configs() {
  cat > "$WALK_C1_FACTORY/pack.toml" <<'TOML'
[pack]
name = "my-factory"
schema = 2

[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
TOML

  cat > "$WALK_C1_FACTORY/city.toml" <<TOML
[workspace]
name = "$WALK_C1_CITY_NAME"
provider = "claude"

[session]
startup_timeout = "3m"

[daemon]
formula_v2 = true
patrol_interval = "30s"
max_restarts = 5
restart_window = "1h"
shutdown_timeout = "5s"
TOML
}

lesson_run() {
  local lesson_rc=0

  echo
  echo "[1/10] pre-flight"
  assert_walkthrough_preflight
  purge_stranded_walkthrough_cities

  echo
  echo "[2/10] scratch setup"
  WALK_C1_SCRATCH="$WALK_SCRATCH/C1"
  WALK_C1_FACTORY="$WALK_C1_SCRATCH/my-factory"
  WALK_C1_CITY_NAME="sfi-walkthrough-C1-$run_id"
  mkdir -p "$WALK_C1_FACTORY"
  cp -R "$WALK_REPO_ROOT/packs" "$WALK_C1_SCRATCH/packs"
  write_c1_factory_configs
  step_pass "C1 factory config selects copied packs/lessons/C1"
  save_state WALK_C1_FACTORY WALK_C1_CITY_NAME

  echo
  echo "[3/10] gc register C1 factory"
  if ! register_walkthrough_city "$WALK_C1_FACTORY" "$WALK_C1_CITY_NAME" "C1"; then
    fail "C1 factory register failed"
  fi

  echo
  echo "[4/10] project rig + gc rig add"
  WALK_C1_RIG="$WALK_C1_SCRATCH/rig"
  cp -r "$WALK_REPO_ROOT/test-harness/tutorial-walkthrough-rig" "$WALK_C1_RIG"
  (
    cd "$WALK_C1_RIG" \
      && git init -q \
      && git config user.name "Factory Harness" \
      && git config user.email "factory@example.local" \
      && git add -A \
      && git commit -qm "initial" >/dev/null 2>&1
  )
  if (cd "$WALK_C1_FACTORY" && gc rig add "$WALK_C1_RIG" >/dev/null 2>&1); then
    step_pass "gc rig add succeeded"
  else
    step_fail "gc rig add failed"
    fail "rig add failed"
  fi
  local build_baseline_sha
  build_baseline_sha="$(cd "$WALK_C1_RIG" && git rev-parse HEAD)"
  save_state WALK_C1_RIG
  export WALK_FACTORY="$WALK_C1_FACTORY" WALK_RIG="$WALK_C1_RIG"

  echo
  echo "[5/10] sync existing rig factory import"
  local import_out
  import_out="$(cd "$WALK_C1_FACTORY" && gc --rig rig import remove factory 2>&1 || true)"
  log "gc --rig rig import remove factory:"
  echo "$import_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  import_out="$(cd "$WALK_C1_FACTORY" && gc --rig rig import add ../packs/lessons/C1 --name factory 2>&1)"
  log "gc --rig rig import add ../packs/lessons/C1 --name factory:"
  echo "$import_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  if echo "$import_out" | grep -q 'Added import "factory"'; then
    step_pass "existing rig imports packs/lessons/C1 as factory"
  else
    step_fail "gc --rig rig import add ../packs/lessons/C1 --name factory failed"
    fail "rig factory import sync failed"
  fi

  echo
  echo "[6/10] factory up"
  (cd "$WALK_C1_FACTORY" && gc doctor --fix >/dev/null 2>&1) || true
  if ! wait_for "supervisor responsive" \
    "cd '$WALK_C1_FACTORY' && gc status >/dev/null 2>&1" 120 3; then
    fail "supervisor unresponsive"
  fi
  step_pass "factory up"

  echo
  echo "[7/10] dry-run boundary"
  if [ "$WALK_DRY_RUN" = "1" ]; then
    step_pass "dry run validated C1 factory selection, rig sync, and formula entrypoint shape"
    return 0
  fi

  start_event_stream "$WALK_C1_FACTORY"

  echo
  echo "[8/10] gc sling C1 formula"
  local rig_tree_before sling_out
  rig_tree_before="$(cd "$WALK_C1_RIG" && find . -type f -not -path './.git/*' -not -path './.beads/*' | sort)"
  echo "$rig_tree_before" > "$WALK_C1_SCRATCH/rig-tree-before.txt"

  sling_out="$(cd "$WALK_C1_FACTORY" && gc sling planner \
    "Add a multiply operation: multiply(a, b) returns a*b" \
    --on mol-release-delivery 2>&1)"
  log "gc sling planner --on mol-release-delivery:"
  echo "$sling_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  if ! echo "$sling_out" | grep -q 'Attached workflow'; then
    step_fail "gc sling did not report a routed formula run"
    stop_event_stream
    fail "C1 formula sling failed"
  fi
  WALK_C1_WORKFLOW_BEAD_ID="$(echo "$sling_out" | awk '/Attached workflow/ {print $3; exit}')"
  if [ -n "$WALK_C1_WORKFLOW_BEAD_ID" ]; then
    export WALK_ROOT_BEAD_ID="$WALK_C1_WORKFLOW_BEAD_ID"
    save_state WALK_C1_WORKFLOW_BEAD_ID
  fi

  local plan_check='count=$(find "'"$WALK_C1_RIG"'/docs/plans" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Planner to write docs/plans/*.md" "$plan_check" 600 15 "" "rig/factory.planner" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Planner failed to produce plan artifact"; }
  WALK_C1_PLAN="$(find "$WALK_C1_RIG/docs/plans" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Planner produced plan: $WALK_C1_PLAN"

  local arch_check='count=$(find "'"$WALK_C1_RIG"'/docs/architecture" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Architect to write docs/architecture/*.md" "$arch_check" 600 15 "" "rig/factory.architect" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Architect failed to produce architecture artifact"; }
  WALK_C1_ARCHITECTURE="$(find "$WALK_C1_RIG/docs/architecture" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Architect produced architecture: $WALK_C1_ARCHITECTURE"

  local design_check='count=$(find "'"$WALK_C1_RIG"'/docs/designs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Designer to write docs/designs/*.md" "$design_check" 600 15 "" "rig/factory.designer" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Designer failed to produce design artifact"; }
  WALK_C1_DESIGN="$(find "$WALK_C1_RIG/docs/designs" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Designer produced design: $WALK_C1_DESIGN"

  local build_check='cd "'"$WALK_C1_RIG"'" && git log --all --not "'"$build_baseline_sha"'" --oneline 2>/dev/null | grep -q .'
  wait_for "Builder to commit at least one new change" "$build_check" 900 20 "" "rig/factory.builder" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Builder did not produce a new commit"; }
  WALK_C1_CODE_COMMITTED="$(cd "$WALK_C1_RIG" && git log --all --oneline | head -1)"
  step_pass "Builder committed: $WALK_C1_CODE_COMMITTED"

  local validation_check='count=$(find "'"$WALK_C1_RIG"'/docs/validation" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Validator to write docs/validation/*.md" "$validation_check" 600 15 "" "rig/factory.validator" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Validator failed to produce validation artifact"; }
  WALK_C1_VALIDATION="$(find "$WALK_C1_RIG/docs/validation" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Validator produced validation: $WALK_C1_VALIDATION"

  local review_check='count=$(find "'"$WALK_C1_RIG"'/docs/reviews" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Reviewer to write docs/reviews/*.md" "$review_check" 600 15 "" "rig/factory.reviewer" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Reviewer failed to produce review artifact"; }
  WALK_C1_REVIEW="$(find "$WALK_C1_RIG/docs/reviews" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Reviewer produced review: $WALK_C1_REVIEW"

  local release_check='count=$(find "'"$WALK_C1_RIG"'/docs/releases" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Release gate to write docs/releases/*.md" "$release_check" 600 15 "" "rig/factory.release-gate" "$WALK_C1_FACTORY" \
    || { stop_event_stream; fail "Release gate failed to produce release artifact"; }
  WALK_C1_RELEASE="$(find "$WALK_C1_RIG/docs/releases" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Release gate produced release record: $WALK_C1_RELEASE"

  echo
  echo "[9/10] verify artifacts and tests"
  local builder_branch test_out test_rc
  builder_branch="$(cd "$WALK_C1_RIG" && git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -1)"
  (cd "$WALK_C1_RIG" && git checkout -q "$builder_branch" 2>&1) | sed 's/^/    /' | tee -a "$WALK_LOG" || true
  test_out="$(cd "$WALK_C1_RIG" && node --test 2>&1)"; test_rc=$?
  log "node --test output (last 20 lines):"
  echo "$test_out" | tail -20 | sed 's/^/    /' | tee -a "$WALK_LOG"
  if [ "$test_rc" -eq 0 ]; then
    step_pass "node --test passes on $builder_branch"
  else
    stop_event_stream
    fail "node --test failed on $builder_branch"
  fi
  if grep -R "multiply" "$WALK_C1_RIG/src" "$WALK_C1_RIG/test" >/dev/null 2>&1; then
    step_pass "implementation references multiply in source or tests"
  else
    stop_event_stream
    fail "builder commit did not implement the requested multiply feature"
  fi

  assert_artifact_has_sections "$WALK_C1_PLAN" \
    '^## Goal' '^## User Stories' '^## Acceptance Criteria'
  assert_artifact_has_sections "$WALK_C1_ARCHITECTURE" \
    '^## Context' '^## Options Considered' '^## Decision'
  assert_artifact_has_sections "$WALK_C1_DESIGN" \
    '^## Interface' '^## Behavior' '^## Edge Cases' '^## Test Plan'
  assert_artifact_has_sections "$WALK_C1_VALIDATION" \
    '^## Verdict' '^## Test Command' '^## Results'
  assert_file_contains_at_least "$WALK_C1_VALIDATION" 1 \
    "validation report: explicit PASS/FAIL verdict" '\b(PASS|FAIL)\b'
  assert_artifact_has_sections "$WALK_C1_REVIEW" \
    '^## Verdict' '^## Findings' '^## Test Evidence'
  assert_file_contains_at_least "$WALK_C1_REVIEW" 1 \
    "review report: severity-labelled finding" '\b(critical|high|medium|low)\b'
  assert_artifact_has_sections "$WALK_C1_RELEASE" \
    '^## Verdict' '^## Required Checks' '^## Evidence'
  assert_file_contains_at_least "$WALK_C1_RELEASE" 1 \
    "release gate: explicit PASS/FAIL verdict" '\b(PASS|FAIL)\b'

  echo
  echo "[10/10] retrospective"
  log "creating retrospective from C1 run"
  local retro_dir="$WALK_C1_SCRATCH/activities-capstone-C1"
  mkdir -p "$retro_dir"
  cat > "$retro_dir/retrospective.md" <<RETRO
# Factory Run Retrospective

## Run Summary
- Feature: multiply operation
- Root bead: ${WALK_ROOT_BEAD_ID:-unknown}
- Formula: mol-release-delivery
- Stages completed: plan, architecture, design, build, validate, review, release

## What Worked
- All seven formula steps completed without manual intervention.
- Artifacts landed in the expected docs/ subdirectories.

## What Didn't Work
- (none observed in automated walkthrough)

## W4 Improvement Criteria Applied
| Rule | Signal Observed? | Metric Before | Metric After |
|------|-----------------|---------------|--------------|
| (walkthrough does not have prior W4 rules to evaluate) | N/A | N/A | N/A |

## Config Changes Made During This Run
| File | Change | Why |
|------|--------|-----|
| (none — walkthrough used stock prompts) | — | — |

## What I Would Change Before the Next Run
- Add project-specific Review Standards to PROJECT_MANIFEST.md.
RETRO
  if [ -f "$retro_dir/retrospective.md" ]; then
    step_pass "retrospective created: $retro_dir/retrospective.md"
  else
    step_fail "retrospective was not created"
  fi
  WALK_C1_RETROSPECTIVE="$retro_dir/retrospective.md"
  save_state WALK_C1_RETROSPECTIVE

  log "what C1 produced (rig tree diff since lesson start):"
  (cd "$WALK_C1_RIG" && find . -type f -not -path './.git/*' -not -path './.beads/*' | sort \
    | diff "$WALK_C1_SCRATCH/rig-tree-before.txt" - | grep '^>' | sed 's/^> /      + /') | tee -a "$WALK_LOG"

  # Save ALL artifacts — every file the agents produced
  save_snapshot "C1" "gc-sling.txt" "$sling_out"
  save_all_artifacts "C1" "plans" "$WALK_C1_RIG/docs/plans"
  save_all_artifacts "C1" "architecture" "$WALK_C1_RIG/docs/architecture"
  save_all_artifacts "C1" "designs" "$WALK_C1_RIG/docs/designs"
  save_all_artifacts "C1" "validation" "$WALK_C1_RIG/docs/validation"
  save_all_artifacts "C1" "reviews" "$WALK_C1_RIG/docs/reviews"
  save_all_artifacts "C1" "releases" "$WALK_C1_RIG/docs/releases"
  save_snapshot "C1" "node-test.txt" "$test_out"
  save_snapshot "C1" "builder-commit.txt" "$WALK_C1_CODE_COMMITTED"
  save_snapshot_file "C1" "retrospective.md" "$WALK_C1_RETROSPECTIVE"
  save_agent_sessions "C1" "$WALK_C1_FACTORY"

  save_state WALK_C1_PLAN WALK_C1_ARCHITECTURE WALK_C1_DESIGN WALK_C1_CODE_COMMITTED WALK_C1_VALIDATION WALK_C1_REVIEW WALK_C1_RELEASE
  stop_event_stream
  return "$lesson_rc"
}

lesson_rc=0

lesson_prerequisites_check || exit 77
lesson_run
exit "$lesson_rc"
