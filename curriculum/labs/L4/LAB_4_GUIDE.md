# L4 · Deploy Reviewer + Deployer Agents

> **Goal:** Complete your software factory by adding its final two specialists, and practice the central discipline of the curriculum: improving quality by refining the instructions your agents follow rather than the work they produce.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Reviewer + Release-Gate agents, one `review-reports/<slug>-review.md`, one `release-gates/<slug>-gate.md`, and at least one finding resolved via a Builder prompt edit (never a manual code change) |

---

## Session workspace note

Pack renames since this README was first written: **Coder → `builder`** and **Deployer → `release-gate`** (same roles, same outputs, new pack directories). Prompt template paths are `packs/builder/prompts/builder.md.tmpl` and `packs/release-gate/prompts/release-gate.md.tmpl`. Commands `gc sling builder` and `gc sling release-gate` replace their `coder` / `deployer` equivalents.

**Where your work goes this session:**
* Session deliverables → `../../../activities/labs/L4/` (the activity folder for L4)
* Customised pack copies → `../../../activities/labs/L4/packs/<agent>/`
* Wire packs into `../../../my-factory/city.toml` — `includes = [..., "../packs/reviewer", "../packs/release-gate"]` (shipped) or `../activities/labs/L4/packs/<agent>` (customised). See [`activities/labs/L4/README.md`](../../../activities/labs/L4/README.md) for exact lines.

If a prompt edit breaks the pack, swap `includes` back to the shipped `../packs/<name>` path and `gc service restart` — the shipped pack always passes `gc doctor`.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. This is the strictest session for config discipline: **review findings are fixed by editing the Builder prompt, never by editing code**. An agent reading this README should start by opening `my-factory/PROJECT_MANIFEST.md` — especially the Review Standards and Release Criteria sections — since the Reviewer and Release-Gate agents read those as their rubric.

---

## Architecture Diagram

```
                    ┌───────────────────────────┐
                    │     Coder Output (L3)       │
                    │  src/<feature>/*            │
                    │  tests/<feature>/*          │
                    │  (on feature branch)        │
                    └─────────────┬─────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────┐
                    │      REVIEWER AGENT        │
                    │                            │
                    │  Reads:                     │
                    │    • code diff on branch    │
                    │    • design/<slug>-spec.md  │
                    │    • work-packages/<slug>   │
                    │    • PROJECT_MANIFEST       │
                    │      (Review Standards)     │
                    │                            │
                    │  Produces:                  │
                    │    review-reports/          │
                    │      <slug>-review.md       │───► Summary, Spec Compliance,
                    │                            │     Style + Security findings,
                    └─────────────┬─────────────┘     Test Coverage, Recommendation
                                  │
                                  │   If REQUEST_CHANGES:
                                  │   ◂────── edit packs/builder/prompts/builder.md.tmpl
                                  │           re-sling coder, re-sling reviewer
                                  │
                                  │   If APPROVE:
                                  ▼
                    ┌───────────────────────────┐
                    │      DEPLOYER AGENT        │
                    │                            │
                    │  Reads:                     │
                    │    • review-reports/<slug>  │
                    │    • work-packages/<slug>   │
                    │    • feature branch code    │
                    │    • PROJECT_MANIFEST       │
                    │      (Release Criteria)     │
                    │                            │
                    │  Produces:                  │
                    │    release-gates/           │
                    │      <slug>-gate.md         │───► Binary PASS/FAIL per
                    │                            │     criterion with evidence,
                    └───────────────────────────┘     Release Notes, References
```

Both the Reviewer and the Deployer are driven by `orchestrator.yaml` — not by ad-hoc `gc sling` commands. The orchestrator is the automation layer that converts a Coder-completed bead into a Reviewer bead, and a Reviewer-approved bead into a Deployer bead. You will still use manual `gc sling` commands in this lab to exercise each agent directly, but the exit criteria require that the orchestrator drive both stages.

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L3 complete | `ls ~/path/to/your-repo/design/` and `ls ~/path/to/your-repo/src/` show the loyalty-points feature files | Go back and complete L3. The Reviewer needs a spec and implementation to review. |
| Designer + Coder agents working | `gc status` shows `designer` and `coder` as `idle` | Re-run the L3 installs with `gc rig add --include packs/designer` and `gc rig add --include packs/builder`. |
| All 4 prior packs installed | `gc rig list` shows `planner`, `architect`, `designer`, `coder` on your rig | Re-run `gc rig add --include` for each missing pack from L2 and L3. |
| Feature branch present | `git branch --show-current` in your repo shows `l3-designer-coder` (or your L3 branch) with the Coder's commits on it | Check out the branch produced in L3 before slinging the Reviewer. |
| Work package + spec exist | `ls work-packages/loyalty-points-system.md design/loyalty-points-system-spec.md` → both exist | Complete the Planner and Designer steps from L2 and L3 first. |
| PROJECT_MANIFEST has Review + Release sections | `grep -E "Review Standards\|Release Criteria" docs/PROJECT_MANIFEST.md` → both headings present | Copy the templates from [`curriculum/PROJECT_MANIFEST_TEMPLATE.md`](../../PROJECT_MANIFEST_TEMPLATE.md) and fill them in before slinging. |

If any row fails, stop and fix it. L4 is the thinnest lab in terms of new Gas City mechanics (you already know `gc rig add --include`, `gc sling`, and `bd create`), but it is the most demanding in terms of upstream artifact quality. A vague Review Standards section produces vague review findings. A vague Release Criteria section produces meaningless gate records.

---

## The Running Example

We continue the Loyalty Points System feature from L2 and L3. By now you have:

- `work-packages/loyalty-points-system.md` — Planner's output, with acceptance criteria and test cases
- `docs/adr/0001-loyalty-points-storage.md` — Architect's decision (separate `points_ledger` table)
- `design/loyalty-points-system-spec.md` — Designer's component spec
- `src/services/loyaltyPoints.ts`, `src/api/loyalty.ts`, and `tests/loyalty.test.ts` — Coder's implementation

In L4 the Reviewer reads all of this plus the diff on the feature branch, and the Deployer reads the review report plus the branch state. If you are working against your own project, substitute your own feature — but make sure the Coder has actually produced code files and at least one passing test. The Reviewer produces nothing useful if there is no code to review.

---

## Part 0: Read the Shipped Packs (5 min)

> **Goal:** Inspect the final two specialists you are about to install, so you begin configuration with a clear understanding of how they evaluate and gate the work your factory has already produced.

Before installing anything, read the two pack files. You will edit them later in this lab, so build the mental model now.

### Step 1: Open the Reviewer Pack Prompt

Open this file in your editor and read it end-to-end — it's under 70 lines:

[`packs/reviewer/prompts/reviewer.md`](../../../packs/reviewer/prompts/reviewer.md)

You should see the same six-section structure you saw in L2 (Planner) and L3 (Designer, Coder):

```
# Reviewer Agent

## Role              ← "You review code produced by the Coder against
                        the component spec, work package acceptance
                        criteria, and the project's review policy."

## Inputs            ← code diff + design/<slug>-spec.md +
                        work-packages/<slug>.md + the Review Standards
                        section of PROJECT_MANIFEST.md

## Output Format     ← review-reports/<slug>-review.md with 6 blocks:
                        Summary (PASS/FAIL), Spec Compliance table,
                        Style Findings, Security Findings, Test Coverage,
                        Recommendation (APPROVE or REQUEST_CHANGES)

## Quality Gate      ← 4 rules: every spec element is checked, security
                        review covers injection/auth/data-exposure, every
                        test case has a PASS/FAIL, recommendation is
                        actionable

## Process           ← 8 steps, ending with: "If REQUEST_CHANGES: add
                        findings as comments on the bead and route back
                        to Coder"

## Config Discipline ← "If your review criteria need to change, the fix
                        is updating this file or the manifest's Review
                        Standards section — not ad-hoc re-prompting."
```

**What's happening here:** The Reviewer's entire personality is in this prompt plus the `Review Standards` section of `docs/PROJECT_MANIFEST.md`. The Output Format section is particularly important — it specifies the exact shape of `review-reports/<slug>-review.md`, which the Deployer then reads as its primary input. If the Reviewer writes free-form prose instead of the structured tables, the Deployer cannot parse it. The contract is the format.

### Step 2: Open the Reviewer Pack Metadata

[`packs/reviewer/pack.toml`](../../../packs/reviewer/pack.toml)

```toml
[pack]
name = "reviewer"
schema = 1
description = "Reviewer agent — automated code review against specs and policy"

[[agent]]
name = "reviewer"
scope = "rig"
prompt_template = "prompts/reviewer.md"
overlay_dir = "overlays/default"
nudge = "Check your hook for code ready for review."
idle_timeout = "1h"
max_active_sessions = 1
```

**What's happening here:** Same pattern as every other agent pack. `scope = "rig"` means the Reviewer runs inside the rig directory (your project repo), which is required because it needs to run `git diff`, read `src/`, and execute tests. The `nudge` is what the orchestrator-triggered hook message will look like when the Reviewer wakes up to process a queue of beads.

### Step 3: Open the Deployer Pack Prompt

[`packs/release-gate/prompts/release-gate.md.tmpl`](../../../packs/release-gate/prompts/release-gate.md.tmpl)

Same six-section structure, different role:

```
## Role              ← "You evaluate whether a reviewed feature meets
                        all release criteria and produce a release gate
                        checklist with binary PASS/FAIL evidence."

## Inputs            ← review-reports/<slug>-review.md +
                        work-packages/<slug>.md + feature branch code +
                        Release Criteria section of PROJECT_MANIFEST.md

## Output Format     ← release-gates/<slug>-gate.md with:
                        Overall Verdict (PASS/FAIL),
                        a Criteria table with 6 default rows
                        (each row: #, Criterion, Result, Evidence),
                        Release Notes, References

## Quality Gate      ← 3 rules: every criterion has binary PASS/FAIL with
                        evidence (not opinions), overall verdict matches
                        (FAIL if any fails), release notes are user-facing

## Process           ← 7 steps ending with: "If PASS: the feature is
                        deployment-ready — mark bead closed. If FAIL:
                        route back with specific criteria that failed."

## Config Discipline ← "If your gate criteria need to change, the fix is
                        updating this file or the manifest's Release
                        Criteria section — not ad-hoc re-prompting."
```

Notice the key phrase in the Quality Gate: **"evidence (not opinions)"**. This is the contract that makes the Deployer useful in an autonomous loop. A result of `PASS — looks good` is not evidence. A result of `PASS — npm test reports 14/14 passing (see tests/loyalty.test.ts output)` is evidence. The downstream release process can trust evidence. It cannot trust opinions.

### Step 4: Open the Deployer Pack Metadata

[`packs/release-gate/pack.toml`](../../../packs/release-gate/pack.toml)

```toml
[pack]
name = "deployer"
schema = 1
description = "Deployer agent — release gate evaluation and deployment prep"

[[agent]]
name = "deployer"
scope = "rig"
prompt_template = "prompts/deployer.md"
overlay_dir = "overlays/default"
nudge = "Check your hook for reviewed code ready for release evaluation."
idle_timeout = "1h"
max_active_sessions = 1
```

Identical shape to the Reviewer pack, differing only in `name`, `description`, `prompt_template`, and `nudge`. You're done reading. Now install.

---

## Part 1: Install the Packs (10 min)

> **Goal:** Bring the last two specialists of your factory online, preparing the ground for an end-to-end pipeline that can evaluate its own output.

### Step 1: Add the Reviewer Pack to Your Rig

```bash
cd my-factory
gc rig add ~/path/to/your-repo \
  --include /path/to/software-factory-intensive/packs/reviewer
```

You should see:

```
rig "your-repo" updated — added pack "reviewer"
```

### Step 2: Add the Deployer Pack to Your Rig

```bash
gc rig add ~/path/to/your-repo \
  --include /path/to/software-factory-intensive/packs/release-gate
```

You should see:

```
rig "your-repo" updated — added pack "deployer"
```

### Step 3: Restart and Verify

```bash
gc restart
gc status
```

You should see all 6 agents:

```
NAME        STATE   LAST ACTIVITY   BEAD
dev-agent   idle    2h ago          --
planner     idle    1h ago          --
architect   idle    1h ago          --
designer    idle    30m ago         --
coder       idle    10m ago         --
reviewer    idle    --              --
deployer    idle    --              --
```

(Seven rows counting `dev-agent`. The factory agents are the last six: `planner`, `architect`, `designer`, `coder`, `reviewer`, `deployer`. If your project uses a different name in `city.toml` for the deployer — e.g. `devops` — keep using whatever name is in your file; the pack declaration is what matters.)

### Step 4: Run the Doctor

```bash
gc doctor
```

You should see something like:

```
Checking tmux ................... OK
Checking rig paths .............. OK
Checking pack configs ........... OK (6 packs loaded)
Checking GitHub credentials ..... OK
Checking hooks .................. OK
```

If `pack configs` is below 6, re-run the `gc rig add --include` commands — one of them silently no-op'd on a wrong path. Absolute paths only.

### Step 5: List the Rig's Packs

```bash
gc rig list
```

You should see all six factory packs plus any workshop/integration packs you installed earlier:

```
RIG                  PACKS
your-repo            planner, architect, designer, coder, reviewer, deployer
```

If you don't see `reviewer` or `deployer` here, the pack didn't register. Check that `pack.toml` is present in the pack directory and that you passed the directory path (not the `pack.toml` path) to `--include`.

---

## Part 2: Declare Agents in city.toml (5 min)

> **Goal:** Wire the new specialists into your factory so that they can be invoked alongside every specialist you have installed in prior labs.

`gc rig add --include` registers the pack's `[[agent]]` block for you automatically, but many participants prefer to also declare the agents explicitly in their city's `city.toml` so they can tune `idle_timeout` and override the role name per project. If you skip this step the pack defaults apply — still fine for the lab.

### Step 1: Add the Reviewer Agent Block

Open `my-factory/city.toml` and add:

```toml
[[agent]]
name = "reviewer"
dir = "your-repo-name"
provider = "claude"          # other providers (codex, cursor, gemini, etc.) are also supported
idle_timeout = "1h"
role = "reviewer"
```

### Step 2: Add the Deployer Agent Block

Below that, add:

```toml
[[agent]]
name = "deployer"
dir = "your-repo-name"
provider = "claude"          # other providers (codex, cursor, gemini, etc.) are also supported
idle_timeout = "2h"
role = "deployer"
```

The Deployer gets a longer `idle_timeout` because gate evaluation plus release-note generation can run longer than review on a large change.

### Step 3: Restart and Verify Again

```bash
gc restart
gc status
```

All six factory agents should still be listed and idle:

```
NAME        STATE   LAST ACTIVITY   BEAD
dev-agent   idle    2h ago          --
planner     idle    1h ago          --
architect   idle    1h ago          --
designer    idle    30m ago         --
coder       idle    10m ago         --
reviewer    idle    --              --
deployer    idle    --              --
```

### Step 4: Commit the city.toml Change

```bash
cd my-factory
git add city.toml
git commit -m "chore(city): declare reviewer + deployer agents"
```

(If your city isn't a git repo, skip the commit — the config is local-only.)

---

## Part 3: Sling to the Reviewer (15 min)

> **Goal:** Subject your factory's implementation to the Reviewer's scrutiny, and evaluate whether the resulting feedback is specific enough to guide meaningful improvements.

> **Agent Guide:** Before the participant slings, ask: "Which criteria in your Review Standards matter most for this feature? What should the Reviewer catch that a linter can't?" Naming those out loud anchors what "a good review" means for this bead. Also: do not let the participant sling the Reviewer without a Builder artifact — the Reviewer has no contract without the Coder's output.

### Step 1: Create the Reviewer Bead

```bash
cd my-factory
bd create "Review: Loyalty Points PR" \
  --description "$(cat <<'EOF'
Review the Coder's implementation of the loyalty points system.

Feature branch: l3-designer-coder

Inputs for your review:
- Work package: work-packages/loyalty-points-system.md
- Design spec: design/loyalty-points-system-spec.md
- ADR: docs/adr/0001-loyalty-points-storage.md
- Review Standards: docs/PROJECT_MANIFEST.md (Review Standards section)

Produce the review report at review-reports/loyalty-points-system-review.md
using the Output Format from your prompt. Every spec element must appear
in the Spec Compliance table. Every test case must have a PASS/FAIL.

If REQUEST_CHANGES: for each finding, specify which Coder prompt change
would prevent the issue going forward.
EOF
)" \
  --depends-on [coder-bead-id]
```

Replace `[coder-bead-id]` with the bead ID you closed at the end of L3. You should see:

```
Created bead: my-factory-r1r2r3
```

Note this ID — you will use it in the next few steps.

### Step 2: Sling the Bead to the Reviewer

```bash
gc sling reviewer my-factory-r1r2r3
```

You should see:

```
Slinging my-factory-r1r2r3 → reviewer
Session started: reviewer-r1r2r3 (tmux)
```

**What's happening here:** Gas City starts a tmux session, launches Claude Code inside your project directory, loads `packs/reviewer/prompts/reviewer.md` as the system prompt, and hands the bead's description as the task. The Reviewer begins reading the spec, work package, and branch diff.

### Step 3: Watch the Reviewer Work

```bash
gc watch reviewer
```

The Reviewer should:

1. Read `docs/PROJECT_MANIFEST.md` (specifically the Review Standards section)
2. Read `work-packages/loyalty-points-system.md` and `design/loyalty-points-system-spec.md`
3. Run `git diff main...HEAD` on the feature branch to see the Coder's changes
4. Inspect each file referenced by the spec's Location field
5. Run `npm test` (or your project's test command) to verify the test cases
6. Write `review-reports/loyalty-points-system-review.md`
7. Commit on the feature branch

Press `Ctrl+b d` to detach from tmux (the agent keeps running). You can also monitor from another terminal:

```bash
gc session peek reviewer      # snapshot of the current session
gc events --follow            # stream of city events
bd show my-factory-r1r2r3        # bead progress
```

Wait until the Reviewer returns to `idle` in `gc status`. This typically takes 3–8 minutes depending on the size of the Coder's diff.

### Step 4: Examine the Review Report

> **Agent Guide:** Ask the participant: "What's the highest-severity finding?" Don't move on until they can state it in one sentence. Then — before any fix — have them confirm out loud: "I will fix this by editing `packs/builder/prompts/builder.md.tmpl`. I will not touch the code." This verbal checkpoint is where most participants break discipline; catching it before the fix starts is easier than rolling back after.

```bash
cd ~/path/to/your-repo
cat review-reports/loyalty-points-system-review.md
```

You should see something structurally similar to this (content varies — this is an illustrative example):

```markdown
# Review Report: Loyalty Points System

## Summary
REQUEST_CHANGES — spec is mostly implemented but three findings require
resolution before release. See recommendations for specific Coder prompt
edits that would prevent recurrence.

## Spec Compliance
| Spec Element | Implemented? | Notes |
|-------------|-------------|-------|
| PointsLedger table (see ADR-0001) | Yes | Migration at db/migrations/003_points_ledger.sql |
| earnPoints(orderId, amountCents) | Yes | src/services/loyaltyPoints.ts:12 |
| redeemPoints(userId, points) | Yes | src/services/loyaltyPoints.ts:45 |
| getBalance(userId) | Partial | Returns raw SUM — spec requires clamped ≥0 |
| GET /api/loyalty/balance endpoint | Yes | src/api/loyalty.ts:18 |
| POST /api/loyalty/redeem endpoint | Yes | src/api/loyalty.ts:34 |
| Refund handling via negative ledger entry | No | Not implemented — ADR-0001 calls for this |

## Style Findings
- [ ] (low) src/services/loyaltyPoints.ts:22 — magic number `100` for points-per-dollar should be a named constant POINTS_PER_DOLLAR in src/services/constants.ts
- [ ] (low) src/api/loyalty.ts:18 — handler lacks explicit return type annotation; project convention (PROJECT_MANIFEST §conventions) requires explicit types on exported functions

## Security Findings
- [ ] (medium) src/api/loyalty.ts:34 — redeem endpoint does not verify the authenticated user matches the userId in the request body. An attacker could redeem another user's points by passing their userId.
- [ ] (high) src/services/loyaltyPoints.ts:45 — redeem path does not wrap the balance-read and ledger-write in a transaction. Two concurrent redeem calls can both read balance=100, both succeed, and leave balance=-100. Violates ADR-0001's "balance must be accurate (no double-counting)" constraint.

## Test Coverage
- Test case 1 (earn points on $12.99 order → +12 points): PASS
- Test case 2 (redeem 100 points → $5 discount applied): PASS
- Test case 3 (refund reverses earned points): FAIL — no refund path implemented
- Test case 4 (getBalance on user with no orders → 0): PASS
- Test case 5 (concurrent redeem of same balance): MISSING — no test for this in tests/loyalty.test.ts

## Recommendation
REQUEST_CHANGES. To resolve:

1. **High: concurrent redeem race** — Update packs/builder/prompts/builder.md.tmpl
   Quality Gate to require: "Any code path that both reads and mutates a
   shared balance MUST wrap the read-and-write in a single transaction.
   Use db.transaction() from better-sqlite3."

2. **Medium: redeem auth bypass** — Update packs/builder/prompts/builder.md.tmpl
   Rules section to require: "Every endpoint that takes a userId parameter
   MUST verify req.user.id === req.body.userId (or equivalent). If the
   spec does not specify auth behavior, assume the authenticated user is
   the only valid actor."

3. **High: missing refund handling** — This is a spec gap, not a Coder
   gap. The Designer's spec should include a refundOrder path. File
   design gap separately or re-sling the Designer with this note.

4. **Low findings** — Both are fixed by a single Coder prompt update:
   "Named constants must be declared in src/services/constants.ts. All
   exported functions must have explicit return type annotations."

## References
- work-packages/loyalty-points-system.md
- design/loyalty-points-system-spec.md
- docs/adr/0001-loyalty-points-storage.md
```

### Step 5: Check the Review Report Against the Quality Gate

Open `packs/reviewer/prompts/reviewer.md` and verify each Quality Gate rule:

| Quality Gate Rule | Pass? | Evidence |
|-------------------|-------|----------|
| Every spec element is checked | Yes / No | Count rows in Spec Compliance vs. spec's element list |
| Security review covers injection, auth, data exposure | Yes / No | Are all three domains addressed in Security Findings? |
| Each test case has PASS/FAIL | Yes / No | Count test cases in Test Coverage |
| Recommendation is actionable | Yes / No | Does each finding specify the exact config edit that would fix it? |

If any rule fails: **do not edit the review report by hand.** Edit `packs/reviewer/prompts/reviewer.md` to close the gap, delete the report, and re-sling the Reviewer.

---

## Part 4: Fix Via Config (Critical Step — ~20 min)

> **Goal:** Resolve the Reviewer's findings by refining the instructions of the specialists responsible, practicing the core discipline of improving your factory rather than improving any single output.

> **Agent Guide:** This is the strictest enforcement of the entire curriculum. The instant the participant opens the Coder's output files to hand-fix a finding, stop them, roll the edit back, and redirect them to `packs/builder/prompts/builder.md.tmpl`. No exceptions. If they argue "just this once," that's exactly the habit the workshop is trying to break.

This is the crux of L4. The Reviewer has produced findings. A developer's instinct is to open the Coder's output files and fix them directly. **Do not do this.** The whole point of a factory is that improvements persist as agent config, not as one-off manual edits. If you hand-fix the code today, the next feature will have the same bug tomorrow.

The discipline is:

1. For each reviewer finding, identify what the Coder should have done differently.
2. Edit `packs/builder/prompts/builder.md.tmpl` to make that behavior the Coder's default.
3. Re-sling the Coder against the same bead. The Coder regenerates the code with the updated prompt.
4. Re-sling the Reviewer against the same review bead. Verify the finding is gone.

Walk through two detailed scenarios below.

### Scenario A: High-Severity Security Finding (Transaction Wrapping)

The Reviewer flagged this finding:

> (high) src/services/loyaltyPoints.ts:45 — redeem path does not wrap the balance-read and ledger-write in a transaction. Two concurrent redeem calls can both read balance=100, both succeed, and leave balance=-100.

#### Step 1: Open the Coder Prompt

```bash
$EDITOR packs/builder/prompts/builder.md.tmpl
```

Current Quality Gate section:

```markdown
## Quality Gate

Code is complete when:
1. Every prop/input from the spec is implemented
2. Every interaction from the spec works
3. Edge cases (empty, error, loading) are handled
4. At least 2 test cases from the work package pass
5. Code passes lint (`npm run lint` or equivalent)
```

#### Step 2: Add the New Rule

Append a new item to the Quality Gate. Below is the diff:

```diff
 ## Quality Gate

 Code is complete when:
 1. Every prop/input from the spec is implemented
 2. Every interaction from the spec works
 3. Edge cases (empty, error, loading) are handled
 4. At least 2 test cases from the work package pass
 5. Code passes lint (`npm run lint` or equivalent)
+6. Any code path that both reads and mutates a shared balance, counter,
+   or other concurrent-access resource MUST wrap the read-and-write in a
+   single database transaction. Use `db.transaction(...)` from
+   better-sqlite3 (or the equivalent in your project's stack). A matching
+   concurrency test case must exist in tests/ asserting that two
+   interleaved calls cannot produce a negative balance or double spend.
```

Save and close.

#### Step 3: Commit the Prompt Change

```bash
cd ~/path/to/your-repo
git add packs/builder/prompts/builder.md.tmpl
git commit -m "chore(coder): require transaction wrapping for balance mutations"
```

#### Step 4: Re-Sling the Coder

```bash
cd my-factory
gc sling builder [coder-bead-id-from-L3]
gc watch coder
```

The Coder rereads its updated prompt, sees the new Quality Gate rule, and updates `src/services/loyaltyPoints.ts` to wrap the redeem path in `db.transaction(...)`. It also adds a concurrency test case to `tests/loyalty.test.ts`. Wait until the Coder returns to `idle`.

#### Step 5: Re-Sling the Reviewer

```bash
gc sling reviewer my-factory-r1r2r3
gc watch reviewer
```

The Reviewer regenerates the review report. The transaction-wrapping finding should no longer appear in Security Findings, and the new concurrency test case should now appear in Test Coverage with a PASS.

Verify:

```bash
cd ~/path/to/your-repo
grep -i "transaction\|concurrent" review-reports/loyalty-points-system-review.md
```

You should see a PASS line for the concurrency test and no open high-severity finding about transactions.

### Scenario B: Medium-Severity Auth Bypass

The Reviewer also flagged:

> (medium) src/api/loyalty.ts:34 — redeem endpoint does not verify the authenticated user matches the userId in the request body.

#### Step 1: Add a Rule to the Coder's Rules Section

Current Rules section:

```markdown
## Rules

- Follow the spec exactly. If the spec is wrong, note it but implement as written.
- Never modify files outside the scope of your bead's feature.
- If you need a dependency, add it via package manager and document in the commit.
- All code changes must be on a feature branch, never directly on main.
```

#### Step 2: Apply This Diff

```diff
 ## Rules

 - Follow the spec exactly. If the spec is wrong, note it but implement as written.
 - Never modify files outside the scope of your bead's feature.
 - If you need a dependency, add it via package manager and document in the commit.
 - All code changes must be on a feature branch, never directly on main.
+- Every API endpoint that accepts a `userId` parameter (in path, query,
+  or body) MUST verify that the authenticated user matches. If the spec
+  does not specify auth behavior, assume the authenticated user is the
+  only valid actor and return 403 otherwise. Document the check with an
+  inline comment referencing this rule.
```

Save.

#### Step 3: Commit, Re-Sling Coder, Re-Sling Reviewer

```bash
cd ~/path/to/your-repo
git add packs/builder/prompts/builder.md.tmpl
git commit -m "chore(coder): require auth check on userId endpoints"

cd my-factory
gc sling builder [coder-bead-id]
gc watch coder

gc sling reviewer my-factory-r1r2r3
gc watch reviewer
```

After the re-sling, `src/api/loyalty.ts` contains an explicit `if (req.user.id !== req.body.userId) return res.status(403)` check and the Reviewer's Security Findings no longer contains the bypass finding.

### Why This Matters

Every finding you resolve via config is a systemic improvement — the next feature the Coder writes will already have the transaction-wrapping rule and the auth-check rule baked in. Every finding you resolve via a hand-edit is a one-off — the next feature will re-introduce the bug. The orchestrator runs indefinitely; hand-edits do not accumulate into a better factory. Config edits do.

**Minimum to pass the exit criteria:** at least one review finding must be resolved by editing `packs/builder/prompts/builder.md.tmpl` (or the Designer's spec when the gap is upstream of the Coder). Zero manual code edits in response to review findings.

---

## Part 5: Sling to the Deployer (10 min)

> **Goal:** Submit the reviewed work for final evaluation, and confirm that your factory can make a release decision grounded in criteria declared in advance rather than improvised in the moment.

> **Agent Guide:** Before slinging, ask the participant to read their release criteria aloud. Every criterion should be testable — produce PASS/FAIL evidence, not an opinion. "Code is clean" fails this test; "`npm run lint` exits 0" passes. If any criterion is opinion-based, that's a prompt gap in the manifest's Release Criteria section — fix it before slinging.

Once the review report returns `APPROVE` (or returns `REQUEST_CHANGES` with only findings you've deliberately deferred and documented), the feature is ready for release gate evaluation.

### Step 1: Create the Deployer Bead

```bash
cd my-factory
bd create "Release Gate: Loyalty Points" \
  --description "$(cat <<'EOF'
Evaluate release criteria for the loyalty points feature.

Feature branch: l3-designer-coder

Inputs for your evaluation:
- Review report: review-reports/loyalty-points-system-review.md
- Work package: work-packages/loyalty-points-system.md
- Release Criteria: docs/PROJECT_MANIFEST.md (Release Criteria section)

Produce the gate checklist at release-gates/loyalty-points-system-gate.md
using the Output Format from your prompt. Every criterion must have a
binary PASS/FAIL with explicit evidence — no opinions, no "looks good".

If PASS: mark this bead closed. The feature is deployment-ready.
If FAIL: list which criteria failed and what would have to change.
EOF
)" \
  --depends-on my-factory-r1r2r3
```

You should see:

```
Created bead: my-factory-d1d2d3
```

### Step 2: Sling the Bead to the Deployer

```bash
gc sling release-gate my-factory-d1d2d3
```

(If you renamed the agent to something else in `city.toml` — e.g. `devops` or `deployer` — use `gc sling <your-name> my-factory-d1d2d3`. The shipped pack in this lab declares the agent as `release-gate`; the agent name in your city is whatever you declared.)

You should see:

```
Slinging my-factory-d1d2d3 → deployer
Session started: deployer-d1d2d3 (tmux)
```

### Step 3: Watch the Deployer Work

```bash
gc watch deployer
```

The Deployer should:

1. Read `docs/PROJECT_MANIFEST.md` (Release Criteria section)
2. Read `review-reports/loyalty-points-system-review.md`
3. Read `work-packages/loyalty-points-system.md` for acceptance criteria
4. Run `npm test` to confirm test state
5. Run `git status` on the feature branch to check for untracked files
6. Run `git merge-base` or `git merge --no-commit --no-ff` dry run to check for merge conflicts with main
7. Write `release-gates/loyalty-points-system-gate.md`
8. Commit on the feature branch

Wait until the Deployer returns to `idle`. This typically takes 2–5 minutes.

### Step 4: Examine the Release Gate Record

> **Agent Guide:** Check every row: does each criterion have PASS/FAIL with evidence (command output, test results, artifact paths), or does it read like an opinion? Any "looks good" verdict is a prompt gap in the Release-Gate template — fix it before the session ends. A gate whose output is opinions is not a gate.

```bash
cd ~/path/to/your-repo
cat release-gates/loyalty-points-system-gate.md
```

You should see something like (illustrative — your project's Release Criteria determine the exact rows):

```markdown
# Release Gate: Loyalty Points System

## Overall Verdict
PASS

## Criteria

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | All acceptance criteria met | PASS | 4 of 4 ACs from work-packages/loyalty-points-system.md verified: earn points on purchase, view balance, redeem at checkout, prevent double-count via transaction |
| 2 | Review report approved | PASS | review-reports/loyalty-points-system-review.md: Summary line "APPROVE — all findings resolved via Coder prompt updates" |
| 3 | No high-severity findings open | PASS | 0 high-severity findings open in review-reports/loyalty-points-system-review.md (2 were resolved in commits 7a3b4c5 and 9d2e1f8) |
| 4 | Tests pass | PASS | `npm test` reports 17/17 passing on commit HEAD=f4e5d6c (see tests/loyalty.test.ts). Coverage 87% on src/services/loyaltyPoints.ts |
| 5 | No untracked files in feature scope | PASS | `git status` shows working tree clean on branch l3-designer-coder |
| 6 | Feature branch is clean | PASS | `git merge --no-commit --no-ff main` dry run: no conflicts; 12 files changed, 0 deleted |

## Release Notes
Customers now earn 1 loyalty point for every dollar spent at checkout, and
can redeem 100 points for a $5 discount on any future order. Point balances
are visible on the order confirmation page. Refunds automatically reverse
earned points via the points ledger. Admins can view total points issued
and redeemed in the admin dashboard under /admin/loyalty.

## References
- work-packages/loyalty-points-system.md
- review-reports/loyalty-points-system-review.md
- docs/adr/0001-loyalty-points-storage.md
```

### Step 5: Verify the Quality Gate

| Quality Gate Rule | Pass? | Evidence |
|-------------------|-------|----------|
| Every criterion has binary PASS/FAIL with evidence | Yes / No | Scan the Result column for words other than `PASS` or `FAIL` |
| Overall verdict matches individual criteria | Yes / No | If any row is FAIL and Overall Verdict says PASS, that's a Quality Gate violation |
| Release notes are present and user-facing | Yes / No | Is the paragraph about what users get — not about implementation details like `points_ledger` table? |

**If Overall Verdict says PASS but a row says FAIL:** update the Deployer prompt's Quality Gate to enforce verdict consistency, delete the gate file, and re-sling. This is a config fix, never a hand edit.

**If a row is `PASS — LGTM`:** the Deployer is emitting opinions instead of evidence. Add a Quality Gate rule: "Every Result entry MUST include a concrete artifact reference — file path, git commit SHA, command output line, or numeric count. Strings like 'looks good', 'LGTM', 'ok', 'fine' are never acceptable." Re-sling.

### Step 6: Close the Deployer Bead

```bash
cd my-factory
bd close my-factory-d1d2d3 --comment "Release gate PASS. Feature deployment-ready."
```

---

## Part 6: Reviewer + the Actual AI ADR System

> **Goal:** Understand how the Reviewer's findings connect to the broader system of recorded decisions that guides your factory, so quality improvements accumulate as durable knowledge rather than one-time corrections.

If you seeded tailored ADRs via `actual adr-bot` in L2, your Reviewer should check **compliance with both sets of ADRs**:

1. Project-authored ADRs under `docs/adr/` (written by the Architect in L2)
2. Tailored industry ADRs in the `# Tailored ADRs` section of `CLAUDE.md` (written by `actual adr-bot`)

Update `packs/reviewer/prompts/reviewer.md` to make this explicit:

```markdown
### Review Checklist
1. **Architectural Consistency:** Does the code follow every ADR under `docs/adr/`?
2. **Industry Baseline Compliance:** Does the code respect the Tailored ADRs
   section of `CLAUDE.md`?
   - Each violation must be called out by name: "Violates CLAUDE.md §serde-rename-all"
   - Deviations are acceptable ONLY if the PR contains a new ADR explaining why
3. Code quality, test coverage, security, performance, docs, error handling (unchanged)
```

### Example: Reviewer Catches a Tailored-ADR Violation

Suppose `actual adr-bot` seeded a baseline that says:

> **CLAUDE.md §parameterized-queries** — All database access must use parameterized queries. String-concatenated SQL is forbidden.

And the Coder, under pressure to ship the admin dashboard, wrote:

```ts
const rows = db.prepare(`SELECT * FROM points_ledger WHERE user_id = '${userId}'`).all();
```

A Reviewer with the baseline-compliance rule produces this finding:

```markdown
## Security Findings
- [ ] (high) src/admin/loyaltyReport.ts:22 — violates CLAUDE.md
  §parameterized-queries. String-concatenated SQL (`user_id = '${userId}'`)
  creates an injection vector. Fix: use `db.prepare(...).all(userId)` with
  a `?` placeholder. Tracking ADR-0001 storage rules requires this.
```

And the fix is: add to the Coder prompt's Rules:

```diff
+- All SQL queries MUST use parameterized placeholders (`?`) with the
+  value passed as an argument to .all/.get/.run. Never interpolate user
+  input into a SQL string. Violates CLAUDE.md §parameterized-queries.
```

### Example: Reviewer Catches a Commit-Message Convention Violation

If `actual adr-bot` seeded:

> **CLAUDE.md §conventional-commits** — All commit messages must follow the `type(scope): description` format.

And the Coder committed with `fix stuff`, the Reviewer produces:

```markdown
## Style Findings
- [ ] (low) commit f4e5d6c ("fix stuff") violates CLAUDE.md
  §conventional-commits. Expected format: `type(scope): description`,
  e.g., `fix(loyalty): correct balance calculation on refund`.
```

Fix in Coder prompt's Process:

```diff
-6. Commit on the same feature branch
+6. Commit on the same feature branch using conventional-commits format
+   (`type(scope): description`). Violates CLAUDE.md §conventional-commits
+   if skipped.
```

This turns the Actual ADR system into an enforced quality gate, not just documentation. Re-run `actual adr-bot` any time the baseline shifts — the Reviewer will automatically pick up the new tailored ADRs on next sling.

---

## Inline Insight: Why the Reviewer is Not Just a Linter

A linter catches syntax and style issues that can be expressed as grammar rules (`no-unused-vars`, `prefer-const`, `indent: 2`). The Reviewer catches **intent** issues — whether the implementation matches the spec, whether security properties are preserved, whether test coverage is meaningful. Those require reading the spec, running the tests, and reasoning about the diff.

Concretely:

- A linter cannot tell you that the redeem endpoint is missing an auth check, because the grammar of the code is fine.
- A linter cannot tell you that the spec called for a `refundOrder` path and the Coder skipped it.
- A linter cannot tell you that `tests/loyalty.test.ts` has 14 passing tests but zero of them cover the concurrent-redeem case that ADR-0001 explicitly flagged as a risk.

The Reviewer can do all three, and its entire toolkit for doing so is `packs/reviewer/prompts/reviewer.md` + `docs/PROJECT_MANIFEST.md § Review Standards`. If a Reviewer is missing a class of finding, the fix is always upstream — add a standard, add a Quality Gate rule, add an input. Never patch the output.

## Inline Insight: Why Deployer Findings Must Be Binary

A release decision is a commitment. Either you merge to main or you don't. Either you cut the release or you don't. If the Deployer reports `Criterion 3: mostly passing, some concerns`, a human has to re-evaluate the gate, and the factory has lost its automation. The binary-PASS/FAIL rule is what makes the Deployer's output a viable input to automated merge + release workflows.

This is also why **every PASS must carry evidence**. The automation layer (or a human auditor later) needs to verify the claim without re-running the evaluation. `PASS — npm test 17/17 on commit f4e5d6c` can be verified in 10 seconds by running `git checkout f4e5d6c && npm test`. `PASS — tests look good` cannot be verified at all.

## Inline Insight: The Orchestrator Drives Both Stages

The exit criteria require that `orchestrator.yaml` drive both the Reviewer and the Deployer. That means:

- When the Coder closes its bead, the orchestrator automatically creates the Reviewer bead with `--depends-on` satisfied, and slings it.
- When the Reviewer produces a report with Recommendation `APPROVE`, the orchestrator automatically creates the Deployer bead and slings it.
- When the Reviewer produces `REQUEST_CHANGES`, the orchestrator does **not** advance — it either re-routes to the Coder (if the finding is a Coder gap) or surfaces to the human (if the finding is a spec gap).

You don't need to build the orchestrator in L4 — you just need to have `orchestrator.yaml` wired up so that re-running the pipeline for the next feature doesn't require manual `gc sling` commands. The manual slinging you did in this lab is for learning. In steady state, the orchestrator does it.

---

## Common Issues and Solutions

### Issue 1: Reviewer too lenient (approves everything)

**Cause:** `Review Standards` section of `PROJECT_MANIFEST.md` is vague. The Reviewer has nothing specific to check against, so it defaults to "looks fine."

**Fix:** Make Review Standards concrete. Replace "code should be clean" with:

```markdown
## Review Standards
- Every new function must have an explicit return type annotation
- Every API endpoint that accepts user IDs must verify the authenticated user
- Every SQL query must use parameterized placeholders
- Every test file must include at least one error-path case
- Concurrent-access code paths must wrap read+write in a transaction
```

Re-sling the Reviewer. Specific standards produce specific findings.

### Issue 2: Reviewer too strict (nothing passes)

**Cause:** The Reviewer's Quality Gate has rules that aren't reachable by the Coder (e.g., "100% test coverage"). The Coder's prompt and the Reviewer's prompt are out of sync.

**Fix:** Pick a threshold both prompts agree on. For example, the Coder prompt's Quality Gate says "At least 2 test cases from the work package pass." The Reviewer prompt should then check for ≥2 passing, not 100%. Update `packs/reviewer/prompts/reviewer.md` Quality Gate to match, or update both to a new shared threshold.

### Issue 3: Reviewer writes prose instead of the structured format

**Cause:** The Reviewer either couldn't find the Output Format section or decided it knew better.

**Fix:** Add a hard rule to the prompt: "The review report MUST use the Markdown template in Output Format above. Any deviation from the table structure, the severity labels, or the PASS/FAIL test coverage lines is a Quality Gate violation. Re-read Output Format before writing." Re-sling. If the Reviewer still deviates, inspect whether your `packs/reviewer/prompts/reviewer.md` was actually reloaded (`gc restart` after editing).

### Issue 4: Reviewer can't find the feature branch

**Cause:** The Reviewer's tmux session opened on `main`, or the bead description didn't specify the branch.

**Fix:** Add the branch name explicitly in the bead description (`Feature branch: l3-designer-coder`). Add to the Reviewer prompt's Process step 3: "Before reading the diff, run `git branch --show-current`. If you are not on the feature branch named in the bead, `git checkout <branch>` first."

### Issue 5: Coder regenerates the same bug after prompt update

**Cause:** The prompt edit wasn't reloaded, or the new rule was ambiguous.

**Fix:** Run `gc restart` after editing `packs/builder/prompts/builder.md.tmpl`. Verify the new text is present with `grep "<new rule text>" packs/builder/prompts/builder.md.tmpl`. If ambiguous, tighten the wording — prefer imperative "MUST" over suggestive "should."

### Issue 6: Deployer writes PASS/FAIL without evidence

**Cause:** Prompt's Quality Gate rule about evidence isn't specific enough. The model defaults to terse confirmations.

**Fix:** Add to the Deployer's Quality Gate: "Every entry in the Evidence column MUST include one of: a git commit SHA (7+ chars), a file path, a numeric count, or a verbatim line from a command output. The strings 'looks good', 'LGTM', 'ok', 'fine', 'passes', 'approved' (standalone) are never valid evidence." Re-sling.

### Issue 7: Deployer marks PASS when review says REQUEST_CHANGES

**Cause:** The Deployer didn't actually read the review report, or the review report didn't use `APPROVE`/`REQUEST_CHANGES` as expected.

**Fix:** Add to the Deployer Quality Gate: "Criterion 2 (Review report approved) MUST FAIL if the review report's Recommendation is REQUEST_CHANGES, regardless of whether findings appear resolved. The only way to advance is a fresh review report with Recommendation APPROVE." Re-sling.

### Issue 8: Reviewer finding points at a spec gap, not a Coder gap

**Cause:** The Designer's spec was incomplete (e.g., missing refund handling). The Coder implemented the spec faithfully. Editing the Coder prompt won't fix this — the issue is upstream.

**Fix:** Don't edit the Coder prompt. Route the finding to the Designer:

```bash
bd create "Spec gap: refundOrder path in loyalty points" \
  --description "Reviewer finding: design/loyalty-points-system-spec.md does not include the refundOrder code path required by ADR-0001. Update the spec to include refund handling as a negative ledger entry." \
  --depends-on my-factory-r1r2r3
gc sling designer <new-bead-id>
```

After the Designer updates the spec, re-sling the Coder and Reviewer.

### Issue 9: Release notes in the gate file describe implementation, not user value

**Cause:** The Deployer read the code and summarized the code. It should be summarizing the user-facing outcome.

**Fix:** Add to Deployer Output Format: "Release Notes MUST be written for end users. Do not mention database tables, internal services, file paths, or code constructs. Use the phrase 'Customers can now...' or equivalent to ground the notes in user-facing behavior." Re-sling.

### Issue 10: gc sling reviewer fails with "no such agent"

**Cause:** The pack registered but the agent didn't load into `city.toml`'s runtime. Usually a restart was skipped.

**Fix:** Run `gc restart`, then `gc status` to verify the agent appears. If still missing, inspect `my-factory/city.toml` to see whether the `[[agent]]` block was merged. If not, add it manually (see Part 2, Step 1).

### Issue 11: Reviewer and Deployer keep running concurrently and collide

**Cause:** `max_active_sessions = 1` is set per-agent, but if the orchestrator slings a Reviewer bead before the previous Reviewer session closed, the new sling queues rather than rejects.

**Fix:** In steady state this is fine — queuing is correct behavior. If you want hard exclusion, set `max_active_sessions = 1` in both packs (it already is) and let the orchestrator wait. If two different rigs are running the same feature, use distinct branch names per rig.

### Issue 12: The whole review-fix-review loop takes too long to iterate

**Cause:** Re-slinging Coder, then Reviewer, burns 5–10 minutes per loop. Three loops = half the lab's budget.

**Fix:** Batch multiple findings into a single Coder prompt edit. If the Reviewer reported 5 findings, don't make 5 Coder prompt edits + 5 re-slings. Make one edit that closes all 5, then one re-sling of the Coder, then one re-sling of the Reviewer. The discipline is "fix via config"; the velocity is "fix all findings in one config change."

---

## Quality Bar

When you review your own output, check:

- **Spec Compliance Coverage** — Every element of the design spec appears as a row in the Spec Compliance table. Nothing was silently skipped.
- **Security Breadth** — Findings address at least three domains: injection, auth, and data exposure. Missing domains indicate the Reviewer prompt needs a more explicit checklist.
- **Actionable Recommendations** — Every finding specifies the exact Coder prompt change (or spec change) that would prevent the issue next time. A finding without a config remediation is not actionable.
- **Binary Gate Results** — Every row in the Release Gate's Criteria table is `PASS` or `FAIL` — nothing in between. No "mostly", "partially", "needs attention", "looks good".
- **Evidence Density** — Every PASS row cites a specific artifact: commit SHA, file path, test-runner output, or `git status` line. No opinions.
- **Config Discipline** — At least one reviewer finding was resolved by editing a prompt file (Coder, Designer, or Reviewer itself). Zero review findings were resolved by hand-editing `src/`.

---

## Concept Check (before moving to W4)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain — in their own words, without re-reading — each bullet below. If they can't, revisit the matching section. Also verify by running `git log packs/builder/prompts/` that at least one finding was resolved via a Builder prompt edit, not a code edit.

- Why review findings are fixed by editing the Builder prompt, not the code. (A manual fix solves this bead; a prompt edit prevents the next hundred.)
- The difference between a Reviewer and a linter. (Linters enforce syntax and style; Reviewers enforce spec compliance and project-specific conventions a linter can't express.)
- What makes a release gate "binary." (A single command produces a clean PASS or FAIL with evidence — no "mostly ready" or "looks good.")
- Why the full pipeline is driven by `orchestrator.yaml` (W3) and not by ad-hoc slings. (Declarative config is auditable, reproducible, and edit-once-run-many.)
- What evidence the Release-Gate should attach to each PASS/FAIL. (Command output, test results, artifact paths — not prose.)

---

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `gc status` shows all 6 factory agents: `planner`, `architect`, `designer`, `coder`, `reviewer`, `deployer` (or `devops` if you kept that role name)
- [ ] `review-reports/loyalty-points-system-review.md` is committed with Spec Compliance, Style, Security, and Test Coverage sections filled in
- [ ] At least one reviewer finding was resolved by editing `packs/builder/prompts/builder.md.tmpl` (or the Designer's spec), not by hand-editing code
- [ ] `release-gates/loyalty-points-system-gate.md` is committed with binary PASS/FAIL evidence for every criterion
- [ ] Both the review report and the gate record reference the work package by path
- [ ] `orchestrator.yaml` drives both the reviewer and the deployer (not just manual `gc sling` invocations)
- [ ] Both beads are closed (`bd list` shows status `closed` for the review and release-gate beads)
- [ ] `DECISIONS.md` has an L4 entry noting which Coder prompt edits the Reviewer drove

**L4 completes the 6-agent pipeline.** The factory is now capable of taking a feature request from intake (Planner) to deployment gate (Deployer) without a human touching the code. The workshops and capstone that follow are about running this pipeline at volume, tightening the orchestrator, and adding feedback loops.

---

## Suggestions Based on Project Type

- **If your project has strict security requirements:** Update `packs/reviewer/prompts/reviewer.md` to explicitly check the OWASP Top 10 relevant to your stack. Add per-language rules to `PROJECT_MANIFEST.md § Review Standards` (e.g., for Node: "No use of `child_process.exec` with interpolated input"; for Python: "No use of `pickle.loads` on external data").
- **If your project deploys to production:** Extend the Deployer's Release Criteria to include deployment-specific checks: health endpoint returns 200, rollback plan is documented in the gate record, feature flag is defined. Add these as rows in the gate's Criteria table.
- **If your project is pre-launch:** The Deployer can focus on "merge to main" readiness instead of production deployment. Simplify Release Criteria to: ACs met, review approved, tests pass, no conflicts.
- **If you use GitHub Actions or another CI:** Update the Deployer prompt so Criterion 4 (Tests pass) references the CI run status instead of a local `npm test`. The Evidence column should contain the CI run URL and commit SHA, not local output.
- **If your project has many small, cosmetic PRs:** Add a fast-path to the Reviewer prompt — "If the diff touches only .css, .md, or configuration files, skip the security review section and emit APPROVE directly." The fast-path should still be a prompt rule, not a manual override.
- **If your project supports multiple languages/services:** Create separate `Review Standards` subsections per service in `PROJECT_MANIFEST.md`. The Reviewer should pick the subsection matching the files touched in the diff.

---

## Command Cheat Sheet

Every command you ran during this lab, in order:

```bash
# PART 0 — Read the packs (no commands — just read the files)

# PART 1 — Install Reviewer and Deployer
cd my-factory
gc rig add ~/path/to/your-repo --include /path/to/packs/reviewer
gc rig add ~/path/to/your-repo --include /path/to/packs/release-gate
gc restart
gc status
gc doctor
gc rig list

# PART 2 — Declare agents in city.toml
$EDITOR my-factory/city.toml             # add [[agent]] blocks
gc restart
gc status
git -C my-factory add city.toml && git -C my-factory commit -m "chore(city): declare reviewer + release-gate agents"

# PART 3 — Sling to Reviewer
bd create "Review: Loyalty Points PR" --description "..." --depends-on [coder-bead]
gc sling reviewer my-factory-r1r2r3
gc watch reviewer                        # Ctrl+b d to detach
cat review-reports/loyalty-points-system-review.md

# PART 4 — Fix via config
$EDITOR packs/builder/prompts/builder.md.tmpl    # add Quality Gate / Rules entries
git -C ~/path/to/your-repo add packs/builder/prompts/builder.md.tmpl
git -C ~/path/to/your-repo commit -m "chore(coder): <what rule you added>"
gc sling builder [coder-bead-id]          # re-sling after prompt edit
gc watch coder
gc sling reviewer my-factory-r1r2r3        # re-verify
gc watch reviewer
# repeat until review report is APPROVE

# PART 5 — Sling to Deployer
bd create "Release Gate: Loyalty Points" --description "..." --depends-on my-factory-r1r2r3
gc sling release-gate my-factory-d1d2d3
gc watch deployer
cat release-gates/loyalty-points-system-gate.md
bd close my-factory-d1d2d3 --comment "Release gate PASS"

# PART 6 — (optional) tighten Reviewer with tailored ADRs
$EDITOR packs/reviewer/prompts/reviewer.md   # add CLAUDE.md compliance rule
git -C ~/path/to/your-repo add packs/reviewer/prompts/reviewer.md
git -C ~/path/to/your-repo commit -m "chore(reviewer): enforce CLAUDE.md tailored-ADR baselines"

# Cleanup
bd close my-factory-r1r2r3 --comment "Review APPROVE"
git -C ~/path/to/your-repo push
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Reviewer pack | `packs/reviewer/` | Defines the Reviewer agent: prompt, overlay, metadata |
| Reviewer prompt | `packs/reviewer/prompts/reviewer.md` | System prompt for the Reviewer — Role, Inputs, Output Format, Quality Gate, Process, Config Discipline |
| Deployer pack | `packs/release-gate/` | Defines the Deployer agent: prompt, overlay, metadata |
| Deployer prompt | `packs/release-gate/prompts/release-gate.md.tmpl` | System prompt for the Deployer — same six-section structure |
| Review Standards | `docs/PROJECT_MANIFEST.md` (Review Standards section) | Project-specific review policy — what counts as a finding |
| Release Criteria | `docs/PROJECT_MANIFEST.md` (Release Criteria section) | Project-specific release gate rows — what must be PASS for a release |
| Review report | `review-reports/loyalty-points-system-review.md` | Reviewer's output: Summary, Spec Compliance, Style, Security, Test Coverage, Recommendation |
| Release gate | `release-gates/loyalty-points-system-gate.md` | Deployer's output: Overall Verdict, Criteria table with binary PASS/FAIL + evidence, Release Notes, References |
| Coder prompt edits | `packs/builder/prompts/builder.md.tmpl` diff | The config-discipline artifact — each reviewer finding resolved is a commit on this file |
| Reviewer bead | `bd show my-factory-r1r2r3` | Work item that triggered the Reviewer, depends on the Coder bead |
| Deployer bead | `bd show my-factory-d1d2d3` | Work item that triggered the Deployer, depends on the Reviewer bead |
| Orchestrator config | `orchestrator.yaml` | Automation wiring: Coder-close → Reviewer-sling → (if APPROVE) Deployer-sling |

---

## Next Steps

After L4, your complete factory pipeline is:

1. Planner — breaks feature requests into work packages
2. Architect — makes technical decisions (ADRs)
3. Designer — produces component specs from the work package + ADR
4. Coder — implements code from the spec
5. Reviewer — reviews code against spec + policy, produces structured findings
6. Deployer — evaluates binary release criteria, produces a gate record

You now have an end-to-end software factory. In the workshops (W2–W4) and capstone (C1), you'll:

- Tighten the orchestrator so beads advance between agents without manual slings
- Add feedback loops so recurring findings become permanent prompt rules
- Run the full factory autonomously against a queue of real feature requests
- Measure throughput and quality: how many features per day, findings per feature, failed gates per week

The pattern in every stage is the same as what you just practiced: read pack, install pack, customize prompt, create bead, sling, review output against Quality Gate, iterate config (never hand-edit), commit. You've done it six times now. The remaining curriculum is about scale and stability, not new mechanics.
