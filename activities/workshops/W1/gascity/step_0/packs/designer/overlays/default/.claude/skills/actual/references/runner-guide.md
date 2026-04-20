# Runner Guide Reference

Deep reference for all 5 runners. Load this when setting up a runner, troubleshooting runner-specific issues, or answering model compatibility questions.

## Table of Contents

- [Overview](#overview)
- [claude-cli](#claude-cli)
- [anthropic-api](#anthropic-api)
- [openai-api](#openai-api)
- [codex-cli](#codex-cli)
- [cursor-cli](#cursor-cli)
- [Runner Resolution Order](#runner-resolution-order)
- [Model-to-Runner Inference](#model-to-runner-inference)
- [Troubleshooting](#troubleshooting)

## Overview

Runners are the AI backends that power `actual adr-bot`'s tailoring step. Each runner connects to a different AI provider or local CLI tool.

| Runner | Type | Binary | Auth Method | Default Model |
|--------|------|--------|-------------|---------------|
| claude-cli | CLI wrapper | `claude` | `claude auth login` | claude-sonnet-4-6 |
| anthropic-api | Direct API | (none) | `ANTHROPIC_API_KEY` env var | claude-sonnet-4-6 |
| openai-api | Direct API | (none) | `OPENAI_API_KEY` env var | gpt-5.2 |
| codex-cli | CLI wrapper | `codex` | `OPENAI_API_KEY` env var or `codex login` (ChatGPT OAuth) | gpt-5.2 |
| cursor-cli | CLI wrapper | `cursor-agent` | Optional `CURSOR_API_KEY` env var | `auto` |

## claude-cli

**The default runner.** Wraps the Claude Code CLI binary.

### Requirements

- `claude` binary in PATH
- Authenticated via `claude auth login`

### Setup

```bash
# Install Claude Code CLI (see Claude Code docs)
# Then authenticate:
claude auth login
```

### Authentication Check

```bash
actual auth
```

Returns auth status. If not authenticated, the error `ClaudeNotAuthenticated` (exit code 2) is returned during sync.

### Model Compatibility

- Default: `claude-sonnet-4-6`
- Supports short aliases: `sonnet`, `opus`, `haiku`
- Supports full claude model names (though those auto-infer to anthropic-api)

### Config

```bash
actual config set runner claude-cli
actual config set model claude-sonnet-4-6  # or just "sonnet"
```

## anthropic-api

Direct Anthropic API access without the Claude CLI binary.

### Requirements

- `ANTHROPIC_API_KEY` environment variable set

### Setup

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Authentication Check

```bash
actual auth  # Shows API key status
```

If the key is missing, the error `ApiKeyMissing` (exit code 2) is returned.

### Model Compatibility

- Default: `claude-sonnet-4-6`
- Supports all `claude-*` model names
- Full model names (e.g., `claude-sonnet-4-6`) auto-infer to this runner

### Config

```bash
actual config set runner anthropic-api
actual config set model claude-sonnet-4-6
# Or set the API key in config (stored with 0600 permissions):
actual config set anthropic_api_key "sk-ant-..."
# Increase max output tokens if responses are truncated (default: 16384):
actual config set max_tokens 32768
```

### Truncation Detection

The anthropic-api runner detects when a response is truncated (stop reason `max_tokens`) and logs a warning with the configured limit. If you see truncation warnings, increase `max_tokens`.

## openai-api

Direct OpenAI API access.

### Requirements

- `OPENAI_API_KEY` environment variable set

### Setup

```bash
export OPENAI_API_KEY="sk-..."
```

### Model Compatibility

- Default: `gpt-5.2`
- Supports `gpt-*`, `o1*`, `o3*`, `o4*`, `chatgpt-*` model names

### Config

```bash
actual config set runner openai-api
actual config set model gpt-5.2
# Or set the API key in config:
actual config set openai_api_key "sk-..."
```

## codex-cli

Wraps the Codex CLI binary. Supports two authentication modes.

### Requirements

- `codex` binary in PATH
- One of:
  - `OPENAI_API_KEY` environment variable, OR
  - ChatGPT OAuth via `codex login`

### Setup

```bash
# Install Codex CLI (see Codex docs)
# Then either:
export OPENAI_API_KEY="sk-..."
# Or use ChatGPT OAuth:
codex login
```

### ChatGPT OAuth Limitation

When using ChatGPT OAuth (via `codex login`), the codex-cli runner **only supports the default model**. If you specify an explicit model, you will get the `CodexCliModelRequiresApiKey` error (exit code 2).

To use a specific model with codex-cli, you must set `OPENAI_API_KEY` instead of using OAuth.

### Model Error Fallback

If codex-cli fails with a model-related error, the CLI automatically falls back to the openai-api runner and retries. This is transparent to the user.

### Model Compatibility

- Default: `gpt-5.2`
- Supports `codex-*`, `gpt-*-codex*` model names
- Also supports `gpt-*`, `o1*`, `o3*`, `o4*`, `chatgpt-*`

### Config

```bash
actual config set runner codex-cli
actual config set model gpt-5.2
```

## cursor-cli

Wraps the Cursor agent CLI binary.

### Requirements

- `agent` binary in PATH
- Optional: `CURSOR_API_KEY` environment variable

### Setup

```bash
# Install Cursor CLI (see Cursor docs)
# Optionally set API key:
export CURSOR_API_KEY="..."
```

### Model Compatibility

- Uses cursor's default model
- Config key `model` sets the model when cursor-cli runner is active

### Config

```bash
actual config set runner cursor-cli
actual config set model <model-name>
```

## Runner Resolution Order

When determining which runner to use, the CLI checks in this priority order:

1. **`--runner` CLI flag** (if provided): use that runner directly, no probing
2. **`runner` config key** (if set): use that runner directly, no probing
3. **Auto-detection** (`auto_detect_runner`): probe the environment to find which runner is actually available (see below)

When `--runner` or `runner` config is set, the runner is used unconditionally — no environment probing occurs.

## Auto-Detection (no `--runner` / no config `runner`)

When no explicit runner is specified, `auto_detect_runner` selects a runner by probing the environment in candidate order. The probe order is determined by the model:

1. **`--model` CLI flag** (if provided): use `runner_candidates(model)` to get an ordered list
2. **`model` config key** (if set): use `runner_candidates(model)` to get an ordered list
3. **No model**: default candidate list `[ClaudeCli, AnthropicApi]`

Each candidate is probed in order:
- **ClaudeCli**: checks that the binary exists and auth is valid
- **AnthropicApi**: checks that `ANTHROPIC_API_KEY` is set (env or config)
- **OpenAiApi**: checks that `OPENAI_API_KEY` is set (env or config)
- **CodexCli**: checks that the `codex` binary exists and auth is available
- **CursorCli**: checks that the `cursor-agent` binary exists and auth is available

The **first candidate whose probe succeeds** is selected. If all fail, the `NoRunnerAvailable` error (exit code 2) is returned with a list of every candidate and the reason each failed.

## Model-to-Runner Candidate Mapping

The `runner_candidates(model)` function returns an **ordered list** of candidates for a given model name:

| Model Pattern | Candidates (in priority order) |
|---------------|-------------------------------|
| Short aliases: `sonnet`, `opus`, `haiku` | `[ClaudeCli, AnthropicApi]` |
| Full Anthropic: `claude-*` | `[AnthropicApi, ClaudeCli]` |
| OpenAI standard: `gpt-*`, `o1*`, `o3*`, `o4*`, `chatgpt-*` | `[CodexCli, OpenAiApi]` |
| Codex models: `codex-*`, `gpt-*-codex*` | `[CodexCli, OpenAiApi]` |
| Unrecognized / custom | `[ClaudeCli, AnthropicApi, OpenAiApi, CodexCli, CursorCli]` |

### Edge Cases

- Short aliases (`sonnet`) try `ClaudeCli` first, then fall back to `AnthropicApi`
- Full names (`claude-sonnet-4-6`) try `AnthropicApi` first, then fall back to `ClaudeCli`
- `chatgpt-*` goes to `CodexCli` first, then `OpenAiApi`
- Unrecognized model names probe all runners in the order listed above

## Troubleshooting

### Runner Not Found

| Error | Missing Binary | Install |
|-------|---------------|---------|
| ClaudeNotFound | `claude` | Install Claude Code CLI |
| CodexNotFound | `codex` | Install Codex CLI |
| CursorNotFound | `agent` | Install Cursor CLI |

Check with: `which claude`, `which codex`, `which agent`

### Authentication Failures

| Error | Runner | Fix |
|-------|--------|-----|
| ClaudeNotAuthenticated | claude-cli | `claude auth login` |
| CodexNotAuthenticated | codex-cli | Set `OPENAI_API_KEY` or `codex login` |
| ApiKeyMissing | anthropic-api / openai-api | Set the required env var |
| CodexCliModelRequiresApiKey | codex-cli + OAuth | Set `OPENAI_API_KEY` (OAuth only supports default model) |
| NoRunnerAvailable | (auto-detect) | Install a runner or set an API key; see error output for which candidates were tried |

### Runner Timeout

If the runner exceeds `invocation_timeout_secs` (default 600s):

```bash
# Increase timeout
actual config set invocation_timeout_secs 1200
```

### Model Mismatch

If you get an error about an unrecognized model:

```bash
# List all known models
actual models

# Check what runner a model maps to
actual runners
```

## actual models

Lists known model names grouped by runner, with live model fetching from OpenAI and Anthropic APIs.

By default, `actual models` fetches the live model list from the OpenAI and Anthropic APIs (using cached credentials) and merges the results with the hardcoded static list. Live models are annotated with `(live)` in the output. The freshness of the cached live list is shown per-family.

Options:
  --no-fetch    Skip live API fetch; show only the hardcoded model list (useful for offline or air-gapped environments)
