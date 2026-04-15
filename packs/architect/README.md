# actual-architect

The **Architect** agent of the Actual Software Factory. One of eight
Agent-Operation packs under `examples/actual/`. Maps to the
"Architect" operation at https://www.actual.ai/softwarefactory.

## Persona

Principal Engineer + Solutions Architect. Prioritizes simplicity over
cleverness. Documents the *why* behind decisions. Thinks in trust
boundaries, access controls, guardrails, and end-to-end trade-offs.
Anchor personas are defined in
`actual-factory/extensions/factory-vscode/shared/actual-agents/built-in-agents.ts`.

## What it does

- Reads beads labelled `needs-architecture`
- Uses the bundled **actual** skill to run `actual adr-bot` and keep
  `CLAUDE.md` / `AGENTS.md` in sync with the rig's ADRs
- Writes one-page guardrail rules under `.actual/rules/<topic>.md`
- Hands off to the **planner** by creating child beads with the
  `needs-plan` label

## What it does NOT do

Write implementation code. Decompose work. Run CI. Review PRs.

## How to run

As part of the full factory:
```bash
gc rig add /path/to/your/project
gc start examples/actual/
```

Standalone (just this agent):
```bash
# add to a city.toml:
# [workspace]
# includes = ["examples/actual/architect"]
```

Manual dispatch of the formula against a specific bead:
```bash
gc sling <rig>/architect --on mol-architect-review \
    --var topic=auth-boundaries
```

## Pack contents

| File | Purpose |
|------|---------|
| `pack.toml` | Agent + formulas + orders + doctor + commands declaration |
| `prompts/architect.md.tmpl` | The Principal-Engineer persona prompt |
| `formulas/mol-architect-review.formula.toml` | 5-step review workflow |
| `formulas/orders/architect-guardrail-check/order.toml` | Condition-gated auto-dispatch |
| `doctor/check-architect.sh` | Verifies `bd`, `gc`, `git`, `jq`, and (optional) `actual` |
| `commands/status.sh` | Shows architect work queue |
| `commands/rules.sh` | Lists rules under `.actual/rules/` |
| `scripts/sync-actual-skill.sh` | Author tool: re-vendor upstream actual-skill |
| `overlays/default/.claude/skills/actual/` | Vendored upstream actual-skill |

## Updating the vendored actual-skill

The `overlays/default/.claude/skills/actual/` tree is a verbatim copy
of `skills/actual/` from
[actual-software/actual-skill](https://github.com/actual-software/actual-skill).
When upstream publishes a new version:

```bash
./scripts/sync-actual-skill.sh            # pulls main
./scripts/sync-actual-skill.sh v1.2.3     # pins to a tag
git diff -- overlays/default/.claude/skills/actual
```

Review and commit the diff.

## Handoff protocol

```
architect (this pack)  →  planner  →  designer/validator  →  builder
                                                                ↓
                                                             reviewer
                                                                ↓
                                                          release-gate
                                                                ↓
                                                            improver
                                                                ↓
                                                           (loop back)
```

Each step advances via a label change on the bead. No Go code, no
hardcoded pipeline — just beads and label-matching order gates.
