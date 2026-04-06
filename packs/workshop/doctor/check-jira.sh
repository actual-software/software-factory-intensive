#!/usr/bin/env bash
# Doctor check: verify Jira credentials and project access.
set -euo pipefail

url="${JIRA_URL:-}"
user="${JIRA_USERNAME:-}"
token="${JIRA_API_TOKEN:-}"
project="${JIRA_PROJECT:-}"

if [ -z "$url" ] || [ -z "$token" ]; then
    echo "Jira not configured (JIRA_URL or JIRA_API_TOKEN missing)"
    echo "Set credentials in .env — see env.example"
    exit 1
fi

resp=$(curl -sf -u "${user}:${token}" \
    -H "Accept: application/json" \
    "${url}/rest/api/3/myself" 2>/dev/null || echo "")

if [ -z "$resp" ]; then
    echo "Jira authentication failed"
    echo "Check JIRA_URL, JIRA_USERNAME, and JIRA_API_TOKEN"
    exit 2
fi

name=$(echo "$resp" | jq -r '.displayName // .emailAddress // "unknown"')

if [ -n "$project" ]; then
    proj_resp=$(curl -sf -u "${user}:${token}" \
        -H "Accept: application/json" \
        "${url}/rest/api/3/project/${project}" 2>/dev/null || echo "")
    if [ -z "$proj_resp" ]; then
        echo "authenticated as $name but project $project not accessible"
        exit 1
    fi
fi

echo "authenticated as $name (project: ${project:-not set})"
exit 0
