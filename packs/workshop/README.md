# Workshop Integrations Pack

Gas City pack that pre-configures external service integrations for the Software Factory Intensive workshop. Participants include this pack in their city to get issue tracker sync, observability, cloud access, and MCP tool integrations with a single command.

## Quick Start

```bash
# 1. Copy env template and fill in your credentials
cp packs/workshop/env.example .env
# Edit .env with your tokens

# 2. The workshop pack is already wired into my-factory/pack.toml.template
#    via a workspace-scope import ([imports.workshop] source = "../packs/workshop"),
#    so its commands surface as `gc workshop ...` once you've copied the template.
cd my-factory
gc restart

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
| GitLab | `GITLAB_*` | bd sync only |

## Doctor Checks

Run `gc doctor` to validate all configured integrations:

```
  ✓ workshop:check-core-tools    — all core tools present
  ✓ workshop:check-github        — authenticated as octocat
  ✓ workshop:check-jira          — authenticated as user@company.com (project: PROJ)
  ⚠ workshop:check-linear        — LINEAR_API_KEY not set
  ⚠ workshop:check-observability — no observability services configured (optional)
  ⚠ workshop:check-cloud         — no cloud CLIs authenticated (optional)
```

Checks are pack-prefixed in real `gc doctor` output. Only `workshop:check-core-tools` is required. All other checks are informational — configure only the integrations your project needs.

## CLI Commands

```bash
gc workshop status     # Show which integrations are configured
gc workshop setup      # Write env vars into bd config
gc workshop sync-all   # Run all configured issue tracker syncs
```

## Pack Structure

```
packs/workshop/
├── pack.toml                          # Pack metadata (schema = 2)
├── env.example                        # Credential template
├── README.md                          # This file
├── commands/
│   ├── setup/{command.toml,run.sh}        # Write env vars to bd config
│   ├── status/{command.toml,run.sh}       # Integration status dashboard
│   └── sync-all/{command.toml,run.sh}     # Run all configured syncs
├── doctor/
│   ├── check-cloud/{doctor.toml,run.sh}          # AWS, GCP, Azure CLI auth
│   ├── check-core-tools/{doctor.toml,run.sh}     # gc, bd, dolt, tmux, jq, git, curl
│   ├── check-github/{doctor.toml,run.sh}         # GitHub token validation
│   ├── check-gitlab/{doctor.toml,run.sh}         # GitLab token validation
│   ├── check-jira/{doctor.toml,run.sh}           # Jira auth + project access
│   ├── check-linear/{doctor.toml,run.sh}         # Linear API key validation
│   └── check-observability/{doctor.toml,run.sh}  # Sentry, DataDog, PostHog, Grafana, OTel
├── orders/
│   ├── sync-github.toml               # 5-min GitHub sync
│   ├── sync-gitlab.toml               # 5-min GitLab sync
│   ├── sync-jira.toml                 # 5-min Jira sync
│   └── sync-linear.toml               # 5-min Linear sync
└── overlay/
    └── .claude/
        └── settings.json              # MCP servers for agent tool access
```

## Adding More Integrations

To add a new integration:

1. Add env vars to `env.example`
2. Add a doctor check in `doctor/check-<name>/run.sh` + `doctor/check-<name>/doctor.toml`
3. If it has bd support, add an order in `orders/sync-<name>.toml`
4. If it has an MCP server, add it to `overlay/.claude/settings.json`
5. Update `commands/setup/run.sh` and `commands/status/run.sh`
