# L1 · Build a Structured Development Loop — Activity

**Walkthrough:** [`../../../curriculum/labs/L1/README.md`](../../../curriculum/labs/L1/README.md)
**Reference examples:**
* [`../../../reference-project/fired-up-pizza/CLAUDE.md`](../../../reference-project/fired-up-pizza/CLAUDE.md)
* [`../../../reference-project/fired-up-pizza/DECISIONS.md`](../../../reference-project/fired-up-pizza/DECISIONS.md)

## Deliverables

Two files in this folder (mirroring the reference project):

* `CLAUDE.md` — your filled-in agent-instructions file. Start from the shipped reference structure, fill the Tech Stack / Project Structure / Rules / Release Criteria sections in for *your* project. If you're using a non-Claude assistant, name it `AGENTS.md` instead — the content is identical.
* `DECISIONS.md` — a log with one entry per `CLAUDE.md` rule change during L1. Date, short description, and the commit SHA that made the change.

You'll also generate your project's `PROJECT_MANIFEST.md` during L1. That file belongs in `../../../my-factory/PROJECT_MANIFEST.md` (template already placed there) — not in this folder.

## Workspace wiring

L1 registers `../../../my-factory/` as a Gas City workspace and adds your project repo as a rig. No pack is included yet — the first pack gets added in L2. After L1, `../../../my-factory/city.toml` should have:

```toml
[workspace]
name = "my-factory"
provider = "claude"
includes = []

[[rigs]]
name = "your-project"
path = "../../path/to/your-project"
includes = []
```

## Exit criteria

* [ ] `activities/labs/L1/CLAUDE.md` exists with at least 5 project-specific rules
* [ ] `activities/labs/L1/DECISIONS.md` has an entry per rule change during the lab
* [ ] `../../../my-factory/PROJECT_MANIFEST.md` filled in (Overview, Tech Stack, Project Structure sections minimum)
* [ ] `gc status` from `../../../my-factory/` shows your rig registered

## Skipped this session?

Every later lab reads from `PROJECT_MANIFEST.md`. At the very minimum, copy the reference manifest to `../../../my-factory/PROJECT_MANIFEST.md` and replace the domain-specific sections with your project's. Without a filled manifest, the Planner and Architect have nothing to ground their output on.
