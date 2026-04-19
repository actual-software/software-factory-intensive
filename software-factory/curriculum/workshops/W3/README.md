# W3 · Architect Multi-Agent Coordination

> **Goal:** Learn the five coordination primitives that Gas City agents use to work together — **beads**, **mail**, **nudges**, **hooks**, and **files** — understand when each is the right tool, and add one new coordination method to your factory before you walk out of the session.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | Workshop |
| **Deliverable** | One new coordination rule committed to your factory's config — an order, a hook, a mail trigger, or a shared-file convention — with a short note in `DECISIONS.md` explaining why you picked it |

---

## Session workspace note

W3 edits the packs you installed in L1 — you are not installing new packs, and you are not creating a new activity folder. Every change lands in a `pack.toml`, an `order.toml`, a `settings.json`, or a prompt template under your factory's `packs/` tree. The W3 deliverable is a commit in your factory, not a markdown in `activities/`.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should start by running `bd label list-all` on the participant's factory to see which labels already exist, and by skimming `software-factory/LABELED_BEADS.md` so every coordination suggestion is grounded in the canonical handoff protocol rather than reinvented each time.

---

## Why Coordination Is a Separate Workshop

In L1 you installed six agents, each of which *can* do its own job: the Planner breaks down work, the Architect decides, the Coder writes code, and so on. Each agent's pack encodes *how* it works. What the packs deliberately do **not** encode is how the agents know when it's their turn, how they tell each other they're done, and how they surface trouble. That wiring is coordination — and getting it wrong is the single most common way multi-agent systems fall apart.

Gas City has a deliberately small vocabulary for coordination. There are **five primitives**, and every real factory is composed of them. There is no sixth mechanism. If you find yourself wanting to pass something between agents that doesn't fit one of the five, stop and redesign: the pattern you're inventing will not hold up under operation.

The whole workshop takes about 45 minutes. You'll spend ~20 minutes touring the primitives, ~5 minutes on tradeoffs, and ~20 minutes adding one new coordination method to your factory and testing that it fires.

---

## Prerequisites

Before starting this workshop, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| W2 complete | You've shifted to the pack-based, Config-Over-Prompting mindset | Go back and complete W2 — W3 layers on top of that paradigm |
| L1 complete | `ls ~/Projects/factory/lab_l1/l1-gc-factory/packs/actual/` → all six agent packs (planner, architect, designer, coder, reviewer, deployer) installed | Complete L1 first — W3 edits packs L1 installed on your project |
| Factory registered and runnable | `gc status --city ~/Projects/factory/lab_l1/l1-gc-factory` runs cleanly | Re-run the L1 install step; if `gc doctor --fix` doesn't resolve it, flag to a facilitator |
| Labeled-beads protocol read | You can name at least 3 of the 6 canonical labels from memory | Read [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md) — 5 min |
| `gc` CLI pinned to v0.14.1 | `gc version` prints `gascity 0.14.1` | `brew install gastownhall/gascity/gascity@0.14.1` — see `factory-activity-agent/SKILL.md` |
| Editor open on your factory's pack source | You can browse `~/Projects/factory/lab_l1/l1-gc-factory/packs/actual/` | `code ~/Projects/factory/lab_l1/l1-gc-factory/packs/actual/` |

You do **not** need L2, L3, or L4 complete. W3 runs right after L1: the factory is installed with shipped packs, and L2 (which starts customizing Planner + Architect in depth) comes next. Any coordination rule you add today is forward-compatible with the customizations L2–L4 layer on.

---

## The Running Example: Fired Up Pizza Loyalty Points

We keep using the same Loyalty Points feature you saw run end-to-end in W1's reference factory, so every coordination example below lands on concrete file paths and bead IDs.

Concretely, imagine a feature bead titled **"Loyalty points — earn/redeem"** that will walk through your six-agent factory. At different points in the walk, each coordination primitive comes into play: the Architect emits an ADR and re-labels the bead, the Coder sometimes needs to reach the Architect out of band, a human occasionally needs to steer a live agent away from a bad path. Each primitive description below shows that moment concretely.

If you're working against your own project, substitute the first feature you plan to thread through your factory after W3 (you'll actually drive it through Planner + Architect in L2). A feature with *one* real architectural question and *one* plausible review finding gives every primitive something to demonstrate; a trivial feature does not.

---

## Part 0: Re-Read the Labeled Beads Protocol (~3 min)

Labels on beads are the backbone of coordination. The other four primitives are **supplements**, not replacements. Before we inventory them, make sure the label protocol is fresh in your head.

Open [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md) and skim the "Six canonical labels" table. You should be able to answer, for each of the six labels:

1. Who adds it?
2. Who consumes it?
3. What does the consuming agent do with it?

If any answer is fuzzy, re-read that row of the table before continuing. Every coordination choice you make in the rest of the workshop presumes you know which label routes to which agent.

> **Inline Insight: Labels Are the Floor, Not the Ceiling**
>
> It is tempting to solve every coordination problem by adding labels. Resist this. Labels are for **routing state machines** — "this bead is now ready for stage X." They are poor at nuance ("I think the Reviewer might want to re-check this one") and at urgency ("please look at this before you close your session"). The four primitives below fill those gaps.

---

## Part 1: Inventory the Five Coordination Primitives (~20 min)

Read all five descriptions end to end before picking one for the hands-on. Each primitive is ~3 minutes of reading.

### Primitive 1 · Beads (with labels)

**What it is.** A bead is the unit of work. Its labels are its routing state. An agent polls `bd ready --label <inbound>`; when the upstream agent re-labels a bead to that value, the downstream agent picks it up on its next poll.

**Latency.** Seconds to a few minutes — the agent's poll interval determines the ceiling. The shipped planner polls every 60 seconds (`sleep 60 && bd ready --label=needs-plan`), and the shipped `planner-intake` order re-evaluates on every supervisor tick.

**Durability.** Very high. Beads live in the beads database, are replicated with `bd dolt push`, and survive agent restarts, crashes, and session timeouts.

**Visibility.** High — `bd list`, `bd ready`, and `bd label list-all` all inspect the state of every in-flight bead. The dashboard at `http://localhost:8080` visualizes the queue per label.

**When to reach for it.** Any handoff that is part of the feature lifecycle. If the state is "work has reached stage X," use a label.

**Example from the Loyalty Points feature.** The Architect finishes the ADR and runs `bd label remove <id> needs-architecture && bd label add <id> needs-plan`. The Planner's next poll picks it up.

### Primitive 2 · Mail

**What it is.** `gc mail send <recipient> -s <subject> -m <body>` delivers a persistent message to an agent's mailbox. The recipient reads it on startup (`gc prime`) or explicitly with `gc mail inbox`. Mail is one-to-one, named, and durable.

**Latency.** Higher than beads — the recipient has to be primed or explicitly check its inbox. A running agent does not automatically receive mail mid-session; it picks up new mail on its next `gc prime` or on its next session start.

**Durability.** High — mail is stored per-agent and survives restarts.

**Visibility.** Medium — `gc mail inbox` shows the recipient's view; there is no global "all mail" feed. For shared visibility, use a bead instead.

**When to reach for it.** Escalations, clarifications, and things that aren't "work to do" but are "information the recipient should see when they next wake up." When a Coder hits an acceptance-criterion gap the Planner needs to fix, `gc mail send planner -s "AC unclear on FUP-3" -m "Bullet 3 says 'show total' but doesn't specify rounding"` is the right shape. A bead with a `needs-info` label would also work, but mail is lighter — no queue discipline required.

**Example from the Loyalty Points feature.** The Reviewer finds a schema problem that the Architect should resolve *before* the Coder iterates again. `gc mail send architect -s "Revisit points_ledger isolation level" -m "Current serializable isolation on points_ledger causes deadlocks under concurrent redeem+earn. See review-reports/loyalty-points-review.md:42."`

**Shipped reference.** Every agent's prompt template tells it to call `gc prime` on startup; `gc prime` includes "check `gc mail inbox`." Mail delivery is already part of the workflow if your pack uses the shipped prompts.

### Primitive 3 · Nudges

**What it is.** `gc session nudge <session-id> "<message>"` injects a message into a **currently running** agent session. It's the only way to reach a live session that's in the middle of a work loop. One-to-one, targeted, ephemeral.

**Latency.** Near-zero — the running session sees the message on its next interaction turn.

**Durability.** None. If the session isn't running, the nudge is dropped. If the session restarts, the nudge is gone.

**Visibility.** Low — only the recipient session sees it. `gc session list` shows who's running; past nudges are not persisted.

**When to reach for it.** Urgent, in-session corrections that don't warrant a full bead state change. A humans-in-the-loop example: the Coder is still running and you realize you gave it the wrong acceptance criterion — `gc session nudge <coder-sid> "Stop. Reviewer caught that the rounding rule is cents-down, not half-up. Re-read the updated AC before committing."` catches it before the commit lands.

**Example from the Loyalty Points feature.** The Planner is decomposing a bead into children; you realize mid-decomposition that one of the proposed children would duplicate existing bead FUP-17. `gc session nudge <planner-sid> "FUP-17 already covers the receipt-formatting subtask — skip it in your decomposition."`

**Caution.** Nudges are a firehose for ad-hoc prompting. If you catch yourself nudging the same agent about the same class of mistake twice, that's a config-discipline problem: fix the pack's prompt (L2/L3 teach how) rather than keep re-nudging.

### Primitive 4 · Hooks

**What it is.** Claude Code hooks (configured in each pack's `overlays/default/.claude/settings.json`) and Gas City gates (`gate = "condition"` in an `order.toml`) are **declarative triggers**. They fire automatically when a condition is true or when a session reaches a lifecycle event — `session_start`, `session_live`, stop events — without requiring any agent or human to poll.

**Latency.** Depends on the trigger:
- **Claude Code hooks** fire at the session lifecycle events they're bound to (start, live, stop). Effectively immediate.
- **Gas City order gates** (`gate = "condition"` or `gate = "cooldown"`) are evaluated on the supervisor tick — seconds to a minute.

**Durability.** High for the trigger itself (it's committed config); outcomes are as durable as the action the hook runs.

**Visibility.** Medium — `gc order list` shows the order-based hooks; `settings.json` per pack shows the Claude hooks. There is no global hook-firing log, but hooks that run commands can write to stdout/stderr or to a file.

**When to reach for it.** Automation that has no human in the loop and no ambiguity. Common shapes:

- **"When a session starts, always run the doctor."** A Claude Code `session_start` hook executes `bash scripts/doctor.sh` so every agent boots with a green env or fails loudly.
- **"Every 5 minutes, sync external issues."** Already shipped — see `packs/workshop/orders/sync-jira/order.toml`. The `gate = "cooldown"` + `interval = "5m"` compose a declarative periodic trigger.
- **"When a bead gets labelled `ready-to-ship`, spin up the Deployer."** Already shipped — see `packs/planner/formulas/orders/planner-intake/order.toml` for the pattern (a `gate = "condition"` order watches for a label and wakes the agent via a formula).
- **"On session stop, push bead DB changes."** A Claude `session_stop` hook runs `bd dolt push` so work never strands locally.

**Example from the Loyalty Points feature.** You add a `session_live` hook to the Coder that runs `npm run lint --silent || gc mail send coder -s 'lint failed' -m 'lint failed during session, fix before committing'` every N minutes. If the Coder's code starts drifting off-convention, the agent mails itself a reminder before it commits.

**Shipped reference.** The existing `packs/planner/formulas/orders/planner-intake/order.toml` is the cleanest declarative-trigger example:

```toml
[order]
description = "Wake the planner when any bead is labelled needs-plan"
formula = "mol-plan-breakdown"
gate = "condition"
check = "bd ready --label=needs-plan --limit=1 | grep -q ."
pool = "planner"
```

Every line is config. Nothing is prompted. If the `check` returns true, the supervisor dispatches the Planner via the `mol-plan-breakdown` formula. Your hand-on could add one of these for a label you want to automate.

### Primitive 5 · Files

**What it is.** Artifacts committed to the shared rig directory — `docs/decisions/*.md`, `docs/designs/*.md`, `docs/plans/*.md`, source code, tests, `DECISIONS.md`. Files are the one place where durable content lives between agents; every other primitive above points *at* a file rather than carrying the content itself.

**Latency.** Immediate — once committed, any agent that reads the file picks it up.

**Durability.** Maximum — files are version-controlled; git is the audit trail.

**Visibility.** Maximum — `git log`, `git blame`, `ls docs/decisions/`. Anyone can open the file in an editor.

**When to reach for it.** Anything substantive. Decisions (ADRs), specs (design docs), accumulated knowledge (`PROJECT_MANIFEST.md`), rules (`CLAUDE.md`), and of course the source code itself. Every agent's prompt template names specific files under `docs/` that it reads as inputs and writes as outputs.

**Explicit rule.** Files are the **only** primitive for durable content. If an agent needs to pass more than a sentence to another agent, the right shape is: the upstream agent writes a file, commits it, updates the bead to point at the file, and re-labels. The downstream agent reads the bead, opens the file, acts on its contents. **Do not** stuff multi-paragraph context into a bead description, a mail body, or a nudge — those are pointers, not payloads.

**Example from the Loyalty Points feature.** The Architect writes `docs/decisions/0001-points-storage.md`. The bead's comment is one line: "Decision captured at docs/decisions/0001-points-storage.md; revisit if concurrent-update load exceeds 10 TPS." The Designer reads the file, not the bead comment.

---

## Part 2: Tradeoffs — When to Reach for Which (~5 min)

Read the table below once, top to bottom. In the hands-on you'll pick one row to exercise.

| Primitive | Best when... | Worst when... | Cognitive cost |
|---|---|---|---|
| **Beads (labels)** | State transition is part of the feature lifecycle; many agents need to see the queue | The state is ephemeral ("just this session"); urgency matters more than routing | Low — the six canonical labels are fixed vocabulary |
| **Mail** | Out-of-band note to a specific agent, needs durability, doesn't require blocking | You need real-time interruption; recipient may not wake soon | Low — one command, clear recipient |
| **Nudges** | Live session is drifting and needs correction *now* | Session isn't running; durability matters; same correction recurs | Medium — tempts you into ad-hoc prompting; easy to abuse |
| **Hooks** | Fully-automatable condition, no human judgement, happens often enough to be worth the setup | Condition is subtle or requires reasoning; one-off cases | Higher — you are writing config that has to be right, and debugging requires tracing through supervisor logs or settings.json |
| **Files** | Durable, substantive content; audit trail matters; multiple agents read same input | Content is small and disposable; writing a file is overkill for a single sentence | Low — everyone already knows how files work |

### A quick decision sketch

**"The Coder needs to know the Architect's decision."** → **File** (the ADR). The bead is just a pointer to the file.

**"The Reviewer wants the Coder to redo the fix."** → **Bead** (re-label from `needs-review` back to `ready-to-build` with notes in the bead).

**"The Planner is off-track and I need it to stop decomposing a bead the wrong way."** → **Nudge** (session is live; correction is immediate).

**"The Architect should revisit a decision next time it wakes."** → **Mail** (no urgency; durable).

**"Every 5 minutes, pull new Jira tickets into beads."** → **Hook** (declarative, periodic, no human).

---

> **Inline Insight: The Primitives Don't Stack Randomly**
>
> A well-run factory uses all five, but *not for the same purpose*. Beads carry state. Files carry content. Mail carries out-of-band notes. Nudges carry urgent corrections. Hooks carry automation. If you find yourself putting state in a file, or content in a nudge, stop — you're mixing layers, and the cost shows up later as "why did no one notice that the decision changed?" (Because it was only in a nudge, which disappeared when the session ended.)

---

## Part 3: Hands-On — Add One Coordination Method (~15 min)

You are going to pick **one** primitive you are not currently using (or not using fully) in your factory and wire it in with a declarative config change. This is where Config Over Prompting meets the road: your change lands in a `.toml`, `.json`, or `.md` file, is committed, and works the same way for every future bead without further prompting.

Pick one of the three worked examples below, or design your own in the same shape.

### Option A — Add a mail escalation from Reviewer to Architect

**Scenario.** Your Reviewer will occasionally find issues that require an architectural re-visit (not "the Coder got it wrong" but "the ADR we wrote is incomplete or stale"). By default the Reviewer just rejects the bead back to `ready-to-build` and the problem never reaches the Architect. You want it to.

**What you change.** Edit `packs/reviewer/prompts/reviewer.md.tmpl` (the reviewer pack L1 already installed; you'll customize it in depth during L4). Add a paragraph to the **Handoff** section:

```markdown
### Architectural escalation

If your review finds that the ADR is incomplete, contradictory, or
no longer matches reality — not just that the implementation is
wrong — mail the architect with the evidence:

    gc mail send architect \
      -s "ADR revisit needed: <adr-slug>" \
      -m "review-reports/<slug>.md:<line> — <one-sentence reason>"

Then still re-label the bead back to `ready-to-build` with review
notes so the Coder keeps moving. Mail is the escalation channel;
the bead queue is the work channel.
```

**Why this is a coordination change and not a prompt tweak.** The Reviewer now has an explicit, reproducible rule for when to escalate to the Architect and what channel to use. It is not "I told Claude to escalate" — it is a two-sentence contract committed in the prompt. If you change your mind next month, you edit the prompt, not the chat.

**Validate.** From the Reviewer's agent directory, run:

```bash
gc mail send architect -s "test" -m "smoke"   # sends ok
gc mail inbox --agent architect               # confirms delivery
```

### Option B — Add a `session_start` hook that runs the doctor

**Scenario.** You've had one too many sessions where the agent starts, tries to run `bd`, and discovers bd is not on PATH or the beads DB is stale. Today you catch this manually; you want the session to fail fast on boot.

**What you change.** Edit `packs/coder/overlays/default/.claude/settings.json` (or whichever pack you're hardening). Add a `hooks` block:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": { /* existing permissions stay the same */ },
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "bash scripts/doctor.sh" }
        ]
      }
    ]
  }
}
```

Then create `scripts/doctor.sh` at the pack root (or the rig root) that runs `which bd && which gc && bd list --limit=1 > /dev/null`. Non-zero exit kills the session before it does any work.

**Why this is coordination.** Every session now runs the same check on boot. You can swap the doctor script without touching any agent's prompt. Every agent inherits the rule by the same mechanism.

**Validate.** Start a new Coder session:

```bash
gc session new coder
gc session list   # confirm the session came up (or died on the doctor check)
```

### Option C — Add a new label-triggered order for a role you've added

**Scenario.** In L2 you added a custom "spec-writer" role to your factory (or any other custom agent your project needs). Right now, the only way to route work to it is to run `gc sling spec-writer "..."` manually. You want it to wake automatically whenever a bead gets a `needs-spec` label.

**What you change.** Create `packs/spec-writer/formulas/orders/spec-writer-intake/order.toml`:

```toml
[order]
description = "Wake the spec-writer when any bead is labelled needs-spec"
formula = "mol-spec-write"
gate = "condition"
check = "bd ready --label=needs-spec --limit=1 | grep -q ."
pool = "spec-writer"
```

And reference the new formula in your pack's formulas directory (model it on `packs/planner/formulas/mol-plan-breakdown.formula.toml`).

**Why this is coordination.** The agent now wakes on a declarative condition. Anyone who labels a bead `needs-spec` — Planner, human, another agent — triggers the same wake path. There is no "who invoked gc sling" ambiguity.

**Validate.** Label any bead `needs-spec` and watch for the spec-writer session to start:

```bash
bd label add <bead-id> needs-spec
sleep 90   # one supervisor tick
gc session list | grep spec-writer
```

### Record your choice

Append a one-paragraph entry to `DECISIONS.md` in your project repo:

```markdown
## 2026-04-21 · W3 coordination addition

Chose: <Option A / B / C / custom>
Primitive: <mail / hook / bead-order / etc.>
Rule committed at: <path to file you edited>
Trigger/when it fires: <one sentence>
Removal condition: <one sentence — what would make this rule unnecessary?>
```

The removal condition keeps coordination from accreting forever. If you can't write one, treat that as a signal — maybe the rule is not load-bearing and you're adding it out of caution rather than need.

---

## Part 4: Verify the Rule Fires (~5 min)

Every coordination rule you add has to be *observably firing* or it's not a coordination rule — it's a wish.

Pick the applicable verification for your option:

**For mail (Option A).** Create a dummy review report that mentions an ADR gap, run the Reviewer end-to-end on a test bead (or simulate by calling the mail command directly), then run `gc mail inbox --agent architect`. The mail should be there. Screenshot or paste the output into your W3 `DECISIONS.md` entry.

**For hooks (Option B).** Cold-start a new session; watch stdout for the doctor script output. If you want to prove the hook fires, deliberately break the check (rename `bd` temporarily) and confirm the session dies on boot with the doctor's error.

**For orders (Option C).** Label a test bead with the trigger label; within one supervisor tick (~60s) the agent session should appear in `gc session list`. If it doesn't, check `gc order list` to confirm the order is registered, and re-run `gc doctor --fix`.

If the rule doesn't fire, the most common causes are (in order):

1. **Config file not picked up** — packs are re-read on `gc register` / `gc start`. Run `gc restart` after editing.
2. **Typo in the condition string** — `bd ready --label=needs-spec` vs. `--label needs-spec` (spacing matters to the shell).
3. **Pool not defined** — `pool = "spec-writer"` has to match a pool configured in `city.toml`.
4. **Permissions deny the command in hooks** — Claude hooks run with the agent's permissions; your `scripts/doctor.sh` call must be allow-listed in `settings.json` under `permissions.allow`.

---

## Config Over Prompting — Applied to Coordination

Every primitive you just learned except **nudges** is declarative:

- Beads + labels live in the beads database; label transitions are one command.
- Mail commands land in prompt templates, so they are committed config.
- Hooks live in `settings.json` and `order.toml`; pure config.
- Files are, by definition, committed artifacts.

Only **nudges** are ad-hoc — and that's the one primitive you should use with discipline. Every time you reach for a nudge, ask: *"If I had to do this again tomorrow, would I nudge again, or would I rather have a hook/mail/label do it for me?"* If the answer is the second one, the nudge is revealing a coordination gap. Close the gap via config.

This is the same Config Over Prompting discipline W2 introduced, specialized to inter-agent coordination. A factory that's coordinated via declared config + occasional nudges is operable overnight. A factory coordinated via nudges with occasional config is a workshop with extra steps.

---

## Common Issues & Solutions

### Issue 1: Mail stuck in inbox

<details>
<summary>Solution</summary>

**Symptom:** `gc mail inbox` shows messages but the recipient never acts on them.

**Fix:** Recipient's prompt template doesn't include `gc prime` on startup (or `gc mail inbox` explicitly). Edit the pack's prompt, not the current session.

</details>

### Issue 2: Hook fires on every tool call

<details>
<summary>Solution</summary>

**Symptom:** `SessionStart` hook actually runs on something broader.

**Fix:** Check the `matcher` regex; `.*` is "all". Narrow it to the specific event if you only want certain triggers.

</details>

### Issue 3: Order never wakes the agent

<details>
<summary>Solution</summary>

**Symptom:** Bead is labelled, minutes pass, no session.

**Fix:** (1) `gc order list` — is your order registered? (2) `check` condition — run it manually at the shell, does it succeed? (3) `pool` — does it match a pool in `city.toml`?

</details>

### Issue 4: Nudge ignored

<details>
<summary>Solution</summary>

**Symptom:** Message sent, session shows no sign of receiving it.

**Fix:** Session wasn't running, or the session was mid-tool-call and hadn't returned to the model yet. Confirm with `gc session list` (active column) before nudging.

</details>

### Issue 5: Agent overwrites a file another agent was editing

<details>
<summary>Solution</summary>

**Symptom:** Two sessions race on `docs/PROJECT_MANIFEST.md`.

**Fix:** Files aren't protected by the primitives — add a bead `blocks` edge (`bd dep add child blocks parent`) so one agent can't run while another holds the file.

</details>

### Issue 6: Coordination rule works but doesn't survive reinstall

<details>
<summary>Solution</summary>

**Symptom:** Works in this session, missing after `factory-activity-agent delete && install`.

**Fix:** You edited a live-session overlay, not the pack source. Always edit under `packs/<name>/...`, not under `~/Projects/factory/.../packs/actual/<name>/...` which is a copy.

</details>

### Issue 7: Mail subject collisions

<details>
<summary>Solution</summary>

**Symptom:** Two agents both send `-s "review found issue"` and recipient can't tell them apart.

**Fix:** Subject convention: `<scope>:<action>` — e.g. `adr:revisit-needed` or `coder:ac-unclear`. Namespace by subsystem, not by sender (sender is in metadata).

</details>

### Issue 8: `session_live` hook runs on every keystroke

<details>
<summary>Solution</summary>

**Symptom:** Hook is too chatty.

**Fix:** `session_live` fires on session activity; use it sparingly. Prefer `session_start` for one-shot boot checks and `session_stop` for end-of-work actions like `bd dolt push`.

</details>

### Issue 9: Nudge appears to do nothing, then agent changes behavior 10 min later

<details>
<summary>Solution</summary>

**Symptom:** Agent was mid-turn; the nudge landed in the next conversation turn.

**Fix:** Normal. Nudges aren't interrupts; they're messages that land at the next turn boundary.

</details>

### Issue 10: Hook writes to stdout, no one reads it

<details>
<summary>Solution</summary>

**Symptom:** Hook is firing but you can't see it.

**Fix:** Redirect hook output to a file (e.g., `bash scripts/doctor.sh 2>&1 >> .gc/logs/doctor.log`) and `tail -f` it during development.

</details>

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] You can name all five primitives (beads, mail, nudges, hooks, files) and state when you'd reach for each.
- [ ] You picked **one** primitive that wasn't previously active in your factory and wired it in via config (not prompt corrections).
- [ ] The config change is committed in the pack source — not in the live session copy.
- [ ] You observed the rule firing: mail delivered, hook ran, order woke the agent, or the new file was read by its consumer.
- [ ] `DECISIONS.md` has a W3 entry naming the rule, its trigger, and a removal condition.
- [ ] `git status` is clean in the pack repo — your change is committed.

**W3 blocks L4.** L4 wires in the Reviewer and Deployer, and one of the options you may choose in L4 is to build on the coordination primitive you introduced here (e.g., extend Option A's escalation-mail to Deployer → Reviewer for deploy failures).

---

## Command Cheat Sheet

Every command you'd run during (or immediately after) this workshop:

```bash
# PART 0 — Read labeled-beads protocol
# Open software-factory/LABELED_BEADS.md and skim

# PART 1 — Inspect the five primitives in your factory
bd label list-all                                # labels currently in use
gc mail inbox                                    # your mayor inbox
gc session list                                  # live sessions (for nudges)
gc order list                                    # declarative triggers
ls docs/decisions/ docs/plans/ docs/designs/     # file artifacts

# PART 3 — Hands-on: pick one option

# Option A: mail
# (edit packs/reviewer/prompts/reviewer.md.tmpl)
gc mail send architect -s "smoke" -m "test"
gc mail inbox --agent architect

# Option B: hooks
# (edit packs/coder/overlays/default/.claude/settings.json)
# (create scripts/doctor.sh)
gc restart                                       # re-read settings
gc session new coder
gc session list

# Option C: orders
# (create packs/<agent>/formulas/orders/<agent>-intake/order.toml)
gc restart
bd label add <bead-id> needs-spec
sleep 90 && gc session list | grep spec-writer

# PART 4 — Verify firing
gc order list                                    # is your order registered?
tail -f .gc/logs/doctor.log                      # for hook-based rules
gc mail inbox --agent <recipient>                # for mail-based rules

# Commit
cd ~/Projects/factory/<slug>/<alias>-gc-factory/packs/actual/
git add <path to edited pack>
git commit -m "W3: add <coordination primitive> for <scenario>"
git push
```

---

## Quick Reference: What You Produced

| Component | File | What It Does |
|---|---|---|
| Coordination rule | `packs/<agent>/{prompts,overlays,formulas/orders}/...` | One new primitive wired into your factory |
| Decision record | `DECISIONS.md` (W3 entry) | Rule, trigger, removal condition — future-you will thank you |
| Primitive count used in your factory | ≥ 2 (was: beads + files; now: + one of mail/nudges/hooks, or a richer use of beads) | The factory now exercises multiple coordination layers |

---

## Next Steps

In **L4**, you'll:

- Install the Reviewer and Deployer packs, completing the 6-agent pipeline
- Watch your factory run the full Planner → … → Deployer path on a single feature
- If you chose Option A today, see your Reviewer → Architect escalation fire on a real review finding
- Optionally add a second coordination rule (the natural pairing for Option B is a `session_stop` hook that runs `bd dolt push`; for Option A, a symmetric Deployer → Reviewer mail on deploy-gate failure)

**Bring to L4:** the coordination rule you committed today, your `DECISIONS.md` entry, and — most importantly — the habit of asking "is this a nudge or a config change?" before every inter-agent correction you make. That question is the difference between a factory you operate and one that operates itself.
