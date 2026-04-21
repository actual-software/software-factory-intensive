# actual-planner

The **Planner** agent of the Actual Software Factory. One of the
Agent-Operation packs under `examples/actual/`. Maps to the first
stage of the pipeline — translating feature requests into formal
Product Requirements Documents.

## Persona

Product Manager. Translates feature requests into clear, measurable
requirements. References the project manifest for all technical
constraints. Ensures downstream agents have the context they need.
Anchor personas are defined in
`actual-factory/extensions/factory-vscode/shared/actual-agents/built-in-agents.ts`.

## What it does

- Reads beads labelled `needs-plan`
- Reads `docs/PROJECT_MANIFEST.md` for tech stack, domain model,
  conventions, and project scope
- Writes a formal PRD at `docs/PRD.md`
- Hands off to the **architect** by creating child beads with the
  `needs-architecture` label
- Hands off to the **designer** by creating child beads with the
  `needs-design` label

## What it does NOT do

Write implementation code. Make architecture decisions. Design UI/UX.
Decompose work into tasks. Run CI. Review PRs.

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
# includes = ["examples/actual/planner"]
```

Manual dispatch of the formula against a specific bead:
```bash
gc sling <rig>/planner --on mol-planner-prd \
    --var slug=user-profiles
```

## Pack contents

| File | Purpose |
|------|---------|
| `pack.toml` | Agent + formulas + orders + doctor + commands declaration |
| `prompts/planner.md.tmpl` | The Product-Manager persona prompt |
| `prompts/planner.md` | Standalone prompt (no gc template vars) |
| `formulas/mol-planner-prd.formula.toml` | 4-step PRD workflow |
| `formulas/orders/planner-intake/order.toml` | Condition-gated auto-dispatch |
| `doctor/check-planner.sh` | Verifies `bd`, `gc`, `git`, `jq` |
| `commands/status.sh` | Shows planner work queue |
| `scripts/sync-actual-skill.sh` | Author tool: re-vendor upstream actual-skill |
| `overlays/default/.claude/skills/actual/` | Vendored upstream actual-skill |

## Handoff protocol

```
planner (this pack)  →  architect  →  pm  →  designer/validator  →  builder
                     →  designer                                       ↓
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
