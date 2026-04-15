# Sync Workflow Reference

Complete internals of `actual adr-bot`. Load this when debugging sync failures or when the user asks what sync does.

## Table of Contents

- [Overview](#overview)
- [Step-by-Step Workflow](#step-by-step-workflow)
- [Environment Check Details](#environment-check-details)
- [Analysis and Caching](#analysis-and-caching)
- [ADR Fetching](#adr-fetching)
- [Tailoring](#tailoring)
- [Diff and Write](#diff-and-write)
- [Flags Reference](#flags-reference)

## Overview

`actual adr-bot` is a 13-step pipeline: environment check, analysis, filtering, confirmation, config reload, ADR fetch, rejection filtering, tailoring, diff computation, diff display, dry-run handling, write confirmation, and file write.

## Step-by-Step Workflow

### Step 1: Environment Check

Displays current environment information:
- Auth status (runner + auth state)
- Runner and model in use
- API server URL
- Config file path
- Working directory
- Git branch (if in a git repo)
- Cache status

The environment check also runs a runner pre-flight probe: it verifies that the selected runner is available and accessible (binary present, API key set, etc.) before proceeding. If the probe fails, sync aborts here with an error in the Environment step rather than letting the run continue into Analysis and Tailoring.

**Default runner**: When no `runner` or `model` is configured, sync auto-detects using the fallback order `claude-cli → anthropic-api`. If an OpenAI model (e.g. `gpt-5.2`) is set but no runner is specified, it uses `codex-cli → openai-api → cursor-cli` instead. If no runner is available, the run aborts during this step with a `NoRunnerAvailable` error.

### Step 2: Analysis

Analyzes the repository to determine what ADRs are relevant.

- **Caching**: If the repo is a git repository, analysis results are cached. Subsequent runs reuse the cache unless content changes.
- **`--force` flag**: Bypasses the cache and re-analyzes from scratch.
- The analysis examines the codebase structure, frameworks, languages, and patterns.

### Step 3: Project Filtering

If `--project PATH` flags are specified, filters analysis results to only the specified subdirectories. Multiple `--project` flags can be provided (e.g., for monorepo setups).

If no `--project` flag is given, uses the full analysis.

### Step 3b: Language & Framework Selection

After filtering, sync automatically selects the primary language and framework for each project:

- **Language**: The language with the most lines of code is auto-selected.
- **Framework**: The first detected framework compatible with the selected language is auto-selected. Compatibility is determined by manifest source (e.g., Cargo.toml frameworks are compatible with Rust, package.json frameworks with JavaScript/TypeScript).
- If no languages are detected, no selection is made.
- If no compatible frameworks exist, only the language is selected.

### Step 4: Confirmation

Presents the analysis summary (including auto-selected language and framework per project) and asks the user to confirm before proceeding.

- **Accept**: Proceeds with the current selection.
- **Change**: Opens interactive single-select prompts for language and framework (if multiple options exist), then loops back to show the updated summary.
- **Reject**: Exits sync.
- **`--force` flag**: Skips this confirmation prompt entirely, using auto-selected values.

### Step 5: Config Reload

Reloads the configuration file to pick up any changes made since the start of the sync.

If `--reset-rejections` is specified, clears the list of previously rejected ADRs so they are offered again.

### Step 6: ADR Fetching

Fetches ADRs from the API server:
- Uses the configured `api_url` (default: Actual's hosted API)
- Sends analysis results to get relevant ADRs
- Includes retry logic for transient failures
- On HTTP 503 (Service Unavailable), automatically retries 3 times with delays (10s, 30s, 60s), showing live TUI messages like "Actual AI API is updating — retrying in 10s (1/3)..."
- After exhausting 503 retries, surfaces: "Actual AI API is being updated and will be available shortly"
- Respects `batch_size` and `concurrency` settings

### Step 7: Rejection Filtering

Filters out ADRs that the user previously rejected (unless `--reset-rejections` was used in step 5).

### Step 8: Tailoring

Tailors ADR content to the specific codebase using the configured runner/model:
- Sends ADR content + codebase context to the AI runner
- The runner adapts generic ADR guidance to project-specific patterns
- Results are cached per ADR + codebase hash

**Skip with `--no-tailor`**: Uses raw ADR content without AI adaptation. Useful for faster runs or when the AI runner is unavailable.

**`--max-budget-usd`**: Sets a spending cap for the tailoring step. Sync aborts if the estimated cost would exceed this value.

### Step 9: Diff Computation

Computes diffs between current output files and the new tailored content:
- Identifies which files would be created, modified, or left unchanged
- Handles managed section markers for partial file updates

### Step 10: Diff Display

Shows a summary of what would change:
- New files to create
- Existing files to modify (with diff preview)
- Files with no changes

### Step 11: Dry-Run Handling

If `--dry-run` is specified, sync stops here:
- Shows the diff summary from step 10
- With `--full`, also shows the complete content that would be written
- Exits without modifying any files

### Step 12: Write Confirmation

Asks the user to confirm which files to write.

- **`--force` flag**: Skips this confirmation and writes all files.
- The user can selectively accept or reject individual file changes.

### Step 13: File Write

Writes the accepted changes to disk:
- Creates new files with appropriate headers
- Updates existing files by replacing managed sections
- Appends managed sections to files that don't have markers yet
- Preserves file content outside managed section markers

## Environment Check Details

The environment check in step 1 displays:

| Item | Source |
|------|--------|
| Runner | Config `runner` field or CLI `--runner` flag |
| Auth status | Checks binary availability + auth state for the active runner |
| Model | Config `model` or CLI `--model` flag |
| API URL | Config `api_url` or CLI `--api-url` flag |
| Config path | `~/.actualai/actual/config.yaml` or `ACTUAL_CONFIG`/`ACTUAL_CONFIG_DIR` override |
| Working directory | Current directory |
| Git branch | From git, if in a repo |
| Cache status | Whether cached analysis exists for this repo |

## Analysis and Caching

- Cache key: derived from the git repository state + config hash (include/exclude categories, include_general, max_per_framework)
- Cache location: managed internally by the CLI (stored in `~/.actualai/actual/config.yaml` under `cached_analysis`)
- Cache invalidation: automatic when repo content changes or config fields change
- **TTL**: cached entries expire after 7 days and are treated as a miss
- **Size limit**: entries larger than 10 MiB when serialized are silently skipped (not cached)
- `--force` always bypasses the cache
- Use `actual cache clear` to manually wipe cached analysis and tailoring results

## ADR Fetching

- Endpoint: configured `api_url` + ADR fetch path
- Auth: uses the runner's authentication (API key or CLI auth)
- Retry: automatic retry on transient HTTP errors
- Batching: controlled by `batch_size` config (default 15)
- Parallelism: controlled by `concurrency` config (default 10)

## Tailoring

- Input: raw ADR content + codebase analysis context
- Output: ADR content adapted to the specific project
- Runner: uses whichever runner is configured (same as sync's main runner)
- Caching: tailored results are cached per (ADR content hash, codebase hash); TTL 7 days; max 10 MiB
- Budget: `--max-budget-usd` limits total spend across all tailoring calls

## Diff and Write

### Managed Section Markers

All output files use these markers to delimit the CLI-managed content:

```
<!-- managed:actual-start -->
<!-- last-synced: TIMESTAMP -->
<!-- version: N -->
<!-- adr-ids: id1,id2,... -->
(tailored ADR content here)
<!-- managed:actual-end -->
```

### Merge Strategies

| Scenario | Behavior |
|----------|----------|
| New root file | Write header + managed section |
| New subdir file | Write managed section only (no header) |
| Existing file with markers | Replace content between markers |
| Existing file without markers | Append managed section at end |

Content outside the managed markers is never modified.

## Flags Reference

| Flag | Short | Purpose | Notes |
|------|-------|---------|-------|
| `--dry-run` | | Preview without writing | Safe, no side effects |
| `--full` | | Show full content in dry-run | Requires `--dry-run` |
| `--force` | | Skip confirmations, bypass cache | |
| `--project PATH` | | Filter to subdirectory | Repeatable for monorepos |
| `--model MODEL` | | Override model | Auto-infers runner from model name |
| `--runner RUNNER` | | Override runner | One of: claude-cli, anthropic-api, openai-api, codex-cli, cursor-cli |
| `--api-url URL` | | Override API URL | |
| `--verbose` | | Verbose output | |
| `--no-tailor` | | Skip AI tailoring | Uses raw ADR content |
| `--max-budget-usd N` | | Set spending cap | Positive finite number |
| `--no-tui` | | Disable TUI mode | Plain text output |
| `--output-format FMT` | | Override output format | claude-md, agents-md, cursor-rules |
| `--reset-rejections` | | Re-offer rejected ADRs | |
| `--show-errors` | | Show detailed errors | |
