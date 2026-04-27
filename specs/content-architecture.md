# Content Architecture: Self-Contained Lesson Packs

## Summary

The Software Factory Intensive should teach Gas City through self-contained
PackV2 lesson packs. Each lesson pack is a complete, runnable, inspectable
factory for that lesson, even when that duplicates agents, formulas, prompts,
skills, and support files from earlier lessons.

The top-level folder or pack name may use the curriculum identifier for
navigation, such as `packs/lessons/L2` or `name = "sfi-l2"`. Inside that pack,
runtime definitions must read like a small portable factory someone could take
home: no agent prompt, formula description, doctor, command, or pack README
should say it is running "L2", a lesson, a lab, a workshop, or a curriculum
exercise. That framing belongs in the user-facing tutorials only.

The primary student path should be:

```text
pick lesson pack -> restart city -> sling one request -> formula routes work
```

The student path should not be:

```text
create labelled bead -> order scans label -> helper command wakes downstream ->
agent prompt polls label -> formula relabels bead -> repeat
```

This spec optimizes for teaching. The old shared/manual/label pack topology is
not a reference architecture to preserve in active repo paths. Git history is
the archive for that version of the material. The active repository should move
to self-contained lesson packs and formula-native content.

## Teaching Goals

The content should make these concepts obvious in this order:

1. A pack is the unit of factory definition.
2. A lesson pack contains the factory being taught.
3. A formula is the workflow.
4. Agents execute formula steps.
5. Routing is defined by the formula and pack configuration.
6. Beads are the runtime records of work.
7. Labels are metadata for search, provenance, reporting, and human triage.
8. The same project rig carries artifacts forward across lessons.

The curriculum should minimize CLI surface area until the student has a reason
to learn more. The pack should carry defaults; students should not have to pass
five flags to express a concept the pack already knows.

## Current Problem

The current material optimizes for reusable pack composition, not learning.
The runtime is assembled from reusable leaf packs plus `packs/all`.

That makes one lab difficult to inspect:

- agents are split across separate leaf packs
- formulas live inside those leaf packs
- orders watch stage labels
- formulas create or relabel downstream beads
- `gc all wake-downstream` scans labels and slings work
- activities can override selected packs
- `my-factory` controls which pack graph is active

The visible workflow language becomes labels:

- `needs-architecture`
- `needs-plan`
- `needs-design`
- `needs-tests`
- `ready-to-build`
- `needs-review`
- `ready-to-ship`

Those labels are doing work that formulas can express directly through steps,
dependencies, conditions, fanout, checks, retries, and routing metadata.

## Architecture Decision

Create first-class lesson packs under `packs/lessons/`:

```text
packs/
  lessons/
    W1/
    W2/
    W3/
    W4/
    L1/
    L2/
    L3/
    L4/
    C1/
```

All active content in this repository is in scope: workshops, labs, capstone,
curriculum mirrors, activity READMEs, reference artifacts, `my-factory`, packs,
and harnesses. Some workshops are design-only and do not need a runtime pack,
but they still must teach the same content architecture and must not preserve
the old leaf-pack, label-handoff, or `default_rig_includes` model.

Runtime-heavy lessons should move first:

1. `L2`
2. `L3`
3. `L4`
4. `C1`
5. `W3` formula-design content
6. `W4` feedback-loop content
7. `W2` factory-design content
8. `W1` workflow-card content

Each lesson pack must be self-contained. It must not import earlier lesson packs
or shared agent leaf packs. If L3 needs planner, architect, designer, and
builder agents, L3 contains its own copies of those definitions.

This duplication is intentional. Students should be able to open one folder and
understand the entire factory they are about to run.

Students should keep the same project rig across lessons. L2 creates early
planning and architecture artifacts, L3 consumes and extends them through
design/build work, L4 reviews and release-checks the same project history, and
C1 runs an end-to-end feature against the accumulated rig state.

## PackV2 Implementation Facts

PackV2 is convention-based. The pack directory structure is the declaration.
Use standard definition subdirectories:

```text
pack.toml
agents/
formulas/
orders/
commands/
doctor/
overlay/
skills/
mcp/
```

Prompt and resource directories have different semantics:

```text
template-fragments/
assets/
```

Current implementation details that affect lesson design:

- `agents/<name>/` creates an agent by convention.
- `agents/<name>/prompt.template.md` is the canonical templated prompt name.
- `agents/<name>/overlay/` is the agent-local overlay directory.
- formulas live in top-level `formulas/`.
- new orders live in top-level `orders/<name>.toml`.
- commands live in `commands/<name>/run.sh`.
- doctors live in `doctor/<name>/run.sh`.
- `template-fragments/` files are prompt resources referenced by prompt config;
  they are not standalone runtime definitions.
- `assets/` files are opaque resources reached by explicit references; they
  are not auto-wired as lesson behavior.
- `[defaults.rig.imports]` is implemented in the city root `pack.toml` and is
  the primary active-factory switching mechanism.
- supported pack scopes are `city` and `rig`.
- FormulaV2 is still feature-gated by `[daemon] formula_v2 = true`, but this
  curriculum treats that as a permanent city prerequisite, not a per-lesson
  option.

Design implication: core lesson workflow should not depend on pack commands.
Commands are useful convenience tools, but formulas should carry the workflow.

## Formula Version Policy

Use FormulaV2 syntax for all active lesson formulas, starting with the first
lesson that introduces formulas. Do not teach FormulaV1 as the beginner syntax
and then ask students to switch halfway through the course.

This is a curriculum policy, not a claim that every lesson needs every
FormulaV2 feature. A simple FormulaV2 formula is only slightly more syntax than
a simple FormulaV1 formula:

```toml
formula = "mol-feature-intake"
version = 2
contract = "graph.v2"

[[steps]]
id = "intake"
title = "Read the request"

[[steps]]
id = "summarize"
title = "Summarize the desired outcome"
needs = ["intake"]
```

The teaching progression should add one concept at a time:

- first formula lesson: `version = 2`, `contract = "graph.v2"`, simple steps
- dependency lesson: `needs = [...]`
- multi-agent lesson: `metadata = { "gc.run_target" = "factory.planner" }`
- larger workflow lesson: `children` only if grouping makes the graph clearer
- validation/retry lesson: `check` or `retry` only if the lesson explicitly
  teaches runtime validation
- optional-path lesson: `condition` only if the lesson needs a clear branch

Do not introduce `loop`, dynamic `on_complete` fanout, formula expansion,
advice, scopes, cleanup controls, or dispatcher internals in the first pass.
Those are advanced Gas City features, not prerequisites for understanding
packs, formulas, agents, and beads.

FormulaV1 should not remain in active student-path material. Git history is the
archive for old FormulaV1 examples.

## Lesson Pack Contract

Every runtime lesson pack should satisfy this contract:

- has `pack.toml`
- has `README.md`
- has every agent required for the lesson under `agents/`
- has every formula required for the lesson under `formulas/`
- uses FormulaV2 syntax for active lesson formulas
- does not import shared packs
- does not require `packs/all`
- has doctor checks for factory readiness
- starts from one documented `gc sling` command
- uses labels only as metadata
- uses formulas for workflow structure and stage progression

Example L3 shape:

```text
packs/lessons/L3/
  README.md
  pack.toml
  agents/
    planner/
      agent.toml
      prompt.template.md
      overlay/
    architect/
      agent.toml
      prompt.template.md
      overlay/
    designer/
      agent.toml
      prompt.template.md
      overlay/
    builder/
      agent.toml
      prompt.template.md
      overlay/
  formulas/
    mol-feature-delivery.toml
  doctor/
    factory-ready/
      doctor.toml
      run.sh
  commands/
    status/
      command.toml
      run.sh
  skills/
  template-fragments/
```

## `pack.toml` Shape

Minimal:

```toml
[pack]
name = "sfi-l3"
schema = 2
```

Use `[agent_defaults]` only for fields the runtime applies reliably and that
make student commands simpler:

```toml
[agent_defaults]
default_sling_formula = "mol-feature-delivery"
```

Avoid legacy declarations:

- no `[[agent]]`
- no `[formulas]`
- no `[[commands]]`
- no `[[doctor]]`
- no `pack.includes`

Do not set `append_fragments = ["graph-worker"]`. The graph worker prompt is a
built-in FormulaV2 fallback, not a file in `template-fragments/`. Use
`append_fragments` only for local fragment filenames that actually exist in the
pack's `template-fragments/` directories.

## Agent Shape

Keep each agent's essential configuration local:

```toml
scope = "rig"
wake_mode = "fresh"
max_active_sessions = 1
default_sling_formula = "mol-feature-delivery"
nudge = "Run gc prime, then work the assigned formula step."
```

Avoid teaching custom `work_query` and `sling_query` in normal lessons. Default
routing is sufficient for the beginner path. Introduce custom routing only in a
lesson that is explicitly about routing internals.

Prompt guidance should fit graph-first work:

- find assigned or routed work
- read the current bead
- execute exactly the current formula step
- close the current step when the work is done
- record pass/fail or request-changes information as metadata or artifacts
- briefly check for more assigned work
- drain when idle

Do not tell agents to poll `bd ready --label=<stage>` forever.

Dependency readiness is based on prerequisite beads being closed. A failed or
request-changes result does not automatically choose a different graph path.
Branching, retry, or validation behavior must be modeled with explicit
`check`, `retry`, `condition`, or student-driven re-sling instructions.

### Reference Prompt Structure

Every runtime `agents/<name>/prompt.template.md` should adapt the same
graph-worker-style structure. Role-specific judgment, taste, and quality bars
belong inside that structure; the work loop should not be redesigned per agent.

Required sections:

1. `Role`: the agent's factory role, scope of authority, and quality bar.
2. `Inputs`: current formula step, current bead, upstream artifacts, project
   files, and any domain or pack-local context the agent should read.
3. `Graph Work Process`: inspect assigned/routed work, execute only the current
   step, read prerequisite artifacts, write the expected artifact, and avoid
   creating downstream stage beads or labels.
4. `Output Format`: artifact paths, summary, decisions, risks, and handoff
   notes expected by the next formula step.
5. `Close Behavior`: close the current step when complete, record useful
   metadata or review findings, do not relabel the bead, and do not run
   `gc all wake-downstream`.

Prompts may mention labels only as metadata for search, provenance, or human
triage. They must not instruct agents to poll label queues, add stage labels, or
wake downstream agents manually.

Prompts must also be curriculum-blind. Do not tell an agent that it is "the L2
Planner", "running a workshop", helping "students", or following "lab"
instructions. The same prompt should make sense if copied into a small real
project factory.

## Formula-Native Workflow

The curriculum should teach formulas as the workflow language from the first
formula lesson. Formula graphs should own:

- stage order
- dependencies
- parallelism
- per-step routing

Introduce advanced graph features only when the lesson needs them:

- `condition` for simple optional paths
- `children` for grouping larger graphs
- `check` or `retry` for validation and retry behavior
- gates or dynamic fanout only after the core factory concepts are already
  clear and the installed Gas City version is reliable for the classroom path

Formula step descriptions still contain judgment. The formula should not try to
replace the agent's judgment. It should express the workflow structure around
that judgment.

Recommended entry formula:

```toml
formula = "mol-feature-delivery"
version = 2
contract = "graph.v2"
description = "Run the L3 factory from feature request to implemented change."

[[steps]]
id = "plan"
title = "Break the feature into implementation work"
metadata = { "gc.run_target" = "factory.planner" }

[[steps]]
id = "architecture"
title = "Choose the technical approach"
needs = ["plan"]
metadata = { "gc.run_target" = "factory.architect" }

[[steps]]
id = "design"
title = "Design the UI and interaction changes"
needs = ["architecture"]
metadata = { "gc.run_target" = "factory.designer" }

[[steps]]
id = "build"
title = "Implement the approved design"
needs = ["design"]
metadata = { "gc.run_target" = "factory.builder" }
```

Use formula features before shell workarounds:

- `needs` for dependencies
- `metadata.gc.run_target` for agent routing
- `children` for nested work when it simplifies a large lesson graph
- `condition` for optional steps when a lesson needs an explicit branch
- `check` or `retry` for validation and retry behavior in lessons that teach it

Avoid this pattern:

```text
builder closes bead
builder adds needs-review label
builder calls gc all wake-downstream
wake-downstream finds needs-review
wake-downstream slings bead to reviewer
reviewer formula runs
```

Prefer:

```text
formula step build completes
formula step review becomes ready because it depends on build
review step is routed to reviewer
review records pass or request-changes as an artifact
```

If a lesson needs runtime branching from review output, that branch must be an
explicit FormulaV2 construct. The default L4 rework loop should be
student-driven: students read the review, edit the builder configuration or
artifact, and sling the same formula again.

## Simplest Student CLI

The pack should capture as much as possible so the student command is short.

Preferred:

```bash
gc sling <rig>/factory.planner "Build user profile editing"
```

This is the target when `default_sling_formula` is configured on the entry
agent.

Acceptable when the lesson needs explicit formula attachment:

```bash
gc sling <rig>/factory.planner "Build user profile editing" --on mol-feature-delivery
```

Avoid as the normal student path:

```bash
bd create --title "Build user profile editing" --label needs-plan
gc sling --nudge <rig>/factory.planner <bead-id>
```

That path teaches bead creation, stage labels, and explicit routing before the
student has seen the factory concept.

Introduce `bd` after the first run, when students inspect what Gas City created:

```bash
gc events --follow
bd list
bd show <bead-id>
gc graph <bead-id>
```

## Lesson Switching

FormulaV2 is enabled once in `my-factory/city.toml`:

```toml
[daemon]
formula_v2 = true
```

Students switch lessons by editing the city root `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

This is city-wide active lesson selection. It is the source of truth for which
factory pack should be active across the city.

The agents inside each lesson pack remain rig-scoped:

```toml
scope = "rig"
```

With the import binding named `factory`, students address the imported agents as
`<rig>/factory.<agent>`, for example:

```bash
gc sling <rig>/factory.planner "Build user profile editing"
```

Current Gas City copies root default rig imports into a rig when `gc rig add`
creates that rig. Because students keep the same rig from lesson to lesson, the
docs and checks must include an existing-rig sync step after changing the
active lesson. The synced rig import should match the city-wide factory
selection:

```toml
[rigs.imports.factory]
source = "../packs/lessons/L3"
```

Student-facing docs should make that sync concrete. For L2, where the rig may
not yet have a factory import:

```bash
gc --rig <rig> import add ../packs/lessons/L2 --name factory
```

For L3 and later, where the same rig already has a previous factory import:

```bash
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L3 --name factory
```

If a lesson must expose city-scope commands, add an explicit city import as a
separate, documented exception:

```toml
[imports.factory]
source = "../packs/lessons/L3"
```

Core lesson flow should not require that exception. Do not use
`default_rig_includes` in new student-facing material.

Then:

```bash
cd my-factory
gc restart
gc doctor
```

## Labels

Labels are useful for:

- provenance, such as `source:github`, `source:jira`, or `lesson:L3`
- search and reporting, such as `frontend`, `security`, or `high-risk`
- human triage, such as `needs-info` or `blocked-by-user`
- external tools that only understand labels
- demo visibility where a visible tag helps students inspect state

Labels should not be required to determine the next workflow stage when a
formula graph already knows that.

Avoid labels whose primary meaning is "route this to the next factory stage":

- `needs-plan`
- `needs-architecture`
- `needs-design`
- `needs-tests`
- `ready-to-build`
- `needs-review`
- `ready-to-ship`

If removing a label changes the workflow, the design is still label-driven.

## Orders

Use orders for real triggers:

- cooldown work
- cron work
- tracker sync
- external event handling
- optional manual dispatch

Do not use orders as the main stage-to-stage dispatch mechanism inside a
lesson factory.

Bad lesson-default pattern:

```toml
[order]
trigger = "condition"
check = "bd ready --label=needs-review --limit=1 | grep -q ."
formula = "mol-code-review"
pool = "reviewer"
```

Better lesson-default pattern:

```toml
[[steps]]
id = "review"
needs = ["build"]
metadata = { "gc.run_target" = "factory.reviewer" }
```

## Commands

Commands are allowed, but they should be optional convenience.

Good command uses:

- lesson-local graph status
- show lesson artifacts
- reset lesson scratch files
- import demo tickets

Bad command use:

- scan labels and wake downstream agents
- report only label queues as lesson status
- implement the workflow scheduler
- hide required behavior outside formulas

## Doctors

Every runtime lesson pack should include at least one doctor check.

Recommended checks:

- `formula_v2` enabled in `city.toml`
- required agents discovered
- entry formula discovered
- required binaries available
- bead store initialized
- expected lesson artifact directories writable

Doctor output should teach the pack boundary: "this factory pack is loaded and
ready."

## Duplication Policy

Duplication is intentional in lesson packs.

Do not optimize lesson packs for DRY. Optimize them for:

- readability
- local reasoning
- resetability
- predictable student outcomes
- direct comparison between lessons

Rules:

- a lesson pack must run standalone
- a lesson pack must not require students to inspect another pack
- duplicated content may be simplified to fit the lesson goal
- changes to copied content must be reviewed per lesson
- lesson READMEs should explicitly say duplication is deliberate

Later, if maintenance cost becomes too high, generate lesson packs from shared
sources. Generated lesson packs should still be concrete folders that students
can inspect.

## Curriculum Guidance

### W1

Teaching focus: single-agent workflow discipline.

Recommended rewrite:

- remains design-only unless a future exercise runs a factory
- workflow card maps forward to `Role`, `Inputs`, `Graph Work Process`,
  `Output Format`, and `Close Behavior`
- references active lesson prompt paths under `packs/lessons/*`, not shared
  leaf packs as the student runtime surface
- does not describe W3/W4 as an orchestrator or label system

### W2

Teaching focus: factory design before runtime execution.

Recommended rewrite:

- remains design-only unless paired with a runtime demonstration pack
- deliverable is a factory wiring table for self-contained lesson packs
- maps roles to lesson-local agents and FormulaV2 graph steps, not shipped leaf
  packs
- names artifact contracts and prompt sections using the shared prompt
  structure
- does not tell students that L2 adds shared packs through `city.toml`

### L2

Teaching focus: first real factory with planner and architect.

Recommended runtime:

- one self-contained L2 pack
- one FormulaV2 entry formula
- planner and architect agents included locally
- no `packs/all`
- no activity-pack override instructions
- one `gc sling` entry command

Minimum formula graph:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |

### L3

Teaching focus: design and build workflow.

Recommended runtime:

- L3 pack duplicates L2 planner/architect if still needed
- adds designer and builder locally
- formula routes plan -> design -> build
- build step depends on design or explicit skip condition

Minimum formula graph:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |

### L4

Teaching focus: review and release control.

Recommended runtime:

- L4 pack duplicates needed prior agents
- adds reviewer and release-gate locally
- formula runs a linear review/release pipeline
- reviewer records pass or request-changes as an artifact
- request-changes rework is student-driven unless the lesson explicitly teaches
  `check`, `retry`, or `condition`

Minimum formula graph:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |
| `review` | `build` | `factory.reviewer` |
| `release-check` | `review` | `factory.release-gate` |

### W3

Teaching focus: coordination.

Recommended rewrite:

- teach formula graph design directly
- deliverable is a FormulaV2 graph design: step table, dependencies,
  `gc.run_target` routing, artifact contract, and any chosen `check`, `retry`,
  or `condition`
- gates are formula steps/checks/retries when the lesson specifically needs
  runtime validation
- rejection paths require explicit formula constructs or a documented
  student-driven re-sling loop
- keep `orchestrator.yaml` only as a comparison artifact if useful

### W4

Teaching focus: continuous improvement loops.

Recommended rewrite:

- feedback rules update the active lesson pack prompt copy, manifest, or
  formula artifact contract
- rule files name the exact lesson-local prompt path under `packs/lessons/*`
- reactive and aggregate loops are documented as config changes followed by a
  re-sling, not as edits to shared shipped packs
- external loops start a new formula run through the lesson entrypoint
- no references to `default_rig_includes`, copied activity packs, or old
  prompt-template paths

### C1

Teaching focus: end-to-end factory run.

Recommended runtime:

- one C1 pack
- one capstone formula
- one initial `gc sling`
- formula instantiates or attaches all major stages
- run report records formula state and artifacts, not manual stage bead setup
- `reference-project/fired-up-pizza` is the project input; `packs/lessons/C1`
  is the factory that operates on it

Minimum formula graph:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |
| `validate` | `build` | `factory.validator` |
| `review` | `validate` | `factory.reviewer` |
| `release` | `review` | `factory.release-gate` |

## Migration Path

1. Lock this spec as the target architecture.
2. Rewrite `plans/port-to-packs-v2.md` around lesson packs, not format-only
   migration.
3. Create `packs/lessons/L2` as proof of shape.
4. Update L2 docs to switch one factory import and run one `gc sling`.
5. Validate the runtime on a clean factory.
6. Repeat for L3, L4, and C1.
7. Rework W1-W4 around the same architecture.
8. Remove `packs/all`, label handoff, and activity override instructions from
   the primary student path.
9. Delete or replace the old shared/manual/label pack topology from active repo
   paths; git history is the archive.

## Maintenance Checks

Add checks that enforce the teaching architecture. The primary static guard is
the lesson-pack linter:

```bash
run the lesson pack linter for L2 without the repository scan
run the lesson pack linter for L2
run the full lesson pack linter
```

The linter reads the lesson contracts and validates the
lesson pack shape, FormulaV2 graph, binding-qualified routes, artifact
contracts, graph-worker prompt sections, root lesson selection, existing-rig
sync docs, and stale label/manual-pack patterns. Use it as the red-green driver
for each lesson migration.

Supporting checks should still enforce pack layout:

```bash
find packs/lessons -name pack.toml -print
find packs/lessons -path '*/agents/*/agent.toml' -print
find packs/lessons -path '*/formulas/*.toml' -print
```

Search for old control-plane patterns:

```bash
rg 'gc all wake-downstream|bd ready --label|bd create .*--labels?|needs-plan|needs-architecture|ready-to-build|needs-review|ready-to-ship' \
  curriculum activities activites packs/lessons my-factory
```

Expected result: no active lesson-path matches.

Search for FormulaV1 in active lesson packs:

```bash
rg 'version\s*=\s*1' packs/lessons
```

Expected result: no matches.

Search for stale lesson switching:

```bash
rg 'default_rig_includes|workspace scope|scope = "workspace"|bd dep graph|append_fragments = \["graph-worker"\]' \
  README.md curriculum activities activites my-factory packs reference-project
```

Expected result: no active student-path matches. Historical comparison callouts
must be clearly labeled.

Check the root factory wiring:

```bash
rg '^\[daemon\]|formula_v2\s*=\s*true' my-factory/city.toml
rg '^\[defaults\.rig\.imports\.factory\]|source\s*=\s*"\.\./packs/lessons/' my-factory/pack.toml
```

## Acceptance Criteria

This architecture is successful when:

- each runtime lab can run from a single lesson pack
- students can inspect one folder and see all runtime definitions for that lab
- FormulaV2 is enabled once in `my-factory/city.toml`
- switching lessons uses city-wide selection in `my-factory/pack.toml` plus an
  existing-rig sync step for the same project rig
- starting a lesson requires one simple `gc sling` command
- active lesson formulas use `version = 2` and `contract = "graph.v2"`
- lesson packs do not depend on `packs/all`
- stage progression is visible in formulas
- labels remain metadata, not the workflow state machine
- `gc all wake-downstream` is absent from lesson-critical flow
- W3 and C1 no longer teach manual stage-labelled bead creation as the ideal
- skipping ahead to L3 or L4 still produces a working lesson environment

## Non-Goals

This spec does not require:

- renaming `activites/`
- fixing upstream Gas City command exposure
- fixing upstream skill materialization
- remote pack imports
- using every FormulaV2 feature in the first formula lesson
- performing the full migration in one atomic commit

The first concrete step is to make lesson-pack composition explicit and
self-contained. Active lesson formulas should be FormulaV2; old FormulaV1 and
label-dispatch material should leave active repo paths as each lesson migrates.
