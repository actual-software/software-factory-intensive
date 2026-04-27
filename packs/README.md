# Packs

The active runtime packs for this curriculum live under `packs/lessons/`.

Each runnable lesson pack is a complete Gas City pack factory:

```text
packs/lessons/<lesson>/
├── pack.toml
├── agents/
├── formulas/
├── commands/
└── doctor/
```

Lesson packs do not import other packs. If a later lesson needs the same planner or builder role, it carries a local copy of that role definition. The duplication is deliberate: students should be able to inspect one folder and understand the whole factory they are running.

## Active Lesson Packs

| Pack | Purpose |
|---|---|
| `lessons/L2` | Planner and Architect factory for plan and architecture artifacts |
| `lessons/L3` | Adds Designer and Builder for design plus implementation |
| `lessons/L4` | Adds Reviewer and Release-Gate for review and release decisions |
| `lessons/C1` | End-to-end release factory with validation, review, and gate artifacts |

## Optional Support Pack

`workshop/` contains optional service-integration helpers. It is not the workflow engine for the lessons. Runnable lesson flow belongs in the selected lesson pack and its formula graph.

## Authoring Rules

- Use pack conventions: `agents/`, `formulas/`, `commands/`, `doctor/`.
- Use formula v2 for every workflow formula: `version = 2` and `contract = "graph.v2"`.
- Route graph steps with binding-qualified targets such as `factory.builder`.
- Keep agent prompts portable and curriculum-blind.
- Do not use stage labels as the workflow engine.
- Do not rely on a separate composition layer for lesson-critical behavior.
