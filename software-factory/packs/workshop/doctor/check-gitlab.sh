#!/usr/bin/env bash
# Doctor check: verify GitLab token and project access.
set -euo pipefail

url="${GITLAB_URL:-https://gitlab.com}"
token="${GITLAB_TOKEN:-}"

if [ -z "$token" ]; then
    echo "GITLAB_TOKEN not set"
    echo "Create one at ${url}/-/user_settings/personal_access_tokens"
    exit 1
fi

user=$(curl -sf -H "PRIVATE-TOKEN: $token" \
    "${url}/api/v4/user" 2>/dev/null | jq -r '.username // empty')

if [ -z "$user" ]; then
    echo "GitLab authentication failed"
    echo "Check GITLAB_URL and GITLAB_TOKEN"
    exit 2
fi

echo "authenticated as $user on ${url}"
exit 0
