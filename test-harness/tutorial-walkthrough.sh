#!/usr/bin/env bash
# tutorial-walkthrough.sh — End-to-end workshop walkthrough dispatcher.
#
# Drives the Software Factory Intensive workshop through real live-LLM
# agent runs, one lesson at a time. Per-lesson bodies live under
# test-harness/walkthroughs/<lesson>.sh and are invoked here with a shared
# state.env so later lessons can chain off earlier ones (just like a
# real student's factory state accumulates across sessions).
#
# Usage:
#   bash test-harness/tutorial-walkthrough.sh <lesson>        # run one lesson
#   bash test-harness/tutorial-walkthrough.sh                 # run all known lessons in order
#
# Environment:
#   TUTORIAL_WALKTHROUGH_DRY_RUN=1       — skip live-agent steps
#   TUTORIAL_WALKTHROUGH_KEEP_SCRATCH=1  — leave $WALK_SCRATCH for inspection
#
# Exit codes:
#   0  — all requested lessons passed
#   1  — one or more lessons failed
#   77 — lesson prerequisites not met (dispatcher aborts the chain)

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
WALK_REPO_ROOT="$repo_root"

# Canonical path (resolve /tmp → /private/tmp on macOS). gc rig add's
# server-reuse check compares process args as strings, so if gc register
# canonicalizes the cwd to /private/tmp/... and we then invoke gc rig add
# from /tmp/..., verify_our_server fails and rig-add tries to spawn a
# second dolt that collides on the start lock. Using the canonical path
# everywhere sidesteps that mismatch.
TUTORIAL_SCRATCH_ROOT="$(cd "$(mkdir -p /tmp/sfi-tutorial-walkthrough && echo /tmp/sfi-tutorial-walkthrough)" && pwd -P)"

# The library (run_id + cleanup + divergence/pass/fail + asserts). The
# library's cleanup handles unregister-by-path for everything in
# REGISTERED_CITY_PATHS; we wrap it below with walkthrough-specific
# pre-work (gc stop, tmux kill, scratch rm).
# shellcheck source=lib/tutorial-common.sh
source "$repo_root/test-harness/lib/tutorial-common.sh"

# Canonical lesson order. L1 is setup-only (city + rig registration);
# the live FormulaV2 walkthroughs begin at L2.
ALL_LESSONS=(L1 L2 L3 L4 C1)

# --- state -------------------------------------------------------------

WALK_SCRATCH="$TUTORIAL_SCRATCH_ROOT/$run_id"
WALK_DIVERGENCES="$DIVERGENCES_LOG"
WALK_STATE_ENV="$WALK_SCRATCH/state.env"
WALK_DRY_RUN="${TUTORIAL_WALKTHROUGH_DRY_RUN:-0}"
export WALK_REPO_ROOT WALK_SCRATCH WALK_DIVERGENCES WALK_STATE_ENV WALK_DRY_RUN

# --- cleanup -----------------------------------------------------------

walkthrough_cleanup() {
  local rc=$?
  # Source state.env so we see WALK_FACTORY even if the lesson body
  # only exported it (and this cleanup runs after it exited).
  if [ -s "$WALK_STATE_ENV" ]; then
    set -a; source "$WALK_STATE_ENV"; set +a
  fi
  # Safety-net: kill any lesson-started event stream whose process
  # survived (lesson_run normally calls stop_event_stream, but if it
  # crashed or was interrupted the PID file may still be live).
  if [ -f "$WALK_SCRATCH/events.pid" ]; then
    local ev_pid
    ev_pid="$(cat "$WALK_SCRATCH/events.pid" 2>/dev/null)"
    if [ -n "$ev_pid" ] && kill -0 "$ev_pid" 2>/dev/null; then
      kill "$ev_pid" 2>/dev/null || true
      wait "$ev_pid" 2>/dev/null || true
    fi
    rm -f "$WALK_SCRATCH/events.pid"
  fi
  # Best-effort stop of any factory the lessons spun up.
  if [ -n "${WALK_FACTORY:-}" ] && [ -d "${WALK_FACTORY:-}" ]; then
    (cd "$WALK_FACTORY" 2>/dev/null && run_bounded 20 gc stop >/dev/null 2>&1) || true
  fi
  # Unregister before deleting scratch; gc unregister may need the city
  # directory to tear down runtime providers cleanly.
  for city_path in "${REGISTERED_CITY_PATHS[@]-}"; do
    [ -n "$city_path" ] || continue
    (cd "$city_path" 2>/dev/null && run_bounded 20 gc stop >/dev/null 2>&1) || true
    run_bounded 30 gc unregister "$city_path" >/dev/null 2>&1 || prune_walkthrough_city_registry "$city_path"
  done
  REGISTERED_CITY_PATHS=()
  run_bounded 15 gc supervisor reload >/dev/null 2>&1 || true
  # Kill test-owned runtime processes rooted in this walkthrough's scratch tree.
  # `gc stop` is best-effort; live agent sessions can otherwise leave Dolt,
  # tmux, or provider CLIs alive after the walkthrough exits.
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
  # Kill any tmux server rooted at our isolated TMUX_TMPDIR.
  if [ -n "${TMUX_TMPDIR:-}" ] && [ -d "${TMUX_TMPDIR:-}" ]; then
    tmux -S "$TMUX_TMPDIR/default" kill-server >/dev/null 2>&1 || true
  fi
  # Give the standalone controller's fds a beat to close before we
  # rm -rf (otherwise we get "Directory not empty" spam).
  sleep 2
  if [ "${TUTORIAL_WALKTHROUGH_KEEP_SCRATCH:-0}" = "1" ]; then
    echo
    echo "TUTORIAL_WALKTHROUGH_KEEP_SCRATCH=1 — scratch retained at: $WALK_SCRATCH"
  else
    rm -rf "$WALK_SCRATCH" 2>/dev/null || true
  fi
  # Library cleanup handles gc unregister per REGISTERED_CITY_PATHS and
  # prints the divergence summary, then exits with $rc.
  cleanup "$rc"
}
trap walkthrough_cleanup EXIT INT TERM

# Only clean up our own run_id scratch, not the entire parent — another
# walkthrough (e.g., a live run while pre-commit does a dry-run) may be
# using a sibling directory under the same TUTORIAL_SCRATCH_ROOT.
rm -rf "$WALK_SCRATCH"
mkdir -p "$WALK_SCRATCH"
: > "$DIVERGENCES_LOG"
: > "$WALK_STATE_ENV"

# --- args --------------------------------------------------------------

requested_lessons=( "$@" )
if [ "${#requested_lessons[@]}" -eq 0 ]; then
  requested_lessons=( "${ALL_LESSONS[@]}" )
fi

# Validate every requested lesson has a script.
for lesson in "${requested_lessons[@]}"; do
  if [ ! -f "$repo_root/test-harness/walkthroughs/$lesson.sh" ]; then
    echo "tutorial-walkthrough: no script at test-harness/walkthroughs/$lesson.sh" >&2
    exit 1
  fi
done

# --- dispatch ----------------------------------------------------------

echo "== tutorial-walkthrough =="
echo "repo: $repo_root"
echo "scratch: $WALK_SCRATCH"
echo "run_id: $run_id"
if [ "$WALK_DRY_RUN" = "1" ]; then
  echo "mode: DRY RUN"
fi
echo "lessons: ${requested_lessons[*]}"
echo

walkthrough_failed=0
for lesson in "${requested_lessons[@]}"; do
  echo
  echo "########################################################"
  echo "# LESSON: $lesson"
  echo "########################################################"

  # Re-source state.env so each lesson sees what prior lessons exported.
  # shellcheck disable=SC1090
  if [ -s "$WALK_STATE_ENV" ]; then
    set -a
    source "$WALK_STATE_ENV"
    set +a
  fi

  export WALK_LESSON_NAME="$lesson"
  lesson_script="$repo_root/test-harness/walkthroughs/$lesson.sh"

  bash "$lesson_script"
  lesson_rc=$?

  case "$lesson_rc" in
    0)
      echo "✓ $lesson passed"
      ;;
    77)
      echo "✗ $lesson: prerequisites not met — aborting chain" >&2
      walkthrough_failed=1
      break
      ;;
    *)
      echo "✗ $lesson: exit $lesson_rc" >&2
      walkthrough_failed=1
      # Continue running subsequent lessons? For v1: halt. If later we
      # want --continue-on-failure, flip this.
      break
      ;;
  esac
done

echo
if [ "$walkthrough_failed" -eq 0 ]; then
  if [ "$WALK_DRY_RUN" = "1" ]; then
    echo "✓ tutorial-walkthrough (dry run): ${#requested_lessons[@]} lesson(s) passed"
  else
    echo "✓ tutorial-walkthrough: ${#requested_lessons[@]} lesson(s) passed"
  fi
  exit 0
else
  echo "✗ tutorial-walkthrough: chain halted on failure"
  exit 1
fi
