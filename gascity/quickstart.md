# Gascity Quickstart

## Prerequisites

* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md

```bash
mkdir -p ~/Projects/actual-software
pushd ~/Projects/actual-software
git clone git@github.com:actual-software/software-factory-intensive.git
git checkout david/refine_agents_3
```

## Quick Guide

### GasCity Setup

```bash
brew update
brew upgrade gascity
which gc
gc version
```

```bash
mkdir -p ~/Projects/factory/20260415-gc-factory-v1
mkdir -p ~/Projects/factory/20260415-project-v1
```

#### Setup Project

```bash
pushd ~/Projects/factory/20260415-project-v1
git init
```

#### Setup Factory

```bash
gc init ~/Projects/factory/20260415-gc-factory-v1
```

```
Welcome to Gas City SDK!

Choose a config template:
  1. tutorial  — default coding agent (default)
  2. gastown   — multi-agent orchestration pack
  3. custom    — empty workspace, configure it yourself
Template [1]: 3
```

```
[1/8] Creating runtime scaffold
[2/8] Installing hooks (Claude Code)
[3/8] Writing default prompts
[4/8] Writing default formulas
[5/8] Writing city configuration
Created custom config (Level 1) in "20260415-gc-factory-v1".
[6/8] Checking provider readiness
[7/8] Registering city with supervisor
Registered city '20260415-gc-factory-v1' (/Users/david_miura_actual_ai/Projects/factory/20260415-gc-factory-v1)
Installed launchd service: /Users/david_miura_actual_ai/Library/LaunchAgents/com.gascity.supervisor.plist
[8/8] Waiting for supervisor to start city
```

```bash
pushd ~/Projects/factory/20260415-gc-factory-v1
cp ~/Projects/actual-software/software-factory-intensive/packs/city.toml .
rsync -av ~/Projects/actual-software/software-factory-intensive/packs/ packs/actual/

gc service restart
gc status
gc doctor
```

Console: 

```
20260415-gc-factory-v1  /Users/david_miura_actual_ai/Projects/factory/20260415-gc-factory-v1
  Controller: standalone (PID 62518)
  Suspended:  no

Agents:
  dog                     pool (min=0, max=3)
2026/04/15 14:42:41 tmux state cache: refresh failed in 3.260917ms: no tmux server running
    dog-1                 stopped
2026/04/15 14:42:41 tmux state cache: refresh failed in 3.085875ms: no tmux server running
2026/04/15 14:42:42 tmux state cache: refresh failed in 3.327709ms: no tmux server running
    dog-2                 stopped
2026/04/15 14:42:42 tmux state cache: refresh failed in 2.657166ms: no tmux server running
2026/04/15 14:42:42 tmux state cache: refresh failed in 4.096417ms: no tmux server running
    dog-3                 stopped
2026/04/15 14:42:42 tmux state cache: refresh failed in 3.690792ms: no tmux server running
  claude                  pool (min=0, max=unlimited)

0/3 agents running
  ✓ city-structure — city.toml present
  ✓ city-config — city.toml loaded (0 agents, 0 rigs)
  ✓ config-valid — agents, rigs, and services valid
  ✓ config-refs — all config references valid
  ✓ builtin-pack-family — builtin bd/dolt pack family unmodified
  ✓ config-semantics — config semantics valid
  ✓ duration-range — all durations within reasonable bounds
  ✓ system-formulas — all 1 system formula(s) present
  ✓ tmux-binary — found /opt/homebrew/bin/tmux
  ✓ git-binary — found /opt/homebrew/bin/git
  ✓ jq-binary — found /opt/homebrew/bin/jq
  ✓ pgrep-binary — found /usr/bin/pgrep
  ✓ lsof-binary — found /usr/sbin/lsof
  ✓ controller — controller running (sessions managed)
  ✓ beads-store — store accessible
  ✓ dolt-server — reachable on 127.0.0.1:47139
  ✓ events-log — events.jsonl exists and writable
  ✓ events-log-size — events.jsonl size: 26.0 KB
  ✓ custom-types:city — all 11 required types registered
  ✓ rig-index — all 0 rigs in global index with correct .beads/.env
  ✓ worktrees — no worktrees directory
  ✓ actual-architect:check-architect — ok
  ✓ actual-planner:check-planner — ok
  ✓ actual-designer:check-designer — ok
  ✓ actual-validator:check-validator — ok
  ✓ actual-builder:check-builder — ok
  ✓ actual-reviewer:check-reviewer — ok
  ✓ actual-release-gate:check-release-gate — ok
  ✓ actual-improver:check-improver — ok
  ✓ maintenance:check-binaries — all required binaries available (jq, gh)
  ✓ dolt:check-dolt — dolt available (dolt version 1.86.1), flock ok, lsof ok
  ✓ bd:check-bd — bd bd version 1.0.0 (Homebrew)
```


#### Add "Rig" ie Project Source Repo to Factory

```bash
pushd ~/Projects/factory/20260415-gc-factory-v1
gc rig add ~/Projects/factory/20260415-project-v1
```

Edit `city.toml`

```toml
[[rigs]]
name = ...
path = ...
includes = ["packs/actual/all"]
```

#### Register City

```bash
gc register ~/Projects/factory/20260415-gc-factory-v1
```

Console:

```bash
  ✓ city-structure — city.toml present
  ✓ city-config — city.toml loaded (0 agents, 1 rigs)
  ✓ config-valid — agents, rigs, and services valid
  ✓ config-refs — all config references valid
  ✓ builtin-pack-family — builtin bd/dolt pack family unmodified
  ✓ config-semantics — config semantics valid
  ✓ duration-range — all durations within reasonable bounds
  ✓ system-formulas — all 1 system formula(s) present
  ✓ tmux-binary — found /opt/homebrew/bin/tmux
  ✓ git-binary — found /opt/homebrew/bin/git
  ✓ jq-binary — found /opt/homebrew/bin/jq
  ✓ pgrep-binary — found /usr/bin/pgrep
  ✓ lsof-binary — found /usr/sbin/lsof
  ✓ controller — controller running (sessions managed)
  ✓ beads-store — store accessible
  ✓ dolt-server — reachable on 127.0.0.1:47139
  ✓ events-log — events.jsonl exists and writable
  ✓ events-log-size — events.jsonl size: 26.1 KB
  ✓ custom-types:city — all 11 required types registered
  ✓ rig:20260415-project-v1:path — path "/Users/david_miura_actual_ai/Projects/factory/20260415-project-v1" exists
  ✓ rig:20260415-project-v1:git — git repository
  ✓ rig:20260415-project-v1:beads — store accessible
  ✓ custom-types:20260415-project-v1 — all 11 required types registered
  ✓ rig-index — all 1 rigs in global index with correct .beads/.env
  ✓ worktrees — no worktrees directory
  ✓ actual-architect:check-architect — ok
  ✓ actual-planner:check-planner — ok
  ✓ actual-designer:check-designer — ok
  ✓ actual-validator:check-validator — ok
  ✓ actual-builder:check-builder — ok
  ✓ actual-reviewer:check-reviewer — ok
  ✓ actual-release-gate:check-release-gate — ok
  ✓ actual-improver:check-improver — ok
  ✓ maintenance:check-binaries — all required binaries available (jq, gh)
  ✓ dolt:check-dolt — dolt available (dolt version 1.86.1), flock ok, lsof ok
  ✓ bd:check-bd — bd bd version 1.0.0 (Homebrew)

36 passed
```

bash
```
pushd ~/Projects/factory/20260415-gc-factory-v1
gc start
gc restart
```

#### Serve Gascity Dashboard

bash
```
pushd ~/Projects/factory/20260415-gc-factory-v1
gc dashboard serve
```

##### Gascity Dashboard

* http://localhost:8080

#### Create First Task for Factory

bash
```
pushd ~/Projects/factory/20260415-project-v1
gc sling 20260415-project-v1--architect "Create a script that prints hello world"
gc sling 20260415-hello-world-v0/architect "Create a nextjs web site with hello world home page."
```

## References

* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/quickstart.md
* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/coming-from-gastown.md
