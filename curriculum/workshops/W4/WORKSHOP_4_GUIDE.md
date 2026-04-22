# W4 · Create Continuous Improvement Loops

> **Goal:** Understand how a software factory can learn from its own signals, and demonstrate your understanding by demonstrating an improvement in the factory from a participant-defined set of improvement criteria.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | Clear `improvement-criteria.md` that outlines the criteria for improvement of the software factory, and a demonstrable improvement in the factory based on the criteria |

## Deliverable

By the end of this workshop, you will have:

- `~/Projects/factory/workshop_w4/w4-project/docs/improvement-criteria.md`, containing:
  - `## Signal Inventory` — every signal your factory currently emits, with source and volume so far.
  - 4–8 **Improvement Criteria**, each with a signal, a direction, a target, a measurement method, and a cadence (per-run / weekly / per-incident / one-off).
  - `## Loop 1 Result` — the before/after numbers from one full signal → config change → re-run loop.
- One config edit applied to your L4 factory and re-run against a comparable feature

The improvement-criteria file becomes the audit lens you apply to the C1 capstone run.

## Overview

A software factory that runs the same way on day 1 and day 100 is not a factory — it's a script. What turns a pipeline of specialists into something that *improves* is a feedback loop that reads the factory's own signals (review findings, release-gate failures, rollback events, real-world bugs) and feeds them back into the configuration that shaped the run.

W4 is where you set the rules for that loop. The workshop has two halves:
1. **Decide what "improvement" means** for your factory — the specific criteria you'd use to judge "is run N+1 better than run N?"
2. **Run the loop once** — pick a signal from your L2–L4 runs, translate it into a config change, and show a measurable improvement against your criteria.

Through this workshop you will:
- Catalogue the signals your factory is already emitting
- Author `improvement-criteria.md` — the rules you'll apply every time you consider a change
- Pick one signal, make one config change, and re-run to prove the change moved the criteria
- Leave with a repeatable loop: signals → criteria → change → evidence

> **Fired Up Pizza reference:** The reference project has a completed run report and retrospective at [`reference-project/fired-up-pizza/factory-run-report.md`](../../../reference-project/fired-up-pizza/factory-run-report.md) and [`reference-project/fired-up-pizza/retrospective-card.md`](../../../reference-project/fired-up-pizza/retrospective-card.md). Skim them as examples of what "signals captured" looks like — but your criteria must reflect your own project's priorities.

## The Loop You're Building

```
  ┌───────────────────────────────────────┐
  │          Factory Run (N)              │
  │   Planner → ... → Deployer            │
  └────────────────┬──────────────────────┘
                   │  emits signals
                   ▼
  ┌────────────────────────────────────────────────────────┐
  │                     Signals                            │
  │                                                        │
  │  • Review findings       review-reports/<slug>.md      │
  │  • Release-gate failures release-gates/<slug>.md       │
  │  • Iteration count       factory-iterations.md         │
  │  • Rollback / deploy     CI logs, incident reports     │
  │  • Production bugs       user feedback, error tracking │
  └────────────────┬───────────────────────────────────────┘
                   │  filtered by improvement criteria
                   ▼
  ┌────────────────────────────────────────────────────────┐
  │                Config Change (one edit)                │
  │                                                        │
  │  • Prompt edit (pack)                                  │
  │  • Manifest section edit (standards, criteria, inputs) │
  │  • Coordination channel addition                       │
  │  • Capability / MCP addition                           │
  └────────────────┬───────────────────────────────────────┘
                   │  take effect on next run
                   ▼
  ┌────────────────────────────────────────────────────────┐
  │          Factory Run (N+1)  — measurably better        │
  └────────────────────────────────────────────────────────┘
```

## Part 1: Install the W4 workspace (5 min)

> **Goal:** Stand up the workshop workspace and bring forward the artifacts whose signals you'll analyze.

### Step 1: Install W4

```bash
# In your agent session, run:
/factory-activity-agent install W4
```

### Step 2: Confirm your central docs were seeded and pull in the L4 signal sources

The install step copies your **central deliverables folder** (`software-factory-intensive/docs/`) into the W4 workspace. The docs flow automatically:

```bash
ls ~/Projects/factory/workshop_w4/w4-project/docs/
```

You should see `PROJECT_MANIFEST.md`, `SOFTWARE_FACTORY_MANIFEST_.md`, `factory-pipeline.md`, `coordination-channels.md`, and `factory-iterations.md`.

## Part 2: Catalogue the Signals You Already Have (10 min)

> **Goal:** Build an inventory of what your factory emits today, so Part 3's criteria are grounded in signals that actually exist.

In `docs/improvement-criteria.md`, add:

```markdown
## Signal Inventory

| Signal | Source | What it tells you |
|--------|--------|-------------------|
|        |        |                   |
```

Fill it from the artifacts you brought forward. Typical rows:

| Signal | Source | What it tells you |
|--------|--------|-------------------|
| Review findings by severity | `review-reports/*.md` | Where the Coder is falling short of Review Standards |
| Review → Coder loop-backs | `factory-iterations.md` + review reports | How often a feature needs ≥2 Coder runs |
| Release-gate FAILs by criterion | `release-gates/*.md` | Which release criteria are the bottleneck |
| Prompt iterations per stage | `factory-iterations.md` | Which stages' configs are most unstable |
| Time to first work package | Dashboard / event log | Planner throughput |
| External bug reports / rollbacks | CI, Sentry, team chat | Real-world validation of factory output |

Don't invent signals. If a row has "Volume so far" = 0, it's a source you could develop but don't yet have — record it as a gap.

## Part 3: Author Improvement Criteria (15 min)

> **Goal:** Produce the rules you'll apply every time you consider a config change, so improvement is measured, not vibed.

Under `## Improvement Criteria` in `improvement-criteria.md`, write 4–8 criteria using this shape:

```markdown
### Criterion <N>: <name>

**Signal:** <which row from the Signal Inventory>

**Direction of improvement:** <higher or lower, concretely>

**Target:** <specific threshold or delta>

**How we measure:** <which artifact / command / dashboard to look at>
```

Good example:

```markdown
### Criterion 1: Review loop-backs trend down

**Signal:** Review → Coder loop-backs per feature

**Direction of improvement:** Lower

**Target:** ≤1 loop-back on the next five features

**How we measure:** Count REQUEST_CHANGES verdicts in `review-reports/*.md`
matched to a subsequent Coder iteration in `factory-iterations.md`.
```

Bad example (avoid):

```markdown
### Criterion X: Better code

**Signal:** Reviewer opinions

**Direction:** Up

**Target:** More good code

**How we measure:** Looks right.
```

Rules of thumb:

- **Anchor every criterion to a signal** from Part 2. If the signal doesn't exist, the criterion is aspirational.
- **Prefer delta to absolute.** "Loop-backs fall by 50% on the next five features" is easier to judge than "≤1 loop-back ever."
- **Keep criteria stage-aware.** A Planner criterion, an Architect criterion, a Reviewer criterion — when all your criteria cluster on one stage, you may be neglecting the others.
- **Include at least one project-outcome criterion** (e.g. "fewer Sentry errors in released features") so the factory's improvements eventually connect to what users experience.

> **Insight: Continuous improvement loops are chaotic and complex.**
>
> A self-improving software factory is the ultimate software factory, but it's also the most difficult to tune correctly. Too large of changes can lead to instability and regression, while too small of changes may not be effective. It is important to pick strong signals and connect them to very well-correlated adjustments in the factory's configuration.

## Part 4: Pick One Signal and Make One Change (10 min)

> **Goal:** Demonstrate the loop once — read a signal, translate it into a config change, and re-run to show the criterion moved.

### Step 1: Pick the criterion with the loudest signal

Scan your Signal Inventory: where do your review reports and release gates complain most? That's your starting criterion. If loop-backs are loud, pick the loop-back criterion. If a specific release-gate row fails often, pick that criterion. Don't tackle multiple at once.

### Step 2: Pick the config surface that matches the signal

| Signal type | Config surface to change |
|-------------|--------------------------|
| Review findings cluster on a specific rule | `PROJECT_MANIFEST.md → Review Standards` (tighten or reword) |
| Coder keeps missing an AC format | `packs/planner/prompts/planner.md.tmpl` (require stricter AC shape) |
| Designer specs lack a recurring detail | `packs/designer/prompts/designer.md.tmpl` (add a required section) |
| Same release criterion fails repeatedly | `PROJECT_MANIFEST.md → Release Criteria` (either tighten the criterion or add a Coder-side check that catches it earlier) |
| Stage skips a prior artifact | The downstream stage's `## Inputs you consume` (make the upstream artifact mandatory) |

### Step 3: Make the change and record it

Edit *one* file. Log the change in a `docs/factory-iterations.md` file:

```markdown
| Date       | Stage    | File                                         | Change                                                              | Expected criterion impact |
|------------|----------|----------------------------------------------|---------------------------------------------------------------------|---------------------------|
| 2026-04-20 | Reviewer | docs/PROJECT_MANIFEST.md → Review Standards  | Tightened "boundary types" rule — require JSDoc on exports as well | Fewer Med-severity findings per review |
```

Restart the L4 factory so the change takes effect:

```bash
cd ~/Projects/factory/lab_l4/l4-gc-factory && gc stop && gc start
```

### Step 4: Re-run against a comparable feature

Pick another small feature (similar scope to the one that produced the signal) and run it end-to-end through L4's factory. Read the new review report + release gate and compare against the criterion.

### Step 5: Record the result

In `improvement-criteria.md`, add:

```markdown
## Loop 1 Result

- Criterion touched: <name>
- Change applied: <one-line description, with path>
- Feature used to measure: <slug>
- Before (from the L4 runs): <number / artifact citation>
- After (from this re-run): <number / artifact citation>
- Net movement: improved / no change / regressed
```

A regressed or no-change result is still a valid deliverable — it tells you the signal you picked wasn't the lever you thought it was, and that's a learning W4 is designed to surface.

## Part 5: Decide Which Loops Run on a Cadence (5 min)

> **Goal:** Plan which of your improvement criteria are checked ad-hoc vs on a schedule, so the loop keeps running after the workshop ends.

Not every criterion deserves constant surveillance. For each criterion in your doc, add a **Cadence** line:

- **Per run** — check every time a feature finishes (e.g. review loop-backs)
- **Weekly** — check in a scheduled review (e.g. Sentry trends)
- **Per incident** — check only when something breaks (e.g. rollback rate)
- **One-off** — a criterion you're tracking for a specific initiative and will retire later

If your factory emits a signal per run but the criterion is checked weekly, that's fine — but make sure the signal is captured in a durable file, not ephemeral logs. The `review-reports/` and `release-gates/` directories are durable; dashboard snapshots are not.

## Common Issues and Solutions

- **"My criteria are all about the Coder."** You're probably not reading upstream signals. Look for Planner or Architect failures that *cause* Coder rework — those are cheaper to fix.
- **"The criterion I picked didn't move."** Either your config change was too subtle or the signal is downstream of a different root cause. Re-read the review report carefully and look for a different file to edit.
- **"My signal is noisy — one bad review can't tell me anything."** Use a delta over 3–5 features, not one. Criteria phrased as averages or counts handle noise better than per-feature thresholds.
- **"I'm tempted to just run more features and see what happens."** That's useful but not W4. The workshop is about deliberate change, not volume.

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `docs/improvement-criteria.md` exists with Signal Inventory + 4–8 Improvement Criteria
- [ ] Each criterion names a signal, a direction, a target, and a measurement method
- [ ] At least one criterion has a cadence (Per run / Weekly / Per incident / One-off)
- [ ] One loop has been run: signal → config change → re-run → recorded result
- [ ] `docs/factory-iterations.md` has a new entry for the Part 4 change

## Quick Reference: What You Built

| Artifact | Location | What It Holds |
|----------|----------|---------------|
| `improvement-criteria.md` | `~/Projects/factory/workshop_w4/w4-project/docs/` | Signals, criteria, cadences, loop results |
| Iteration log  | `~/Projects/factory/workshop_w4/w4-project/docs/factory-iterations.md` | Config changes made to the factory |
| One config change | In the appropriate pack or manifest | The concrete improvement you applied |
| One re-run result | Per-feature review report + release gate + entry in `improvement-criteria.md` | Evidence the change moved the criterion |

## Next Steps

**[C1](../../capstone/C1/CAPSTONE_1_GUIDE.md)** is the capstone run — an unfamiliar feature sent end-to-end through your factory. The improvement criteria you authored here are what you'll use to judge whether the capstone run surfaces new signals worth another loop.

Bring to C1:

- [ ] `improvement-criteria.md` committed
- [ ] Your running L4 factory with the Part 4 config change applied
- [ ] An unfamiliar feature request (something you haven't yet run through the factory)
