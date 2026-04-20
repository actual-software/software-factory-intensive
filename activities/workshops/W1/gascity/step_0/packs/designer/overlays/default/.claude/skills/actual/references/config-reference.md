# Config Reference

All configuration keys, defaults, validation rules, and dotpath syntax. Load this when configuring the actual CLI.

## Table of Contents

- [Config File Location](#config-file-location)
- [All Config Keys](#all-config-keys)
- [Key Details](#key-details)
- [Dotpath Syntax](#dotpath-syntax)
- [Environment Variable Overrides](#environment-variable-overrides)
- [File Permissions](#file-permissions)

## Config File Location

**Default**: `~/.actualai/actual/config.yaml`

Override with environment variables:

| Env Var | Purpose | Notes |
|---------|---------|-------|
| `ACTUAL_CONFIG` | Exact path to config file | Takes precedence over everything |
| `ACTUAL_CONFIG_DIR` | Directory containing config | Must be absolute path, no `..` components |

To find the active config path:
```bash
actual config path
```

## All Config Keys

| Key | Type | Default | Validation | Purpose |
|-----|------|---------|------------|---------|
| `api_url` | string | `https://api-service.api.prod.actual.ai` | URL format | API server URL |
| `model` | string | (none) | non-empty | Default model for ALL runners (runner is auto-inferred from model name) |
| `runner` | enum | claude-cli | One of: claude-cli, anthropic-api, openai-api, codex-cli, cursor-cli | AI runner backend |
| `batch_size` | u32 | 15 | min 1 | ADRs per API batch |
| `concurrency` | u32 | 10 | min 1 | Parallel API requests |
| `invocation_timeout_secs` | u64 | 600 | min 1 | Runner timeout in seconds |
| `max_budget_usd` | f64 | (none) | positive, finite | Spending cap for tailoring |
| `max_turns` | u32 | (none) | min 1 | Max conversation turns (claude-cli only) |
| `max_tokens` | u32 | (none) | min 1 | Max output tokens (anthropic-api only, default 16384) |
| `max_per_framework` | u32 | (none) | min 1 | Max ADRs per framework |
| `include_general` | bool | (none) | true/false | Include general (non-framework) ADRs |
| `include_categories` | string | (none) | comma-separated | Only include these ADR categories |
| `exclude_categories` | string | (none) | comma-separated | Exclude these ADR categories |
| `output_format` | enum | claude-md | One of: claude-md, agents-md, cursor-rules | Output file format |
| `anthropic_api_key` | string | (none) | non-empty | Anthropic API key |
| `openai_api_key` | string | (none) | non-empty | OpenAI API key |
| `cursor_api_key` | string | (none) | non-empty | Cursor API key |
| `telemetry.enabled` | bool | (none) | true/false | Enable/disable telemetry |

## Key Details

### Runner and Model Keys

The `model` key is the **unified model config key** for all runners. The runner is automatically inferred from the model name — setting `model: gpt-5` selects CodexCli, `model: claude-sonnet-4-6` selects AnthropicApi, etc.

**Model validation** checks the merged model list: the static hardcoded list plus any models previously fetched from the OpenAI and Anthropic APIs (stored in the local model cache). This means models returned by `actual models` (live or cached) will not trigger spurious "unknown model" warnings when set via `config set model`.

The runner resolution order is:
1. `--model` CLI flag (infers runner from model name)
2. `model` config (infers runner from model name)
3. `runner` config or `--runner` flag
4. Default: claude-cli

### Numeric Keys

All numeric keys have a minimum of 1. Setting a value below the minimum results in a `ConfigError`.

- `batch_size`: Controls how many ADRs are fetched per API call. Higher values mean fewer round trips but larger payloads.
- `concurrency`: Controls how many API requests run in parallel. Higher values are faster but may hit rate limits.
- `invocation_timeout_secs`: How long to wait for the AI runner to respond per invocation. Increase this for slow models or large codebases.
- `max_budget_usd`: Must be positive and finite. Prevents runaway spending during tailoring.
- `max_turns`: Only used by claude-cli runner. Limits the number of conversation turns.
- `max_tokens`: Only used by anthropic-api runner. Controls the maximum number of output tokens per API call (default 16384). Increase this if responses are being truncated for large repositories with many ADRs.

### Category Filtering

`include_categories` and `exclude_categories` accept comma-separated category names:

```bash
actual config set include_categories "security,performance"
actual config set exclude_categories "testing"
```

These are mutually exclusive in practice: use one or the other to filter which ADR categories are synced.

### API Keys in Config

API keys set via `config set` are stored in the config YAML file. The file is created with 0600 permissions (owner read/write only) on Unix systems.

```bash
actual config set anthropic_api_key "sk-ant-..."
actual config set openai_api_key "sk-..."
actual config set cursor_api_key "..."
```

Environment variables (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `CURSOR_API_KEY`) take precedence over config file values.

## Dotpath Syntax

Config keys use dotpath notation for nested values:

```bash
# Top-level key
actual config set model claude-sonnet-4-6

# Nested key (uses dot separator)
actual config set telemetry.enabled false
```

### Get vs Set

```bash
# Show all config
actual config show

# Set a value
actual config set <key> <value>

# Show config file path
actual config path
```

There is no `config get <key>` subcommand. Use `config show` to view all values.

## Cache Management

The CLI caches analysis and tailoring results in `~/.actualai/actual/config.yaml` under the `cached_analysis` and `cached_tailoring` keys. These are managed automatically.

To clear the cache manually:

```bash
actual cache clear
```

This removes both `cached_analysis` and `cached_tailoring` entries from the config file. Other config values are preserved.

### Cache Behavior

| Property | Analysis cache | Tailoring cache |
|----------|---------------|-----------------|
| TTL | 7 days | 7 days |
| Max size | 10 MiB | 10 MiB |
| Key | git HEAD + config hash | ADR content hash + codebase hash |
| Bypass | `--force` flag | `--force` flag |

## Environment Variable Overrides

| Env Var | Overrides Config Key | Notes |
|---------|---------------------|-------|
| `ANTHROPIC_API_KEY` | `anthropic_api_key` | Takes precedence over config |
| `OPENAI_API_KEY` | `openai_api_key` | Takes precedence over config |
| `CURSOR_API_KEY` | `cursor_api_key` | Used by cursor-cli runner |
| `ACTUAL_CONFIG` | Config file path | Exact file path |
| `ACTUAL_CONFIG_DIR` | Config directory | Must be absolute, no `..` |

## File Permissions

On Unix systems, the config file is created with mode 0600 (owner read/write only). This protects API keys stored in the file.

If the config file exists with different permissions, the CLI does not change them. But new files are always created with 0600.
