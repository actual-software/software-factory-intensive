# W4 · Continuous Improvement Loops — Activity

**Walkthrough:** [`../../../curriculum/workshops/W4/README.md`](../../../curriculum/workshops/W4/README.md)
**Reference examples:** [`../../../reference-project/fired-up-pizza/feedback-loops/`](../../../reference-project/fired-up-pizza/feedback-loops/)

## Deliverables

A `feedback-loops/` subfolder in here, containing at least three `.md` files — one per loop type:

* `reactive-<topic>.md` — a specific reviewer finding that was encoded as a pack-prompt rule
* `aggregate-<topic>.md` — a pattern that emerged across multiple runs and was folded into the manifest or a pack prompt
* `external-<topic>.md` — a signal from outside the factory (customer report, ops alert) that fed back into a pack or the manifest

Each loop file follows the reference shape: *What triggered it → What rule was added → Where (exact file path) → Commit SHA*.

## Workspace wiring

W4 doesn't add packs. It **edits** prompts on packs you've already installed — typically the Builder's `../../../packs/builder/prompts/builder.md.tmpl` and the Release-Gate's `../../../packs/release-gate/prompts/release-gate.md.tmpl`. If you're running a customised copy under `activities/<session>/packs/`, edit the copy and commit; otherwise edit the shipped pack and commit.

The `includes` list in `../../../my-factory/city.toml` does not change in W4.

## Exit criteria

* [ ] `feedback-loops/` has at least one reactive, one aggregate, and one external rule file.
* [ ] Each rule file links to a specific commit that changed a pack prompt or the manifest.
* [ ] The pack prompt change and the feedback-loop file are in the **same commit** — that's the audit trail.

## Skipped this session?

C1 measures "feedback-loop hits during the run". Without W4 loops, that field will be zero — still valid, but you lose the signal that your factory is self-correcting.
