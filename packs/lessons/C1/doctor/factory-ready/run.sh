#!/usr/bin/env bash
set -euo pipefail

missing=0
for role in planner architect designer builder validator reviewer release-gate; do
  if [ ! -f "$GC_PACK_DIR/agents/$role/agent.toml" ]; then
    echo "missing agents/$role/agent.toml"
    missing=1
  fi
  if [ ! -f "$GC_PACK_DIR/agents/$role/prompt.template.md" ]; then
    echo "missing agents/$role/prompt.template.md"
    missing=1
  fi
done

if [ ! -f "$GC_PACK_DIR/formulas/mol-release-delivery.toml" ]; then
  echo "missing formulas/mol-release-delivery.toml"
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "release-delivery factory ready"
