# Test Harness

The harness verifies the formula-first lesson architecture from static checks through live walkthroughs.

| Harness | What it proves | Live LLMs? |
|---|---|---|
| `lesson-pack-lint.py` | Active content and lesson packs match `specs/content-architecture.md` | no |
| `migration-check.sh` | PackV2 directory conventions and TOML sidecars are valid | no |
| `tutorial-check.sh` | Student command flow dry-runs for L2-L4/C1 | no |
| `behavioral-smoke.sh` | Runs lint, structure checks, and dry-run walkthroughs together | no |
| `tutorial-walkthrough.sh` | Real agents move work through the lesson formula and produce artifacts | yes |

## Static Lint

```bash
test-harness/lesson-pack-lint.py --lesson L2 --lesson L3 --lesson L4 --lesson C1
```

The linter checks:

- self-contained `packs/lessons/<lesson>/` packs
- rig-scoped agents
- FormulaV2 `contract = "graph.v2"` formulas
- binding-qualified routes such as `factory.planner`
- graph-worker prompt sections
- curriculum-blind pack internals
- student docs that show active lesson selection, existing-rig sync, and one `gc sling` entrypoint

## Structure Check

```bash
bash test-harness/migration-check.sh
```

This verifies PackV2 filesystem conventions: `agents/<role>/agent.toml`, `prompt.template.md`, command sidecars, doctor sidecars, formula filenames, and absence of old v1 directory shapes.

## Dry-Run Walkthrough

```bash
bash test-harness/tutorial-check.sh
```

This invokes the live walkthrough dispatcher with `TUTORIAL_WALKTHROUGH_DRY_RUN=1`. It validates the factory selection, rig import sync, and formula entrypoint command shapes without spawning provider sessions.

## Live Walkthrough

```bash
bash test-harness/tutorial-walkthrough.sh L2
bash test-harness/tutorial-walkthrough.sh L3
bash test-harness/tutorial-walkthrough.sh L4
bash test-harness/tutorial-walkthrough.sh C1
```

With no lesson arguments, the dispatcher runs `L2 L3 L4 C1` in order.

Live runs:

- create an isolated scratch city
- add the calculator fixture as a rig
- select the lesson pack as `factory`
- start the entry formula with `gc sling <rig>/factory.planner ... --on <formula>`
- watch for artifacts, commits, validation reports, reviews, and release gates

The harness logs progress and heartbeats. While a run is active, inspect it with:

```bash
gc events --follow
gc session list
gc session peek rig/factory.planner
gc graph <workflow-bead-id>
```

## Adding A Lesson

1. Add a contract under `test-harness/lesson-contracts/<id>.toml`.
2. Add a self-contained pack under `packs/lessons/<id>/`.
3. Add a walkthrough script under `test-harness/walkthroughs/<id>.sh`.
4. Add the lesson to `ALL_LESSONS` in `tutorial-walkthrough.sh`.
5. Make `lesson-pack-lint.py`, `tutorial-check.sh`, and the live walkthrough pass.
