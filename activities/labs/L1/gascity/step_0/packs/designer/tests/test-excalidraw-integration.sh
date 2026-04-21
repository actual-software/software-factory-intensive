#!/usr/bin/env bash
set -euo pipefail
PACK="activities/workshops/W1/gascity/step_0/packs/designer"
FAIL=0

run() {
  if eval "$2" > /dev/null 2>&1; then echo "[PASS] $1"; else echo "[FAIL] $1"; FAIL=1; fi
}

run "mcpServers.excalidraw present in .mcp.json" \
  "jq -e '.mcpServers.excalidraw' '$PACK/overlays/default/.mcp.json'"

run "excalidraw-export allowed in permissions" \
  "jq -e '[.permissions.allow[] | select(contains(\"excalidraw-export\"))] | length > 0' '$PACK/overlays/default/.claude/settings.json'"

run "excalidraw-diagrams skill exists" \
  "test -f '$PACK/overlays/default/.claude/skills/excalidraw-diagrams/SKILL.md'"

run "skill documents mcp__excalidraw__ tools" \
  "grep -q 'mcp__excalidraw__' '$PACK/overlays/default/.claude/skills/excalidraw-diagrams/SKILL.md'"

run "prompt has no ASCII sketch template" \
  "! grep -q 'ASCII sketch' '$PACK/prompts/designer.md.tmpl'"

run "prompt references excalidraw" \
  "grep -qi 'excalidraw' '$PACK/prompts/designer.md.tmpl'"

run "prompt references .excalidraw file output" \
  "grep -q '\.excalidraw' '$PACK/prompts/designer.md.tmpl'"

run "formula wireframe step references excalidraw" \
  "grep -qi 'excalidraw' '$PACK/formulas/mol-design-cycle.formula.toml'"

run "formula wireframe step has no ASCII art box template" \
  "! grep -q '+----' '$PACK/formulas/mol-design-cycle.formula.toml'"

run "prerequisites doc exists" \
  "test -f '$PACK/docs/excalidraw-prerequisites.md'"

run "doctor script checks excalidraw-mcp binary" \
  "grep -q 'excalidraw-mcp' '$PACK/doctor/check-designer.sh'"

[ $FAIL -eq 0 ] && echo "ALL TESTS PASSED" || { echo "TESTS FAILED"; exit 1; }
