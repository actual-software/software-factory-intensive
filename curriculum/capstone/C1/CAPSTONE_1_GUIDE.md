# C1 · Run the Software Factory End-to-End [UNDER CONSTRUCTION]

> **Note:** This capstone is under construction. It will be updated in the future.

> **Goal:** Demonstrate your understanding of the software factory pipeline by running an unfamiliar feature request through your complete software factory, guided entirely by the configuration you have assembled.

| | |
|---|---|
| **Estimated duration** | ~90 minutes |
| **Type** | CAPSTONE |
| **Deliverable** | 6-agent software factory applied to an unfamiliar feature request, with a high-quality feature produced for your software project |

## Overview

Every session so far asked you to *build* a part of the factory. The capstone asks you to *trust* it.

You will pick a feature you have not already run through the factory. You will put it in front of the Planner the same way a real request arrives — via the source wired in L1 — and watch the pipeline carry it through all six stages with only the interventions your configuration already licenses.

Through this capstone you will:
- Submit one feature request the factory has never seen
- Observe all six stages produce their artifacts end-to-end
- Intervene only through config (prompt edits, manifest edits) — never by typing content into chat
- Audit the run against the improvement criteria you authored in W4
- Decide one follow-up change to enter back into the loop

> **Fired Up Pizza reference:** For a finished end-to-end run, see the reference project's [`factory-run-report.md`](../../../reference-project/fired-up-pizza/factory-run-report.md) and [`retrospective-card.md`](../../../reference-project/fired-up-pizza/retrospective-card.md). The shape of your output should look similar, populated with *your* project's artifacts.

## What the Run Produces

```
   Unfamiliar feature request (from a real source)
                        │
                        ▼
  ┌───────────────────────────────────────────────┐
  │   The full factory, already assembled:        │
  │                                               │
  │   Planner → Architect → Designer →            │
  │                                               │
  │   Coder → Reviewer → Deployer                 │
  │                                               │
  │   (plus the coordination channels from W3 and │
  │    the capabilities attached in L2–L4)        │
  └─────────────────────┬─────────────────────────┘
                        │
                        ▼
     ┌────────────────────────────────────────┐
     │    Feature delivered + audit record    │
     │                                        │
     │   work-packages/<slug>.md              │
     │   docs/adr/NNNN-<slug>.md              │
     │   design/<slug>-spec.md                │
     │   src/** + tests on feature branch     │
     |   review-reports/<slug>-review.md      │
     │   release-gates/<slug>-gate.md         │
     │   docs/c1-run-report.md  (audit)       │
     └────────────────────────────────────────┘
```

## Part 1: Install the C1 Factory (10 min)

> **Goal:** Stand up the final workspace with every pack, manifest, channel, standard, criterion, and capability you have accumulated.

### Step 1: Install C1

```bash
# In your agent session, run:
/factory-activity-agent install C1
```

Creates `~/Projects/factory/capstone_c1/c1-project/` and `~/Projects/factory/capstone_c1/c1-gc-factory/` with all six packs wired.

### Step 2: Confirm every prior artifact was carried forward

The install step above pulls **everything** in. Specifically:

1. Bulk-copies `~/Projects/factory/lab_l4/l4-project/` into the C1 workspace — every stage artifact from the L2→L4 runs plus your source tree.
2. Overlays `docs/improvement-criteria.md` from W4.

Spot-check:

```bash
ls ~/Projects/factory/capstone_c1/c1-project/docs/         # improvement-criteria.md + manifest
ls ~/Projects/factory/capstone_c1/c1-project/design/
ls ~/Projects/factory/capstone_c1/c1-project/work-packages/
ls ~/Projects/factory/capstone_c1/c1-project/review-reports/
ls ~/Projects/factory/capstone_c1/c1-project/release-gates/
```

### Step 3: Mirror any pack customization from L2–L4

Pack prompts you edited live in the per-session factory directory, not the project workspace, so the carry-forward *doesn't* bring them. Confirm and mirror:

```bash
diff -qr ~/Projects/factory/lab_l4/l4-gc-factory/packs/ \
         ~/Projects/factory/capstone_c1/c1-gc-factory/packs/
```

If the `diff` surfaces any customization missing from C1, copy it across before moving on. The point of the capstone is that your *final* configuration is what runs — not a fresh set of defaults.

### Step 4: Verify health

```bash
/factory-activity-agent status C1
/factory-activity-agent doctor C1
```

All six stages must be running; doctor must be clean.

## Part 2: Pick a Genuinely Unfamiliar Feature (10 min)

> **Goal:** Select a feature the factory has no prior artifacts for, so the run tests the configuration — not your ability to hand-hold a known flow.

Candidate shapes, in order of strictness:

1. **Best — a real request from your team** that you have not yet scoped personally. Something a teammate filed in your backlog source.
2. **Good — a feature from your product roadmap** that you haven't written stories for.
3. **Acceptable — a recent bug fix you could frame as a feature** ("add a retry to the import pipeline" rather than "patch line 42 of importer.ts").

Disqualifying shapes (avoid):

- A feature you already ran through the factory in L2–L4
- A trivially cosmetic change (no architectural question, no interesting review)
- A feature where you've already decided the implementation

Record your chosen feature in `docs/c1-run-report.md` with three sentences: what it is, why it's a fair test, what you personally don't yet know about how it should be built.

## Part 3: Submit the Feature and Observe (40 min)

> **Goal:** Run the full pipeline with config-only interventions and capture every artifact.

### Step 1: Place the request through the source the factory is wired to

If your Planner is wired to Linear/Jira/GitHub Issues (from L1), file the ticket there with your `factory-ready` marker. If it's wired to `tickets.md`, append the new row.

### Step 2: Route the Planner at the source

```bash
/factory-activity-agent sling C1 planner \
  "Pick the newly filed <feature-title> from the sources declared in docs/PROJECT_MANIFEST.md and produce a work package."
```

### Step 3: Follow each stage in the dashboard

```bash
/factory-activity-agent dashboard C1
```

Watch the transitions. Each stage should wake on the channel you configured in W3 (mail, work-item label, file presence, or external trigger).

For each stage, as it completes, open the produced artifact and verify:

| Stage | Artifact | What to confirm |
|-------|----------|-----------------|
| Planner | `work-packages/<slug>.md` | Cites source + manifest sections; scope boundary is explicit |
| Architect | `docs/adr/NNNN-<slug>.md` | Cites work package; lists ≥2 options with trade-offs |
| Designer | `design/<slug>-spec.md` | Cites ADR; names real components if a design-system MCP is wired |
| Coder | Feature branch commits | Tests cover each AC; project lint / test / build pass |
| Reviewer | `review-reports/<slug>-review.md` | Every finding cites a Review Standards rule |
| Deployer | `release-gates/<slug>-gate.md` | Every Release Criteria row is PASS/FAIL with evidence |

### Step 4: If a stage fails, intervene via config — not chat

You are allowed to:

- Edit a pack prompt (`packs/<stage>/prompts/<stage>.md.tmpl`)
- Edit the manifest (Review Standards, Release Criteria, Task Inputs, Conventions)
- Restart the factory (`gc stop && gc start`)
- Re-sling the failed stage

You are *not* allowed to:

- Type implementation content into the agent's chat ("also add an auth check here")
- Hand-edit the artifact the agent produced
- Skip a stage (if a stage's artifact is wrong, fix it through that stage, not by bypassing it)

Record each intervention in `docs/factory-iterations.md` exactly as you did in L2–L4.

### Step 5: Wait for `release-gates/<slug>-gate.md` to land with overall PASS

The run is complete when the Deployer's verdict is PASS. If it's FAIL for a legitimate reason (a criterion is genuinely unmet), that is also a valid capstone outcome — treat it as the input to Part 4.

## Part 4: Write the Run Report (15 min)

> **Goal:** Audit the run against your W4 improvement criteria so the capstone feeds back into the loop instead of ending it.

Extend `docs/c1-run-report.md` with:

```markdown
## Run Summary

- Feature: <title>
- Source: <Linear / Jira / tickets.md / etc.>
- Started: <ISO timestamp of Planner sling>
- Ended: <ISO timestamp of Deployer PASS>
- Total elapsed: <duration>
- Human interventions: <count>

## Interventions (from docs/factory-iterations.md)

| Stage | File edited | Reason |
|-------|-------------|--------|
|       |             |        |

## Against W4 Improvement Criteria

For each criterion in `docs/improvement-criteria.md`:

| Criterion | Value observed | Movement vs. prior runs |
|-----------|----------------|-------------------------|
|           |                | improved / no change / regressed |

## One Follow-up

Pick the single loudest gap or regression in this run and describe the
one config change you would make next. Do not make it yet — log it as
the next loop you'd open.

- Target criterion:
- Proposed change (file + section):
- Expected impact:
```

Commit the run report alongside the six stage artifacts.

## Part 5: Decide What Ships, What Loops, What Retires (5 min)

> **Goal:** End the capstone with a decision, not just a run.

Take five minutes and answer:

- **Ship?** Is the feature branch actually mergeable? If yes, merge it the way you normally would. If not, name the specific criterion that blocks it.
- **Loop?** Does the follow-up in Part 4 deserve another W4-style loop this week, or is it lower priority than other work?
- **Retire?** Is there anything in the factory (an unused pack, a stale MCP, a criterion that never fires) you'd remove as a result of this run? Recording what to delete is as valuable as recording what to add.

Write the three answers in a short `## Capstone Decision` section at the end of `c1-run-report.md`.

## Common Issues and Solutions

- **"The Planner produced a generic work package."** The source it pulled from had too little context. Check your backlog item's description and your manifest's Domain Model — the Planner is only as specific as its inputs.
- **"The Architect re-litigated a decision that's already an ADR."** `actual adr-bot` wasn't run on this C1 workspace, or the Architect prompt isn't pointing at `CLAUDE.md` first. Fix both and re-sling.
- **"A stage stalled with no signal."** Check the coordination channel for that transition (from your W3 doc). A label nobody polls and a mail nobody reads look identical: silent.
- **"Everything passes but I don't think the feature is right."** That's a Review Standards gap — the rule you'd cite in a human PR review isn't in the manifest yet. Add it, log it as the next loop, and consider the run a successful surfacing of a real gap.
- **"The capstone is taking longer than 90 minutes."** Stop at the one-hour-thirty mark regardless of stage. The deliverable is the run report plus whatever artifacts you have — a partial run with honest reporting beats an over-fit complete run.

## Exit Criteria

Before closing the capstone, verify all of these:

- [ ] Six stage artifacts exist for the chosen feature (work package, ADR, spec, commits, review report, release gate)
- [ ] `docs/c1-run-report.md` is committed with run summary, interventions, criterion audit, and a follow-up
- [ ] Every intervention during the run is logged in `docs/factory-iterations.md`
- [ ] The factory runs with only config-level interventions — no chat-level content injection
- [ ] The capstone decision section names whether to ship, loop, and retire

## Quick Reference: What You Produced

| Artifact | Location | What It Documents |
|----------|----------|-------------------|
| Six-stage artifact set | `~/Projects/factory/capstone_c1/c1-project/` | The full run for one real feature |
| Run report | `docs/c1-run-report.md` | Summary + intervention log + criterion audit |
| Updated iteration log | `docs/factory-iterations.md` | The ongoing history of config changes |
| Capstone decision | End of `c1-run-report.md` | Ship / loop / retire calls after this run |

## Next Steps

After C1, the factory is yours to run on real work. The habits that matter most going forward:

- **Keep the iteration log alive.** Every prompt edit you make in the weeks ahead deserves a line.
- **Run W4's loop on a cadence.** Pick at least one criterion to review per sprint.
- **Grow the manifest deliberately.** When a new recurring review finding appears, promote it to a Review Standard. When a new deploy gate becomes mandatory, add it to Release Criteria.
- **Tear down cleanly.** When you're done with a given workspace, `/factory-activity-agent delete <session>` keeps `~/Projects/factory/` tidy. The configuration you care about lives in your project repo, not in the per-session workspaces.

The curriculum's participant Slack (see the repo README) is where other participants share the configurations that worked for them. If you ship something interesting from your capstone — or get stuck — that's the place.
