#!/usr/bin/env bash
# L3.sh — FormulaV2 walkthrough for the feature-delivery factory.

set -uo pipefail

source "$WALK_REPO_ROOT/test-harness/walkthroughs/_common.sh"

lesson_prerequisites_check() {
  if ! command -v node >/dev/null 2>&1; then
    echo "L3: node not on PATH" >&2
    return 1
  fi
  local node_major
  node_major="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
  if [ "${node_major:-0}" -lt 18 ]; then
    echo "L3: node $node_major too old (need 18+)" >&2
    return 1
  fi
  return 0
}

write_l3_factory_configs() {
  cat > "$WALK_L3_FACTORY/pack.toml" <<'TOML'
[pack]
name = "my-factory"
schema = 2

[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
TOML

  cat > "$WALK_L3_FACTORY/city.toml" <<TOML
[workspace]
name = "$WALK_L3_CITY_NAME"
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
  WALK_L3_SCRATCH="$WALK_SCRATCH/L3"
  WALK_L3_FACTORY="$WALK_L3_SCRATCH/my-factory"
  WALK_L3_CITY_NAME="sfi-walkthrough-L3-$run_id"
  mkdir -p "$WALK_L3_FACTORY"
  cp -R "$WALK_REPO_ROOT/packs" "$WALK_L3_SCRATCH/packs"
  write_l3_factory_configs
  step_pass "L3 factory config selects copied packs/lessons/L3"
  save_state WALK_L3_FACTORY WALK_L3_CITY_NAME

  echo
  echo "[3/10] gc register L3 factory"
  if ! register_walkthrough_city "$WALK_L3_FACTORY" "$WALK_L3_CITY_NAME" "L3"; then
    fail "L3 factory register failed"
  fi

  echo
  echo "[4/10] project rig + gc rig add"
  WALK_L3_RIG="$WALK_L3_SCRATCH/rig"
  cp -r "$WALK_REPO_ROOT/test-harness/tutorial-walkthrough-rig" "$WALK_L3_RIG"
  (
    cd "$WALK_L3_RIG" \
      && git init -q \
      && git config user.name "Factory Harness" \
      && git config user.email "factory@example.local" \
      && git add -A \
      && git commit -qm "initial" >/dev/null 2>&1
  )
  if (cd "$WALK_L3_FACTORY" && gc rig add "$WALK_L3_RIG" >/dev/null 2>&1); then
    step_pass "gc rig add succeeded"
  else
    step_fail "gc rig add failed"
    fail "rig add failed"
  fi
  local build_baseline_sha
  build_baseline_sha="$(cd "$WALK_L3_RIG" && git rev-parse HEAD)"
  save_state WALK_L3_RIG
  export WALK_FACTORY="$WALK_L3_FACTORY" WALK_RIG="$WALK_L3_RIG"

  echo
  echo "[5/10] sync existing rig factory import"
  local import_out
  import_out="$(cd "$WALK_L3_FACTORY" && gc --rig rig import remove factory 2>&1 || true)"
  log "gc --rig rig import remove factory:"
  echo "$import_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  import_out="$(cd "$WALK_L3_FACTORY" && gc --rig rig import add ../packs/lessons/L3 --name factory 2>&1)"
  log "gc --rig rig import add ../packs/lessons/L3 --name factory:"
  echo "$import_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  if echo "$import_out" | grep -q 'Added import "factory"'; then
    step_pass "existing rig imports packs/lessons/L3 as factory"
  else
    step_fail "gc --rig rig import add ../packs/lessons/L3 --name factory failed"
    fail "rig factory import sync failed"
  fi

  echo
  echo "[6/10] factory up"
  (cd "$WALK_L3_FACTORY" && gc doctor --fix >/dev/null 2>&1) || true
  if ! wait_for "supervisor responsive" \
    "cd '$WALK_L3_FACTORY' && gc status >/dev/null 2>&1" 120 3; then
    fail "supervisor unresponsive"
  fi
  step_pass "factory up"

  echo
  echo "[7/10] dry-run boundary"
  if [ "$WALK_DRY_RUN" = "1" ]; then
    step_pass "dry run validated L3 factory selection, rig sync, and formula entrypoint shape"
    return 0
  fi

  start_event_stream "$WALK_L3_FACTORY"

  echo
  echo "[8/10] gc sling L3 formula"
  local rig_tree_before sling_out
  rig_tree_before="$(cd "$WALK_L3_RIG" && find . -type f -not -path './.git/*' -not -path './.beads/*' | sort)"
  echo "$rig_tree_before" > "$WALK_L3_SCRATCH/rig-tree-before.txt"

  sling_out="$(cd "$WALK_L3_FACTORY" && gc sling planner \
    "Add a percent operation: percent(whole, fraction) returns whole*fraction/100" \
    --on mol-feature-delivery 2>&1)"
  log "gc sling planner --on mol-feature-delivery:"
  echo "$sling_out" | sed 's/^/    /' | tee -a "$WALK_LOG"
  if ! echo "$sling_out" | grep -q 'Attached workflow'; then
    step_fail "gc sling did not report a routed formula run"
    stop_event_stream
    fail "L3 formula sling failed"
  fi
  WALK_L3_WORKFLOW_BEAD_ID="$(echo "$sling_out" | awk '/Attached workflow/ {print $3; exit}')"
  if [ -n "$WALK_L3_WORKFLOW_BEAD_ID" ]; then
    export WALK_ROOT_BEAD_ID="$WALK_L3_WORKFLOW_BEAD_ID"
    save_state WALK_L3_WORKFLOW_BEAD_ID
  fi

  local plan_check='count=$(find "'"$WALK_L3_RIG"'/docs/plans" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Planner to write docs/plans/*.md" "$plan_check" 600 15 "" "rig/factory.planner" "$WALK_L3_FACTORY" \
    || { stop_event_stream; fail "Planner failed to produce plan artifact"; }
  WALK_L3_PLAN="$(find "$WALK_L3_RIG/docs/plans" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Planner produced plan: $WALK_L3_PLAN"

  local arch_check='count=$(find "'"$WALK_L3_RIG"'/docs/architecture" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Architect to write docs/architecture/*.md" "$arch_check" 600 15 "" "rig/factory.architect" "$WALK_L3_FACTORY" \
    || { stop_event_stream; fail "Architect failed to produce architecture artifact"; }
  WALK_L3_ARCHITECTURE="$(find "$WALK_L3_RIG/docs/architecture" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Architect produced architecture: $WALK_L3_ARCHITECTURE"

  local design_check='count=$(find "'"$WALK_L3_RIG"'/docs/designs" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d " "); [ "$count" -ge 1 ]'
  wait_for "Designer to write docs/designs/*.md" "$design_check" 600 15 "" "rig/factory.designer" "$WALK_L3_FACTORY" \
    || { stop_event_stream; fail "Designer failed to produce design artifact"; }
  WALK_L3_DESIGN="$(find "$WALK_L3_RIG/docs/designs" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)"
  step_pass "Designer produced design: $WALK_L3_DESIGN"

  local build_check='cd "'"$WALK_L3_RIG"'" && git log --all --not "'"$build_baseline_sha"'" --oneline 2>/dev/null | grep -q .'
  wait_for "Builder to commit at least one new change" "$build_check" 900 20 "" "rig/factory.builder" "$WALK_L3_FACTORY" \
    || { stop_event_stream; fail "Builder did not produce a new commit"; }
  WALK_L3_CODE_COMMITTED="$(cd "$WALK_L3_RIG" && git log --all --oneline | head -1)"
  step_pass "Builder committed: $WALK_L3_CODE_COMMITTED"

  echo
  echo "[9/10] verify artifacts and tests"
  local builder_branch test_out test_rc
  builder_branch="$(cd "$WALK_L3_RIG" && git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -1)"
  (cd "$WALK_L3_RIG" && git checkout -q "$builder_branch" 2>&1) | sed 's/^/    /' | tee -a "$WALK_LOG" || true
  test_out="$(cd "$WALK_L3_RIG" && node --test 2>&1)"; test_rc=$?
  log "node --test output (last 20 lines):"
  echo "$test_out" | tail -20 | sed 's/^/    /' | tee -a "$WALK_LOG"
  if [ "$test_rc" -eq 0 ]; then
    step_pass "node --test passes on $builder_branch"
  else
    stop_event_stream
    fail "node --test failed on $builder_branch"
  fi
  if grep -R "percent" "$WALK_L3_RIG/src" "$WALK_L3_RIG/test" >/dev/null 2>&1; then
    step_pass "implementation references percent in source or tests"
  else
    stop_event_stream
    fail "builder commit did not implement the requested percent feature"
  fi

  assert_artifact_has_sections "$WALK_L3_PLAN" \
    '^## Goal' '^## User Stories' '^## Acceptance Criteria'
  assert_artifact_has_sections "$WALK_L3_ARCHITECTURE" \
    '^## Context' '^## Options Considered' '^## Decision'
  assert_artifact_has_sections "$WALK_L3_DESIGN" \
    '^## Interface' '^## Behavior' '^## Edge Cases' '^## Test Plan'

  echo
  echo "[10/10] config-over-chat: add skill to builder + re-sling"
  log "config-over-chat: adding testing-conventions skill to builder"

  # README step 7: add a skill to the builder's skills/ directory (PackV2 convention)
  local skill_dir="$WALK_L3_SCRATCH/packs/lessons/L3/agents/builder/skills/testing-conventions"
  mkdir -p "$skill_dir"
  cat > "$skill_dir/SKILL.md" <<'SKILL'
---
name: testing-conventions
description: Project-specific testing conventions for the calculator.
---

These rules are mandatory for all test files in this project:

- Import `assert` from `node:assert/strict` and use `assert.strictEqual` for every comparison. Never use `assert.equal` or `assert.ok` for value checks.
- Structure every test file with `describe()` blocks. Each exported function gets its own `describe('functionName', () => { ... })` block. Do NOT use bare `test()` calls at the top level.
- Inside each `describe()` block, use `it()` for individual test cases, not `test()`.
- Include at least one edge case per function: zero input, negative input, and boundary values.
- Each `it()` description must state the expected behavior (e.g., "returns zero when input is zero"), not the implementation detail.
SKILL
  step_pass "testing-conventions skill added to builder skills/"

  # README step 7: edit prompt to reference the skill
  local builder_prompt="$WALK_L3_SCRATCH/packs/lessons/L3/agents/builder/prompt.template.md"
  printf '\n- Before writing tests, read the testing-conventions skill and follow its rules for assert methods, describe blocks, and edge cases.\n' >> "$builder_prompt"
  step_pass "builder prompt updated with skill reference"

  # README step 7: restart and re-sling
  (cd "$WALK_L3_FACTORY" && gc restart >/dev/null 2>&1) || true
  wait_for "supervisor responsive after restart" \
    "cd '$WALK_L3_FACTORY' && gc status >/dev/null 2>&1" 120 3 \
    || { stop_event_stream; fail "supervisor unresponsive after config-over-chat restart"; }

  # Snapshot commit count before re-sling so we can detect a genuinely new commit
  local pre_resling_commit_count
  pre_resling_commit_count="$(cd "$WALK_L3_RIG" && git log --all --oneline | wc -l | tr -d ' ')"

  local sling2_out
  sling2_out="$(cd "$WALK_L3_FACTORY" && gc sling planner \
    "Add a negate operation: negate(x) returns -x" \
    --on mol-feature-delivery 2>&1)"
  log "config-over-chat re-sling:"
  echo "$sling2_out" | sed 's/^/    /' | tee -a "$WALK_LOG"

  local expected_commits=$(( pre_resling_commit_count + 1 ))
  local commit2_check='cd "'"$WALK_L3_RIG"'" && [ "$(git log --all --oneline | wc -l | tr -d " ")" -ge '"$expected_commits"' ]'
  if wait_for "second builder commit from skill re-sling" "$commit2_check" 900 20 "" "rig/factory.builder" "$WALK_L3_FACTORY"; then
    step_pass "skill re-sling produced a new builder commit"
    # Verify the skill had causal impact on the NEW commit's tests
    local second_branch
    second_branch="$(cd "$WALK_L3_RIG" && git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -1)"
    (cd "$WALK_L3_RIG" && git checkout -q "$second_branch" 2>&1) || true
    if grep -r 'assert\.strictEqual\|assert/strict' "$WALK_L3_RIG/test" >/dev/null 2>&1; then
      step_pass "skill impact verified: tests use assert.strictEqual"
    else
      log "WARN: second commit does not use assert.strictEqual — skill may not have had impact"
    fi
    if grep -r 'describe(' "$WALK_L3_RIG/test" >/dev/null 2>&1; then
      step_pass "skill impact verified: tests use describe() blocks"
    else
      log "WARN: second commit does not use describe() blocks — skill may not have had impact"
    fi
  else
    log "WARN: skill re-sling did not produce a new builder commit within timeout (non-fatal)"
  fi

  log "what L3 produced (rig tree diff since lesson start):"
  (cd "$WALK_L3_RIG" && find . -type f -not -path './.git/*' -not -path './.beads/*' | sort \
    | diff "$WALK_L3_SCRATCH/rig-tree-before.txt" - | grep '^>' | sed 's/^> /      + /') | tee -a "$WALK_LOG"

  # Save ALL artifacts — every file the agents produced
  save_snapshot "L3" "gc-sling.txt" "$sling_out"
  save_all_artifacts "L3" "plans" "$WALK_L3_RIG/docs/plans"
  save_all_artifacts "L3" "architecture" "$WALK_L3_RIG/docs/architecture"
  save_all_artifacts "L3" "designs" "$WALK_L3_RIG/docs/designs"
  save_snapshot "L3" "node-test.txt" "$test_out"
  save_snapshot "L3" "builder-commit.txt" "$WALK_L3_CODE_COMMITTED"
  save_agent_sessions "L3" "$WALK_L3_FACTORY"

  save_state WALK_L3_PLAN WALK_L3_ARCHITECTURE WALK_L3_DESIGN WALK_L3_CODE_COMMITTED
  stop_event_stream
  return "$lesson_rc"
}

lesson_rc=0

lesson_prerequisites_check || exit 77
lesson_run
exit "$lesson_rc"
