# Port Curriculum to PackV2 Lesson Packs

## Status

This plan replaces the earlier format-only PackV2 migration plan.

The old plan treated the existing reusable leaf packs, `packs/all`, stage
labels, label-gated orders, and `gc all wake-downstream` as the desired runtime
shape. That is no longer the target. The target is a curriculum-first PackV2
architecture:

- each runtime lesson has one self-contained pack
- the lesson pack contains the full factory for that lesson
- formulas express workflow structure
- labels are metadata, not the control plane
- student commands stay minimal because the pack carries the defaults

The pack folder and pack name may carry the curriculum identifier for clarity,
for example `packs/lessons/L2` and `name = "sfi-l2"`. Runtime definitions
inside the pack must not. Agent prompts, formulas, doctors, commands, overlays,
and pack READMEs should read like a small real-world factory that can be reused
outside the workshop. Lesson numbers, lab language, workshop framing, and
student/facilitator instructions belong only in tutorial Markdown and internal
checks.

## Decision Summary

Recommended decision: build self-contained lesson packs under
`packs/lessons/<lesson>/` and make those the primary student runtime surface.

The existing reusable leaf packs and `packs/all` are migration inputs, not
fallback runtime targets. The final active repo path removes the old
manual/label pack architecture; git history is the archive for that material.

Recommended student mental model:

```text
choose lesson pack -> restart city -> sling one request -> formula routes work
```

Not:

```text
create stage-labelled bead -> order sees label -> command scans labels ->
sling downstream agent -> downstream prompt polls label queue
```

## What PackV2 and FormulaV2 Actually Want

PackV2 is convention-loaded. A pack is a directory with a `pack.toml` plus
standard definition subdirectories such as:

```text
agents/
formulas/
orders/
commands/
doctor/
overlay/
skills/
mcp/
```

The pack directory is the definition. `agents/foo/` defines an agent. A formula
file in `formulas/` defines a formula. Top-level `orders/*.toml` defines
orders. Students should be able to inspect one pack folder and see what runs.

`template-fragments/` and `assets/` are supporting resources with different
semantics. Template fragments are prompt resources referenced by prompt config.
Assets are opaque files reached by explicit references. Neither should be
described as a standalone runtime definition like agents or formulas.

FormulaV2 is graph-capable. It supports dependencies, children, loops,
conditions, checks, retries, dynamic follow-on bonding, graph routing, and
per-step metadata. That means the formula can carry the factory flow instead
of delegating the flow to labels and shell scripts.

For graph-first lesson workflows:

```toml
formula = "mol-feature-delivery"
version = 2
contract = "graph.v2"
```

and the city needs:

```toml
[daemon]
formula_v2 = true
```

This is a one-time city prerequisite in `my-factory/city.toml`, not a
per-lesson opt-in. The active factory import belongs in the city root
`my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

This is city-wide active lesson selection. The imported factory agents remain
rig-scoped (`scope = "rig"`) because they work inside the student's project rig
and bead store. With the neutral binding named `factory`, student and formula targets are
binding-qualified: `<rig>/factory.planner`, `<rig>/factory.designer`, and
rig-relative formula metadata such as `factory.designer`.

Current Gas City applies root `[defaults.rig.imports]` when `gc rig add`
creates a rig. Students keep the same project rig across lessons, so every
lesson switch also needs an explicit sync step for the existing rig's
`[rigs.imports.factory]` entry. The teaching language should be:

- L2: "You already created your rig. Now bring in the L2 factory pack."
- L3 and later: "Keep the same rig. Update the active lesson factory pack."

Supported pack scopes are `city` and `rig`; do not document a `workspace`
scope. Do not use `default_rig_includes` in new student-facing material.

For routing a graph step to an agent, prefer:

```toml
metadata = { "gc.run_target" = "factory.designer" }
```

Do not use stage labels such as `needs-design` as the primary routing
mechanism. Formula routing resolves `gc.run_target`, stamps runtime routing
metadata, and lets Gas City's work-query/reconciler path do the rest.

Curriculum policy: active lesson formulas use FormulaV2 syntax from the first
formula lesson. This avoids teaching FormulaV1 and then forcing a dialect switch
when multi-agent routing appears. The course should still introduce FV2
gradually: simple steps first, then dependencies, then `gc.run_target`, then
larger graph features only when a lesson actually needs them.

## Issues in Current Material

### 1. The current plan is format-only

The previous migration plan preserved the existing topology: reusable leaf
packs, `packs/all`, checkpoint pack copies, label handoffs, and helper
commands. That would produce PackV2-shaped files but keep the wrong teaching
model.

New direction: PackV2 migration is also a content architecture migration.

### 2. `packs/all` hides the factory

Current docs make `packs/all` the default composition pack. It imports all
agent packs and hosts the `wake-downstream` command. This optimizes reuse, but
it makes students chase behavior through multiple packs.

Problem:

- lesson docs point at one activity
- agents live in separate packs
- formulas live in separate packs
- the flow lives partly in labels
- the dispatch command lives in `packs/all`
- the city imports `packs/all`

New direction: each lesson pack contains the lesson's whole factory. `packs/all`
must be removed from the active student runtime path. Do not keep a runnable
legacy comparison pack in the active repo surface; git history is the archive.

### 3. Stage labels are acting as the workflow engine

Current labels include:

- `needs-architecture`
- `needs-plan`
- `needs-design`
- `needs-tests`
- `ready-to-build`
- `needs-review`
- `ready-to-ship`

These are not just tags. They encode stage routing. Orders watch them, prompts
poll them, formulas add/remove them, and `wake-downstream` scans them.

New direction: formulas own stage order and dependencies. Labels remain useful
for provenance, filtering, and reporting.

### 4. Orders are used as label queue dispatchers

Current per-agent orders have checks like:

```toml
check = "bd ready --label=needs-plan --limit=1 | grep -q ."
```

That makes every stage an external queue rather than a formula step.

New direction: use orders only for real external triggers:

- cooldown/background maintenance
- cron-like sync jobs
- external tracker import
- optional manual entrypoints

Do not use orders as the normal handoff path between formula steps.

### 5. `gc all wake-downstream` is a custom scheduler

Current formulas close or relabel beads, then call:

```bash
gc all wake-downstream &
```

That command scans stage labels and slings one matching bead per downstream
agent. Older docs used `packs/all` as both a city-level composition pack and a
rig import to make that custom scheduler available.

New direction: remove this command from lesson-critical flow. Graph formulas
should make downstream steps ready directly.

### 6. Prompts tell agents to poll labels forever

Current prompts tell agents to run patterns like:

```bash
sleep 60 && bd ready --label=needs-plan
```

and never stop polling.

That is not the graph-worker model. For graph-first formulas, agents should
work the ready bead assigned or routed to them, close the current step when it
is done, record pass/fail or request-changes details in metadata or artifacts,
briefly check for more assigned work, then drain when idle.

New direction: lesson agents should use GraphV2-style prompt guidance:

- inspect assigned/routed work
- do the current step
- close the current step
- record pass/fail metadata or artifacts for humans and checks
- let closed prerequisites make dependent steps ready

Important runtime fact: dependency readiness is based on closed prerequisite
beads, not pass/fail outcome. A failed or request-changes review does not
automatically choose a different graph path. Branching, validation, retry, or
rework must be expressed through explicit `check`, `retry`, `condition`, or a
documented student-driven re-sling loop.

### 7. Formulas manually create and relabel beads

Several formulas create child beads with labels or relabel the current bead for
the next stage. For example, planner creates children with `needs-design`,
`needs-tests`, or `ready-to-build`; builder relabels to `needs-review`; reviewer
relabels to `ready-to-build` or `ready-to-ship`.

New direction: model those as formula steps, dependencies, conditions, checks,
and routes. Use step descriptions for judgment, but keep graph structure in the
formula.

### 8. W3 teaches a separate `orchestrator.yaml`

The W3 activity asks students to write an external six-stage orchestrator file
that references labels and artifact paths.

New direction: if the activity is about coordination, the coordination artifact
should be a formula or formula design review, not a parallel orchestration DSL.

### 9. Capstone creates fresh beads per stage

The capstone tells students to manually create one bead for each stage and
attach a stage label.

New direction: capstone should start with one request. The capstone formula
should instantiate or attach the planner, architect, designer, builder,
validator, reviewer, and release steps.

### 10. Activities teach pack override mechanics

The activity README currently teaches copying a shipped pack into an activity
folder, editing it, and changing rig imports to override the shipped version.

New direction: activities should produce lesson deliverables. Runtime behavior
should come from the lesson pack for that session. If a lesson asks students to
edit a pack, they edit the active lesson pack.

### 11. Current curriculum still contains v1 or stale command shapes

Examples still mention old syntax and old paths, including:

- `includes = [ ... ]`
- `[[agent]]`
- `version = 1` lesson formulas
- `prompts/<agent>.md.tmpl`
- `overlays/default`
- label-stage commands
- manual `bd create --labels <stage>`
- `gc all wake-downstream`

New direction: rewrite student-facing docs around one PackV2 import, FormulaV2
lesson formulas, and one entry command per lab.

### 12. Status commands reinforce label queues

Pack status commands currently report `bd ready --label=<stage>`.

New direction: lesson status commands should report formula/molecule state,
ready assigned work, or lesson artifacts. Do not make labels the primary status
view.

### 13. Skills and overlays are mixed with runtime workarounds

Gas City currently discovers pack-root and agent-local skill catalogs, but the
active materializer does not stage all of them consistently. The current packs
duplicate skills through agent overlay directories.

New direction: keep necessary duplicated skills inside each lesson pack's agent
overlay until upstream materialization is reliable. Document this as a runtime
compatibility workaround, not as a teaching concept.

### 14. The `activites/` checkpoint tree duplicates stale behavior

The misspelled `activites/` tree contains checkpoint copies with the same
label-driven patterns. It can be preserved temporarily for historical
checkpoint compatibility, but it should not define the new student runtime
path.

New direction: freeze `activites/` as historical checkpoint material now.
Active teaching moves to `packs/lessons/*`; docs and tests should stop treating
checkpoint copies as a parallel runtime hierarchy.

### 15. Root factory wiring is stale

Current material still talks about `default_rig_includes`, `workspace scope`,
and future support for `[defaults.rig.imports]`.

New direction:

- `my-factory/city.toml` contains permanent `[daemon] formula_v2 = true`
- `my-factory/pack.toml` contains the active
  `[defaults.rig.imports.factory]`
- no active student path uses `default_rig_includes`
- docs use `city` and `rig` for scopes

### 16. FormulaV2 porting is new graph authoring

Current formulas are v1-style inline shell workflows with label handoffs. A
FormulaV2 `graph.v2` lesson formula is a declarative step graph with
dependencies and routing metadata. This is not a schema bump.

New direction: reuse lesson intent, agent roles, and artifact names where they
are still useful, but author new graph formulas for the active lesson packs.

### 17. W3 and reference-project deliverables are under-specified

W3 needs a concrete formula-design deliverable, not a vague "fill in a TOML"
exercise. `reference-project/` artifacts also need a migration phase because
they should match the FormulaV2 output format students see.

New direction: define W3 as a FormulaV2 graph design activity and update
reference artifacts alongside the lesson formulas that produce them.

### 18. Workshops are still on the old architecture

W1-W4 are active content, not optional extras. The current workshop material
still points students at shared leaf packs, old prompt-template paths,
label-triggered coordination, `orchestrator.yaml`, copied activity packs, and
old `city.toml` wiring.

New direction: migrate every workshop to the same content architecture. W1 and
W2 may remain design-only, but their examples and deliverables must point
forward to self-contained lesson packs and FormulaV2 graphs. W3 becomes a
FormulaV2 coordination design workshop. W4 updates active lesson-pack prompt
copies and manifests, not shared shipped packs or activity overrides.

### 19. Lesson continuity depends on the same project rig

The curriculum should keep one project rig across lessons. L2 produces a work
package and ADR, L3 consumes that project history while adding implementation
work, L4 reviews the accumulated implementation, and C1 runs a new feature
against the same accumulated context.

New direction: lesson switching changes the active factory pack; it does not
reset the project rig. Root defaults select the active lesson for new rigs, and
existing rigs must be synced to the same factory import before the next lab.

## Full Implementation Scope

This port is not complete when the docs merely describe a better architecture.
It is complete only when the repository's runnable materials behave that way.

The migration must update all active file families. "Active" includes every
workshop, lab, capstone, curriculum mirror, activity page, reference artifact,
pack, factory config, and internal check that a student or instructor can reach
from the main repo path.

- canonical packs under `packs/`
- new self-contained lesson packs under `packs/lessons/`
- checkpoint pack copies under `activites/` only to freeze them as non-runtime
  migration input until they are deleted or converted
- scripts and manifests embedded in pack commands, doctors, orders, formulas,
  and assets, including `commands/*/command.toml` and `doctor/*/doctor.toml`
- `my-factory/city.toml` and `my-factory/pack.toml`
- `my-factory/*.template`
- all student-facing Markdown in `README.md`, `activities/`, `curriculum/`,
  `my-factory/`, `packs/`, and `reference-project/`
- dry-run/static validation scripts
- live lesson check scripts
- internal check documentation

Anything left on the old label-dispatch model must be removed from active repo
paths. Git history is the archive. A stale pack, script, manifest, template, or
README that still appears in a lesson is a migration bug.

## Current Files That Must Move

The current inventory shows stale behavior in these concrete areas:

- `packs/all/commands/wake-downstream/*`
- `packs/*/agents/*/agent.toml`
- `packs/*/agents/*/prompt.template.md`
- `packs/*/formulas/*.toml`
- `packs/*/orders/*.toml`
- `packs/*/commands/*/command.toml`
- `packs/*/commands/*/run.sh`
- `packs/*/doctor/*/doctor.toml`
- `packs/*/doctor/*/run.sh`
- `packs/*/README.md`
- `my-factory/city.toml`
- `my-factory/pack.toml`
- `my-factory/*.template`
- `my-factory/README.md`
- `README.md`
- `activities/README.md`
- `activities/labs/*/README.md`
- `activities/workshops/*/README.md`
- `activities/capstone/C1/README.md`
- `curriculum/**/README.md`
- `curriculum/**/PROMPT.md`
- `reference-project/**`
- `activites/**/packs/**`
- internal check documentation
- migration check script
- tutorial check script
- live lesson check script
- smoke check script
- live lesson helper scripts

The implementation task is to update these files or explicitly remove them from
the active student path. The plan should not leave any active lesson depending
on an unexamined pack, script, or Markdown page.

## Pack And Script Work

This work includes deletion. Do not preserve commands, orders, formulas,
imports, prompts, scripts, or docs just because they already exist. If a thing
does not serve the formula-native lesson model, remove it from the active pack.
If it is useful only as a comparison to the old system, rely on git history
rather than keeping a runnable legacy pack or command in the active repo path.

### Self-contained lesson packs

Create one pack per runnable lesson:

```text
packs/lessons/
  L2/
  L3/
  L4/
  C1/
```

Add W packs only where the workshop has a runnable factory experience that is
cleared by a pack, but migrate every workshop's Markdown either way:

```text
packs/lessons/
  W1/
  W2/
  W3/
  W4/
```

W1 and W2 may stay design-only with no runtime pack if their rewritten
deliverables do not require running Gas City. W3 and W4 must either use a
self-contained workshop pack or be explicitly written as design/config
exercises whose runtime effects happen in the active lab/capstone lesson pack.
No workshop may continue to teach shared leaf packs, label-driven handoff,
`orchestrator.yaml` as the primary workflow engine, or `default_rig_includes`.

Each lesson pack is the factory for that lesson. Its top-level folder may be
curriculum-indexed, but the runnable contents should be portable and
workshop-blind. It must contain:

- `pack.toml`
- every agent definition used by the lesson
- every agent prompt used by the lesson
- every formula used by the lesson
- any commands, doctors, orders, overlays, and assets needed by the lesson
- any local skill or context material that students need to inspect

Lesson packs must not import other packs. Duplication is intentional. Students
should be able to open one folder and understand the whole runnable lesson.
Old canonical role packs are not an alternate runtime path for students.

Do not write agent prompts or formulas that say "you are running L2", "this
lab", "this workshop", or "help the student". Those are facilitator concerns.
The pack itself should describe factory responsibilities, inputs, artifacts,
and close behavior.

### Prompt rewrite workstream

Prompt rewrites are a major authoring task, not a small config cleanup. The
current repository has 8 canonical role prompts under `packs/*/agents/*/` and
9 checkpoint prompt copies under `activites/`. Self-contained L2/L3/L4/C1
lesson packs add at least 19 lesson prompt files if each lesson carries local
copies of the roles it teaches:

| lesson | local role prompts |
| --- | --- |
| L2 | planner, architect |
| L3 | planner, architect, designer, builder |
| L4 | planner, architect, designer, builder, reviewer, release-gate |
| C1 | planner, architect, designer, builder, validator, reviewer, release-gate |

That puts the prompt rewrite scope at roughly 27 prompt files before any W3/W4
runtime packs, and 32+ files if workshop packs add their own local role copies.
Assign prompt rewriting explicitly in each lesson phase.

Every rewritten prompt should adapt this shared graph-worker-style structure:

1. `Role`: role-specific responsibility, authority, and quality bar.
2. `Inputs`: current formula step, current bead, upstream artifacts, project
   files, and project/domain context to inspect.
3. `Graph Work Process`: inspect assigned/routed work, execute only the current
   formula step, write the expected artifact, and avoid creating downstream
   stage beads or labels.
4. `Output Format`: artifact paths, summary, decisions, risks, and handoff
   notes expected by the next formula step.
5. `Close Behavior`: close the current step when complete, record useful
   metadata or review findings, do not relabel the bead, and do not run
   `gc all wake-downstream`.

Keep persona and role-specific guidance inside that scaffold. Do not let each
implementer invent a different work loop for planner, architect, builder,
reviewer, or release-gate prompts.
Also keep the scaffold curriculum-blind: no lesson number, workshop/lab
language, student/facilitator framing, or tutorial instructions inside runtime
prompt files.

### Canonical packs

The existing canonical packs are currently part of the stale teaching surface:

- `packs/planner`
- `packs/architect`
- `packs/designer`
- `packs/builder`
- `packs/validator`
- `packs/reviewer`
- `packs/release-gate`
- `packs/improver`
- `packs/fired-up-pizza`
- `packs/workshop`
- `packs/all`

These packs are migration source material, not a final active teaching surface.
It is not enough to create lesson packs while leaving canonical packs teaching
the old behavior.

Removal is expected for anything whose only purpose was label dispatch,
including redundant commands, stage-queue orders, wake-downstream glue,
composition imports, and status scripts that only summarize label queues.

For every role pack that remains temporarily during migration:

- update `agents/*/agent.toml` so nudges point at formula-native work, not
  `bd ready --label=...`
- update `agents/*/prompt.template.md` so the agent handles assigned/routed
  formula work and drains when idle instead of polling stage labels forever
- update active `formulas/*.toml` to FormulaV2 syntax; use graph steps,
  dependencies, and `metadata."gc.run_target"` where the pack remains in the
  active lesson path
- remove formula actions that create the next stage only by adding labels
- remove formula actions that call `gc all wake-downstream`
- update `orders/*.toml` so orders are not stage-label queue dispatchers
- update `commands/*/run.sh` so status and helper commands report formula state,
  assigned work, artifacts, or optional external sync state
- update `commands/*/command.toml` or delete the command manifest with the
  command it describes
- update `doctor/*/run.sh` so doctors validate the pack's actual FormulaV2 and
  PackV2 expectations
- update `doctor/*/doctor.toml` or delete the doctor manifest with the doctor
  it describes
- update `README.md` so it points to the lesson-pack model or remove the pack
  from the active repo path
- delete the pack when its active content has been copied into
  `packs/lessons/*`

`packs/all` must stop being the default factory. Remove dependencies on it from
active lesson packs, `my-factory`, docs, and tests. The `wake-downstream`
command and its `command.toml` manifest should be deleted from active packs.
Do not keep a runnable legacy comparison copy; use git history for that.

`reference-project/fired-up-pizza` is the capstone input project. The C1
factory belongs in `packs/lessons/C1`. Any remaining `packs/fired-up-pizza`
content should be moved into `reference-project/`, copied into the C1 lesson
pack, or deleted. It must not be the place where the workflow secretly lives.

`packs/workshop` may keep support tooling only if it is graph-aware and not part
of the old shared/manual/label pack architecture. Otherwise, move the needed
doctors or helpers into lesson packs and delete the shared pack.

### Checkpoint pack copies

The `activites/` tree contains checkpoint copies of packs. Freeze it immediately
as non-runtime migration input instead of maintaining a second pack hierarchy.

Required work:

- remove checkpoint packs from active docs and walkthroughs
- mark any remaining checkpoint README as non-runtime migration history while
  it exists
- exclude checkpoint copies from new lesson-pack conformance
- do not port checkpoint copies in parallel with `packs/lessons/*`

Recommended end state: active lessons use `packs/lessons/*`; checkpoint pack
copies are deleted or converted into current lesson-pack examples, not preserved
as an alternate runnable pack hierarchy.

### Pack scripts

All scripts must follow the same conceptual model as the content:

- commands start, inspect, or set up formulas, artifacts, or external sync; they
  do not advance stages by scanning labels
- doctors check prerequisites and pack health; they do not hide missing runtime
  wiring behind label queue checks
- orders handle external triggers or scheduled maintenance; they do not encode
  the primary lesson workflow
- formula helper scripts, if any, operate on the current formula step and
  artifact contract
- command and doctor manifests must be updated or deleted with their scripts

The following script patterns should disappear from active lesson paths:

```bash
bd ready --label=needs-plan
bd ready --label=needs-architecture
bd ready --label=needs-design
bd ready --label=needs-tests
bd ready --label=ready-to-build
bd ready --label=needs-review
bd ready --label=ready-to-ship
gc all wake-downstream
```

If labels remain in scripts, they must be metadata filters, reporting aids, or
external tracker tags. They must not be the state machine.

## Markdown Content Work

Every student-facing Markdown file must show the same lesson model:

1. ensure FormulaV2 is enabled once in `my-factory/city.toml`
2. select the lesson's self-contained pack in `my-factory/pack.toml`
3. sync the existing project rig to the active factory pack
4. restart or reload Gas City
5. run the lesson's simplest `gc sling` command
6. inspect the formula, graph state, artifacts, and beads that were produced
7. make the lesson-specific edit or observation
8. rerun the same simple entrypoint or the lesson's documented verification

The docs should minimize CLI surface area. Prefer pack-defined behavior over
long command sequences. When students need to use a CLI, use the fewest commands
with the simplest arguments:

```bash
gc restart
gc doctor
gc --rig <rig> import add ../packs/lessons/L2 --name factory
gc --rig <rig> import remove factory
gc sling <rig>/factory.planner "lesson request"
gc events --follow
gc graph <bead-id>
bd list
bd show <id>
```

Avoid making students manually create stage beads. Avoid teaching `bd` labels
before they have seen formula-created work.

Required doc updates:

- `README.md`: describe lesson-pack switching, not `packs/all` as the default
  factory
- `my-factory/README.md`: show permanent FormulaV2 setup, the active lesson
  import, the existing-rig sync step, one `gc sling` entrypoint, and
  formula/artifact inspection
- `my-factory/city.toml`: include `[daemon] formula_v2 = true` and no
  lesson-specific import
- `my-factory/pack.toml`: use `[defaults.rig.imports.factory]` for the active
  lesson, remove inherited `packs/all` comments, and remove old
  `wake-downstream` command guidance
- `activities/README.md`: remove the pack-copy override model as the main path;
  teach lesson packs as the runtime surface
- `activities/labs/*/README.md`: rewrite step-by-step lab commands around the
  active lesson pack and its formula
- `activities/workshops/W1/README.md`: keep design-only if appropriate, but map
  the workflow card to the shared graph-worker prompt sections and future
  lesson-pack prompts
- `activities/workshops/W2/README.md`: replace shipped leaf-pack mapping with
  a self-contained lesson-pack and FormulaV2 graph wiring table
- `activities/workshops/W3/README.md`: replace `orchestrator.yaml` as the main
  artifact with formula graph design or make it an explicit comparison
- `activities/workshops/W4/README.md`: update feedback/improvement flow to use
  active lesson-pack prompt copies and formula-native handoff
- `activities/capstone/C1/README.md`: replace six manual stage beads with one
  capstone request and formula-driven stages
- `curriculum/**/README.md` and `curriculum/**/PROMPT.md`: mirror the activity
  changes so instructor and student tracks do not diverge
- `packs/**/README.md`: explain each pack's current role after migration
- `reference-project/**`: update project examples, reports, and workflow
  artifacts so they reflect formula-native flow and the C1 formula output
  contract
- internal check documentation: document the new validation model and walkthrough
  expectations

The active content surface should not keep runnable examples of the old
label/manual pack model. Use git history for that material.

## Dry-Run And Live Lesson Check Work

The checks must test the content architecture, not preserve the old journey.

### Dry-run/static checks

Add the lesson pack linter as the executable architecture check.
It should read the lesson contracts and produce actionable
curriculum findings for:

- missing or non-self-contained lesson packs
- stale root factory wiring
- missing local role agents
- prompts that do not use the shared graph-worker sections
- formulas that are not FormulaV2 `graph.v2`
- unqualified `gc.run_target` routes
- missing per-step artifact contracts
- docs that omit city-wide lesson selection, existing-rig sync, or the
  binding-qualified `gc sling` entrypoint
- active content that still teaches label/manual-pack workflow

Use the linter as the red-green migration driver:

```bash
run the lesson pack linter for L2 without the repository scan
run the lesson pack linter for L2
run the full lesson pack linter
```

Update the dry-run checks so they fail when active lesson paths contain:

- `packs/all` as a runtime dependency
- `gc all wake-downstream`
- `bd create --label` or `bd create --labels` as a lesson stage entrypoint
- `bd ready --label=<stage>` as workflow dispatch
- stage-routing labels as required workflow state
- prompt instructions to poll labels forever
- FormulaV2 files missing graph routing metadata where multi-agent routing is
  expected
- active lesson formulas using `version = 1`
- lesson packs with imports
- lesson docs that omit `[defaults.rig.imports.factory]`
- lesson docs that omit the existing-rig factory import sync step
- unqualified lesson agent routes such as `gc.run_target = "planner"`
- `default_rig_includes`
- `workspace scope` or `scope = "workspace"`
- `append_fragments = ["graph-worker"]`
- `bd dep graph`

The dry-run should also verify positive structure:

- every documented runnable lesson has `packs/lessons/<lesson>/pack.toml`
- every lesson pack has its local agents and formulas
- every multi-agent lesson formula uses graph dependencies and
  binding-qualified `metadata."gc.run_target"` values such as
  `factory.designer`
- every lesson prompt contains the shared sections: `Role`, `Inputs`,
  `Graph Work Process`, `Output Format`, and `Close Behavior`
- every lesson README contains the one-command sling entrypoint
- every lesson's expected artifacts are named consistently between docs,
  formulas, and tests
- `my-factory/city.toml` contains `[daemon] formula_v2 = true`
- `my-factory/pack.toml` contains exactly one active
  `[defaults.rig.imports.factory]`
- `my-factory/*.template`, `commands/*/command.toml`, and
  `doctor/*/doctor.toml` do not preserve stale label/manual wiring

### Live Lesson Scripts

Rewrite live lesson helpers around formulas rather than labels.

The shared live lesson helper should stop modeling stages as labels.
Replace helpers such as `stage_bead_create` and `run_stage <label> ...` with
helpers that:

- switch the active lesson pack
- run the documented `gc sling` entrypoint
- wait for formula-created/routed work
- inspect generated artifacts
- assert that no label-scanning handoff command was required
- assert that the tutorial transcript matches the Markdown commands

Concrete helper design:

```bash
ensure_formula_v2_enabled
use_lesson_pack <lesson>
sync_existing_rig_lesson_pack <rig> <lesson>
run_lesson_sling <target> <request>
capture_gc_events <output-file>
wait_for_formula_step <root-bead-id> <step-id>
assert_formula_has_route <formula-file> <step-id> <run-target>
assert_no_label_dispatch <path>
assert_doc_command_present <markdown-file> <command-regex>
```

The helpers should edit only the root factory files needed by the lesson:
`my-factory/city.toml` for permanent FormulaV2 setup and `my-factory/pack.toml`
for `[defaults.rig.imports.factory]`, plus the selected existing rig's
`[rigs.imports.factory]` entry when switching lessons after rig creation.

Update these live lesson scripts:

- L2
- L3
- L4
- C1
- my-factory

The live lesson scripts should execute what the lesson docs tell students to
execute. If a hidden setup step is required, comments must make clear that it
is internal scaffolding, not student workflow.

### Behavioral smoke

Update behavioral smoke expectations from label handoff to formula handoff.
Instead of proving that planner relabels work and `wake-downstream` slings the
next agent, prove that:

- the lesson's entry sling instantiates or attaches the expected formula
- formula graph steps become visible
- ready work is routed to the intended agent targets
- closing prerequisite work makes dependent steps ready
- pass/fail outcomes affect graph path only when an explicit `check`, `retry`,
  or `condition` is part of the lesson
- artifacts are written to the documented locations
- the run completes without `gc all wake-downstream`

## Target Directory Shape

Runtime lessons live under:

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

Every workshop is migration scope. Not every conceptual workshop needs a full
runtime factory, but every workshop must be rewritten to match this content
architecture. The first implementation pass should prioritize runtime-heavy
lessons, then sweep the design workshops:

1. `L2`
2. `L3`
3. `L4`
4. `C1`
5. `W3`
6. `W4`
7. `W2`
8. `W1`
9. `L1`

Each lesson pack is self-contained:

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
    lesson-ready/
      run.sh
      doctor.toml
  commands/
    status/
      run.sh
      command.toml
  skills/
  template-fragments/
```

Rules:

- no `[imports.*]` inside lesson packs unless the lesson is explicitly teaching
  imports
- no dependency on `packs/all`
- no dependency on shared leaf packs
- duplicate agents/formulas when needed
- keep lesson-specific simplifications local to the lesson pack

## Lesson Pack `pack.toml`

Minimal shape:

```toml
[pack]
name = "sfi-l3"
schema = 2
```

If most agents share the same default formula:

```toml
[agent_defaults]
default_sling_formula = "mol-feature-delivery"
```

If agents need different default formulas, put `default_sling_formula` in each
`agents/<name>/agent.toml` instead.

Do not add old PackV1 declarations:

- no `[[agent]]`
- no `[formulas]`
- no `[[commands]]`
- no `[[doctor]]`
- no `pack.includes`

## Agent Defaults

The current Gas City runtime applies only a narrow set of agent defaults
reliably. Use defaults where they reduce student commands:

- `default_sling_formula`
- `append_fragments`, but only for actual local template fragment files

Keep essential per-agent values in `agents/<name>/agent.toml`:

```toml
scope = "rig"
wake_mode = "fresh"
max_active_sessions = 1
default_sling_formula = "mol-feature-delivery"
nudge = "Run gc prime, then work the assigned formula step."
```

Avoid teaching `work_query` and `sling_query` unless the lesson is specifically
about routing internals. Default routing is good enough for the student path.

Do not use `append_fragments = ["graph-worker"]`. Graph worker behavior is a
built-in FormulaV2 fallback, not a template fragment.

## Formula Pattern

A lesson should have one visible entry formula:

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

Use FormulaV2 syntax even for the first simple formula lesson. The beginner
formula may only have the header plus plain steps and `needs`; it does not need
multi-agent routing until the lesson teaches multi-agent work.

Teaching progression:

- first formula lesson: `version = 2`, `contract = "graph.v2"`, simple steps
- dependency lesson: add `needs = [...]`
- multi-agent lesson: add
  `metadata = { "gc.run_target" = "factory.planner" }`
- larger workflow lesson: add `children` only if grouping makes inspection
  clearer
- validation lesson: add `check` or `retry` only if retry behavior is being
  taught

Use formula features before shell workarounds:

- `needs` for stage order
- `metadata.gc.run_target` for agent routing
- `children` for inspectable subwork when the graph is large enough to need it
- `condition` for optional steps when the lesson needs a clear branch
- `check` or `retry` for validation and retry behavior when that behavior is
  being taught

Avoid advanced FV2 constructs in the first pass:

- `loop`
- dynamic `on_complete` fanout
- formula expansion or advice
- scope/cleanup/control-dispatcher patterns

Do not encode core flow through:

- `bd update --add-label <next-stage>`
- `bd create --label <next-stage>`
- `gc all wake-downstream`
- `bd ready --label <stage>`

## Minimum Lesson Graphs

Each active lesson pack needs at least one FormulaV2 entry graph with concrete
step IDs, dependencies, and routing metadata. These are the minimum shapes; the
implementation may add artifact fields, descriptions, or checks where the
lesson explicitly teaches them.

L2:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |

L3:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |

L4:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |
| `review` | `build` | `factory.reviewer` |
| `release-check` | `review` | `factory.release-gate` |

L4's rework loop is student-driven unless the lesson explicitly teaches
FormulaV2 branching. The reviewer records pass/request-changes output; the
student reads it, adjusts the builder configuration or artifact, and re-slings
the same entry formula.

C1:

| step id | needs | `gc.run_target` |
| --- | --- | --- |
| `plan` | none | `factory.planner` |
| `architecture` | `plan` | `factory.architect` |
| `design` | `architecture` | `factory.designer` |
| `build` | `design` | `factory.builder` |
| `validate` | `build` | `factory.validator` |
| `review` | `validate` | `factory.reviewer` |
| `release` | `review` | `factory.release-gate` |

## Simplest Student CLI

The active factory pack should carry enough defaults that students do not need to know
the bead lifecycle just to start a lab.

Preferred per-lesson run command:

```bash
gc sling <rig>/factory.planner "Build user profile editing"
```

This works when the target agent has `default_sling_formula` configured in the
pack. Gas City creates/routes the bead and attaches the formula.

If a lesson needs to make formula attachment explicit:

```bash
gc sling <rig>/factory.planner "Build user profile editing" --on mol-feature-delivery
```

Avoid making the normal path:

```bash
bd create --title "Build user profile editing" --label needs-plan
gc sling --nudge <rig>/factory.planner <bead-id>
```

That teaches two tools and a stage label before the student has seen the
factory.

## City Switching

FormulaV2 is enabled once in `my-factory/city.toml`:

```toml
[daemon]
formula_v2 = true
```

Students switch lessons by editing `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

This is city-wide active lesson selection for the curriculum. The agents inside
that pack remain rig-scoped, so the selected project rig sees them as
`<rig>/factory.planner`, `<rig>/factory.architect`, and so on.

Because root defaults are applied when a rig is created, students who keep the
same project rig must also sync the existing rig import after changing lessons.
The resulting rig import should point at the same lesson pack:

```toml
[rigs.imports.factory]
source = "../packs/lessons/L3"
```

Student-facing docs should make the sync concrete. L2 can add the import:

```bash
gc --rig <rig> import add ../packs/lessons/L2 --name factory
```

L3 and later should replace the previous factory import:

```bash
gc --rig <rig> import remove factory
gc --rig <rig> import add ../packs/lessons/L3 --name factory
```

If lesson pack commands must be exposed as `gc <binding> <cmd>`, add an
explicit city import as an exception:

```toml
[imports.factory]
source = "../packs/lessons/L3"
```

The normal lesson path should not need this exception. Student-facing docs
should present exactly one factory import to change and should not mention
`default_rig_includes`.

## Commands and Doctors

Use `doctor/` for readiness checks:

- required binaries
- `formula_v2` enabled in `city.toml`
- expected agents present
- expected formulas present
- project has beads initialized

Use `commands/` for optional convenience only:

- graph-aware status summaries
- artifact display
- reset helpers

Do not put lesson handoff logic in commands. Delete old handoff/status commands
tied to labels, especially `gc all wake-downstream`. Keep only lesson-local,
graph-aware helpers that support inspection or setup and do not control the
workflow.

## Labels

Allowed uses:

- `lesson:L3`
- `source:lesson-pack`
- `artifact:design`
- `risk:security`
- `needs-info`
- external tracker labels

Avoid stage-routing labels:

- `needs-plan`
- `needs-architecture`
- `needs-design`
- `needs-tests`
- `ready-to-build`
- `needs-review`
- `ready-to-ship`

If a label appears in a lesson formula, it should be removable without changing
the workflow graph.

## Migration Phases

## Implementation Status

Current verified state:

- L2, L3, L4, and C1 have self-contained runtime lesson packs under
  `packs/lessons/`.
- Each migrated lesson pack uses FormulaV2 with `contract = "graph.v2"`,
  binding-qualified `factory.*` routes, and graph-worker prompts.
- The student-facing docs for L2, L3, L4, and C1 show the city-wide
  `[defaults.rig.imports.factory]` selection, existing-rig factory import sync,
  and one formula entrypoint `gc sling` command.
- The live lesson checks now validate progress through FormulaV2 graphs
  with `gc session peek`, `gc graph`, and bead state captures.
- Live walkthroughs have passed individually:
  - L2: plan and architecture artifacts through `mol-feature-intake`
  - L3: plan, architecture, design, implementation commit, and passing tests
    through `mol-feature-delivery`
  - L4: plan, architecture, design, implementation commit, review, release
    gate, and passing tests through `mol-delivery-review`
  - C1: plan, architecture, design, implementation commit, validation, review,
    release gate, and passing tests through `mol-release-delivery`
- Targeted lesson lint with `--no-repo-scan`, shell syntax checks, migration
  structural checks, and migrated-lesson dry-runs are green.

Known remaining work:

- Full repo linter scan is still red because non-migrated active surfaces
  remain in L1, W1-W4, `my-factory/`, `README.md`, canonical role packs, and
  `packs/all`.
- Phase 5 through Phase 10 remain necessary before claiming the whole
  repository matches `specs/content-architecture.md`.

### Phase 1: Lock The Architecture Contract

Status: complete. Future implementation work should treat
`specs/content-architecture.md` as the source of truth and this file as the
execution plan.

Update:

- `plans/port-to-packs-v2.md`
- `specs/content-architecture.md`

Purpose: make the new target explicit and prevent further work on the old
format-only migration.

Deliverable: this plan names every active file family that must move, and the
spec names the student-facing rules those files must obey.

### Phase 2: Build The First Complete Lesson Pack

Status: complete for L2.

Build `packs/lessons/L2` first.

Requirements:

- self-contained
- no imports
- includes every agent needed for L2
- one visible entry formula
- no `packs/all`
- no `gc all wake-downstream`
- no stage-label order handoff
- student starts with one `gc sling` command
- formulas express the lesson workflow with graph steps and route metadata
- formula routes use binding-qualified targets such as `factory.planner`
- prompts describe formula-routed work instead of label polling
- scripts inspect or validate formula state instead of dispatching labels
- L2 planner and architect prompts are rewritten from the shared prompt
  structure, not copied with label-polling behavior

Use this lesson to validate the PackV2 and FormulaV2 teaching shape before
duplicating work across L3/L4/C1.

### Phase 3: Rewrite L2 Content And Harness Together

Status: complete. L2 has a passing live walkthrough.

Update L2 docs and walkthrough so students:

1. confirm `[daemon] formula_v2 = true` in `my-factory/city.toml`
2. set `[defaults.rig.imports.factory]` to `../packs/lessons/L2`
3. sync the existing rig's `factory` import to `../packs/lessons/L2`
4. run `gc restart`
5. run one `gc sling <rig>/factory.planner` command
6. inspect `gc events`, `gc graph`, `bd show`, and lesson artifacts

Update at the same time:

- `activities/labs/L2/README.md`
- `curriculum/labs/L2/README.md`
- `curriculum/labs/L2/PROMPT.md`
- any L2 checkpoint under `activites/`
- L2 live lesson script
- shared walkthrough helpers touched by L2

Remove instructions and tests that require copying shared packs, editing
per-rig import overrides, creating stage-labelled beads, or running
label-specific status commands.

### Phase 4: Port The Remaining Runtime Lessons

Status: complete for L3, L4, and C1. All three have passing live walkthroughs.

Port each lesson as a self-contained pack. Duplicate definitions from earlier
lessons intentionally.

Recommended order:

1. `L3` - first multi-agent build lesson
2. `L4` - review/release lesson
3. `C1` - end-to-end factory run

Each lesson should simplify what came before, not just copy all previous
complexity forward.

For each lesson, update all three layers in the same change:

- pack and scripts
- Markdown lesson content
- dry-run and walkthrough coverage
- local prompt copies for every role in the lesson graph

Also update `reference-project/` artifacts in the same phase when a lesson's
formula output contract changes.

### Phase 5: Remove Or Replace Canonical Shared Packs

Replace the canonical role packs with self-contained lesson packs, then remove
the old shared/manual/label pack topology from active repo paths.

Required work includes deleting stale material, not just editing it in place:

- `packs/*/agents/*/agent.toml`: formula-native nudges/default formulas
- `packs/*/agents/*/prompt.template.md`: adapt the shared graph-worker prompt
  structure; no label-polling loops
- `packs/*/formulas/*.toml`: graph/routing/dependency flow
- `packs/*/orders/*.toml`: external triggers only, not stage queues
- `packs/*/commands/*/run.sh`: status/inspection only, not handoff
- `packs/*/doctor/*/run.sh`: validate PackV2/FormulasV2 expectations
- `packs/*/doctor/*/doctor.toml`: validate the same expectations as the script
- `packs/*/commands/*/command.toml`: keep only graph-aware inspection/setup
  commands
- `packs/*/README.md`: point to the lesson-pack model or delete with the pack
- delete role-pack files whose only job was old label-queue dispatch

`packs/all` gets special handling: remove it from the default factory path and
delete `wake-downstream` from active repo paths. Git history is the archive.

### Phase 6: Rework W3 Coordination

Replace `orchestrator.yaml` as the main runtime concept.

Recommended teaching move:

- W3 students produce a FormulaV2 graph design
- the deliverable includes step IDs, `needs`, `gc.run_target`, artifact names,
  and a short rationale for any `check`, `retry`, `condition`, or `children`
- gates are formula steps or check/retry constructs when runtime validation is
  part of the exercise
- rejection paths are explicit formula branches or a documented student-driven
  re-sling loop

Do not keep `orchestrator.yaml` as the normal deliverable. If the old approach
is mentioned, mention it only in prose as retired material and do not require
students to edit or run it.

### Phase 7: Rework The Remaining Workshops

Rewrite W1, W2, and W4 so all workshops match the same architecture.

W1:

- keep it design-only unless a runtime exercise is added
- map the workflow card to the shared prompt sections: `Role`, `Inputs`,
  `Graph Work Process`, `Output Format`, and `Close Behavior`
- update references from shared pack prompts to active lesson-pack prompt copies
- remove any downstream framing that says W3/W4 are orchestrator or label
  systems

W2:

- replace shipped leaf-pack mapping with a self-contained lesson-pack wiring
  model
- make the deliverable a table of roles, FormulaV2 graph steps, artifacts, and
  lesson-local prompt paths
- remove claims that L2 installs shared packs through `city.toml`

W4:

- feedback rules target the active lesson pack prompt copy, project manifest, or
  formula artifact contract
- reactive and aggregate loops are config changes followed by re-slinging the
  lesson formula
- external loops start a new formula run through the lesson entrypoint
- remove `default_rig_includes`, copied activity-pack, and old prompt-path
  guidance

### Phase 8: Rewrite The Markdown Surface

After lesson packs exist, rewrite or remove student-facing references to:

- `packs/all` as default runtime
- `gc all wake-downstream`
- stage-label startup
- label polling loops
- `bd create --labels <stage>` capstone flow
- old `includes = [...]` / `[[agent]]` / `prompts/*.md.tmpl` examples
- `orchestrator.yaml` as the normal workflow engine

This phase covers `README.md`, `activities/`, `curriculum/`, `my-factory/`,
`packs/`, `reference-project/`, and internal check documentation.

### Phase 9: Update Dry-Run And Live Lesson Checks

Rewrite check expectations to enforce the new architecture:

- static checks fail on old dispatch patterns in active lesson paths
- dry-run verifies lesson pack shape and formula graph routing
- live lesson scripts execute the same commands shown in Markdown
- behavioral smoke proves formula handoff, not label handoff
- internal check docs explain formula-native validation

### Phase 10: Clean Checkpoints And Old References

Freeze `activites/` checkpoints as non-runtime migration input now, then delete
or convert them once the matching lesson pack exists.

Required outcome: checkpoint runtime instructions are replaced with lesson pack
pointers, and no checkpoint copy remains as an alternate runnable pack
hierarchy.

## Grill-Me Decision Tree

Question: Should lesson packs import shared base packs to avoid duplication?

Recommended answer: no. The user-facing lesson pack should be fully
self-contained. DRY can be restored later with generation if maintenance cost
becomes painful.

Question: Should labels disappear completely?

Recommended answer: no. Keep labels for provenance and reporting. Remove labels
as the stage router.

Question: Should orders disappear completely?

Recommended answer: no. Keep orders for external triggers and scheduled work.
Do not use orders as the normal formula step handoff mechanism.

Question: Should every workshop get a runtime pack?

Recommended answer: every workshop must migrate, but not every workshop needs a
runtime pack. If the workshop runs agents or formulas, give it a
self-contained pack. If it is design-only, rewrite its deliverable, examples,
and references so they point to self-contained lesson packs and FormulaV2
graphs.

Question: Should the capstone still create one bead per stage?

Recommended answer: no. Capstone should start from one user request. The
capstone formula instantiates or attaches the staged work.

Question: Should we use `default_sling_formula`?

Recommended answer: yes, where it reduces student CLI. It lets the pack define
the lesson formula so students can start with `gc sling <target> "request"`.

Question: Should we rely on pack commands for workflow handoff?

Recommended answer: no. Pack commands are useful, but rig-imported command
exposure is currently limited. More importantly, putting handoff in a command
teaches the wrong abstraction.

Question: Should FormulaV2 be mandatory for active lesson formulas?

Recommended answer: yes. Use FormulaV2 syntax from the first formula lesson so
students do not learn FormulaV1 and then switch halfway through. Keep the early
FormulaV2 formulas simple: header, steps, and `needs`. Add `gc.run_target`,
`children`, `condition`, `check`, or `retry` only when the lesson needs that
specific concept.

Question: Should students edit `city.toml` every lesson?

Recommended answer: no. `city.toml` gets the one-time
`[daemon] formula_v2 = true` setting. Per-lesson switching happens in
`my-factory/pack.toml` by changing `[defaults.rig.imports.factory]`.

Question: Should students learn `bd create` early?

Recommended answer: not as the lab entrypoint. Introduce `bd` after they have
seen Gas City create and route work from a simple `gc sling` command.

## Acceptance Criteria

The migration is on track when:

- `packs/lessons/L2` exists and runs standalone
- L2 docs use one active lesson pack import in `my-factory/pack.toml`
- L2 docs include the existing-rig sync step for `[rigs.imports.factory]`
- `my-factory/city.toml` enables FormulaV2 permanently
- L2 starts with one `gc sling` command
- active L2 lesson formulas use `version = 2` and `contract = "graph.v2"`
- no L2-critical flow uses `packs/all`
- no L2-critical flow uses `gc all wake-downstream`
- no L2-critical flow uses stage-label orders
- formulas route work with binding-qualified `gc.run_target` values such as
  `factory.planner`
- labels in L2 are metadata only
- L2 walkthrough follows the Markdown commands
- dry-run checks fail if L2 reintroduces label dispatch
- `gc doctor` from `my-factory` reports expected compatibility warnings only

The migration is complete when:

- L2, L3, L4, and C1 each have self-contained lesson packs
- W1-W4 are all rewritten to match `specs/content-architecture.md`
- any workshop that runs a factory has a self-contained lesson pack
- student docs no longer teach `packs/all` as the main factory
- capstone starts from one request, not six manually-created stage beads
- W3 coordination is taught through FormulaV2 graph design
- old shared/manual/label packs are removed from active repo paths after their
  useful content is copied into lesson packs
- checkpoint copies under `activites/` are deleted, converted, or frozen as
  non-runtime migration input and excluded from active lessons
- all pack scripts, doctors, orders, formulas, and prompts obey the same
  formula-native workflow model
- all command and doctor manifests match their scripts and do not preserve old
  label-dispatch commands
- all active lesson prompts use the shared graph-worker-style section
  structure while preserving role-specific guidance
- all active lesson formulas use FormulaV2 syntax; FormulaV1 is absent from
  active repo paths
- all student-facing Markdown gives accurate, complete, step-by-step commands
  for the active lesson pack
- all workshop Markdown either has no runtime wiring by design or points to the
  active self-contained lesson pack model
- dry-run/static checks enforce the content architecture
- walkthrough scripts execute the documented steps for every runnable lesson
- behavioral smoke proves formula graph routing rather than label scanning
- reference-project artifacts reflect formula-native flow and the C1 output
  contract

## Verification Commands

Static checks for old workflow patterns:

```bash
rg 'gc all wake-downstream|bd ready --label|bd create .*--labels?|needs-plan|needs-architecture|ready-to-build|needs-review|ready-to-ship' \
  README.md curriculum activities activites my-factory packs reference-project
```

The result should be empty in active student paths.

Static checks for old pack composition:

```bash
rg 'packs/all|default_rig_includes|wake-downstream' \
  README.md curriculum activities activites my-factory packs reference-project
```

Expected result: no active student-path matches.

Static checks for stale PackV2/CLI claims:

```bash
rg 'workspace scope|scope = "workspace"|bd dep graph|append_fragments = \["graph-worker"\]' \
  README.md curriculum activities activites my-factory packs reference-project
```

Expected result: no active student-path matches.

Workshop architecture checks:

```bash
rg 'orchestrator.yaml|label-based handoff|needs-plan|needs-design|ready-to-build|needs-review|ready-to-ship|prompts/<agent>\\.md\\.tmpl|default_rig_includes|shipped packs' \
  activities/workshops curriculum/workshops
```

Expected result: no active workshop-path matches.

Root factory wiring checks:

```bash
rg '^\[daemon\]|formula_v2\s*=\s*true' my-factory/city.toml
rg '^\[defaults\.rig\.imports\.lesson\]|source\s*=\s*"\.\./packs/lessons/' my-factory/pack.toml
rg '^\[rigs\.imports\.lesson\]|source\s*=\s*"\.\./packs/lessons/' my-factory/city.toml
```

Pack shape checks:

```bash
find packs/lessons -name pack.toml -print
find packs/lessons -path '*/agents/*/agent.toml' -print
find packs/lessons -path '*/formulas/*.toml' -print
```

Lesson packs should have no imports:

```bash
rg '^\s*\[imports|^\s*\[\[imports|source\s*=' packs/lessons
```

Expected result: no cross-pack imports. Local files and local asset references
are fine.

Formula routing checks:

```bash
rg 'version\s*=\s*2|contract\s*=\s*"graph.v2"|gc.run_target|needs\s*=' packs/lessons
rg 'gc.run_target"\s*=\s*"(planner|architect|designer|builder|validator|reviewer|release-gate)"' packs/lessons
```

Every active lesson formula should show FormulaV2 syntax. Every multi-agent
lesson formula should also show dependencies and binding-qualified routing
metadata. The second command should return no matches.

FormulaV1 should be absent from active lesson packs:

```bash
rg 'version\s*=\s*1' packs/lessons
```

Expected result: no matches.

Prompt structure checks:

```bash
for section in 'Role' 'Inputs' 'Graph Work Process' 'Output Format' 'Close Behavior'; do
  rg "^# .*${section}|^## .*${section}" packs/lessons/*/agents/*/prompt.template.md
done
```

Every active lesson prompt should use the shared section structure. Prompts may
add role-specific sections, but they should not omit the graph work loop or
close behavior.

Runtime smoke test for each lesson:

```bash
cd my-factory
gc restart
gc doctor
gc sling <rig>/factory.<entry-agent> "Small feature request"
```

Then verify:

- the lesson formula is instantiated or attached
- graph steps are visible
- routed steps target the intended agents
- no label-scanning handoff command is needed
- lesson artifacts land where the README says they will

Internal checks after the port:

```bash
run the repository migration check
run the repository tutorial check
run the live lesson dry run
run the repository smoke check
```

The checks must fail if Markdown, packs, or scripts drift back toward the
label-dispatch workflow.

## Out of Scope

- completing the entire repository migration in a single atomic commit
- renaming `activites/` to `activities`
- fixing upstream Gas City command exposure or skill materialization
- remote pack imports
- making every FormulaV2 feature part of the first formula lesson
- expanding the curriculum to new agent roles beyond the current lesson goals
