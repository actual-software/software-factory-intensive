# W1 · Run the 6-Agent Software Factory

> **Goal:** Install the curriculum-agent tooling, stand up the Fired-Up Pizza reference factory on your machine, and watch a single feature bead walk through all six agents — `needs-plan` → `needs-architecture` → `needs-design` → `ready-to-build` → `needs-review` → `ready-to-ship` → closed — without a human typing a prompt at any stage.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Workshop |
| **Deliverable** | A running Fired-Up Pizza factory on your machine, with at least one bead visibly re-labelled by each of the six agents and inspectable via the dashboard |

---

## Session workspace note

* **Curriculum-agent source:** `software-factory/curriculum-agent/` — `SKILL.md` is the canonical entry point; `scripts/` hold the thin Bash wrappers (`install.sh`, `status.sh`, `doctor.sh`, `delete.sh`, `diagnose.sh`) that front the Python runner at `scripts/curriculum_agent.py`.
* **Reference project (the "rig" the factory works on):** `software-factory/reference-project/` — a small React + TypeScript + SQLite pizza-restaurant app with `docs/PROJECT_MANIFEST.md`, `tickets.md` (initial backlog), and `package.json` already in place.
* **Fired-Up Pizza pack (what you install into your factory):** `software-factory/packs/fired-up-pizza/` — a composite pack bundling the six agents, plus a doctor check for the reference scaffold and a `tickets.md` importer.
* **Factory workspace (created during this session):** `~/Projects/factory/fired-up-pizza/fup-gc-factory/` — the Gas City `city.toml` + workspace that runs the agents. Every `gc` command below is run from that directory unless otherwise noted.

Nothing in this session is edited in `software-factory/` itself. You install a skill, stand up a factory outside the repo, point it at the shipped reference project, and watch.

**Canonical reference:** before you install anything, read [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md) — it is the authoritative doc for the six labels that drive the factory's handoffs. Every "why did the agent wake now?" question this session surfaces is answered there. Keep it open in a tab.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still run the commands yourself. W1 is the session where participants first *see* the factory move; resist the urge to type prompts or `gc sling` commands to speed things up. Every handoff in this session is supposed to happen on a label flip alone. If the agent tries to skip the wait, stop it and check `gc status` / `bd label list <id>` to confirm the pipeline is moving on its own.

---

## What You'll See Run

```
     tickets.md (FUP-1 … FUP-6)
         │
         ▼  bd create --label needs-plan
┌──────────────────────────────────────────────────────────┐
│  Planner        (consumes needs-plan)                    │
│    decomposes → sets needs-architecture / needs-design / │
│                 ready-to-build on children               │
└────────────┬─────────────────────────────────────────────┘
             │
             ▼  needs-architecture        needs-design
   ┌──────────────────────┐        ┌────────────────────┐
   │  Architect            │        │  Designer          │
   │  writes ADR;          │        │  writes spec;      │
   │  flips → needs-plan   │        │  flips →           │
   │         or            │        │  ready-to-build    │
   │  ready-to-build       │        │                    │
   └──────────┬───────────┘        └─────────┬──────────┘
              │                              │
              └──────────┬───────────────────┘
                         ▼  ready-to-build
              ┌─────────────────────────┐
              │  Coder                  │
              │  implements; commits;   │
              │  flips → needs-review   │
              └──────────┬──────────────┘
                         ▼  needs-review
              ┌─────────────────────────┐
              │  Reviewer               │
              │  verdict: pass →        │
              │    ready-to-ship        │
              │  verdict: changes →     │
              │    ready-to-build       │
              └──────────┬──────────────┘
                         ▼  ready-to-ship
              ┌─────────────────────────┐
              │  Deployer               │
              │  tags; rollback plan;   │
              │  closes bead            │
              └─────────────────────────┘
```

Every transition is a **label flip on the same bead**. No agent writes a durable markdown to hand off to the next. No `gc sling` is run by hand after the initial `needs-plan` label. That is the paradigm — see [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for the full contract.

---

## Prerequisites

Verify each row before starting. If a row fails, fix it before Part 0 — otherwise you'll lose demo time debugging setup.

| Prerequisite | How to verify | If it's missing |
|--------------|---------------|-----------------|
| `gc` CLI pinned to v0.14.1 | `gc version` prints `gascity 0.14.1` | Install the pinned version: see `curriculum-agent/SKILL.md` → *Prerequisites* for the `brew tap-new` + `brew extract` recipe |
| `bd` (beads) CLI on PATH | `bd --version` exits 0 | `bd` ships with `gc`; if missing, `gc doctor --fix` will install it, or follow the beads install docs |
| Python 3.8+ on PATH | `python3 --version` ≥ 3.8 | `brew install python@3.12` (macOS) or your platform's package manager |
| `software-factory-intensive` repo cloned locally | `ls ~/Projects/actual-software/software-factory-intensive/software-factory/packs/fired-up-pizza/README.md` exists | `git clone git@github.com:actual-software/software-factory-intensive.git ~/Projects/actual-software/software-factory-intensive` |
| Claude Code (or Codex) installed | `which claude` (or `codex`) returns a path | See the [top-level README](../../../../README.md) — "Before You Arrive" — for supported CLI coding agents |
| `~/Projects/factory/` exists and is writable | `mkdir -p ~/Projects/factory && ls -ld ~/Projects/factory` | `mkdir -p ~/Projects/factory` |

**If any row fails in the room**, flag it to David — do not spend more than 2 minutes debugging on your own. Getting the factory moving is the point of this session, not debugging installs.

---

## Part 0: Read the Labeled-Beads Protocol (~5 min)

Every question W1 raises — *"why did the Architect wake?" "why did the bead move to `ready-to-build`?" "what does the Coder look at to know it's up?"* — is answered in one short doc. Read it before installing anything, so the rest of the session lands on a foundation.

Open [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md) and skim:

1. The **six canonical labels** table (`needs-architecture`, `needs-plan`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`).
2. The **example lifecycle** walkthrough — the single worked example of a bead walking the factory.
3. The note on **skipping stages** — a pure-backend bead can skip `needs-design`; a hotfix can skip Planner. The labels, not the pipeline DAG, determine the path.

Do not try to memorize. You should come away able to name, for any label, (a) who adds it and (b) who consumes it. Everything you see this session is an instance of that protocol.

> **Inline Insight: Labels are the contract.** Earlier versions of this factory coordinated agents via long-lived markdown documents (`SPEC.md`, `ARCHITECTURE.md`, per-stage hand-off files). That worked single-threaded and fell apart as soon as two beads were in flight. Labels fix it: each bead is one unit of work; its labels are its state; `bd ready --label <x>` is the natural per-agent queue. See `LABELED_BEADS.md` §"Why labels replaced durable markdowns" for the full rationale.

---

## Part 1: Install the `curriculum-agent` Skill (~10 min)

The **curriculum-agent** is the tooling you'll use across every W/L session for setup, teardown, status, and diagnosis. Install it once now; every session after this assumes it is on your path.

### Step 1: Symlink the skill into Claude Code

The curriculum-agent lives in the repo at `software-factory/curriculum-agent/`. Symlink it into your Claude Code skills directory so the slash command is available anywhere:

```bash
cd ~/Projects/actual-software/software-factory-intensive
mkdir -p ~/.claude/skills
ln -sfn "$(pwd)/software-factory/curriculum-agent" ~/.claude/skills/curriculum-agent
```

If you're using Codex instead of Claude Code, swap `~/.claude/skills` for `~/.codex/skills` — same shape. Full install options (project-level symlink, copy, pack overlay) are in [`curriculum-agent/SKILL.md`](../../../curriculum-agent/SKILL.md) → *Installation*.

**Verify.** In Claude Code (or Codex) run:

```
/curriculum-agent list
```

You should see a table of activities (`W1`, `W2`, …, `L5`) with their install status. Every row will say `no` — nothing is installed yet. If the slash command isn't recognized, the symlink didn't resolve; re-check the path.

### Step 2: Learn the four commands you'll use this weekend

The curriculum-agent is a wrapper over `gc` + Python scaffolding. You only need four verbs for W1, and you'll re-use them across every session after this.

#### `install` — stand up a factory for a curriculum activity

```bash
# Run from the SFI repo root
bash software-factory/curriculum-agent/scripts/install.sh <activity> [--dry-run]
```

The wrapper validates the activity name, pre-flight-checks `gc` and `python3`, then delegates to `scripts/curriculum_agent.py install <activity>`. Always run a `--dry-run` first if you're unsure what it's about to do — the dry-run prints every command without executing.

> **Note — fired-up-pizza install route is in flight.** The `install` verb today knows the workshop/lab activities (`W1`–`W4`, `L1`–`L5`). A dedicated `fired-up-pizza` activity is being wired up in a follow-up bead (F4 — `sfi-9iq`). Until that lands, you'll install the Fired-Up Pizza factory with the **manual stand-up** from [`packs/fired-up-pizza/README.md`](../../../packs/fired-up-pizza/README.md) — that's what Part 2 walks you through.

#### `status` — see every registered factory + agent state

```bash
bash software-factory/curriculum-agent/scripts/status.sh
```

Prints: `gc version`, which activities have factory directories on disk, which cities are registered with the supervisor, and — for each installed factory — `gc status` output naming the running agents. First thing to run if anything looks off.

#### `doctor` — diagnose + optionally auto-fix

```bash
bash software-factory/curriculum-agent/scripts/doctor.sh
```

Wraps `gc doctor --fix` with the curriculum-specific checks (binary versions, auth state, registered rigs). Run it after any install; run it again whenever `gc status` shows a red agent.

#### `dashboard` — web UI for the factory

```bash
gc dashboard serve --city ~/Projects/factory/fired-up-pizza/fup-gc-factory
```

Serves `http://localhost:8080`. Shows the bead queue per label, live agent sessions, event log, and lets you watch a feature move through the pipeline in real time. This is the single most useful observability surface in the workshop — keep it open in a tab any time a factory is running.

### Step 3: Commit muscle memory

You will run each of these four verbs at least once before lunch on Day 1 and on most Day-2 sessions. Three sanity checks to do right now before moving on:

```bash
bash software-factory/curriculum-agent/scripts/install.sh W1 --dry-run   # preview — does not run
bash software-factory/curriculum-agent/scripts/status.sh                 # nothing installed yet; still prints the frame
bash software-factory/curriculum-agent/scripts/doctor.sh                 # confirms gc / python / bd are green
```

If all three print something reasonable, the tooling is ready. Move on.

---

## Part 2: Install the Fired-Up Pizza Factory (~15 min)

> **Agent Guide:** Resist the urge to paraphrase the commands below for the participant. The manual stand-up is deliberately explicit — every line is one of the Gas City primitives a later session will dissect (`gc init`, `gc register`, `gc rig add`, `gc start`). If the participant asks "can you do this for me?", the right answer is *"no — you need to see which command produced which piece of state."*

The canonical install path ([`packs/fired-up-pizza/README.md`](../../../packs/fired-up-pizza/README.md) → *Manual stand-up*) is five commands. Walk through them from the top.

### Step 1: Create the factory workspace directory

```bash
mkdir -p ~/Projects/factory/fired-up-pizza/fup-gc-factory
cd ~/Projects/factory/fired-up-pizza/fup-gc-factory
```

This is the Gas City *workspace* — not the project. The project (the "rig" the factory works *on*) is the reference project inside the repo.

### Step 2: Write the `city.toml`

The factory configuration is a single file:

```bash
cat > city.toml <<'TOML'
[workspace]
name = "fup-factory"
provider = "claude"
includes = ["/abs/path/to/software-factory-intensive/software-factory/packs/fired-up-pizza"]

[session]
startup_timeout = "3m"
TOML
```

**Replace `/abs/path/to/software-factory-intensive` with your actual clone path.** The easy way:

```bash
SFI="$(cd ~/Projects/actual-software/software-factory-intensive && pwd)"
sed -i.bak "s|/abs/path/to/software-factory-intensive|$SFI|g" city.toml && rm city.toml.bak
cat city.toml   # sanity-check the path
```

Using `provider = "claude"` points the factory at Claude Code for every agent session. If you installed Codex instead, swap to `provider = "codex"`.

### Step 3: Register the reference project as the factory's rig

```bash
gc rig add ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
```

A *rig* in Gas City is the project the agents work on. This command tells the supervisor "the agents' working directory is this path" — the Coder writes into `src/` there, the Architect writes ADRs into `docs/decisions/` there, and so on.

### Step 4: Register and start the factory

```bash
gc register .                              # register this workspace with the gc supervisor
gc start                                   # bring up all six agents
```

`gc start` spawns one tmux session per agent (Planner, Architect, Designer, Coder, Reviewer, Deployer). Each session runs its pack's startup prompt and parks on its order gate, waiting for work with the label aimed at it.

### Step 5: Verify with doctor + status

```bash
bash ~/Projects/actual-software/software-factory-intensive/software-factory/curriculum-agent/scripts/doctor.sh
gc status --city ~/Projects/factory/fired-up-pizza/fup-gc-factory
```

`doctor` should return green. `gc status` should list six agent sessions as either *idle* or *waiting*. The fired-up-pizza pack also runs a `check-project` doctor that verifies the reference project has `docs/PROJECT_MANIFEST.md` and `package.json` in place — if that fails, your rig path in Step 3 is wrong.

### Step 6: Import the initial backlog into beads

The reference project ships an opinionated starter backlog in `reference-project/tickets.md` — six feature tickets (FUP-1 through FUP-6). Import them into the bead store:

```bash
cd ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
bash ../packs/fired-up-pizza/scripts/import-tickets.sh tickets.md
bd list   # should show FUP-1 … FUP-6, all unlabelled
```

Nothing is routed yet — the beads have no labels, so no agent sees them. The next part is where you flip one label and watch the factory start moving.

---

## Part 3: Walk a Feature Bead Through the Factory (~20 min)

You are going to pick one bead (FUP-1 — "Menu display page"), label it `needs-plan`, and watch the factory carry it through every stage without a single `gc sling` from you. Keep the dashboard open throughout.

### Step 1: Open the dashboard

```bash
gc dashboard serve --city ~/Projects/factory/fired-up-pizza/fup-gc-factory &
```

Open `http://localhost:8080` in a browser. The dashboard has three panes:

- **Bead queue** — grouped by label.
- **Agent sessions** — live status, current step.
- **Event log** — every label flip, session start/stop, order-gate match.

Keep it in a side window. Every assertion below is verifiable there.

### Step 2: Identify the bead to walk

```bash
bd list | grep "Menu display"
```

Copy the bead ID it prints (something like `fup-m3n`). For the rest of this part, `<id>` means that bead ID.

### Step 3: Flip the first label

```bash
bd label add <id> needs-plan
```

That's the entire trigger for the factory. Within one supervisor poll (~60 seconds) the Planner's order gate matches `bd ready --label=needs-plan`, the Planner wakes, and `mol-plan-breakdown` starts. Watch the dashboard's *Agent sessions* pane flip the Planner row from *idle* to *working*.

### Step 4: Narrate each handoff (~15 min, ~2 min per stage)

For each of the six stages, run the three commands below and narrate what you see. You're not driving the factory — you're observing it. David will walk the room through a full cycle; if you're self-paced, expect 8–12 minutes of real time for each stage as the agents do real work.

```bash
# See which agent is currently working + what bead they're on
gc status

# See the bead's label at the current moment — this is the ground truth
bd label list <id>

# Optional: peek at the agent's live tmux session
gc session peek <rig>/<agent>     # e.g. reference-project/planner
```

Concretely, here is what you'll see. Label values are what to expect *on the bead*; the bullet underneath is the agent action each label transition describes.

1. **Start** — bead has `needs-plan`. Planner wakes, reads the bead + `docs/PROJECT_MANIFEST.md` + existing beads, and either (a) decomposes it into child beads each labelled for the next stage, or (b) sets `needs-architecture` if it decides new rules are required first. FUP-1 is simple enough that Planner usually decomposes directly.
2. **Post-Plan** — children appear with `needs-design` (UI parts) or `ready-to-build` (backend parts). For FUP-1 the menu-list child picks up `needs-design`; an API-route child picks up `ready-to-build`. The Designer wakes on the first; the Coder wakes on the second. They run in parallel — you can tell because `gc status` shows *two* agents in *working* state simultaneously.
3. **Designer done** — the UI child flips from `needs-design` to `ready-to-build` with a spec file written under `docs/designs/` of the rig. The Coder wakes again for that child.
4. **Coder done** — each implemented child flips to `needs-review` when the Coder commits. The Reviewer wakes.
5. **Reviewer verdict** — pass flips to `ready-to-ship`; request-changes flips back to `ready-to-build`. On a clean run FUP-1 passes first try; on a less-clean run the reviewer sends it back with notes and the Coder wakes again.
6. **Deployer done** — the bead gets tagged (a new `git tag` appears in the rig), a rollback plan is written into the bead's notes, the bead closes, and a `needs-improve` child bead appears (handoff to the optional 7th agent, which you'll install in W4).

**You did not type a single prompt during any of this.** The only human action was one `bd label add` at Step 3. Every subsequent handoff happened because an agent flipped a label and another agent's order gate matched.

### Step 5: Inspect the finished bead

Once FUP-1 (or the first child of it) closes:

```bash
bd show <id>                              # status: CLOSED; notes include verdict + rollback_plan
bd label list <id>                        # no labels; work is done
git -C ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project log --oneline -5
git -C .../software-factory/reference-project tag -l | tail -3
```

The bead carries the state. The notes carry the findings and verdicts. The rig carries the artifacts (ADR, design spec, source code, tests, release tag). **Nothing was passed between agents as a markdown document they had to read and append to.** Labels drove every handoff; artifacts landed in their canonical locations as side-effects of the work.

> **Agent Guide:** If the participant asks "should I read the review report?" — *no.* The verdict is in `bd show <id>`'s notes. A file-based review report existed in earlier factory iterations and was exactly the kind of durable-markdown handoff the labeled-beads paradigm replaced. Re-orient them to `bd show` and the dashboard.

---

## Part 4: Observability — How to Watch a Factory Run (~5 min)

You kept the dashboard open during Part 3; now use the last few minutes to internalize the three observability surfaces you'll reach for across every remaining session.

### Surface 1 — the web dashboard (`gc dashboard serve`)

Best for: realtime overview, grouped bead queue, which agent is working right now.

Keep `http://localhost:8080` open whenever a factory is running. Eighty percent of "what's happening?" questions can be answered by glancing at it.

### Surface 2 — the beads CLI

Best for: precise per-bead state and history.

```bash
bd list                           # all beads
bd list --label needs-review       # filter by label
bd ready --label needs-plan        # what the Planner's order gate is matching on
bd show <id>                       # every note written by every agent on this bead
bd label list <id>                 # current labels on a single bead
bd label list-all                  # label vocabulary currently in use
```

These are the commands the agents themselves use; seeing the same output gives you the agents' view of the world.

### Surface 3 — gc sessions + events

Best for: drilling into what an agent is doing in a live session.

```bash
gc status                          # all agents, one-line per
gc session list                    # every live session with its state
gc session peek <rig>/<agent>      # snapshot of the agent's tmux session
gc events --follow                 # stream label transitions + session lifecycle
```

`gc events --follow` is the most useful flag of the three — it's the verbose log of every label flip and agent wake. If the factory stalls, this is where you look first.

### Anti-surface — never `gc sling` mid-flight

`gc sling <rig>/<agent> "<prompt>"` *does* exist — you saw it in the `curriculum-agent` SKILL reference. Do not use it during W1 or any time the factory is supposed to be running autonomously. Slinging a prompt at an agent bypasses the order gate and the label contract; from that moment forward, the agent isn't reacting to labels, it's reacting to your prompt. Save slings for deliberate demos and debugging, not for "the Coder is slow, let me poke it."

---

## Inline Insight: Why the Factory Runs on Labels, Not Prompts

This session is your first experience of the thing the rest of the workshop is trying to make durable: **a multi-agent system that advances without a human in the keyboard loop.** The magic is not in any single agent's prompt — every pack's prompt is a few hundred lines of plain Markdown. The magic is in the *coordination contract*: each agent watches for exactly one inbound label and sets exactly one outbound label when done.

That contract is what makes the factory operable overnight, with no one at the terminal. It's also what makes it comprehensible — the entire pipeline is six label transitions; there is no hidden state in somebody's scratchpad that you'd have to read to follow along.

The rest of Day 1 (W2, L1, W3, L2) is about how you customize the agents that run inside this contract for *your* project. The contract itself stays the same. You change the agents; the labels stay.

---

## Inline Insight: Why Participants Don't Write Code This Session

A reasonable thing to want on your first hands-on is to type *something* — to feel productive. W1 deliberately denies that. The whole point is that **the factory types for you**: you place a ticket, the agents take it from there. If you find yourself wanting to "just open `src/menu/MenuPage.tsx` and tweak that one line," notice the feeling — it's the exact habit the workshop exists to unbuild. The place for your customization is the agent packs in L2–L4, not the source code in `src/`. W1 is where you see that the customization location has moved.

---

## Common Issues & Solutions

### Issue 1: `/curriculum-agent list` isn't recognized by Claude Code

**Cause:** The symlink at `~/.claude/skills/curriculum-agent` didn't resolve, or Claude Code hasn't rescanned the skills directory.

**Fix:** Re-check `ls -l ~/.claude/skills/curriculum-agent` — it should show a working symlink into the repo. Restart Claude Code. If still missing, copy the directory in instead of symlinking (`cp -r software-factory/curriculum-agent ~/.claude/skills/curriculum-agent`).

### Issue 2: `gc rig add` reports "path does not exist"

**Cause:** You passed a relative path from a directory where the rig isn't reachable, or the absolute path typo'd.

**Fix:** Use an absolute path. `cd` to the repo and use `$(pwd)`:

```bash
cd ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
gc rig add "$(pwd)"
```

### Issue 3: `gc start` succeeds but `gc status` shows all six agents as dead / red

**Cause:** The `includes` path in `city.toml` still points at `/abs/path/to/...` (you forgot to substitute), or the provider (`claude` vs `codex`) doesn't match what you have installed.

**Fix:** `cat city.toml` and confirm the include resolves (`ls` on the path prints the `pack.toml`). If it does, re-check `provider = ...` matches a CLI on your PATH, then `gc restart`.

### Issue 4: Planner doesn't wake after `bd label add <id> needs-plan`

**Cause:** Either the order gate isn't registered, or the label you added isn't exactly `needs-plan` (capitalization matters; trailing spaces matter).

**Fix:** `bd label list <id>` — does it show `needs-plan` exactly? Then `gc order list` — is the Planner's intake order present? If neither surfaces a problem, `gc doctor --fix`. Common sneaky cause: the factory was started before you registered the rig; restart with `gc restart`.

### Issue 5: Two agents race on the same file in the rig

**Cause:** Parallel children of FUP-1 both landed in `ready-to-build` and two Coder sessions picked them up simultaneously — both are editing `src/menu/`.

**Fix:** This is rare with a fresh factory. When it happens, the later write wins and the earlier session errors out. Close the stray bead (`bd close <id> --reason "duplicate"`) and re-label the kept one. The real fix — serializing concurrent work via bead dependencies — is introduced in W3 (coordination primitives); for W1 just note the behavior.

### Issue 6: Dashboard shows the bead stuck on `ready-to-build` and no Coder session starts

**Cause:** The rig's `package.json` is missing dependencies the Coder needs to run tests (`npm ci` has never been run), so the Coder errors out instantly on boot. This happens on a freshly-cloned repo.

**Fix:**

```bash
cd ~/Projects/actual-software/software-factory-intensive/software-factory/reference-project
npm ci
```

Then `gc restart` to pick up the change.

### Issue 7: `gc dashboard serve` fails with "address already in use"

**Cause:** Another factory (probably from a previous session) has a dashboard on :8080.

**Fix:** `lsof -i :8080` to find the process; kill it; retry. Or `gc dashboard serve --port 8081` if you want both running.

### Issue 8: The Reviewer keeps returning `request-changes` and the Coder re-cycles

**Cause:** The Coder is regenerating the same issue because the shipped coder prompt is generic. That's expected — customizing the coder for your project is L3's entire job; you'll see the fix-via-config discipline land then.

**Fix (for W1 specifically):** nothing. Let it cycle. The point of this session is to see the pipeline move, not to produce merge-ready code. If it cycles more than three times on the same finding, stop the factory (`gc stop`) and call David over — the failure mode might be worth walking the room through.

### Issue 9: `import-tickets.sh` printed warnings like "failed to create FUP-2"

**Cause:** Your `bd` database already has beads with matching titles from a previous workshop run.

**Fix:** Either clear the prior state (`bd list` + close or delete duplicates) or continue — the script is idempotent-ish; duplicates just don't get re-imported. `bd list` should still show at least FUP-1 through FUP-6 once.

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `~/.claude/skills/curriculum-agent` (or `~/.codex/skills/curriculum-agent`) resolves to the repo
- [ ] `bash .../curriculum-agent/scripts/status.sh` prints a green `gc version` and lists your factory directory under *Installed Activities* / *Registered Cities*
- [ ] `gc status --city ~/Projects/factory/fired-up-pizza/fup-gc-factory` shows six agents as running (idle or working — not dead)
- [ ] The dashboard at `http://localhost:8080` loaded and showed at least one non-empty label column
- [ ] At least one bead flipped through at minimum three distinct labels under your observation (`needs-plan` → `ready-to-build` → `needs-review` is the minimum chain)
- [ ] You did not run `gc sling` manually after the initial `bd label add`
- [ ] You can name, from memory, which label each of the six agents consumes as input

**W1 is the foundation for everything that follows.** W2 (next) shifts you from "watching the reference factory run" to "understanding what the agents consume and emit so you can configure them for your own project." L1 installs the factory on your project. L2–L4 customize each agent pack.

---

## Command Cheat Sheet

```bash
# PART 1 — install curriculum-agent skill
cd ~/Projects/actual-software/software-factory-intensive
mkdir -p ~/.claude/skills
ln -sfn "$(pwd)/software-factory/curriculum-agent" ~/.claude/skills/curriculum-agent
# Claude Code: /curriculum-agent list   (verify)

# The four verbs you'll use across the workshop
bash software-factory/curriculum-agent/scripts/install.sh <activity> [--dry-run]
bash software-factory/curriculum-agent/scripts/status.sh
bash software-factory/curriculum-agent/scripts/doctor.sh
gc dashboard serve --city ~/Projects/factory/<slug>/<alias>-gc-factory

# PART 2 — stand up Fired-Up Pizza factory (manual stand-up)
mkdir -p ~/Projects/factory/fired-up-pizza/fup-gc-factory
cd    ~/Projects/factory/fired-up-pizza/fup-gc-factory

SFI="$(cd ~/Projects/actual-software/software-factory-intensive && pwd)"
cat > city.toml <<TOML
[workspace]
name = "fup-factory"
provider = "claude"
includes = ["$SFI/software-factory/packs/fired-up-pizza"]

[session]
startup_timeout = "3m"
TOML

gc rig add "$SFI/software-factory/reference-project"
gc register .
gc start
bash "$SFI/software-factory/curriculum-agent/scripts/doctor.sh"
gc status --city ~/Projects/factory/fired-up-pizza/fup-gc-factory

# Import backlog
cd "$SFI/software-factory/reference-project"
bash ../packs/fired-up-pizza/scripts/import-tickets.sh tickets.md
bd list

# PART 3 — walk a bead through the factory
gc dashboard serve --city ~/Projects/factory/fired-up-pizza/fup-gc-factory &
# open http://localhost:8080

bd list | grep "Menu display"          # copy the id
bd label add <id> needs-plan           # the only manual trigger this session

# Monitor (run repeatedly during the demo)
gc status
bd label list <id>
gc events --follow                     # in a second terminal
gc session peek <rig>/<agent>          # peek at a specific agent

# PART 3 (after close)
bd show <id>
git -C "$SFI/software-factory/reference-project" tag -l | tail -3
bd list --label needs-improve          # optional-7th handoff handle
```

---

## Quick Reference: What You Built

| Component | Location | What It Does |
|-----------|----------|--------------|
| `curriculum-agent` skill | `~/.claude/skills/curriculum-agent` → `software-factory/curriculum-agent` | Slash command and Bash wrappers for `install` / `status` / `doctor` / `dashboard` / `delete` |
| `install.sh` wrapper | `software-factory/curriculum-agent/scripts/install.sh` | Validates an activity, pre-flight-checks, delegates to `curriculum_agent.py` |
| `status.sh` wrapper | `software-factory/curriculum-agent/scripts/status.sh` | Prints `gc version`, registered cities, and per-factory agent status |
| `doctor.sh` wrapper | `software-factory/curriculum-agent/scripts/doctor.sh` | Runs `gc doctor --fix` and the curriculum's environment checks |
| Fired-Up Pizza factory workspace | `~/Projects/factory/fired-up-pizza/fup-gc-factory/` | Your live Gas City workspace — `city.toml`, registered rig, six running agents |
| Reference project (the rig) | `software-factory/reference-project/` | React/TS/SQLite app the factory works on; ships `tickets.md`, `docs/PROJECT_MANIFEST.md`, `package.json` |
| Fired-Up Pizza composite pack | `software-factory/packs/fired-up-pizza/` | Bundles the six agent packs + `check-project` doctor + `import-tickets.sh` |
| Beads backlog | `bd list` | FUP-1 through FUP-6 imported from `reference-project/tickets.md` |
| Dashboard | `http://localhost:8080` | Realtime view of queue, sessions, events |

---

## Next Steps

**W2 (next, 1:00pm Day 1)** turns the lens inward: *how* do the agents do their job? You'll trace a feature bead through the six packs, read each agent's prompt template + formula, and start building the mental model you'll need in L1/L2 when the packs become *your* configuration to edit. If you can, re-read the `needs-plan` through `ready-to-ship` cycle on the dashboard once before W2 starts — the pattern will be fresher.

**L1 (1:45pm Day 1)** is where the factory becomes *yours*. You'll register your own project as the rig, point the six shipped packs at it, and watch the same cycle you just saw run against *your* codebase's first feature bead.

Between now and W2: leave the factory running if you can (it's idle, not costly). If the dashboard is open, keep it open. Part of the workshop's intent is that by Day 2 afternoon you stop noticing the dashboard because the factory running is just the ambient state.
