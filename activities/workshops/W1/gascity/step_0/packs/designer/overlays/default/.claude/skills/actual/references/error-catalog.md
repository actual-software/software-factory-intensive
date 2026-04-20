# Error Catalog Reference

Complete catalog of all error types in the actual CLI. Load this when troubleshooting a specific error.

## Table of Contents

- [Error Summary Table](#error-summary-table)
- [Exit Code 2: Auth and Setup Errors](#exit-code-2-auth-and-setup-errors)
- [Exit Code 3: Billing and API Errors](#exit-code-3-billing-and-api-errors)
- [Exit Code 1: General Runtime Errors](#exit-code-1-general-runtime-errors)
- [Exit Code 4: User Cancelled](#exit-code-4-user-cancelled)
- [Exit Code 5: I/O Errors](#exit-code-5-io-errors)
- [Diagnosis Pattern](#diagnosis-pattern)

## Error Summary Table

| Error | Exit | Category | One-Line Fix |
|-------|------|----------|-------------|
| ClaudeNotFound | 2 | Auth/Setup | Install Claude Code CLI, ensure `claude` is in PATH |
| ClaudeNotAuthenticated | 2 | Auth/Setup | Run `claude auth login` |
| CodexNotFound | 2 | Auth/Setup | Install Codex CLI, ensure `codex` is in PATH |
| CodexNotAuthenticated | 2 | Auth/Setup | Set `OPENAI_API_KEY` or run `codex login` |
 | CursorNotFound | 2 | Auth/Setup | Install Cursor CLI, ensure `agent` is in PATH |
 | CursorNotAuthenticated | 2 | Auth/Setup | Set `CURSOR_API_KEY` or run `cursor-agent login` |
 | ApiKeyMissing | 2 | Auth/Setup | Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` |
| CodexCliModelRequiresApiKey | 2 | Auth/Setup | Set `OPENAI_API_KEY` (ChatGPT OAuth only supports default model) |
| NoRunnerAvailable | 2 | Auth/Setup | Install a runner or set an API key — none of the candidates for the given model were usable |
| CreditBalanceTooLow | 3 | Billing/API | Add credits to your account |
| ApiError | 3 | Billing/API | Check API URL, network, credentials |
| ApiResponseError | 3 | Billing/API | Check API status page, retry later |
| ServiceUnavailable | 3 | Billing/API | API is temporarily updating — retry automatically (10s, 30s, 60s), then fails gracefully |
| RunnerFailed | 1 | Runtime | Check runner output for details |
| RunnerOutputParse | 1 | Runtime | Check model compatibility with runner |
| RunnerTimeout | 1 | Runtime | Increase `invocation_timeout_secs` config |
| ConfigError | 1 | Runtime | Check YAML syntax, run `actual config show` |
| AnalysisEmpty | 1 | Runtime | Check project path and repo content |
| TailoringValidationError | 1 | Runtime | Retry, or use `--no-tailor` |
| InternalError | 1 | Runtime | Report as bug |
| TerminalIOError | 1 | Runtime | Check terminal capabilities |
| IoError | 5 | I/O | Check file permissions and disk space |
| UserCancelled | 4 | User | Intentional cancellation (not an error) |

## Exit Code 2: Auth and Setup Errors

These errors mean the runner or authentication is not properly configured. Fix them before attempting sync.

### ClaudeNotFound

**Cause**: The `claude` binary is not found in PATH.

**Hint**: Install the Claude Code CLI or check that it is in your PATH.

**Diagnosis**:
```bash
which claude
echo $PATH
```

**Fix**: Install Claude Code CLI per its documentation. Ensure the install directory is in PATH.

### ClaudeNotAuthenticated

**Cause**: The Claude Code CLI is installed but not authenticated.

**Hint**: Run `claude auth login` to authenticate.

**Diagnosis**:
```bash
actual auth
claude auth status  # if available
```

**Fix**:
```bash
claude auth login
```

### CodexNotFound

**Cause**: The `codex` binary is not found in PATH.

**Hint**: Install the Codex CLI or check that it is in your PATH.

**Diagnosis**:
```bash
which codex
echo $PATH
```

**Fix**: Install Codex CLI per its documentation.

### CodexNotAuthenticated

**Cause**: The Codex CLI is installed but not authenticated.

**Hint**: Set `OPENAI_API_KEY` or run `codex login`.

**Diagnosis**:
```bash
codex --version  # verify binary works
echo $OPENAI_API_KEY | head -c 7  # check key prefix without revealing it
```

**Fix**:
```bash
# Option 1: API key
export OPENAI_API_KEY="sk-..."
# Option 2: ChatGPT OAuth
codex login
```

### CursorNotFound

**Cause**: The `agent` binary is not found in PATH.

**Hint**: Install the Cursor CLI or check that it is in your PATH.

**Diagnosis**:
```bash
which agent
```

**Fix**: Install Cursor CLI per its documentation.

### CursorNotAuthenticated

**Cause**: The Cursor CLI is installed but not authenticated.

**Hint**: Set `CURSOR_API_KEY` or run `cursor-agent login`.

**Diagnosis**:
```bash
agent --version  # verify binary works
echo $CURSOR_API_KEY | head -c 7  # check key prefix without revealing it
```

**Fix**:
```bash
# Option 1: API key
export CURSOR_API_KEY="..."
# Option 2: OAuth login
cursor-agent login
```

### ApiKeyMissing

**Cause**: The runner requires an API key that is not set, or the provided key was rejected by the API (HTTP 401/403).

**Hint**: The error message and hint both specify exactly which environment variable needs to be set (e.g., `Set ANTHROPIC_API_KEY environment variable or add it to your config file`).

**Diagnosis**:
```bash
# Check which keys are set (without revealing values):
[ -n "$ANTHROPIC_API_KEY" ] && echo "ANTHROPIC_API_KEY: set" || echo "ANTHROPIC_API_KEY: not set"
[ -n "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY: set" || echo "OPENAI_API_KEY: not set"
```

**Fix**:
```bash
# For anthropic-api runner:
export ANTHROPIC_API_KEY="sk-ant-..."
# For openai-api runner:
export OPENAI_API_KEY="sk-..."
```

Or set in config (stored with 0600 permissions):
```bash
actual config set anthropic_api_key "sk-ant-..."
actual config set openai_api_key "sk-..."
```

### CodexCliModelRequiresApiKey

**Cause**: Using codex-cli with ChatGPT OAuth authentication and an explicit model. OAuth only supports the default model.

**Hint**: Set `OPENAI_API_KEY` to use explicit models with codex-cli.

**Diagnosis**:
```bash
actual config show  # check if model is set
echo $OPENAI_API_KEY | head -c 7  # check if key is set
```

**Fix**: Either remove the explicit model (use default) or set `OPENAI_API_KEY`:
```bash
# Option 1: Use default model
actual config set model ""
# Option 2: Set API key for explicit model support
export OPENAI_API_KEY="sk-..."
```

### NoRunnerAvailable

**Cause**: `actual adr-bot` was called without `--runner` or a `runner` config value, and none of the candidate runners for the given model passed their environment probe. The error message lists each candidate and the reason it was skipped.

**Hint**: Install a runner (e.g. `npm install -g @anthropic-ai/claude-code`) or set an API key (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`).

**Diagnosis**:
```bash
# See exactly which runners were tried and why each failed:
actual adr-bot 2>&1          # stderr shows the "Tried:" list

# Check which binaries are installed:
which claude
which codex
which cursor-agent

# Check which API keys are set:
[ -n "$ANTHROPIC_API_KEY" ] && echo "ANTHROPIC set" || echo "ANTHROPIC not set"
[ -n "$OPENAI_API_KEY" ]    && echo "OPENAI set"    || echo "OPENAI not set"
```

**Fix**: Install at least one runner for the model you are targeting, then re-run:
```bash
# For claude/sonnet models — install Claude Code CLI:
npm install -g @anthropic-ai/claude-code
claude auth login

# Or set the Anthropic API key directly:
export ANTHROPIC_API_KEY="sk-ant-..."

# For gpt/o-series models — set the OpenAI API key:
export OPENAI_API_KEY="sk-..."

# Alternatively, pin a specific runner with --runner to skip auto-detection:
actual adr-bot --runner anthropic-api
```

## Exit Code 3: Billing and API Errors

### CreditBalanceTooLow

**Cause**: The API account does not have sufficient credits for the requested operation.

**Hint**: Add credits at your provider's billing page or check your account quota.

**Diagnosis**: Check your account balance at the provider's dashboard (e.g., [Anthropic billing](https://console.anthropic.com/settings/billing) or [OpenAI billing](https://platform.openai.com/settings/organization/billing)).

**Fix**: Add credits. Consider using `--max-budget-usd` to control spending.

### ApiError

**Cause**: The API request failed (network error, invalid URL, authentication rejected by server).

**Hint**: Check your API URL, network connection, and credentials.

**Diagnosis**:
```bash
actual config show  # check api_url
curl -I <api_url>   # test connectivity
```

**Fix**: Verify `api_url` config, check network, ensure credentials are valid.

### ApiResponseError

**Cause**: The API returned an unexpected response (malformed JSON, unexpected status code).

**Hint**: This may be a transient issue. Try again later. If persistent, check the API status page.

**Diagnosis**: Run with `--verbose` and `--show-errors` for detailed error output.

**Fix**: Retry. If persistent, check the API provider's status page.

### ServiceUnavailable

**Cause**: The Actual AI API returned HTTP 503, indicating it is temporarily updating or unavailable.

**Behavior**: The CLI automatically retries 3 times with increasing delays (10s, 30s, 60s), showing live TUI messages during each wait ("Actual AI API is updating — retrying in Xs (N/3)..."). If all retries fail, the error is surfaced as a graceful message.

**Display**: "Actual AI API is being updated and will be available shortly"

**Fix**: Wait a few minutes and re-run. This is a transient condition during API deployments.

## Exit Code 1: General Runtime Errors

### RunnerFailed

**Cause**: The runner process exited with a non-zero status.

**Display**: `Runner failed: {message}\nstderr: {stderr}` — stderr output from the subprocess is shown inline.

**Hint**: Check the error details above. For subprocess runners, re-run with --verbose for more output.

**Diagnosis**:
```bash
actual adr-bot --verbose --show-errors  # get detailed output
# stderr from the runner subprocess is now included in the error message
```

**Fix**: Depends on the runner's error message. Common causes: model not available, rate limiting, context too large.

### RunnerOutputParse

**Cause**: The runner produced output that could not be parsed by the CLI.

**Hint**: The model may not be compatible with the runner or may have produced malformed output.

**Diagnosis**: Run with `--verbose` to see raw runner output.

**Fix**: Try a different model. Check `actual models` for known-compatible models.

### RunnerTimeout

**Cause**: The runner did not complete within `invocation_timeout_secs` (default: 600 seconds).

**Hint**: Increase the timeout or use a faster model.

**Diagnosis**:
```bash
actual config show  # check invocation_timeout_secs
```

**Fix**:
```bash
actual config set invocation_timeout_secs 1200  # double the timeout
```

### ConfigError

**Cause**: The configuration file has invalid YAML syntax or invalid values.

**Hint**: Check the config file for syntax errors.

**Diagnosis**:
```bash
actual config path   # find the config file
actual config show   # attempt to parse and display
```

**Fix**: Edit the config file to fix YAML syntax. Or reset:
```bash
# View the file
cat "$(actual config path)"
# Fix the YAML syntax, or delete to reset to defaults
```

### AnalysisEmpty

**Cause**: The analysis step produced no results, usually because the project path is empty or doesn't contain recognizable code.

**Hint**: Check that you're running in the correct directory and that the repo has code content.

**Diagnosis**:
```bash
pwd
ls -la
git log --oneline -5  # verify repo has commits
```

**Fix**: Ensure you're in the right directory. If using `--project`, verify the path exists.

### TailoringValidationError

**Cause**: The tailored output failed validation checks (e.g., the AI produced structurally invalid output).

**Hint**: Retry the sync. If persistent, use `--no-tailor` to skip AI tailoring.

**Fix**:
```bash
# Retry
actual adr-bot
# Or skip tailoring
actual adr-bot --no-tailor
```

### InternalError

**Cause**: An unexpected internal error occurred. This is likely a bug.

**Fix**: Report the error with reproduction steps.

### TerminalIOError

**Cause**: Failed to read from or write to the terminal (e.g., pipe closed, terminal capabilities missing).

**Fix**: Ensure you're running in a proper terminal. Try `--no-tui` to disable TUI mode.

## Exit Code 4: User Cancelled

### UserCancelled

**Cause**: The user cancelled the operation (e.g., declined a confirmation prompt).

This is not an error. No action needed.

## Exit Code 5: I/O Errors

### IoError

**Cause**: A file I/O operation failed (read, write, create directory).

**Hint**: Check file permissions and available disk space.

**Diagnosis**:
```bash
# Check permissions on output file location
ls -la CLAUDE.md 2>/dev/null || echo "File does not exist"
ls -la . | head -5  # check directory permissions
df -h .  # check disk space
```

**Fix**: Fix file permissions or free disk space.

## Diagnosis Pattern

When encountering any error, follow this pattern:

1. **Match**: Identify the error name from the CLI output
2. **Look up**: Find the error in this catalog (use the summary table)
3. **Diagnose**: Run the diagnosis commands listed for that error
4. **Fix**: Apply the fix
5. **Verify**: Re-run the command that failed to confirm the fix worked

For comprehensive environment checks, use the diagnostic script:
```bash
bash .claude/skills/actual/scripts/diagnose.sh
```
