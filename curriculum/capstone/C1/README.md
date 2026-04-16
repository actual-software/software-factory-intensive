# C1 · Run the Software Factory End-to-End

> **What you'll do:** Take a brand-new feature request (one you have not seen in any prior lab) and run it through all six agents of your factory — Planner → Architect → Designer → Coder → Reviewer → Deployer — driven entirely by the configuration you've built across W1–W4 and L1–L4. You will not type a single ad-hoc prompt. Every fix happens through a config edit. The deliverable is a committed feature branch, a completed Factory Run Report, and a retrospective card — even if you don't reach the Deployer in ~90 minutes.

| | |
|---|---|
| **Estimated duration** | ~90 minutes |
| **Type** | CAPSTONE |
| **Deliverable** | Factory Run Report + committed feature branch (any stage) + retrospective card (all at `activities/capstone/C1/`) |

---

## Session workspace note

Pack mapping: *Coder* → `packs/builder`, *Deployer* → `packs/release-gate`. Prompt templates are `packs/<name>/prompts/<name>.md.tmpl`. Commands use the pack names: `gc sling builder <bead>`, `gc sling release-gate <bead>`.

Before starting the run, verify all six packs are wired in `../../../my-factory/city.toml`:

```toml
includes = [
    "../packs/planner",
    "../packs/architect",
    "../packs/designer",
    "../packs/builder",
    "../packs/reviewer",
    "../packs/release-gate",
]
```

If you skipped an earlier lab, add the shipped path for that pack — the capstone still runs against the reference packs even without customisations. The run report + retrospective land at `../../../activities/capstone/C1/`.

---

## Architecture Diagram

```
                         ┌──────────────────────────────┐
                         │    Feature Request (bead)     │
                         │    — medium complexity —      │
                         └───────────────┬──────────────┘
                                         │
                                         ▼
   ┌───────────────────────────┐   ┌──────────────────┐
   │  orchestrator.yaml         │──▶│   PLANNER AGENT   │──▶ work-packages/<slug>.md
   │  (W3 coordination)         │   └────────┬─────────┘
   │                            │            │ handoff: bead --depends-on
   │  pipeline:                 │            ▼
   │    - planner               │   ┌──────────────────┐
   │    - architect             │──▶│ ARCHITECT AGENT   │──▶ docs/adr/NNNN-<slug>.md
   │    - designer              │   └────────┬─────────┘
   │    - coder                 │            │
   │    - reviewer              │            ▼
   │    - deployer              │   ┌──────────────────┐
   │                            │──▶│ DESIGNER AGENT    │──▶ design/<slug>-spec.md
   │  gates:                    │   └────────┬─────────┘
   │    - architect: human      │            │
   │    - deployer: human       │            ▼
   │                            │   ┌──────────────────┐
   └────────────┬───────────────┘──▶│   CODER AGENT     │──▶ src/... + feature branch
                │                   └────────┬─────────┘
                │                            │
                │                            ▼
                │                   ┌──────────────────┐
                │                ──▶│ REVIEWER AGENT    │──▶ review-reports/<slug>-review.md
                │                   └────────┬─────────┘
                │                            │ human gate
                │                            ▼
                │                   ┌──────────────────┐
                │                ──▶│ DEPLOYER AGENT    │──▶ release-gates/<slug>-gate.md
                │                   └────────┬─────────┘
                │                            │
                ▼                            ▼
        ┌────────────────────────────────────────────────┐
        │  feedback-loops/run-analyzer.sh (W4)            │
        │  observes runtime events, writes auto-guidance  │
        │  back into CLAUDE.md + agent prompts            │
        └────────────────────────────────────────────────┘
                                 ▲
                                 │ feeds back into every agent's next run
```

Every arrow going *down* is a handoff artifact on disk. Every arrow going *up* is a feedback signal that changes config. The factory is complete when both axes are wired and a bead entering at the top produces a release gate at the bottom without you typing into any agent session.

---

## Prerequisites

Before starting the capstone, verify each row. If any row fails, fix it *before* creating the feature bead — the capstone cannot surface useful signal if the factory is misconfigured at the start.

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L1 complete | `ls ~/path/to/your-repo/CLAUDE.md` → file exists with project context | Go back and complete L1 |
| L2 complete | `gc status` shows `planner` and `architect` as idle agents | Complete L2 (Part 1 + Part 2 install flow) |
| L3 complete | `gc status` also shows `designer` and `coder`; prior work package + ADR committed | Complete L3 |
| L4 complete | `gc status` also shows `reviewer` and `devops`; prior PR has a review report | Complete L4 |
| All 6 agents declared in `city.toml` | `grep -c '^\[\[agent\]\]' my-factory/city.toml` → returns 6 (or more if you kept `dev-agent`) | Re-run `gc rig add --include` for any missing pack |
| Project manifest is tight | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` — Review Standards and Release Criteria sections have explicit, testable rules (not "code should be clean") | Tighten before starting — vague manifests produce vague agent output |
| Orchestrator present (optional but recommended) | `cat my-factory/orchestrator.yaml` shows the 6-stage pipeline from W3 | You can run manually (slinging each stage by hand); note this in the report's "Config Discipline" row |
| At least one feedback loop encoded | `ls ~/path/to/your-repo/feedback-loops/rules/` → at least one `*.sh` rule | Go back to W4 Part 2 and write one rule |
| `CLAUDE.md` has tailored industry ADRs (optional) | `grep -i "tailored" ~/path/to/your-repo/CLAUDE.md` returns results | Run `actual adr-bot` (see L2 Part 2 Step 1) |
| `packs/workshop/` integrations installed (optional) | `gc rig list` shows the workshop pack | L1 walkthrough covers install — without it, ticket sync and observability signals are absent but the run still works |
| Clean working tree | `git status` in your project repo is clean | Commit or stash before starting |

**What "all six agents declared" means in practice.** Your `city.toml` should have a block for each agent like this (the exact shape doesn't matter, but every agent must resolve from an installed pack):

```toml
[[agent]]
name = "planner"
dir = "your-repo-name"
provider = "claude"          # other providers (codex, cursor, gemini, etc.) are also supported
idle_timeout = "1h"
role = "planner"

[[agent]]
name = "architect"
dir = "your-repo-name"
provider = "claude"          # other providers (codex, cursor, gemini, etc.) are also supported
idle_timeout = "1h"
role = "architect"

# ... and so on for designer, coder, reviewer, devops
```

---

## The Use Case (New Feature)

The capstone deliberately uses a feature you have **not** touched in L2–L4. The prior labs built a loyalty points system. The capstone is about a different area of the codebase so your factory can't rely on cached reasoning from earlier sessions.

### For Fired Up Pizza (reference project)

**Feature:** Order history page — customers view past orders by phone number.

Concretely, a customer navigates to `/orders/history`, enters their phone number, and sees a list of their past orders with items ordered, total paid, order date, and order status. This feature:

- Touches the backend (new API endpoint to look up orders by phone)
- Touches the frontend (new page + form + table)
- Requires at least one architectural decision (how to handle the phone-number lookup — indexed column? separate lookup table? rate-limited endpoint?)
- Has testable acceptance criteria (given phone X, see orders Y and Z; given unknown phone, see empty state)
- Is medium complexity — roughly the same scope as the loyalty points feature but in a different slice (read path, not write path)

### For your own project

Pick an equivalent medium-complexity feature. It should:

- Touch **both** backend and frontend (or their equivalents in your stack)
- Require at least **one architectural decision** — something the Architect will need to write an ADR about
- Have **acceptance criteria that are objectively testable** (given X, system does Y — not "the UX is nicer")
- Be **90-minute-scope** — if you have to squint at the manifest to figure out where the code lives, it's too big
- Be in a **different area of the codebase** than your L2–L4 thread — the capstone tests factory generality, not factory memory

Write the feature description as a markdown block before starting. You will paste this into the bead description in Step 1.

---

## The Rules (Config Discipline)

These three rules are the spine of the capstone. Every decision you make during the run comes back to one of these. They are not suggestions.

### Rule 1: No ad-hoc prompting.

If an agent produces wrong output — missing sections, wrong directory, vague reasoning — the fix is **always** a prompt-file edit followed by a re-sling. Never type corrections into the agent's chat. Never prefix an instruction with "also please remember to...".

**Rationale.** The factory you're running today needs to run tomorrow without you present. If a fix lives only in a chat message, it evaporates the moment the session ends. A prompt-file diff is permanent, diffable, and reviewable. That's the only form of fix that scales.

**Example violation.** The Planner's work package omits the Scope Boundary section. You notice, and in the same `gc watch planner` tmux you type "please add a Scope Boundary section." The section gets added — and the next time the Planner runs on a different bead, the scope boundary is missing again. The fix didn't stick.

**Correct move.** Open `packs/planner/prompts/planner.md.tmpl`, sharpen the Output Format or Quality Gate to require Scope Boundary explicitly, commit the change, delete the half-finished work package, re-sling the Planner.

### Rule 2: All fixes via config.

If tests fail after the Coder runs, if the Reviewer flags an issue, if the Deployer gate refuses to pass — the fix is a **prompt update**, a **manifest update**, or a **feedback-rule update**. Never a manual code edit.

**Rationale.** A manual code edit ships the fix for this feature and loses the fix for every future feature. A prompt or manifest update ships the fix into every subsequent factory run. The whole point of the factory is that corrections compound; manual edits erase that property.

**Example violation.** The Coder writes a React component that imports from `@/lib/formatPrice` but your project uses `src/utils/formatPrice`. You open the file and change the import path by hand. The code builds, the PR merges. Three features later the Coder makes the same mistake — because the fix never reached its prompt.

**Correct move.** Open `packs/builder/prompts/builder.md.tmpl`, add a rule to the Output Format: "All imports use project-relative paths from `src/` — never aliases like `@/lib/*` unless they're declared in the manifest's `tsconfig.paths`." Commit. Re-sling the Coder on the same bead.

### Rule 3: Log everything.

The Factory Run Report is not a post-mortem artifact you fill in at the end. It's a **live log**. You update it as each stage runs, each config change lands, each gate fires. At T+90 min, the report should already be 80% complete; the last 10 minutes are for the retrospective and the "What I'd do differently" rows.

**Rationale.** Memory of what happened during a 90-minute factory run decays fast. Config changes you made at T+20 min blur into the ones you made at T+45 min. If the report is your working document during the run, it captures the truth; if you write it at T+85 min from memory, it captures fiction.

**Example violation.** You finish the run, open `factory-runs/` and write "Planner took one sling, Architect took one sling, Designer took two slings." You actually re-slung the Planner twice and forgot; the "config iterations" count is wrong. When someone reads your report next month to understand what's flaky, they'll chase a phantom problem.

**Correct move.** Keep the run report open in a split pane while the factory runs. Add a row to the Pipeline Results table the moment each stage starts. Fill in the outcome the moment it ends. The "Config Changes" column is populated as you make the changes, not after.

---

## Run Sequence

Below is the full run, broken into six agent-stage sub-steps plus a pre-run setup block. Each agent stage has: duration estimate, exact command, what to watch, expected artifact, common failure modes + config fix.

### Step 0: Pre-Run Setup (~5 min)

Create the feature bead and start the live run report.

```bash
cd my-factory

# Create the capstone bead
bd create "Order history page — customers view past orders by phone number" \
  --label "capstone-feature" \
  --description "$(cat <<'EOF'
# Feature Request: Order History Page

## User Story
**As a** returning customer
**I want** to look up my past orders by phone number
**So that** I can re-order my favorites and check the status of recent orders

## Acceptance Criteria
- [ ] Customer navigates to `/orders/history` and sees a phone number input
- [ ] On submit with a phone number that has orders: list orders (newest first) with items, total, date, status
- [ ] On submit with a phone number that has no orders: show empty state with link to menu
- [ ] On submit with an invalid phone format: show validation error
- [ ] Endpoint is rate-limited to prevent phone-number enumeration

## Constraints
- Must use existing orders table (no schema migration unless ADR justifies it)
- Lookups must be O(log n) or better — add an index if needed
- UI consistent with existing order confirmation page (Tailwind, no new design tokens)

## Success Metrics
- Lookup P95 < 200ms for up to 10,000 orders
- Page loads in < 1s on a mid-tier phone
EOF
)"
```

Note the bead ID returned (e.g., `my-factory-c1a2p3`). This is the anchor for every subsequent sling.

Open the Factory Run Report template (further down in this document) in a split-pane editor. Add the feature name, date, and bead ID to the header. You will fill in the rest as the run proceeds.

If you have `orchestrator.yaml` from W3 fully wired:

```bash
gc orchestrate --pipeline feature-pipeline --bead my-factory-c1a2p3
```

This will sequentially sling each stage. You still monitor and still handle human gates. **If orchestrator is not wired, sling each stage manually below.** Note which path you took in the Config Discipline section of your report.

Also open two observability panes:

```bash
# Pane A — every city event
gc events --follow

# Pane B — active sessions
gc session list         # refresh as needed
```

### Step 1: Planner (~10 min)

**Command:**

```bash
gc sling planner my-factory-c1a2p3
gc watch planner          # Ctrl+b d to detach when you've seen it start
```

**What to watch:**

- Planner reads `docs/PROJECT_MANIFEST.md` (you'll see the file open in the session)
- Planner reads the bead description
- Planner writes `work-packages/order-history.md`
- Planner commits on a feature branch and marks the bead ready for the Architect

**Expected artifact:** `work-packages/order-history.md` with the six sections from L2's Planner pack — Goal, User Stories, Acceptance Criteria, Dependencies, Test Cases, Scope Boundary. The Acceptance Criteria should map 1:1 to the bead's AC list (or expand them).

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| Work package missing Scope Boundary | Planner prompt Output Format is ambiguous | Sharpen `packs/planner/prompts/planner.md.tmpl` Output Format; require `## Scope Boundary` verbatim; re-sling |
| Work package uses "improve UX" or "make it faster" language | Quality Gate rule on ambiguous terms isn't being enforced | Add explicit forbidden-words list to `packs/planner/prompts/planner.md.tmpl` Quality Gate |
| File written to `plan/` or `docs/plans/` instead of `work-packages/` | Output path drift | Make output path literal in the prompt: "Write to `work-packages/<feature-slug>.md` — never anywhere else" |
| Acceptance criteria are rephrases of bead criteria, not expansions | Planner isn't adding edge cases | Add Quality Gate rule: "Each AC must include a happy-path AND at least one edge case" |

Close the Planner bead when the work package passes its Quality Gate:

```bash
bd close my-factory-c1a2p3 --comment "Work package: work-packages/order-history.md"
```

### Step 2: Architect (~10 min)

**Command:**

```bash
# Create the dependent bead
bd create "ADR: Phone-number order lookup" \
  --description "$(cat <<'EOF'
Review work-packages/order-history.md. Make an architectural decision about:

- Phone-number storage and indexing (add index to existing column? normalize? hash?)
- Rate-limit strategy to prevent phone-number enumeration
- Whether the lookup endpoint is part of the existing /api/orders or a new /api/orders/lookup

Read docs/PROJECT_MANIFEST.md for tech stack constraints.
Read CLAUDE.md for tailored-ADR baselines.
Produce docs/adr/NNNN-order-history-lookup.md using MADR.
EOF
)" \
  --depends-on my-factory-c1a2p3

gc sling architect <architect-bead-id>
gc watch architect
```

**What to watch:**

- Architect reads `docs/PROJECT_MANIFEST.md`, `CLAUDE.md` (for tailored ADRs), and existing ADRs under `docs/adr/`
- Architect reads `work-packages/order-history.md`
- Architect writes `docs/adr/NNNN-order-history-lookup.md`
- Architect appends a cross-reference to the work package under an `## Architectural Decisions` heading

**Expected artifact:** An MADR-format ADR with Status, Context, Options Considered (at least 2 with trade-offs), Decision, Consequences (including at least one risk), References. The References section must cite `work-packages/order-history.md` by path.

**Human gate (if configured in `orchestrator.yaml`):** The ADR usually sits in `needs-approval` before the Designer runs. Review the decision. Approve or reject via `bd approve` / `bd reject`. Keep the approval time in the run report under Human Interventions.

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| ADR considers only 1 option | Architect prompt doesn't force comparison | Add Quality Gate: "You MUST evaluate at least 3 distinct approaches. List the naive approach and explain why rejected" |
| ADR decides something already covered in tailored ADRs | Architect isn't reading `CLAUDE.md` | Add `CLAUDE.md` to Inputs section of `packs/architect/prompts/architect.md.tmpl` (see L2 Part 2 Step 4) |
| No cross-reference appended to work package | Process step 5 missing or unclear | Make it literal in the Process: "Open the work package file and append the ADR path under `## Architectural Decisions`. Create the heading if it doesn't exist" |
| Consequences lists only positives | Quality Gate isn't requiring risk | Add rule: "Consequences must include at least one line starting with `- Risk:`" |

Close the Architect bead when the ADR passes its Quality Gate.

### Step 3: Designer (~10 min)

**Command:**

```bash
bd create "Design: Order history page + lookup endpoint" \
  --description "Produce design/order-history-spec.md from work-packages/order-history.md and docs/adr/NNNN-order-history-lookup.md. Include component tree, props, API contract, test plan." \
  --depends-on <architect-bead-id>

gc sling designer <designer-bead-id>
gc watch designer
```

**What to watch:**

- Designer reads work package + ADR + manifest
- Designer writes `design/order-history-spec.md` with: component tree (e.g., `OrderHistoryPage > PhoneLookupForm > OrderList > OrderRow`), props/types, API contract (endpoint, request shape, response shape, error shapes), test plan
- Designer cross-references both upstream artifacts

**Expected artifact:** A component spec that is specific enough that the Coder could implement it without reading the work package or ADR (but should still read them for context). Types defined, states enumerated (loading, empty, error, populated), edge cases flagged.

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| Spec has components but no types/props | Output Format doesn't require a Types section | Add required section: "### Types (TypeScript interfaces for all props + API shapes)" |
| No empty/error/loading states described | Quality Gate silent on UI states | Add rule: "Each component must enumerate states: loading, empty, error, populated (at minimum)" |
| API contract missing error shapes | Too generous Output Format | Require: "API contract must include success shape AND every error shape the endpoint can return" |
| Test plan is vague ("tests the component") | Quality Gate doesn't require specific test names | Require: "Test plan lists at least 5 test cases by name, each mapped to an AC from the work package" |

Close the Designer bead.

### Step 4: Coder (~20 min)

**Command:**

```bash
bd create "Implement: Order history page + lookup endpoint" \
  --description "Implement design/order-history-spec.md. Follow the component tree exactly. All tests from the spec's test plan must pass before marking ready." \
  --depends-on <designer-bead-id>

gc sling builder <coder-bead-id>
gc watch coder
```

**What to watch:**

- Coder reads the spec (primary input), manifest, work package, ADR (for context)
- Coder creates a feature branch like `feat/order-history`
- Coder writes backend code (`src/api/orders/lookup.ts` or similar), frontend code (`src/pages/OrderHistoryPage.tsx`, child components), and tests
- Coder runs quality gates locally: `npm run build`, `npm test`, `npm run lint`
- Coder commits and pushes the branch

**Expected artifact:** A committed feature branch with code + tests. `npm test`, `npm run build`, `npm run lint` all exit 0 when run on that branch. PR created (if `packs/workshop/` is installed) or branch pushed and noted in the bead.

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| Tests fail on the same pattern repeatedly (e.g., "Cannot read property 'map' of undefined") | This is exactly what W4 feedback loops exist for | Your feedback rule from W4 should detect this and append a "Common Pitfalls" section to `CLAUDE.md`. If it doesn't fire, the rule's detection logic is wrong — fix the rule, not the code |
| Coder writes to wrong directory (e.g., `components/` instead of `src/components/`) | Coder prompt doesn't reference manifest's Project Structure explicitly | Add to `packs/builder/prompts/builder.md.tmpl` Process: "Read `docs/PROJECT_MANIFEST.md` Project Structure section and use those paths exclusively" |
| Coder re-implements something that already exists (e.g., a `formatPhone` util) | Coder isn't scanning existing `src/utils/` | Add to Process: "Before writing any util function, grep `src/utils/` for an existing implementation" |
| Lint fails on every commit | Coder isn't running lint locally | Add to Quality Gate: "Before marking ready, run `npm run lint` and `npm test` — both must exit 0" |
| Coder commits secrets or `.env` contents | Guardrail missing | Add hard rule: "Never commit files matching `.env*`, `*.pem`, `credentials*`" |

**If the Coder stalls for 10+ minutes:** check the session with `gc session peek coder`. Most often, the spec was under-specified and the Coder is second-guessing. That's a Designer prompt issue — edit the Designer prompt to require whatever was missing, re-sling the Designer, then re-sling the Coder. Do not type instructions into the Coder's session.

Close the Coder bead when its quality gates pass.

### Step 5: Reviewer (~10 min)

**Command:**

```bash
# If packs/workshop installed, pull latest PR state first
gc workshop sync-all

bd create "Review: Order history PR" \
  --description "Review the feat/order-history PR. Use the review checklist in the reviewer prompt and the Review Standards in docs/PROJECT_MANIFEST.md. Post review as a PR comment. Also write review-reports/order-history-review.md." \
  --depends-on <coder-bead-id>

gc sling reviewer <reviewer-bead-id>
gc watch reviewer
```

**What to watch:**

- Reviewer checks out the feature branch locally (via `git fetch` or the GitHub MCP in `packs/workshop`)
- Reviewer runs local quality gates to verify the Coder's claims
- Reviewer evaluates the code against: project ADRs (`docs/adr/`), tailored ADRs (`CLAUDE.md`), manifest Review Standards
- Reviewer writes `review-reports/order-history-review.md` with severity-tagged findings
- Reviewer posts the review as a PR comment (if GitHub is wired)

**Expected artifact:** `review-reports/order-history-review.md` with a clear verdict (APPROVE / CHANGES REQUESTED / BLOCK), a severity-tagged findings list, and a checklist showing which standards passed.

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| Reviewer approves despite `npm test` failing | Reviewer isn't running gates locally | Add to Process: "Run `npm run build && npm test && npm run lint`. Verdict is BLOCK if any exit non-zero" |
| Reviewer finds 1 Low-severity issue and calls it "clean" | No severity threshold for verdict | Add to Output Format: "APPROVE requires zero High findings. CHANGES REQUESTED for any Medium+. BLOCK for any High" |
| Reviewer doesn't check tailored ADRs | Reviewer prompt doesn't list `CLAUDE.md` as input | Update checklist rule 2 to explicitly reference the Tailored ADRs section of `CLAUDE.md` (see L4's "Reviewer + the Actual AI ADR System" section) |
| Reviewer contradicts the Architect's ADR | Reviewer prompt doesn't list project ADRs as authoritative | Add to the ordering: "Project ADRs under `docs/adr/` are authoritative. If a finding contradicts an ADR, the finding is wrong unless there's a new ADR" |

If the review is CHANGES REQUESTED: do **not** manually fix the code. Update the Coder prompt with the missing guidance (or update the Designer prompt if the issue is a spec gap). Re-sling the Coder. When the Coder finishes, re-sling the Reviewer. Count each of these as a "Config Iteration" in the run report.

Close the Reviewer bead.

### Step 6: Deployer (~10 min)

**Command:**

```bash
bd create "Deploy: Order history feature" \
  --description "Evaluate release-gates for order-history. Use Release Criteria in docs/PROJECT_MANIFEST.md. Write release-gates/order-history-gate.md. If all required gates PASS, proceed with the deploy pipeline defined in the deployer prompt." \
  --depends-on <reviewer-bead-id>

gc sling devops <deployer-bead-id>
gc watch devops
```

**What to watch:**

- Deployer reads the review report and the manifest's Release Criteria
- Deployer runs each required gate (tests, lint, mergeable check, review verdict) and records pass/fail
- Deployer writes `release-gates/order-history-gate.md` with the gate table
- If all Required gates PASS, deployer executes the deploy script (may be a no-op for MVP — `npm run build` + a staging copy is fine)
- Deployer updates `CHANGELOG.md`, creates/updates runbook if relevant

**Expected artifact:** `release-gates/order-history-gate.md` with every Required gate and its status. If the feature reached production: URL + health check result. If the manifest says "no external deploy target — local staging only," the gate document is the deploy.

**Human gate (if configured):** Production deploy typically requires human approval. Review the gate document. Approve or reject.

**Common failure modes + config fix:**

| Symptom | Root cause | Config fix |
|---------|-----------|-----------|
| Deployer marks all gates PASS without actually running them | Process doesn't require evidence | Add: "For each gate, show the command run and the exit code. Screenshot-level evidence in the gate document" |
| Vague release criteria ("code is clean") produce vague gate results | Manifest issue, not prompt issue | Tighten `docs/PROJECT_MANIFEST.md` Release Criteria — this is the L4 lesson applied |
| Deployer proceeds with Reviewer verdict CHANGES REQUESTED | Deployer isn't reading review report | Add to Process: "Read `review-reports/<slug>-review.md` FIRST. If verdict ≠ APPROVE, write gate document with BLOCK status and stop" |
| No CHANGELOG entry | Deployer prompt doesn't require it | Add to Process step: "Append an entry to `CHANGELOG.md` under `## Unreleased`" |

Close the Deployer bead.

### Step 7: Close the Run (~5 min)

Regardless of how far you got:

```bash
# Commit the run report + retrospective
cd ~/path/to/your-repo
git checkout main || git checkout -    # back to whichever branch you've been on
git add factory-runs/capstone-<date>-order-history.md
git add retrospectives/capstone-<date>.md
git commit -m "docs(capstone): factory run report + retrospective for order history"
git push
```

If you didn't reach the Deployer, **that's fine**. The report and retrospective still ship. Note which stages completed and which didn't. Partial completion is a successful capstone — see the inline insight "Why Partial Completion Still Teaches You What You Need" below.

---

## Factory Run Report Template

Create `factory-runs/capstone-<date>-<feature-slug>.md`. Update it continuously during the run, not at the end (Rule 3).

```markdown
# Factory Run Report — Capstone

## Feature
Order history page — customers view past orders by phone number

**Date:** 2026-04-22
**Bead ID:** my-factory-c1a2p3
**Branch:** feat/order-history
**Report status:** COMPLETE | PARTIAL | ABANDONED

---

## Pipeline Results

| Stage | Agent | Status | Artifact | Runs | Config Changes |
|-------|-------|--------|----------|------|----------------|
| Plan | planner | PASS | work-packages/order-history.md | 1 | — |
| Architect | architect | PASS | docs/adr/0002-order-history-lookup.md | 2 | Added CLAUDE.md to Inputs (was missing tailored-ADR baseline); re-slung |
| Design | designer | PASS | design/order-history-spec.md | 1 | — |
| Code | coder | PASS | feat/order-history (src/pages/OrderHistoryPage.tsx + src/api/orders/lookup.ts + tests) | 2 | Added import-path rule to coder prompt after first run used `@/lib` aliases that don't exist in manifest |
| Review | reviewer | PASS | review-reports/order-history-review.md | 1 | — |
| Deploy | deployer | PARTIAL | release-gates/order-history-gate.md | 1 | Gate passed; no external staging target in manifest; local `npm run build` is the deploy |

**Totals:** 6/6 stages executed, 4/6 first-try passes, 2 config iterations.

---

## Quality Gates (from Reviewer + Deployer)

| Gate | Status | Evidence |
|------|--------|----------|
| Build | PASS | `npm run build` exit 0 |
| Lint | PASS | `npm run lint` exit 0 (0 warnings) |
| Tests | PASS | `npm test` exit 0, 11/11 passing |
| Test coverage | INFO | 82% line coverage (manifest requires no minimum; informational) |
| Review verdict | APPROVE | review-reports/order-history-review.md §Verdict |
| Branch mergeable | PASS | no conflicts with main |
| Manifest Release Criteria | PASS | all 6 required criteria PASS in release-gates/order-history-gate.md |

---

## Artifacts Produced

- [x] Work package: `work-packages/order-history.md`
- [x] ADR: `docs/adr/0002-order-history-lookup.md`
- [x] Design spec: `design/order-history-spec.md`
- [x] Feature branch: `feat/order-history` (12 commits)
- [x] Review report: `review-reports/order-history-review.md`
- [x] Release gate: `release-gates/order-history-gate.md`
- [x] CHANGELOG entry: `CHANGELOG.md` §Unreleased
- [x] This run report
- [x] Retrospective card: `retrospectives/capstone-2026-04-22.md`

Every upstream artifact is referenced by every downstream artifact — verified by `grep -l order-history` across the repo.

---

## Ad-Hoc Prompts Used

0. Zero ad-hoc prompts typed into any agent session.

(If non-zero, list each and why it was needed — then write the prompt-file rule that will prevent this next time.)

---

## Feedback Rules Triggered

1. **None fired during this run.** The W4 `test-failure-array-check.sh` rule would have fired on a "Cannot read property X of undefined" pattern, but all tests passed first try.

(If any fired, cite the rule file, the commit hash of the auto-update, and the resulting `CLAUDE.md` diff.)

---

## Human Interventions

| When | Why | Action Taken | Duration |
|------|-----|--------------|----------|
| T+15min | Architect ADR human gate | Reviewed 3 options (index on phone column / normalized lookup table / hashed phone column). Approved option 1. | 4 min |
| T+75min | Deployer pre-deploy gate | Reviewed release-gates/order-history-gate.md. All required criteria PASS. Approved. | 2 min |

**Total human time: 6 min out of 90 min** — human time was gate decisions, not debugging.

---

## Config Discipline

- Ad-hoc prompts used: 0
- Manual code edits: 0
- Manual edits to agent-produced artifacts (work package, ADR, spec, etc.): 0
- Config iterations (prompt/manifest/feedback-rule edits): 2
- Orchestrator mode: `gc orchestrate --pipeline feature-pipeline` (not manual)

**Config changes committed during the run:**
- `chore(architect): add CLAUDE.md to Inputs section` — commit abc123
- `chore(coder): require manifest-declared import paths only` — commit def456

---

## What Went Well

1. The Designer spec was detailed enough that the Coder needed one iteration to produce passing code. This was a direct outcome of tightening the Designer Quality Gate in L3.
2. The Architect's ADR correctly deferred to the tailored ADR for rate limiting — confirming that `CLAUDE.md` baselines prevent re-deriving decisions already covered.
3. The Reviewer caught no Highs on a first review, meaning the factory's upstream stages are producing code that meets the manifest's Review Standards without the Reviewer acting as safety net.

## What Didn't Go Well

1. The Architect missed `CLAUDE.md` on the first run — the prompt had the tailored-ADR awareness **almost** right but not literally. Cost: one extra sling (~5 min).
2. The Coder used non-existent `@/lib` path aliases, caught by a test failure, not by the Reviewer. Add a feedback rule: "if build fails with module-not-found, append import-path rule to coder prompt."

## Lessons Learned (carry into daily use)

1. **Every agent prompt's Inputs list must be literal file paths.** "Tailored-ADR baselines" was too vague; "Read `CLAUDE.md`, specifically the `# Tailored ADRs` section" works.
2. **Build errors that should be caught upstream aren't feedback failures — they're config gaps.** Add rules only for recurring runtime issues; fix upstream prompts for things that should never reach the Coder.

---

## Next Steps

- [ ] Promote the import-path rule into a tailored ADR (it's now triggering in real runs — upgrade it from Coder-prompt to ADR)
- [ ] Wire the build-failure → coder-prompt feedback rule (new W4-style rule)
- [ ] Refresh tailored ADRs with `actual adr-bot` — the phone-number-validation decision from this run is worth capturing as a pattern

---

**Factory Status:** Production-ready for features of this complexity. Needs more runs on write-path features before relying on it for everything.
```

---

## Retrospective Card

Create `retrospectives/capstone-<date>.md`. Short, committed alongside the run report.

```markdown
# Capstone Retrospective

**Run:** Order history page
**Date:** 2026-04-22

- **Keep:** The Designer-spec-first discipline. When the spec is detailed, the
  Coder is fast and the Reviewer finds little. When the spec is vague, the
  Coder is slow and the Reviewer finds everything.

- **Change:** I still think of `CLAUDE.md` as documentation. It's not — it's a
  runtime input every agent reads. Next run, I'll treat `CLAUDE.md` as
  first-class config and grep every agent prompt for it the way I grep for
  manifest references.

- **Question:** When a feedback rule and a tailored ADR conflict (e.g., the
  rule wants to relax a constraint the ADR enforces), what's the right
  escalation path? W4 said "escalate via bead" — in practice that bead sits
  for days. Need a faster signal than another bead.
```

Additional worked examples for inspiration:

### Worked example A — A run that stalled at the Coder

```markdown
- **Keep:** Re-slinging the Designer when the Coder stalled instead of fixing
  the Coder directly. That upstream fix caught a second bug the Coder hadn't
  reached yet.
- **Change:** I kept the Coder session open while editing the Designer prompt.
  The Coder session had stale context once the spec changed. Close the session
  before editing upstream prompts, then re-sling cleanly.
- **Question:** Is there a way to invalidate an agent's in-flight session when
  an upstream artifact changes? Manually killing tmux feels wrong.
```

### Worked example B — A run that shipped but with config debt

```markdown
- **Keep:** Shipping a partial run and being honest about it in the report.
  Partial with an accurate report > complete with a fictional report.
- **Change:** I let three prompt-file diffs pile up uncommitted to "fix them
  all together at the end." Two of them conflicted when I went to commit.
  Commit each prompt diff the moment it's made.
- **Question:** How long should a factory-runs/ history grow before I start
  archiving? A year of reports is useful; five years is noise.
```

---

## Reference: What a Successful Capstone Directory Looks Like

After a complete capstone run on the reference project, the directory state should resemble this:

```
reference-project/fired-up-pizza/
  work-packages/order-history.md                        ← Planner output
  docs/adr/0002-order-history-lookup.md                 ← Architect output
  design/order-history-spec.md                          ← Designer output
  src/pages/OrderHistoryPage.tsx                        ← Coder output
  src/components/PhoneLookupForm.tsx                    ← Coder output
  src/components/OrderHistoryList.tsx                   ← Coder output
  src/api/orders/lookup.ts                              ← Coder output
  src/api/orders/__tests__/lookup.test.ts               ← Coder output
  src/pages/__tests__/OrderHistoryPage.test.tsx        ← Coder output
  review-reports/order-history-review.md                ← Reviewer output
  release-gates/order-history-gate.md                   ← Deployer output
  CHANGELOG.md                                          ← Deployer updated
  factory-runs/capstone-2026-04-22-order-history.md     ← Your report
  retrospectives/capstone-2026-04-22.md                 ← Your retrospective
```

Each downstream file references each upstream file by path. Run this to verify the reference chain:

```bash
# Every upstream artifact should be mentioned by name in every downstream artifact
cd ~/path/to/your-repo
grep -rl "order-history" work-packages/ docs/adr/ design/ review-reports/ release-gates/ factory-runs/
```

You should see every artifact listed. If any directory has no reference to order-history, that stage didn't run or its output is miswired.

**Contrast with the loyalty thread from L2–L4.** The loyalty run lives in the same directory structure but with different filenames (`loyalty-points-system.md`, `0001-loyalty-points-storage.md`, etc.). Both threads coexist. Over time your factory-runs/ directory will accumulate one run report per feature, each linking to the seven artifacts that belong to it. This is the factory's running history.

---

## Gas City Commands You'll Actually Use

This is the first session where you exercise Gas City's full orchestration surface, not just `gc sling` one agent at a time.

| Command | What it does | Used when |
|---------|--------------|-----------|
| `gc orchestrate --pipeline feature-pipeline --bead <id>` | Kick off the full pipeline from `orchestrator.yaml` | Start of run, if orchestrator is wired |
| `gc sling <agent> <bead>` | Manually dispatch one stage | Manual mode, or re-slinging after config fix |
| `bd list --status needs-approval` | Poll for human-gate beads | Between stages, to catch pending gates |
| `bd approve <bead> --comment "..."` | Release a human gate | ADR approval, pre-deploy approval |
| `bd reject <bead> --comment "..."` | Reject + send back upstream | When a gate artifact isn't good enough to approve |
| `bd event list --since 1h` | Inspect feedback signals | During run, to see what's been logged |
| `gc events --follow` | Stream every city-level event | Continuously in a side pane |
| `gc session list` | See all running agent sessions | Spot stuck sessions |
| `gc session peek <agent>` | Snapshot an agent's session without attaching | When you suspect a stall but don't want to Ctrl+C |
| `gc workshop sync-all` | Pull fresh tickets/PR state | Before Reviewer, if packs/workshop installed |

If your orchestrator isn't wired, you can still run the capstone **manually sequenced** — sling each stage by hand after the previous bead closes. Note this choice in the Factory Run Report under "Config Discipline — Orchestrator mode."

---

## Inline Insight: Why the Capstone Has a Different Feature From L2–L4

L2 through L4 used the loyalty points thread. That thread taught you the primitives — how a work package becomes an ADR, how an ADR becomes a spec, how a spec becomes code. But because you watched each stage iteratively, it's easy to leave the labs with a factory that works on *the loyalty feature* and not for *arbitrary features*.

The capstone feature deliberately lives in a different slice of the codebase. Order history is a **read-path feature** (lookups, indexing, pagination) where loyalty points was a **write-path feature** (mutations, ledgers, consistency). If your factory runs cleanly on both, you've validated that the configuration generalizes. If it stumbles, the stumble location tells you exactly which agent's prompt has a write-path-only assumption baked in.

This is the single most important test of the week. Factories that only work on one feature type are just elaborate prompts. Factories that work on two or more are actual factories.

---

## Inline Insight: Why Partial Completion Still Teaches You What You Need

You might not reach the Deployer in 90 minutes. This is not a failure condition — it's the most common outcome on a first capstone run, and the Run Report is calibrated to reward it.

The value of the capstone is in the *signal you generate*, not the *stages you complete*. A run that stalls at the Coder because the Designer spec was under-specified tells you more about your factory than a run that ships to production on luck. The stall point is the exact coordinate of the weakest link.

Commit what you have. If you finished Planner + Architect + Designer and the Coder is still thrashing at T+85, close the Coder session, write the report with `Code: PARTIAL`, note why it stalled in the "What Didn't Go Well" section, and commit. The retrospective card's "Change" bullet should be the fix for the stall point. Next week you run again; the stall moves downstream. Three runs in, you'll be hitting Deployer reliably.

The only wrong outcome is an uncommitted run. Uncommitted runs erase themselves from memory within 48 hours.

---

## Inline Insight: Config Iteration Is a First-Class Activity

New participants often describe the capstone to themselves as "watching the factory run." That framing is subtly wrong. You are not a spectator — you are the **config engineer** for a process that happens to be running. Your job during the 90 minutes is to:

1. Notice when an agent produces output that doesn't meet its Quality Gate
2. Identify which config artifact (prompt, manifest, feedback rule) owns the gap
3. Edit that artifact
4. Commit the edit with a message that explains the cause
5. Re-sling the affected stage

A capstone run that required zero config iterations is suspicious. It either means your factory is genuinely production-grade (rare after four labs) or that you didn't look hard enough at the output. A capstone run that required 8+ config iterations is also suspicious — that's likely one or two upstream prompts producing garbage that you're patching at every downstream stage; fix the upstream prompt instead.

The healthy band is **1-4 config iterations** for a 90-minute run. Each iteration should be committed as a `chore(<agent>): ...` message so the diff is reviewable. Your Factory Run Report's "Config Changes" column shows these, and your retrospective's Keep/Change bullets often come directly from them.

---

## Inline Insight: How the Run Report Compounds

Each completed run report adds a row to your factory's implicit metrics table. After six runs you will see things that are invisible after one:

- **Stages-to-passing trends.** Are you getting faster? If the Planner consistently takes 1 sling and the Coder consistently takes 2, you know exactly where to invest your next hour of config work.
- **Config-iteration distribution.** Which agent's prompt is accumulating the most post-run edits? That agent is under-specified relative to the others.
- **Feedback-rule hit rates.** If no rule has fired in 4 runs, either your rules are too narrow or your factory is too clean. Usually the former.

Keep a rolling `factory-runs/metrics.md` as a table with one row per run. Each run's report links to the row. Over time this is the truest picture of your factory's health.

---

## Pipeline Stall Playbook

A "stall" is 10+ minutes of no session activity or a stage producing output that immediately fails its own Quality Gate. Here is the pattern for each of the six stages.

### Stall at Planner

**Symptoms.** Work package is missing sections, uses vague language, writes to the wrong directory, or the Planner says "I need more information" and halts.

**Root cause 85% of the time.** The bead description is too thin. You fed the Planner three sentences of feature intent and no acceptance criteria.

**Config fix.** Open the bead description (or the source ticket the bead came from) and tighten it. If the Planner is halting for clarification on every run, add a rule to `packs/planner/prompts/planner.md.tmpl` Process: "If acceptance criteria are absent from the bead, write your own best-guess AC list and mark the work package as `Status: draft — AC needs human review`." This converts halting into progress-with-a-flag.

### Stall at Architect

**Symptoms.** ADR considers only 1 option, rehashes a decision already in `CLAUDE.md`, or treats a non-decision as a multi-option analysis (the button-color-ADR problem from L2 Scenario 2).

**Root cause.** Quality Gate isn't forcing option count, or Inputs doesn't include `CLAUDE.md`, or no decision threshold tells the Architect when *not* to write an ADR.

**Config fix.** Add to `packs/architect/prompts/architect.md.tmpl`: "Only write an ADR if the decision affects more than one file OR has long-term consequences OR contradicts a tailored ADR. For cosmetic or single-file changes, write a one-line note in the work package and close the bead." Then the minimum-3-options rule for cases that do pass this threshold.

### Stall at Designer

**Symptoms.** Spec missing types, missing UI states, missing API error shapes, or just a rephrasing of the work package.

**Root cause.** Designer prompt's Output Format is checklist-vague. It says "include component design" when it should say "include a `### Types` section, a `### States` section, a `### API Contract` section with every error shape."

**Config fix.** Convert the Output Format from bullets to a literal template. The Designer writes what you template; if you don't template it, they don't write it.

### Stall at Coder

**Symptoms.** Tests failing repeatedly on the same pattern, code written to wrong paths, imports breaking, or the Coder getting stuck in a "fix one test → break another" loop.

**Root cause, 70% of stalls.** Upstream spec gap. The Coder can't implement what the Designer didn't specify.

**Config fix.** Don't edit the Coder prompt. Edit the **Designer** prompt to require whatever is missing. Re-sling Designer, then Coder. If after one Designer-spec iteration the Coder is still stuck, then and only then edit the Coder prompt — usually to add a project-convention rule (import paths, utility re-use, naming).

**Root cause, 30% of stalls.** A recurring runtime error pattern (null refs, array-undefined, unhandled promise rejections). That's a feedback-rule job — let the W4 rule fire, auto-append to `CLAUDE.md`, and re-sling the Coder. If no rule exists for the pattern, write one before fixing the code manually.

### Stall at Reviewer

**Symptoms.** Reviewer approves garbage, rejects clean code, or produces a review with no severity tags.

**Root cause.** Review Standards in the manifest are vague. The Reviewer reflects the manifest.

**Config fix.** Tighten `docs/PROJECT_MANIFEST.md` Review Standards — replace "code should be clean" with specific, testable rules (no inline styles, no `any`, components < 200 lines, etc.). The Reviewer will sharpen automatically because the manifest is its primary input.

If the Reviewer over-approves, add a severity-threshold rule to the reviewer prompt: "APPROVE requires zero High findings. CHANGES REQUESTED for any Medium+. BLOCK for any High."

### Stall at Deployer

**Symptoms.** Gate document is vague, gates are marked PASS without evidence, deploy proceeds despite review CHANGES REQUESTED, or the Deployer halts because Release Criteria are unclear.

**Root cause.** Release Criteria in the manifest are vague OR the Deployer prompt's Process doesn't enforce evidence-per-gate.

**Config fix.** Tighten `docs/PROJECT_MANIFEST.md` Release Criteria to a numbered list of objectively testable conditions (see reference manifest's 6-item Required list). Then add to the Deployer prompt: "For each Required criterion, show the command run and exit code in the gate document. A criterion with no evidence is automatically FAIL."

For the deploy-despite-changes-requested case: make the Deployer prompt's Process step 1 be "Read `review-reports/<slug>-review.md`. If verdict is not APPROVE, write a gate document with status BLOCK and exit." Make it literally the first step.

---

## Common Issues & Solutions

A compact reference for what tends to go wrong across the whole factory during a real run. When you hit one of these, look up the fix here, apply it, re-sling, and log it in the run report.

### 1. Agent gets stuck with no activity for 10+ min

Check the session: `gc session peek <agent>`. If the session is alive but idle, it's usually waiting on a clarification it's been taught not to ask for. Kill the session (`gc session kill <agent>`), tighten the upstream artifact or prompt, re-sling.

### 2. Same quality-gate failure recurs across features

This is the signal a W4 feedback rule should be catching. If no rule exists, write one now. If a rule exists but isn't firing, its detection pattern is wrong — check the regex/grep against actual log lines.

### 3. Wrong stage runs before its dependency

Check `bd show <bead-id>` for the `depends_on` chain. If the chain is missing, the bead was created without `--depends-on`. Close the wrong-ordered work, recreate the bead with the dependency, re-sling from the correct stage.

### 4. Orchestrator fails to advance to next stage

`gc orchestrate` reads `orchestrator.yaml`. If a stage doesn't advance, one of: (a) previous stage's bead wasn't closed, (b) `orchestrator.yaml` has a typo in the agent name, (c) a human gate is pending. Run `bd list --status needs-approval` to check for pending gates.

### 5. `gc sling` returns "agent not found"

Agent isn't loaded. Run `gc rig list` to confirm the pack is installed. Re-run `gc rig add --include /absolute/path/to/pack` if missing. Run `gc restart`.

### 6. Artifact written to wrong path

Output-path drift. Every prompt's Output Format line must have the literal path, not a description. Change "write the work package to an appropriate directory" to "write to `work-packages/<feature-slug>.md` — never anywhere else."

### 7. Cross-references missing between artifacts

L2 Step 6 pattern: the downstream agent's prompt must explicitly include a Process step that opens the upstream artifact and appends a back-reference. If the Architect isn't back-linking to the work package, it's a Process step, not a Quality Gate — add the step.

### 8. Deployer passes gates but feature doesn't work in staging

The gates are wrong, not the code. The manifest's Release Criteria is missing a condition that matters (e.g., "endpoint returns 200 on smoke test"). Add the condition to the manifest, re-sling the Deployer, and note in the run report that the gate coverage was inadequate.

### 9. `CLAUDE.md` is growing monotonically from feedback rules

Feedback rules add but don't decay. Per W4 safety review: every auto-generated section in `CLAUDE.md` needs a "last triggered" timestamp comment. Anything not triggered in 90 days is auto-commented-out for review. If you don't have the decay rule, write it before `CLAUDE.md` becomes noise.

### 10. Reviewer contradicts Architect

Two possible causes: (a) the Architect's ADR is wrong and should be updated, or (b) the Reviewer prompt doesn't treat ADRs as authoritative. Check the ADR first; if the ADR is right, add to the Reviewer prompt: "Project ADRs under `docs/adr/` are authoritative. A finding that contradicts an ADR is only valid if accompanied by a proposed new ADR."

### 11. Tailored ADRs conflict with a new ADR the Architect wrote

The Architect is extending or overriding a baseline — which is allowed by L2's Part 2 Step 4 pattern, but must be explicit. Check that the new ADR has a "Relationship to tailored ADR X" section. If not, that section is missing from the Architect prompt's MADR template — add it and re-sling.

### 12. Factory stalls because a prompt-file edit has a syntax error

Prompts aren't compiled, so "syntax" means markdown or whitespace. Most common: indentation of a list item in the Quality Gate section that makes the model misinterpret what's required vs. optional. Always re-read your own edits as if the agent were reading them. If an edit introduces ambiguity, fix the edit — don't layer another edit on top.

---

## Exit Criteria

You pass the capstone when all of these are true. Check them off as you go.

- [ ] **Feature bead created** with explicit acceptance criteria and constraints (not a one-line description)
- [ ] **At least one downstream artifact committed** — work package, ADR, spec, code, review, or gate. (A factory that produces only a work package still produced something, and that partial state goes in the report.)
- [ ] **Zero ad-hoc prompts typed into any agent session** during the run
- [ ] **Zero manual code edits** during the run (manual edits to *prompts*, *manifest*, and *feedback rules* are encouraged; manual edits to agent-produced *artifacts* are not)
- [ ] **Factory Run Report completed and committed** — even if the report says `PARTIAL` and the Deploy row is blank. Commit what you have before stopping.
- [ ] **Retrospective card written and committed** alongside the run report — Keep / Change / Question
- [ ] **Feature branch present on the remote** (any stage — branch after Coder is ideal, branch after Planner is still valid)

If all seven are checked, you've passed. If the Deploy row is blank, you've still passed — partial runs are first-class outcomes.

---

## Test Scenarios (Optional — If You Finish Early)

If you complete the primary run before T+90, try one of these stress tests. Each one exercises a different axis of factory generality.

### Scenario A: Run on a deliberately under-specified feature

Create a bead with a terse description: "Add CSV export to the reports page." No AC, no constraints.

**Expected:** The Planner should either refuse (if your Quality Gate forbids ambiguous bead descriptions) or produce a work package that writes its own best-guess AC and flags them. What you're checking: does your factory degrade gracefully under thin inputs, or does it hallucinate?

### Scenario B: Run on a feature that tests your tailored-ADR enforcement

Pick a feature that deliberately tempts a pattern forbidden by a tailored ADR in `CLAUDE.md`. For example, if a tailored ADR requires parameterized queries: create a bead like "Add admin SQL report builder."

**Expected:** The Architect should catch the conflict with the tailored ADR and write a *conflict-resolution* ADR, not a vanilla one. The Reviewer should reference the tailored ADR in its findings. If neither agent notices the conflict, your tailored-ADR inputs aren't being read — tighten the Inputs sections of both prompts.

### Scenario C: Run on a refactor-only bead

Create a bead: "Refactor src/api/orders/*.ts to extract shared validation." No user-facing feature.

**Expected:** The Planner should recognize this is a non-feature work package (no user stories) and adapt its output. Some Planner prompts handle this gracefully; others produce nonsensical "As a developer I want..." stories. This test reveals whether your Planner's Output Format has a fallback for non-feature work.

---

## What Comes After C1

The capstone ends here. Your factory continues. Below are the habits that separate factories that *scale* from factories that *atrophy*.

### Immediately (this week)

1. **Commit everything** — prompts, manifest updates, feedback rules, the run report, the retrospective. Push to your team's default branch. The diff from L4-to-C1 is the most valuable artifact of the whole intensive.
2. **Archive the full run log** — `gc events --dump --since 2h > factory-runs/capstone-<date>-events.log` captures every event for later inspection.
3. **Update the DECISIONS.md** — append an L-series-style entry summarizing what changed and why, so the next agent/person reading the repo sees the full arc.

### Next week

1. **Run the factory on a real backlog ticket.** Don't pick a toy feature. Pick the next thing your team actually needs. The smoothness of the real-ticket run tells you whether the factory is ready for daily work.
2. **Refine based on capstone learnings.** Whatever stalled most in the capstone is now your highest-leverage config target. Fix that one thing before running again.
3. **Add one feedback rule per new failure pattern** you observe. Keep the catalog small and specific; noisy rules create noise, not learning.

### Next month

1. **Measure velocity.** Roll up `factory-runs/metrics.md` into a simple dashboard: average config iterations per stage, average human gate time, percentage of runs reaching the Deployer. Three data points are enough to see direction.
2. **Expand the factory.** Specialized agents — security, performance, docs, data — follow the exact same pattern as the core six. Each is a pack: prompt file + pack.toml + overlay. The mechanics you've already mastered.
3. **Re-run `actual adr-bot` on a weekly cron.** Tailored-ADR baselines drift as the codebase changes; the wiki reference to a weekly order in `my-factory/orders/adr-refresh/order.toml` captures this as a Gas City scheduled agent.

### Ongoing habits

- **Promote recurring feedback rules into ADRs.** A rule that fires 5+ times/month is no longer a pitfall — it's a principle. Move the guidance from the auto-generated `CLAUDE.md` section into a new `docs/adr/NNNN-*.md`, remove the rule, note the promotion in `DECISIONS.md`.
- **Keep run reports short and committed.** A run report that's 200 lines is unread noise. 40-80 lines, linked to the commits and artifacts that matter, compounds beautifully across dozens of runs.
- **Audit the `git log --grep="feedback:"` weekly.** Bad feedback rules silently poison the factory; the only cure is weekly review of what they've been auto-committing.
- **Treat prompt files like source code.** They go through PR review. They have owners. They get refactored. When a prompt hits ~200 lines, split it: extract shared sections (like "Config Discipline" or standard commit conventions) into a shared include file that all packs reference.

### Building a composite pack for your team

If you've made it through the capstone, you've installed six packs individually. The next time a teammate joins, they shouldn't have to install six — they should install one composite that pulls in all six. The reference project ships `packs/fired-up-pizza/pack.toml` as a 20-line composite bundle. The shape is:

```toml
[pack]
name = "fired-up-pizza-factory"
schema = 1
description = "Composite: all six factory agents for Fired Up Pizza"

includes = [
  "../planner",
  "../architect",
  "../designer",
  "../builder",
  "../reviewer",
  "../release-gate",
]
```

After the capstone, build the equivalent for your own factory:

```bash
mkdir -p packs/team-factory
# Write packs/team-factory/pack.toml using the shape above,
# listing the six leaf packs under includes.
```

Then the next teammate bootstraps with a single include in their `my-factory/city.toml`:

```toml
includes = ["../packs/team-factory"]
```

One command instead of six. This is how your factory becomes shareable.

---

## Command Cheat Sheet

Every command you might use during the capstone, grouped by purpose.

```bash
# ----- Pre-run setup -----
cd my-factory
bd create "Order history page — customers view past orders by phone number" \
  --label "capstone-feature" \
  --description "$(cat <<'EOF'
...feature request with AC + constraints + success metrics...
EOF
)"
# note the bead ID that comes back

# ----- Orchestrator mode (if orchestrator.yaml is wired) -----
gc orchestrate --pipeline feature-pipeline --bead <bead-id>

# ----- Manual mode (if running stage-by-stage) -----
gc sling planner       <bead-id>
gc sling architect     <architect-bead-id>
gc sling designer      <designer-bead-id>
gc sling builder       <builder-bead-id>
gc sling reviewer      <reviewer-bead-id>
gc sling release-gate  <release-gate-bead-id>

# ----- Each sling pairs with one of these to observe -----
gc watch <agent>               # stream that agent's session
gc session peek <agent>        # snapshot without attaching
gc session list                # all active sessions
gc events --follow             # every city event in real time

# ----- Bead management -----
bd list                                   # everything
bd list --status open                     # active work
bd list --status needs-approval           # pending human gates
bd show <bead-id>                         # one bead's detail + dependency chain
bd create "..." --depends-on <bead-id>    # dependent bead
bd close <bead-id> --comment "..."        # mark done
bd approve <bead-id> --comment "..."      # release human gate
bd reject <bead-id> --comment "..."       # reject, send back upstream
bd event list --since 1h                  # feedback-signal audit

# ----- Workshop pack (if installed) -----
gc workshop sync-all          # pull fresh ticket + PR state
gc workshop status            # integration connectivity check

# ----- Artifact inspection during the run -----
cat work-packages/order-history.md
cat docs/adr/*-order-history-*.md
cat design/order-history-spec.md
git log --oneline feat/order-history
git diff main...feat/order-history
cat review-reports/order-history-review.md
cat release-gates/order-history-gate.md

# ----- Config-iteration workflow (when a stage fails) -----
# 1. Identify the prompt that owns the failing behavior
# 2. Edit the prompt (packs/<agent>/prompts/<agent>.md)
# 3. Commit with chore(<agent>): message
# 4. Delete the bad artifact
# 5. Re-sling

# ----- Close the run -----
git add factory-runs/capstone-<date>-<slug>.md retrospectives/capstone-<date>.md
git commit -m "docs(capstone): factory run report + retrospective"
git push

# ----- Full run log dump (optional, for metrics) -----
gc events --dump --since 2h > factory-runs/capstone-<date>-events.log
```

---

## Quick Reference: The 6 Agents + Their Artifacts

| Stage | Agent | Primary Input | Output Artifact | Quality Gate Source |
|-------|-------|---------------|------------------|--------------------|
| 1 | Planner | Bead description + manifest | `work-packages/<slug>.md` | `packs/planner/prompts/planner.md.tmpl` |
| 2 | Architect | Work package + manifest + `CLAUDE.md` + existing ADRs | `docs/adr/NNNN-<slug>.md` | `packs/architect/prompts/architect.md.tmpl` |
| 3 | Designer | Work package + ADR + manifest | `design/<slug>-spec.md` | `packs/designer/prompts/designer.md.tmpl` |
| 4 | Coder | Design spec + manifest + `CLAUDE.md` | Feature branch under `src/` + tests | `packs/builder/prompts/builder.md.tmpl` + manifest build gates |
| 5 | Reviewer | Code diff + spec + manifest Review Standards + `CLAUDE.md` | `review-reports/<slug>-review.md` + PR comment | `packs/reviewer/prompts/reviewer.md.tmpl` + manifest |
| 6 | Deployer | Review report + manifest Release Criteria | `release-gates/<slug>-gate.md` + (if passes) deploy | `packs/release-gate/prompts/release-gate.md.tmpl` + manifest |

### Capstone deliverables

| Deliverable | File | Status check |
|-------------|------|--------------|
| Feature bead with explicit AC | `bd show <bead-id>` | Description has AC + constraints + success metrics |
| At least one downstream artifact | `work-packages/` and beyond | At minimum, Planner output committed |
| Factory Run Report | `factory-runs/capstone-<date>-<slug>.md` | All sections present; partial completion noted honestly |
| Retrospective card | `retrospectives/capstone-<date>.md` | Keep / Change / Question all populated |
| Feature branch on remote | `git branch -r | grep <slug>` | Branch pushed; any stage counts |
| Zero ad-hoc prompts | Self-attested in report | Config Discipline row: "Ad-hoc prompts used: 0" |
| Zero manual code edits | `git log --author=<you>` on feature branch | All commits are from agents or are `chore(<agent>): ...` prompt edits |

When every row on both tables resolves, your factory works end-to-end on a feature it has never seen. That's the whole intensive, in one run.

---

## Quality Bar

When you review your own capstone output, check each of these:

- **Stage traceability** — Every artifact references every upstream artifact by path. `grep -rl "<feature-slug>"` across the repo returns every stage's file.
- **Config-first fixes** — Every fix landed as a commit to a prompt, manifest, or feedback-rule file. No commits directly edit agent-produced artifacts.
- **Quality Gate honesty** — Each gate in the run report matches the command you actually ran, with an exit code or equivalent evidence. "PASS (by inspection)" is not evidence; "PASS (`npm test` exit 0)" is.
- **Retrospective specificity** — Keep / Change / Question bullets are concrete. "Keep: shipping faster" is vague; "Keep: re-slinging the Designer when the Coder stalls" is actionable.
- **Partial completion owned** — If the run was partial, the report says so in the header (`Report status: PARTIAL`), the missing stages are listed as "not reached" (not "PASS"), and the retrospective explains why.

---

## Troubleshooting Quick Table

One-line fixes for the top issues you're likely to hit during the run. These are the same patterns surfaced in the Pipeline Stall Playbook and Common Issues sections, compressed into a grep-friendly table.

| Symptom | One-line fix |
|---------|-------------|
| `gc sling` "agent not found" | `gc rig list`; re-run `gc rig add --include /abs/path/to/pack`; `gc restart` |
| Planner produces output with vague language | Add forbidden-words list to `packs/planner/prompts/planner.md.tmpl` Quality Gate; re-sling |
| Architect writes 1-option ADR | Add "minimum 3 options" rule to `packs/architect/prompts/architect.md.tmpl`; re-sling |
| Designer spec has no types | Convert Output Format to literal template with `### Types` required; re-sling |
| Coder uses wrong import paths | Add manifest-declared-paths-only rule to `packs/builder/prompts/builder.md.tmpl`; re-sling |
| Reviewer over-approves | Add severity-threshold-for-verdict rule to `packs/reviewer/prompts/reviewer.md.tmpl`; re-sling |
| Deployer marks gates PASS without evidence | Add "show command + exit code per gate" rule to `packs/release-gate/prompts/release-gate.md.tmpl`; re-sling |
| Cross-references missing between artifacts | Add explicit Process step to downstream prompt: "Open upstream artifact and append back-reference"; re-sling downstream |
| Orchestrator doesn't advance | Check `bd list --status needs-approval`; check previous bead closed; check orchestrator.yaml agent names |
| Feedback rule not firing | Check detection regex against actual log lines with `bd event list --since 1h` |
| Session idle for 10+ min | `gc session peek <agent>` to inspect; kill with `gc session kill <agent>`; fix upstream prompt; re-sling |
| Build fails on branch the Coder pushed | Coder prompt is missing "run `npm run build && npm test && npm run lint` before marking ready"; add and re-sling |

---

## Final Note

The capstone is not a milestone — it's a baseline. After you run it today, you should be able to run it again next week on a different feature and spend less time. Three months from now, the same run should take 20 minutes of human attention instead of 90. Six months from now, your factory should be running end-to-end on tickets while you're asleep, and the first sign of a problem is a bead sitting in `needs-approval` when you wake up.

If your factory is getting faster per run, you're doing this right. If it's getting slower, the config is drifting faster than it's adapting — audit your feedback rules, prune the ones that don't fire, and tighten the manifest.

That's the whole discipline: **config over prompting, artifacts as handoffs, config discipline as the scaling axis.** The capstone is the first place you prove it. Every run after is the evidence.
