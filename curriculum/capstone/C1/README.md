# C1: Run the Full Release Delivery Factory

> **What you will do:** switch the active factory to the C1 pack and run the
> full formula graph from feature request through release gate.

## Mental Model

C1 is the whole factory as one graph:

```text
plan -> architecture -> design -> build -> validate -> review -> release
```

The factory pack is selected in `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
```

The imported agents are rig-scoped:

```text
<rig>/factory.planner
<rig>/factory.architect
<rig>/factory.designer
<rig>/factory.builder
<rig>/factory.validator
<rig>/factory.reviewer
<rig>/factory.release-gate
```

## 1. Confirm formula v2

Confirm `my-factory/city.toml` contains:

```toml
[daemon]
formula_v2 = true
```

## 2. Select the C1 Factory Pack

Edit `my-factory/pack.toml`:

```toml
[pack]
name = "my-factory"
schema = 2

[defaults.rig.imports.factory]
source = "../packs/lessons/C1"
```

## 3. Sync the Existing Rig

```bash
cd my-factory
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/C1 --name factory
gc restart
gc doctor
```

## 4. Start the Formula

```bash
gc sling planner \
  "Add a multiply operation: multiply(a, b) returns a*b" \
  --on mol-release-delivery
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
factory.planner -> factory.architect -> factory.designer -> factory.builder -> factory.validator -> factory.reviewer -> factory.release-gate
```

## 6. Inspect Outputs

In your project rig:

```bash
ls docs/plans
ls docs/architecture
ls docs/designs
ls docs/validation
ls docs/reviews
ls docs/releases
git log --oneline -5
npm test
```

Expected outputs:

- plan, architecture, and design artifacts
- implementation commit and passing tests
- validation report with test evidence
- review report with severity-labelled findings
- release gate with a clear `PASS` or `FAIL`

A complete run should produce artifacts with sections like these:

- Plan: `Goal`, `User Stories`, `Acceptance Criteria`, `Scope Boundary`, `Dependencies`, `Open Questions`, `Handoff`
- Architecture: `Context`, `Options Considered`, `Decision`, `Consequences`, `Risks`, `References`
- Design: `Interface`, `Behavior`, `Edge Cases`, `Test Plan`, `Build Notes`, `References`
- Validation: `Verdict`, `Test Command`, `Results`, `Issues`, `References`
- Review: `Verdict`, `Summary`, `Findings`, `Test Evidence`, `Recommendation`, `References`
- Release: `Verdict`, `Required Checks`, `Evidence`, `Risks`, `Decision Notes`, `References`

## 7. Write the Retrospective

Before writing the retrospective, decide: are you measuring the W4 rule you already applied, or applying a new one now? If you want to test a new rule, edit the C1 pack prompt or manifest, re-sling with a different feature, and compare the two runs. If you're measuring the existing rule, use the run you just completed.

Create `activities/capstone/C1/retrospective.md`:

```markdown
# Factory Run Retrospective

## Run Summary
- Feature:
- Root bead:
- Formula: mol-release-delivery
- Stages completed:

## What Worked
- [observation with artifact evidence]

## What Didn't Work
- [observation with root cause]

## W4 Improvement Criteria Applied

Revisit your W4 feedback rules. For each rule you applied:

| Rule | Signal Observed? | Metric Before | Metric After |
|------|-----------------|---------------|--------------|

## Config Changes Made During This Run
| File | Change | Why |
|------|--------|-----|

## What I Would Change Before the Next Run
```

If no W4 criteria or config changes applied during the run, record that
explicitly instead of inventing one.

## Exit Criteria

- The run started with one `gc sling planner ... --on mol-release-delivery`.
- No stage labels or manual downstream beads were used.
- All seven agents received and completed their formula steps.
- The release gate includes an explicit verdict backed by validation and review evidence.
- Retrospective exists and evaluates any W4 criteria that applied.
- Config changes are documented with file and reason, or the retrospective
  explicitly says that no config changes were made.
