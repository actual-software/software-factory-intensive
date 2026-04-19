#!/usr/bin/env bash
# sync-actual-skill.sh
#
# Re-vendor the upstream actual-software/actual-skill into this pack's
# overlay so the architect agent ships with the latest SKILL.md,
# references, and scripts.
#
# This is an author/maintainer tool. End users do NOT need to run it —
# the vendored skill is checked into the gascity repo. Run it when
# upstream releases a new version.
#
# Usage: ./scripts/sync-actual-skill.sh [UPSTREAM_REF]
set -euo pipefail

UPSTREAM_REF="${1:-main}"
UPSTREAM_REPO="https://github.com/actual-software/actual-skill.git"

pack_dir="$(cd "$(dirname "$0")/.." && pwd)"
overlay_skill_dir="$pack_dir/overlays/default/.claude/skills/actual"
tmp_dir="$(mktemp -d -t actual-skill-vendor.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "── sync-actual-skill ──────────────────────────────────────────"
echo "pack:     $pack_dir"
echo "overlay:  $overlay_skill_dir"
echo "upstream: $UPSTREAM_REPO @ $UPSTREAM_REF"
echo

git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO" "$tmp_dir/repo"

if [ ! -d "$tmp_dir/repo/skills/actual" ]; then
    echo "error: upstream has no skills/actual/ tree — schema changed?" >&2
    exit 1
fi

mkdir -p "$overlay_skill_dir"
rsync -a --delete \
    --exclude '.git' \
    "$tmp_dir/repo/skills/actual/" "$overlay_skill_dir/"

echo
echo "ok — vendored skill updated."
echo "review the diff with: git diff -- $overlay_skill_dir"
