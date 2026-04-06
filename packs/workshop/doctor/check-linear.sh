#!/usr/bin/env bash
# Doctor check: verify Linear API key and team access.
set -euo pipefail

key="${LINEAR_API_KEY:-}"
if [ -z "$key" ]; then
    echo "LINEAR_API_KEY not set"
    echo "Get one at https://linear.app/settings/api"
    exit 1
fi

resp=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: $key" \
    -d '{"query":"{ viewer { name email } }"}' \
    "https://api.linear.app/graphql" 2>/dev/null || echo "")

name=$(echo "$resp" | jq -r '.data.viewer.name // empty' 2>/dev/null)

if [ -z "$name" ]; then
    echo "Linear authentication failed"
    echo "Check LINEAR_API_KEY"
    exit 2
fi

echo "authenticated as $name"
exit 0
