# L3 · Deploy Designer + Coder Agents

> **What you'll build:** The next two agents of the 6-agent pipeline — a **Designer** that takes a `needs-design` bead and produces wireframes + an accessibility audit under `docs/designs/`, and a **Coder** that takes a `ready-to-build` bead and produces committed code plus tests that exercise the bead's acceptance criteria. By the end of this lab a bead walks `needs-design` → Designer → `ready-to-build` → Coder → `needs-review` on your own project, driven entirely by label flips.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | Lab |
| **Deliverable** | Customised `designer` + `coder` packs scoped to your project, plus one `needs-design` bead that walked through Designer and Coder to a committed implementation labelled `needs-review` |

---

## Session workspace note

* **Pack locations (shipped):** `packs/designer/` and `packs/coder/` under the `software-factory/` tree. Prompt templates are `packs/<agent>/prompts/<agent>.md.tmpl` (the `.tmpl` suffix is the Gas City template extension). Formulas are `packs/<agent>/formulas/mol-<name>.formula.toml`.
* **Gas City workspace:** `my-factory/` — this is where `city.toml` lives. Every `gc` command below is run from that folder unless otherwise noted.
* **Your deliverables this session:** `notes.md` plus customised pack copies. If your workshop uses an activity folder (`activities/labs/L3/`), put them there; otherwise keep your customised pack copies anywhere tracked by git.
* **Wiring the packs:** at the end of the session, `my-factory/city.toml`'s `includes` should reach the `designer` and `coder` packs — either the shipped copies or your customised copies.

If a pack edit breaks your factory, swap back to the shipped pack path in `city.toml` and `gc service restart` — the shipped packs always pass `gc doctor`.

**Canonical reference:** by L3 the labeled-beads protocol should be familiar, but keep [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) open in another tab anyway — `needs-design` and `ready-to-build` are the two labels you'll be wiring against this session, and every handoff is a label flip on the same bead. There are no durable markdown docs passed between Designer and Coder; the bead carries the state, the label carries the routing.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should open `docs/PROJECT_MANIFEST.md` in the participant's rig first — the designer reads it for design-system conventions and the coder reads it for the tech stack, test framework, and naming rules. If it's empty, designer output will be generic wireframes and coder output will default to common patterns instead of the project's actual conventions.

---

## Architecture Diagram

```
                (planner decomposed into children with
                 needs-design or ready-to-build labels —
                 from L2)
                                 │
                                 ▼  needs-design
             ┌──────────────────────────────────────┐
             │            DESIGNER AGENT             │
             │                                        │
             │  Order gate: bd ready --label=needs-   │
             │              design --limit=1          │
             │                                        │
             │  Reads:                                 │
             │    • the bead (title, notes, ACs)       │
             │    • docs/plans/<slug>.md (if any)      │
             │    • docs/rules/*.md (a11y + design     │
             │      system rules)                      │
             │    • existing components / tokens /     │
             │      storybook entries                  │
             │                                        │
             │  Runs mol-design-cycle: intake →        │
             │  wireframe → a11y-check → handoff       │
             │                                        │
             │  Produces: docs/designs/<slug>.md        │
             │  (wireframe + a11y audit) and relabels  │
             │  the bead ready-to-build                │
             └────────────────────┬───────────────────┘
                                  │
                                  ▼  ready-to-build
             ┌──────────────────────────────────────┐
             │             CODER AGENT               │
             │                                        │
             │  Order gate: bd ready --label=ready-   │
             │              to-build --limit=1        │
             │                                        │
             │  Reads:                                 │
             │    • the bead (title, notes, ACs)       │
             │    • docs/designs/<slug>.md (if any)    │
             │    • docs/plans/<slug>.md (if any)      │
             │    • docs/rules/*.md                    │
             │    • CLAUDE.md / AGENTS.md (via the     │
             │      actual skill, for tailored ADRs)   │
             │                                        │
             │  Runs mol-code-from-spec: intake →      │
             │  actual-adr-check → plan → implement    │
             │  → self-test → handoff                  │
             │                                        │
             │  Produces: code + tests committed on    │
             │  a feature branch, bead relabelled      │
             │  needs-review                           │
             └──────────────────────────────────────┘
                                  │
                                  ▼  needs-review (handed to reviewer in L4)
```

Nothing in this diagram is a durable markdown *handoff* document. The design file (`docs/designs/<slug>.md`) and any plan file are **artifacts** that both agents and humans can read — but the **routing signal** that wakes the next agent is the label flip on the bead. That's the paradigm the factory runs on — see [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for why.

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L2 complete | `gc status` shows the planner and architect packs wired, and at least one bead has walked `needs-plan` → (optionally `needs-architecture` →) child beads labelled `needs-design` / `ready-to-build` | Finish L2 first. L3 consumes the planner's children as its own input. |
| Gas City running | `gc status` shows your city and agents are up | Re-run `gc service start` from `my-factory/`. |
| `docs/PROJECT_MANIFEST.md` filled in | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` shows tech stack, domain model, conventions | Copy from [`../../../PROJECT_MANIFEST_TEMPLATE.md`](../../../PROJECT_MANIFEST_TEMPLATE.md) and fill in. Designer and coder both read it on every run. |
| `docs/designs/` directory exists in your rig | `ls ~/path/to/your-repo/docs/designs/` succeeds (empty is fine) | `mkdir -p ~/path/to/your-repo/docs/designs` — the designer will populate it. |
| `docs/rules/` directory exists in your rig | `ls ~/path/to/your-repo/docs/rules/` succeeds | If L2 architect didn't populate it, `mkdir -p ~/path/to/your-repo/docs/rules` and add at least one `.md` — the designer reads rules for design-system constraints, the coder reads them for implementation guardrails. |
| `actual` CLI installed (recommended) | `actual --version` prints a version | `brew install actual-software/actual/actual`. The coder's `actual-adr-check` step skips gracefully without it; with it the coder verifies that `CLAUDE.md` / `AGENTS.md` are in sync with the rig's ADRs before writing code. |
| A bead labelled `needs-design` or a feature that should produce one | `bd list --label needs-design` shows at least one open bead, OR you have a feature idea sized for a single component/screen | See *"No needs-design bead handy?"* below. |

If any row fails, stop and fix it. L3 is the first lab where the downstream agent writes real code — a missing manifest propagates into defaulted library choices, and a missing rules file lets the designer invent a new navigation pattern instead of reusing the existing one.

### No needs-design bead handy?

If L2's planner didn't produce a `needs-design` child (pure backend work), or if you want a fresh starting point for L3, file one:

```bash
cd ~/path/to/your-repo
bd create \
  --title "Feature: Loyalty points badge on order confirmation" \
  --label needs-design \
  --notes "$(cat <<'EOF'
acceptance_criteria:
- Badge renders on the order confirmation page
- Shows current point balance fetched from the loyalty ledger
- Empty state: new customer with zero points → "0 points · earn 1 per $1 spent"
- Loading state: skeleton at the same width as the final badge
- Error state: "Points unavailable" (non-blocking)
- Reuses existing card + typography components

context:
- ADR: docs/adr/0001-loyalty-points-storage.md (points_ledger table)
- Plan: docs/plans/loyalty-points-system.md (if L2 produced one)
EOF
)"
```

The acceptance criteria are deliberately concrete — this lab is about watching Designer + Coder work against a tight contract, not about resolving ambiguity.

---

## Part 0: Read the Shipped Packs (~5 min)

Before customising anything, read what you're about to install. Both packs ship with a prompt template, a formula, an order gate, a doctor check, and one or two commands.

### Step 1: Open the designer pack

Three files in order:

1. [`packs/designer/pack.toml`](../../../packs/designer/pack.toml) — metadata. Note `wake_mode = "fresh"` (every wake re-derives state from the bead; no cached status files) and the nudge that tells the agent to `bd ready --label=needs-design`. `max_active_sessions = 1` is deliberate — design quality drops when the designer is context-switching between features.
2. [`packs/designer/prompts/designer.md.tmpl`](../../../packs/designer/prompts/designer.md.tmpl) — the system prompt. Skim the two personas: **UI/UX Designer** (user-centered, wireframe-first) and **Accessibility Engineer** (WCAG 2.1 AA, keyboard + screen reader first). The hard constraint near the top is *accessibility is built in, not bolted on.*
3. [`packs/designer/formulas/mol-design-cycle.formula.toml`](../../../packs/designer/formulas/mol-design-cycle.formula.toml) — the 4-step work loop: intake → wireframe → a11y-check → handoff. Every step writes state into the root bead's notes via `bd update --notes` and produces `docs/designs/<slug>.md`.

And the order gate that decides *when* the designer wakes:

[`packs/designer/formulas/orders/designer-intake/order.toml`](../../../packs/designer/formulas/orders/designer-intake/order.toml)

```toml
[order]
description = "Wake the designer when any bead is labelled needs-design"
formula = "mol-design-cycle"
gate = "condition"
check = "bd ready --label=needs-design --limit=1 | grep -q ."
pool = "designer"
```

**What's happening here:** Same shape as the planner and architect order gates you wired in L2. The label *is* the trigger. As soon as a bead shows up with `needs-design`, mol-design-cycle runs. No explicit `gc sling designer <bead>` anywhere.

### Step 2: Open the coder pack

Same shape, longer work loop:

1. [`packs/coder/pack.toml`](../../../packs/coder/pack.toml) — metadata. The nudge points at `bd ready --label=ready-to-build`. `idle_timeout = "2h"` is longer than the designer's because a real implementation often spans multiple build/test/fix cycles.
2. [`packs/coder/prompts/coder.md.tmpl`](../../../packs/coder/prompts/coder.md.tmpl) — persona is a **generalist engineer** in the mold of the Backend + Frontend voices. Hard constraint: *follow existing patterns rather than inventing new ones.* Note also the explicit bypass rule: the coder does **not** bypass `actual-adr-check` — stale ADRs get handed back to the architect.
3. [`packs/coder/formulas/mol-code-from-spec.formula.toml`](../../../packs/coder/formulas/mol-code-from-spec.formula.toml) — the 6-step work loop: intake → actual-adr-check → plan → implement → self-test → handoff.
4. [`packs/coder/formulas/orders/coder-intake/order.toml`](../../../packs/coder/formulas/orders/coder-intake/order.toml) — order gate polling `bd ready --label=ready-to-build`.

Notice the two formula vars at the top of `mol-code-from-spec.formula.toml`:

```toml
[vars]
[vars.test_cmd]
description = "Command to run the rig's test suite. Empty means auto-detect."
default = ""

[vars.commit_scope]
description = "Conventional-commit type (feat|fix|refactor|...)"
default = "feat"
```

`test_cmd` is how you pin the coder to your project's test runner instead of the auto-detect (which guesses from `go.mod` / `package.json` / `Cargo.toml` / `pyproject.toml`). Override it if your project uses something nonstandard. `commit_scope` controls the conventional-commits prefix on the coder's commit — most participants leave it as `feat` for feature work and only override when shipping a fix or a refactor.

### Step 3: Notice what's *not* here

Read both prompts end to end. A few things are deliberately absent:

- **No `design/<slug>-spec.md`, no component-spec file passed from designer to coder.** Earlier drafts of this curriculum had the designer write a structured spec (Props / State / Layout / Interactions) consumed by the coder. That's gone — the wireframe + a11y audit lives in `docs/designs/<slug>.md` as reference documentation, and the *routing signal* is the `ready-to-build` label flip on the bead.
- **No `gc sling` in the prompts.** Both prompts' Startup sections poll `bd ready --label=…` in a loop. The designer's outbound label is `ready-to-build` (per the canonical handoff in [`LABELED_BEADS.md`](../../../LABELED_BEADS.md)); the coder's outbound label is `needs-review`.
- **No separate test file / spec file authored by the designer.** The designer produces wireframes and an a11y audit. The coder authors the tests, alongside the code, driven by the bead's acceptance criteria. The reviewer downstream (L4) verifies AC coverage.

You're done reading. Now install.

---

## Part 1: Include the Packs and Wire `city.toml` (~10 min)

### Step 1: Decide shipped vs. customised

You have two choices for each pack:

**(a) Shipped as-is.** Include the pack directly from `../software-factory/packs/designer/` and `../software-factory/packs/coder/`. Fastest path — good for a first green run.

**(b) Copy and customise.** Copy the pack into your workspace (typically `my-factory/packs/<agent>/` or `activities/labs/L3/packs/<agent>/`), edit the prompt or formula, and include your copy. This is what Parts 2 and 3 below actually teach — the lab's main deliverable is a *customised* copy.

Most participants do (a) first to confirm the pipeline runs end-to-end, then switch to (b). The swap is one line in `city.toml`.

### Step 2: Copy the packs into your workspace

```bash
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/designer packs/designer
cp -rf ../software-factory/packs/coder packs/coder
```

(Exact source path depends on your checkout — adjust to point at `packs/designer/` and `packs/coder/` in the software-factory tree.)

### Step 3: Add the includes

Open `my-factory/city.toml` and make sure `includes` reaches `designer` and `coder`. If you did L2, you already have `planner` and `architect` wired — this session adds two more:

```toml
includes = [
    "packs/planner",        # from L2
    "packs/architect",      # from L2
    "packs/designer",       # NEW — your customised copy under my-factory/packs/
    "packs/coder",          # NEW
    "../packs/reviewer",    # shipped (L4 customises this)
    "../packs/deployer",    # shipped (L4 customises this)
]
```

If you're running shipped only (Step 1a), point the includes at the shipped paths (e.g. `"../packs/designer"`) and skip the copy.

### Step 4: Restart and verify

```bash
gc service restart
gc doctor
gc status
```

`gc doctor` should be green for all six agents. `gc status` should list `designer` and `coder` alongside the four other agents from L2 and L4. If either is missing, `gc doctor`'s output names the failing check — usually a missing binary (`bd`, `gc`, `git`, `jq`; `actual` is optional but recommended for the coder).

### Step 5: Commit the wiring

```bash
cd my-factory
git add city.toml packs/designer packs/coder
git commit -m "chore(L3): wire designer + coder packs into my-factory"
```

---

## Part 2: Customise the Designer (~20 min)

> **Agent Guide:** Before the participant edits anything, ask them: "What existing components does your project have that this feature should reuse before inventing new ones?" Then: "What's the one accessibility concern you most often forget to address in design review?" Naming both out loud before editing keeps the customisation grounded in real project shape rather than generic design advice.

The designer's behaviour comes from three places:
- `packs/designer/prompts/designer.md.tmpl` — the personas, the primary focus, the work-loop narrative
- `packs/designer/formulas/mol-design-cycle.formula.toml` — the step-by-step procedure (wireframe → a11y-check → handoff)
- `docs/PROJECT_MANIFEST.md` and `docs/rules/*.md` in your rig — the project-specific context

You'll make one edit in each of the first two (the manifest and rules were populated in L1/L2).

### Step 1: Align the handoff label with canonical

Open `my-factory/packs/designer/formulas/mol-design-cycle.formula.toml` and find the `handoff` step. The shipped formula relabels the bead `needs-plan` and hands back to the planner — a historical artifact from an earlier draft where the designer's wireframe could span multiple implementation beads.

The canonical contract in [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) is simpler: the designer's outbound label is `ready-to-build`, and the coder consumes it directly. Align the handoff:

```diff
 ```bash
 bd update $ROOT_ID \\
-    --add-label needs-plan \\
+    --add-label ready-to-build \\
     --add-label source:actual-designer \\
     --remove-label needs-design \\
     --notes "<existing notes>
 design_artifact: docs/designs/{{slug}}.md"
 ```
```

This is the single most important edit of Part 2. Without it the bead flips back to `needs-plan`, the planner re-runs, and the lab's clean `needs-design` → `ready-to-build` walk gets muddied. Commit it before moving on.

### Step 2: Sharpen the designer prompt for your project

Open `my-factory/packs/designer/prompts/designer.md.tmpl` in your editor. Find the *Primary focus* block:

```markdown
> Design user-centered interfaces that are intuitive, consistent, and
> visually polished. Ensure accessibility is built in, not bolted on.
```

Append one project-specific sentence that tells the designer what your product most often hinges on. Example for an e-commerce app with a mature design system:

```diff
 > Design user-centered interfaces that are intuitive, consistent, and
 > visually polished. Ensure accessibility is built in, not bolted on.
+> For this project, every design must reuse existing components from
+> src/components/ui/ before proposing new ones. If a wireframe cannot
+> be assembled from existing primitives, call out the missing piece
+> explicitly — don't silently invent a new visual pattern.
```

Substitute your own highest-leverage design-system rule. Aim for one sentence that tells the designer what to weigh hardest.

### Step 3: Tighten the wireframe step for your project shape

Open `my-factory/packs/designer/formulas/mol-design-cycle.formula.toml` and find the `wireframe` step's output structure. The shipped template produces Screens / Components / Interactions sections. If your project has a more specific shape — states, routing, data dependencies — extend the template. Example for a React app with feature folders:

```diff
 ## Screens

 ### Screen 1: <name>

 ```
 +--------------------+
 | Header             |
 +--------------------+
 | ... ASCII sketch . |
 +--------------------+
 ```

 Components reused: <list from the design system>
 New components needed: <list, or "none">
+
+Feature folder: src/features/<feature-slug>/
+Data dependencies: <list of hooks or endpoints the screen calls>
+Loading / error / empty states: <one line each>
```

The added fields force the designer to name the feature folder path, the data dependencies, and the three lifecycle states on every design — concrete enough that the coder in Part 3 has unambiguous context to implement against.

### Step 4: Add one project-specific a11y rule

The `a11y-check` step is where accessibility gets recorded. The shipped template covers focus order, ARIA, contrast, keyboard nav, and screen-reader labels. Add one project-specific rule if your product has recurring a11y debt. Example:

```diff
 - **Screen-reader labels:** <list of labels, alt text, aria-labels>
 - **Risks:** <any known a11y gaps the coder must avoid>
+- **Live regions:** any async state that updates without user action
+  (e.g. toast, balance refresh) must be announced via aria-live.
+  Silent updates are a blocker finding.
```

Substitute an a11y gap that has bitten your project before. Generic WCAG coverage is already in the shipped template; project-specific rules are what make this pack *yours*.

### Step 5: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor            # should still be green
git add packs/designer
git commit -m "chore(designer): align handoff label + add project design rules"
```

---

## Part 3: Customise the Coder (~20 min)

> **Agent Guide:** Before the participant edits anything, ask them what testing framework their project uses — Jest, Vitest, pytest, Go test, etc. Then: what's the one convention (commit style, import order, naming rule) that a first-week contributor most often gets wrong? Both answers should end up in the customisation below — the first as `test_cmd`, the second as a rule in the prompt.

The coder's behaviour comes from three places:
- `packs/coder/prompts/coder.md.tmpl` — the persona, the primary focus, the work-loop narrative
- `packs/coder/formulas/mol-code-from-spec.formula.toml` — the step-by-step procedure (actual-adr-check → plan → implement → self-test → handoff) and the two formula vars
- `docs/PROJECT_MANIFEST.md` + `docs/rules/*.md` + `CLAUDE.md` / `AGENTS.md` in your rig — project context read on every run

You'll make one edit to each of the first two.

### Step 1: Set the formula vars

Open `my-factory/packs/coder/formulas/mol-code-from-spec.formula.toml`. The `[vars]` block controls how the coder runs tests and commits. Pin both to your project:

```diff
 [vars]
 [vars.test_cmd]
 description = "Command to run the rig's test suite. Empty means auto-detect."
-default = ""
+default = "npm run typecheck && npm run lint && npm test -- --run"

 [vars.commit_scope]
 description = "Conventional-commit type (feat|fix|refactor|...)"
 default = "feat"
```

Replace with your project's equivalent — `go test ./...`, `pytest -q`, `cargo test`, `./gradlew test`, whatever the project actually runs in CI. Tying `test_cmd` to your CI's exact command means a green `self-test` step is a hard predictor of a green CI run on the coder's commit.

The auto-detect fallback (when `test_cmd` is empty) is fine for a first green pipeline, but it drops the typecheck and lint passes — making the coder's self-test weaker than CI. Explicit beats implicit.

### Step 2: Sharpen the coder prompt for your project

Open `my-factory/packs/coder/prompts/coder.md.tmpl`. Find the *Primary focus* block:

```markdown
> Implement reliable, performant code with clean architecture and
> comprehensive error handling. Follow existing component patterns.
> Keep bundle size minimal. Prefer correctness over performance
> optimization.
```

Append one project-specific sentence that names the highest-leverage convention your project depends on. Example for a TypeScript web app with strict typing:

```diff
 > Implement reliable, performant code with clean architecture and
 > comprehensive error handling. Follow existing component patterns.
 > Keep bundle size minimal. Prefer correctness over performance
 > optimization.
+> For this project, no exported function or component returns an
+> untyped value — `any` is prohibited in exported signatures. If a
+> type cannot be named precisely, prefer `unknown` with a narrowing
+> guard over `any`.
```

Substitute your own most-load-bearing code convention. This is the rule that, if broken, is expensive to fix later — so you want the coder to honour it on every first-pass implementation.

### Step 3: Tighten the implement step's guardrails

Open `my-factory/packs/coder/formulas/mol-code-from-spec.formula.toml` and find the `implement` step. The shipped guardrails are generic ("follow existing code patterns", "never add dependencies without a note"). Add one project-specific guardrail. Example for a React project with a standardised folder layout:

```diff
 **Guardrails:**
 - Follow existing code patterns. Check neighbouring files for style,
   naming, and library choices before adding anything new.
 - Never add dependencies without an explicit note in the bead.
 - Never modify files outside the scope implied by the plan.
 - Do not write documentation files unless the rule set requires them.
 - Do not commit yet — the commit happens in the handoff step after
   tests pass.
+- If the bead's design artifact names a feature folder
+  (`src/features/<slug>/`), implementation files MUST live under
+  that path. Never flatten into `src/components/`. Tests go in
+  `src/features/<slug>/__tests__/`.
```

Substitute a structural rule specific to your repo. The design artifact the designer produced (`docs/designs/<slug>.md`) is the coder's primary input after the bead — pointing the coder at it explicitly makes the handoff tight.

### Step 4: Require AC-referencing test descriptions

In the same `implement` step, or as a separate guardrail under `self-test`, add:

```diff
 **1. Determine the test command:**
```

expand just above that block with a rule:

```markdown
**Test-authorship rule.** Before running the suite, enumerate every
acceptance criterion from the bead notes. For each, write at least
one test whose description references the criterion by wording or
number (e.g. `it('[AC1] shows 0 points for a new customer', ...)`).
A test file without AC references passes `npm test` but will fail the
reviewer's spec-findings check in L4 — fix it here, not there.
```

This is how the coder pays down the AC-coverage gap *before* the reviewer flags it. The reviewer in L4 reads acceptance criteria off the bead and verifies each one is exercised by name; making that visible in the coder's prompt now saves a round-trip in L4.

### Step 5: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor
git add packs/coder
git commit -m "chore(coder): pin test_cmd + AC-referencing rule + feature-folder guardrail"
```

---

## Part 4: Walk a Bead Through the Handoff (~15 min)

> **Agent Guide:** Once the participant's `needs-design` bead is queued, resist the urge to `gc sling` anything. The point of the lab is to see that **labels alone drive the handoff.** If the designer doesn't wake within ~60s, the problem is the order gate or `gc doctor`, not a missing sling. Same for the coder after the designer relabels.

You'll pick up (or create) one `needs-design` bead, watch it walk through the designer and then the coder, and inspect every artifact and note it accumulates.

### Step 1: Queue the `needs-design` bead

Option (a) — use a child bead L2's planner produced:

```bash
bd list --label needs-design           # pick one of the IDs
```

Option (b) — file a fresh one (see *"No needs-design bead handy?"* in Prerequisites for a full example):

```bash
cd ~/path/to/your-repo
bd create \
  --title "Feature: Loyalty points badge on order confirmation" \
  --label needs-design \
  --notes "acceptance_criteria:
- Badge renders on order confirmation page
- Shows current point balance from the ledger
- Empty/loading/error states all handled"
```

Either way, the designer's order gate (`bd ready --label=needs-design --limit=1 | grep -q .`) will match within the gate's poll interval, and `mol-design-cycle` will start.

### Step 2: Watch the designer work

```bash
gc status                           # designer should flip to working
gc session peek <rig>/designer      # snapshot of the tmux session
gc events --follow                  # stream events from another terminal
bd show <bead-id>                   # notes accumulate as each step completes
```

The designer walks its 4 steps:

1. **intake** — reads the bead, any parent plan, existing components. Records the primary user action in notes.
2. **wireframe** — writes `docs/designs/<slug>.md` with screens, reused components, interactions (plus your project-specific fields from Part 2 Step 3).
3. **a11y-check** — appends an accessibility section (focus, ARIA, contrast, keyboard nav, screen-reader labels, plus your project-specific a11y rule from Part 2 Step 4).
4. **handoff** — adds `ready-to-build`, removes `needs-design`, pins `design_artifact: docs/designs/<slug>.md` in the notes.

After step 4, the bead is aimed at the coder. Verify:

```bash
bd label list <bead-id>                        # should show ready-to-build + source:actual-designer
ls ~/path/to/your-repo/docs/designs/           # new <slug>.md file
bd show <bead-id> | grep -E 'design_artifact|slug'
```

If the bead is still labelled `needs-design` after the designer returned to idle, the handoff step didn't run — inspect `gc events --follow` for the failure. Most common cause is a template variable (`{{slug}}`) that wasn't set; the formula exits step 4 early and leaves the bead in place.

### Step 3: Watch the coder work

The coder's order gate is now matching (because the designer just added `ready-to-build`). Within a poll interval, `gc status` shows the coder working. Its 6 steps:

1. **intake** — reads the bead, plan artifact, design artifact, and all rules under `docs/rules/`. Records acceptance criteria as the "exit contract" in bead notes.
2. **actual-adr-check** — runs `actual status` to verify CLAUDE.md / AGENTS.md are in sync with ADRs. If drifted, files a `needs-architecture` hand-back bead and stops; if `actual` isn't installed, skips gracefully.
3. **plan** — writes a 2–3 bullet implementation plan into bead notes. No speculative abstractions.
4. **implement** — writes code following the plan. The guardrails you tightened in Part 3 Step 3 apply here.
5. **self-test** — runs `{{test_cmd}}` from Part 3 Step 1. If it fails, loops back to step 4 and fixes. Never hands off red tests.
6. **handoff** — stages the scoped files, commits with a conventional message, removes `ready-to-build`, adds `needs-review`, closes the bead so downstream dependencies unblock.

The coder's run is usually the longest single step in the whole pipeline — typical runtime 10–25 minutes for a first-time feature, depending on how many implement/self-test cycles it takes to converge.

Detach with `Ctrl+b d`; the agent continues. Monitor progress:

```bash
gc events --follow                  # see every file read, every tool call
gc status                           # coder state: working → idle
bd show <bead-id>                   # notes keep growing
```

Wait until the coder's state returns to `idle`.

### Step 4: Verify the commit + handoff

```bash
cd ~/path/to/your-repo
git log --oneline | head -5
bd label list <bead-id>
bd show <bead-id> | grep -E 'impl_plan|self_test|commit'
```

You should see:

- A new commit at the top of `git log`, with a conventional-commit subject referencing the bead ID (e.g. `feat: Loyalty points badge on order confirmation (refs my-factory-abc123)`).
- Labels on the bead: `needs-review` added, `ready-to-build` removed. Status: `CLOSED` (the coder closes the bead after handoff; the reviewer in L4 re-labels without re-opening it).
- Notes containing `impl_plan:` (from step 3), `self_test: pass` and `test_cmd:` (from step 5), and the design_artifact line from the designer.

If the commit doesn't reference the bead ID, or the bead isn't labelled `needs-review`, the handoff step hit an error — `gc events --follow` will show where. Most common cause is `git add` failing because the coder edited files outside the scope implied by the plan; the commit step exits, and the bead sits in `ready-to-build` until the next poll.

### Step 5: Capture the run in `notes.md`

For your activity deliverable, drop a short `notes.md` noting:

- The bead id you walked through
- The design artifact path and a one-line summary of its a11y findings
- The coder's `impl_plan` bullets and the final `test_cmd` that ran
- Any pack edits you made during iteration and which finding motivated each

---

## Part 5: Fix via Config (~10 min)

> **Agent Guide:** This is the strictest part of the session. The instant the participant opens a source file to hand-fix a bug the coder introduced — or opens the wireframe to hand-fix a design gap — stop them, revert, and redirect to the prompt or formula. Hand-fixes die with the bead; config edits persist across every future feature.

Three realistic scenarios follow, one each for the designer, the coder, and the designer-coder seam. Work through whichever applies to your run.

### Scenario A — Designer omitted the empty/loading/error states

The designer's wireframe shows a happy-path balance display, but nothing about a new customer with zero points, the async fetch, or a failed request.

**Wrong fix:** Open `docs/designs/<slug>.md` and add the three states by hand.

**Right fix:** The designer's `wireframe` step template is the contract. Tighten it in `my-factory/packs/designer/formulas/mol-design-cycle.formula.toml`:

```diff
 Components reused: <list from the design system>
 New components needed: <list, or "none">

 Feature folder: src/features/<feature-slug>/
 Data dependencies: <list of hooks or endpoints the screen calls>
 Loading / error / empty states: <one line each>
+
+**Exit criteria for this step:** The Loading, Error, and Empty state
+lines each describe what renders in words. "TBD" or "skeleton"
+without further detail is not acceptable — name the element.
```

Re-run by adding `needs-design` back on the bead (`bd label add <id> needs-design`) and removing any downstream labels so the designer re-starts cleanly.

### Scenario B — Coder skipped AC-referencing test descriptions

Tests pass, but `grep -E 'AC[0-9]' src/features/<slug>/__tests__/` returns nothing. The reviewer in L4 will flag `uncovered_criteria` on every AC.

**Wrong fix:** Open the test file and rename the `it(...)` blocks by hand.

**Right fix:** The rule you added in Part 3 Step 4 wasn't load-bearing enough. Make it an exit criterion in the formula instead of a note in the prompt:

```diff
 [[steps]]
 id = "self-test"
 title = "Run the rig's test suite"
```

Add before step 6 (or to the end of step 5):

```markdown
**AC-coverage gate.** Before running the tests, grep the test files
for AC references:

```bash
AC_REFS=$(grep -cE '\[AC[0-9]+\]' $(find tests __tests__ -name '*.test.*' 2>/dev/null) 2>/dev/null || echo 0)
AC_COUNT=$(bd show $ROOT_ID --json | jq -r '.notes' | grep -cE '^- ' || echo 0)
if [ "$AC_REFS" -lt "$AC_COUNT" ]; then
    bd update $ROOT_ID --notes "<existing notes>
self_test: blocked — $AC_REFS/$AC_COUNT tests reference acceptance criteria by tag"
    exit 1
fi
```

Every `- ` line in acceptance_criteria must be matched by at least
one `[AC<N>]` reference in a test description.
```

Commit the formula edit, remove `needs-review` and re-add `ready-to-build` on the bead to send it back through the coder — the new gate runs before the coder can hand off, so the coder itself writes the tags instead of the reviewer chasing them in L4.

### Scenario C — Designer's feature folder disagrees with existing layout

The designer wrote `Feature folder: src/features/loyalty-points/` but your project uses `src/modules/loyalty-points/` by convention. The coder implemented in a brand-new `src/features/` path that didn't exist before this bead.

**Wrong fix:** `git mv` the files to the right path.

**Right fix:** This is a designer bug (wrong folder) that the coder inherited. Tighten the designer's `intake` step:

```diff
 **2. Survey existing components** — grep for existing storybook
 entries, component files, or design tokens. Re-use aggressively.
+
+**3. Identify the project's feature folder convention** by running
+`ls src/` and noting whether it contains `features/`, `modules/`,
+`pages/`, or something else. Use the existing convention on every
+design. Never propose a new top-level folder.
```

Commit, revert the commits the coder made (`git reset --hard HEAD~1` on the feature branch), remove `needs-review`, add `needs-design` back on the bead, and let the walk run again. Both designer and coder pick up the new convention.

### The Rule

At least **one** finding in your run must be resolved via a prompt or formula edit — not a hand-edit in `src/` or `docs/designs/`. That is the deliverable of this lab. Run `git log my-factory/packs/designer my-factory/packs/coder` at the end of the session; you should see at least one commit whose message names the finding the edit addresses.

---

> **Inline Insight: Why the Designer Doesn't Author Tests**
>
> In the shipped factory the designer's work loop ends at a wireframe + a11y audit. Tests are authored by the coder, alongside the implementation. That split exists because design and test design draw on different expertise — a UX designer knows the contrast ratio and the focus order; a generalist engineer knows the test framework, the existing test doubles, and the typical flakiness modes in your suite.
>
> Merging the two would produce weaker outputs in both directions. A designer writing Jest assertions from inside the wireframe loses contact with the user; a coder doing a11y from scratch duplicates the designer's a11y audit. The split keeps each agent focused on the artefact it produces best, and the bead's acceptance criteria are the contract that keeps them aligned — the designer's wireframe must cover every AC, and the coder's tests must reference every AC.

> **Inline Insight: Why the Coder Runs `actual-adr-check` Before Writing Code**
>
> The coder's second formula step is `actual-adr-check`: run `actual status`, verify CLAUDE.md / AGENTS.md match the rig's ADRs, and hand back to the architect on drift. It looks like ceremony until you imagine the alternative.
>
> Without the check, the coder reads a CLAUDE.md that says "all queries use the ORM" — but the most recent ADR (that didn't sync) just replaced the ORM with hand-written SQL. The coder dutifully writes ORM code against the new schema; the reviewer bounces it; the coder rewrites it; the bead cycles. The fix isn't a better prompt — it's a gate that refuses to start work until the rules the coder will read are the rules the architect actually decided. That's what `actual-adr-check` enforces, and it's why it runs *before* the plan step, not after.
>
> If your rig doesn't have `actual` installed, the step skips gracefully (records `adr_check: skipped — actual CLI not installed` in bead notes). You lose the check but nothing else crashes.

> **Inline Insight: Why the Bead Closes at the Coder's Handoff, Not at the Reviewer's**
>
> The coder's handoff step runs `bd close $ROOT_ID`. At first glance that seems premature — the code hasn't been reviewed or shipped yet. The reason is that `bd close` unblocks downstream dependencies in the bead graph. Other beads waiting on this one (e.g. a follow-up feature that depends on the points ledger existing) become ready as soon as the coder's implementation is committed — not after the reviewer eventually passes.
>
> The reviewer's job (L4) is to decide whether the committed code is safe to ship. That decision produces a `ready-to-ship` label or a `ready-to-build` bounce — both of which can happen on a *closed* bead via `bd update --add-label`. The label is the routing signal; the close state is the dependency-graph signal. Conflating them would force every blocked feature to wait for review — slowing the factory by the review time on every predecessor.

---

## Common Issues & Solutions

### Issue 1: Designer never wakes after a bead gets `needs-design`

<details>
<summary>Solution</summary>

**Cause:** Same family as L2's Issue 1. Either `bd` isn't on PATH for the order gate, or the label on the bead doesn't match exactly.

**Fix:** Run `bd ready --label=needs-design --limit=1` manually. If it returns a result but the designer doesn't wake, `gc doctor` will show the `check-designer` script failing. If it returns nothing, `bd label list <bead-id>` — watch for trailing spaces, case mismatches, or typos.

</details>

### Issue 2: Designer relabels to `needs-plan` instead of `ready-to-build`

<details>
<summary>Solution</summary>

**Cause:** You skipped Part 2 Step 1 (aligning the handoff label). The shipped formula hands back to the planner by default.

**Fix:** Apply the Part 2 Step 1 diff in `mol-design-cycle.formula.toml`. Remove `needs-plan` from the stuck bead and add `ready-to-build`; the coder picks it up on the next poll.

</details>

### Issue 3: Designer produces a wireframe without an a11y section

<details>
<summary>Solution</summary>

**Cause:** The `a11y-check` step crashed or exited early. Usually a missing template variable (`{{slug}}`) that made the file path invalid.

**Fix:** `gc events --follow` during the next run. Look for an error in the a11y-check step. Fix the template variable or fall back to setting it explicitly on the invocation (`bd update $ROOT_ID --notes 'slug: loyalty-points-badge'`) before re-labeling.

</details>

### Issue 4: Coder never wakes after the designer's handoff

<details>
<summary>Solution</summary>

**Cause:** Either the designer didn't actually add `ready-to-build` (see Issue 2), or the coder's order gate is failing.

**Fix:** `bd ready --label=ready-to-build --limit=1` manually. If it returns the bead but the coder is missing from `gc status`, `gc doctor` will name the failing check.

</details>

### Issue 5: Coder commits code that doesn't implement the design's a11y notes

<details>
<summary>Solution</summary>

**Cause:** The coder read the design artifact but the a11y section wasn't load-bearing enough in its prompt/formula to translate into test cases.

**Fix:** Add a rule in the coder's `implement` step: "Before writing any component file, list every bullet in the design's Accessibility section and write at least one test per bullet (focus, ARIA, contrast, keyboard nav, screen-reader labels, live regions)." Re-run the walk.

</details>

### Issue 6: `actual status` fails inside the coder with `TerminalIOError`

<details>
<summary>Solution</summary>

**Cause:** The formula isn't passing `--force --no-tui`, or the CLI is trying to open an interactive pane inside a tmux session that has no TTY.

**Fix:** `grep -n 'actual status' my-factory/packs/coder/formulas/mol-code-from-spec.formula.toml` — verify the invocation. The shipped formula's invocation is safe for non-interactive use; if you customised it and added prompts, remove them.

</details>

### Issue 7: Coder hand-edits files outside the plan, commit fails

<details>
<summary>Solution</summary>

**Cause:** The `handoff` step stages specific paths from `impl_plan` but the coder wrote to other files too — the commit either succeeds with unwanted changes or fails on `git add <missing-file>`.

**Fix:** Strengthen the `implement` step's guardrail: "Never modify files outside the scope implied by the plan" is too abstract. Replace with: "Before making a change, check that the file path is listed in `impl_plan`. If it isn't, either update `impl_plan` or don't make the change." Revert and re-run.

</details>

### Issue 8: Self-test step passes locally but fails CI

<details>
<summary>Solution</summary>

**Cause:** `test_cmd` is narrower than CI's invocation — e.g. the coder ran `npm test` but CI runs `npm run typecheck && npm run lint && npm test`.

**Fix:** Update `test_cmd` in the formula's `[vars]` block to match CI verbatim (Part 3 Step 1). A green `self-test` should be a hard predictor of a green CI.

</details>

### Issue 9: Designer's output duplicates components that already exist

<details>
<summary>Solution</summary>

**Cause:** The intake step's "survey existing components" guidance is too vague — the designer proposed new components without checking for reuse.

**Fix:** Tighten intake: "Run `rg -l 'export (default )?(function|const) [A-Z]' src/components/` and list every existing component by name. For each new component the wireframe proposes, justify explicitly why no existing component covers the use case." Commit and re-run.

</details>

### Issue 10: Bead flips between `ready-to-build` and `needs-review` repeatedly

<details>
<summary>Solution</summary>

**Cause:** The coder self-tests green, hands off to review, the reviewer (L4) bounces it, the coder re-runs, bounces again. This is the signal-from-L4 loop you're meant to act on — but the fix is in the coder's prompt, not in re-running.

**Fix:** Read the reviewer's notes on the bead (`bd show <bead-id>`). Translate the finding into a coder prompt or formula rule (see Scenario B in Part 5). Only then re-run. Looping the coder without a prompt edit is the anti-pattern this workshop tries to break.

</details>

### Issue 11: Coder closes the bead but never commits

<details>
<summary>Solution</summary>

**Cause:** The `handoff` step's git add / git commit logic silently fails (e.g. no files in the scope), but the close + relabel run anyway.

**Fix:** Guard the handoff: "If `git diff --cached --name-only` is empty after staging, abort — do not close the bead. Instead, record `handoff: blocked — no changes to commit` in notes and exit non-zero." Commit the formula edit; the next failure is explicit.

</details>

---

## Quality Bar

When you review your own output, check:

- **Labels drove everything.** `gc events --follow` output for this bead shows `label_added` / `label_removed` events at every handoff. No `gc sling designer <bead>` or `gc sling coder <bead>` in the history.
- **Design artifact exists.** `docs/designs/<slug>.md` is committed, contains wireframes + the a11y audit, and names a feature folder path.
- **Coder respected the design.** The implementation lives under the feature folder path the designer named. Every prop or data dependency in the design has a visible implementation. Every a11y note has at least one test.
- **Tests reference ACs.** Every acceptance criterion from the bead is exercised by at least one test whose description references it by tag or wording.
- **Config-discipline evidence.** At least one commit in `git log my-factory/packs/designer my-factory/packs/coder` names a designer or coder finding the edit addresses. Zero hand-edits attributable to "fixing the design" or "fixing the code" in `git log ~/path/to/your-repo/`.
- **ADR check ran or was explicitly skipped.** If `actual` is installed, the bead notes record `adr_check: ok` (or `adr_check: drift — handed back to architect`). If not, `adr_check: skipped — actual CLI not installed`. A silent absence is a signal the step crashed.

---

## Concept Check (before moving to L4)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain each bullet in their own words, without re-reading. If they can't, revisit the matching section.

- **Why labels are the handoff contract between Designer and Coder.** (`needs-design` → `ready-to-build` is a single relabel; no SPEC.md needed. The bead carries the state; the label carries the routing.)
- **Why the designer doesn't author tests.** (Separation of concerns: a11y + UX vs. test infrastructure. Tests are authored by the coder, alongside the code, against the bead's ACs.)
- **Why the coder runs `actual-adr-check` before planning.** (To refuse to code against stale rules. If CLAUDE.md / AGENTS.md don't match the ADRs, hand back to architect rather than implement against rot.)
- **Why the bead closes at the coder's handoff, not at the reviewer's.** (`bd close` unblocks the dependency graph; the reviewer's verdict lives on labels, not close state. Conflating them slows the factory.)
- **What would happen if you hand-fixed a failing test rather than editing the coder's prompt.** (Current bead passes; next feature re-introduces the same bug. Hand-fixes die with the bead; prompt edits persist.)

---

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `gc doctor` is green for `designer` and `coder` alongside the four other packs
- [ ] `my-factory/city.toml` includes the designer and coder packs (shipped or your customised copies)
- [ ] One `needs-design` bead walked to `ready-to-build` (designer handoff) then to `needs-review` (coder handoff), on nothing but label flips
- [ ] `docs/designs/<slug>.md` exists and is committed, with wireframes + a11y audit
- [ ] Implementation code is committed on a feature branch at the path the designer named
- [ ] Tests reference acceptance criteria by tag or wording and pass via the pinned `test_cmd`
- [ ] If `actual` CLI is installed: the coder's bead notes record `adr_check: ok` (or a documented hand-back)
- [ ] At least one commit in `git log my-factory/packs/designer my-factory/packs/coder` resolves a finding via a prompt / formula edit (zero hand-edits to design or code files attributable to findings)
- [ ] Both customised packs are committed to git

**L3 is a prerequisite for L4.** The reviewer and deployer in L4 consume the coder's committed implementation and the design artifact together. If the coder's commit is missing, the feature branch is dirty, or the design artifact is stale, L4 will feel like the reviewer is inexplicably strict — the cause is upstream. Don't move on until the exit criteria above all pass.

---

## Command Cheat Sheet

Every command you ran during this lab, in order:

```bash
# PART 0 — read the packs (no commands — just read the files)

# PART 1 — include + wire
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/designer packs/designer
cp -rf ../software-factory/packs/coder packs/coder
$EDITOR city.toml                              # add "packs/designer" + "packs/coder" to includes
gc service restart
gc doctor
gc status
git add city.toml packs/designer packs/coder
git commit -m "chore(L3): wire designer + coder packs"

# PART 2 — customise designer
$EDITOR packs/designer/formulas/mol-design-cycle.formula.toml   # handoff label → ready-to-build
$EDITOR packs/designer/prompts/designer.md.tmpl                 # tighten Primary focus
$EDITOR packs/designer/formulas/mol-design-cycle.formula.toml   # wireframe + a11y additions
gc service restart && gc doctor
git add packs/designer
git commit -m "chore(designer): align handoff label + project design rules"

# PART 3 — customise coder
$EDITOR packs/coder/formulas/mol-code-from-spec.formula.toml   # test_cmd + commit_scope
$EDITOR packs/coder/prompts/coder.md.tmpl                       # tighten Primary focus
$EDITOR packs/coder/formulas/mol-code-from-spec.formula.toml   # implement guardrails + AC gate
gc service restart && gc doctor
git add packs/coder
git commit -m "chore(coder): pin test_cmd + AC gate + feature-folder guardrail"

# PART 4 — walk a bead through the handoff
bd list --label needs-design                          # pick an existing one, or create a fresh one:
cd ~/path/to/your-repo
bd create --title "Feature: <your feature>" --label needs-design \
  --notes "acceptance_criteria:
- <criterion 1>
- <criterion 2>"
gc status                                # watch designer wake + run
bd show <bead-id>                        # notes accumulate
bd label list <bead-id>                  # ready-to-build after designer handoff
ls docs/designs/                         # design artifact
gc status                                # watch coder wake + run
bd show <bead-id>                        # notes grow through 6 steps
git log --oneline | head -5              # coder's commit on top
bd label list <bead-id>                  # needs-review (ready for L4)

# PART 5 — fix via config (when designer or coder output has a finding)
$EDITOR my-factory/packs/<agent>/...     # edit the prompt or formula
git -C my-factory add packs/<agent>
git -C my-factory commit -m "chore(<agent>): <what the finding required>"
bd label add <bead-id> needs-design       # or ready-to-build — re-arm the relevant agent
# (agent re-runs; findings are now absent)
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Designer pack | `packs/designer/` | Defines the Designer agent: prompt template, formula, order gate, doctor check, commands |
| Designer prompt | `packs/designer/prompts/designer.md.tmpl` | UI/UX + Accessibility Engineer personas, primary focus, work-loop narrative |
| Designer formula | `packs/designer/formulas/mol-design-cycle.formula.toml` | 4-step work loop: intake → wireframe → a11y-check → handoff |
| Designer order gate | `packs/designer/formulas/orders/designer-intake/order.toml` | Polls `bd ready --label=needs-design`; wakes the designer on match |
| Coder pack | `packs/coder/` | Defines the Coder agent |
| Coder prompt | `packs/coder/prompts/coder.md.tmpl` | Generalist engineer persona (backend + frontend voices); follow-existing-patterns constraint |
| Coder formula | `packs/coder/formulas/mol-code-from-spec.formula.toml` | 6-step work loop: intake → actual-adr-check → plan → implement → self-test → handoff |
| Coder order gate | `packs/coder/formulas/orders/coder-intake/order.toml` | Polls `bd ready --label=ready-to-build`; wakes the coder on match |
| Project manifest | `docs/PROJECT_MANIFEST.md` in your rig | Read by both agents on every run |
| Design artifact | `docs/designs/<slug>.md` in your rig | Wireframe + a11y audit (reference doc, not a routing signal) |
| Feature-branch commit | `git log <feature-branch> --oneline` | Coder's output: code + tests committed with a conventional-commit message referencing the bead |
| Bead notes | `bd show <bead-id>` | Where design_artifact, impl_plan, self_test, and adr_check findings live |

---

## Next Steps

After L3, four of the six agents are yours. The final lab and the capstone follow the same pattern you just practised:

- **L4** — customise the **Reviewer** (consumes `needs-review`) and the **Deployer** (consumes `ready-to-ship`). Completes the 6-agent pipeline. The reviewer reads the coder's commit and the design artifact side-by-side; make sure both are clean coming out of L3.
- **W4** — introduces the optional 7th agent, the **Improver**, which consumes `needs-improve` beads produced by the deployer.
- **L5** — the Capstone. Combine everything and run a real feature end-to-end.

The pattern — read pack → include + wire → customise prompt and formula → watch a bead walk through on labels alone → fix findings by editing config, never by hand-editing output — is the whole curriculum at this point. L2 was the first pass on *your* project; L3 is the middle of the pipeline; L4 closes it.
