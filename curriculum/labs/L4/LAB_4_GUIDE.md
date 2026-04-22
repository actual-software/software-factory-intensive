# L4 · Deploy Reviewer + Deployer Agents

> **Goal:** Complete your software factory by adding its final two specialists, and tie the output back to the `PROJECT_MANIFEST.md` as a reference for the Review and Release criteria.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Reviewer + Deployer (DevOps) agents, with the `PROJECT_MANIFEST.md` as a reference for the Review and Release criteria |

## Deliverable

By the end of this lab, you will have:

- A factory at `~/Projects/factory/lab_l4/l4-gc-factory/` with **all six stages** running.
- `docs/PROJECT_MANIFEST.md` populated with:
  - `## Review Standards` — at least four categories of checkable rules (Style, Security, Correctness, …) plus a severity scale that maps to APPROVE / REQUEST_CHANGES.
  - `## Release Criteria` — at least six binary PASS/FAIL gates, each with a named evidence source (CI logs, test output, work-package checklist, etc.).
- Reviewer and Deployer prompts that explicitly cite their manifest section as authoritative (no inventing rules outside the manifest).
- For one real feature: `review-reports/<slug>-review.md` and `release-gates/<slug>-gate.md`, with every Reviewer finding citing a Review Standards rule and every Deployer row resolving to PASS or FAIL with evidence.
- Evidence that a manifest edit visibly changes a verdict — proving the manifest is load-bearing, not decorative.

The `review-reports/` and `release-gates/` directories become the primary signal source W4 reads from.

## Overview

L2 built the thinking half of the factory; L3 built the doing half. L4 closes the loop with the **gating** half — the two stages that decide whether work produced by the previous four is good enough to ship.

The Reviewer and Deployer are defined almost entirely by *configuration*, not by LLM capability. The Reviewer is only as strict as the standards you hand it. The Deployer is only as disciplined as the criteria you write down. Both agents read `PROJECT_MANIFEST.md` on every run; both will accept or reject work based on the sections named below.

Through this lab you will:
- Install and run the Reviewer and Deployer against your project
- Populate `PROJECT_MANIFEST.md → Review Standards` with your team's real code quality rules
- Populate `PROJECT_MANIFEST.md → Release Criteria` with your team's real shipping gates
- Wire each agent to its manifest section and verify that changes to the manifest change the agent's verdicts
- Exercise the full Reviewer → Deployer handoff on the feature branch you produced in L3

## What You'll Build

```
            feature branch (from L3)
                     │
                     ▼
          ┌──────────────────────┐
          │  Reviewer (L4)       │  ← reads: PROJECT_MANIFEST.md
          │                      │           (Review Standards section)
          │  produces:           │
          │  review-reports/     │
          │    <slug>-review.md  │
          └──────────┬───────────┘
                     │  verdict: APPROVE (else loop back to Coder)
                     ▼
          ┌──────────────────────┐
          │  Deployer (L4)       │  ← reads: PROJECT_MANIFEST.md
          │                      │           (Release Criteria section)
          │  produces:           │
          │  release-gates/      │
          │    <slug>-gate.md    │
          └──────────────────────┘
                     │
                     ▼
               Ready to ship
```

The arrow from the Reviewer to the Coder (if the verdict is REQUEST_CHANGES) is the feedback loop you care most about — L4 is the first lab where the pipeline fully closes on itself.

## Part 1: Install the L4 Factory (10 min)

> **Goal:** Bring up the factory with Reviewer and Deployer active alongside every stage you've installed so far.

### Step 1: Install L4

```bash
# In your agent session, run:
/factory-activity-agent install L4
```

Creates `~/Projects/factory/lab_l4/l4-project/` and `~/Projects/factory/lab_l4/l4-gc-factory/` with all six packs wired.

### Step 2: Confirm your central docs were seeded and pull in the per-feature artifacts

The install step copies your **central deliverables folder** (`software-factory-intensive/docs/`) into the L4 workspace. Spot-check what flows automatically:

```bash
ls ~/Projects/factory/lab_l4/l4-project/docs/
```

You should see `PROJECT_MANIFEST.md`, `SOFTWARE_FACTORY_MANIFEST_.md`, `factory-pipeline.md`, and `coordination-channels.md`. (`factory-iterations.md` is authored in W4; you won't have it yet.)

Per-feature artifacts from L3 — the feature branch source, `work-packages/`, and `design/` — live outside `docs/` and are *not* auto-carried. Pull them in so the Reviewer has something to evaluate:

```bash
cp -R ~/Projects/factory/lab_l3/l3-project/work-packages \
      ~/Projects/factory/lab_l4/l4-project/

cp -R ~/Projects/factory/lab_l3/l3-project/design \
      ~/Projects/factory/lab_l4/l4-project/

# Plus the project source + feature branch the Coder produced:
cp -R ~/Projects/factory/lab_l3/l3-project/src \
      ~/Projects/factory/lab_l4/l4-project/
git -C ~/Projects/factory/lab_l4/l4-project log --oneline -5   # confirm the branch state
```

If anything in `docs/` is missing, see [Backup Project Setup](../../../README.md#backup-project-setup) in the main README.

### Step 3: Verify all six stages are up

```bash
/factory-activity-agent status L4
```

Expect `planner`, `architect`, `designer`, `builder`, `reviewer`, `release-gate` all listed.

## Part 2: Read the Reviewer and Deployer (10 min)

> **Goal:** Know precisely what each stage reads from the manifest so you can write the right content in Part 3.

| Stage | Prompt file | Reads | Produces | Decides |
|-------|-------------|-------|----------|---------|
| **Reviewer** | [`packs/reviewer/prompts/reviewer.md.tmpl`](../../../packs/reviewer/prompts/reviewer.md.tmpl) | Feature branch diff, spec, work package, `PROJECT_MANIFEST.md → Review Standards` | `review-reports/<slug>-review.md` — summary, findings, verdict | *Is this code ready for production?* |
| **Deployer** | [`packs/release-gate/prompts/release-gate.md.tmpl`](../../../packs/release-gate/prompts/release-gate.md.tmpl) | Review report, work package, branch state, `PROJECT_MANIFEST.md → Release Criteria` | `release-gates/<slug>-gate.md` — PASS/FAIL per criterion | *Do all required criteria have PASS evidence?* |

A key distinction: the Reviewer's judgement is *qualitative* (opinion backed by evidence); the Deployer's is *deterministic* (a binary checklist). Keeping these separate — and keeping each grounded in its own manifest section — is what makes both auditable.

## Part 3: Populate the Manifest Sections (25 min)

> **Goal:** Write the real Review Standards and Release Criteria for your project, so the two stages have something specific and team-accepted to enforce.

### Step 1: Author Review Standards

Open `docs/PROJECT_MANIFEST.md` and edit (or create) `## Review Standards`. Include at least four categories. Each rule must be *checkable* — a rule the Reviewer could plausibly flag with a file + line reference.

```markdown
## Review Standards

### Style
- No `any` / `unknown` types at module boundaries
- Every function with three or more parameters must use a named object
- Lines wrap at 100 characters

### Security
- Never interpolate user input into SQL strings; use parameterized queries
- No secrets in source — verified by `gitleaks` / `trufflehog` in CI
- Every new endpoint declares its auth scope

### Correctness
- Every acceptance criterion in the work package has a matching test
- No broadened catch-all `try { ... } catch(e) { }` blocks without a re-throw

### Severity scale
| Level | Definition                                              | Action |
|-------|---------------------------------------------------------|--------|
| High  | Security issue, data loss risk, or AC not implemented   | REQUEST_CHANGES |
| Med   | Style violation at a boundary the team has committed to | REQUEST_CHANGES |
| Low   | Cosmetic, convention nit                                 | APPROVE with note |
```

Pull these rules from how your team actually operates — your PR template, your reviewer checklist, your tribal knowledge. The manifest is where you turn that tacit rulebook into something the Reviewer can read.

### Step 2: Author Release Criteria

In the same manifest, edit (or create) `## Release Criteria`. Each criterion must be **binary** — PASS or FAIL, no judgement. If a criterion requires judgement, it belongs in Review Standards, not here.

```markdown
## Release Criteria

| # | Criterion                                           | Evidence source |
|---|-----------------------------------------------------|-----------------|
| 1 | All acceptance criteria from the work package pass  | Work package checklist in review report |
| 2 | Review verdict is APPROVE                            | `review-reports/<slug>-review.md` |
| 3 | No open High-severity review findings                | Review report findings list |
| 4 | `npm run lint` passes on feature branch              | CI log (or local re-run) |
| 5 | `npm test` passes on feature branch                  | CI log (or local re-run) |
| 6 | `npm run build` produces a bundle                    | CI log (or local re-run) |
| 7 | Branch merges cleanly into `main`                    | `git merge --no-commit` dry run |
| 8 | Release notes present in the work package's notes    | Work package notes |
```

Use the commands your project actually runs. If you use `pytest` and `make`, write those. If your CI is in GitHub Actions, cite the workflow file by name.

### Step 3: Wire each stage to its section

Edit `packs/reviewer/prompts/reviewer.md.tmpl`:

```markdown
## Inputs you consume
  + `docs/PROJECT_MANIFEST.md → Review Standards` — THIS is your checklist.
    Do not invent rules that are not in this section.

## Constraints
  + Every finding must cite a rule from Review Standards, with file+line
  + Severity uses the scale in Review Standards; no ad-hoc severities
```

Edit `packs/release-gate/prompts/release-gate.md.tmpl`:

```markdown
## Inputs you consume
  + `docs/PROJECT_MANIFEST.md → Release Criteria` — THIS is the table
    you evaluate. Do not add or remove rows.

## Constraints
  + Every criterion must resolve to a binary PASS or FAIL with evidence
  + The overall verdict is PASS iff every row is PASS; otherwise FAIL
```

Restart the factory:

```bash
cd ~/Projects/factory/lab_l4/l4-gc-factory && gc stop && gc start
```

## Part 4: Run the Reviewer and Deployer (20 min)

> **Goal:** Exercise the full handoff on the real feature branch you produced in L3, and verify that the manifest's standards are what shape the verdicts.

### Step 1: Sling the Reviewer

```bash
/factory-activity-agent sling L4 reviewer \
  "Review the feature branch for <slug> against docs/PROJECT_MANIFEST.md → Review Standards."
```

Read `review-reports/<slug>-review.md`. Every finding must cite a rule from your Review Standards.

### Step 2: If REQUEST_CHANGES, loop back to the Coder

Your Reviewer's verdict is the input to the Coder, not a direct edit. If REQUEST_CHANGES, sling the Coder with the review report as context; do not edit the code yourself.

```bash
/factory-activity-agent sling L4 builder \
  "Address the findings in review-reports/<slug>-review.md."
```

Re-sling the Reviewer after the Coder commits.

### Step 3: Sling the Deployer

Once the Reviewer returns APPROVE:

```bash
/factory-activity-agent sling L4 release-gate \
  "Evaluate release-gates/<slug>-gate.md against docs/PROJECT_MANIFEST.md → Release Criteria."
```

Read `release-gates/<slug>-gate.md`. Every row from Release Criteria must be present; every row must be PASS or FAIL with a line of evidence.

### Step 4: Prove the manifest is load-bearing

Change one rule in Review Standards (tighten it — e.g. lower the severity threshold for an existing rule) and re-sling the Reviewer. The verdict should change. If it does not, the Reviewer isn't actually consuming the manifest — fix the prompt wiring before moving on.

Do the same for Release Criteria: add a criterion (e.g. "bundle size delta < 5%") and re-sling the Deployer. The new row should appear in `release-gates/<slug>-gate.md`.

## Common Issues and Solutions

- **"The Reviewer flags rules that aren't in Review Standards."** The prompt doesn't constrain it strictly enough. Add a `MUST NOT invent rules outside Review Standards` line under `## Constraints`.
- **"The Deployer's verdict is inconsistent with its own criteria."** Either a criterion is subjective (reclassify it as a Review Standard) or the prompt isn't enforcing binary output. Tighten the `## Constraints` to require PASS/FAIL + evidence per row.
- **"The feedback loop never terminates — Reviewer keeps asking for more."** Usually over-broad standards. Either narrow the rule or move it to a lower severity so it doesn't trigger REQUEST_CHANGES.
- **"A rule is correct in my head but not in the manifest."** That's the whole point of this lab. If a reviewer would flag it in a human PR review, it goes in the manifest; if not, let the agent ship it.
- **"My Release Criteria reference CI that I don't have."** That's fine — run the commands locally and have the Deployer cite the local output. Wiring CI is a W4 improvement, not an L4 requirement.

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `/factory-activity-agent status L4` shows all six stages running
- [ ] `docs/PROJECT_MANIFEST.md → Review Standards` has at least four categories with rules that apply to your project
- [ ] `docs/PROJECT_MANIFEST.md → Release Criteria` has at least six binary criteria with evidence sources
- [ ] Reviewer prompt and Deployer prompt each explicitly cite their manifest section as authoritative
- [ ] A full run produced `review-reports/<slug>-review.md` and `release-gates/<slug>-gate.md` for a real feature
- [ ] One manifest-edit iteration (Review Standards or Release Criteria) visibly changed the agent's verdict

## Quick Reference: What You Built

| Artifact | Location | What It Does |
|----------|----------|--------------|
| L4 factory | `~/Projects/factory/lab_l4/l4-gc-factory/` | Full six-stage factory |
| `PROJECT_MANIFEST.md → Review Standards` | Inside the L4 project workspace | Authoritative rule set the Reviewer enforces |
| `PROJECT_MANIFEST.md → Release Criteria` | Inside the L4 project workspace | Binary gate list the Deployer evaluates |
| Review report | `review-reports/<slug>-review.md` | Qualitative verdict on one feature |
| Release gate report | `release-gates/<slug>-gate.md` | Binary gate evaluation on one feature |

## Next Steps

**[W4](../../workshops/W4/WORKSHOP_4_GUIDE.md)** introduces continuous improvement loops — the practice of feeding signals from finished runs back into your configuration so each run produces better outputs than the last. Your L4 review reports and release gates are the primary signal source.

**[C1](../../capstone/C1/CAPSTONE_1_GUIDE.md)** is the capstone run — an unfamiliar feature request sent end-to-end through the factory you just completed.
