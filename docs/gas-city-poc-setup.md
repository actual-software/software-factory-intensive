# Gas City PoC Setup Guide

This guide explains how to configure and run a local Gas City Proof-of-Concept (PoC) instance that integrates with Jira and GitHub to automate software development workflows.

## Overview

The Gas City PoC demonstrates an agent-driven SDLC workflow where:
1. Jira tickets trigger work via special `[gas-city-poc]` comments
2. A Gas City instance polls Jira and creates work items (beads)
3. Coding agents implement the requested features
4. Pull requests are automatically opened on GitHub
5. Jira tickets are updated with progress

## Prerequisites

### Required Tools

| Tool | Purpose | Min Version | Installation |
|------|---------|-------------|--------------|
| **tmux** | Session management | any | `apt install tmux` |
| **git** | Version control | any | `apt install git` |
| **jq** | JSON processing | any | `apt install jq` |
| **dolt** | Beads data plane | 1.80.0+ | [Install dolt](#installing-dolt) |
| **bd** (Beads CLI) | Issue tracking | 0.61.0+ | [Install beads](#installing-beads) |
| **flock** | File locking | any | `apt install util-linux` |
| **Go** | Build Gas City | 1.25+ | [Install Go](#installing-go) |
| **GitHub CLI** | GitHub integration | 2.0+ | [Install gh](#installing-github-cli) |

### API Credentials

You'll need:
- **Jira API Token**: Generated from your Atlassian account settings
- **Jira Email**: Your Atlassian account email
- **Jira Account ID**: Found via Jira REST API
- **GitHub Authentication**: Via `gh auth login`

## Installation

### Installing Go

```bash
cd /tmp
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
```

Add to `~/.bashrc` or `~/.zshrc`:
```bash
export PATH=$PATH:/usr/local/go/bin
```

### Installing dolt

```bash
cd /tmp
wget https://github.com/dolthub/dolt/releases/download/v1.85.0/dolt-linux-amd64.tar.gz
tar -xzf dolt-linux-amd64.tar.gz
sudo install -m 755 dolt-linux-amd64/bin/dolt /usr/local/bin/dolt
rm -rf dolt-linux-amd64*
dolt version
```

Configure dolt identity:
```bash
dolt config --global --add user.name "Your Name"
dolt config --global --add user.email "your.email@example.com"
```

### Installing Beads (bd)

```bash
cd /tmp
wget https://github.com/gastownhall/beads/releases/download/v0.61.0/beads_0.61.0_linux_amd64.tar.gz
tar -xzf beads_0.61.0_linux_amd64.tar.gz
sudo install -m 755 bd /usr/local/bin/bd
rm -rf bd beads_0.61.0_linux_amd64.tar.gz
bd version
```

### Installing Gas City

```bash
cd ~/.openclaw/workspace  # or your preferred directory
gh repo clone actual-software/gascity
cd gascity
export PATH=$PATH:/usr/local/go/bin
make build
sudo install -m 755 bin/gc /usr/local/bin/gc
gc version
```

### Installing GitHub CLI

```bash
# Install gh CLI
cd /tmp
wget https://github.com/cli/cli/releases/download/v2.89.0/gh_2.89.0_linux_amd64.tar.gz
tar -xzf gh_2.89.0_linux_amd64.tar.gz
sudo install -m 755 gh_2.89.0_linux_amd64/bin/gh /usr/local/bin/gh
rm -rf gh_2.89.0_linux_amd64*

# Authenticate
gh auth login
# Follow prompts: choose HTTPS, authenticate via browser or token
```

## Configuration

### 1. Initialize Gas City

```bash
# Create your city
gc init ~/.openclaw/workspace/gas-city-poc
cd ~/.openclaw/workspace/gas-city-poc
```

### 2. Configure Agents

Edit `city.toml`:
```toml
[workspace]
name = "gas-city-poc"
provider = "claude"  # or your preferred CLI agent

[[agent]]
name = "mayor"
prompt_template = "prompts/mayor.md"

[[agent]]
name = "claude"  # Add your CLI coding agent
```

### 3. Add Your Project as a Rig

```bash
# Clone your target repository
cd ~/.openclaw/workspace
gh repo clone your-org/your-repo

# Register it as a rig
cd gas-city-poc
gc rig add ../your-repo
```

### 4. Set Up Jira Integration

Create `.env` file in your Gas City directory:
```bash
export JIRA_API_TOKEN="your-jira-api-token-here"
export JIRA_EMAIL="your.email@example.com"
export JIRA_URL="https://your-workspace.atlassian.net"
export JIRA_ACCOUNT_ID="your-account-id"
```

Source it:
```bash
source .env
```

### 5. Install the Jira Sync Script

Create `scripts/sync-ticket.sh`:
```bash
#!/bin/bash
# Jira sync script
set -euo pipefail

JIRA_URL="${JIRA_URL}"
JIRA_EMAIL="${JIRA_EMAIL}"
JIRA_TOKEN="${JIRA_API_TOKEN}"
ISSUE_KEY="$1"  # Pass ticket key as argument
STATE_FILE=".gc/${ISSUE_KEY}-state.json"
RIG_PATH="../your-repo"

# Initialize state
[[ ! -f "$STATE_FILE" ]] && echo '{"bead_id": null, "last_comment_id": null}' > "$STATE_FILE"

# Fetch comments
COMMENTS_JSON=$(curl -s -u "${JIRA_EMAIL}:${JIRA_TOKEN}" \
    "${JIRA_URL}/rest/api/3/issue/${ISSUE_KEY}/comment")

# Extract latest [gas-city-poc] command
LATEST_COMMENT=$(echo "$COMMENTS_JSON" | jq -r '
    [.comments[]? | 
     select((.body.content[]?.content[]?.text? // "") | contains("[gas-city-poc]")) |
     {id: .id, text: (.body.content[]?.content[]?.text? // "")}
    ] | 
    sort_by(.id) | 
    last // empty
')

[[ -z "$LATEST_COMMENT" ]] && exit 0

COMMENT_ID=$(echo "$LATEST_COMMENT" | jq -r '.id')
LAST_ID=$(jq -r '.last_comment_id // empty' "$STATE_FILE")

[[ "$COMMENT_ID" == "$LAST_ID" ]] && exit 0

# Extract command
COMMAND=$(echo "$LATEST_COMMENT" | jq -r '.text' | sed -n 's/.*\[gas-city-poc\][[:space:]]*//p')

# Create bead
cd "$RIG_PATH"
BEAD_OUTPUT=$(bd create "$COMMAND" 2>&1)
BEAD_ID=$(echo "$BEAD_OUTPUT" | grep -oP '\\w+-\\w+' | head -1)

# Post to Jira
curl -s -X POST -u "${JIRA_EMAIL}:${JIRA_TOKEN}" \
    -H "Content-Type: application/json" \
    "${JIRA_URL}/rest/api/3/issue/${ISSUE_KEY}/comment" \
    --data "{
      \"body\": {
        \"type\": \"doc\\",
        \"version\": 1,
        \"content\": [{
          \"type\": \"paragraph\",
          \"content\": [{\"type\": \"text\", \"text\": \"✅ Created work item: ${BEAD_ID}\"}]
        }]
      }
    }" > /dev/null

# Sling to agent
cd ~/.openclaw/workspace/gas-city-poc
gc sling claude "$BEAD_ID"

# Update state
jq --arg cid "$COMMENT_ID" --arg bead "$BEAD_ID" \
   '.last_comment_id = $cid | .bead_id = $bead' \
   "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"
```

Make it executable:
```bash
chmod +x scripts/sync-ticket.sh
```

## Running the PoC

### Start Gas City

```bash
cd ~/.openclaw/workspace/gas-city-poc
gc start
```

Verify it's running:
```bash
gc status
```

### Trigger Work via Jira

1. **Create or open a Jira ticket** assigned to you
2. **Add a comment** with the trigger format:
   ```
   [gas-city-poc] Your command or request here
   ```
   
   Example:
   ```
   [gas-city-poc] Add a new API endpoint for user authentication at /api/v1/auth/login
   ```

3. **Run the sync script**:
   ```bash
   cd ~/.openclaw/workspace/gas-city-poc
   source .env
   ./scripts/sync-ticket.sh PROJ-123  # Replace with your ticket key
   ```

4. **Watch the agent work**:
   ```bash
   gc session attach mayor  # Or your agent name
   ```

### Automated Polling (Optional)

Set up a cron job or systemd timer to poll Jira automatically:

```bash
# Add to crontab (every 2 minutes)
*/2 * * * * cd ~/.openclaw/workspace/gas-city-poc && source .env && ./scripts/sync-ticket.sh PROJ-123
```

Or use a simple polling loop:
```bash
#!/bin/bash
while true; do
    cd ~/.openclaw/workspace/gas-city-poc
    source .env
    ./scripts/sync-ticket.sh PROJ-123
    sleep 120  # Poll every 2 minutes
done
```

## Workflow Example

**End-to-End Flow:**

1. **Developer adds Jira comment**:
   ```
   [gas-city-poc] Create a README.md file with project setup instructions
   ```

2. **Sync script detects it**:
   - Fetches latest comments
   - Finds `[gas-city-poc]` pattern
   - Extracts command text

3. **Gas City creates work item (bead)**:
   - `bd create "Create a README.md file..."`
   - Assigns bead ID (e.g., `proj-a1b`)

4. **Bead is slung to agent**:
   - `gc sling claude proj-a1b`
   - Agent starts working

5. **Agent completes work**:
   - Creates/modifies files
   - Commits changes
   - Opens pull request (if configured)

6. **Jira is updated**:
   - Status changes to "In Review"
   - Comment added: "PR opened: #123"

## Troubleshooting

### Gas City won't start

```bash
# Check dependencies
gc doctor

# View logs
tail -f ~/.gc/supervisor.log
```

### Bead creation fails

```bash
# Check beads database
cd your-rig-path
bd list

# Reset if corrupted
rm -rf .beads
gc rig add .
```

### Jira API errors

```bash
# Test your credentials
curl -u "your.email@example.com:YOUR_API_TOKEN" \
  https://your-workspace.atlassian.net/rest/api/3/myself
```

### GitHub CLI not authenticated

```bash
gh auth status
gh auth login  # Re-authenticate if needed
```

### Agent not found

Make sure your CLI coding agent (claude, codex, gemini, etc.) is installed and on PATH:
```bash
which claude  # or codex, gemini, etc.
```

## Advanced Configuration

### Custom Formulas

Gas City uses "formulas" to orchestrate multi-step workflows. Create custom formulas in `formulas/`:

```toml
# formulas/pr-workflow.formula.toml
[[step]]
name = "implement"
agent = "claude"

[[step]]
name = "test"
agent = "codex"

[[step]]
name = "review"
agent = "mayor"
```

### Multiple Agents

Configure different agents for different types of work:

```toml
[[agent]]
name = "frontend"
provider = "claude"

[[agent]]
name = "backend"
provider = "codex"

[[agent]]
name = "devops"
provider = "gemini"
```

### Webhook Integration (Advanced)

For real-time Jira updates instead of polling, set up a webhook:

1. Configure a public endpoint (ngrok, AWS API Gateway, etc.)
2. Register webhook in Jira Settings → System → WebHooks
3. Listen for `issue_commented` events
4. Filter for `[gas-city-poc]` pattern
5. Trigger sync immediately

## Security Considerations

- **Never commit API tokens** to git
- Store credentials in environment variables or secret management
- Use least-privilege API tokens (only required scopes)
- Review agent changes before deploying to production
- Consider running in an isolated environment

## Next Steps

- Extend the sync script to handle multiple tickets
- Add GitHub PR creation automation
- Implement status updates (ticket → In Progress, Done)
- Create custom formulas for your workflow
- Set up monitoring and alerting

## Resources

- [Gas City Documentation](https://github.com/gastownhall/gascity/tree/main/docs)
- [Beads Documentation](https://github.com/gastownhall/beads)
- [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [GitHub CLI Manual](https://cli.github.com/manual/)

---

**Questions or Issues?** Open a ticket or ask in your team's Slack channel!
