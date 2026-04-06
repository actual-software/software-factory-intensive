#!/usr/bin/env bash
# Doctor check: verify GitHub token and connectivity.
set -euo pipefail

token="${GITHUB_TOKEN:-${GITHUB_PERSONAL_ACCESS_TOKEN:-}}"
if [ -z "$token" ]; then
    echo "GITHUB_TOKEN not set"
    echo "Set it in .env or export GITHUB_TOKEN=ghp_..."
    exit 1
fi

user=$(curl -sf -H "Authorization: token $token" \
    "https://api.github.com/user" 2>/dev/null | jq -r '.login // empty')

if [ -z "$user" ]; then
    echo "GITHUB_TOKEN invalid or expired"
    echo "Generate a new token at https://github.com/settings/tokens"
    exit 2
fi

echo "authenticated as $user"
exit 0
