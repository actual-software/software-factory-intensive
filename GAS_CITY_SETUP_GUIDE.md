# Gas City Setup Guide

> **Status:** This guide documents Gas City setup and configuration. Some advanced workflows require beads backend integration that may need additional configuration.

## Overview

Gas City is an orchestration-builder SDK for multi-agent coding workflows. It coordinates AI coding agents working on shared codebases through:

- **Beads** (`bd`) - Issue tracker with dependency support
- **Gas City** (`gc`) - Multi-agent workspace orchestration  
- **Dolt** - Versioned SQL database for work state (or file backend)
- **Coding Agent CLI** - Your choice of Claude, Codex, Gemini, Cursor, or other compatible tools

## Terminology

- **City:** A Gas City workspace (the orchestration instance)
- **Rig:** An individual project workspace within a city
- **Agent:** A configured coding agent session (can be persistent or pooled)
- **Order:** Automated task (exec order runs shell, formula order instantiates agent work)
- **Formula:** Declarative workflow definition for agent-driven tasks
- **Bead:** A work item (issue/task) in the beads tracker

## Prerequisites

### System Requirements
- **OS:** macOS or Ubuntu 24.04 LTS (or similar Linux)
- **Memory:** 4GB+ RAM recommended
- **Disk:** 10GB+ free space
- **Network:** Internet access for package downloads

### Required Tools

**macOS:**
```bash
# Core dependencies (always required)
brew install tmux git jq

# Beads backend (default provider)
brew install dolt flock

# Install beads from releases
brew install gastownhall/beads/beads

# Install Gas City
brew install gastownhall/gascity/gascity
```

**Linux (Ubuntu/Debian):**
```bash
# Core dependencies (always required)
sudo apt-get update
sudo apt-get install -y \
  tmux \
  git \
  jq \
  procps \
  lsof

# Beads backend (default provider)
# Dolt - download from releases
sudo curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | sudo bash

# flock (usually included in util-linux)
sudo apt-get install -y util-linux

# Build beads from source
git clone https://github.com/gastownhall/beads.git /tmp/beads
cd /tmp/beads
make install

# Build Gas City from source
git clone https://github.com/gastownhall/gascity.git /tmp/gascity
cd /tmp/gascity
make install
```

### Coding Agent CLI Tools

Gas City supports multiple coding agent providers. Install at least one:

**Claude Code (Anthropic):**
```bash
# Follow Claude Code installation docs
# Requires API key from Anthropic Console
```

**Codex:**
```bash
# Follow Codex installation docs
```

**Cursor:**
```bash
# Follow Cursor installation docs
```

**Gemini:**
```bash
# Follow Gemini installation docs
```

**Other compatible agents:**
- Check Gas City documentation for provider-specific setup

### Verify Installation

```bash
gc version          # Should show Gas City version
bd --version        # Should show beads version (if using bd provider)
dolt version        # Should show 1.80.0+ (if using bd provider)
tmux -V            # Should show tmux version
git --version      # Should show git version
jq --version       # Should show jq version
```

## Installation & Setup

### 1. Initialize a City

Create your Gas City workspace:

```bash
# Initialize city (workspace)
gc init ~/my-city
cd ~/my-city

# Start the city under supervisor
gc start

# Verify status
gc status
```

### 2. Add Your First Rig

Register a project repository as a rig:

```bash
# Create or navigate to your project
mkdir ~/my-project
cd ~/my-project
git init

# Add it as a rig
gc rig add .

# Or add an existing repo
cd ~/my-city
gc rig add ~/path/to/existing-repo --name my-existing-project
```

### 3. Configure City Settings

Edit `~/my-city/city.toml` to customize your setup:

```toml
# Example: Configure a coding agent
[[agent]]
name = "dev-alpha"
dir = "my-project"           # Rig scope
provider = "claude"          # Or: codex, gemini, cursor
idle_timeout = "4h"

# Configure agent pool for dynamic scaling
[agent.pool]
min = 1
max = 5

# Example: Include Gastown pack (optional - provides mayor, refinery, etc.)
[[rigs]]
name = "my-project"
path = "/absolute/path/to/my-project"
includes = ["packs/gastown"]  # If using Gastown conventions
```

### 4. Configure Coding Agent Provider

Set up authentication for your chosen provider:

**Claude:**
```bash
# Set API key
export ANTHROPIC_API_KEY="your-api-key"

# Or configure in city.toml
```

**Other providers:**
- Follow provider-specific authentication setup
- Some providers may require account configuration via `gc account` (check provider docs)

### 5. Create Work Items

Use beads to track work:

```bash
cd ~/my-city/my-project

# Initialize beads in the rig (if not done)
bd init

# Create a work item
bd create "Implement user authentication"

# List work
bd list

# View details
bd show 1
```

## Usage

### Basic Workflow with Formulas & Orders

Gas City uses **formulas** (agent-driven workflow) and **orders** (automation tasks) for orchestration.

#### Example: Exec Order (No Agent)

For simple shell commands:

```bash
# Create exec order in city.toml or pack
# Example: Automated git fetch
[[order]]
name = "fetch-upstream"
type = "exec"
command = "git fetch origin"
trigger.cron = "*/5 * * * *"  # Every 5 minutes
```

#### Example: Formula Order (Agent Work)

For agent-driven tasks:

```bash
# Define formula that routes work to agents
# Gas City resolves formulas; beads backend executes them

# Sling a bead to an agent with formula
gc sling --issue 1 --agent dev-alpha --formula implement-feature
```

### Work Routing

#### Manual Sling

```bash
# Assign work to a specific agent
gc sling --issue PROJ-123 --agent dev-alpha

# Sling with formula
gc sling --issue PROJ-123 --formula auto-implement
```

#### Attach to Agent Session

```bash
# List active sessions
gc session list

# Attach to agent session (if using Gastown pack)
gc session attach mayor

# Detach: Ctrl-b d (tmux)
```

### Monitor Progress

```bash
# Check city status
gc status

# View events
gc events

# Check bead status
bd show PROJ-123

# Review changes
cd ~/my-city/my-project
git log --oneline
git diff
```

### Automation Patterns

Instead of cron-based external scripts, use Gas City's built-in automation:

#### Pattern 1: Formula-based Automation

Define formulas in your pack or city config that describe agent workflows.

#### Pattern 2: Order-based Automation

Use orders for scheduled or event-triggered work:

```toml
# Example: Periodic issue sync
[[order]]
name = "sync-jira"
type = "exec"
command = "/path/to/jira-sync-script.sh"
trigger.cron = "*/10 * * * *"

# Example: Event-triggered build
[[order]]
name = "run-tests"
type = "exec"
command = "make test"
trigger.event = "bead.closed"
```

## Architecture

### Component Interaction

```
┌──────────────┐
│    Jira /    │ ← Issue source (external)
│  Issue Mgmt  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Gas City    │ ← Orchestration layer
│    (gc)      │   - Routing (sling)
│              │   - Orders (automation)
│              │   - Formulas (workflow)
└──────┬───────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌──────────┐  ┌─────────────┐
│  Beads   │  │ Coding      │
│  (bd)    │  │ Agents      │
│          │  │ (Claude/etc)│
└────┬─────┘  └──────┬──────┘
     │               │
     │               │
     ▼               ▼
┌──────────────────────────┐
│     Dolt / File Store    │ ← Work state backend
│      (or other backend)  │
└──────────────────────────┘
     │
     ▼
┌──────────────────────────┐
│   Git Repository         │ ← Code output
└──────────────────────────┘
```

### Data Flow

1. **External source** (Jira, Linear, manual creation) provides work items
2. **Beads** tracks work state and dependencies
3. **Gas City** orchestrates: routes work via sling, triggers orders, resolves formulas
4. **Coding agent** (Claude, Codex, etc.) makes autonomous code changes
5. **Backend** (Dolt or file) persists work state
6. **Git** receives commits from agents

## Configuration Reference

### City Config (`city.toml`)

Key sections:

```toml
# Rig registration
[[rigs]]
name = "project-name"
path = "/absolute/path"
includes = ["packs/gastown"]  # Optional

# Agent definition
[[agent]]
name = "dev-agent"
dir = "project-name"     # Rig scope
provider = "claude"
idle_timeout = "4h"

[agent.pool]
min = 1
max = 5

# Order definition
[[order]]
name = "cleanup"
type = "exec"
command = "make clean"
trigger.cron = "0 2 * * *"

# Beads backend
[beads]
provider = "bd"  # Or "file" for simpler file-based storage
```

See [Gas City Config Reference](https://docs.gascityhall.com/reference/config) for full details.

### Provider Configuration

Each coding agent provider has specific configuration needs. Consult provider documentation for:
- API key setup
- Model selection
- Rate limiting
- Custom parameters

## Troubleshooting

### City Won't Start

```bash
# Check prerequisites
gc doctor

# Check supervisor status
gc supervisor status

# View supervisor logs
gc supervisor logs

# Restart city
gc stop
gc start
```

### Beads Backend Errors

**If using Dolt backend:**

```bash
# Check Dolt installation
dolt version

# Check database state
cd ~/my-city/my-project
dolt status

# Verify beads connection
bd status
```

**Alternative: Switch to file backend:**

```toml
# In city.toml
[beads]
provider = "file"
```

Note: File backend is simpler but may have feature limitations compared to `bd` provider.

### Agent Not Responding

```bash
# List active sessions
gc session list

# Check specific session
gc session peek <session-name>

# View session logs
gc session logs <session-name>

# Restart agent
gc session stop <session-name>
gc sling --issue <issue-id> --agent <agent-name>
```

### Git/Code Issues

```bash
# Verify git config
git config --list | grep user

# Check working directory state
git status

# Review recent commits
git log --oneline -10

# Check agent work directory
# (defined in city.toml as work_dir for agent)
```

## Integration Patterns

### Jira Integration

Use beads Jira commands or create sync orders:

```bash
# Manual Jira sync (if bd supports it)
bd jira import --sprint "Sprint 48"

# Or: Create sync order
[[order]]
name = "jira-sync"
type = "exec"
command = "/path/to/jira-import-script.sh"
trigger.cron = "*/15 * * * *"
```

### CI/CD Integration

Trigger orders on Git events or schedule tests:

```toml
[[order]]
name = "ci-check"
type = "exec"
command = "make ci"
trigger.event = "bead.ready"
```

### Multi-Rig Setup

```toml
# First rig
[[rigs]]
name = "frontend"
path = "/path/to/frontend"

# Second rig
[[rigs]]
name = "backend"
path = "/path/to/backend"

# Agent scoped to frontend
[[agent]]
name = "fe-dev"
dir = "frontend"
provider = "claude"

# Agent scoped to backend
[[agent]]
name = "be-dev"
dir = "backend"
provider = "codex"
```

## Next Steps

1. **Explore packs** - Check Gas City's pack system for reusable configurations
2. **Define formulas** - Create workflow automation for common tasks
3. **Add orders** - Automate repetitive operations (testing, syncing, cleanup)
4. **Scale agents** - Configure pools for dynamic agent scaling
5. **Monitor & iterate** - Use `gc events` and `gc status` to observe and improve

## Resources

- [Gas City Documentation](https://docs.gascityhall.com)
- [Gas City Repository](https://github.com/gastownhall/gascity)
- [Beads Documentation](https://github.com/gastownhall/beads)
- [Coming from Gas Town Guide](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/coming-from-gastown.md)
- [Gas City Config Reference](https://docs.gascityhall.com/reference/config)

## Contributing

Found an issue or have improvements? Please open an issue or PR in the [software-factory-intensive](https://github.com/actual-software/software-factory-intensive) repository.
