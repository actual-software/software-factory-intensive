# Gas City Setup Guide: Jira→Agent→PR Automation

> **Goal:** Set up an autonomous workflow where a `[gas-city-poc]` comment on a Jira ticket triggers a Gas City coding agent to implement the work, push changes, and comment results back on Jira—no manual commands after initial setup.

## What You'll Build

```
User comments [gas-city-poc] on Jira ticket
      ↓
Gas City Order (polls Jira comments every 2 min)
      ↓
Script acknowledges on Jira, slings bead to agent
      ↓
Coding Agent implements changes
      ↓
Git Commit + Push + PR
      ↓
Results posted back to Jira
```

## Prerequisites

- macOS or Linux with admin rights
- A Jira Cloud instance with API access
- A Git repository to work on
- An Anthropic API key (for Claude Code) or equivalent for your chosen agent

## Step 1: Install Gas City

**macOS (one command installs everything):**
```bash
brew install gastownhall/gascity/gascity
```

This pulls in all dependencies: `gc`, `bd` (beads CLI), `dolt`, `tmux`, `jq`, `git`, `flock`.

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update && sudo apt-get install -y tmux git jq procps lsof util-linux
sudo curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | sudo bash

git clone https://github.com/gastownhall/beads.git /tmp/beads
cd /tmp/beads && make install

git clone https://github.com/gastownhall/gascity.git /tmp/gascity
cd /tmp/gascity && make install
```

**Verify:**
```bash
gc version       # e.g. 0.13.4
bd --version     # e.g. bd version 0.63.3
dolt version     # e.g. dolt version 1.85.0
tmux -V          # e.g. tmux 3.6a
```

## Step 2: Initialize Your City

```bash
gc init ~/my-city
```

The interactive wizard will prompt you to:
1. Choose a config template — select **tutorial** (default)
2. Choose a coding agent — select **Claude Code** (default)

Then verify:
```bash
gc status ~/my-city
```

You should see the city running with a `mayor` agent and a `claude` pool.

## Step 3: Add Your Repository as a Rig

Run from **inside the city directory** (gc walks up from cwd to find city.toml):

```bash
cd ~/my-city
gc rig add ~/path/to/your-repo
```

Rigs stay at their original filesystem location — Gas City registers them by path, it doesn't copy or move anything.

Verify:
```bash
gc rig list
```

## Step 4: Add a Coding Agent for Your Rig

Edit `~/my-city/city.toml` to add an agent scoped to your rig:

```toml
[[agent]]
name = "dev-agent"
dir = "your-repo-name"       # Must match the rig name from gc rig list
provider = "claude"
idle_timeout = "4h"
```

The rig name is auto-derived from the directory name. Check `gc rig list` to confirm.

**Provider auth** — set your API key so the agent can use Claude:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Verify the agent appears:
```bash
cd ~/my-city && gc status
```

## Step 5: Configure Jira Sync

From your **rig directory** (not the city directory), configure beads to talk to Jira:

```bash
cd ~/path/to/your-repo

bd config set jira.url "https://your-company.atlassian.net"
bd config set jira.username "your-email@company.com"
bd config set jira.api_token "YOUR_JIRA_API_TOKEN"
bd config set jira.project "PROJ"
```

**Get a Jira API token:** https://id.atlassian.com/manage-profile/security/api-tokens

Test the connection:
```bash
bd jira sync --pull --dry-run
```

If it lists tickets, do the real sync:
```bash
bd jira sync --pull
```

Verify beads were created:
```bash
bd list
```

## Step 6: Create the Jira Sync Order

Orders automate periodic tasks. Create one to keep beads in sync with Jira:

```bash
cd ~/my-city
mkdir -p orders/jira-sync
cat > orders/jira-sync/order.toml << 'EOF'
[order]
description = "Pull new and updated tickets from Jira"
gate = "cooldown"
interval = "5m"
exec = "cd /absolute/path/to/your-repo && bd jira sync --pull"
EOF
```

**Important:** Use the absolute path to your rig in the `exec` command, since `bd` needs to find the rig's `.beads` database.

Verify the order is recognized:
```bash
gc order list
```

## Step 7: Create the Comment-Trigger Script

Gas City's `bd jira sync` imports tickets but not comments. To trigger work from Jira comments tagged `[gas-city-poc]`, we need a polling script.

Create `~/my-city/scripts/jira-comment-poll.sh`:

```bash
mkdir -p ~/my-city/scripts
cat > ~/my-city/scripts/jira-comment-poll.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURE THESE ===
CITY_DIR="$HOME/my-city"
RIG_DIR="/absolute/path/to/your-repo"
AGENT_TARGET="your-repo-name/dev-agent"   # rig-name/agent-name
# ========================

STATE_FILE="${HOME}/.gc-jira-poc-state.json"

JIRA_URL="$(cd "$RIG_DIR" && bd config get jira.url)"
JIRA_USER="$(cd "$RIG_DIR" && bd config get jira.username)"
JIRA_TOKEN="$(cd "$RIG_DIR" && bd config get jira.api_token)"

if echo "$JIRA_TOKEN" | grep -q "(not set)"; then
    echo "ERROR: Jira not configured in rig" >&2; exit 1
fi

[ -f "$STATE_FILE" ] || echo '{}' > "$STATE_FILE"

cd "$RIG_DIR"
bd list --json 2>/dev/null | \
  jq -c '.[] | select(.metadata.source_system // "" | startswith("jira:"))' | \
while read -r bead; do
    bead_id=$(echo "$bead" | jq -r '.id')
    jira_key=$(echo "$bead" | jq -r '.metadata.source_system' | awk -F: '{print $3}')
    [ -n "$jira_key" ] || continue

    last=$(jq -r --arg k "$jira_key" '.[$k] // empty' "$STATE_FILE")

    comments=$(curl -sf -u "${JIRA_USER}:${JIRA_TOKEN}" \
        -H "Accept: application/json" \
        "${JIRA_URL}/rest/api/3/issue/${jira_key}/comment" || echo '{}')

    match=$(echo "$comments" | jq -r '
        [.comments[]? |
         {id: .id, created: .created,
          text: ([.body.content[]?.content[]? | select(.type=="text") | .text] | join(""))} |
         select(.text | contains("[gas-city-poc]"))] |
        sort_by(.created) | last // empty')

    [ -n "$match" ] && [ "$match" != "null" ] || continue

    cid=$(echo "$match" | jq -r '.id')
    [ "$last" != "$cid" ] || continue

    cmd=$(echo "$match" | jq -r '.text' | sed 's/\[gas-city-poc\]//g' | xargs)
    echo "$(date -u +%FT%TZ) [${jira_key}] → ${cmd}"

    # Acknowledge on Jira
    ack=$(jq -n '{body:{type:"doc",version:1,content:[{type:"paragraph",content:[{type:"text",text:("Gas City received and routing to agent:\n"+$c)}]}]}}' --arg c "$cmd")
    curl -sf -u "${JIRA_USER}:${JIRA_TOKEN}" -H "Content-Type: application/json" \
        -X POST -d "$ack" "${JIRA_URL}/rest/api/3/issue/${jira_key}/comment" >/dev/null || true

    # Add context to bead and sling to agent
    bd comments add "$bead_id" "[gas-city-poc] ${cmd}" 2>/dev/null || true
    gc sling "$AGENT_TARGET" "$bead_id" --city "$CITY_DIR" 2>&1 || true

    # Mark processed
    jq --arg k "$jira_key" --arg c "$cid" '. + {($k): $c}' "$STATE_FILE" > "${STATE_FILE}.tmp" \
        && mv "${STATE_FILE}.tmp" "$STATE_FILE"
done

echo "$(date -u +%FT%TZ) Poll complete"
SCRIPT
chmod +x ~/my-city/scripts/jira-comment-poll.sh
```

**Edit the three config variables** at the top of the script to match your setup.

## Step 8: Create the Comment-Poll Order

Wire the script into Gas City as a periodic order:

```bash
cd ~/my-city
mkdir -p orders/jira-comment-poll
cat > orders/jira-comment-poll/order.toml << 'EOF'
[order]
description = "Poll Jira comments for [gas-city-poc] commands and route to agents"
gate = "cooldown"
interval = "2m"
exec = "$GC_CITY_ROOT/scripts/jira-comment-poll.sh"
EOF
```

Verify both orders:
```bash
gc order list
```

You should see:
```
NAME                 TYPE     GATE         INTERVAL/SCHED  POOL
jira-comment-poll    exec     cooldown     2m              -
jira-sync            exec     cooldown     5m              -
```

## Step 9: Test End-to-End

### 9.1: Verify Orders Run

Manually trigger the Jira sync order to confirm it works:
```bash
gc order run jira-sync
```

Then manually run the comment poll:
```bash
bash ~/my-city/scripts/jira-comment-poll.sh
```

If there are no `[gas-city-poc]` comments yet, it should print `Poll complete` with no matches.

### 9.2: Trigger from Jira

Go to a Jira ticket in your project and add a comment:
```
[gas-city-poc] Add a hello world function to utils.py
```

Wait up to 2 minutes (or manually run the poll script again). You should see:
1. The script finds the comment and prints the command
2. An acknowledgment comment appears on the Jira ticket
3. The bead is slung to the agent

### 9.3: Monitor

```bash
# Watch events in real time
gc events --follow

# Check agent session
gc session list
gc session peek dev-agent

# View order execution history
gc order history jira-comment-poll

# Check bead status
cd ~/path/to/your-repo && bd list
```

### 9.4: Stop the Agent (if needed)

```bash
gc session suspend <session-id>   # Pause, can resume later
gc session close <session-id>     # Stop permanently
```

Get the session ID from `gc session list`.

## Troubleshooting

### gc rig add fails with "no such file: city.toml"

You must run `gc rig add` from inside the city directory, or pass `--city ~/my-city`.

### bd config / bd jira commands fail with "no beads database found"

Run `bd` commands from inside the rig directory (where `.beads/` lives), not the city directory.

### Order not running

```bash
gc order list              # Is it listed?
gc order show <name>       # Check config
gc order run <name>        # Manual trigger
gc order history <name>    # Execution history
```

### Agent not picking up work

```bash
gc status                       # Is the agent running?
gc session list                 # Active sessions?
gc session peek <session-id>    # What's it doing?
gc doctor                       # Diagnose issues
```

### Jira comment not detected

```bash
# Run poll script manually with verbose output
bash -x ~/my-city/scripts/jira-comment-poll.sh

# Check state file (shows processed comment IDs)
cat ~/.gc-jira-poc-state.json

# Reset state to reprocess all comments
echo '{}' > ~/.gc-jira-poc-state.json
```

## Reference Commands

| Command | Description |
|---------|-------------|
| `gc init <path>` | Create a new city |
| `gc start` / `gc stop` | Start/stop city |
| `gc status` | Show city and agent status |
| `gc rig add <path>` | Register a repository |
| `gc rig list` | List registered rigs |
| `gc sling <target> <bead>` | Route work to an agent |
| `gc session list` | List active sessions |
| `gc session peek <id>` | View agent output |
| `gc session suspend <id>` | Pause a session |
| `gc session close <id>` | Stop a session permanently |
| `gc events` | View event log |
| `gc events --follow` | Stream events in real time |
| `gc order list` | List automation orders |
| `gc order run <name>` | Manually trigger an order |
| `gc order history <name>` | View order execution log |
| `gc doctor` | Diagnose city health |
| `bd list` | List beads (work items) |
| `bd show <id>` | Show bead details |
| `bd jira sync --pull` | Import from Jira |
| `bd jira sync --push` | Export to Jira |
| `bd jira status` | Show Jira sync status |
| `bd config set <key> <val>` | Configure beads |

## Resources

- [Gas City Documentation](https://docs.gascityhall.com)
- [Gas City Repository](https://github.com/gastownhall/gascity)
- [Beads Documentation](https://github.com/gastownhall/beads)
- [Gas City Installation Guide](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md)

## Contributing

Found an issue? Please open an issue or PR in the [software-factory-intensive](https://github.com/actual-software/software-factory-intensive) repository.
