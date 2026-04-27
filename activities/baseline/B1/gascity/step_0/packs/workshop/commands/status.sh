#!/usr/bin/env bash
# Show integration connection status for the workshop pack.
set -euo pipefail

green="\033[32m" yellow="\033[33m" red="\033[31m" dim="\033[2m" reset="\033[0m"

check() {
    local name="$1" var="$2"
    local val="${!var:-}"
    if [ -n "$val" ]; then
        printf "  ${green}●${reset} %-16s configured\n" "$name"
    else
        printf "  ${dim}○${reset} %-16s ${dim}not configured${reset}\n" "$name"
    fi
}

echo "Issue Trackers"
check "Jira"       "JIRA_API_TOKEN"
check "Linear"     "LINEAR_API_KEY"
check "GitHub"     "GITHUB_TOKEN"
check "GitLab"     "GITLAB_TOKEN"
check "Azure DevOps" "AZURE_DEVOPS_PAT"
check "Notion"     "NOTION_TOKEN"
check "Asana"      "ASANA_ACCESS_TOKEN"

echo ""
echo "Observability"
check "Sentry"     "SENTRY_AUTH_TOKEN"
check "DataDog"    "DATADOG_API_KEY"
check "PostHog"    "POSTHOG_API_KEY"
check "Grafana"    "GRAFANA_API_KEY"
check "OTel Metrics" "GC_OTEL_METRICS_URL"

echo ""
echo "Cloud Providers"
for cmd in aws gcloud az; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf "  ${green}●${reset} %-16s installed\n" "$cmd"
    else
        printf "  ${dim}○${reset} %-16s ${dim}not installed${reset}\n" "$cmd"
    fi
done

echo ""
echo "Communication"
check "Slack"      "SLACK_BOT_TOKEN"
check "Discord"    "DISCORD_BOT_TOKEN"

echo ""
echo "CI/CD"
check "CircleCI"   "CIRCLECI_TOKEN"

echo ""
echo "Run 'gc doctor' for detailed connectivity checks."
