# L1 · Build a Structured Development Loop — Activity

**Walkthrough:** [`../../../curriculum/labs/L1/README.md`](../../../curriculum/labs/L1/README.md)

L1 converts your W1 workflow card into agent-readable config and registers your project with Gas City.

## Deliverables

You will create or update these files:

- The relevant agent instruction file (ex. `CLAUDE.md` for Claude Code, `AGENTS.md` for OpenCode/Codex CLI/etc.) in your project rig — converted from your W1 workflow card with project-specific rules, commands, and safety boundaries.
- `docs/PROJECT_MANIFEST.md` with overview, tech stack, and project structure. Review Standards and Release Criteria are added before L4 and C1 respectively.

## Factory State After L1

`my-factory` should be registered, formula v2 should be enabled in `city.toml`, and your project should be added as a rig:

```bash
cd ../../../my-factory
gc register .
gc rig add /path/to/your-project
gc doctor --fix
```

No feature workflow runs in L1. The first runnable formula flow starts in L2.

## Exit Criteria

- [ ] The relevant agent instruction file (ex. `CLAUDE.md` for Claude Code, `AGENTS.md` for OpenCode/Codex CLI/etc.) exists in the project rig with project-specific rules.
- [ ] `docs/PROJECT_MANIFEST.md` has overview, tech stack, and project structure.
- [ ] `my-factory/city.toml` enables formula v2.
- [ ] `my-factory/pack.toml` selects `../packs/lessons/L2` as `factory`.
- [ ] `gc status` from `my-factory/` shows the city and rig.
