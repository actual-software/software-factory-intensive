#!/usr/bin/env bash
# migration-check.sh — structural invariants for the pack v1→v2 migration.
#
# Exits 0 if every invariant holds against packs that have been migrated
# (schema = 2 in pack.toml). Packs still at schema = 1 are skipped — they
# haven't migrated yet. Run this after every per-pack slice per the plan's
# Principle 3 + 5.
#
# Invariants apply to active packs under:
#   - packs/
#
# Exit codes:
#   0 — all invariants pass
#   1 — one or more invariants failed; see stderr

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

FAILED=0
fail() {
  echo "FAIL: $*" >&2
  FAILED=$((FAILED + 1))
}

# Enumerate every active pack.toml.
PACK_TOMLS=()
while IFS= read -r pack_toml; do
  PACK_TOMLS+=("$pack_toml")
done < <(find packs -name pack.toml 2>/dev/null | sort)

MIGRATED_PACK_DIRS=()
for pt in "${PACK_TOMLS[@]}"; do
  if grep -q '^schema = 2' "$pt"; then
    MIGRATED_PACK_DIRS+=("$(dirname "$pt")")
  fi
done

echo "== migration-check =="
echo "Found ${#PACK_TOMLS[@]} pack.toml files total."
echo "Migrated (schema=2): ${#MIGRATED_PACK_DIRS[@]}"
echo

# --- Invariant 1: migrated pack.toml contains no v1 inline blocks ---
echo "[1] no v1 blocks in migrated pack.toml files"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  pt="$pack_dir/pack.toml"
  # Match any of: [[agent]], [[commands]], [[doctor]], top-level overlay_dir/prompt_template,
  # schema = 1, or the legacy [formulas] dir=... block.
  if grep -Eq '^\[\[agent\]\]|^\[\[commands\]\]|^\[\[doctor\]\]|^overlay_dir|^prompt_template|^schema = 1|^\[formulas\]' "$pt"; then
    fail "$pt contains v1 block(s)"
  fi
done

# --- Invariant 2: migrated agent-bearing packs have required v2 agent structure ---
echo "[2] migrated agent-bearing packs have agents/<n>/{agent.toml, prompt*.md}"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  [ -d "$pack_dir/agents" ] || continue
  for agent_dir in "$pack_dir"/agents/*/; do
    [ -d "$agent_dir" ] || continue
    [ -f "$agent_dir/agent.toml" ] || fail "$agent_dir missing agent.toml"
    # Accept either prompt.template.md or prompt.md (plain) per v2 convention.
    if [ ! -f "$agent_dir/prompt.template.md" ] && [ ! -f "$agent_dir/prompt.md" ]; then
      fail "$agent_dir missing prompt.template.md or prompt.md"
    fi
  done
done

# --- Invariant 3: migrated packs have no v1 directory artifacts ---
# prompts/, overlays/, scripts/, formulas/orders/ are all v1-shaped; v2 uses
# agents/<n>/, assets/, commands/, doctor/, orders/ (flat).
echo "[3] migrated packs have no v1 prompts/|overlays/|scripts/|formulas/orders/ dirs"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  for stale in prompts overlays scripts formulas/orders; do
    if [ -e "$pack_dir/$stale" ]; then
      fail "$pack_dir/$stale still exists (v1 artifact)"
    fi
  done
done

# --- Invariant 4: every commands/<n>/ has run.sh + command.toml sidecar ---
# Applies only to migrated packs. Unmigrated v1 packs have commands/*.sh (file, not dir).
echo "[4] migrated packs' commands/<n>/ dirs have run.sh + command.toml"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  [ -d "$pack_dir/commands" ] || continue
  for cmd_dir in "$pack_dir"/commands/*/; do
    [ -d "$cmd_dir" ] || continue
    [ -f "$cmd_dir/run.sh" ]      || fail "$cmd_dir missing run.sh"
    [ -f "$cmd_dir/command.toml" ] || fail "$cmd_dir missing command.toml"
  done
  # No bare commands/<n>.sh files remain in migrated packs.
  if find "$pack_dir/commands" -maxdepth 1 -name '*.sh' -type f 2>/dev/null | grep -q .; then
    fail "$pack_dir/commands/ has bare *.sh files (should be in <n>/run.sh)"
  fi
done

# --- Invariant 5: every doctor/<n>/ has run.sh + doctor.toml sidecar ---
echo "[5] migrated packs' doctor/<n>/ dirs have run.sh + doctor.toml"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  [ -d "$pack_dir/doctor" ] || continue
  for doc_dir in "$pack_dir"/doctor/*/; do
    [ -d "$doc_dir" ] || continue
    [ -f "$doc_dir/run.sh" ]     || fail "$doc_dir missing run.sh"
    [ -f "$doc_dir/doctor.toml" ] || fail "$doc_dir missing doctor.toml"
  done
  if find "$pack_dir/doctor" -maxdepth 1 -name '*.sh' -type f 2>/dev/null | grep -q .; then
    fail "$pack_dir/doctor/ has bare *.sh files (should be in <n>/run.sh)"
  fi
done

# --- Invariant 6: migrated formulas use .toml not .formula.toml ---
echo "[6] migrated packs' formulas/ have no .formula.toml files"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  if find "$pack_dir/formulas" -name '*.formula.toml' -type f 2>/dev/null | grep -q .; then
    fail "$pack_dir/formulas/ has .formula.toml files (rename to .toml)"
  fi
done

# --- Invariant 7: migrated orders are flat .toml files, not nested <n>/order.toml ---
echo "[7] migrated packs' orders/ have no nested <n>/order.toml shape"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  if find "$pack_dir/orders" -mindepth 2 -name 'order.toml' 2>/dev/null | grep -q .; then
    fail "$pack_dir/orders/ has nested <n>/order.toml (flatten to <n>.toml)"
  fi
done

# --- Invariant 8: no stale repository-wide v1 paths ---
# These should be gone from ALL migrated content (formulas, READMEs, curriculum docs
# that reference migrated packs). Unmigrated packs may still have them.
echo "[8] no stale v1 paths in migrated packs"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  # packs/actual/all/ — v1 rsync-install artifact
  if grep -rq 'packs/actual/all' "$pack_dir" 2>/dev/null; then
    fail "$pack_dir references stale packs/actual/all/ path"
  fi
  # overlays/default/ — v1 agent overlay path; v2 uses agents/<n>/overlay/
  if grep -rq 'overlays/default' "$pack_dir" 2>/dev/null; then
    fail "$pack_dir references v1 overlays/default/ path"
  fi
done

# --- Invariant 9: {{.CityRoot}} is NOT used in formula step bodies ---
# The formula parser's {{name}} syntax doesn't do Go text/template — {{.CityRoot}}
# ships literally to the shell. Use $GC_CITY_PATH or pack commands instead.
echo "[9] no {{.CityRoot}} in migrated formula files"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  if grep -rq '{{\s*\.CityRoot\s*}}' "$pack_dir" 2>/dev/null; then
    fail "$pack_dir uses {{.CityRoot}} (see workshop:#785 — use \$GC_CITY_PATH or pack command)"
  fi
done

# --- Invariant 10: no "Option D" $PACK_DIR references in formula step bodies ---
# $PACK_DIR / $GC_PACK_DIR are NOT available in agent session shells
# (workshop:#785). Formula step bodies that use them will produce empty-
# string expansion at runtime.
echo "[10] no \$PACK_DIR / \$GC_PACK_DIR in migrated formula step bodies"
for pack_dir in "${MIGRATED_PACK_DIRS[@]}"; do
  [ -d "$pack_dir/formulas" ] || continue
  if grep -rEq '\$\{?PACK_DIR|\$\{?GC_PACK_DIR' "$pack_dir/formulas" 2>/dev/null; then
    fail "$pack_dir/formulas/ references \$PACK_DIR or \$GC_PACK_DIR (not in agent session env — workshop:#785)"
  fi
done

# --- Summary ---
echo
if [ "$FAILED" -eq 0 ]; then
  echo "✓ all structural invariants pass (${#MIGRATED_PACK_DIRS[@]} migrated packs checked)"
  exit 0
else
  echo "✗ $FAILED structural invariant(s) failed" >&2
  exit 1
fi
