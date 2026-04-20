# W2 · Design the 6-Agent Software Factory

> **Goal:** Understand how the specialists in a software factory coordinate their work, and translate that understanding into a design for the factory you will bring to life over the remainder of the curriculum.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | Factory wiring diagram + handoff contracts + filled `my-factory/PROJECT_MANIFEST.md` |

---

## Session workspace note

Pack mapping, where this README mentions a role → the shipped pack name:

| Role (curriculum) | Shipped pack |
|-------------------|--------------|
| Planner | `packs/planner` |
| Architect | `packs/architect` |
| Designer | `packs/designer` |
| **Coder** | **`packs/builder`** |
| Reviewer | `packs/reviewer` |
| **Deployer** | **`packs/release-gate`** |

Prompt files end in `.md.tmpl` (Gas City templates). The W2 deliverable (`factory-wiring.md`) belongs in `../../../activities/workshops/W2/`. No pack is installed in this workshop — L2 is the first session that adds packs to `../../../my-factory/city.toml`.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should start by opening `docs/PROJECT_MANIFEST.md` so every handoff example uses the participant's actual tech stack and artifact paths.

---

## Architecture Diagram

The 6-agent pipeline is a linear sequence of specialists. Each agent reads a small, fixed set of artifacts, writes exactly one new artifact, and hands off via the file system — never via chat memory.

```
                           ┌──────────────────────────┐
                           │    Feature Request        │
                           │  (bead title + body)      │
                           └─────────────┬────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
                    │ 1. PLANNER                              │
                    │   Reads:  bead + PROJECT_MANIFEST.md     │
                    │   Writes: work-packages/<slug>.md        │
                    └────────────────────┬────────────────────┘
                                         │  handoff: work package
                                         ▼
                    ┌────────────────────┴────────────────────┐
                    │ 2. ARCHITECT                            │
                    │   Reads:  work package + MANIFEST        │
                    │           + CLAUDE.md (tailored ADRs)    │
                    │           + existing docs/adr/*          │
                    │   Writes: docs/adr/NNNN-<slug>.md        │
                    └────────────────────┬────────────────────┘
                                         │  handoff: work package + ADR
                                         ▼
                    ┌────────────────────┴────────────────────┐
                    │ 3. DESIGNER                             │
                    │   Reads:  work package + ADR + MANIFEST  │
                    │   Writes: design/<slug>-spec.md          │
                    └────────────────────┬────────────────────┘
                                         │  handoff: component spec
                                         ▼
                    ┌────────────────────┴────────────────────┐
                    │ 4. CODER                                │
                    │   Reads:  spec + work package + ADR      │
                    │   Writes: src/** files + tests           │
                    └────────────────────┬────────────────────┘
                                         │  handoff: feature branch
                                         ▼
                    ┌────────────────────┴────────────────────┐
                    │ 5. REVIEWER                             │
                    │   Reads:  diff + spec + AC               │
                    │           + MANIFEST (Review Standards)  │
                    │   Writes: review-reports/<slug>-review.md│
                    └────────────────────┬────────────────────┘
                                         │  handoff: APPROVE verdict
                                         ▼
                    ┌────────────────────┴────────────────────┐
                    │ 6. DEPLOYER                             │
                    │   Reads:  review report + branch         │
                    │           + MANIFEST (Release Criteria)  │
                    │   Writes: release-gates/<slug>-gate.md   │
                    └────────────────────┬────────────────────┘
                                         ▼
                                   Done (closed bead)
```

Keep this diagram in mind throughout the workshop. Your design deliverable is *this exact shape*, filled in with paths, formats, and constraints from your own project.

---

## Prerequisites

Before starting W2, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| W1 complete | You've read `curriculum/workshops/W1/README.md` end-to-end | Read W1 now — 20 min. It frames the "why" for this workshop's "how". |
| L1 complete | `ls ~/path/to/your-repo/CLAUDE.md` → file exists | Complete L1 first. W2 assumes a Gas City city exists and a rig is pointed at your repo. |
| Skeleton scaffold copied | `ls ~/path/to/your-repo/work-packages/` → directory exists | `mkdir -p ../../path/to/your-repo/{work-packages,docs/adr,design,review-reports,release-gates,feedback-loops}` |
| Project Manifest in place | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` → non-empty | Copy `curriculum/PROJECT_MANIFEST_TEMPLATE.md` and fill in tech stack, domain model, conventions |
| One feature in mind | You can describe in one sentence the feature you'll trace through all six stages | Pick something small: "add CSV export to the orders page", "ship dark-mode toggle". Use the Fired Up Pizza loyalty points example if nothing else jumps out. |
| Editor open on the packs dir | You can browse `packs/planner/`, `packs/architect/`, etc. | `cd software-factory-intensive && code .` (or your editor of choice) |

---

## The Running Example: Loyalty Points for Fired Up Pizza

Throughout this workshop we use a single feature to keep every example concrete: **a loyalty points system for Fired Up Pizza** (the reference project at `reference-project/fired-up-pizza/`).

- Customers earn 1 point per $1 spent on an order.
- Points can be redeemed at checkout (100 points = $5 off).
- The points balance shows on the order confirmation page.

This feature is deliberately chosen because:

1. It has a clear *planning* question (what are the user stories?).
2. It has a real *architectural* question (where do we store the points?).
3. It has *both* frontend and backend work, so Designer and Coder produce non-trivial artifacts.
4. It's small enough that every stage's output fits in a page.

If you're working against your own project, substitute a comparable feature. It should have at least one open architectural decision and touch at least one existing file.

**Do the substitution now, before continuing.** Write one sentence per agent describing what *your* feature's artifact will look like. You'll refine these into the full design deliverable during Part 3.

---

## Part 1: Read the Shipped Packs (5 min)

> **Goal:** Become familiar with the common structure that every agent in a software factory follows, so you can read, evaluate, and later adapt any specialist using the same mental model.

Before you can design your factory, you need to see the shape each pack provides. Gas City ships one pack per agent, and each pack has the same six-section prompt file: **Role, Inputs, Output Format, Quality Gate, Process, Config Discipline**. Your design in Part 3 will customize those six sections per agent.

### Step 1: Open the Planner Pack Prompt

Open this file and scan the six headings. It's 65 lines — skim, don't memorize.

[`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl)

```markdown
# Planner Agent

## Role              ← "You receive feature requests and break them into
                        structured work packages..."

## Inputs            ← bead description + docs/PROJECT_MANIFEST.md

## Output Format     ← work-packages/<feature-slug>.md with 6 sections:
                        Goal, User Stories, Acceptance Criteria,
                        Dependencies, Test Cases, Scope Boundary

## Quality Gate      ← 4 rules: every story has an AC, 2+ test cases,
                        explicit scope boundary, no ambiguous terms

## Process           ← 6 steps: read bead → read manifest → produce file
                        → commit on branch → update bead → mark ready

## Config Discipline ← "the fix is updating this file — not ad-hoc
                        re-prompting"
```

**What's happening here:** This is the Planner's entire personality. In L2, when you `gc sling planner <bead>`, Gas City loads this prompt as the system message. Everything the Planner does comes from this file plus your `docs/PROJECT_MANIFEST.md`.

### Step 2: Open the Planner Pack Metadata

[`packs/planner/pack.toml`](../../../packs/planner/pack.toml)

```toml
[pack]
name = "planner"
schema = 1
description = "Planner agent — breaks feature requests into structured work packages"

[[agent]]
name = "planner"
scope = "rig"
provider = "claude"        # Other providers (OpenAI, Gemini, local) are supported
prompt_template = "prompts/planner.md"
overlay_dir = "overlays/default"
nudge = "Check your hook for new feature requests to plan."
idle_timeout = "1h"
max_active_sessions = 1
```

**What's happening here:** The `[[agent]]` block is what Gas City merges into your city's effective configuration when you run `gc rig add --include`. The `provider = "claude"` line is the runner selection — other providers (OpenAI, Gemini, local Ollama models) are supported, but this curriculum defaults to Claude.

### Step 3: Repeat for Each of the Remaining Five Packs

Open each prompt in the same way. You're looking for the **Inputs** and **Output Format** sections — those define the handoff contracts you'll design in Part 4.

| Agent | Prompt file | Output Location |
|-------|-------------|-----------------|
| Planner | [`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl) | `work-packages/<slug>.md` |
| Architect | [`packs/architect/prompts/architect.md.tmpl`](../../../packs/architect/prompts/architect.md.tmpl) | `docs/adr/NNNN-<slug>.md` |
| Designer | [`packs/designer/prompts/designer.md.tmpl`](../../../packs/designer/prompts/designer.md.tmpl) | `design/<slug>-spec.md` |
| Coder | [`packs/builder/prompts/builder.md.tmpl`](../../../packs/builder/prompts/builder.md.tmpl) | `src/**` |
| Reviewer | [`packs/reviewer/prompts/reviewer.md.tmpl`](../../../packs/reviewer/prompts/reviewer.md.tmpl) | `review-reports/<slug>-review.md` |
| Deployer | [`packs/release-gate/prompts/release-gate.md.tmpl`](../../../packs/release-gate/prompts/release-gate.md.tmpl) | `release-gates/<slug>-gate.md` |

**What's happening here:** Notice the shape is identical across all six packs — same six headings, same "read manifest first" step in Process, same Config Discipline paragraph. This uniformity is the point: once you've read one, you can read the rest in 30 seconds each, and you can edit any of them with the same mental model.

### Inline Insight: Why six headings, not five or seven?

Each of the six prompt sections has a specific purpose in the factory's error-recovery flow:

| Heading | Purpose | When you'd edit it |
|---------|---------|--------------------|
| Role | Scopes *what the agent is*. | Almost never. |
| Inputs | Declares what the agent is allowed to read. | When you add a new source of truth (e.g., adding `CLAUDE.md` as Architect input in L2). |
| Output Format | Contract for the next stage. | When the downstream agent complains about missing fields. |
| Quality Gate | Binary pass/fail rules the agent self-checks. | When output quality slips. Add a rule, re-sling. |
| Process | Ordered steps the agent follows. | When the agent skips a step (e.g., forgets to cross-reference). |
| Config Discipline | Reminder that behavior changes via config, not chat. | Never (it's the same across all packs). |

When the factory misbehaves, you diagnose by asking: *which of these six sections needs to change?* That's why the shape is rigid.

---

## Part 2: Understand the 6 Agents (10 min)

> **Goal:** Develop a clear understanding of each specialist's responsibility and contribution, forming the reference you will draw on when adapting them to your own project.

Now that you've seen the shape, let's walk through each agent's role with concrete artifact examples. For each agent you'll see: a tiny input example, a tiny output example, how it reads `PROJECT_MANIFEST.md`, and a two-line skeleton of its prompt.

### Agent 1: Planner

**Responsibility:** Break a natural-language feature request into a structured work package.

**Key question the Planner asks:** "Is this feature clear enough that an Architect, Designer, and Coder could complete it without ever talking to a human?"

**Example input (bead description):**

```
Add a loyalty points system. Customers earn 1 point per $1 spent and can
redeem 100 points for $5 off at checkout. Balance shows on order
confirmation.
```

**Example output (excerpt of `work-packages/loyalty-points.md`):**

```markdown
# Work Package: Loyalty Points System

## Goal
Let customers earn redeemable points on every order, surfaced on the
order confirmation page.

## User Stories
- As a customer, I want to earn 1 point per $1 spent, so that repeated
  orders feel rewarding.
- As a customer, I want to redeem points at checkout, so that I see
  tangible value from loyalty.

## Acceptance Criteria
- [ ] Points ledger is updated on order placement (not on cart change)
- [ ] 100 points redeemed = 500 cents off (per PROJECT_MANIFEST convention)
- [ ] Cancelled orders do not award points

## Test Cases
- Given a $12.99 order, when placed, then 12 points are awarded.
- Given 250 point balance, when 100 are redeemed, then 150 remain.

## Scope Boundary
- IN: earn on placement, redeem at checkout, show balance on confirmation
- OUT: expiration policy, admin dashboard, tier-based multipliers
```

**How Planner reads `PROJECT_MANIFEST.md`:** It pulls the domain model (`Order`, `OrderItem` entities) and conventions (prices in cents) to make sure stories and ACs use project-native vocabulary. It does *not* invent new entities.

**Prompt skeleton:**

```markdown
# Planner Agent

## Role
You receive feature requests and break them into structured work packages.

## Inputs
- Feature request (bead title + description)
- docs/PROJECT_MANIFEST.md

## Output Format
work-packages/<slug>.md with: Goal, User Stories, Acceptance Criteria,
Dependencies, Test Cases, Scope Boundary.

## Quality Gate
1. Every story has ≥1 AC
2. ≥2 test cases
3. Explicit scope boundary
4. No ambiguous terms
```

### Agent 2: Architect

**Responsibility:** Make technical decisions for the feature and record them as ADRs.

**Key question the Architect asks:** "What are the long-term consequences of this approach, and is it already covered by an existing ADR?"

**Example input:** the work package above, plus this bead description:

```
Review work-packages/loyalty-points.md. Decide how to store loyalty
points. Produce an ADR.
```

**Example output (excerpt of `docs/adr/0001-loyalty-points-storage.md`):**

```markdown
# ADR-0001: Loyalty Points Storage Strategy

## Context
The loyalty points feature (see work-packages/loyalty-points.md) needs
persistent point balances. Existing stack is SQLite via better-sqlite3.

## Options Considered
1. **Column on users table** — simple, but no audit trail.
2. **Separate points_ledger table** — event-sourced, derivable balance.
3. **External points microservice** — over-engineered for a single store.

## Decision
Option 2 (points_ledger). Balance = SUM(delta) for user_id.

## Consequences
- Positive: natural refund handling (negative ledger entries)
- Negative: balance query requires aggregation
- Risk: >100K orders/month may require materialized view

## References
- work-packages/loyalty-points.md
```

**How Architect reads `PROJECT_MANIFEST.md`:** It pulls the tech stack (SQLite, no external services allowed per Constraints section) to rule out options, and reads `CLAUDE.md` for tailored industry ADRs that may already cover the pattern.

**Prompt skeleton:**

```markdown
# Architect Agent

## Role
You receive work packages and produce ADRs.

## Inputs
- work-packages/<slug>.md
- docs/PROJECT_MANIFEST.md
- CLAUDE.md (tailored ADR baselines)
- existing docs/adr/*

## Output Format
docs/adr/NNNN-<slug>.md in MADR form: Context, Options, Decision,
Consequences, References.

## Quality Gate
1. All 4 MADR sections present
2. ≥2 options with trade-offs
3. Decision references work package by path
4. Consequences include ≥1 risk
```

### Agent 3: Designer

**Responsibility:** Translate a work package + ADR into a concrete component spec the Coder can implement without making design decisions.

**Key question the Designer asks:** "Can a Coder implement this with zero architectural ambiguity?"

**Example input:** the work package and the ADR above.

**Example output (excerpt of `design/loyalty-points-spec.md`):**

```markdown
# Component Spec: LoyaltyBalance

## Purpose
Display the current points balance on the order confirmation page.

## Location
`src/components/LoyaltyBalance.tsx`

## Props / Inputs
| Name      | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| userId    | string | yes      | Phone-number key (per MVP auth)|
| showLabel | bool   | no       | Render "Points:" label         |

## Edge Cases
- Empty state: "Earn your first points on this order"
- Error state: silent fail, don't block confirmation page render
- Loading state: render skeleton (Tailwind `animate-pulse`)

## References
- work-packages/loyalty-points.md
- docs/adr/0001-loyalty-points-storage.md
```

**How Designer reads `PROJECT_MANIFEST.md`:** It pulls Conventions (PascalCase component files, co-located tests, Tailwind-only styling) to decide file paths and the "no inline styles" constraint.

**Prompt skeleton:**

```markdown
# Designer Agent

## Role
You receive work packages + ADRs and produce component specs.

## Inputs
- work-packages/<slug>.md
- docs/adr/*
- docs/PROJECT_MANIFEST.md

## Output Format
design/<slug>-spec.md with: Purpose, Location, Props, State, Layout,
Interactions, Data Flow, Edge Cases, References.

## Quality Gate
1. Props and state are typed
2. ≥1 interaction documented
3. Empty, error, loading states covered
4. Location path specified
```

### Agent 4: Coder

**Responsibility:** Write code that implements the spec exactly, with tests covering the work package's test cases.

**Key question the Coder asks:** "Does this code pass the spec's Quality Gate and the project's lint/test commands?"

**Example input:** the spec above, the work package, and the ADR.

**Example output:** files under `src/`:

```
src/components/LoyaltyBalance.tsx        # implements spec
src/components/LoyaltyBalance.test.tsx   # covers work-package test cases
src/db/pointsLedger.ts                   # pointsLedger table queries
```

**How Coder reads `PROJECT_MANIFEST.md`:** It pulls Review Standards (no `any`, no inline styles, components <200 lines) as self-imposed constraints *before* the Reviewer sees the code. Linting to the Review Standards is cheaper than a Reviewer rejection round-trip.

**Prompt skeleton:**

```markdown
# Coder Agent

## Role
You receive specs and implement code.

## Inputs
- design/<slug>-spec.md
- work-packages/<slug>.md
- docs/adr/*
- docs/PROJECT_MANIFEST.md

## Output
Files under src/ matching the spec's Location field.

## Quality Gate
1. Every prop/input implemented
2. Every interaction works
3. Edge cases handled
4. ≥2 test cases from work package pass
5. npm run lint passes
```

### Agent 5: Reviewer

**Responsibility:** Check the Coder's diff against the spec, acceptance criteria, and project Review Standards. Return a binary APPROVE / REQUEST_CHANGES verdict.

**Key question the Reviewer asks:** "Is this code ready for production, and if not, which specific config change would fix it?"

**Example input:** the feature branch diff, the spec, the work package.

**Example output (excerpt of `review-reports/loyalty-points-review.md`):**

```markdown
# Review Report: Loyalty Points

## Summary
PASS — all spec elements implemented, all AC test cases pass, no
high-severity findings.

## Spec Compliance
| Spec Element  | Implemented? | Notes           |
|---------------|--------------|-----------------|
| userId prop   | Yes          | -               |
| empty state   | Yes          | -               |
| error state   | Partial      | silent fail ok, but no log emitted |

## Recommendation
APPROVE — minor: add console.warn on fetch error (low severity).
If you want this enforced, add to packs/builder/prompts/builder.md.tmpl:
"All network errors must be logged via the project logger."
```

**How Reviewer reads `PROJECT_MANIFEST.md`:** It pulls the Review Standards section (style, security, severity scale) and uses it as the checklist. This is why the manifest has an explicit Review Standards section — it's the Reviewer's configuration, versioned in the repo.

**Prompt skeleton:**

```markdown
# Reviewer Agent

## Role
You review code against spec, AC, and review policy.

## Inputs
- feature branch diff
- design/<slug>-spec.md
- work-packages/<slug>.md
- docs/PROJECT_MANIFEST.md (Review Standards section)

## Output Format
review-reports/<slug>-review.md: Summary, Spec Compliance, Style
Findings, Security Findings, Test Coverage, Recommendation.

## Quality Gate
1. Every spec element checked
2. Security review covers injection, auth, data exposure
3. Each test case has PASS/FAIL
4. Recommendation is actionable
```

### Agent 6: Deployer

**Responsibility:** Evaluate every release criterion from the manifest. Produce a binary PASS/FAIL gate report.

**Key question the Deployer asks:** "Does every required criterion have PASS evidence, or does any one fail?"

**Example output (excerpt of `release-gates/loyalty-points-gate.md`):**

```markdown
# Release Gate: Loyalty Points

## Overall Verdict
PASS

## Criteria
| # | Criterion                        | Result | Evidence                   |
|---|----------------------------------|--------|----------------------------|
| 1 | All AC met                       | PASS   | see work package checklist |
| 2 | Review report approved           | PASS   | review-reports/loyalty-points-review.md |
| 3 | No high-severity findings open   | PASS   | 0 high, 1 low              |
| 4 | Tests pass                       | PASS   | 142 passed, 0 failed       |
| 5 | No untracked files in scope      | PASS   | git status clean           |
| 6 | Branch mergeable with main       | PASS   | no conflicts               |

## Release Notes
Customers now earn 1 point per dollar spent and can redeem 100 points
for $5 off at checkout. Point balance shows on order confirmation.
```

**How Deployer reads `PROJECT_MANIFEST.md`:** It pulls the Release Criteria section exactly — the criteria table is generated from the manifest, not invented by the agent.

**Prompt skeleton:**

```markdown
# Deployer Agent

## Role
You evaluate whether a feature meets release criteria and produce a
binary PASS/FAIL gate.

## Inputs
- review-reports/<slug>-review.md
- work-packages/<slug>.md
- docs/PROJECT_MANIFEST.md (Release Criteria section)

## Output Format
release-gates/<slug>-gate.md: Overall Verdict, Criteria table (PASS/FAIL
with evidence), Release Notes, References.

## Quality Gate
1. Every criterion has binary PASS/FAIL with evidence
2. Overall verdict matches individual criteria
3. Release notes are present and user-facing
```

### Inline Insight: Why is Reviewer separate from Deployer?

It's tempting to collapse these into one "shipping" agent. Don't.

- **Reviewer** makes *qualitative* judgments informed by code. It looks at style, security, completeness, spec fidelity. Its output is an opinion backed by evidence.
- **Deployer** makes *binary* judgments informed by checklists. It runs tests, counts findings, checks branch state. Its output is a gate result.

Separating them means the Reviewer's subjectivity stays in one prompt (Review Standards) and the Deployer's determinism stays in another (Release Criteria). You tune them independently. When a dev complains "this feature was blocked for no reason," you can tell them exactly which criterion failed and which config file to edit.

---

## Part 3: Map Your Project (15 min)

> **Goal:** Apply what you now know about each specialist to your own project, producing an initial design that reflects how a software factory would deliver features for it.

Now you design your own factory. You'll fill in the same pipeline shape, but with your project's paths, formats, and constraints.

### Step 1: Pick Your Feature

> **Agent Guide:** Push the participant to pick a feature with both frontend and backend work — single-layer features don't exercise enough of the pipeline. If they can't name a real architectural question the feature raises, pick a different feature; the Architect stage exists to answer real trade-offs, not rubber-stamp.

Write one sentence describing a feature you'll trace through all six stages. Keep it small (implementable in ~2 hours of real coding) and make sure it has at least one open architectural question.

```markdown
## Feature: <name>

One-sentence description.

The architectural question this feature raises: <question>
```

For Fired Up Pizza: *"Add a loyalty points system where customers earn 1 point per $1 and redeem 100 points for $5 off. Architectural question: where do we store the points ledger?"*

**What's happening here:** The architectural question is what distinguishes a feature needing the full 6-agent pipeline from one that could skip the Architect. If you can't identify a real decision, pick a different feature — you'll be bored by L2.

### Step 2: Draft the Per-Agent Table

> **Agent Guide:** For each row, insist on a file path for "what it produces" — abstract names like "the plan" or "the design" aren't allowed. Also flag duplicate artifacts: if two stages produce or consume the same file, that's a missing boundary, split them.

Paste this template into your editor and fill in each row. This *is* your design deliverable — keep it terse.

```markdown
## Factory Design · <Your Feature>

| Agent      | What it produces for this feature                          |
|------------|-------------------------------------------------------------|
| Planner    | work-packages/<your-slug>.md — stories, AC, tests, scope    |
| Architect  | docs/adr/NNNN-<your-slug>.md — <your architectural question>|
| Designer   | design/<your-slug>-spec.md — <component/module name>        |
| Coder      | src/<path> + tests — <files you'll touch>                   |
| Reviewer   | review-reports/<your-slug>-review.md — <specific checks>    |
| Deployer   | release-gates/<your-slug>-gate.md — <pass/fail criteria>    |
```

For Fired Up Pizza, this becomes:

```markdown
## Factory Design · Loyalty Points

| Agent      | What it produces for this feature                          |
|------------|-------------------------------------------------------------|
| Planner    | work-packages/loyalty-points.md                             |
| Architect  | docs/adr/0001-loyalty-points-storage.md (points_ledger vs column) |
| Designer   | design/loyalty-points-spec.md (LoyaltyBalance + checkout hook) |
| Coder      | src/components/LoyaltyBalance.tsx, src/db/pointsLedger.ts   |
| Reviewer   | review-reports/loyalty-points-review.md                     |
| Deployer   | release-gates/loyalty-points-gate.md                        |
```

**What's happening here:** Each row is one commit you'll see in L2-L4. If you can't name the file path now, you can't instruct the agent to write there later.

### Step 3: List the Existing Code Your Feature Touches

```markdown
## Integration Points

- src/api/orders.ts (add points award on POST /api/v1/orders)
- src/pages/OrderConfirmation.tsx (mount LoyaltyBalance)
- src/db/schema.sql (add points_ledger table)
- docs/PROJECT_MANIFEST.md (add points_ledger to Domain Model)
```

**What's happening here:** This list is what your Designer will reference when writing the spec's Data Flow section, and what your Reviewer will constrain the Coder against ("don't modify files outside this list"). An incomplete list here leads to accidental out-of-scope changes in L3.

### Step 4: Save Your Design to `docs/factory-wiring.md`

```bash
cat > ~/path/to/your-repo/docs/factory-wiring.md <<'EOF'
# Factory Wiring · <Your Feature>

## Architecture Diagram

```mermaid
graph LR
    FR[Feature Request] --> P[Planner]
    P -->|work-package.md| A[Architect]
    A -->|ADR| D[Designer]
    D -->|component-spec.md| C[Coder]
    C -->|code on branch| R[Reviewer]
    R -->|review-report.md| DP[Deployer]
    DP -->|release-gate.md| DONE[Done]
```

## Per-Agent Table
<paste the table from Step 2>

## Integration Points
<paste the list from Step 3>
EOF
```

Commit it. This file becomes the reference document L2's facilitator re-reads at the start of each lab.

### Inline Insight: Why ADRs come before design specs

A common failure mode is "Designer writes the spec; Coder discovers a fatal architectural flaw; spec is rewritten." This burns two agent-runs per discovery.

The Architect goes *before* the Designer specifically to prevent this. The ADR is the cheap, small, reversible artifact that locks down the shape before we spend tokens on detailed props tables. If Designer and Coder produce garbage, you first suspect a bad ADR — then fix it — rather than re-spec'ing in place.

If you're running without an Architect, you've effectively asked the Designer to make architectural decisions inline. That's fine for cosmetic features (button colors) but catastrophic for anything involving storage, concurrency, or external integrations.

---

## Part 4: Define Handoff Contracts (10 min)

> **Goal:** Make the transitions between specialists explicit, ensuring that every stage produces exactly what the next one requires to do its job.

> **Agent Guide:** As the participant reads each handoff row, ask: "Could a stranger pick up the consumed artifact and produce the next one without asking a question?" If not, the fields list is incomplete. For the Reviewer handoff specifically, ask which checks are specific to this project — things a generic linter can't catch. Those define the Reviewer's unique value.

The 6 agents are connected by 5 handoffs. Each handoff is a **contract**: Agent A produces a specific artifact; Agent B reads it as authoritative and is not allowed to relitigate.

### Step 1: Read the Five Handoff Contracts

Copy this table into your design doc:

```markdown
## Handoff Contracts

| From → To             | Artifact                          | Required fields |
|-----------------------|-----------------------------------|-----------------|
| Planner → Architect   | work-packages/<slug>.md           | goal, stories, AC, deps, test cases, scope boundary |
| Architect → Designer  | docs/adr/NNNN-<slug>.md           | context, options (≥2), decision, consequences, references to WP |
| Designer → Coder      | design/<slug>-spec.md             | purpose, location, props, state, interactions, data flow, edge cases |
| Coder → Reviewer      | feature branch (no file artifact) | passing tests, lint clean, code matches spec |
| Reviewer → Deployer   | review-reports/<slug>-review.md   | summary, spec compliance, findings, test coverage, recommendation |
```

### Step 2: Pick the Two Most Interesting Handoffs

For *your* project, pick the two handoffs with the most risk — the ones most likely to go wrong first. For a typical web app, those are:

1. **Planner → Architect** — high risk because vague Planner output wastes Architect reasoning.
2. **Designer → Coder** — high risk because ambiguous specs lead to wrong implementations.

For a data/ML project, you might pick Architect → Designer (for schema decisions) and Reviewer → Deployer (for evaluation gates). Pick whatever *you* expect to struggle with.

### Step 3: Write a Full Contract for Each

Use this template per handoff:

```markdown
## <Agent A> → <Agent B> Handoff Contract

### Agent A MUST provide:
- <artifact type>
- <required field 1>
- <required field 2>

### Agent B EXPECTS to receive:
- <input format>
- <level of detail>

### Agent B MUST NOT:
- <decision A should not revisit>
- <artifact A should not edit>

### Example for our feature:
<paste a concrete excerpt showing the contract in use>
```

**Example: Planner → Architect for Fired Up Pizza loyalty points:**

```markdown
## Planner → Architect Handoff Contract

### Planner MUST provide:
- work-packages/loyalty-points.md
- Goal section (one sentence, outcome-focused)
- ≥1 AC per story, binary-testable
- Test cases in Given/When/Then form
- Scope Boundary with IN and OUT lists

### Architect EXPECTS to receive:
- Full work package path in the bead description
- All AC already quantified (no "make it fast" — must say "<100ms p95")
- Scope boundary that names the open architectural questions explicitly

### Architect MUST NOT:
- Edit the work package's stories or AC
- Re-open scope that the Planner marked OUT
- Invent new acceptance criteria

### Example excerpt:
  > From work-packages/loyalty-points.md:
  > "Scope Boundary → OUT: expiration policy, admin dashboard"
  >
  > Architect's ADR therefore only addresses storage for earn/redeem,
  > not retention or admin tooling.
```

**What's happening here:** The "MUST NOT" line is load-bearing. Without it, Agent B will helpfully "improve" the spec and silently erase scope. You'll see this pattern repeat in every downstream handoff — each agent must refuse to revise artifacts upstream of itself.

### Step 4: Commit Both Contracts

Append them to `docs/factory-wiring.md` so L2 can read them. In L2, Part 1 Step 3, you'll turn these contracts into concrete edits to `packs/planner/prompts/planner.md.tmpl` (Output Format) and `packs/architect/prompts/architect.md.tmpl` (Inputs + Quality Gate).

### Inline Insight: Config over ad-hoc chat corrections

When an agent produces bad output, there are two ways to respond:

- **Wrong:** Open the chat, say "hey, also add a section on error handling." Agent complies. Next run, same bug.
- **Right:** Edit the Quality Gate of that agent's prompt to require error handling. Re-sling the bead. The fix is now in version control and repeats every future run.

This is the single biggest discipline shift from "using an LLM as a tool" to "running a software factory." L2, L3, and L4 all require this discipline to stick; W2 is where you internalize it before the stakes rise.

### Inline Insight: Artifacts are the only memory

Agents do not share memory across beads. When the Architect runs, it does not remember what the Planner said in chat — it reads the work package. When the Reviewer runs, it does not remember the Coder's reasoning — it reads the diff and the spec.

This has two practical consequences:

1. **If a fact matters, it must be in a file.** "The Planner said in chat that refunds are out of scope" is useless to the Architect. "The work package's Scope Boundary section lists refunds under OUT" is authoritative.
2. **Cross-references are load-bearing.** The Architect appends the ADR path to the work package specifically so the Designer, reading the work package, finds the ADR. Break the cross-reference chain and you break the handoff.

---

## Part 5: Understand the `actual adr-bot` Layer (5 min)

> **Goal:** Understand how industry best practices can be brought into your factory automatically, so your specialists begin grounded in patterns the field has already validated rather than rediscovering them from scratch.

Your Architect agent writes ADRs. You have two ways to source ADR content:

1. **Write each ADR from scratch** — the Architect proposes three options, evaluates trade-offs, picks one. This is what L2 walks you through.
2. **Seed tailored industry ADRs first** (`actual adr-bot`) — a CLI that analyzes your repo and *tailors* best-practice ADRs to your codebase, writing them into `CLAUDE.md` / `AGENTS.md` automatically (works with any AI coding assistant). Your Architect then references those ADRs when making local decisions instead of rediscovering industry patterns.

### Step 1: Install (Optional but Recommended)

```bash
brew install actual-software/actual/actual
```

From your project repo:

```bash
cd ~/path/to/your-repo
actual adr-bot --dry-run      # Preview what it would write
actual adr-bot                 # Write tailored ADRs into CLAUDE.md / AGENTS.md
```

### Step 2: Example ADRs You Might See Written

For a React/TypeScript/SQLite project like Fired Up Pizza, `actual adr-bot` might populate `CLAUDE.md` with tailored versions of ADRs like:

- **ADR-seed-1: Prefer explicit TypeScript types at module boundaries** — customized to cite `src/types/` and call out exported functions specifically.
- **ADR-seed-2: Use parameterized queries for all database access** — customized to name `better-sqlite3`'s `.prepare()` API and show an example against the `orders` table.

The Architect, when asked to write ADR-0001 for loyalty points, will:

1. Read these seed ADRs from `CLAUDE.md` first.
2. Recognize that "parameterized queries" is already a project standard — it won't rewrite that decision.
3. Focus its ADR exclusively on the *novel* question (points ledger vs column on users table).

### Step 3: Note the Three Design Implications

What this adds to your W2 design:

- **Handoff contract Planner → Architect** gains a prior step: the Architect reads the curated ADR set first, and only writes a new ADR when the decision isn't covered by an existing one.
- **Quality bar for ADRs** gets higher: a decision to *deviate* from a tailored industry ADR is a more interesting artifact than a decision made in a vacuum.
- **Review criteria (Reviewer agent, W4 inputs)** now has `actual`-sourced ADRs as an additional compliance axis: "Does this code violate ADR-seed-2 on parameterized queries?"

Note this in your `docs/factory-wiring.md`: *"Architect reads `CLAUDE.md` ADR section first; writes new ADRs to `docs/adr/NNNN-<slug>.md` only for decisions not covered."*

Skipping `actual adr-bot` is fine for the workshop — you'll just have fewer ADR baselines and the Architect will rederive more patterns. You can install it later.

---

## Connection to Gas City

Each row of your factory design maps directly to a file path under `packs/` and `my-factory/`. Here's the mapping to keep open as you move to L2:

| W2 design deliverable | Becomes concrete edit in | Installed in |
|-----------------------|--------------------------|--------------|
| "Planner produces `<your work package format>`" | `packs/planner/prompts/planner.md.tmpl` — Output Format section | L2 |
| "Architect produces `<your ADR format>`" | `packs/architect/prompts/architect.md.tmpl` — Output Format section | L2 |
| "Designer produces `<your spec format>`" | `packs/designer/prompts/designer.md.tmpl` — Output Format section | L3 |
| "Coder writes to `<your src layout>`" | `packs/builder/prompts/builder.md.tmpl` — Output + Rules sections | L3 |
| "Reviewer checks `<your review standards>`" | `packs/reviewer/prompts/reviewer.md.tmpl` + `docs/PROJECT_MANIFEST.md` Review Standards | L4 |
| "Deployer gates on `<your release criteria>`" | `packs/release-gate/prompts/release-gate.md.tmpl` + `docs/PROJECT_MANIFEST.md` Release Criteria | L4 |
| Handoff contract Planner → Architect | `## Inputs` + `## Output Format` must match across both prompts | L2 |
| Handoff contract Architect → Designer | `## Inputs` of designer.md must reference the ADR path format Architect writes | L3 |
| Handoff contract Designer → Coder | `## Inputs` of coder.md must name the spec format Designer writes | L3 |
| Handoff contract Coder → Reviewer | Reviewer's Inputs section references the feature-branch diff + spec path | L4 |
| Handoff contract Reviewer → Deployer | Deployer's Inputs section references review report path + Release Criteria | L4 |

Also note the skeleton template layout — this is what your project's filesystem should look like after W2:

```
my-factory/
  docs/
    PROJECT_MANIFEST.md        ← source of truth every agent reads first
    factory-wiring.md          ← your W2 deliverable
    adr/                       ← Architect writes here (ADR-NNNN-slug.md)
  work-packages/               ← Planner writes here
  design/                      ← Designer writes here
  review-reports/              ← Reviewer writes here
  release-gates/               ← Deployer writes here
  feedback-loops/              ← W4 feedback rules
  CLAUDE.md                    ← Global agent instructions (+ tailored ADRs)
```

During W2, two of these files matter most:

1. **`docs/PROJECT_MANIFEST.md`** — your design's single source of truth. Every agent reads this before doing anything. Domain model, conventions, success criteria, Review Standards, Release Criteria *all* land here.
2. **`docs/factory-wiring.md`** — the Mermaid diagram + per-agent table + handoff contracts you just wrote in Parts 3–4.

If you haven't copied the skeleton into your project repo yet, do so now so L2 starts clean:

```bash
mkdir -p ../../path/to/your-repo/{work-packages,docs/adr,design,review-reports,release-gates,feedback-loops}
```

---

## Read Fired Up Pizza as a Finished Reference

Fired Up Pizza is the reference project — a complete, working example of a 6-agent factory's *shape*. Spend 5 minutes scanning:

- [`reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md`](../../../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — compare length and specificity to your own `docs/PROJECT_MANIFEST.md`. Note the Review Standards and Release Criteria sections — those are the Reviewer's and Deployer's input.
- [`reference-project/fired-up-pizza/tickets.md`](../../../reference-project/fired-up-pizza/tickets.md) — the backlog that feeds the factory. Note how each ticket is written: single-sentence goal, explicit acceptance criteria, no implementation detail. Tickets become bead descriptions, which become Planner input.
- [`reference-project/fired-up-pizza/workflow-card.md`](../../../reference-project/fired-up-pizza/workflow-card.md) — the workflow card that seeded Fired Up Pizza's agent instructions. Note the rules around prices in cents and TypeScript strict mode — those constrain every agent downstream.
- [`packs/fired-up-pizza/pack.toml`](../../../packs/fired-up-pizza/pack.toml) — the *composite* pack that bundles all 6 agent packs. In C1 (the capstone), you install this one pack and get all 6 agents at once.

Ask yourself: *if I replaced `docs/PROJECT_MANIFEST.md` in Fired Up Pizza with mine, would the agent prompts still make sense?* If not, your manifest is under-specified — and that's exactly what Part 3 corrects.

---

## Common Issues and Solutions

Real problems you'll hit during and after W2:

### Issue 1: "My feature is too simple — the Architect has nothing to decide"

If your chosen feature is purely cosmetic (button color, copy change), the Architect will produce a trivial ADR and you won't learn the discipline. **Fix:** pick a feature with a storage, concurrency, or integration decision. "Add CSV export" becomes interesting if you ask "stream vs buffer? run in request vs queue job?".

### Issue 2: "My work package has vague acceptance criteria"

You wrote AC like "should be fast" or "should be nice." **Fix:** quantify everything. "Fast" → "p95 <100ms on the order confirmation page". "Nice" → "matches the visual style of the adjacent order summary card." The Planner's Quality Gate literally says "no ambiguous terms remain."

### Issue 3: "I can't tell what goes in the manifest vs. what goes in a prompt"

Rule of thumb: if it's *project-specific* (domain model, tech stack, Review Standards) it goes in `docs/PROJECT_MANIFEST.md`. If it's *agent-specific* (output format, quality gate, process steps) it goes in the pack prompt.

### Issue 4: "My handoff contract has no MUST NOT clause"

Without it, downstream agents will edit upstream artifacts and silently erase scope. **Fix:** every contract needs at least one MUST NOT. Examples: "Architect MUST NOT edit AC", "Coder MUST NOT reorganize files from the spec", "Reviewer MUST NOT add new requirements not in the spec."

### Issue 5: "I put integration points in the Designer's prompt, not the manifest"

Integration points (existing files and APIs your feature touches) are project-specific, not agent-specific. Put them in the manifest's Domain Model or a per-feature work package. Pack prompts should be reusable across features.

### Issue 6: "I wrote my design as prose, not a table"

Prose is hard to translate into prompt-file edits. **Fix:** the per-agent table in Part 3, Step 2 is the expected form. Each row becomes one concrete edit in L2-L4.

### Issue 7: "I have more than one open architectural question for this feature"

Write more than one ADR. It's normal for a feature to spawn ADR-0001 (storage) and ADR-0002 (API pattern). Just make sure each ADR addresses a single decision — multi-decision ADRs are impossible to supersede cleanly later.

### Issue 8: "My Reviewer is going to check things not in PROJECT_MANIFEST"

Everything the Reviewer checks must be in the Review Standards section. If you want it to check accessibility, add an Accessibility subsection. If you want it to check error handling, add an Error Handling subsection. The Reviewer cannot invent standards out of thin air — it reads them from the manifest.

### Issue 9: "Skipped the Architect for a small feature — now the Coder is making architectural choices"

If the Coder is deciding where to store data or which API pattern to use, you should have routed through the Architect first. **Fix:** in your wiring doc, write "Architect runs unless feature touches only one file in `src/components/`." Anything broader triggers the full pipeline.

### Issue 10: "Not sure how `actual adr-bot` fits with my own ADRs"

Tailored ADRs (in `CLAUDE.md`) are baselines. Hand-written ADRs (in `docs/adr/`) are feature-specific decisions. The Architect reads baselines first, then writes a feature ADR only if the decision isn't already covered or needs a local override. Think of `CLAUDE.md` as ADR-seed-\* and `docs/adr/` as ADR-NNNN.

---

## Concept Check (before moving to L2)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain — in their own words, without re-reading — each bullet below. If they can't, revisit the matching section before running the Exit Criteria check.

- Why each agent reads files, not chat history, for handoff. (Chat memory is lost across sessions; files are durable.)
- Why the artifact per stage is singular — one work package, one ADR, one spec. (Keeps the interface auditable.)
- What distinguishes the Planner's work package from the Architect's ADR from the Designer's spec. (Scope of decision — what-to-build, how-to-build, how-to-structure.)
- Why the 6-agent split produces better code than a single do-everything agent. (Each prompt is narrow; each handoff is a checkpoint.)
- Why `AGENTS.md` stubs belong in the project repo even before the packs are installed. (They encode the pipeline shape — L2 just fills it in.)

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `docs/PROJECT_MANIFEST.md` exists in your project repo and has all five sections filled in (Tech Stack, Project Structure, Domain Model, Conventions, Review Standards, Release Criteria)
- [ ] `docs/factory-wiring.md` exists with a Mermaid diagram + per-agent table + integration points + two handoff contracts
- [ ] You can name, in one sentence each, what every one of the 6 agents will produce for your chosen feature
- [ ] You've skimmed all 6 pack prompt files in `packs/*/prompts/*.md` and recognize the six-section shape
- [ ] You've decided whether to seed ADR baselines with `actual adr-bot` before L2 (or explicitly noted "write all ADRs from scratch")
- [ ] You've read the Fired Up Pizza reference project's manifest and tickets for comparison

---

## Command Cheat Sheet

W2 is design-only — no agent runs. These are the file-browsing and scaffolding commands you may have used:

```bash
# Browse the shipped packs
ls /path/to/software-factory-intensive/packs/
cat /path/to/software-factory-intensive/packs/planner/prompts/planner.md.tmpl
cat /path/to/software-factory-intensive/packs/architect/pack.toml

# Read the reference project
cat /path/to/software-factory-intensive/reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md
cat /path/to/software-factory-intensive/reference-project/fired-up-pizza/tickets.md

# Scaffold your project with the skeleton
mkdir -p ../../path/to/your-repo/{work-packages,docs/adr,design,review-reports,release-gates,feedback-loops}

# Optional: seed tailored industry ADRs before L2
brew install actual-software/actual/actual
cd ~/path/to/your-repo
actual adr-bot --dry-run
actual adr-bot

# Commit your design
cd ~/path/to/your-repo
git add docs/PROJECT_MANIFEST.md docs/factory-wiring.md
git commit -m "docs: W2 factory design for <your feature>"
```

No `gc` or `bd` commands are required for W2. Those kick in at L2 when you install your first pack.

---

## Quick Reference: Your Factory Design

After W2, your design doc should answer every row in this table. Fill it in now if any row is still blank.

| Axis | Your answer |
|------|-------------|
| Chosen feature | e.g., "Loyalty points for Fired Up Pizza" |
| Architectural question | e.g., "Column vs separate ledger table for storage?" |
| Planner output path | `work-packages/<your-slug>.md` |
| Architect output path | `docs/adr/NNNN-<your-slug>.md` |
| Designer output path | `design/<your-slug>-spec.md` |
| Coder output path(s) | `src/<subpath>` — list every file you expect to touch |
| Reviewer output path | `review-reports/<your-slug>-review.md` |
| Deployer output path | `release-gates/<your-slug>-gate.md` |
| Integration points (existing files) | List every file your feature will edit or depend on |
| Review Standards added to manifest | Any project-specific Review Standards (e.g., "prices in cents") |
| Release Criteria added to manifest | Any project-specific gates (e.g., "bundle size delta <5%") |
| ADR baselines via `actual adr-bot`? | Yes / No — decide before L2 |
| Riskiest handoff | Which handoff you expect to struggle with most |
| `docs/factory-wiring.md` committed? | Yes / No — must be Yes before starting L2 |

---

## Next Steps

In **L2**, you'll:

- Install the Planner and Architect packs (`gc rig add --include`)
- Customize `packs/planner/prompts/planner.md.tmpl` and `packs/architect/prompts/architect.md.tmpl` with the handoff contracts you wrote here
- Create your first bead, sling it to the Planner, review the work package against the Quality Gate
- Optionally seed tailored ADRs via `actual adr-bot` before running the Architect
- Sling a dependent bead to the Architect, produce ADR-0001, verify cross-references in both directions

**Bring to L2:**

- [ ] `docs/PROJECT_MANIFEST.md` — filled in with tech stack, domain model, Conventions, Review Standards, Release Criteria
- [ ] `docs/factory-wiring.md` — Mermaid diagram + per-agent table + integration points + two handoff contracts
- [ ] A one-sentence note of whether you'll seed ADRs via `actual adr-bot` or write each from scratch
- [ ] Your chosen feature ready to describe as a bead title + description

Without these three artifacts, L2's first 20 minutes will be scrambling to write what W2 was designed to produce.
