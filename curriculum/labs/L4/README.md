# L4 · Deploy Reviewer + DevOps Agents

> **Goal:** Complete your software factory by adding its final two specialists, and tie the output back to the `PROJECT_MANIFEST.md` as a reference for the Review and Release criteria.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Reviewer + DevOps (a.k.a Release Gate) agents, with the `PROJECT_MANIFEST.md` as a reference for the Review and Release criteria |

## Architecture

```
            feature branch (from L3)
                     │
                     ▼
          ┌──────────────────────┐
          │  Reviewer (L4)       │  ← reads: PROJECT_MANIFEST.md
          │                      │           (Review Standards section)
          │  produces:           │
          │  docs/reviews/       │
          │  <slug>.md           │
          └──────────┬───────────┘
                     │  verdict: APPROVE (else loop back to Coder)
                     ▼
          ┌──────────────────────┐
          │  DevOps   (L4)       │  ← reads: PROJECT_MANIFEST.md
          │                      │           (Release Criteria section)
          │  produces:           │
          │  docs/releases/      │
          │  <slug>.md           │
          └──────────────────────┘
                     │
                     ▼
               Ready to ship
```

## Mental Model

L4 keeps the same process shape as L3 and adds two downstream evidence steps:

```text
plan -> architecture -> design -> build -> review -> release gate
```

The factory pack is selected in `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L4"
```

The imported agents are rig-scoped:

```text
<rig>/factory.planner
<rig>/factory.architect
<rig>/factory.designer
<rig>/factory.builder
<rig>/factory.reviewer
<rig>/factory.release-gate
```

## 1. Confirm formula v2

Confirm `my-factory/city.toml` contains:

```toml
[daemon]
formula_v2 = true
```

## 2. Select the L4 Factory Pack

Edit `my-factory/pack.toml`:

```toml
[pack]
name = "my-factory"
schema = 2

[defaults.rig.imports.factory]
source = "../packs/lessons/L4"
```

## 3. Sync the Existing Rig

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L4 --name factory
gc restart
gc doctor
```

## 4. Start the Formula

```bash
gc sling planner \
  "Add a clamp operation: clamp(x, lo, hi) returns x bounded to [lo, hi]" \
  --on mol-delivery-review
```

Capture the workflow bead id printed by `Attached workflow ...`.

## 5. Watch Progress

```bash
gc events --follow
gc session list
gc session peek <session-id>
gc graph <workflow-bead-id>
bd list
```

You should see:

```text
factory.planner -> factory.architect -> factory.designer -> factory.builder -> factory.reviewer -> factory.release-gate
```

Use the observability commands from L2. Watch for review findings and release verdicts in the event stream.

## 6. Inspect Outputs

In your project rig:

```bash
ls docs/plans
ls docs/architecture
ls docs/designs
ls docs/reviews
ls docs/releases
git log --oneline -5
npm test
```

Expected outputs:

- plan, architecture, and design artifacts
- implementation commit and passing tests
- review report with severity-labelled findings
- release gate with a clear `PASS` or `FAIL`

A complete L4 run should produce artifacts with these sections:

| Artifact | Required sections |
|---|---|
| Plan | Goal, User Stories, Acceptance Criteria, Scope Boundary, Dependencies, Open Questions, Handoff |
| Architecture | Context, Options Considered, Decision, Consequences, Risks, References |
| Design | Interface, Behavior, Edge Cases, Test Plan, Build Notes, References |
| Review | Verdict, Summary, Findings, Test Evidence, Recommendation, References |
| Release gate | Verdict, Required Checks, Evidence, Risks, Decision Notes, References |

For the example above, the feature adds `clamp(x, lo, hi)` and `npm test`
should show 8 tests, 8 passing.

## 7. Prove the manifest is load-bearing

The reviewer and release-gate prompts in this lesson pack read `PROJECT_MANIFEST.md` and look for Review Standards and Release Criteria sections. If those sections exist, the reviewer uses them to structure findings and the release-gate evaluates each criterion individually. If they don't exist, the agents fall back to general judgment.

You're about to prove that by adding standards and watching the output change.

Open the manifest you created at `docs/PROJECT_MANIFEST.md` and add:

- Add at least 4 Review Standards with checkable rules and severity mapping
- Add at least 6 Release Criteria with binary PASS/FAIL gates and evidence sources

Use standards like these:

| Review Standard | Severity |
|---|---|
| All exported functions must have JSDoc comments | Medium |
| No hardcoded credentials or secrets | Critical |
| All error paths must be handled explicitly | High |
| New public functions must have corresponding test cases | High |

Then re-sling with a different feature:

```bash
gc sling planner \
  "Add a modulo operation: mod(a, b) returns a%b" \
  --on mol-delivery-review
```

Compare the second review artifact to the first one:

- The reviewer should cite your Review Standards by name
- The findings should tie back to concrete standards such as JSDoc, testing, error paths, or credential handling

If the manifest change produced no visible difference, the reviewer or release-gate prompt needs to reference the manifest more explicitly — which is itself a W4 feedback rule.

## Exit Criteria

- The run started with one `gc sling planner ... --on mol-delivery-review`.
- No stage labels or manual downstream beads were used.
- All six agents received and completed their formula steps.
- The release gate includes an explicit verdict backed by evidence.
- Manifest load-bearing test completed — reviewer cited Review Standards from `docs/PROJECT_MANIFEST.md`.

## Next Steps

**[W4](../../workshops/W4/README.md)** introduces continuous improvement loops — the practice of feeding signals from finished runs back into your configuration so each run produces better outputs than the last. Your L4 review reports and release gates are an example of a primary signal source that may feed into this loop.
