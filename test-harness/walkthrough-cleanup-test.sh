#!/usr/bin/env bash
# walkthrough-cleanup-test.sh - unit checks for per-lesson cleanup ownership.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp_root="$(mktemp -d /tmp/sfi-walkthrough-cleanup-test.XXXXXX)"
trap 'rm -rf "$tmp_root"' EXIT

fake_bin="$tmp_root/bin"
mkdir -p "$fake_bin"

cat > "$fake_bin/gc" <<'GC'
#!/usr/bin/env bash
set -euo pipefail
log="${GC_FAKE_LOG:?}"
case "${1:-}" in
  register)
    shift
    city_name=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --name) city_name="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    printf "register:%s:%s\n" "$city_name" "$PWD" >> "$log"
    printf "Registered city '%s' (%s)\n" "$city_name" "$PWD"
    ;;
  stop)
    printf "stop:%s\n" "$PWD" >> "$log"
    ;;
  unregister)
    printf "unregister:%s\n" "${2:-}" >> "$log"
    ;;
  supervisor)
    if [ "${2:-}" = "reload" ]; then
      printf "supervisor-reload\n" >> "$log"
    fi
    ;;
  cities)
    printf "NAME PATH\n"
    ;;
  *)
    printf "gc %s\n" "$*" >> "$log"
    ;;
esac
GC
chmod +x "$fake_bin/gc"

export PATH="$fake_bin:$PATH"
export GC_FAKE_LOG="$tmp_root/gc.log"
export WALK_REPO_ROOT="$repo_root"
export WALK_SCRATCH="$tmp_root/scratch"
export WALK_DIVERGENCES="$tmp_root/divergences.log"
export WALK_STATE_ENV="$tmp_root/state.env"
export WALK_DRY_RUN=1
export WALK_LESSON_NAME=TEST
mkdir -p "$WALK_SCRATCH"
: > "$WALK_DIVERGENCES"
: > "$WALK_STATE_ENV"
: > "$GC_FAKE_LOG"

# shellcheck source=walkthroughs/_common.sh
source "$repo_root/test-harness/walkthroughs/_common.sh"

factory="$tmp_root/factory"
mkdir -p "$factory"

register_walkthrough_city "$factory" "sfi-walkthrough-TEST" "TEST" >/dev/null
lesson_cleanup
lesson_cleanup

unregister_count="$(grep -c "^unregister:$factory$" "$GC_FAKE_LOG" || true)"
if [ "$unregister_count" -ne 1 ]; then
  echo "expected exactly one unregister for $factory, got $unregister_count" >&2
  cat "$GC_FAKE_LOG" >&2
  exit 1
fi

echo "✓ per-lesson cleanup unregisters registered city exactly once"
