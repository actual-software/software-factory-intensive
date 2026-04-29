# W4 · Create Continuous Improvement Loops

> **Goal:** Understand how a software factory can learn from its own signals, and demonstrate your understanding by demonstrating an improvement in the factory from a participant-defined set of improvement criteria.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `improvement-criteria.md` (signal inventory + criteria + Loop 1 result), plus a demonstrable improvement in the factory against those criteria |

## Architecture

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
  │  • Review findings       docs/reviews/<slug>.md        │
  │  • Release-gate failures docs/releases/<slug>.md       │
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

## Overview

A software factory that runs the same way on day 1 and day 100 is not a factory — it's a script. What turns a pipeline of specialists into something that *improves* is a feedback loop that reads the factory's own signals (review findings, release-gate failures, rollback events, real-world bugs) and feeds them back into the configuration that shaped the run.

W4 is where you set the rules for that loop. The workshop has two halves:

1. **Decide what "improvement" means** for your factory — the specific criteria you'd use to judge "is run N+1 better than run N?"
2. **Run the loop once** — pick a signal from your L2–L4 runs, translate it into a config change, and show a measurable improvement against your criteria.

By the end of this workshop, you should have:

- `activities/workshops/W4/feedback-loops/improvement-criteria.md`, containing:
  - `## Signal Inventory` — every signal your factory currently emits, with source and volume so far.
  - 4–8 **Improvement Criteria**, each with a signal, a direction, a target, a measurement method, and a cadence (per-run / weekly / per-incident / one-off).
  - `## Loop 1 Result` — the before/after numbers from one full signal → config change → re-run loop.
- One config edit applied to your L4 factory and re-run against a comparable feature.

The improvement-criteria file becomes the audit lens you apply to the C1 capstone run; the iteration log becomes the durable record of every config change made thereafter.

## 1. Catalogue the Signals You Already Have (10 min)

```bash
mkdir -p activities/workshops/W4/feedback-loops
touch activities/workshops/W4/feedback-loops/improvement-criteria.md

In `feedback-loops/improvement-criteria.md`, add:

```markdown
## Signal Inventory

| Signal | Source | What it tells you |
|--------|--------|-------------------|
|        |        |                   |
```

Fill it from the artifacts you brought forward. Typical rows:

| Signal | Source | What it tells you |
|--------|--------|-------------------|
| Review findings by severity | `docs/reviews/*.md` | Where the Coder is falling short of Review Standards |
| Release-gate FAILs by criterion | `docs/releases/*.md` | Which release criteria are the bottleneck |
| Time to first work package | Dashboard / event log | Planner throughput |
| External bug reports / rollbacks | CI, Sentry, team chat | Real-world validation of factory output |

Don't invent signals. If a row has "Volume so far" = 0, it's a source you could develop but don't yet have — record it as a gap.

## 2. Author Improvement Criteria (15 min)

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

**How we measure:** Count REQUEST_CHANGES verdicts in `docs/reviews/*.md`.
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

- **Anchor every criterion to a signal** from Part 1. If the signal doesn't exist, the criterion is aspirational.
- **Prefer delta to absolute.** "Loop-backs fall by 50% on the next five features" is easier to judge than "≤1 loop-back ever."
- **Keep criteria stage-aware.** A Planner criterion, an Architect criterion, a Reviewer criterion — when all your criteria cluster on one stage, you may be neglecting the others.
- **Include at least one project-outcome criterion** (e.g. "fewer Sentry errors in released features") so the factory's improvements eventually connect to what users experience.

> **Insight: Continuous improvement loops are chaotic and complex.**
>
> A self-improving software factory is the ultimate software factory, but it's also the most difficult to tune correctly. Too large of changes can lead to instability and regression, while too small of changes may not be effective. It is important to pick strong signals and connect them to very well-correlated adjustments in the factory's configuration.

## 4. Write Feedback Rule Files (10 min)

For 2-4 signals you identified in Part 1, write a feedback rule file.

```bash
$EDITOR activities/workshops/W4/feedback-loops/<feedback-rule-name>.md
```

Use this structure:

```markdown
# <Rule Name>

## Signal

What signal are you reacting to?

## Trigger

How many times or under what condition should this become a factory rule?

## Target

Which file should change?

## Proposed Change

What exact behavior should be added or removed?

## Verification

How will a future run prove the change worked?

## Rollback

When should the change be removed or simplified?
```

## 3. Decide Where The Rule Belongs

| Rule Type | Typical Target |
|---|---|
| Better planning output | `packs/lessons/<active>/agents/planner/prompt.template.md` |
| Better architecture decisions | `packs/lessons/<active>/agents/architect/prompt.template.md` |
| Better implementation behavior | `packs/lessons/<active>/agents/builder/prompt.template.md` |
| Better validation | `packs/lessons/<active>/agents/validator/prompt.template.md` or the formula validation step |
| Better release decisions | `packs/lessons/<active>/agents/release-gate/prompt.template.md` |
| Project-specific policy | project `CLAUDE.md`, `AGENTS.md`, or `docs/PROJECT_MANIFEST.md` |

The activity file explains the lesson learned. The runtime file should encode the durable behavior without saying it came from a workshop.

## 4. Apply One Rule at a Time (10 min)

Choose one rule and make the smallest real config change. Commit the rule file and the runtime change together so the audit trail shows why the factory changed.

Example:

```bash
git add activities/workshops/W4/feedback-loops/reactive-async-error-handling.md
git add packs/lessons/C1/agents/builder/prompt.template.md
git commit -m "Teach builder async error handling rule"
```

## 5. Measure One Improvement (10 min)

For a given rule, you should be able to measure an improvement in the factory against the criterion. Use the tools available to you to measure the signal before and after the config change. Record the results in the `improvement-criteria.md` file as follows:

```markdown
## Loop 1 Result

- Criterion touched: <name>
- Rule applied: <feedback-rule-name>
- Before (from the L4 runs): <number / artifact citation>
- After (from this re-run): <number / artifact citation>
- Net movement: improved / no change / regressed
``` 

## 6. Continue the Loop, Applying One Rule at a Time (10 min)

As time permits, apply the remaining rules to the active lesson pack or project instructions and measure the improvement in the factory against the criterion. Record the results in the `improvement-criteria.md` file.

## Exit Criteria

- [ ] At least three feedback rule files exist.
- [ ] Each rule has signal, trigger, target, proposed change, verification, and rollback.
- [ ] One rule has been applied to the active lesson pack or project instructions.
- [ ] The runtime change is portable and does not mention the workshop.
- [ ] At least one rule includes before/after measurement from a factory run.

## Next Steps

**[C1](../../labs/C1/README.md)** runs the factory end-to-end, using the `improvement-criteria.md` file as the audit lens.
