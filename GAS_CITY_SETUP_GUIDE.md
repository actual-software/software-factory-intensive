# Gas City Setup Guide: Jira→Agent→PR Automation

> **Goal:** Set up an autonomous workflow where Jira tickets automatically flow through Gas City to a coding agent, get implemented, and sync results back to Jira—no manual commands after initial setup.

## What You'll Build

```
Jira Ticket Created
      ↓
Gas City Order (periodic sync)
      ↓
Bead Created in Gas City
      ↓
Formula Routes to Coding Agent
      ↓
Agent Implements Changes
      ↓
Git Commit + Push
      ↓
Results Sync Back to Jira
```

**Expected Time:** 30-45 minutes

## Prerequisites

- macOS or Linux with admin rights
- A Jira instance with API access
- A Git repository to work on
- Claude Code CLI (or Codex/Cursor/Gemini)

## Step 1: Install Gas City

**macOS:**
```bash
# One command installs everything (Gas City, beads, dolt, tmux, jq, git)
brew install gastownhall/gascity/gascity

# Verify
gc version
bd --version
dolt version
```

**Linux (Ubuntu/Debian):**
```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y tmux git jq procps lsof util-linux

# Install Dolt
sudo curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | sudo bash

# Build and install beads + Gas City
git clone https://github.com/gastownhall/beads.git /tmp/beads
cd /tmp/beads && make install

git clone https://github.com/gastownhall/gascity.git /tmp/gascity
cd /tmp/gascity && make install

# Verify
gc version
bd --version
```

## Step 2: Initialize Your City

The `gc init` wizard sets up everything interactively:

```bash
# Create city workspace
gc init ~/my-software-factory

# Follow the wizard:
# - Choose "tutorial" template (sets up Claude Code agent by default)
# - Accept default paths
# - Let it configure the beads backend

# Verify city is running
gc status
```

**What this creates:**
- `~/my-software-factory/city.toml` - Main config
- `~/my-software-factory/orders/` - Automation definitions
- `~/my-software-factory/.gc/` - Runtime state
- Dolt server running on port 3307 (default)

## Step 3: Add Your Repository

Point Gas City to your actual codebase:

```bash
# Add your repo as a rig (name auto-derived from directory)
cd ~/my-actual-project
gc rig add .

# Verify
gc rig list
```

**Important:** Rigs stay at their original filesystem location—Gas City doesn't copy or move them.

## Step 4: Configure Jira Sync

Set up beads to sync with your Jira instance:

```bash
# Configure Jira connection
bd config set jira.url "https://your-company.atlassian.net"
bd config set jira.username "your-email@company.com"
bd config set jira.api_token "your-jira-api-token"
bd config set jira.project "PROJ"  # Your Jira project key

# Test connection
bd jira sync --pull --dry-run

# If successful, do real sync
bd jira sync --pull
```

**Get your Jira API token:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create API token
3. Use it in the `bd config set` command above

## Step 5: Create the Jira Sync Order

Orders are Gas City's automation primitive. Create one to periodically sync Jira:

```bash
cd ~/my-software-factory

# Create order directory
mkdir -p orders/jira-sync

# Create order config
cat > orders/jira-sync/order.toml << 'EOF'
# Periodic Jira sync order
interval = "5m"  # Run every 5 minutes

[exec]
# Pull new tickets from Jira
command = "bd jira sync --pull"

[gate.cooldown]
# Don't run more than once per minute (safety)
duration = "1m"
EOF

# Verify order is recognized
gc order list
```

**What this does:**
- Every 5 minutes, Gas City runs `bd jira sync --pull`
- New Jira tickets become beads in Gas City
- Cooldown gate prevents excessive API calls

## Step 6: Configure Agent for Auto-Implementation

Edit `~/my-software-factory/city.toml` to set up your coding agent:

```toml
# Find the [[agent]] section (created by gc init wizard)
[[agent]]
name = "dev-agent"
dir = "my-actual-project"    # Must match your rig name
provider = "claude"           # Or: codex, cursor, gemini
idle_timeout = "4h"

# Enable auto-implementation (requires formula configuration)
# See Step 7
```

**Provider auth:**
```bash
# Claude Code
export ANTHROPIC_API_KEY="sk-ant-..."

# Codex (if using)
# export CODEX_API_KEY="..."

# Verify agent can start
gc session list
```

## Step 7: Create Auto-Implementation Formula

Formulas define agent workflows. Create one that implements beads automatically:

```bash
cd ~/my-software-factory

# Create formulas directory if needed
mkdir -p formulas

# Create auto-implement formula
cat > formulas/auto-implement.toml << 'EOF'
# Auto-implementation formula
# Routes ready beads to coding agent

[[step]]
# Check if bead is ready (no blockers, in "Todo" state)
type = "check"
condition = "state == 'Todo' && !blocked"

[[step]]
# Route to dev-agent
type = "sling"
target = "dev-agent"

[[step]]
# Agent implements (autonomous coding)
type = "implement"
auto_commit = true

[[step]]
# Push changes
type = "exec"
command = "git push origin HEAD"

[[step]]
# Update bead state
type = "transition"
state = "Done"
EOF
```

## Step 8: Link Formula to Jira-Synced Beads

Configure beads created from Jira to automatically trigger the formula:

```bash
# Edit beads config
bd config set formula.auto "auto-implement"

# Or: add label-based routing
bd config set formula.on_label "auto-implement=auto-implement"

# Verify
bd config list | grep formula
```

**What this means:**
- New beads from Jira with label "auto-implement" → formula triggers
- Or: all new beads → formula triggers (if using `formula.auto`)

## Step 9: Test End-to-End

Time to verify the full pipeline works:

### 9.1: Create Test Jira Ticket

In your Jira instance:
1. Create a new ticket in your project
2. Set status to "Todo"
3. Add label "auto-implement" (if using label-based routing)
4. Description: "Add a hello world function to utils.py"

### 9.2: Watch It Flow

```bash
# Watch for Jira sync (should happen within 5 minutes)
gc events --follow

# Check if bead was created
bd list --state Todo

# Check if agent picked it up
gc session list

# Watch agent session
gc session peek dev-agent

# Check for new commits
cd ~/my-actual-project
git log --oneline -5
```

### 9.3: Verify Jira Update

Check your Jira ticket—it should now have:
- Comment from Gas City with commit link
- Status updated to "Done" (or your configured state)

## Step 10: Monitor & Iterate

```bash
# View all automation activity
gc events --since 1h

# Check order execution history
gc order logs jira-sync

# View agent logs
gc session logs dev-agent

# Check beads state
bd list --state all
```

## Troubleshooting

### Jira sync not running

```bash
# Check order status
gc order list

# Check cooldown gate (might be preventing execution)
gc order inspect jira-sync

# Manually trigger
bd jira sync --pull
```

### Agent not picking up beads

```bash
# Check formula configuration
cat ~/my-software-factory/formulas/auto-implement.toml

# Verify beads have correct label/state
bd list --state Todo

# Check agent is running
gc session list

# Manually sling bead to agent
gc sling dev-agent "tp-xyz"  # Use actual bead ID
```

### Commits not pushing

```bash
# Check git credentials
cd ~/my-actual-project
git push origin HEAD

# Verify agent has git access
gc session attach dev-agent
# Inside agent session:
git config --list | grep user
```

### Formula not triggering

```bash
# Check beads config
bd config list | grep formula

# Verify order is running
gc order logs jira-sync

# Check events for formula evaluation
gc events | grep formula
```

## What You've Built

You now have a fully autonomous software development pipeline:

1. **Jira ticket created** → `bd jira sync --pull` (every 5 min)
2. **Bead created in Gas City** → formula evaluates conditions
3. **Formula routes to agent** → `gc sling dev-agent <bead>`
4. **Agent implements changes** → Claude Code writes code
5. **Auto-commit and push** → changes appear in Git
6. **Jira updated automatically** → ticket status changes, comment added

## Next Steps

### Scale Up

```bash
# Add more agents for parallelism
# Edit city.toml:
[[agent]]
name = "dev-agent-2"
dir = "my-actual-project"
provider = "claude"

[agent.pool]
min = 1
max = 5  # Auto-scale up to 5 agents
```

### Add More Orders

```bash
# Example: Run tests after implementation
mkdir -p orders/run-tests
cat > orders/run-tests/order.toml << 'EOF'
interval = "10m"

[exec]
command = "cd ~/my-actual-project && make test"

[gate.event]
type = "bead.closed"
EOF
```

### Multi-Rig Setup

```bash
# Add another repository
cd ~/my-frontend-repo
gc rig add .

# Add rig-specific agent
# Edit city.toml:
[[agent]]
name = "frontend-agent"
dir = "my-frontend-repo"
provider = "claude"
```

### Custom Formulas

Create specialized formulas for different types of work:

```bash
# Example: bug-fix formula (higher priority)
cat > formulas/bug-fix.toml << 'EOF'
[[step]]
type = "check"
condition = "labels contains 'bug'"

[[step]]
type = "sling"
target = "dev-agent"
priority = "high"

[[step]]
type = "implement"
auto_commit = true
EOF
```

## Reference Commands

**City Management:**
```bash
gc start              # Start city supervisor
gc stop               # Stop city
gc status             # Show city status
gc events             # View event log
```

**Rig Management:**
```bash
gc rig add <path>     # Add repository
gc rig list           # List rigs
gc rig remove <name>  # Remove rig
```

**Order Management:**
```bash
gc order list         # List orders
gc order logs <name>  # View order execution logs
gc order inspect <name> # Show order details
```

**Agent/Session Management:**
```bash
gc session list       # List active sessions
gc session attach <name>  # Attach to agent session (tmux)
gc session logs <name>    # View agent logs
gc session peek <name>    # View agent output
```

**Beads Management:**
```bash
bd list                    # List beads
bd show <id>              # Show bead details
bd jira sync --pull       # Sync from Jira
bd config set <key> <val> # Configure beads
```

**Sling (Manual Work Routing):**
```bash
gc sling <target> <bead-or-text>  # Route work to agent
# Example: gc sling dev-agent "tp-abc"
# Example: gc sling dev-agent "Implement login feature"
```

## Resources

- [Gas City Documentation](https://docs.gascityhall.com)
- [Gas City Repository](https://github.com/gastownhall/gascity)
- [Beads Documentation](https://github.com/gastownhall/beads)
- [Coming from Gas Town Guide](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/coming-from-gastown.md)

## Advanced Topics

For production deployments, multi-team setups, and advanced configuration, see:

- **Packs:** Reusable configuration bundles
- **Provider Configuration:** Custom model parameters, rate limiting
- **Kubernetes Deployment:** Running Gas City at scale
- **Security:** API key management, agent sandboxing
- **Observability:** Metrics, dashboards, alerting

These topics are covered in the full Gas City documentation.

## Contributing

Found an issue? Please open an issue or PR in the [software-factory-intensive](https://github.com/actual-software/software-factory-intensive) repository.

---

**Related:**
- SRAI-1657: Gas City PoC demo (working implementation)
- SRAI-1685: This setup guide
- `examples/jira-aider-poc.py`: Pre-Gas City validation script
