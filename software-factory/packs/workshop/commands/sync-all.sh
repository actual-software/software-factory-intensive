#!/usr/bin/env bash
# Run all configured issue tracker syncs.
set -euo pipefail

synced=0

# Check which integrations are configured and sync each
if bd config get jira.url 2>/dev/null | grep -qv "(not set)"; then
    echo "Syncing Jira..."
    bd jira sync --pull && synced=$((synced + 1)) || echo "  Jira sync failed"
fi

if bd config get linear.api_key 2>/dev/null | grep -qv "(not set)"; then
    echo "Syncing Linear..."
    bd linear sync --pull && synced=$((synced + 1)) || echo "  Linear sync failed"
fi

if bd config get github.token 2>/dev/null | grep -qv "(not set)"; then
    echo "Syncing GitHub..."
    bd github sync && synced=$((synced + 1)) || echo "  GitHub sync failed"
fi

if bd config get gitlab.token 2>/dev/null | grep -qv "(not set)"; then
    echo "Syncing GitLab..."
    bd gitlab sync && synced=$((synced + 1)) || echo "  GitLab sync failed"
fi

if bd config get ado.pat 2>/dev/null | grep -qv "(not set)"; then
    echo "Syncing Azure DevOps..."
    bd ado sync && synced=$((synced + 1)) || echo "  Azure DevOps sync failed"
fi

echo ""
if [ $synced -eq 0 ]; then
    echo "No integrations synced. Run 'gc workshop setup' first."
else
    echo "$synced integration(s) synced successfully."
    echo ""
    bd list | head -20
fi
