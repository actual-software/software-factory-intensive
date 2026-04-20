# `factory-activity-agent` — Installation & Command Reference

The **factory-activity-agent** skill is a wrapper over `gc` plus Python scaffolding. It exposes seven commands that you will re-use across most sessions in the curriculum. This page is the reference for how to install it and what each command does under the hood.

Each command supports a `--dry-run` flag that prints every command the wrapper would execute without running them — use it any time you want to see what a command is about to do before it touches your machine.

---

## Installation

The factory-activity-agent lives in the repo at `skills/factory-activity-agent/`. Install it into your coding agent's skills directory so the slash command is available anywhere. You only need to do this once — every curriculum session after W1 assumes it's on your path.

Pick one of the options below based on your coding agent and scoping preference.

```bash
## Claude Code
cd ~/Projects/actual-software/software-factory-intensive
# Option 1: Symlink into user-level skills (available in all projects)
ln -s "$(pwd)/skills/factory-activity-agent" ~/.claude/skills/factory-activity-agent

# Option 2: Symlink into project-level skills (this project only)
mkdir -p .claude/skills
ln -s "$(pwd)/skills/factory-activity-agent" .claude/skills/factory-activity-agent

# Option 3: Copy into user-level skills
cp -r skills/factory-activity-agent ~/.claude/skills/factory-activity-agent

## Codex
cd ~/Projects/actual-software/software-factory-intensive
ln -sfn "$(pwd)/skills/factory-activity-agent" ~/.codex/skills/factory-activity-agent
```

After installing, restart your coding agent and run `/factory-activity-agent list` in its session. You should see a table of activities (`W1`–`W4`, `L1`–`L4`, `C1`, `B1`) with their install status — every row will say `no` until you install a factory. If the slash command isn't recognized, the symlink didn't resolve; see [Troubleshooting CLI coding agents](../troubleshooting/cli-coding-agents.md).

---

## Command Reference

## `/factory-activity-agent install <activity> [--dry-run]` — stand up a factory for a curriculum activity

The wrapper validates the activity name, pre-flight-checks `gc` and `python3`, then delegates to `scripts/factory_activity_agent.py install <activity>`. Always run a `--dry-run` first if you're unsure what it's about to do — the dry-run prints every command without executing.

## `/factory-activity-agent delete <activity> [--dry-run]` — delete a factory for a curriculum activity

This command deletes the factory for the given activity. This is helpful if you want to start fresh or if you want to delete a factory that is causing issues.

## `/factory-activity-agent status <activity> [--dry-run]` — survey factory and agent health

The wrapper runs `bash skills/factory-activity-agent/scripts/status.sh` from the SFI repo root. It prints the `gc` version, a table of curriculum activities and whether each has a factory directory under `~/Projects/factory/`, the output of `gc cities`, then `gc status --city …` for each installed factory so you can see agents, rigs, and service health. This is read-only. `<activity>` tells the agent which factory you care about when interpreting output; the script summarizes every installed factory.

## `/factory-activity-agent doctor <activity> [--dry-run]` — run Gas City diagnostics (with auto-fix)

The wrapper runs `bash skills/factory-activity-agent/scripts/doctor.sh`. That invokes `gc doctor --fix --city` on each installed factory directory (or on one path if given), checking dependencies, configuration, and authentication and applying fixes where `gc` can. Use this when installs fail mysteriously, agents won’t start, or `gc doctor` reports problems.

## `/factory-activity-agent sling <activity> [--dry-run]` — route work to a factory agent

This maps to `gc sling` for the activity’s rig (e.g. `w1-project/architect`). You run it from that activity’s project or factory directory (or pass the city path) and provide the agent role and a prompt string—`gc` creates or routes a bead so that agent executes the task. Examples in the skill use `planner`, `architect`, `builder`, and `reviewer`.

## `/factory-activity-agent dashboard <activity> [--dry-run]` — start the gc web dashboard

This starts `gc dashboard serve --city` for that activity’s factory directory (for example `~/Projects/factory/workshop_w1/w1-project/`). The dashboard listens on `http://localhost:8080` for monitoring agents and sessions. Only one dashboard can bind that port at a time; stop any other instance first.

## `/factory-activity-agent list <activity> [--dry-run]` — list activities and install status

The wrapper runs `status.sh --list`, which prints the same activity table as `status` (which codes are installed and where the factory dirs live) but skips the detailed per-factory `gc status` sections—useful for a quick “what’s on disk.” You can invoke it as `/factory-activity-agent list` without an activity; `<activity>` is optional context for the agent. This is read-only.
