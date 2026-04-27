# W4 · Create Continuous Improvement Loops

W4 teaches how a factory improves after real runs. The runtime remains the selected lesson pack; this workshop produces rule proposals and, when appropriate, edits to that pack or to project instructions.

## Goal

Capture feedback in a form that can become durable factory behavior.

## 1. Gather Signals

Look at artifacts from the latest L4 or C1 run:

```bash
find docs -maxdepth 3 -type f | sort
git log --oneline --decorate -10
```

Useful signals:

- repeated review findings
- validation failures
- vague acceptance criteria
- missing architecture tradeoffs
- release gate failures
- unclear artifact formats

## 2. Write Feedback Rule Files

Create:

```bash
mkdir -p activities/workshops/W4/feedback-loops
```

For each rule:

```bash
$EDITOR activities/workshops/W4/feedback-loops/<type>-<topic>.md
```

Use this structure:

```markdown
# <Rule Name>

## Signal

What happened?

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
| Project-specific policy | project `CLAUDE.md`, `AGENTS.md`, or `my-factory/PROJECT_MANIFEST.md` |

The activity file explains the lesson learned. The runtime file should encode the durable behavior without saying it came from a workshop.

## 4. Apply One Small Rule

Choose one rule and make the smallest real config change. Commit the rule file and the runtime change together so the audit trail shows why the factory changed.

Example:

```bash
git add activities/workshops/W4/feedback-loops/reactive-async-error-handling.md
git add packs/lessons/C1/agents/builder/prompt.template.md
git commit -m "Teach builder async error handling rule"
```

## 5. Measure One Improvement

A rule that doesn't change behavior isn't a rule yet. Pick one measurable signal from your feedback rules:

1. Record the before-state from your most recent L4 or C1 run (e.g., reviewer finding count, release gate verdict, test pass rate).
2. Apply the config change (step 4).
3. Re-sling the same formula with a similar feature request.
4. Record the after-state.

| Metric | Before | After | Change Applied | File |
|--------|--------|-------|----------------|------|
| | | | | |

Add a Measurement section to your feedback rule files after Verification:

```markdown
## Measurement

What metric did you check? What was the before/after?
```

## Exit Criteria

- [ ] At least three feedback rule files exist.
- [ ] Each rule has signal, trigger, target, proposed change, verification, and rollback.
- [ ] One rule has been applied to the active lesson pack or project instructions.
- [ ] The runtime change is portable and does not mention the workshop.
- [ ] At least one rule includes before/after measurement from a factory run.
