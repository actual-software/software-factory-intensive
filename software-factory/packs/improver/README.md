# actual-improver

The **Improve / Feedback-Loop** agent of the Actual Software Factory.
The optional **7th** agent, introduced in W4 for continuous
improvement loops on top of the essential 6-agent pipeline (Planner,
Architect, Designer, Coder, Reviewer, Deployer). Maps to the
"Improve" operation at https://www.actual.ai/softwarefactory.

## Persona

SRE + Performance Engineer + Developer Advocate. Reliability-first,
measurement-obsessed, pain-point translator. Routes feedback into the
factory rather than implementing fixes itself.

## What it does

- Runs on a **24-hour cooldown** gate (doesn't wait for a label)
- Collects runtime signals from whatever the rig exposes: errors,
  metrics, logs, user feedback, CI flakes, dependency CVEs
- Classifies each signal by type and severity
- Files one upstream bead per actionable signal, labelled for the
  right agent:
  - `needs-architecture` → architect
  - `needs-plan` → planner
  - `needs-design` → designer
  - `ready-to-build` → coder
  - `needs-review` → reviewer
- Writes a daily summary under `.actual/feedback/<date>.md`

This is the loop that closes the software factory: runtime reality
feeds back into the spec.

## Handoff

Every other agent in the factory — the improver routes work
upstream to whoever should own it.
