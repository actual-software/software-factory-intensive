#!/usr/bin/env python3
"""
Autonomous Jira → Aider Integration POC

This script demonstrates a simple autonomous workflow that:
1. Polls Jira for commands tagged with [gas-city-poc]
2. Executes the command via Aider (AI pair programming tool)
3. Posts results back to Jira

This POC was used to validate end-to-end autonomous coding before
full Gas City integration. It's included here as a reference for
understanding how to integrate external tools with coding agents.

Configuration:
- JIRA_URL: Your Atlassian instance URL
- JIRA_EMAIL: Your Jira user email
- JIRA_API_TOKEN: API token from Atlassian (set via environment variable)
- ISSUE_KEY: The Jira issue to monitor for commands
- AIDER_MODEL: The AI model to use (AWS Bedrock in this example)

Usage:
  export JIRA_API_TOKEN="your-token"
  python3 jira-aider-poc.py

For continuous operation:
  */5 * * * * cd /path/to/repo && python3 jira-aider-poc.py >> ~/poc.log 2>&1

Note: In Gas City, this workflow would be implemented using:
- Orders (for the polling/scheduling)
- Formulas (for the agent work definition)
- Beads (for work state tracking)
- gc sling (for routing work to agents)
"""

import os
import sys
import json
import subprocess
import requests
from datetime import datetime
from pathlib import Path

# Configuration
JIRA_URL = "https://ravenai.atlassian.net"
JIRA_EMAIL = "austin@actual.ai"
JIRA_TOKEN = os.getenv("JIRA_API_TOKEN")
ISSUE_KEY = "SRAI-1685"
STATE_FILE = Path.home() / ".openclaw/workspace/.jira-aider-state.json"
REPO_PATH = Path.home() / ".openclaw/workspace/software-factory-intensive"
AWS_REGION = "us-east-1"
AIDER_MODEL = "bedrock/us.anthropic.claude-sonnet-4-5-20250929-v1:0"

def load_state():
    """Load last processed comment ID"""
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"last_comment_id": None}

def save_state(state):
    """Save last processed comment ID"""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def get_latest_command():
    """Fetch latest [gas-city-poc] command from Jira"""
    if not JIRA_TOKEN:
        print("ERROR: JIRA_API_TOKEN not set", file=sys.stderr)
        sys.exit(1)
    
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    url = f"{JIRA_URL}/rest/api/3/issue/{ISSUE_KEY}/comment"
    response = requests.get(url, auth=(JIRA_EMAIL, JIRA_TOKEN), headers=headers)
    response.raise_for_status()
    
    comments = response.json().get("comments", [])
    
    # Find latest [gas-city-poc] comment
    poc_comments = []
    for comment in comments:
        comment_text = ""
        for content_block in comment.get("body", {}).get("content", []):
            for item in content_block.get("content", []):
                if item.get("type") == "text":
                    comment_text += item.get("text", "")
        
        if "[gas-city-poc]" in comment_text:
            poc_comments.append({
                "id": comment["id"],
                "text": comment_text.replace("[gas-city-poc]", "").strip(),
                "created": comment["created"]
            })
    
    if not poc_comments:
        return None
    
    # Return most recent
    return sorted(poc_comments, key=lambda x: x["created"])[-1]

def post_jira_comment(message):
    """Post acknowledgment to Jira"""
    url = f"{JIRA_URL}/rest/api/3/issue/{ISSUE_KEY}/comment"
    payload = {
        "body": {
            "type": "doc",
            "version": 1,
            "content": [{
                "type": "paragraph",
                "content": [{"type": "text", "text": message}]
            }]
        }
    }
    
    response = requests.post(
        url,
        auth=(JIRA_EMAIL, JIRA_TOKEN),
        headers={"Content-Type": "application/json"},
        json=payload
    )
    response.raise_for_status()
    return response.json()

def run_aider(command):
    """Execute Aider with the given command"""
    os.chdir(REPO_PATH)
    
    env = os.environ.copy()
    env["AWS_REGION"] = AWS_REGION
    env["PATH"] = str(Path.home() / ".local/bin") + ":" + env.get("PATH", "")
    
    aider_cmd = [
        str(Path.home() / ".local/bin/aider"),
        "--model", AIDER_MODEL,
        "--yes",
        "--auto-commits",
        "--no-show-model-warnings",
        "--message", command
    ]
    
    print(f"[{datetime.utcnow().isoformat()}] Running: {' '.join(aider_cmd)}")
    
    result = subprocess.run(
        aider_cmd,
        env=env,
        capture_output=True,
        text=True,
        timeout=300  # 5 minute timeout
    )
    
    return {
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr
    }

def main():
    print(f"[{datetime.utcnow().isoformat()}] Checking Jira for [gas-city-poc] commands...")
    
    state = load_state()
    latest = get_latest_command()
    
    if not latest:
        print(f"[{datetime.utcnow().isoformat()}] No [gas-city-poc] commands found")
        return
    
    if latest["id"] == state.get("last_comment_id"):
        print(f"[{datetime.utcnow().isoformat()}] No new commands (last: {latest['id']})")
        return
    
    print(f"[{datetime.utcnow().isoformat()}] New command detected!")
    print(f"  Comment ID: {latest['id']}")
    print(f"  Command: {latest['text']}")
    
    # Post acknowledgment
    ack_message = f"🤖 Autonomous workflow started: {latest['text'][:100]}..."
    post_jira_comment(ack_message)
    print(f"[{datetime.utcnow().isoformat()}] Posted acknowledgment to Jira")
    
    # Run Aider
    print(f"[{datetime.utcnow().isoformat()}] Executing Aider...")
    result = run_aider(latest["text"])
    
    # Post result
    if result["returncode"] == 0:
        result_message = f"✅ Task completed successfully!\n\nAider output:\n```\n{result['stdout'][-500:]}\n```"
    else:
        result_message = f"❌ Task failed with exit code {result['returncode']}\n\nError:\n```\n{result['stderr'][-500:]}\n```"
    
    post_jira_comment(result_message)
    print(f"[{datetime.utcnow().isoformat()}] Posted result to Jira")
    
    # Save state
    state["last_comment_id"] = latest["id"]
    save_state(state)
    print(f"[{datetime.utcnow().isoformat()}] Workflow complete!")

if __name__ == "__main__":
    main()
