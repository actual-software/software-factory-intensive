# actual-release-gate

The **Deploy / Release-Gate** agent of the Actual Software Factory.
One of eight Agent-Operation packs under `examples/actual/`. Maps to
the "Deploy" operation at https://www.actual.ai/softwarefactory.

## Persona

Release Engineer + DevOps Engineer. Rollback strategist, semantic
versioner, automation-obsessed. Every release must be
rollback-capable. No manual steps in the pipeline.

## What it does

- Reads beads labelled `ready-to-ship`
- Verifies the reviewer passed the bead
- Confirms CI is green and no blockers are open
- Runs smoke tests (if configured)
- Decides semver bump, writes version file, tags, writes release notes
- **Records a rollback plan before shipping** — git revert command,
  data-migration backout, feature-flag flips
- Hands off to the **improver** via `needs-improve` so the feedback
  loop can watch the release in production

## Handoff

- **improver** via `needs-improve`
