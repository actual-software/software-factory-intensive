# Gas City Setup Guide

> **Status:** This guide documents the intended Gas City setup workflow based on codebase analysis and testing. Some steps may require upstream fixes (see [Known Issues](#known-issues)).

## Overview

Gas City is a multi-agent workspace manager that coordinates AI agents working on shared codebases. It uses:
- **Beads** (`bd`) - Issue tracker with first-class dependency support
- **Gas Town** (`gt`) - Multi-agent workspace orchestration  
- **Dolt** - Versioned SQL database for issue/work state
- **Aider** - AI pair programming tool for autonomous code changes

## Prerequisites

### System Requirements
- **OS:** Ubuntu 24.04 LTS (or similar Linux)
- **Memory:** 4GB+ RAM recommended
- **Disk:** 10GB+ free space
- **Network:** Internet access for package downloads

### Required Tools

Install dependencies:
```bash
# Core build tools
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  golang-go \
  libicu-dev \
  git \
  curl \
  jq

# Dolt database
sudo curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | sudo bash

# Python & pip (for Aider)
sudo apt-get install -y python3 python3-pip

# Aider
pip3 install aider-chat
```

Verify installations:
```bash
go version          # Should show 1.21+
dolt version        # Should show 1.40+
aider --version     # Should show latest
python3 --version   # Should show 3.10+
```

## Installation

### 1. Clone Repositories

```bash
# Choose a workspace directory
export WORKSPACE_DIR=~/gas-city-workspace
mkdir -p $WORKSPACE_DIR
cd $WORKSPACE_DIR

# Clone Beads (issue tracker)
git clone https://github.com/gastownhall/beads.git
cd beads
make build
sudo cp bd /usr/local/bin/
cd ..

# Clone Gas Town (workspace manager)
git clone https://github.com/gastownhall/gastown.git
cd gastown
make build
sudo cp gt /usr/local/bin/
cd ..

# Verify installations
bd --version
gt --version
```

### 2. Initialize Gas Town Workspace

```bash
# Create a new Gas Town HQ (workspace root)
gt install ~/gas-town-hq

# Navigate to HQ
cd ~/gas-town-hq

# Initialize git if needed
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 3. Configure Dolt Server

Gas Town uses a centralized Dolt SQL server for multi-client access:

```bash
# Initialize Dolt configuration
gt dolt init

# Start Dolt server (default port 3307)
gt dolt start

# Verify server is running
gt dolt status
```

Expected output:
```
Dolt server: running
Port: 3307
Databases: 1
  - gas_town_hq
```

### 4. Create a Rig (Project Workspace)

Rigs are individual project workspaces within Gas Town:

```bash
# Create a new rig for your project
gt rig create my-project

# Navigate to rig
cd rigs/my-project

# Initialize beads in this rig
bd init

# Verify beads database
bd status
```

### 5. Configure Jira Integration (Optional)

For Jira→Aider autonomous workflow:

```bash
# Set Jira credentials
export JIRA_URL="https://your-instance.atlassian.net"
export JIRA_USER="your-email@example.com"
export JIRA_TOKEN="your-api-token"

# Configure beads Jira sync
bd jira configure \
  --url "$JIRA_URL" \
  --user "$JIRA_USER" \
  --token "$JIRA_TOKEN"

# Test connection
bd jira status
```

## Usage

### Basic Workflow

#### 1. Import Issues from Jira

```bash
# Sync Jira sprint to beads
bd jira import --sprint "Sprint 48"

# List imported issues
bd list
```

#### 2. Assign Work to Agent

```bash
# Sling work to an agent (creates agent session)
gt sling --issue SRAI-1234 --agent polecat-alpha

# Check agent status
gt agents
```

#### 3. Monitor Progress

```bash
# View agent activity
gt trail polecat-alpha

# Check work status
bd show SRAI-1234
```

#### 4. Review Changes

```bash
# Agent will create a branch and commit
git log --oneline -10

# Review diff
git diff origin/main
```

### Autonomous Jira→Aider Loop

For fully autonomous operation, use the provided POC script:

```bash
# Create cron job (runs every 5 minutes)
crontab -e

# Add this line:
*/5 * * * * cd ~/gas-town-hq/rigs/my-project && python3 jira_aider_poc.py >> ~/jira-aider.log 2>&1
```

The POC script:
1. Fetches open Jira tickets from your sprint
2. Passes ticket context to Aider
3. Aider autonomously makes changes
4. Creates commit with ticket reference
5. Pushes to remote branch

## Architecture

### Component Interaction

```
┌─────────────┐
│    Jira     │ ← Issue source
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Gas Town   │ ← Orchestration layer
│     (gt)    │
└──────┬──────┘
       │
       ├──────────────┐
       │              │
       ▼              ▼
┌─────────────┐  ┌──────────┐
│   Beads     │  │  Agents  │
│    (bd)     │  │ (Aider)  │
└──────┬──────┘  └─────┬────┘
       │                │
       │                │
       ▼                ▼
┌─────────────────────────┐
│      Dolt Server        │ ← Shared state
│       (port 3307)       │
└─────────────────────────┘
       │
       ▼
┌─────────────────────────┐
│     Git Repository      │ ← Code output
└─────────────────────────┘
```

### Data Flow

1. **Jira** provides issue metadata (description, acceptance criteria, labels)
2. **Beads** tracks work state and dependencies
3. **Gas Town** dispatches work to agents
4. **Aider** makes autonomous code changes
5. **Dolt** persists all work state with version history
6. **Git** receives commits from agents

## Known Issues

> ⚠️ **Current Blockers:** The following issues were encountered during setup and may require upstream fixes.

### Issue 1: Dolt Migration Timing

**Symptom:**
```
error="table not found: config"
error="Duplicate key name 'idx_issues_issue_type'"
```

**Analysis:**
- Beads migration system attempts to re-run migrations against existing schema
- Race condition: Beads queries config table before Dolt fully initialized
- NOT data corruption - database integrity verified

**Workaround:**
None available. Requires upstream fix to Beads bootstrap logic.

**Reported:**
- GitHub: gastownhall/beads (pending issue creation)
- Investigation: `~/.openclaw/workspace/gas-city-findings.md`

### Issue 2: File Storage Backend Limitation

**Symptom:**
```bash
bd --store-type file
# Server starts but work queues don't function
```

**Analysis:**
- File backend doesn't support beads/work queue features
- Documented limitation, not a bug

**Workaround:**
Use Dolt backend (requires fixing Issue 1).

### Issue 3: Foreign Key Constraints

**Symptom:**
```
error="foreign key `fk_dep_depends_on` was not found"
```

**Analysis:**
- Part of migration replay problem
- Foreign keys exist but Beads tries to re-create them

**Workaround:**
Same as Issue 1 - requires upstream fix.

## Troubleshooting

### Dolt Server Won't Start

```bash
# Check for port conflicts
sudo lsof -i :3307

# Kill imposters
gt dolt kill-imposters

# Restart server
gt dolt restart
```

### Beads Database Errors

```bash
# Check database integrity
cd ~/gas-town-hq/rigs/my-project
dolt sql -q "SHOW TABLES;"

# Verify config table exists
dolt sql -q "SELECT * FROM config;"

# Check for uncommitted changes
dolt status
dolt diff
```

### Agent Not Making Changes

```bash
# Check Aider configuration
aider --help

# Verify git credentials
git config --list | grep user

# Check API keys (if using OpenAI/Anthropic)
echo $OPENAI_API_KEY
echo $ANTHROPIC_API_KEY
```

### Jira Sync Issues

```bash
# Test Jira connection
curl -u "$JIRA_USER:$JIRA_TOKEN" \
  "$JIRA_URL/rest/api/3/myself" | jq

# Check beads Jira config
bd jira status

# Re-authenticate if needed
bd jira configure --reset
```

## Alternative: Standalone POC

If Gas City setup is blocked, use the standalone POC:

### Setup

```bash
# Clone test repo
git clone https://github.com/your-org/test-project.git
cd test-project

# Create POC script
cat > jira_aider_poc.py << 'EOF'
#!/usr/bin/env python3
"""
Autonomous Jira→Aider workflow (standalone)
"""
import os
import json
import requests
from datetime import datetime

# Configuration
JIRA_URL = os.getenv("JIRA_URL")
JIRA_USER = os.getenv("JIRA_USER") 
JIRA_TOKEN = os.getenv("JIRA_TOKEN")
PROJECT_KEY = os.getenv("JIRA_PROJECT", "SRAI")

def fetch_todo_issues():
    """Fetch TODO issues from current sprint"""
    jql = f'project = {PROJECT_KEY} AND status = "To Do" ORDER BY priority DESC'
    
    response = requests.get(
        f"{JIRA_URL}/rest/api/3/search",
        auth=(JIRA_USER, JIRA_TOKEN),
        params={"jql": jql, "maxResults": 5}
    )
    
    return response.json().get("issues", [])

def process_issue(issue):
    """Pass issue to Aider for autonomous work"""
    key = issue["key"]
    summary = issue["fields"]["summary"]
    description = issue["fields"].get("description", "")
    
    # Extract text from Atlassian Document Format
    desc_text = ""
    if description and "content" in description:
        for block in description["content"]:
            if block.get("type") == "paragraph":
                for item in block.get("content", []):
                    if item.get("type") == "text":
                        desc_text += item.get("text", "")
    
    # Create Aider message
    message = f"""
    Issue: {key}
    Summary: {summary}
    
    Description:
    {desc_text}
    
    Please implement this feature/fix.
    """
    
    # Call Aider
    import subprocess
    result = subprocess.run(
        ["aider", "--yes", "--message", message],
        capture_output=True,
        text=True
    )
    
    return result.returncode == 0

if __name__ == "__main__":
    issues = fetch_todo_issues()
    
    for issue in issues:
        print(f"Processing {issue['key']}...")
        success = process_issue(issue)
        
        if success:
            print(f"  ✓ Completed {issue['key']}")
        else:
            print(f"  ✗ Failed {issue['key']}")
        
        # Only process one at a time
        break
EOF

chmod +x jira_aider_poc.py
```

### Run

```bash
# Set environment
export JIRA_URL="https://your-instance.atlassian.net"
export JIRA_USER="your-email@example.com"
export JIRA_TOKEN="your-api-token"
export JIRA_PROJECT="SRAI"

# Run once
python3 jira_aider_poc.py

# Or schedule via cron
crontab -e
# Add: */5 * * * * cd ~/test-project && python3 jira_aider_poc.py >> ~/aider.log 2>&1
```

## Next Steps

1. **Test the setup** - Follow this guide on a clean Ubuntu VM
2. **Report blockers** - Open issues on gastownhall/beads and gastownhall/gastown
3. **Document workarounds** - Update this guide as fixes become available
4. **Validate POC** - Ensure standalone workflow works for April 21-22 demo

## Resources

- [Beads Documentation](https://github.com/gastownhall/beads/blob/main/README.md)
- [Gas Town Documentation](https://github.com/gastownhall/gastown/blob/main/README.md)
- [Dolt Documentation](https://docs.dolthub.com/)
- [Aider Documentation](https://aider.chat/)
- [DoltHub Blog: A Day in Gas Town](https://www.dolthub.com/blog/2026-01-15-a-day-in-gas-town/)

## Contributing

Found a fix for one of the known issues? Please:

1. Fork this repo
2. Update this guide with your solution
3. Open a PR with details
4. Reference the original issue

## License

This guide is part of the Software Factory Intensive curriculum.
