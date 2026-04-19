# L1 · Build a Structured Development Loop

> **Goal:** Install the 6-agent software factory — Planner, Architect, Designer, Coder, Reviewer, Deployer — against **your own project**, then watch one feature bead walk all six agents end-to-end. By the end, you have a working factory you own, not a demo you've read about.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | Lab |
| **Deliverable** | A running city with your project registered as a rig, all 6 agents wired in, and one feature bead fully traversed from `needs-plan` to `ready-to-ship` |

---

> **Agent Guide** — If an AI coding agent is walking you through this session, look for **`> Agent Guide: …`** callouts at pivotal steps. They tell the agent which verifications to run and which anti-patterns to flag — additive to the step instructions, never replacing them.

---

## Where this lab sits

In **W1** you installed the Fired-Up Pizza reference factory and watched it run. That was somebody else's factory on somebody else's project. In **W2** you prepared your own project and toolset to be factory-ready.

L1 is the handoff: you take the reference pattern from W1 and the factory-ready config from W2, and you install the 6-agent city against **your project**. You aren't writing any custom prompts yet — that starts in L2. L1 is the "it works on my repo" milestone that makes every subsequent lab worth doing.

The factory you leave this lab with is minimal but real: feature in, six agents touch it, implementation out. L2, L3, and L4 replace the shipped packs one by one with your custom versions; the topology stays the same.

---

## Architecture: The 6-Agent Factory, Driven by Labels

```
                            ┌─ user files bead ─────────────────────────┐
                            │  bd create --label needs-plan             │
                            └─────────────────┬─────────────────────────┘
                                              │
                            needs-plan        ▼
                        ┌──────────────► Planner ────┐
                        │                            │ (on drift)
                        │ needs-architecture         │
                        │                            ▼
                        │                        Architect
                        │                            │
                        │  needs-plan                │
                        └────────────────────────────┘
                                              │
                                              │ needs-design  │ ready-to-build
                                              ▼               ▼
                                           Designer ─────► Coder
                                                             │
                                                             │ needs-review
                                                             ▼
                                                          Reviewer
                                           ┌─────────────────┴─────────────────┐
                                           │ ready-to-build                    │ ready-to-ship
                                           ▼                                   ▼
                                        (back to Coder)                    Deployer
                                                                              │
                                                                              ▼
                                                                       bead closed
```

The six labels are the contract between agents: each agent waits for its inbound label, does its work, and re-labels the bead for the next agent. There are **no durable markdown handoffs** — every piece of state the next agent needs lives on the bead.

See [`../../../LABELED_BEADS.md`](../../../LABELED_BEADS.md) for the canonical label reference (who adds, who consumes, edge cases). You will reference that file, not re-learn its content, for the rest of the curriculum.

---

## Prerequisites

Verify each of these before Step 1. Fixing a missing prereq mid-lab costs more than the lab's full duration.

| Prerequisite | How to verify | How to fix |
|-------------|---------------|-----------|
| W1 complete | You've run the Fired-Up Pizza factory end-to-end and seen at least one bead traverse all 6 agents | Finish W1 first. L1 depends on recognizing what a running factory looks like. |
| W2 complete | Your project has a filled-in `docs/PROJECT_MANIFEST.md` and a short "factory-ready" checklist from W2 | Finish W2. Without a manifest, agents have no project context. |
| `gc` CLI pinned to v0.14.1 | `gc version` → `v0.14.1` | See [Gas City installation](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md) or the workshop pinned-version recipe. |
| `bd` (beads) installed | `bd --version` prints a version | Installed alongside `gc`; if missing, `brew install beads` or re-run `gc` install. |
| `claude` (or another provider CLI) authenticated | `claude --version`; `claude` opens and answers a prompt | `claude auth login`. Codex/Cursor/Gemini also work — set `provider` in `city.toml` accordingly. |
| Your project repo cloned, clean | `cd ~/path/to/your-project && git status` → clean working tree | Commit/stash pending work before L1; the factory will want to branch off a known state. |
| A small user story | Something you could implement by hand in 15–30 minutes touching fewer than five files | If you don't have one, borrow from the reference: [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md). FUP-3 ("Shopping cart — running total") is the running example. |
| `factory-activity-agent` skill available | `/factory-activity-agent list` inside Claude Code prints the activity table | See [`../../../factory-activity-agent/SKILL.md`](../../../factory-activity-agent/SKILL.md) for installation — one `ln -s` into `~/.claude/skills/`. |

**Scope anchor.** This lab will install a new, L1-scoped factory at `~/Projects/factory/lab_l1/`. It does not touch the `my-factory/` workspace from earlier sessions or the Fired-Up Pizza factory from W1. The point is that you can stand up additional factories at will — one per project, one per experiment.

---

## Running Example: Show Order Total in Cart

Throughout the lab we walk the feature **"Show Order Total in Cart"** through the factory. It is deliberately tiny — one component, a handful of files, no open architectural questions. Your first walk-through is a calibration run, not a hero play.

If you are working against your own project, substitute a comparably small story. The criteria: under five files, under 30 minutes by hand, no decisions the factory has to escalate to you mid-run. You will get more ambitious features later; L1's job is to prove the topology.

---

## Step 1: Install the L1 Factory (~10 min)

> **Agent Guide:** Before running `install`, confirm with the participant that their project repo is clean (no uncommitted work) and that `gc` v0.14.1 is on PATH. If either is off, the install will surface a confusing error later.

`factory-activity-agent` is the skill that manages per-activity factory setups for this curriculum. It wraps the raw `gc` + `bd` commands in a single idempotent verb per lifecycle step (install, status, doctor, delete). You will use it in every session from here forward.

### Step 1.1: Dry-run the install

```bash
cd /path/to/software-factory-intensive/software-factory
bash factory-activity-agent/scripts/install.sh L1 --dry-run
```

**What's happening here:** `--dry-run` prints every command the installer would execute without running it. Skim the output — you should see: create `~/Projects/factory/lab_l1/`, initialize a sub-project at `l1-project/`, initialize a Gas City factory at `l1-gc-factory/`, copy the L1 packs into `l1-gc-factory/packs/actual/`, register the factory with the supervisor, and start the agents. If anything in the plan surprises you (e.g. a path you didn't expect), stop and ask — don't run the real install until you understand the plan.

### Step 1.2: Execute the install

```bash
bash factory-activity-agent/scripts/install.sh L1
```

Expected output (truncated):

```
==> Installing activity L1
==> Creating project at ~/Projects/factory/lab_l1/l1-project
==> Initializing factory at ~/Projects/factory/lab_l1/l1-gc-factory
==> Copying L1 packs → l1-gc-factory/packs/actual/
==> Registered city 'l1-gc-factory'
==> Started supervisor + agents
==> Install complete for L1
```

**What's happening here:** the installer stands up a factory at `~/Projects/factory/lab_l1/l1-gc-factory/` configured with the 6 essential agent packs (`planner`, `architect`, `designer`, `coder`, `reviewer`, `deployer`) plus the `all` composition pack that wires them together. The stub project at `l1-project/` is a scratch git repo the installer creates; you will replace it with your own project as the rig in Step 2.

The pack source the installer copies from is the B1 baseline tree at [`B1/gascity/step_0/packs/`](B1/gascity/step_0/packs/). You can inspect that directory to see exactly what shipped — `all/`, `planner/`, `architect/`, `designer/`, `coder/`, `reviewer/`, `deployer/`, plus `improver/` (the optional 7th, introduced in W4) and `fired-up-pizza/` (the reference composite used in W1).

### Step 1.3: Confirm the factory is up

```bash
bash factory-activity-agent/scripts/status.sh
```

You should see `l1-gc-factory` listed as running, with one or more agents in the `running` state. If anything reports `failed`, run `bash factory-activity-agent/scripts/doctor.sh` and fix what it surfaces before moving on. Most first-time failures are missing CLI auth (`claude auth login`) or a stale `gc` version.

---

## Step 2: Register Your Project as the Rig (~10 min)

The installer gave you a stub project at `~/Projects/factory/lab_l1/l1-project/`. That stub is useful for the installer's smoke test, but the outcome of L1 is running the factory against **your** project. In Gas City terms: you are replacing (or adding) a rig in the city's configuration.

### Step 2.1: Add your project as a rig

```bash
cd ~/Projects/factory/lab_l1/l1-gc-factory
gc rig add ~/path/to/your-project
```

Expected output:

```
Re-initializing rig 'your-project'...
  Detected git repo at /Users/you/path/to/your-project
  Prefix: yp
  Initialized beads database
  Generated routes.jsonl for cross-rig routing
Rig re-initialized.
```

**What's happening here:** `gc rig add` does three things — records the rig's path in `city.toml`, initializes a per-rig beads database under your project (so beads live alongside code), and generates routing metadata so agents in the city can refer to your project by name. The two-letter `Prefix` (`yp` above) namespaces bead IDs.

### Step 2.2: Wire the 6-agent pack into your rig

Open `~/Projects/factory/lab_l1/l1-gc-factory/city.toml` and find your `[[rigs]]` block. Add an `includes` line that points at the `all` composition pack the installer copied in Step 1.2:

```toml
[[rigs]]
name = "your-project"
path = "/Users/you/path/to/your-project"
includes = ["packs/actual/all"]
```

**What's happening here:** `includes` tells Gas City which pack configurations to overlay onto this rig's effective context. The `all` pack is a composition — it includes the 6 essential agent packs. By pointing your rig at `all`, every agent in the pipeline knows how to operate on your project.

If you prefer to wire each agent individually (so you can drop one later), list them explicitly:

```toml
includes = [
  "packs/actual/planner",
  "packs/actual/architect",
  "packs/actual/designer",
  "packs/actual/coder",
  "packs/actual/reviewer",
  "packs/actual/deployer",
]
```

Functionally equivalent to `packs/actual/all` at this stage. Either is fine; the explicit list makes it easier in later labs to swap a shipped pack for your custom copy.

### Step 2.3: (Optional) Remove the stub rig

If you want your project to be the only rig in the city, remove the stub:

```bash
gc rig remove l1-project
```

Otherwise, leave it in place — it doesn't interfere with your project's rig, and some troubleshooting recipes in Step 7 use it.

### Step 2.4: Restart and verify

```bash
gc service restart
gc status
```

Expected (truncated):

```
l1-gc-factory  /Users/you/Projects/factory/lab_l1/l1-gc-factory
Agents:
  your-project/planner    running
  your-project/architect  running
  your-project/designer   running
  your-project/coder      running
  your-project/reviewer   running
  your-project/deployer   running
Rigs:
  your-project  /Users/you/path/to/your-project
```

All six agents should show `running`. If any are missing, your `includes` line doesn't reference the pack — re-check `city.toml`.

---

## Step 3: Run Doctor and Open the Dashboard (~5 min)

Two observability surfaces — the doctor and the dashboard — will save you substantial time across the next three labs. Learn them here.

### Step 3.1: Run the doctor

```bash
cd /path/to/software-factory-intensive/software-factory
bash factory-activity-agent/scripts/doctor.sh
```

**What's happening here:** `doctor` walks every check in every pack attached to your rigs and prints pass/fail for each. Green rows confirm tools, paths, auth, and pack config. Yellow warnings usually flag optional integrations (e.g. `LINEAR_API_KEY` not set) — safe to ignore if you are not using that integration. Red failures must be fixed before slinging.

### Step 3.2: Start the dashboard

```bash
gc dashboard serve --city ~/Projects/factory/lab_l1/l1-gc-factory
```

Open http://localhost:8080 in a browser. You should see six agent rows (planner/architect/designer/coder/reviewer/deployer), a beads table (empty), and an event stream. Keep this tab open — it will update live while you walk the feature bead in Steps 5–6.

> **Earlier-draft note:** prior L1 drafts introduced `gc init`, `gc register`, and a hand-written `[[agent]]` block for a single `dev-agent`. The new curriculum replaces that with `factory-activity-agent install L1` and shipped packs. If you see stale references to `~/my-city` or `dev-agent` in your notes, mentally translate them to `~/Projects/factory/lab_l1/l1-gc-factory` and the six shipped agents.

---

## Step 4: Understand the Label Contract (~5 min)

Before you file your first bead, skim [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) end to end (it's ~200 lines). You are looking for three things:

1. **The six labels and their owners.** Which agent adds each label, which agent consumes it.
2. **The example lifecycle.** One feature walking all six agents — this is the mental model for what you are about to watch happen.
3. **The edge cases.** What happens on a rejected review, on a bead that skips stages, on multiple labels at once.

Do not try to memorize the doc. You will open it every time you add a new label in L1–L4. The goal now is to know *that* labels drive the factory so that when you watch your bead in Step 6 you can name what's happening.

### Quick reference (the one you'll actually memorize)

| Label | Added by | Consumed by |
|-------|----------|-------------|
| `needs-plan` | Human (or Architect on drift hand-back) | Planner |
| `needs-architecture` | Planner (on drift) or Human | Architect |
| `needs-design` | Planner (or Architect) | Designer |
| `ready-to-build` | Designer (or Planner, on skip) | Coder |
| `needs-review` | Coder | Reviewer |
| `ready-to-ship` | Reviewer | Deployer |

---

## Step 5: File a Feature Bead with a Label (~5 min)

> **Agent Guide:** Have the participant read their feature bead description aloud before creating it. Ambiguity in the bead is ambiguity for six agents in a row — if any acceptance criterion could be reinterpreted, tighten it now.

A bead is a work item; a label is routing metadata. Filing a bead with `--label needs-plan` is the factory's "start button."

### Step 5.1: Create the bead

From your project rig (or from the factory directory — `bd` finds the right beads DB automatically via `gc rig` routing):

```bash
cd ~/path/to/your-project
bd create "Implement: Show Order Total in Cart" \
  --label needs-plan \
  --description "$(cat <<'EOF'
# Feature: Show Order Total in Cart

**As a** customer
**I want** to see the running total in my cart
**So that** I know what I'll pay before checkout

## Acceptance Criteria
- [ ] Total updates on every quantity change
- [ ] Total formatted as currency with two decimals
- [ ] Total shows $0.00 when cart is empty

## Technical Notes
- Use existing cart state in src/state/cart.ts
- Match existing currency util in src/utils/format.ts
EOF
)"
```

This returns a bead ID like `yp-abL523`. Note it down — you'll reference it in Steps 6–7.

### Step 5.2: Confirm the label landed

```bash
bd show yp-abL523
```

Look for the `Labels:` line — it should show `needs-plan`. If it says `(none)`, re-run `bd label add yp-abL523 needs-plan`. The label is what wakes the Planner; without it, the bead sits unnoticed forever.

**What's happening here:** filing the bead with `--label needs-plan` is equivalent to filing + labeling in two steps. The factory polls `bd ready --label needs-plan --unassigned` every few seconds from the Planner's order gate. Once your bead shows up in that query, the Planner wakes, claims it, and gets to work. No human needs to dispatch anything.

---

## Step 6: Watch the Bead Walk the Factory (~15 min)

This is the payoff. You should see — live, in the dashboard and the event stream — a single bead re-labeled six times, one agent per transition, over the next several minutes.

### Step 6.1: Follow the event stream

In a new terminal:

```bash
cd ~/Projects/factory/lab_l1/l1-gc-factory
gc events --follow
```

**What's happening here:** `gc events --follow` is the city-wide event log. You will see session spawns, file reads, `bd label` calls, tool invocations, and commits — one line per event, timestamped. It's verbose; that's the point. You'll learn to spot the shape of a healthy walk.

### Step 6.2: Watch the label transitions

In a third terminal, poll the bead every few seconds:

```bash
watch -n 3 "bd show yp-abL523 | head -20"
```

You should see the `Labels:` line change over the course of the walk:

```
needs-plan        (Planner working)
  → needs-design  (Planner done; Designer next) OR ready-to-build (no design needed)
  → ready-to-build (Designer done; Coder next)
  → needs-review  (Coder done; Reviewer next)
  → ready-to-ship (Reviewer done; Deployer next)
  → (bead closed) (Deployer done)
```

If your feature needs architectural guardrails, the Planner may hand it back with `needs-architecture` first. The Architect then re-labels it `needs-plan` once the ADR exists, and the walk continues.

### Step 6.3: Check the dashboard

The dashboard at http://localhost:8080 will show the bead moving through the agents visually — each agent's "working on" column updates as it claims the bead. Use the dashboard when you want the high-level view; use `gc events --follow` when you want to read what an agent is actually doing.

### Step 6.4: Expected duration

A small feature like "Cart Total" typically walks the full pipeline in **8–15 minutes** of wall-clock time. Most of that is the Coder writing + testing. The Planner, Architect (if invoked), Designer, Reviewer, and Deployer are each ~1–3 minutes.

If more than 20 minutes pass and the bead hasn't advanced past one agent, see Step 7 troubleshooting.

### Step 6.5: Confirm completion

When the Deployer closes the bead, you'll see:

```
$ bd show yp-abL523
yp-abL523  Implement: Show Order Total in Cart   [closed]
  Labels: ready-to-ship
  Closed: <timestamp>
  Closed by: your-project/deployer
```

Run `git log -5 --oneline` in your project repo. You should see a commit from the Coder (and possibly a deploy tag from the Deployer). You never typed into a chat; you never wrote code yourself. The factory did.

---

## Step 7: Troubleshooting a Stalled Walk (~5 min)

A stall usually means the bead has a label no agent is consuming, or an agent failed silently. The diagnostic is always the same: read the label, then read the agent's status.

### Step 7.1: Read the bead's current label

```bash
bd show yp-abL523 | head -10
```

### Step 7.2: Check the agent that should be handling that label

Match the label to its consumer from the Step 4 table. Then:

```bash
gc status
```

Look for the agent listed in that row. If it says `running`, the agent is alive but may be stuck on the task — `gc session peek your-project/<agent>` will show what it's actually doing. If it says `failed`, `gc doctor` will tell you why.

### Step 7.3: Common stalls and fixes

| Symptom | Fix |
|---------|-----|
| Bead sits on `needs-plan` for 5+ minutes with Planner `running` | `gc session peek your-project/planner` — the Planner is probably waiting on a question. Tighten the bead description and re-run `bd label add yp-abL523 needs-plan` to re-wake it. |
| Bead stuck on `needs-architecture` | Architect was invoked; check `docs/adr/` in your project for a new ADR. If none, Architect hit an error — `gc doctor`. |
| Bead walks to `ready-to-build` then sits | Coder may be missing Quality Gates config. Confirm `packs/actual/coder/prompts/coder.md.tmpl` references your project's test commands; if not, add them via the pack config (not the chat). |
| Reviewer bounces the bead back to `ready-to-build` | **This is expected behavior on real reviews.** Read the Reviewer's notes on the bead, address them in config if the fix would repeat, and let the Coder pick it up again. |
| Bead has no labels | You forgot `--label needs-plan` on creation. `bd label add yp-abL523 needs-plan`. |
| Two agents both claim the bead | Rare but possible if labels overlap. Remove one label with `bd label remove yp-abL523 <extra-label>`. |

### Step 7.4: The "nuclear" recovery

If the factory gets into a state you can't reason about:

```bash
gc stop
bash /path/to/software-factory-intensive/software-factory/factory-activity-agent/scripts/doctor.sh
gc start
```

`doctor` will surface config issues; `gc start` brings everything back up. Your bead's labels survive — the factory resumes where it left off.

---

> **Inline Insight: Why Labels (Not Markdowns) Carry State**
>
> Earlier iterations of this curriculum passed context between agents via long-lived markdown files — `SPEC.md`, `PLAN.md`, `REVIEW.md` and so on. That design forced every agent to know every doc path and every section contract; two beads in flight couldn't be distinguished without parsing the docs' internal state; handoffs were implicit.
>
> Labels fix all of that. A bead is the unit of work; its labels are its state; `bd ready --label X` is a natural queue per agent. The factory becomes a state machine whose edges are label transitions, and the coordination surface shrinks to the six-word label vocabulary.
>
> If you catch yourself writing a `SPEC.md` or `DESIGN.md` to "pass between agents" in a later lab, that's a signal to stop — whatever you were about to write into the doc belongs on the bead (as a comment, a checkbox item, or a new child bead). The label already tells the next agent what to do next.
>
> See [`../../../LABELED_BEADS.md`](../../../LABELED_BEADS.md#why-labels-replaced-durable-markdowns) for the longer version of this argument.

---

## Exit Criteria

- [ ] `factory-activity-agent install L1` succeeded; factory running at `~/Projects/factory/lab_l1/l1-gc-factory/`
- [ ] Your project is registered as a rig (`gc rig list` shows it)
- [ ] `city.toml` includes `packs/actual/all` (or the six individual packs) for your rig
- [ ] `gc status` shows all six agents running
- [ ] Dashboard at http://localhost:8080 is reachable
- [ ] You filed a bead with `--label needs-plan` and watched it traverse all six labels to a closed state
- [ ] `git log` in your project shows a commit authored by the Coder, satisfying the feature's acceptance criteria
- [ ] You did not type any correction into an agent chat window — every iteration happened through bead / label config

**L1 blocks L2.** Don't move on until every box is checked. L2 replaces the shipped Planner and Architect with your custom copies — that substitution is only meaningful if the shipped pipeline works on your project first.

---

## Quality Bar

- **One-run traversal.** Your feature bead reached `ready-to-ship` (or a closed state) on the first walk, or on a single Reviewer bounce. If it took three or more walks, something in your project config is fighting the shipped packs — file a note for L2 to tighten.
- **Zero chat corrections.** Re-read the event stream. If any event is you typing into a `gc watch` window, your habit needs another rep — not a bad thing, just name it.
- **Labels, not markdowns.** No `SPEC.md` / `DESIGN.md` / `REVIEW.md` files were created by you or any agent during the walk. If any agent wrote a durable handoff doc, its pack config is misconfigured — flag it as L2 input.
- **Dashboard-readable.** If you closed the event-stream terminal, could you still reconstruct what happened from the dashboard alone? If yes, the observability layer is doing its job.
- **Reproducible.** `factory-activity-agent delete L1 && factory-activity-agent install L1` returns you to a working factory. If it doesn't, something was done by hand that belongs in config.

---

## Test Scenarios

Once the base walk succeeds, try these variations to stress-test your setup.

### Scenario 1: Feature requiring architectural guardrails

File a bead whose implementation would change a schema, add a dependency, or introduce a new trust boundary:

```bash
bd create "Add user-uploaded avatars with S3 signed URLs" --label needs-plan
```

**Expected behavior:** the Planner detects drift (new storage dependency, new trust boundary around user uploads) and re-labels to `needs-architecture`. The Architect produces an ADR and re-labels back to `needs-plan`. The walk then continues normally.

**What it tests:** the drift hand-back. If your Planner charged ahead without escalating, inspect `packs/actual/planner/prompts/planner.md.tmpl` — its drift-detection section is probably missing or vague.

### Scenario 2: Reviewer bounce

File a bead whose implementation you can predict the Reviewer will reject (e.g. one that tempts the Coder to skip a test):

```bash
bd create "Expose raw /api/debug endpoint for quick testing" --label needs-plan
```

**Expected behavior:** the Coder implements something, the Reviewer bounces it back to `ready-to-build` with notes on the bead, and the Coder picks it up again.

**What it tests:** the regression loop. If the Reviewer rubber-stamped, its prompt lacks specificity — another note for L4 (where you customize the Reviewer).

### Scenario 3: Second bead in parallel

While your first bead is still walking, file a second:

```bash
bd create "Add a 'Clear cart' button" --label needs-plan
```

**Expected behavior:** both beads walk in parallel; agents pick up whichever is ready-for-them when they finish their current claim.

**What it tests:** concurrency. If one bead blocks the other, an agent's `max_active_sessions` is set too low, or two labels collide on the same bead.

---

## Common Issues & Solutions

### Issue 1: `factory-activity-agent install L1` fails on "Activity L1 has no gascity packs"

<details>
<summary>Solution</summary>

**Fix:** the installer couldn't find the pack source tree. Verify you're running from `software-factory/` (the repo's software-factory subdir, where `factory-activity-agent/` lives). If the directory is missing entirely, re-sync your repo (`git pull`).

</details>

### Issue 2: `gc rig add` reports "path does not exist"

<details>
<summary>Solution</summary>

**Fix:** you passed a relative path that didn't resolve. Use the absolute path to your project: `gc rig add "$(realpath ~/path/to/your-project)"`.

</details>

### Issue 3: Dashboard shows agents but the event stream is silent

<details>
<summary>Solution</summary>

**Fix:** events are emitted only during active sessions. Sling work (create a labeled bead) and events will flow. If they don't, `tail -f ~/Projects/factory/lab_l1/l1-gc-factory/events.jsonl` directly.

</details>

### Issue 4: Bead stuck on `needs-plan` with no Planner activity

<details>
<summary>Solution</summary>

**Fix:** the Planner's order gate isn't matching the label. `gc config --city ~/Projects/factory/lab_l1/l1-gc-factory` → verify the Planner's order points at `needs-plan`. Almost always the stub-project-rig rather than your-project-rig is receiving the label; remove the stub or tag your bead to the right rig.

</details>

### Issue 5: Coder commits to `main` instead of a feature branch

<details>
<summary>Solution</summary>

**Fix:** the shipped Coder pack should default to a feature branch. If it committed to main, the pack's `coder.md.tmpl` is missing the branch rule. Do NOT fix this by chat-correcting — edit the template and re-sling. This is the single most important config-discipline rep of the lab.

</details>

### Issue 6: You caught yourself typing into a `gc watch` session

<details>
<summary>Solution</summary>

**Fix:** stop immediately. The correction is invisible to the next sling and to every other agent. Close the watch tab, translate your correction into a change on the relevant pack's prompt template or on the bead description, re-label to re-trigger the agent.

</details>

### Issue 7: `bash factory-activity-agent/scripts/doctor.sh` fails with "Port 8080 already in use"

<details>
<summary>Solution</summary>

**Fix:** a previous dashboard is still running. `lsof -i :8080` to find the PID, `kill <pid>`, re-run.

</details>

### Issue 8: Two factories running simultaneously confuse the supervisor

<details>
<summary>Solution</summary>

**Fix:** run `gc cities` to list all registered factories. Stop the one you don't need (`gc stop --city <path>`) or delete it with `factory-activity-agent delete <activity>`.

</details>

---

## Command Cheat Sheet

```bash
# FROM software-factory/ ROOT

# STEP 1 — Install the L1 factory
bash factory-activity-agent/scripts/install.sh L1 --dry-run
bash factory-activity-agent/scripts/install.sh L1
bash factory-activity-agent/scripts/status.sh

# STEP 2 — Register your project as the rig
cd ~/Projects/factory/lab_l1/l1-gc-factory
gc rig add ~/path/to/your-project
# (edit city.toml to add `includes = ["packs/actual/all"]` to your rig)
gc service restart
gc status

# STEP 3 — Observability
bash factory-activity-agent/scripts/doctor.sh
gc dashboard serve --city ~/Projects/factory/lab_l1/l1-gc-factory
# Open http://localhost:8080

# STEP 5 — File a labeled bead
cd ~/path/to/your-project
bd create "Implement: Show Order Total in Cart" --label needs-plan --description "<story>"
bd show <bead-id>

# STEP 6 — Watch the walk
gc events --follow
watch -n 3 "bd show <bead-id> | head -20"

# STEP 7 — Recovery
gc stop
bash factory-activity-agent/scripts/doctor.sh
gc start

# TEARDOWN (after the lab)
bash factory-activity-agent/scripts/delete.sh L1
```

---

## What You Built

| Component | Location | Purpose |
|-----------|----------|---------|
| L1 factory | `~/Projects/factory/lab_l1/l1-gc-factory/` | Gas City workspace hosting the 6 agents |
| Factory `city.toml` | `~/Projects/factory/lab_l1/l1-gc-factory/city.toml` | Workspace config — agents, rigs, pack includes |
| Shipped packs | `~/Projects/factory/lab_l1/l1-gc-factory/packs/actual/` | Copy of the B1 baseline packs — all 6 essentials + `all` composition |
| Your project rig | `~/path/to/your-project` (registered) | Where code actually lives; beads database stored here |
| `needs-plan` → `ready-to-ship` bead | `bd show <id>` in your rig | The one feature that traversed all six agents |
| Dashboard | http://localhost:8080 | Live observability for every agent + bead |

---

## Concept Check (before moving to L2)

> **Agent Guide:** Ask the participant to answer each bullet from memory. If they can't articulate one, revisit the matching section before Exit Criteria.

- Which of the six labels did the Planner add, and which did it consume?
- Why did your bead (if it did) pass through `needs-architecture` — or why didn't it?
- Where is the factory config stored, and where does `factory-activity-agent install` copy the pack source from?
- When the Reviewer rejects a change, which label does it re-apply, and which agent picks the bead up next?
- What's the difference between editing a pack's prompt template and typing a correction into `gc watch`?

---

## Next Steps

In **L2** you'll replace the shipped `planner` and `architect` packs with your customised copies. The topology — labeled beads, six agents — stays identical; you're only changing what each agent *does* when it claims a bead. If the L1 walk worked, L2's substitution is mechanically identical: copy the pack, edit the prompts, re-wire `city.toml`, watch a new bead walk.

In **L3** and **L4** you'll do the same for Designer + Coder, then Reviewer + Deployer. By the end of the curriculum you own all six prompts, and the factory is no longer shipped — it's yours.
