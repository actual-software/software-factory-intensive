# L2 · Deploy Planner + Architect Agents

> **What you'll build:** The first two agents of the 6-agent pipeline — a **Planner** that takes a `needs-plan` bead and decomposes it into a dependency graph of labelled child beads, and an **Architect** that takes a `needs-architecture` bead and produces a system design, architectural rules, and ADRs synchronized via `actual adr-bot`. By the end of this lab a bead walks `needs-plan` → (optionally `needs-architecture` → `needs-plan`) → children labelled `needs-design` or `ready-to-build` on your own project, driven entirely by label flips.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | Lab |
| **Deliverable** | Customised `planner` + `architect` packs scoped to your project, plus one goal bead that walked through planning (and architecture, if triggered) to a dependency graph of downstream child beads |

---

## Session workspace note

* **Pack locations (shipped):** `packs/planner/` and `packs/architect/` under the `software-factory/` tree. Prompt templates are `packs/<agent>/prompts/<agent>.md.tmpl` (the `.tmpl` suffix is the Gas City template extension). Formulas are `packs/<agent>/formulas/mol-<name>.formula.toml`.
* **Gas City workspace:** `my-factory/` — this is where `city.toml` lives. Every `gc` command below is run from that folder unless otherwise noted. (If you installed the L1 factory under `~/Projects/factory/lab_l1/l1-gc-factory/` via `curriculum-agent install L1`, substitute that path — the lab steps are path-agnostic.)
* **Your deliverables this session:** `notes.md` plus customised pack copies. If your workshop uses an activity folder (`activities/labs/L2/`), put them there; otherwise keep your customised pack copies anywhere tracked by git.
* **Wiring the packs:** at the end of the session, `my-factory/city.toml`'s `includes` should reach the `planner` and `architect` packs — either the shipped copies or your customised copies.

If a pack edit breaks your factory, swap back to the shipped pack path in `city.toml` and `gc service restart` — the shipped packs always pass `gc doctor`.

**Canonical reference:** L2 is your first hands-on encounter with the labeled-beads paradigm. Keep [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) open in another tab — it's the authoritative doc for the six labels, who adds each one, and who consumes it. Every handoff in this lab is a label flip on the same bead; there are no durable markdown docs (`PLAN.md`, `ARCHITECTURE.md`) passed between agents.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should open `docs/PROJECT_MANIFEST.md` in the participant's rig first — the planner and architect both read it as their primary project-context input. If it's empty or missing, planner output will be generic and architect output will hallucinate the stack.

---

## Architecture Diagram

```
                     (user files a goal bead with --label needs-plan)
                                       │
                                       ▼  needs-plan
                  ┌──────────────────────────────────────┐
                  │           PLANNER AGENT               │
                  │                                        │
                  │  Order gate: bd ready --label=needs-   │
                  │              plan --limit=1            │
                  │                                        │
                  │  Reads:                                 │
                  │    • the bead (title, notes, ACs)       │
                  │    • docs/PROJECT_MANIFEST.md           │
                  │    • docs/architecture/*.md (if any)    │
                  │    • docs/rules/*.md (guardrails)       │
                  │                                        │
                  │  Runs mol-plan-breakdown: intake →      │
                  │  tracker-import → clarify → decompose   │
                  │  → dep-graph → handoff                  │
                  │                                        │
                  │  Produces: docs/plans/<slug>.md +       │
                  │  child beads labelled needs-design or   │
                  │  ready-to-build                         │
                  └────────────────────┬───────────────────┘
                          │            │
                 (normal) │            │ (drift detected)
                          │            ▼  needs-architecture
                          │  ┌────────────────────────────────┐
                          │  │         ARCHITECT AGENT         │
                          │  │                                  │
                          │  │  Order gate: bd ready --label=   │
                          │  │              needs-architecture  │
                          │  │              --limit=1           │
                          │  │                                  │
                          │  │  Runs mol-architect-review:      │
                          │  │  intake → research → design →    │
                          │  │  actual-adr-sync → rules →       │
                          │  │  handoff                         │
                          │  │                                  │
                          │  │  Produces:                        │
                          │  │    • docs/architecture/<t>.md    │
                          │  │    • docs/rules/<t>.md           │
                          │  │    • synced CLAUDE.md / AGENTS.md│
                          │  │      (via actual adr-bot)        │
                          │  │    • child bead with needs-plan  │
                          │  └──────────────┬──────────────────┘
                          │                  │
                          │                  ▼  needs-plan (back to planner)
                          │                  │
                          ▼                  │
                  ┌───────┴──────────────────┴──────────────┐
                  │ children with needs-design / ready-to-  │
                  │ build (continue to Designer + Coder in   │
                  │ L3 and L4)                               │
                  └──────────────────────────────────────────┘
```

Nothing in this diagram is a durable markdown *handoff* document. The plan file (`docs/plans/<slug>.md`) and the architecture/rules files are **artifacts produced by each agent** for humans and downstream agents to read, but the **routing signal** — what wakes which agent next — is a label flip on the bead. That's the paradigm the factory runs on — see [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for why.

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L1 complete | `gc status` shows your project rig with at least the shipped 6-agent pipeline wired in | Finish L1 first. L2 replaces two of the shipped packs with your customised copies; the pipeline must be running first. |
| Gas City running | `gc status` shows your city and agents are up | Re-run `gc service start` from `my-factory/` (or the `lab_l1` factory dir if that's where you installed it in L1) |
| `docs/PROJECT_MANIFEST.md` filled in | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` shows tech stack, domain model, conventions | Copy from [`../../../PROJECT_MANIFEST_TEMPLATE.md`](../../../PROJECT_MANIFEST_TEMPLATE.md) and fill in. A generic manifest produces generic planner output. |
| `docs/rules/` directory exists in your rig | `ls ~/path/to/your-repo/docs/rules/` succeeds (empty is fine) | `mkdir -p ~/path/to/your-repo/docs/rules` — the architect will populate it. |
| `actual` CLI installed (recommended) | `actual --version` prints a version | `brew install actual-software/actual/actual`. Without it the architect skips the ADR-sync step gracefully; with it you get synchronised `CLAUDE.md` / `AGENTS.md` for free. |
| A goal worth planning | A feature idea for your project that's complex enough to decompose into 3+ child beads (e.g. "Add loyalty points system", "Add two-factor auth") | Borrow from the reference: FUP-4 "Loyalty points for Fired Up Pizza" is the running example and is sized exactly right for this session. |

If any row fails, stop and fix it. L2 is a thin lab by Gas City primitive count (you already know `gc rig add --include`, order gates, and `bd label` from L1) but it is demanding in terms of upstream artifact quality. A weak `PROJECT_MANIFEST.md` propagates into weak plans and weak architecture; the same feature with a tight manifest produces dramatically different agent output.

### No goal handy?

If you don't have a feature sketch ready for your own project, use the Loyalty Points example verbatim:

```bash
cd ~/path/to/your-repo
bd create \
  --title "Feature: Loyalty points system" \
  --label needs-plan \
  --notes "$(cat <<'EOF'
Add a loyalty points system where customers earn 1 point per $1 spent
and can redeem 100 points for $5 off at checkout.

Acceptance:
- Points accrue on every paid order
- Points visible on order confirmation page
- 100 pt → $5 discount applied at checkout
- Refunded orders reverse earned points
- Admin can see total issued vs. redeemed

Open questions:
- Where to store points — user column or separate ledger?
- How to treat partial refunds?
- Expiration policy?
EOF
)"
```

The open questions are deliberate — they will trip the planner's drift detection and route the bead through the architect, exercising both agents.

---

## Part 0: Read the Shipped Packs (~5 min)

Before customising anything, read what you're about to install. Both packs ship with a prompt template, a formula, an order gate, a doctor check, and one or two commands.

### Step 1: Open the planner pack

Three files in order:

1. [`packs/planner/pack.toml`](../../../packs/planner/pack.toml) — metadata. Note `wake_mode = "fresh"` (every wake re-derives state from the bead; no cached status files) and the nudge that tells the agent to `bd ready --label=needs-plan`. The two agent-level knobs you'll touch most are `idle_timeout` and `max_active_sessions`.
2. [`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl) — the system prompt. Skim the *Primary focus* block: **take goal beads, produce dependency-ordered child beads**. The two personas in the prompt (Product Manager + Program Manager) are intentional — the PM voice writes user stories and ACs; the PgM voice wires dependencies and flags risk.
3. [`packs/planner/formulas/mol-plan-breakdown.formula.toml`](../../../packs/planner/formulas/mol-plan-breakdown.formula.toml) — the 6-step work loop: intake → tracker-import → clarify → decompose → dep-graph → handoff. Every step writes state into the root bead's notes via `bd update --notes` and into `docs/plans/<slug>.md`.

And the order gate that decides *when* the planner wakes:

[`packs/planner/formulas/orders/planner-intake/order.toml`](../../../packs/planner/formulas/orders/planner-intake/order.toml)

```toml
[order]
description = "Wake the planner when any bead is labelled needs-plan"
formula = "mol-plan-breakdown"
gate = "condition"
check = "bd ready --label=needs-plan --limit=1 | grep -q ."
pool = "planner"
```

**What's happening here:** The planner doesn't need explicit `gc sling` commands. The order gate polls `bd ready --label=needs-plan`; as soon as a bead shows up with that label, mol-plan-breakdown runs. The label *is* the trigger. If you built any factory before using `gc sling <rig>/planner <bead>` by hand, unlearn it — L2 is where that habit goes away.

### Step 2: Open the architect pack

Same shape, different work:

1. [`packs/architect/pack.toml`](../../../packs/architect/pack.toml) — metadata. The nudge points at `bd ready --label=needs-architecture`.
2. [`packs/architect/prompts/architect.md.tmpl`](../../../packs/architect/prompts/architect.md.tmpl) — persona is **Principal Engineer + Solutions Architect**. Note the hard constraint near the top: *simplicity over cleverness; document the why*.
3. [`packs/architect/formulas/mol-architect-review.formula.toml`](../../../packs/architect/formulas/mol-architect-review.formula.toml) — the 6-step work loop: intake → research → design → actual-adr-sync → rules → handoff.
4. [`packs/architect/formulas/orders/architect-guardrail-check/order.toml`](../../../packs/architect/formulas/orders/architect-guardrail-check/order.toml) — order gate polling `bd ready --label=needs-architecture`.

Notice the two formula vars at the top of `mol-architect-review.formula.toml`:

```toml
[vars]
[vars.topic]
description = "Short topic slug used to name the design doc and rules file"
required = true

[vars.skip_adr_sync]
description = "Set to 'true' to skip the actual-adr-sync step"
default = "false"
```

`topic` is set per-invocation and ends up as the filename of the design and rules docs (`docs/architecture/<topic>.md`, `docs/rules/<topic>.md`). `skip_adr_sync` is the safety valve for rigs that don't have the `actual` CLI installed — the shipped formula will skip gracefully, but setting the default explicitly makes the behaviour visible.

### Step 3: Notice what's *not* here

Read both prompts end to end. A few things are deliberately absent:

- **No `work-packages/` or `SPEC.md` directory.** Earlier drafts of this curriculum had the planner write `work-packages/<slug>.md` as the handoff artifact. That's gone — child beads with labels carry the routing now. The plan file (`docs/plans/<slug>.md`) is a human-readable summary, not a handoff doc.
- **No architect → planner durable spec.** The architect produces `docs/architecture/<topic>.md`, `docs/rules/<topic>.md`, and ADRs. Those are reference artifacts. The actual "work is ready for you" signal to the planner is a new child bead with `needs-plan`.
- **No `gc sling` in the prompts.** Both prompts' Startup sections poll `bd ready --label=…` in a loop. That's the paradigm.

You're done reading. Now install.

---

## Part 1: Include the Packs and Wire `city.toml` (~10 min)

### Step 1: Decide shipped vs. customised

You have two choices for each pack:

**(a) Shipped as-is.** Include the pack directly from `packs/planner/` and `packs/architect/`. Fastest path — good for a first green run.

**(b) Copy and customise.** Copy the pack into your workspace (typically `my-factory/packs/<agent>/` or `activities/labs/L2/packs/<agent>/`), edit the prompt or formula, and include your copy. This is what Parts 2 and 3 below actually teach — the lab's main deliverable is a *customised* copy.

Most participants do (a) first to confirm the pipeline runs end-to-end, then switch to (b). The swap is one line in `city.toml`.

### Step 2: Copy the packs into your workspace

```bash
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/planner packs/planner
cp -rf ../software-factory/packs/architect packs/architect
```

(Exact source path depends on your checkout — adjust to point at `packs/planner/` and `packs/architect/` in the software-factory tree. If you installed L1 via `curriculum-agent install L1`, the shipped packs also live under `~/Projects/factory/lab_l1/l1-gc-factory/packs/actual/{planner,architect}/` and you can copy from there.)

### Step 3: Add the includes

Open `my-factory/city.toml` and make sure `includes` reaches `planner` and `architect`:

```toml
includes = [
    "packs/planner",        # NEW — your customised copy under my-factory/packs/
    "packs/architect",      # NEW
    "../packs/designer",    # shipped (L3 customises this)
    "../packs/coder",       # shipped (L3 customises this)
    "../packs/reviewer",    # shipped (L4 customises this)
    "../packs/deployer",    # shipped (L4 customises this)
]
```

If you're running shipped only (Step 1a), point the includes at the shipped paths (e.g. `"../packs/planner"`) and skip the copy.

### Step 4: Restart and verify

```bash
gc service restart
gc doctor
gc status
```

`gc doctor` should be green for all six agents. `gc status` should list `planner` and `architect` alongside the four downstream agents. If either is missing, `gc doctor`'s output names the failing check — usually a missing binary (`bd`, `gc`, `jq`; `actual` is optional but recommended for the architect).

### Step 5: Commit the wiring

```bash
cd my-factory
git add city.toml packs/planner packs/architect
git commit -m "chore(L2): wire planner + architect packs into my-factory"
```

---

## Part 2: Customise the Planner (~20 min)

> **Agent Guide:** Before the participant edits anything, ask them: "What's the shape of a typical feature in your project — backend-only, UI-only, full-stack?" Then: "Which of those shapes requires a design step vs. going straight to build?" Naming this out loud first keeps the `needs-design` vs `ready-to-build` routing rules grounded in real project shape instead of generic advice.

The planner's behaviour comes from three places:
- `packs/planner/prompts/planner.md.tmpl` — the personas, the primary focus, the work-loop narrative
- `packs/planner/formulas/mol-plan-breakdown.formula.toml` — the step-by-step procedure (decompose → dep-graph → handoff)
- `docs/PROJECT_MANIFEST.md` in your rig — the project-specific context the planner reads every run

You'll make one edit in each of the first two (the manifest was filled in as a prereq).

### Step 1: Sharpen the planner prompt for your project

Open `my-factory/packs/planner/prompts/planner.md.tmpl` in your editor. Find the *Primary focus* block:

```markdown
> Create work packages for agents based on high-level goals. Define
> clear acceptance criteria, track dependencies, flag risks early.
```

Append one project-specific sentence that tells the planner what your features most often hinge on. Example for an order-centric TypeScript app:

```diff
 > Create work packages for agents based on high-level goals. Define
 > clear acceptance criteria, track dependencies, flag risks early.
+> For this project, every plan must include at least one acceptance
+> criterion covering the order-lifecycle side effect (points, audit
+> log, webhook) — features that modify a customer's balance without
+> audit trail are the highest-recurrence bug class.
```

Substitute your own recurring-risk class. Aim for one sentence that tells the planner what to weight hardest when decomposing.

### Step 2: Tighten the decompose step for your project shape

Open `my-factory/packs/planner/formulas/mol-plan-breakdown.formula.toml` and find the `decompose` step. The shipped routing rules say:

```
- Design-touching work (new screens, new flows, changed interactions) → `needs-design`
- Implementation work (backend endpoint, algorithm, refactor, test coverage) → `ready-to-build`
```

If your project has a more specific shape, extend the rules. Example for a full-stack web app:

```diff
 **Label routing rules:**
 - **Design-touching work** (new screens, new flows, changed
   interactions) → `needs-design`
 - **Implementation work** (backend endpoint, algorithm, refactor,
   test coverage) → `ready-to-build`. The coder authors tests
   alongside the code; the reviewer downstream verifies that each
   acceptance criterion is exercised.
+- **Schema-changing work** → always gets its own child bead,
+  labelled `ready-to-build`, with an explicit migration in the
+  acceptance criteria. Never fold a migration into another child.
+- **Auth-touching work** → always gets `needs-architecture` first
+  (even if the goal bead was `needs-plan`) so the scoped-handler
+  boundary is decided before implementation.
```

The second rule above is how the planner learns to detect *drift* and hand back up to the architect. See the "needs-architecture" branch of the architecture diagram at the top of this README.

### Step 3: Add one drift-detection rule

The planner's `clarify` step is where drift should be caught. Find it in the same formula file and add a concrete drift check. Example:

```diff
 **3. If the goal is ambiguous enough that you can't write draft
 criteria confidently, STOP and file a clarification bead:**
 ...
+
+**4. Drift check.** Before proceeding to `decompose`, scan
+`docs/rules/*.md` for any rule that this goal would violate or
+extend. If found, STOP and hand the bead back up to the architect:
+```bash
+bd label remove $ROOT_ID needs-plan
+bd label add $ROOT_ID needs-architecture
+bd update $ROOT_ID --notes "<existing notes>
+drift: would violate docs/rules/<name>.md — routed to architect"
+exit 0
+```
```

This is the single most important rule in the planner customisation. Without it, the planner will cheerfully decompose a bead that should have gone through the architect, and your factory will ship code that violates its own rules.

### Step 4: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor            # should still be green
git add packs/planner
git commit -m "chore(planner): add drift check + schema-work routing rule"
```

---

## Part 3: Customise the Architect (~20 min)

> **Agent Guide:** Before the participant edits anything, ask them to name — in one sentence — the single architectural decision they most regret not making earlier in their project. That decision is the template for the kind of rule the architect should produce going forward. If they can't think of one, point them at `docs/PROJECT_MANIFEST.md` and ask which line has the weakest "why."

The architect's behaviour comes from three places:
- `packs/architect/prompts/architect.md.tmpl` — the personas, the primary focus, the constraint
- `packs/architect/formulas/mol-architect-review.formula.toml` — the step-by-step procedure (design → actual-adr-sync → rules)
- `docs/PROJECT_MANIFEST.md` in your rig — the project context the architect reads

You'll make one edit each in the prompt and the formula.

### Step 1: (Recommended) Seed tailored industry ADRs

Before the architect writes any ADR, give it a curated baseline. [Actual AI's `actual` CLI](https://github.com/actual-software/actual-cli) analyses your repo, fetches relevant Architecture Decision Records from a curated library, tailors them to your codebase, and writes the result into `CLAUDE.md` / `AGENTS.md`.

```bash
cd ~/path/to/your-repo
actual adr-bot --dry-run --full --force --no-tui
```

Read the preview. If it looks reasonable, run it for real:

```bash
actual adr-bot --force --no-tui
git add CLAUDE.md AGENTS.md docs/adr docs/rules
git commit -m "chore: seed tailored industry ADRs via actual adr-bot"
```

**What's happening here:** `actual adr-bot` looks at your repo's language, framework, dependencies, and file patterns, fetches ADRs that match, and rewrites each to reference your project's specific conventions. When the architect runs later, its `actual-adr-sync` step re-runs this same tool — the architect is piggy-backing on a baseline you seeded manually, not starting from scratch every time.

**The `--force --no-tui` flags matter.** Without them, `actual adr-bot` expects an interactive terminal and fails inside the architect's agent session with a `TerminalIOError`. The shipped architect formula always passes both flags — but if you run `actual` manually, match the invocation.

**Skipping this step is fine.** The architect will just write every ADR from scratch at its first invocation. But seeding baselines now means higher-quality first-run output.

### Step 2: Tighten the architect prompt for your project

Open `my-factory/packs/architect/prompts/architect.md.tmpl`. Find the *Primary focus* block:

```markdown
> Design the complete system architecture — technology stack, database
> schema, API design, component layout, trust boundaries, and
> guardrails.
```

Append one sentence that tells the architect what class of decision your project most often needs. Example for a multi-tenant SaaS:

```diff
 > Design the complete system architecture — technology stack, database
 > schema, API design, component layout, trust boundaries, and
 > guardrails.
+> For this project, every design must explicitly account for tenant
+> isolation — every table gets a tenant_id column, every query is
+> scoped, every API surface verifies the caller's tenant. If a design
+> cannot answer "how does this isolate tenant A from tenant B," it is
+> not done.
```

Substitute your own high-risk cross-cutting concern. Aim for one sentence that the architect will weigh every decision against.

### Step 3: Set the architect's default topic slug convention

Open `my-factory/packs/architect/formulas/mol-architect-review.formula.toml` and find the `[vars]` block:

```toml
[vars.topic]
description = "Short topic slug used to name the design doc and rules file"
required = true
```

Add a default so that architect invocations without an explicit topic don't fail. Example:

```diff
 [vars.topic]
 description = "Short topic slug used to name the design doc and rules file"
-required = true
+required = false
+default = "untitled-$(date +%Y%m%d-%H%M%S)"
```

The default isn't pretty, but it's better than the formula refusing to run when the planner (in its drift-escalation path) creates a `needs-architecture` bead without a pre-chosen topic slug. You can always rename the files afterward.

### Step 4: Add a project-specific constraint to the design step

In the same formula, find the `design` step and extend the design-doc structure to mention your project's recurring shape. Example for a web app that lives and dies by database performance:

```diff
 Structure:
 ```markdown
 # System Design: {{topic}}

 Root: $ROOT_ID
 Generated: <YYYY-MM-DD>

 ## Overview

 <1-2 paragraph summary of the system being designed>

 ## Technology Stack

 | Layer | Choice | Rationale |
 |-------|--------|-----------|
 ...

 ## Database Schema

 <Tables, relationships, indexes. ERD in ASCII or Mermaid.>
+
+## Query Performance

+For every new table, list the indexes that support the queries this
+feature will run, and name the query pattern each index serves.
+"Indexes as needed" is not an answer.

 ## API Design
```

Substitute whatever your project most often under-specifies. A project-specific prompt to "say the quiet part out loud" in every design doc is more valuable than three pages of generic architecture advice.

### Step 5: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor
git add packs/architect
git commit -m "chore(architect): tighten focus + require query-perf section"
```

---

## Part 4: Walk a Bead Through the Handoff (~15 min)

> **Agent Guide:** Once the participant creates the `needs-plan` bead, resist the urge to `gc sling` it manually. The point of this lab is to see that **labels alone drive the handoff.** If the planner doesn't wake within ~60s, the problem is the order gate or `gc doctor`, not a missing sling. Same for the architect.

You'll file one goal bead, watch it walk from `needs-plan` → (optionally `needs-architecture` → back to `needs-plan`) → child beads, and inspect every note it accumulates along the way.

### Step 1: Create the `needs-plan` bead

Using the loyalty-points example from Prerequisites, or your own goal:

```bash
cd ~/path/to/your-repo
bd create \
  --title "Feature: Loyalty points system" \
  --label needs-plan \
  --notes "acceptance_criteria:
- Points accrue on every paid order
- 100 pt → \$5 discount at checkout
- Refunded orders reverse earned points

open_questions:
- Where to store points — user column or ledger?
- How to treat partial refunds?"
```

The open questions are deliberately unresolved — they should trip the planner's drift check (Part 2, Step 3) and route the bead through the architect. Note the bead ID that `bd create` prints.

### Step 2: Watch the planner work

```bash
gc status                           # planner should flip to working
gc session peek <rig>/planner       # snapshot of the tmux session
gc events --follow                  # stream events from another terminal
bd show <bead-id>                   # notes accumulate as each step completes
```

The planner walks its 6 steps:

1. **intake** — classifies the goal (feature/bug/refactor/research), records `slug` in notes.
2. **tracker-import** — no-op if no tracker skill is installed.
3. **clarify** — copies acceptance criteria into a structured block; runs the drift check you added.
4. **decompose** — creates 3–10 child beads with routing labels.
5. **dep-graph** — wires `bd dep add` edges, writes `docs/plans/<slug>.md`.
6. **handoff** — closes the root bead.

After step 3, one of two things happens:

**(a) No drift detected.** The planner proceeds to decompose, creates child beads with `needs-design` / `ready-to-build` labels, closes the root bead. You're done with the planner path; jump to Step 4.

**(b) Drift detected.** The planner removes `needs-plan`, adds `needs-architecture`, and exits. The bead is now aimed at the architect. Continue to Step 3.

Verify which path ran:

```bash
bd label list <bead-id>
bd show <bead-id> | grep -E 'drift|goal_class|slug'
```

### Step 3: Watch the architect work (if drift was routed)

The architect's order gate is now matching. Within a poll interval, `gc status` shows the architect working. Its 6 steps:

1. **intake** — classifies the architectural question (access-control, trust-boundary, data-flow, …), records topic.
2. **research** — surveys existing ADRs, tech stack, codebase patterns. Writes findings to bead notes.
3. **design** — writes `docs/architecture/<topic>.md` (the system-design doc).
4. **actual-adr-sync** — runs `actual adr-bot --dry-run --full --force --no-tui`, inspects the diff. On a small/sensible diff, commits it. On a large divergence, files a divergence bead and stops. Skipped gracefully if `actual` isn't installed.
5. **rules** — writes `docs/rules/<topic>.md` with the guardrail that motivated this review.
6. **handoff** — creates one or more child beads labelled `needs-plan`, closes the root bead.

Verify:

```bash
ls ~/path/to/your-repo/docs/architecture/
ls ~/path/to/your-repo/docs/rules/
bd show <bead-id> | grep -E 'arch_category|topic|adr_sync'
bd list --label needs-plan             # the new children the architect handed back
```

### Step 4: Watch the planner re-run on the architect's child bead

The architect's child bead is now labelled `needs-plan`, which the planner's order gate matches. The planner wakes again (on the *child* bead, not the original root — which is closed), runs its 6 steps, and this time decomposes cleanly because the drift is resolved.

Verify:

```bash
bd show <child-id>                      # status in flight then closed
bd list --label=needs-design            # any UI-touching children
bd list --label=ready-to-build          # any direct-to-coder children
cat docs/plans/<slug>.md                # human-readable plan
```

### Step 5: Inspect the full graph

```bash
bd dep graph <original-bead-id> --format=ascii
```

You should see a tree rooted at your original bead, with the architect's child in the middle layer, and the planner's final children at the leaves. The whole walk just happened on label flips.

### Step 6: Capture the run in `notes.md`

For your activity deliverable, drop a short `notes.md` noting:
- The root bead id you filed
- Whether drift was routed (and to which rule in `docs/rules/`)
- The topic slug the architect picked
- The final leaf beads (ID + label) and their titles
- Any prompt/formula edits you made during iteration and which finding motivated each

---

## Part 5: Fix via Config (~10 min)

> **Agent Guide:** If the planner produced weak output (vague ACs, too many children, no dependency edges), the correction goes into the prompt or formula. The instant the participant opens `docs/plans/<slug>.md` to hand-fix the plan, stop them — the next feature gets the same weakness.

Three realistic scenarios follow, one for each of the most common first-run failures.

### Scenario A — Planner produced children with vague ACs

A child bead reads: "Implement points accrual — make sure it works." No measurable criteria.

**Wrong fix:** Edit the child bead by hand, add criteria, carry on.

**Right fix:** Edit `my-factory/packs/planner/formulas/mol-plan-breakdown.formula.toml` step `decompose`. Append to the per-child rule:

```diff
 **For each child:**
 ```bash
 CHILD_ID=$(bd create \
     --title "<concrete user-story title>" \
     --label <needs-design|ready-to-build> \
     --label source:actual-planner \
     --label plan:{{slug}} \
     --notes "Acceptance:
 - <criterion 1>
 - <criterion 2>

 Derived from $ROOT_ID" \
     --json | jq -r '.id')
 ```
+
+**Rule:** Every child bead must have at least two acceptance
+criteria, each phrased as "Given X, when Y, then Z". If you cannot
+write two criteria, the child bead is too coarse — split it.
```

Re-run on the same root (`bd label add <root-id> needs-plan && bd update <root-id> --reopen`), and the next iteration enforces the rule on every child.

### Scenario B — Planner didn't hand back drift to the architect

The planner cheerfully decomposed a goal that clearly required architectural review (e.g., a new trust boundary), bypassing the architect entirely.

**Wrong fix:** Manually create a `needs-architecture` bead and relabel.

**Right fix:** Strengthen the drift check you added in Part 2 Step 3. Add concrete keywords that should always trigger drift:

```diff
 **4. Drift check.** Before proceeding to `decompose`, scan
 `docs/rules/*.md` for any rule that this goal would violate or
 extend.
+
+Also, if the goal body matches any of the following keywords,
+escalate regardless of existing rules:
+- `auth`, `login`, `permission`, `access control`
+- `pricing`, `payment`, `checkout`, `refund`
+- `migration`, `schema change`, `drop column`
+If any match, remove `needs-plan`, add `needs-architecture`, and exit.
```

Commit, relabel the root back to `needs-plan`, watch it escalate correctly this time.

### Scenario C — Architect produced a design without a Query Performance section (the one you required in Part 3 Step 4)

You added a project-specific section requirement, but the architect skipped it.

**Wrong fix:** Edit `docs/architecture/<topic>.md` by hand to add the section.

**Right fix:** The architect's `design` step narrative is the contract. Your template diff is there, but the architect is ignoring it because the requirement isn't load-bearing enough in the formula. Tighten it:

```diff
 ## Query Performance

 For every new table, list the indexes that support the queries this
 feature will run, and name the query pattern each index serves.
 "Indexes as needed" is not an answer.
+
+**Exit criteria for this step:** If the design document does not
+include a Query Performance section with at least one (index,
+query-pattern) pair, do NOT advance to `actual-adr-sync`. Write the
+missing section first.
```

Commit, relabel the root to `needs-architecture`, watch the architect this time produce the section.

### The Rule

At least **one** agent output in your run must be resolved via a prompt or formula edit — not a hand-edit in `docs/plans/` or `docs/architecture/`. That is the deliverable of this lab. Run `git log my-factory/packs/` at the end of the session; you should see at least one commit whose message names the finding the edit addresses.

---

## Inline Insight: Why the Planner Can Hand Back to the Architect

Most factories conceive of the pipeline as a straight line: Planner → Architect → Designer → Coder → Reviewer → Deployer. In practice, the most common real-world *re-route* is the Planner discovering mid-decompose that a goal needs architectural guardrails it doesn't have. The shipped planner formula makes this re-route a first-class path: the `clarify` step is explicitly allowed to remove `needs-plan`, add `needs-architecture`, and exit before `decompose` ever runs.

That's why the architecture diagram at the top of this README has a loop back. It's not a graceful degradation — it's the expected happy path for any feature that touches rules the architect hasn't written yet. If your planner never triggers drift across a full session's worth of features, that's a signal the drift check is too lenient, not that your features are unusually straightforward.

## Inline Insight: Why the Architect Writes Both `docs/architecture/` and `docs/rules/`

The design doc (`docs/architecture/<topic>.md`) captures the *full decision* — stack choices, schema, API, trade-offs, alternatives considered. It's long and narrative, meant for the human who has to extend or overturn the decision later.

The rule file (`docs/rules/<topic>.md`) captures the *single enforceable constraint* the decision produces — "every query must be tenant-scoped," "every endpoint taking userId must verify req.user.id," etc. It's short, with an explicit "How to apply" section, and is read by the planner's drift check and the reviewer's spec check on every run.

Both matter, for different readers. The design doc is how the architect's *reasoning* persists. The rule file is how the architect's *decision* enforces itself across the factory's future runs without anyone re-reading the reasoning.

## Inline Insight: Why `actual adr-bot` Runs Inside the Architect Formula

You could hand-run `actual adr-bot` after every architect invocation and keep the rig's `CLAUDE.md` / `AGENTS.md` in sync. You could, but you won't — nobody does that reliably, and the moment it lapses, the coder and reviewer start reading stale guardrails.

The architect's `actual-adr-sync` step makes the sync a mandatory output of any architectural review. The cost is one formula step and a `--force --no-tui` invocation; the benefit is that `CLAUDE.md` is always as fresh as the most recent ADR, because the agent that wrote the ADR also ran the sync in the same session.

If your rig doesn't have `actual` installed, the step skips gracefully (check the formula — it exits 0 with a documented reason). You lose auto-sync but nothing else.

---

## Common Issues & Solutions

### Issue 1: Planner never wakes after you label a bead `needs-plan`

**Cause:** The order gate either can't find `bd`, or the label syntax on the bead doesn't match. `bd ready --label=needs-plan --limit=1` on the command line returns nothing.

**Fix:** Run `bd ready --label=needs-plan --limit=1` manually. If it returns a result but the agent still doesn't wake, `gc doctor` will show the `check-planner` script failing — usually a missing binary. If the command returns nothing, double-check `bd label list <bead-id>` — a trailing space or case mismatch prevents matching.

### Issue 2: Planner produces zero children

**Cause:** Either the goal bead is ambiguous enough that the planner filed a `needs-info` clarification bead and paused, or the decompose step crashed silently.

**Fix:** `bd list --label needs-info` to see any clarification beads. If none, check `gc events --follow` for errors during `decompose`. Common culprit: your goal has fewer than 2 sentences of body, and the planner couldn't identify distinct work items. Flesh out the goal bead and re-label `needs-plan`.

### Issue 3: Planner decomposed without triggering drift, but should have

**Cause:** Your Part 2 Step 3 drift check is too lenient or wasn't committed.

**Fix:** `git log my-factory/packs/planner/formulas/` — is the commit there? If yes, `grep -n drift my-factory/packs/planner/formulas/mol-plan-breakdown.formula.toml` to confirm the rule is present. Add concrete keyword triggers (Scenario B above) if the original rule was too abstract.

### Issue 4: Architect never wakes after a `needs-architecture` bead appears

**Cause:** Same family as Issue 1, but for the architect's order gate.

**Fix:** `bd ready --label=needs-architecture --limit=1`. `gc doctor` for the `check-architect` script. The most common distinct failure is that the architect requires the `actual` CLI in its doctor check; if `actual` isn't installed, the check can pass-with-warning (shipped default) or fail (if the check is strict). Install it or mark the check optional.

### Issue 5: `actual adr-bot` fails inside the architect with `TerminalIOError`

**Cause:** The formula isn't passing `--force --no-tui`, or someone removed those flags during customisation.

**Fix:** `grep -n 'actual adr-bot' my-factory/packs/architect/formulas/mol-architect-review.formula.toml` — every invocation must include `--force --no-tui`. Without them, `actual` expects an interactive terminal and crashes the agent session. The shipped formula has it right; don't strip the flags.

### Issue 6: Architect filed a divergence bead and stopped

**Cause:** The `actual-adr-sync` step saw a large, unrelated diff in the dry-run and refused to commit it. This is a safety default — it would rather stop than ship a bulk rewrite of unrelated ADRs.

**Fix:** `bd list --label type:divergence` to find the bead. Either (a) run `actual adr-bot --dry-run --full --force --no-tui` manually, review the diff, and commit it if it's actually desired; or (b) narrow the sync to a subset of ADRs. Resolve the divergence bead and the architect can finish its run.

### Issue 7: Children inherit wrong labels

**Cause:** The planner's `decompose` step defaulted to `ready-to-build` for everything, including UI work that should have been `needs-design`.

**Fix:** Tighten the decompose step's routing rules (Part 2, Step 2). Add concrete signals (file extensions, module names, manifest sections) that should force `needs-design`. Re-run; watch the children label correctly.

### Issue 8: You hand-edited `docs/plans/<slug>.md` and the next planner run re-wrote it

**Cause:** The planner's `dep-graph` step rewrites `docs/plans/<slug>.md` every run. Hand-edits between runs get clobbered — by design.

**Fix:** Don't hand-edit plan artifacts. If the plan is wrong, the prompt or formula is wrong; fix that and re-run. If you need to record side context, add it to the bead's notes, not the plan file.

---

## Quality Bar

When you review your own output, check:

- **Labels drove everything.** `gc events --follow` output for this bead shows `label_added` / `label_removed` events at every handoff. No `gc sling planner <bead>` or `gc sling architect <bead>` in the history.
- **Drift was exercised.** The goal bead either walked through `needs-architecture` or you can explain specifically why it didn't for your project (i.e. no rules would have been violated — so document the absence of drift, not just its absence of appearance).
- **Plan artifact is concrete.** `docs/plans/<slug>.md` names every child bead by ID and title, shows the dep graph in ASCII, and can be handed to a new engineer as a standalone doc.
- **Architecture artifacts are paired.** If the architect ran, `docs/architecture/<topic>.md` (the long-form decision) AND `docs/rules/<topic>.md` (the enforceable constraint) both exist. One without the other is a bug.
- **Config-discipline evidence.** At least one commit in `git log my-factory/packs/` names a planner or architect finding the edit addresses. Zero hand-edits attributable to "fixing the plan" or "fixing the design" in `git log ~/path/to/your-repo/docs/`.
- **ADR sync ran or was explicitly skipped.** If `actual` is installed, the architect committed a sync. If not, the bead notes record `adr_sync: skipped — actual CLI not installed`. A silent absence is a signal the step crashed.

---

## Concept Check (before moving to L3)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain each bullet in their own words, without re-reading. If they can't, revisit the matching section.

- **Why labels are the handoff contract instead of a durable `PLAN.md` or `SPEC.md`.** (State machine, one inbound label per agent, natural queue via `bd ready --label`. The plan file and design doc are artifacts, not handoffs.)
- **Why the planner can hand a bead back up to the architect.** (Real features frequently discover mid-decompose that they need guardrails that don't exist yet. Drift-back is the expected happy path, not an exception.)
- **Why the architect writes both `docs/architecture/` and `docs/rules/`.** (The design doc is narrative; the rule file is enforceable. The planner's drift check reads rules on every run, not the full design doc.)
- **Why `actual adr-bot --force --no-tui` matters.** (Agent sessions have no interactive terminal; without the flags, `actual` crashes. The shipped formula passes them; don't strip them during customisation.)
- **What would happen if you hand-edited `docs/plans/<slug>.md` after the planner ran.** (Next planner run overwrites it. The file is a generated artifact, not a source of truth. Fix the prompt, not the file.)

---

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `gc doctor` is green for `planner` and `architect` alongside the four downstream packs
- [ ] `my-factory/city.toml` includes the planner and architect packs (shipped or your customised copies)
- [ ] One goal bead walked `needs-plan` → (optionally `needs-architecture` → back to `needs-plan`) → child beads labelled `needs-design` or `ready-to-build`, on nothing but label flips
- [ ] `docs/plans/<slug>.md` exists and names every child bead
- [ ] If drift was routed: `docs/architecture/<topic>.md` and `docs/rules/<topic>.md` both exist in your rig
- [ ] If `actual` CLI is installed: the architect committed an ADR sync; `CLAUDE.md` / `AGENTS.md` reflect the new decision
- [ ] At least one commit in `git log my-factory/packs/` resolves a planner or architect finding via a prompt / formula edit (zero hand-edits to plan or design files attributable to findings)
- [ ] Both customised packs are committed to git

**L2 is a prerequisite for L3.** The designer and coder in L3 consume the planner's child beads (labelled `needs-design` and `ready-to-build`). If the planner doesn't produce clean children here, L3 will feel like the designer and coder agents are inexplicably weak — the cause is upstream. Don't move on until the exit criteria above all pass.

---

## Command Cheat Sheet

Every command you ran during this lab, in order:

```bash
# PART 0 — read the packs (no commands — just read the files)

# PART 1 — include + wire
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/planner packs/planner
cp -rf ../software-factory/packs/architect packs/architect
$EDITOR city.toml                              # add "packs/planner" + "packs/architect" to includes
gc service restart
gc doctor
gc status
git add city.toml packs/planner packs/architect
git commit -m "chore(L2): wire planner + architect packs"

# PART 2 — customise planner
$EDITOR packs/planner/prompts/planner.md.tmpl                    # tighten Primary focus
$EDITOR packs/planner/formulas/mol-plan-breakdown.formula.toml   # add drift check + routing rules
gc service restart && gc doctor
git add packs/planner && git commit -m "chore(planner): add drift check + routing rules"

# PART 3 — customise architect
cd ~/path/to/your-repo
actual adr-bot --dry-run --full --force --no-tui     # preview tailored ADRs
actual adr-bot --force --no-tui                      # commit (if preview looked right)
git add CLAUDE.md AGENTS.md docs/adr docs/rules && git commit -m "chore: seed tailored ADRs"
cd -                                                  # back to my-factory
$EDITOR packs/architect/prompts/architect.md.tmpl                    # add project constraint
$EDITOR packs/architect/formulas/mol-architect-review.formula.toml   # topic default + design template
gc service restart && gc doctor
git add packs/architect && git commit -m "chore(architect): project constraint + design-doc template"

# PART 4 — walk a bead through the handoff
cd ~/path/to/your-repo
bd create --title "Feature: <your feature>" --label needs-plan \
  --notes "acceptance_criteria:
- <criterion 1>
- <criterion 2>

open_questions:
- <question 1>"
gc status                                # watch planner wake + run
bd show <bead-id>                        # notes accumulate (goal_class, slug, drift)
bd label list <bead-id>                  # see label flipped to needs-architecture (if drift) or remain / children spawn
# If architect ran:
bd show <bead-id> | grep -E 'arch_category|topic|adr_sync'
ls docs/architecture/ docs/rules/
# After planner re-runs on the architect's child:
bd dep graph <original-bead-id> --format=ascii
bd list --label needs-design
bd list --label ready-to-build
cat docs/plans/<slug>.md

# PART 5 — fix via config (when planner or architect output is weak)
$EDITOR my-factory/packs/planner/formulas/mol-plan-breakdown.formula.toml     # tighten the rule
git -C my-factory add packs/planner/formulas
git -C my-factory commit -m "chore(planner): require two ACs per child"
bd label add <bead-id> needs-plan        # re-arm the planner
# (planner re-runs; findings are now absent)
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Planner pack | `packs/planner/` | Defines the Planner agent: prompt template, formula, order gate, doctor check, commands |
| Planner prompt | `packs/planner/prompts/planner.md.tmpl` | PM + PgM personas, primary focus, work-loop narrative, drift-handback rationale |
| Planner formula | `packs/planner/formulas/mol-plan-breakdown.formula.toml` | 6-step work loop: intake → tracker-import → clarify → decompose → dep-graph → handoff |
| Planner order gate | `packs/planner/formulas/orders/planner-intake/order.toml` | Polls `bd ready --label=needs-plan`; wakes the planner on match |
| Architect pack | `packs/architect/` | Defines the Architect agent |
| Architect prompt | `packs/architect/prompts/architect.md.tmpl` | Principal Engineer + Solutions Architect persona; simplicity-over-cleverness constraint |
| Architect formula | `packs/architect/formulas/mol-architect-review.formula.toml` | 6-step work loop: intake → research → design → actual-adr-sync → rules → handoff |
| Architect order gate | `packs/architect/formulas/orders/architect-guardrail-check/order.toml` | Polls `bd ready --label=needs-architecture`; wakes the architect on match |
| Project manifest | `docs/PROJECT_MANIFEST.md` in your rig | Read by both agents on every run — the primary source of project-specific context |
| Plan artifact | `docs/plans/<slug>.md` in your rig | Human-readable plan summary (not a handoff — children carry routing) |
| Design doc | `docs/architecture/<topic>.md` in your rig | Full-decision narrative (stack, schema, API, trade-offs) |
| Rule file | `docs/rules/<topic>.md` in your rig | Enforceable constraint with explicit "How to apply" — read by planner drift check and reviewer spec check |
| Synced ADR state | `CLAUDE.md`, `AGENTS.md`, `docs/adr/` | Kept fresh by `actual adr-bot` inside the architect's `actual-adr-sync` step |
| Bead notes | `bd show <bead-id>` | Where every intake / assessment / drift / adr_sync finding lives — no durable markdown handoff docs |

---

## Next Steps

After L2 the first two stages of your factory are yours. Remaining labs follow the same pattern you just practised:

- **L3** — customise the **Designer** (consumes `needs-design`) and the **Coder** (consumes `ready-to-build`). The planner's children from this lab are exactly what L3's designer and coder consume — clean child beads here make L3's agents look sharp.
- **L4** — customise the **Reviewer** (consumes `needs-review`) and the **Deployer** (consumes `ready-to-ship`). Completes the 6-agent pipeline.
- **W4** — introduces the optional 7th agent, the **Improver**, which consumes `needs-improve` beads produced by the deployer and feeds production signal back into agent prompts.
- **L5** — the Capstone. Combine everything and run a real feature end-to-end.

The pattern — read pack → include + wire → customise prompt and formula → watch a bead walk through on labels alone → fix findings by editing config, never by hand-editing output — is the whole curriculum at this point. L2 is where you first practised it on *your* project; L3 and L4 are the same loop at more stages.
