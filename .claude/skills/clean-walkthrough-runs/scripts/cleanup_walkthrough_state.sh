#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  cleanup_walkthrough_state.sh status
  cleanup_walkthrough_state.sh clean --kill [--kill-hooks]

Reports or cleans Software Factory Intensive walkthrough state:
  - registered gc cities named sfi-walkthrough-*
  - processes rooted in /tmp/sfi-tutorial-walkthrough or named sfi-walkthrough-*
  - optional hook-owned chains: .githooks/pre-commit -> behavioral-smoke -> tutorial-walkthrough

The clean command requires --kill. Hook-owned cleanup also requires --kill-hooks.
USAGE
}

mode="${1:-status}"
shift || true

kill_processes=0
kill_hooks=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --kill) kill_processes=1 ;;
    --kill-hooks) kill_hooks=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$mode" in
  status|clean) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown mode: $mode" >&2; usage >&2; exit 2 ;;
esac

if [ "$mode" = "clean" ] && [ "$kill_processes" -ne 1 ]; then
  echo "clean requires --kill" >&2
  exit 2
fi

echo "== registered sfi walkthrough cities =="
if command -v gc >/dev/null 2>&1; then
  gc cities 2>/dev/null | awk 'NR == 1 || $1 ~ /^sfi-walkthrough-/' || true
else
  echo "gc not found"
fi

echo
echo "== walkthrough processes =="
ps -axo pid,ppid,etime,state,command \
  | awk '
      NR == 1 { print; next }
      index($0, " awk ") > 0 { next }
      index($0, "sfi-tutorial-walkthrough") > 0 ||
      index($0, "sfi-walkthrough-") > 0 ||
      index($0, "test-harness/tutorial-walkthrough.sh") > 0 ||
      index($0, "test-harness/behavioral-smoke.sh") > 0 ||
      index($0, ".githooks/pre-commit") > 0 { print }
    ' || true

if [ "$mode" != "clean" ]; then
  exit 0
fi

echo
echo "== cleaning registered sfi walkthrough cities =="
if command -v gc >/dev/null 2>&1; then
  gc cities 2>/dev/null \
    | awk 'NR > 1 && $1 ~ /^sfi-walkthrough-/ { print $2 }' \
    | while IFS= read -r city_path; do
        [ -n "$city_path" ] || continue
        echo "unregister $city_path"
        gc unregister "$city_path" >/dev/null 2>&1 || true
      done
fi

walk_pids="$(
  ps -axo pid=,command= \
    | awk '
        index($0, " awk ") > 0 { next }
        index($0, "sfi-tutorial-walkthrough") > 0 ||
        index($0, "sfi-walkthrough-") > 0 {
          print $1
        }
      ' \
    | sort -u
)"

hook_pids=""
if [ "$kill_hooks" -eq 1 ]; then
  hook_pids="$(
    ps -axo pid=,command= \
      | awk '
          index($0, " awk ") > 0 { next }
          index($0, ".githooks/pre-commit") > 0 ||
          index($0, "test-harness/behavioral-smoke.sh") > 0 ||
          index($0, "test-harness/tutorial-walkthrough.sh") > 0 {
            print $1
          }
        ' \
      | sort -u
  )"
fi

all_pids="$(printf '%s\n%s\n' "$walk_pids" "$hook_pids" | awk 'NF' | sort -u)"

echo
echo "== killing test-owned processes =="
if [ -n "$all_pids" ]; then
  printf '%s\n' "$all_pids" | while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    echo "kill $pid"
    kill "$pid" >/dev/null 2>&1 || true
  done
  sleep 2
  printf '%s\n' "$all_pids" | while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    if kill -0 "$pid" >/dev/null 2>&1; then
      echo "kill -9 $pid"
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  done
else
  echo "none"
fi

echo
echo "== final status =="
if command -v gc >/dev/null 2>&1; then
  gc cities 2>/dev/null | awk 'NR == 1 || $1 ~ /^sfi-walkthrough-/' || true
fi
ps -axo pid,ppid,etime,state,command \
  | awk '
      NR == 1 { print; next }
      index($0, " awk ") > 0 { next }
      index($0, "sfi-tutorial-walkthrough") > 0 ||
      index($0, "sfi-walkthrough-") > 0 ||
      index($0, "test-harness/tutorial-walkthrough.sh") > 0 ||
      index($0, "test-harness/behavioral-smoke.sh") > 0 ||
      index($0, ".githooks/pre-commit") > 0 { print }
    ' || true
