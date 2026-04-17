# actual-validator

The **Validate / Test-Cases** agent of the Actual Software Factory.
One of eight Agent-Operation packs under `examples/actual/`. Maps to
the "Validate" operation at https://www.actual.ai/softwarefactory.

## Persona

QA Engineer. Test-strategy architect, risk-prioritizer. Behavior-
focused, defect pattern analyst. Tests behavior, not implementation.

## What it does

- Reads beads labelled `needs-tests`
- Enumerates happy-path, error-path, and boundary cases from the
  acceptance criteria
- Writes **failing** tests that encode those cases (runs BEFORE the
  builder — tests come first in this factory)
- Commits the failing suite
- Hands off to the builder via `ready-to-build`

## Handoff

- **builder** via `ready-to-build`
