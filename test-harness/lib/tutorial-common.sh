#!/usr/bin/env bash
# tutorial-common.sh — Shared helpers for the SFI tutorial-check and
# tutorial-walkthrough harnesses. Source this after setting the two
# required variables below.
#
# Required from caller:
#   repo_root              — absolute path to the SFI repo root
#   TUTORIAL_SCRATCH_ROOT  — absolute path for this harness's scratch tree
#                            (e.g. /tmp/sfi-tutorial-check,
#                                  /tmp/sfi-tutorial-walkthrough)
#
# Provides:
#   run_id                       — unique suffix (seconds-$pid) for isolation
#   DIVERGENCES_LOG              — path under scratch root
#   FAILED_LESSONS[]             — bash array; lessons may append on failure
#   REGISTERED_CITY_PATHS[]      — bash array; cities to unregister in cleanup
#   cleanup()                    — trap handler (EXIT INT TERM)
#   divergence(), step_pass(), step_fail()
#   assert_gc_version_ge_015
#   assert_gc_doctor_healthy
#   assert_agent_doctor_checks_present
#
# The caller is responsible for:
#   - `set -uo pipefail` at top of its script
#   - `trap cleanup EXIT INT TERM` AFTER sourcing this file
#   - Running `rm -rf "$TUTORIAL_SCRATCH_ROOT" && mkdir -p "$TUTORIAL_SCRATCH_ROOT" && : > "$DIVERGENCES_LOG"`
#
# Not shared (intentionally per-harness):
#   - The scratch-root path itself (set by caller)
#   - The lesson functions (each harness has its own set)
#   - Any host-isolation / provider-shim logic — that belongs to the
#     walkthrough harness only, since tutorial-check explicitly does not
#     require auth.

if [ -z "${repo_root:-}" ]; then
  echo "tutorial-common.sh: caller must set \$repo_root before sourcing" >&2
  return 1 2>/dev/null || exit 1
fi
if [ -z "${TUTORIAL_SCRATCH_ROOT:-}" ]; then
  echo "tutorial-common.sh: caller must set \$TUTORIAL_SCRATCH_ROOT before sourcing" >&2
  return 1 2>/dev/null || exit 1
fi

DIVERGENCES_LOG="$TUTORIAL_SCRATCH_ROOT/divergences.log"
declare -a FAILED_LESSONS=()
declare -a REGISTERED_CITY_PATHS=()

run_bounded() {
  local seconds="$1"; shift
  "$@" &
  local cmd_pid=$!
  (
    sleep "$seconds"
    if kill -0 "$cmd_pid" 2>/dev/null; then
      kill "$cmd_pid" 2>/dev/null || true
      sleep 2
      kill -KILL "$cmd_pid" 2>/dev/null || true
    fi
  ) &
  local watchdog_pid=$!
  wait "$cmd_pid"
  local rc=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  return "$rc"
}

prune_walkthrough_city_registry() {
  local city_path="$1"
  local registry="${HOME}/.gc/cities.toml"
  [ -f "$registry" ] || return 0
  case "$city_path" in
    /tmp/sfi-tutorial-walkthrough/*|/private/tmp/sfi-tutorial-walkthrough/*) ;;
    *) return 0 ;;
  esac
  local tmp
  tmp="$(mktemp "${registry}.XXXXXX")" || return 0
  awk -v p="$city_path" '
    function flush() {
      if (block != "") {
        if (keep) {
          printf "%s", block
        }
        block = ""
        keep = 1
        in_city = 0
      }
    }
    function value(line) {
      sub(/^[[:space:]]*[a-z_]+[[:space:]]*=[[:space:]]*"/, "", line)
      sub(/"[[:space:]]*$/, "", line)
      return line
    }
    BEGIN { keep = 1 }
    /^\[\[/ {
      flush()
      block = $0 ORS
      in_city = ($0 == "[[cities]]")
      city_path = ""
      city_name = ""
      next
    }
    {
      if (block != "") {
        block = block $0 ORS
        if (in_city && $1 == "path") {
          city_path = value($0)
        }
        if (in_city && $1 == "name") {
          city_name = value($0)
        }
        if (in_city && city_path == p && city_name ~ /^sfi-walkthrough-/) {
          keep = 0
        }
      } else {
        print
      }
    }
    END { flush() }
  ' "$registry" > "$tmp" && mv "$tmp" "$registry" || rm -f "$tmp"
}

# Unique suffix so parallel runs (and cohort users on the same machine)
# don't collide on registry names or scratch paths.
run_id="$(date +%s)-$$"

cleanup() {
  local rc="${1:-$?}"
  # Stop any still-running standalone controllers so unregister can tear
  # down state cleanly. Then unregister by absolute path (gc unregister
  # takes a path, not a --name — learned the hard way).
  for city_path in "${REGISTERED_CITY_PATHS[@]-}"; do
    [ -n "$city_path" ] || continue
    (cd "$city_path" 2>/dev/null && run_bounded 20 gc stop >/dev/null 2>&1) || true
    run_bounded 30 gc unregister "$city_path" >/dev/null 2>&1 || prune_walkthrough_city_registry "$city_path"
  done
  echo
  if [ -s "$DIVERGENCES_LOG" ]; then
    echo "Divergences logged ($(wc -l <"$DIVERGENCES_LOG" | tr -d ' ') entries): $DIVERGENCES_LOG"
  fi
  exit "$rc"
}

divergence() {
  local lesson="$1" detail="$2"
  echo "[$lesson] $detail" >> "$DIVERGENCES_LOG"
  echo "    ⚠ $detail"
}
step_pass() { echo "    ✓ $1"; }
# step_fail sets lesson_rc in the caller's scope (each lesson_* function
# declares `local lesson_rc=0` at its start).
step_fail() { echo "    ✗ $1" >&2; lesson_rc=1; }

assert_gc_version_ge_015() {
  local v
  v="$(gc version 2>&1 | tail -1 | tr -d ' \r\n')"
  case "$v" in
    0.1[5-9]*|0.[2-9]*|[1-9].*|[1-9][0-9]*.*) step_pass "gc version $v (≥ 0.15.0)" ;;
    *) step_fail "gc version $v — expected ≥ 0.15.0" ;;
  esac
}

# Prints doctor output to stdout (for further inspection by caller) and
# pass/fails on the two documented deprecation warnings.
assert_gc_doctor_healthy() {
  local city_dir="$1" doctor_out
  doctor_out="$(cd "$city_dir" && gc doctor 2>&1)"
  # Expected documented warnings (workshop:#781, #600).
  if echo "$doctor_out" | grep -q 'v2-default-rig-import-format'; then
    step_pass "gc doctor emits documented v2-default-rig-import-format warning"
  else
    step_fail "gc doctor missing documented v2-default-rig-import-format warning"
  fi
  if echo "$doctor_out" | grep -q 'v2-workspace-name'; then
    step_pass "gc doctor emits documented v2-workspace-name warning"
  else
    step_fail "gc doctor missing documented v2-workspace-name warning"
  fi
  echo "$doctor_out"
}

assert_agent_doctor_checks_present() {
  local doctor_out="$1"
  shift
  local agent
  for agent in "$@"; do
    if echo "$doctor_out" | grep -q ":check-${agent}"; then
      step_pass "$agent doctor check present"
    else
      step_fail "$agent doctor check missing from gc doctor output"
    fi
  done
}
