# W4 · Create Continuous Improvement Loops

> **Goal:** Add the optional 7th agent — the **Improver** — to your factory, run it against the runtime signals your six-agent pipeline already emitted in L2–L4, and watch it turn a `needs-improve` bead into one concrete proposed config change on one of the 6 essential agents. Then leave with an honest mental model of why self-improvement is *hard*, what makes the narrow slice safe, and when to say no.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | Workshop |
| **Deliverable** | `improver` pack wired into your factory, one `docs/feedback/<date>.md` harvest summary committed in your project rig, and one config change committed on one of the 6 essential agent packs in response to a bead the Improver filed |

---

## Session workspace note

* **Pack source (shipped):** `packs/improver/` under the `software-factory/` tree. The agent is named `improver`; the pack is named `actual-improver`.
* **Gas City workspace:** `my-factory/` — where `city.toml` lives. W4 adds **one** line to `includes` (the improver pack) and that's the only workspace edit.
* **Your deliverables this session:** the wired pack, a harvest summary under `docs/feedback/` in your project rig, and a commit on one of the six essential packs (`planner` / `architect` / `designer` / `coder` / `reviewer` / `deployer`). If your workshop uses an activity folder, put any session notes at `activities/workshops/W4/notes.md`.
* **Not a core agent.** The factory is complete at six. Improver is the **optional 7th** — adding it turns the factory into a *learning* factory. Leaving it out is a perfectly legitimate choice, and a factory without an improver still ships.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should first run `bd list --label=needs-improve --status=open` and `gc mail inbox --agent reviewer` on the participant's factory so every Improver example lands on their real L2–L4 output. If both are empty, fall back to the reference project's closed bead history — but flag the fallback to the participant before proceeding.

---

## Why the 7th Agent Is Optional

The six essential agents close a loop from feature-request to shipped code: Planner → Architect → Designer → Coder → Reviewer → Deployer. That loop is self-contained. Every bead that enters `needs-plan` eventually reaches `ready-to-ship` or `closed`, and every rule the factory follows lives in a committed pack prompt or formula. You can run this factory for months without an Improver — you just have to read your mail, your review notes, and your deploy gates by hand, decide what needs changing, and file upstream beads yourself.

That manual loop is fine, and sometimes preferable. The moment you add a 7th agent that reads runtime signals and files beads for the other six, you also add the risks unique to self-improvement: **loop divergence** (the improver's output becomes its own input), **reward hacking** (the agent optimizes the signal, not the underlying goal), and **drift** (small prompt changes compound into a factory that no longer resembles the one you started with). Part 4 of this workshop treats those failure modes head-on.

So: the Improver is optional by design. The factory's essential definition is six. Turning it on commits you to a different operating discipline — one where every proposal the Improver files is reviewed by a human before any prompt is edited.

---

## Architecture Diagram

```
   (feature walks Planner → Architect → Designer → Coder → Reviewer → Deployer,
    emitting notes, mail, and gate verdicts as it goes — all from L2–L4)
                                       │
                                       ▼  deployer closes bead; emits needs-improve
                          ┌──────────────────────────┐
                          │   RUNTIME SIGNALS         │
                          │                            │
                          │   • bead notes (reviewer   │
                          │     findings, gate checks) │
                          │   • mail between agents    │
                          │   • closed bead metadata   │
                          │   • errors / metrics / CI  │
                          │     (if the rig exposes it)│
                          └───────────────┬──────────┘
                                          │
                                          ▼  cooldown: 24h (or manual harvest)
                          ┌──────────────────────────┐
                          │   IMPROVER (optional 7)   │
                          │                            │
                          │   mol-feedback-harvest:    │
                          │     collect → classify →   │
                          │     propose → file-beads   │
                          │                            │
                          │   writes                    │
                          │   docs/feedback/<date>.md  │
                          └───────────────┬──────────┘
                                          │
                                          ▼  new labeled beads
         ┌──────────────────────────────────────────────────────────┐
         │                                                            │
         │  needs-architecture  needs-plan  needs-design              │
         │  ready-to-build      needs-review                          │
         │        │                  │              │                  │
         │        ▼                  ▼              ▼                  │
         │    architect           planner        designer / coder /    │
         │                                       reviewer              │
         └──────────────────────────────────────────────────────────┘
                                          │
                                          ▼  (a human reviews the proposed bead)
                                  ACCEPT → config change commit on target pack
                                  REJECT → close bead with reason
                                          │
                                          ▼
                          next factory run with the improvement baked in
```

Three things to notice before you run anything:

1. **The Improver does not edit prompts or code.** It files beads. Every config change still goes through a human.
2. **The trigger is a cooldown, not a label.** The Improver wakes every 24 hours whether or not a `needs-improve` bead exists. That's because runtime signals show up on their own schedule — you can't label them in advance.
3. **The output is ordinary labeled beads.** Nothing about the Improver's output is special — its beads walk the same `needs-architecture` / `needs-plan` / `needs-review` routes every other upstream bead walks. The factory doesn't grow a new handoff protocol; the Improver just becomes a new *source* on the existing one.

---

## Prerequisites

Before starting this workshop, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L4 complete | `gc status` shows reviewer + deployer alongside the upstream four | Go back and complete L4 — W4 is about learning from L4's output, so L4 has to have produced some |
| At least one bead walked end-to-end | `bd list --status=closed --limit=5` shows a bead that passed through `needs-review` → `ready-to-ship` → `closed` | Re-run the L4 handoff on a synthetic bead; even one closed bead is enough |
| At least one `needs-improve` bead | `bd list --label=needs-improve --limit=5` shows at least one open bead | L4's deployer emits one per deploy. If yours is missing, re-run the deploy handoff, or create one: `bd create --title "Seed: needs-improve from L4" --label needs-improve --notes "placeholder signal for W4"` |
| Recent inter-agent mail | `gc mail inbox --agent reviewer` or `--agent coder` shows at least one message | Not strictly required, but a factory with no mail traffic means the Improver will produce a very thin summary — consider slinging one Reviewer→Coder escalation first |
| `jq` installed | `command -v jq` returns a path | `brew install jq` / `apt install jq` — the harvest molecule pipes bead JSON through it |
| `bd`, `gc`, `git` on PATH | `gc doctor` green for existing packs | Re-run install; `gc doctor --fix` where applicable |

If any row fails, stop and fix it. The Improver is only as useful as the signals it reads — a factory that hasn't emitted any output yet is not a factory you can learn from.

---

## The Running Example

Carry forward the same feature you walked through L2–L4 — in the reference project that's **Loyalty Points**; in your own factory it's whichever feature you drove end-to-end. By the end of L4 you have a committed trail of artifacts:

```
bd show <loyalty-points-bead-id>      # closed, with review notes + gate verdict
gc mail inbox --agent reviewer        # at least one Reviewer→Coder escalation
gc mail inbox --agent architect       # possibly an "ADR revisit" note
bd list --label=needs-improve         # deployer-emitted bead, still open
```

Concretely, assume the Reviewer flagged twice that acceptance criterion #3 ("user sees earned points on the receipt") was not exercised by any test, the Coder patched it by adding one narrow assertion, and the Deployer shipped anyway because the verdict was `pass` on the second round. That's a live pattern the Improver should catch: AC coverage is technically green, but the Reviewer's rubric is loose enough that thin assertions slip through. The fix is not a code change; it's a rubric change.

We'll thread that pattern through every Part below. If your own factory produced a different pattern — missing null checks, inconsistent error envelopes, flaky deploy smoke tests — substitute it. The shape is the same: a recurring signal in bead notes or mail that points at one agent's prompt or formula.

---

## Part 0: Read the Improver Pack (~5 min)

Before installing anything, read the four files that define the Improver. You are reading them in the same shape as L4's Part 0 — pack metadata, prompt, formula, order gate.

### Step 1: Open `packs/improver/pack.toml`

[`packs/improver/pack.toml`](../../../packs/improver/pack.toml). Three things to notice:

```toml
[pack]
name = "actual-improver"

[[agent]]
name = "improver"
wake_mode = "fresh"
nudge = "Run 'gc prime', then check bd ready --label=needs-improve and run mol-feedback-harvest."
idle_timeout = "2h"
min_active_sessions = 0
max_active_sessions = 1
```

- **`wake_mode = "fresh"`.** Every wake re-derives state from beads and the filesystem; there is no cached status doc. Same paradigm as every other essential agent.
- **`min_active_sessions = 0`.** The Improver doesn't run a persistent session — it sleeps, wakes on the cooldown, runs the molecule, exits.
- **`max_active_sessions = 1`.** There's only ever one Improver running at a time; parallelism would race on the daily summary file.

### Step 2: Open `packs/improver/prompts/improver.md.tmpl`

[`packs/improver/prompts/improver.md.tmpl`](../../../packs/improver/prompts/improver.md.tmpl). The persona is three roles triangulated: **SRE + Performance Engineer + Developer Advocate**. Skim the *What you do NOT do* block — it is load-bearing:

```markdown
## What you do NOT do

- Implement fixes yourself. You route work upstream.
- Silence alerts. You file beads.
- Make architectural calls alone. You hand decisions back to the
  architect.
```

Those three rules are why adding the Improver does not collapse safety: every action it takes is a bead, not a diff. A human or the right upstream agent still owns the change.

### Step 3: Open `packs/improver/formulas/mol-feedback-harvest.formula.toml`

[`packs/improver/formulas/mol-feedback-harvest.formula.toml`](../../../packs/improver/formulas/mol-feedback-harvest.formula.toml). Four steps:

| Step | What it does | Output |
|------|--------------|--------|
| `collect` | Gather runtime signals from whatever the rig exposes — error trackers, metrics, logs, user feedback, CI, dep CVEs | `docs/feedback/<today>.raw.md` |
| `classify` | Assign each signal a type (bug / perf / ux / docs / arch / security / test-gap) and a severity (p0–p2) | `docs/feedback/<today>.md` |
| `propose` | Draft a bead per actionable row: title, upstream label, severity, body with evidence | appended to the summary under `## Proposed beads` |
| `file-beads` | Create the drafted beads with the right labels, close source `needs-improve` beads, wake downstream agents via intake orders | new labeled beads |

The formula takes two vars: `since` (default `"24h"`) and `feedback_dir` (default `docs/feedback`). The manual `harvest` command lets you widen `since` to e.g. `7d` so the first run covers your whole L2–L4 history.

### Step 4: Open the order gate

[`packs/improver/formulas/orders/improver-cooldown/order.toml`](../../../packs/improver/formulas/orders/improver-cooldown/order.toml):

```toml
[order]
description = "Run the feedback harvest on a daily cooldown"
formula = "mol-feedback-harvest"
gate = "cooldown"
interval = "24h"
pool = "improver"
```

The key word is **`gate = "cooldown"`**. Every other pack you've installed uses `gate = "condition"` and watches `bd ready --label=<something>`. The Improver doesn't — there isn't a label for "runtime emitted interesting signals in the last day," so the order fires on a schedule instead. This is the one place the factory breaks its own label-driven rhythm, and the reason is deliberate: runtime signals don't ask for attention on a label, they accrue quietly over time. The cooldown is how you go check on them.

You're done reading. Install next.

---

## Part 1: Wire the Improver Into Your Factory (~10 min)

> **Agent Guide:** Before the participant copies the pack, ask: "Do you intend to keep this agent after the workshop, or are you experimenting?" Either answer is fine — the copy-and-include path below works for both. If they're firmly experimenting-only, the shipped-as-is alternative at the end of this Part is lighter.

### Step 1: Copy the improver pack into your workspace

Same shape as L4 did for reviewer and deployer — copy the shipped pack into `my-factory/packs/`, then include your copy:

```bash
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/improver packs/improver
```

(Adjust the source path to your checkout if needed — it points at `packs/improver/` in the software-factory tree.)

### Step 2: Add the include

Open `my-factory/city.toml` and add one entry to `includes`:

```toml
includes = [
    # ... the six essential entries from L2 / L3 / L4 ...
    "packs/improver",                           # NEW — optional 7th agent
]
```

### Step 3: Restart and verify

```bash
cd my-factory
gc service restart
gc doctor
gc status
```

`gc doctor` should pass `check-improver` (verifies `bd`, `gc`, `jq`). `gc status` should list `improver` alongside the six essential agents. If it's missing, `gc rig list` tells you whether the include resolved; the most common cause is a wrong relative path in the include.

### Step 4: Confirm the cooldown order is registered

```bash
gc order list | grep improver
```

You should see:

```
improver-cooldown   cooldown   24h   improver
```

That's the declarative trigger — it wakes the Improver on the next supervisor tick after 24h elapses. You are not going to wait 24h. Part 2 kicks off a manual harvest.

### Step 5: Commit the wiring

```bash
cd my-factory
git add city.toml packs/improver
git commit -m "chore(W4): wire optional improver pack into my-factory"
```

### Alternative: shipped-only (no copy, no customisation)

If you're purely experimenting and don't want a local copy, skip Step 1 and point the include at the shipped pack directly:

```toml
# my-factory/city.toml
includes = [
    # ... existing six entries ...
    "../software-factory/packs/improver",       # NEW — shipped, read-only
]
```

Then commit only `city.toml`. Steps 3–4 still apply. You give up the ability to tune the persona or formula vars in-place; in exchange, you save one directory.

> **Inline Insight: The Improver Is a Pack, Not a Protocol**
>
> Note that wiring the Improver is the same shape as wiring the Planner, Architect, or any other agent — one include line, one restart, one `gc doctor`. The factory's operating surface does not grow when you add the 7th agent. The only new thing is a cooldown order gate, which is already a supported Gas City primitive (you saw one in W3 for the periodic jira sync). This matters: if adopting the Improver required new framework concepts, the option to say no later would be expensive. It doesn't, so it isn't.

---

## Part 2: Run a Feedback Harvest (~15 min)

This is where you *experience* the self-improvement step. You have real signals from L2–L4 sitting in bead notes and mailboxes. The Improver's job is to read them and file upstream work.

### Step 1: Inventory the signals the Improver will read

Before slinging anything, see what the Improver will see:

```bash
cd my-factory
bd list --label=needs-improve --status=open          # deployer-emitted source beads
bd list --status=closed --since="14 days ago"        # recent closed work with notes
gc mail inbox --agent reviewer                        # review findings the Coder acted on
gc mail inbox --agent architect                       # ADR revisits, if any
gc mail inbox --agent coder                           # Coder's own escalations
```

At minimum you should see one `needs-improve` bead (from L4's deployer), one closed bead with review notes, and one mail between two agents. If any of those three is absent, this is a thinner harvest than ideal — the Improver will still run, but its summary will reflect what it found. Thinness is signal too.

### Step 2: Trigger the harvest manually

Don't wait 24h. The shipped `harvest` command slings the Improver on the formula with whatever time window you pass:

```bash
cd my-factory
sh packs/improver/commands/harvest.sh 7d
```

(If you used the shipped-only alternative in Part 1, point at `../software-factory/packs/improver/commands/harvest.sh` instead.)

This runs `gc sling <rig>/improver --on mol-feedback-harvest --var since=7d` — a single synchronous walk through the four molecule steps. Watch it progress:

```bash
gc watch improver
```

The session should take roughly 2–5 minutes depending on how many signals you have. If it runs longer than 10, something's stuck — check `gc session list` and `gc events --follow` for errors.

### Step 3: Read what the Improver produced

Two files land in your project rig:

```bash
cd ~/path/to/your-repo
ls docs/feedback/
cat docs/feedback/<today>.raw.md          # the collected raw signals
cat docs/feedback/<today>.md              # classified summary + proposed beads
```

The raw file is the input side — whatever signals the Improver could actually reach (bead notes, mail bodies, and anything else the rig exposes). The summary is the classified output:

```markdown
# Feedback harvest 2026-04-22

| # | Type | Severity | Signal | Proposed action | Upstream agent |
|---|------|----------|--------|-----------------|-----------------|
| 1 | test-gap | p2 | Reviewer flagged AC #3 uncovered on 2 of 3 features; patches were thin 1-line assertions | Tighten reviewer AC rubric to require behavioural assertion, not presence | reviewer |
| 2 | arch | p2 | Deployer rollback plan for points_ledger migration was TODO on 2 of 2 releases | File architecture bead: define backout protocol for ledger migrations | architect |

## Proposed beads

### 1. reviewer / test-gap / p2
Title: Reviewer prompt: require behavioural assertion on AC coverage, not presence
Label: needs-review
Body: ...

### 2. architect / arch / p2
Title: Define rollback protocol for ledger migrations
Label: needs-architecture
Body: ...
```

Your actual output will differ — but the *shape* is this table plus drafted beads. Two things to check:

1. **Are the signals real?** Scan the "Signal" column and confirm each row maps to something you yourself would recognize from your factory's last week. If a row cites a signal you don't believe exists, the Improver hallucinated — which happens, and which is exactly why Part 3 starts with a human review gate.
2. **Are the upstream agents right?** A `test-gap` that's really a Coder prompt issue should route to the Coder (`ready-to-build`), not the Reviewer (`needs-review`). Disagreements at this stage tell you something about the persona's routing heuristics; save them — they become feedback *on* the Improver for the next iteration.

### Step 4: Inspect the beads the Improver filed

```bash
bd list --label=source:actual-improver --limit=10
bd show <one-of-them>
```

Each proposed bead has:
- A real label (one of the canonical six)
- A severity label (p0 / p1 / p2)
- A `source:actual-improver` tag — so you can always tell which beads were filed by the Improver vs. by a human
- Body with evidence, a proposed action, and links back to the raw signal

The `needs-improve` source bead(s) from L4 should now be **closed** with reason "feedback harvested <date>". Confirm:

```bash
bd list --label=needs-improve --status=closed --since="1 day ago"
```

That close is the other half of the self-improvement loop — the trigger that said "something needs learning" has been converted into concrete upstream work, and the trigger itself is retired.

### Step 5: Commit the summary

```bash
cd ~/path/to/your-repo
git add docs/feedback/
git commit -m "feedback(improver): daily harvest ${date} — N signals classified, M beads filed"
```

The raw file stays committed too. It is the audit trail for every proposed bead: if someone later asks "why did the Improver file bead X?", the raw signals that led to it are one `git show` away.

---

## Part 3: Act on One Proposed Bead (~10 min)

> **Agent Guide:** Before the participant changes any prompt, ask: "Does this proposal match a pattern you'd have caught yourself?" If yes, the Improver is doing its job and the change is safe to apply. If no — if the participant wouldn't independently agree with the proposal — reject the bead instead. A rejected-bead is a success; a silently-applied wrong proposal is not.

You now have one or more beads with a canonical label, filed by the Improver, sitting in the queue. Pick the **one** that most directly improves one of the 6 essential agents' prompts or formulas, and walk it to resolution.

### Step 1: Read the proposed bead end-to-end

```bash
bd list --label=source:actual-improver --limit=10
bd show <chosen-bead-id>
```

Check the body for:
- **Concrete evidence.** A line number, a bead reference, a mail subject, a grep match — not "I felt like this was a problem."
- **A one-sentence proposed action** that names the file to edit.
- **The right upstream label** (e.g. `needs-review` for a Reviewer-prompt change, `needs-architecture` for a cross-cutting constraint).

If the evidence is vague or the proposed action hand-waves, close the bead with a reason:

```bash
bd close <bead-id> --reason "insufficient evidence: <one sentence>"
```

Rejecting a proposed bead is not failure. It is exactly the human-in-the-loop gate working.

### Step 2: Apply the config change on the target pack

Using the running example — the Improver proposed tightening the Reviewer's AC rubric so thin "presence" assertions don't pass as coverage. The target file is `packs/reviewer/prompts/reviewer.md.tmpl`. Open it and find the AC-coverage block:

```markdown
> AC coverage
>
> - Every acceptance criterion on the bead must be exercised by at
>   least one test.
```

Tighten the bullet with the Improver's proposed wording:

```diff
 > AC coverage
 >
 > - Every acceptance criterion on the bead must be exercised by at
-  least one test.
+  least one test, and that test must assert on the *behaviour* in
+  the acceptance criterion, not merely on the presence of the
+  returned data. A test that only checks "the response has a
+  `points` field" does not cover the AC "user sees earned points
+  on the receipt."
```

Your edit will differ. The shape is the same: one narrow bullet, linked to a specific signal the Improver found, landing in the prompt of one specific agent.

### Step 3: Restart, verify, commit

```bash
cd my-factory
gc service restart
gc doctor                    # still green
cd ~/path/to/your-repo
git -C my-factory add packs/reviewer/prompts/reviewer.md.tmpl
git -C my-factory commit -m "chore(reviewer): require behavioural AC assertions (from improver harvest $(date -u +%F))"
```

Notice the commit message threads the provenance: "from improver harvest <date>". In three months, `git log packs/reviewer/prompts/reviewer.md.tmpl` gives you a timeline of every improvement the Improver surfaced *and* a pointer back to the feedback summary that justified it. That is the audit trail the human-in-the-loop gate produces for free.

### Step 4: Close the proposed bead

```bash
bd close <chosen-bead-id> --reason "applied to packs/reviewer/prompts/reviewer.md.tmpl in commit <sha>"
```

The bead is closed because the config change landed. The change is *not* yet verified — that happens on the next Reviewer run, which will exercise the tightened rubric against a real feature. If the Reviewer starts over-flagging or under-flagging after the change, that is itself a new signal that the next Improver harvest will pick up. That is the loop.

> **Insight: Self-improvement is one commit, not one system.**
>
> Every useful improvement the Improver produces reduces to a single config-change commit on a pack you already owned. The Improver didn't modify the factory's shape. It surfaced a pattern and gave you language for it. Across ten cycles you'll average maybe two commits per week on agent packs — tiny, reversible, pointed — and the factory's quality compounds. The moment an "improvement" requires a bigger change than one pack's prompt, the Improver hands it off to a human architect or to the Planner for real decomposition, not to itself.

---

## Part 4: Why Self-Improvement Is Hard (~5 min)

Read this Part. There is no hands-on — the point is to leave the workshop with an honest mental model, not the impression that you've solved continuous improvement.

Self-improvement in agentic systems fails in four recognisable ways. Each one has shown up in real deployments; each one is easy to wave away until it costs you a week.

**1. Loop divergence.** The Improver's output becomes the input it reads next cycle. If a cycle files ten beads and the next cycle reads them as "signals," the Improver starts counting its own opinions as evidence. In extreme cases the system converges on its own favourite pattern, filing the same bead repeatedly with diminishing real-world justification. *Mitigation:* the shipped harvest molecule explicitly ignores beads tagged `source:actual-improver` when collecting signals. Check yours does too before you trust any extension you make to it.

**2. Reward hacking.** Once the Improver knows what "good" looks like, it optimizes for the signal, not the outcome. If the signal is "Reviewer finds fewer blockers," the easiest way to move that number is to make the Reviewer less strict. An Improver that can file beads against Reviewer prompts is one short step from proposing a rubric loosening that makes its own past proposals look successful. *Mitigation:* the Improver never proposes changes that would suppress a signal (make the reviewer less strict, widen the deployer's gate). The persona's constraints ("measure before optimizing, error budgets guide risk tolerance") push the same way, but the stronger safeguard is the human-in-the-loop review in Part 3.

**3. Drift.** Small prompt changes compound. After ten weeks of tiny improvements, the Coder's prompt has grown by forty bullets, half of which contradict each other. The factory still runs, but its behaviour no longer resembles the one you shipped — and no one deliberately chose the current one. *Mitigation:* cap the rules section of every pack prompt at a fixed line count. When adding a bullet would exceed the cap, the Improver must file a `needs-architecture` bead for a human to consolidate instead of a direct prompt edit. The shipped persona encodes the spirit of this ("never file a vague bead") but the cap is a separate discipline you impose in the Architect's rules.

**4. Ambiguous ownership.** When a proposal touches more than one pack, no agent owns the change. Three weeks later a different proposal contradicts it, and reconciling them is a cross-cutting effort no one scheduled. *Mitigation:* the Improver files **one** bead per signal and routes it to the single most appropriate upstream agent. If a signal genuinely spans multiple agents, it is always routed to the Architect first — the Architect owns cross-cutting constraints by construction, and fans out from there.

What makes self-improvement *work*, in the narrow slice where it does:

- **Tight feedback.** The signal and the change are close in time and scope. Yesterday's Reviewer miss gets corrected in this week's prompt.
- **Bounded changes.** Every proposal is one bullet on one file. Changes larger than that escalate to an architect.
- **Human-in-the-loop gates.** Every proposed bead passes through a human review before any config is edited. In practice this is you reading the harvest summary and accepting or rejecting.
- **Reversibility.** Every config change is one `git revert` away from gone. If the next Reviewer run shows the tightened rubric is wrong, back it out and file a new signal for the next harvest.

When your factory violates any of those four, stop. Close the improver-filed beads. Go look at the last week of agent pack commits. Ask whether the factory you operate today is the one you intended.

---

## Concept Check (before moving to L5/C1)

> **Agent Guide:** Before declaring the session complete, ask the participant to answer each bullet in their own words without re-reading. If any answer is vague, revisit the matching Part.

- Why the Improver is optional — what you give up by not running it, and what you commit to by running it.
- Why the Improver's output is beads, not diffs — and what would go wrong if it edited prompts directly.
- The four-step flow: `collect → classify → propose → file-beads`, and which step the human reviews.
- Four named self-improvement failure modes (loop divergence, reward hacking, drift, ambiguous ownership), and one mitigation for each.
- Why the Improver wakes on a cooldown, not a label.

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `gc status` lists `improver` alongside the six essential agents.
- [ ] `gc order list | grep improver-cooldown` shows the cooldown order registered.
- [ ] `docs/feedback/<today>.md` committed in your project rig, with at least one classified row and one drafted bead.
- [ ] At least one bead labeled `source:actual-improver` exists, filed by this session's harvest.
- [ ] At least one of those beads was acted on: either (a) closed with a reason after human review rejected it, or (b) resolved by a commit on one of the 6 essential agent packs (`packs/<name>/prompts/*.md.tmpl` or a formula), with the bead closed referencing the commit.
- [ ] `git status` clean in both `my-factory/` and your project rig.

**W4 feeds L5.** The capstone assumes the Improver is wired; L5's end-to-end run includes a harvest as the final step, and the feedback summary it produces is one of the retrospective artifacts you'll audit.

---

## Next Steps

In **L5**, you'll:

- Combine the six essential packs (with your L2–L4 customisations) plus the optional 7th into one end-to-end factory run
- Drive a new feature from `needs-plan` to `closed`, then let the Improver harvest immediately after
- Audit what the Improver caught (and what it missed) as part of the retrospective

**Bring to L5:**
- Improver wired and doctor-green
- At least one `docs/feedback/*.md` summary committed
- The commit on one essential pack that closed an Improver-filed bead — you'll use it as the "what got better" artifact in the capstone retrospective
- An explicit answer, in your own head, to "which of the four failure modes in Part 4 would I be most likely to hit on my own project, and how would I notice?"

---

## Command Cheat Sheet

Every command you'd run during this workshop:

```bash
# PART 0 — read the shipped pack
cat packs/improver/pack.toml
cat packs/improver/prompts/improver.md.tmpl
cat packs/improver/formulas/mol-feedback-harvest.formula.toml
cat packs/improver/formulas/orders/improver-cooldown/order.toml

# PART 1 — wire into my-factory (copy + include)
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/improver packs/improver
$EDITOR city.toml                     # add "packs/improver" to includes
gc service restart
gc doctor                             # green
gc status | grep improver             # appears alongside the six
gc order list | grep improver         # cooldown registered
git add city.toml packs/improver
git commit -m "chore(W4): wire optional improver pack into my-factory"

# (alternative: shipped-only, skips the copy)
# $EDITOR city.toml                   # add "../software-factory/packs/improver" to includes
# git add city.toml
# git commit -m "chore(W4): wire shipped improver pack into my-factory"

# PART 2 — run a manual harvest
bd list --label=needs-improve --status=open            # signals you expect the improver to see
bd list --status=closed --since="14 days ago"
gc mail inbox --agent reviewer
sh packs/improver/commands/harvest.sh 7d       # or ../software-factory/packs/improver/commands/harvest.sh
gc watch improver

cd ~/path/to/your-repo
cat docs/feedback/$(date -u +%F).raw.md
cat docs/feedback/$(date -u +%F).md
bd list --label=source:actual-improver --limit=10
bd list --label=needs-improve --status=closed --since="1 day ago"
git add docs/feedback/
git commit -m "feedback(improver): daily harvest $(date -u +%F)"

# PART 3 — act on one proposed bead
bd show <chosen-bead-id>
$EDITOR my-factory/packs/reviewer/prompts/reviewer.md.tmpl   # or whichever pack the bead targets
git -C my-factory add packs/reviewer/prompts/reviewer.md.tmpl
git -C my-factory commit -m "chore(reviewer): <specific change> (from improver harvest $(date -u +%F))"
cd my-factory && gc service restart && gc doctor
bd close <chosen-bead-id> --reason "applied to packs/reviewer/prompts/reviewer.md.tmpl in commit <sha>"

# (reject path, if the proposal was wrong)
bd close <chosen-bead-id> --reason "insufficient evidence: <one sentence>"
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Improver pack | `my-factory/packs/improver/` (local copy) — or include the shipped `software-factory/packs/improver/` directly | Defines the optional 7th agent: prompt, formula, cooldown order, doctor check, `harvest` + `status` commands |
| Improver persona | `packs/improver/prompts/improver.md.tmpl` | SRE + Performance Engineer + Developer Advocate; explicit "what you do NOT do" block that prevents direct fixes, alert silencing, solo arch calls |
| Harvest formula | `packs/improver/formulas/mol-feedback-harvest.formula.toml` | 4-step molecule: collect → classify → propose → file-beads |
| Cooldown order | `packs/improver/formulas/orders/improver-cooldown/order.toml` | `gate = "cooldown"` / `interval = "24h"` — wakes the Improver on a schedule, not on a label |
| Daily summary | `docs/feedback/<date>.md` in your project rig | Classified signals + proposed beads; the audit artifact for every improver cycle |
| Raw signals | `docs/feedback/<date>.raw.md` | Input side — whatever signals the improver could actually reach |
| Improver-filed beads | `bd list --label=source:actual-improver` | Every bead the improver ever filed, searchable by tag |
| Config change | one commit on one of `packs/{planner,architect,designer,coder,reviewer,deployer}/` | The concrete outcome of one improver cycle — the improvement itself |

The 7th agent does not enlarge the factory's operating surface. It gives you a cooldown-triggered, bounded, human-gated way to turn the signal you already emit into the config changes you already know how to commit. A factory that runs without it is still a factory. A factory that runs with it, disciplined, is one that compounds.
