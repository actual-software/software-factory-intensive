# Examples

This directory contains reference implementations and examples related to autonomous software development workflows.

## `jira-aider-poc.py`

A proof-of-concept script demonstrating autonomous Jira→AI coding workflow.

### What It Does

1. Polls Jira for commands tagged with `[gas-city-poc]`
2. Executes commands via Aider (AI pair programming CLI)
3. Posts results back to Jira automatically

### Purpose

This POC was used to validate end-to-end autonomous coding before full Gas City integration. It demonstrates:

- External tool integration (Jira API)
- AI coding agent orchestration (Aider)
- Feedback loop (posting results back)
- State management (tracking processed commands)

### Gas City Equivalent

In Gas City, this workflow would be implemented using:

```toml
# Order for polling Jira
[[order]]
name = "jira-poll"
type = "exec"
command = "/path/to/jira-sync-script.sh"
trigger.cron = "*/5 * * * *"

# Formula for agent work
# (defined in pack or city.toml)
[[formula]]
name = "implement-from-jira"
steps = [
  { type = "fetch", source = "jira" },
  { type = "route", target = "dev-agent" },
  { type = "implement" },
  { type = "commit" },
  { type = "notify", target = "jira" }
]

# Agent to execute work
[[agent]]
name = "dev-agent"
provider = "claude"  # or codex, cursor, gemini
dir = "my-project"

# Sling work to agent
# gc sling --issue SRAI-123 --formula implement-from-jira
```

### Usage

**Prerequisites:**
```bash
pip install aider-chat requests
```

**Configuration:**
```bash
export JIRA_API_TOKEN="your-atlassian-api-token"
```

**Run once:**
```bash
python3 examples/jira-aider-poc.py
```

**Continuous operation (cron):**
```bash
# Add to crontab
*/5 * * * * cd /path/to/repo && python3 examples/jira-aider-poc.py >> ~/poc.log 2>&1
```

**Trigger via Jira:**
Add a comment to the configured issue (SRAI-1685 by default):
```
[gas-city-poc] Add a function to calculate fibonacci numbers
```

The script will:
1. Detect the command
2. Post "🤖 Autonomous workflow started..."
3. Execute Aider with the command
4. Post "✅ Task completed..." or "❌ Task failed..."

### Architecture

```
┌─────────────┐
│    Jira     │
│   (API)     │
└──────┬──────┘
       │ 1. Poll for [gas-city-poc]
       │ 2. Fetch command
       │
       ▼
┌─────────────┐
│   Python    │
│   Script    │
└──────┬──────┘
       │ 3. Execute command
       │
       ▼
┌─────────────┐
│    Aider    │ ← AI pair programming
│  (AWS/LLM)  │
└──────┬──────┘
       │ 4. Make code changes
       │
       ▼
┌─────────────┐
│     Git     │ ← Auto-commit
│    Repo     │
└─────────────┘
       │
       │ 5. Post results
       ▼
┌─────────────┐
│    Jira     │
│  (Comment)  │
└─────────────┘
```

### Limitations

- **Single issue monitoring** - Only watches one Jira issue
- **No concurrency** - Processes one command at a time
- **Cron-based** - External scheduler required
- **No rollback** - Failed changes aren't automatically reverted
- **State file** - Uses local JSON file (not distributed)

Gas City solves these with:
- Multiple rigs and agents
- Built-in concurrency and pools
- Event-driven triggers (not just cron)
- Beads for durable work state
- Controller-managed reconciliation

### Related

- **SRAI-1657:** Gas City PoC demo (working implementation)
- **SRAI-1685:** This setup guide
- **Gas City Docs:** https://docs.gascityhall.com
