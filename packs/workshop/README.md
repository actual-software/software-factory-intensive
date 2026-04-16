# Workshop Integrations Pack

Gas City pack that pre-configures external service integrations for the Software Factory Intensive workshop. Participants include this pack in their city to get issue tracker sync, observability, cloud access, and MCP tool integrations with a single command.

## Quick Start

```bash
# 1. Copy env template and fill in your credentials
cp packs/workshop/env.example .env
# Edit .env with your tokens

# 2. Add the workshop pack to your city's includes.
#    In the Software Factory Intensive curriculum, that's my-factory/city.toml:
#      includes = [..., "../packs/workshop"]
cd my-factory
gc service restart

# 3. Run setup to write credentials into beads config
gc workshop setup

# 4. Validate everything works
gc doctor

# 5. Sync your issue tracker
gc workshop sync-all
```

## What's Included

### Issue Tracker Sync (via bd)

Native bidirectional sync with automatic periodic orders (every 5 min):

| Service | Config Prefix | Sync Command | Order |
|---------|--------------|--------------|-------|
| Jira Cloud | `JIRA_*` | `bd jira sync` | `sync-jira` |
| Linear | `LINEAR_*` | `bd linear sync` | `sync-linear` |
| GitHub Issues | `GITHUB_*` | `bd github sync` | `sync-github` |
| GitLab Issues | `GITLAB_*` | `bd gitlab sync` | `sync-gitlab` |
| Azure DevOps | `AZURE_DEVOPS_*` | `bd ado sync` | -- |
| Notion | `NOTION_*` | `bd notion sync` | -- |

### Observability (via MCP + OTel)

Agents get direct tool access to query dashboards, errors, and analytics:

| Service | Config Prefix | Access Method |
|---------|--------------|---------------|
| Sentry | `SENTRY_*` | MCP server (`@sentry/mcp-server`) |
| DataDog | `DATADOG_*` | MCP server (`@anthropic/mcp-server-datadog`) |
| PostHog | `POSTHOG_*` | MCP server (`@nichochar/posthog-mcp`) |
| Grafana | `GRAFANA_*` | MCP server (`@anthropic/mcp-server-grafana`) |
| Prometheus | `PROMETHEUS_*` | OTel push gateway |
| VictoriaMetrics | `GC_OTEL_*` | Gas City native OTel export |

### Cloud Providers

Validated via CLI authentication:

| Provider | CLI | Auth Command |
|----------|-----|-------------|
| AWS | `aws` | `aws configure` or `AWS_PROFILE` |
| Google Cloud | `gcloud` | `gcloud auth login` |
| Azure | `az` | `az login` |

### Communication (via MCP)

| Service | Config Prefix | Access Method |
|---------|--------------|---------------|
| Slack | `SLACK_*` | MCP server (`@anthropic/mcp-server-slack`) |
| Discord | `DISCORD_*` | env var |

### Source Control (via MCP + CLI)

| Service | Config Prefix | Access Method |
|---------|--------------|---------------|
| GitHub | `GITHUB_*` | MCP server + `gh` CLI + bd sync |
| GitLab | `GITLAB_*` | MCP server + bd sync |

## Doctor Checks

Run `gc doctor` to validate all configured integrations:

```
  ✓ check-core-tools    — all core tools present
  ✓ check-github        — authenticated as octocat
  ✓ check-jira          — authenticated as user@company.com (project: PROJ)
  ⚠ check-linear        — LINEAR_API_KEY not set
  ⚠ check-observability — no observability services configured (optional)
  ⚠ check-cloud         — no cloud CLIs authenticated (optional)
```

Only `check-core-tools` is required. All other checks are informational -- configure only the integrations your project needs.

## CLI Commands

```bash
gc workshop status     # Show which integrations are configured
gc workshop setup      # Write env vars into bd config
gc workshop sync-all   # Run all configured issue tracker syncs
```

## Pack Structure

```
packs/workshop/
├── pack.toml                          # Pack metadata + doctor + commands
├── env.example                        # Credential template
├── README.md                          # This file
├── doctor/
│   ├── check-core-tools.sh           # gc, bd, dolt, tmux, jq, git, curl
│   ├── check-github.sh               # GitHub token validation
│   ├── check-jira.sh                 # Jira auth + project access
│   ├── check-linear.sh               # Linear API key validation
│   ├── check-gitlab.sh               # GitLab token validation
│   ├── check-observability.sh        # Sentry, DataDog, PostHog, Grafana, OTel
│   └── check-cloud.sh               # AWS, GCP, Azure CLI auth
├── orders/
│   ├── sync-jira/order.toml          # 5-min Jira sync
│   ├── sync-linear/order.toml        # 5-min Linear sync
│   ├── sync-github/order.toml        # 5-min GitHub sync
│   └── sync-gitlab/order.toml        # 5-min GitLab sync
├── commands/
│   ├── status.sh                     # Integration status dashboard
│   ├── setup.sh                      # Write env vars to bd config
│   └── sync-all.sh                   # Run all configured syncs
└── overlays/
    └── default/
        └── .claude/
            └── settings.json         # MCP servers for agent tool access
```

## Adding More Integrations

To add a new integration:

1. Add env vars to `env.example`
2. Add a doctor check in `doctor/check-<name>.sh`
3. If it has bd support, add an order in `orders/sync-<name>/order.toml`
4. If it has an MCP server, add it to `overlays/default/.claude/settings.json`
5. Update `commands/setup.sh` and `commands/status.sh`
