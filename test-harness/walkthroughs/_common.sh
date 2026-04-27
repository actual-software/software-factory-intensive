#!/usr/bin/env bash
# test-harness/walkthroughs/_common.sh — shared helpers for per-lesson walkthrough scripts.
#
# Sourced by each test-harness/walkthroughs/<lesson>.sh. Assumes the
# dispatcher has set WALK_REPO_ROOT, WALK_SCRATCH, WALK_DIVERGENCES,
# WALK_STATE_ENV, WALK_DRY_RUN, WALK_LESSON_NAME before invoking.
#
# Also sources the setup-phase library for step_pass/step_fail/
# divergence/assert_gc_* — so lesson scripts have both sets of helpers.

if [ -z "${WALK_REPO_ROOT:-}" ]; then
  echo "_common.sh: WALK_REPO_ROOT not set — this file is sourced by test-harness/walkthroughs/<lesson>.sh, which is invoked by test-harness/tutorial-walkthrough.sh" >&2
  return 1 2>/dev/null || exit 1
fi

# Setup-phase helpers. The library expects repo_root + TUTORIAL_SCRATCH_ROOT.
repo_root="$WALK_REPO_ROOT"
TUTORIAL_SCRATCH_ROOT="$(dirname "$WALK_SCRATCH")"
# shellcheck source=../lib/tutorial-common.sh
source "$WALK_REPO_ROOT/test-harness/lib/tutorial-common.sh"

# --- Per-lesson log ----------------------------------------------------

WALK_LOG="$WALK_SCRATCH/$WALK_LESSON_NAME.log"
: > "$WALK_LOG"
LESSON_CLEANED_UP=0

log() {
  # Append to per-lesson log and stderr. Writing to stderr (not stdout)
  # lets helpers like _stage() return their result on stdout via
  # `echo "$bead_id"` without polluting the caller's `$(...)` capture.
  # The outer `bash ... 2>&1 | tee /tmp/<lesson>.log` still captures
  # these lines in the tee'd transcript.
  local line
  line="$(date +%H:%M:%S) $*"
  printf '%s\n' "$line" >&2
  printf '%s\n' "$line" >> "$WALK_LOG"
}
fail() {
  echo "✗ $*" >&2
  echo "$(date +%H:%M:%S) FAIL: $*" >> "$WALK_LOG"
  exit 1
}

lesson_cleanup() {
  [ "${LESSON_CLEANED_UP:-0}" -eq 0 ] || return 0
  LESSON_CLEANED_UP=1

  stop_event_stream

  local city_path
  for city_path in "${REGISTERED_CITY_PATHS[@]-}"; do
    [ -n "$city_path" ] || continue
    (cd "$city_path" 2>/dev/null && run_bounded 20 gc stop >/dev/null 2>&1) || true
    run_bounded 30 gc unregister "$city_path" >/dev/null 2>&1 || prune_walkthrough_city_registry "$city_path"
  done
  REGISTERED_CITY_PATHS=()

  run_bounded 15 gc supervisor reload >/dev/null 2>&1 || true

  local walk_scratch_alt="$WALK_SCRATCH"
  case "$walk_scratch_alt" in
    /private/tmp/*) walk_scratch_alt="/tmp/${walk_scratch_alt#/private/tmp/}" ;;
    /tmp/*) walk_scratch_alt="/private/tmp/${walk_scratch_alt#/tmp/}" ;;
  esac
  ps -axo pid,command \
    | awk -v root="$WALK_SCRATCH" -v alt="$walk_scratch_alt" '
        (index($0, root) > 0 || index($0, alt) > 0) && $0 ~ /dolt sql-server|tmux -u -L sfi-walkthrough-|claude --dangerously-skip-permissions|gc events --follow|gc nudge poll --city/ {
          print $1
        }' \
    | xargs -r kill 2>/dev/null || true
}

trap 'lesson_cleanup' EXIT
trap 'lesson_cleanup; exit 130' INT
trap 'lesson_cleanup; exit 143' TERM

register_walkthrough_city() {
  local factory="$1" city_name="$2" lesson="$3"
  local out_file="$WALK_SCRATCH/register-$lesson.out"
  : > "$out_file"

  (cd "$factory" && run_bounded "${WALK_REGISTER_TIMEOUT_SECONDS:-60}" gc register --name "$city_name" . >"$out_file" 2>&1)
  local register_rc=$?
  local register_out
  register_out="$(cat "$out_file" 2>/dev/null || true)"

  log "gc register output (first 10 lines):"
  echo "$register_out" | head -10 | sed 's/^/    /' | tee -a "$WALK_LOG"

  if echo "$register_out" | grep -q "Registered city '$city_name'"; then
    REGISTERED_CITY_PATHS+=("$factory")
    step_pass "gc register --name $city_name . registered city"
    return 0
  fi

  if gc cities 2>/dev/null | awk -v n="$city_name" '$1 == n { found = 1 } END { exit !found }'; then
    REGISTERED_CITY_PATHS+=("$factory")
    divergence "$lesson" "gc register timed out or omitted marker after creating $city_name; continuing from registry evidence"
    step_pass "gc register --name $city_name . registered city"
    return 0
  fi

  step_fail "gc register did not emit 'Registered city' marker"
  return "$register_rc"
}

# --- State.env plumbing ------------------------------------------------

# Call once after setting shell vars you want to export to later lessons:
#   save_state WALK_FACTORY WALK_RIG WALK_CITY_NAME
save_state() {
  local var
  for var in "$@"; do
    # Only export if the var has a value.
    if [ -n "${!var:-}" ]; then
      # Strip any prior line for this var, then append fresh.
      if [ -f "$WALK_STATE_ENV" ]; then
        grep -v "^${var}=" "$WALK_STATE_ENV" > "$WALK_STATE_ENV.tmp" 2>/dev/null || true
        mv "$WALK_STATE_ENV.tmp" "$WALK_STATE_ENV"
      fi
      printf '%s=%q\n' "$var" "${!var}" >> "$WALK_STATE_ENV"
    fi
  done
}

# --- Event stream observability ---------------------------------------

# start_event_stream <factory-path>
# Spawns `gc events --follow` against the factory, filters noise, and
# appends to $WALK_SCRATCH/gc-events.log. The PID is saved so
# stop_event_stream can kill it. Safe to call even if gc events fails —
# the stream is best-effort observability, never a correctness signal.
#
# The filter drops:
#   - agent session lifecycle beads (issue_type == "session")
#   - beads-health / improver-cooldown / mol-feedback system-pack noise
#   - system-pack session beads (sw<digits>-<hash> pattern)
start_event_stream() {
  local factory="$1"
  local events_log="$WALK_SCRATCH/gc-events.log"
  : > "$events_log"

  # As of gc 0.15+, `gc events` always outputs JSON Lines — no --json
  # flag. `--follow` streams continuously. The jq filter is tolerant of
  # missing fields (old wire format had .subject/.message/.payload;
  # shape may evolve further — we use `//""` defaults throughout).
  (
    cd "$factory" && gc events --follow 2>/dev/null \
      | stdbuf -oL jq --unbuffered -r '
          select(
            (.payload.issue_type // "") != "session"
            and ((.message // "") | test("order:(beads-health|improver-cooldown|mol-feedback)") | not)
            and ((.subject // "") | test("^sw[0-9]+-") | not)
          )
          | "\((.ts // "")[11:19]) \(.type // "?") subject=\(.subject // "") msg=\(.message // "") actor=\(.actor // "")"'
  ) > "$events_log" 2>&1 &

  echo $! > "$WALK_SCRATCH/events.pid"
  log "event stream → $events_log (PID $(cat "$WALK_SCRATCH/events.pid"))"
}

# stop_event_stream
# Safe to call multiple times; no-op if stream wasn't started.
stop_event_stream() {
  local pid_file="$WALK_SCRATCH/events.pid"
  if [ -f "$pid_file" ]; then
    local pid
    pid="$(cat "$pid_file")"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      # Give the jq pipe a beat to flush.
      sleep 1
    fi
    rm -f "$pid_file"
  fi
}

# --- Poll-for-condition ------------------------------------------------

# rescue_dead_session <rig> <bead-id> <target-template>
#
# When an LLM session dies mid-task (the Claude Code session exits
# before producing its artifact), the bead it was working on still has
# its assignee set. The reconciler's scale_check filters on
# `--unassigned`, so a dead-but-assigned bead is invisible to the
# reconciler and no new session spawns. The bead is orphaned.
#
# Rescue: clear the assignee and re-sling with --force (to overwrite
# the stale gc.routed_to metadata). The reconciler picks it up on the
# next tick and spawns a fresh session.
#
# Verified empirically: L4 and C1 each needed one rescue during their
# first end-to-end validation run.
rescue_dead_session() {
  local rig="$1" bead="$2" target="$3"
  log "    rescue: bd update $bead --assignee '' && gc sling --nudge --force $target $bead"
  (cd "$rig" && bd update "$bead" --assignee "" >/dev/null 2>&1) || true
  local factory_dir
  factory_dir="$(cd "$rig" && dirname "$(pwd)")/my-factory"
  # Fallback: caller's WALK_*_FACTORY if we couldn't derive.
  [ -d "$factory_dir" ] || factory_dir="${WALK_FACTORY:-$factory_dir}"
  (cd "$factory_dir" && gc sling --nudge --force "$target" "$bead" >/dev/null 2>&1) || true
}

# wait_for <description> <shell-command> <timeout-seconds> [<poll-interval>]
# Polls until the command exits 0. Emits a heartbeat log line every 60s
# so any observer (tee'd log, tail -f) sees that work is still happening
# during multi-minute LLM stages. Writes last output to $WALK_LOG on
# timeout. Returns 0 on success, 1 on timeout.
#
# The heartbeat cadence matches the operating rule: never go silent on a
# long-running wait — ~60s is the max a caller should have to wait for a
# "still alive, still working" signal. Progress without heartbeats looks
# identical to a stuck run.
# Query a session's current state from the factory.
# Args: <factory-path> <session-target>
# Echoes one of: active, asleep, missing, unknown
session_state() {
  local factory="$1" target="$2"
  if [ -z "$factory" ] || [ -z "$target" ]; then echo unknown; return; fi
  local out
  out="$(cd "$factory" 2>/dev/null && gc session list 2>/dev/null)" || { echo unknown; return; }
  # gc session list columns: ID TEMPLATE STATE REASON TARGET ...
  # Pick the line whose TEMPLATE matches (2nd column).
  local line
  line="$(printf '%s\n' "$out" | awk -v t="$target" 'NR>1 && $2==t {print; exit}')"
  if [ -z "$line" ]; then echo missing; return; fi
  printf '%s\n' "$line" | awk '{print $3}'
}

session_ref() {
  local factory="$1" target="$2"
  if [ -z "$factory" ] || [ -z "$target" ]; then return 1; fi
  local out line
  out="$(cd "$factory" 2>/dev/null && gc session list 2>/dev/null)" || return 1
  line="$(printf '%s\n' "$out" | awk -v t="$target" 'NR>1 && ($2==t || $5==t) {print; exit}')"
  [ -n "$line" ] || return 1
  printf '%s\n' "$line" | awk '{print $1}'
}

progress_snapshot() {
  local factory="$1" target="${2:-}" rig="${WALK_RIG:-}" root_bead="${WALK_ROOT_BEAD_ID:-}"
  [ -n "$factory" ] && [ -d "$factory" ] || return 0

  log "      progress snapshot: gc session list"
  (cd "$factory" && gc session list 2>&1 | head -30 | sed 's/^/        /') | tee -a "$WALK_LOG" || true

  if [ -n "$target" ]; then
    local ref
    ref="$(session_ref "$factory" "$target" 2>/dev/null || true)"
    if [ -n "$ref" ]; then
      log "      progress snapshot: gc session peek $target via $ref (tail)"
      (cd "$factory" && gc session peek "$ref" 2>&1 | tail -40 | sed 's/^/        /') | tee -a "$WALK_LOG" || true
    else
      log "      progress snapshot: no live session ref for $target"
    fi
  fi

  if [ -n "$root_bead" ]; then
    log "      progress snapshot: gc graph $root_bead"
    (cd "$factory" && gc graph "$root_bead" 2>&1 | tail -60 | sed 's/^/        /') | tee -a "$WALK_LOG" || true
  fi

  if [ -n "$rig" ] && [ -d "$rig" ]; then
    log "      progress snapshot: bd graph --all --compact"
    (cd "$rig" && bd graph --all --compact 2>&1 | tail -80 | sed 's/^/        /') | tee -a "$WALK_LOG" || true
    log "      progress snapshot: bd list"
    (cd "$rig" && bd list --all --limit 20 2>&1 | tail -40 | sed 's/^/        /') | tee -a "$WALK_LOG" || true
  fi
}

wait_for() {
  local desc="$1" cmd="$2" timeout="$3" interval="${4:-3}"
  local rescue_cmd="${5:-}"        # optional shell to run when session is asleep/missing past rescue_after
  local session_target="${6:-}"    # e.g., rig/planner.planner
  local factory_path="${7:-${WALK_FACTORY:-}}"
  local heartbeat="${WALK_HEARTBEAT_SECONDS:-60}"
  local rescue_after="${WAIT_RESCUE_AFTER:-120}"
  local start="$SECONDS" last_beat="$SECONDS" last_out="" last_rc=1
  local rescued=0
  log "    waiting: $desc (≤${timeout}s, poll every ${interval}s, heartbeat every ${heartbeat}s)"
  local tick_log="$WALK_SCRATCH/wait_for.ticks"
  while [ $((SECONDS - start)) -lt "$timeout" ]; do
    printf '%s SECONDS=%d elapsed=%d desc=%q\n' "$(date +%H:%M:%S)" "$SECONDS" "$((SECONDS - start))" "$desc" >> "$tick_log"
    last_out="$(eval "$cmd" 2>&1)"; last_rc=$?
    if [ "$last_rc" -eq 0 ]; then
      log "    ✓ $desc ($((SECONDS - start))s)"
      return 0
    fi
    # On each heartbeat, also peek the session state so observers can
    # see whether the agent is actually working or parked.
    if [ $((SECONDS - last_beat)) -ge "$heartbeat" ]; then
      local state_msg=""
      if [ -n "$session_target" ]; then
        local st
        st="$(session_state "$factory_path" "$session_target")"
        state_msg=" session=$st"
      fi
      log "    … still waiting: $desc ($((SECONDS - start))s elapsed / ${timeout}s budget)${state_msg}"
      progress_snapshot "$factory_path" "$session_target"
      last_beat="$SECONDS"
    fi
    # State-driven rescue: if caller gave us a session_target and the
    # session is asleep or missing (dead) past the grace period, clear
    # the assignee + re-sling. Fallback to timer-based rescue if no
    # target was provided (preserves old callers).
    if [ "$rescued" -eq 0 ] && [ -n "$rescue_cmd" ] && [ $((SECONDS - start)) -ge "$rescue_after" ]; then
      local should_rescue=0
      if [ -n "$session_target" ]; then
        local st2
        st2="$(session_state "$factory_path" "$session_target")"
        if [ "$st2" = "asleep" ] || [ "$st2" = "missing" ]; then
          log "    … session state=$st2 after ${rescue_after}s — invoking rescue hook"
          should_rescue=1
        fi
      else
        log "    … no progress after ${rescue_after}s — invoking rescue hook"
        should_rescue=1
      fi
      if [ "$should_rescue" -eq 1 ]; then
        eval "$rescue_cmd" 2>&1 | sed 's/^/      rescue: /' | tee -a "$WALK_LOG"
        rescued=1
      fi
    fi
    sleep "$interval"
  done
  log "    ✗ TIMEOUT after ${timeout}s waiting for: $desc"
  if [ -n "$last_out" ]; then
    log "      last output ($(echo "$last_out" | wc -l | tr -d ' ') lines, tail 5):"
    echo "$last_out" | tail -5 | sed 's/^/        /' | tee -a "$WALK_LOG"
  fi
  return 1
}

# wait_for_bead_closed <rig-path> <bead-id> <timeout> [<interval>]
wait_for_bead_closed() {
  local rig_path="$1" bead="$2" timeout="$3" interval="${4:-8}"
  wait_for "bead $bead closed" \
    "cd '$rig_path' && bd show '$bead' --json 2>/dev/null | jq -e '.status == \"closed\"' >/dev/null" \
    "$timeout" "$interval"
}

# --- Assertions --------------------------------------------------------

# assert_glob_nonempty <dir> <pattern> <description>
assert_glob_nonempty() {
  local dir="$1" pattern="$2" desc="$3"
  shopt -s nullglob
  local matches=( "$dir"/$pattern )
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 0 ]; then
    step_fail "$desc — no file matches $dir/$pattern"
    return 1
  fi
  local first="${matches[0]}"
  if [ ! -s "$first" ]; then
    step_fail "$desc — file exists but is empty: $first"
    return 1
  fi
  step_pass "$desc → $first ($(wc -c <"$first" | tr -d ' ') bytes)"
}

# assert_artifact_has_sections <file> <section-header-regex>...
# Each regex must match at least one line in <file>. Match is
# case-INSENSITIVE — LLM-authored markdown varies in title-case vs
# sentence-case across prompts (we've observed "## User story" vs
# "## User Story" in the same Planner pack). Case doesn't change which
# section a header identifies semantically, so the helper matches
# either. If a walkthrough author needs case-strict matching, write
# the regex directly with grep inline.
# assert_file_contains_at_least <file> <count> <description> <grep-regex>
# Fails if the regex matches fewer than <count> lines in <file>. Used to
# verify README content claims like "work package has ≥1 user story" or
# "ADR considers ≥2 options" — claims the activity README makes in its
# exit criteria that purely-structural section checks can't verify.
#
# Patterns are case-INSENSITIVE (grep -i). Multiple matches on the same
# line count as 1 — we're checking line count, not occurrence count.
assert_file_contains_at_least() {
  local file="$1" count="$2" desc="$3" pattern="$4"
  if [ ! -s "$file" ]; then
    step_fail "$desc — file missing or empty: $file"
    return 1
  fi
  # grep -c can emit weird multi-line output on some platforms/regexes;
  # pipe through wc -l of matching lines for a reliable integer.
  local hits
  hits=$(grep -iE "$pattern" "$file" 2>/dev/null | wc -l | tr -d '[:space:]')
  hits=${hits:-0}
  # Strip anything non-numeric as a last-resort guard.
  hits=$(printf '%s' "$hits" | tr -dc '0-9')
  : "${hits:=0}"
  if [ "$hits" -lt "$count" ]; then
    step_fail "$desc — expected ≥${count} matches for '$pattern' in $(basename "$file"), found $hits"
    return 1
  fi
  step_pass "$desc ($hits matches)"
}

# assert_artifact_has_sections <file> <section-header-regex>...
assert_artifact_has_sections() {
  local file="$1"; shift
  if [ ! -s "$file" ]; then
    step_fail "$file — file missing or empty"
    return 1
  fi
  local missing=()
  local sect
  for sect in "$@"; do
    if ! grep -iEq "$sect" "$file"; then
      missing+=("$sect")
    fi
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    step_pass "$file has all required sections ($#)"
  else
    step_fail "$file missing sections: ${missing[*]}"
  fi
}

# --- Snapshot helpers --------------------------------------------------
#
# save_snapshot saves walkthrough output to test-harness/walkthrough-snapshots/<lesson>/
# so the validate-lesson-content skill can harvest it and update READMEs.

WALK_SNAPSHOTS_DIR="$WALK_REPO_ROOT/test-harness/walkthrough-snapshots"

save_snapshot() {
  local lesson="$1" name="$2" content="$3"
  local dir="$WALK_SNAPSHOTS_DIR/$lesson"
  mkdir -p "$dir"
  printf '%s\n' "$content" > "$dir/$name"
  log "snapshot saved: walkthrough-snapshots/$lesson/$name"
}

save_snapshot_file() {
  local lesson="$1" name="$2" src="$3"
  local dir="$WALK_SNAPSHOTS_DIR/$lesson"
  mkdir -p "$dir"
  if [ -f "$src" ]; then
    cp "$src" "$dir/$name"
    log "snapshot saved: walkthrough-snapshots/$lesson/$name (from $src)"
  else
    log "snapshot skipped: $src does not exist"
  fi
}

# save_all_artifacts <lesson> <prefix> <dir> [<pattern>]
# Saves every file matching <pattern> (default *.md) from <dir> into
# walkthrough-snapshots/<lesson>/<prefix>-<filename> plus a sections file.
save_all_artifacts() {
  local lesson="$1" prefix="$2" dir="$3" pattern="${4:-*.md}"
  local snap_dir="$WALK_SNAPSHOTS_DIR/$lesson"
  mkdir -p "$snap_dir"
  shopt -s nullglob
  local files=( "$dir"/$pattern )
  shopt -u nullglob
  for f in "${files[@]}"; do
    local base
    base="$(basename "$f")"
    cp "$f" "$snap_dir/${prefix}-${base}"
    log "snapshot saved: walkthrough-snapshots/$lesson/${prefix}-${base}"
    grep -E '^##? ' "$f" > "$snap_dir/${prefix}-${base%.md}-sections.txt" 2>/dev/null || true
    log "snapshot saved: walkthrough-snapshots/$lesson/${prefix}-${base%.md}-sections.txt"
  done
}

# save_agent_sessions <lesson> <factory-path>
# Captures the session peek output for every agent that ran during the lesson.
# This records the agent's conversation including tool calls, MCP usage, and
# skill references — evidence that config changes materially affected output.
save_agent_sessions() {
  local lesson="$1" factory="$2"
  local snap_dir="$WALK_SNAPSHOTS_DIR/$lesson/sessions"
  mkdir -p "$snap_dir"
  local sessions
  sessions="$(cd "$factory" && gc session list 2>/dev/null)" || return 0
  echo "$sessions" | awk 'NR>1 && $2 ~ /^rig\/factory\./ {print $1, $2}' | while read -r sid template; do
    local agent_name
    agent_name="$(echo "$template" | sed 's|rig/factory\.||')"
    (cd "$factory" && gc session peek "$sid" 2>&1) > "$snap_dir/${agent_name}.txt" 2>/dev/null || true
    log "snapshot saved: walkthrough-snapshots/$lesson/sessions/${agent_name}.txt"
  done
}

save_artifact_sections() {
  local lesson="$1" name="$2" artifact="$3"
  if [ -f "$artifact" ]; then
    grep -E '^##? ' "$artifact" > "$WALK_SNAPSHOTS_DIR/$lesson/$name" 2>/dev/null || true
    log "snapshot saved: walkthrough-snapshots/$lesson/$name (section headers)"
  fi
}

# --- Pre-flight helpers ------------------------------------------------

# Clean up any sfi-walkthrough-* cities left behind by prior killed runs.
purge_stranded_walkthrough_cities() {
  local stranded
  stranded="$(gc cities 2>/dev/null | awk '$1 ~ /^sfi-walkthrough-/ {print $2}')"
  if [ -z "$stranded" ]; then
    step_pass "no stranded sfi-walkthrough-* cities"
    return
  fi
  divergence "$WALK_LESSON_NAME" "found stranded sfi-walkthrough-* cities from prior runs; cleaning up"
  while IFS= read -r city_path; do
    [ -n "$city_path" ] || continue
    (cd "$city_path" 2>/dev/null && run_bounded 20 gc stop >/dev/null 2>&1) || true
    if run_bounded 30 gc unregister "$city_path" >/dev/null 2>&1; then
      log "    purged $city_path"
    else
      prune_walkthrough_city_registry "$city_path"
      log "    purge timed out for $city_path"
    fi
  done <<< "$stranded"
}

# Verify the tools a live-agent walkthrough needs.
assert_walkthrough_preflight() {
  assert_gc_version_ge_015
  if command -v claude >/dev/null 2>&1; then
    step_pass "claude CLI on PATH ($(command -v claude))"
  else
    step_fail "claude CLI not on PATH — install Claude Code before running"
  fi
  if claude auth status >/dev/null 2>&1; then
    step_pass "claude CLI authenticated"
  else
    step_fail "claude CLI not authenticated — run 'claude auth login'"
  fi
  local tool
  for tool in jq tmux git bd; do
    if command -v "$tool" >/dev/null 2>&1; then
      step_pass "$tool available"
    else
      step_fail "$tool not on PATH"
    fi
  done
}
