#!/bin/sh
# wake-downstream.sh — Check if any labelled beads just became ready
# and sling them to the appropriate agent.
#
# Called from each agent's formula handoff step after bd close.
# Runs in the background to avoid blocking the closing agent.
#
# Usage: wake-downstream.sh
#   Must be run from the rig root directory.

set -e

GC_BIN="${GC_BIN:-gc}"

wake_agent() {
  local label="$1" agent="$2"
  local bead_id
  bead_id=$(bd ready --label="$label" --limit=1 --json 2>/dev/null \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4) || true
  if [ -n "$bead_id" ]; then
    "$GC_BIN" sling "$agent" "$bead_id" --nudge >/dev/null 2>&1 || true
  fi
}

wake_agent needs-architecture architect
wake_agent needs-plan planner
wake_agent needs-design designer
wake_agent needs-tests validator
wake_agent ready-to-build builder
wake_agent needs-review reviewer
wake_agent ready-to-ship release-gate
