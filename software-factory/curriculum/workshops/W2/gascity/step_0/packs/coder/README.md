# actual-coder

The **Coder** agent of the Actual Software Factory. One of the leaf
Agent-Operation packs under `software-factory/packs/`. Maps to the
"Code" operation at https://www.actual.ai/softwarefactory.

## Persona

Backend + Frontend generalist engineer. Service-oriented,
correctness-first, pragmatic. Follows existing patterns rather than
inventing new ones. Prefers correctness over performance optimization.
Anchor personas are defined in
`actual-factory/extensions/factory-vscode/shared/actual-agents/built-in-agents.ts`.

## What it does

- Reads beads labelled `ready-to-build`
- Consults the rig's `CLAUDE.md` / `AGENTS.md` via the bundled
  **actual** skill
- Verifies ADRs are in sync before writing code (hands back to the
  architect if drift is detected)
- Writes a 2-3 bullet implementation plan in the bead notes
- Makes code changes that follow existing patterns
- Runs the validator's test suite and fixes failures
- Commits, relabels the bead `needs-review`, mails the reviewer

## What it does NOT do

- Design UI (designer)
- Author new tests (validator — the coder *runs* tests but does
  not author them)
- Review its own code (reviewer)
- Approve releases (deployer)
- Make architecture decisions (architect — if a decision is needed,
  the `actual-adr-check` step hands the work back)

## The actual-skill

This pack vendors the upstream
[actual-software/actual-skill](https://github.com/actual-software/actual-skill)
under `overlays/default/.claude/skills/actual/`. The coder reads
the rig's generated rules via `actual status` and refuses to code
against stale ADRs — instead it files a `needs-architecture` bead
back to the architect.

To re-vendor the skill:
```bash
./scripts/sync-actual-skill.sh
```

## How to run

As part of the full factory:
```bash
gc rig add /path/to/your/project
gc start software-factory/packs/
```

Standalone:
```toml
# city.toml
[workspace]
includes = ["software-factory/packs/coder"]
```

Manual dispatch against a specific bead:
```bash
./commands/build.sh <bead-id>
# or:
gc sling <rig>/coder --bead <bead-id> --on mol-code-from-spec
```

## Handoff

- **reviewer** via `needs-review` (forward)
- **architect** via `needs-architecture` (hand-back if ADRs drift)
