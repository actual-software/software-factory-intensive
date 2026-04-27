# W4 · Create Continuous Improvement Loops — Activity

**Walkthrough:** [`../../../curriculum/workshops/W4/README.md`](../../../curriculum/workshops/W4/README.md)

W4 designs feedback loops for the active factory. It does not add a new runtime pack by itself.

## Deliverables

Create `feedback-loops/` in this folder and add one short markdown file per proposed rule:

```text
activities/workshops/W4/feedback-loops/
  reactive-<topic>.md
  aggregate-<topic>.md
  external-<topic>.md
```

Each rule file should include:

- signal observed
- trigger threshold
- target runtime file or project instruction file
- proposed change
- rollback condition
- owner for review

## Where Runtime Changes Go

Rules discovered here should be applied to the self-contained factory pack that will run the next lab or capstone. For example, if the next run uses C1, apply the prompt or formula change inside `../../../packs/lessons/C1/`.

Keep lesson framing out of the pack internals. The activity can explain why the rule was written; the pack should simply encode the durable factory behavior.

## Exit Criteria

- [ ] At least one reactive rule is written.
- [ ] At least one aggregate rule is written.
- [ ] At least one external-signal rule is written.
- [ ] Each rule names the exact file it would change and how to verify it worked.
- [ ] At least one rule includes before/after measurement evidence.
