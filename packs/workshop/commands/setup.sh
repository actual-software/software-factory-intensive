#!/usr/bin/env bash
# Interactive setup wizard: configure bd integrations from env vars.
# Reads from .env (if present) and writes to bd config.
set -euo pipefail

PACK_DIR="${GC_PACK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "Software Factory Intensive — Integration Setup"
echo "================================================"
echo ""

# Source .env if present
if [ -f ".env" ]; then
    echo "Loading .env..."
    set -a; source .env; set +a
elif [ -f "$PACK_DIR/../../.env" ]; then
    echo "Loading .env from repo root..."
    set -a; source "$PACK_DIR/../../.env"; set +a
fi

configured=0

# Jira
if [ -n "${JIRA_API_TOKEN:-}" ] && [ -n "${JIRA_URL:-}" ]; then
    echo "Configuring Jira..."
    bd config set jira.url "$JIRA_URL"
    bd config set jira.username "${JIRA_USERNAME:-}"
    bd config set jira.api_token "$JIRA_API_TOKEN"
    [ -n "${JIRA_PROJECT:-}" ] && bd config set jira.project "$JIRA_PROJECT"
    configured=$((configured + 1))
fi

# Linear
if [ -n "${LINEAR_API_KEY:-}" ]; then
    echo "Configuring Linear..."
    bd config set linear.api_key "$LINEAR_API_KEY"
    [ -n "${LINEAR_TEAM_ID:-}" ] && bd config set linear.team_id "$LINEAR_TEAM_ID"
    configured=$((configured + 1))
fi

# GitHub
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "Configuring GitHub..."
    bd config set github.token "$GITHUB_TOKEN"
    [ -n "${GITHUB_OWNER:-}" ] && bd config set github.owner "$GITHUB_OWNER"
    [ -n "${GITHUB_REPO:-}" ] && bd config set github.repo "$GITHUB_REPO"
    configured=$((configured + 1))
fi

# GitLab
if [ -n "${GITLAB_TOKEN:-}" ]; then
    echo "Configuring GitLab..."
    bd config set gitlab.url "${GITLAB_URL:-https://gitlab.com}"
    bd config set gitlab.token "$GITLAB_TOKEN"
    [ -n "${GITLAB_PROJECT_ID:-}" ] && bd config set gitlab.project_id "$GITLAB_PROJECT_ID"
    configured=$((configured + 1))
fi

# Azure DevOps
if [ -n "${AZURE_DEVOPS_PAT:-}" ]; then
    echo "Configuring Azure DevOps..."
    bd config set ado.pat "$AZURE_DEVOPS_PAT"
    [ -n "${AZURE_DEVOPS_ORG:-}" ] && bd config set ado.org "$AZURE_DEVOPS_ORG"
    [ -n "${AZURE_DEVOPS_PROJECT:-}" ] && bd config set ado.project "$AZURE_DEVOPS_PROJECT"
    configured=$((configured + 1))
fi

echo ""
if [ $configured -eq 0 ]; then
    echo "No integrations configured."
    echo "Copy packs/workshop/env.example to .env, fill in your credentials, and re-run."
else
    echo "$configured integration(s) configured."
    echo "Run 'gc doctor' to validate, then 'gc workshop sync-all' to sync."
fi
