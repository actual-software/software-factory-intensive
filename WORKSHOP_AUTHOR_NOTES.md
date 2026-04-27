# Workshop Author Handoff Notes

This file flags content that needs judgment-call rewrites the mechanical doc-fix pass couldn't automate. Each item cites the file(s) and why the fix is teaching-content rather than find-and-replace.

Companion plan: `plans/fix-stale-docs.md`.

---

## 1. Curriculum files teaching v1 `[[agent]]` blocks

Gas City Pack v1 exposed agent config as `[[agent]]` TOML blocks inside `pack.toml` (or `city.toml`). In Pack v2, agents live at `agents/<name>/agent.toml` inside a pack directory, and the `[[agent]]` block no longer exists in pack.toml at all. Several curriculum files teach students to author, tune, or read `[[agent]]` blocks directly. These lessons cannot be corrected by a string replace — they need rewrites.

**Student impact:** if a student copies a `[[agent]]` block from the curriculum into their `pack.toml`, `gc doctor` will silently ignore it (v2 doesn't parse that key) and the tuning they think they're doing has no effect. The lab's "tune `idle_timeout` and observe the change" exercise fails to teach anything because the tuned value doesn't load.

Regenerate the current hit list before editing:

```bash
rg -n '\[\[agent\]\]' curriculum/ -g '*.md'
rg -ln '\[\[agent\]\]' curriculum/ -g '*.md'
```

**Files known to teach `[[agent]]` (verify before editing):**

- `curriculum/labs/L1/README.md` — the lab's `[[agent]]` block tuning exercise (`idle_timeout`, `max_active_sessions`, etc.). In v2 these fields live in `agents/<name>/agent.toml`. Rewrite around the v2 per-agent `agent.toml` surface. Roughly 14 hits.
- `curriculum/labs/L3/README.md` — references `[[agent]]` instructional content. Roughly 14 hits.
- `curriculum/labs/L4/README.md` — references `[[agent]]` instructional content. Roughly 15 hits.
- `curriculum/workshops/W3/README.md` — orchestrator instructions use `[[agent]].name` as the stage-binding key. V2 pack.toml has no `[[agent]]` block; the correct binding is the `agents/<n>/` directory name. Needs curriculum rewrite, not string replace. Roughly 12 hits.
- `curriculum/capstone/C1/README.md` — `[[agent]]` city.toml teaching example. Roughly 15 hits.

---

## 2. Phantom gc commands used throughout curriculum

**Student impact:** students typing `gc watch` / `gc orchestrate` / `gc session stop` get "unknown command" and stall. Worse, the curriculum's instructional prose often depends on the command's presumed behavior ("now `gc watch` the session and observe..."), so the student can't infer a substitute without reading the upstream CLI help. Every hit is a hard stop.

Three commands appear repeatedly in curriculum but do not exist in gc 0.15:

| Phantom command | v2 equivalent (pick per instructional intent) |
|---|---|
| `gc watch <agent>` | `gc session attach <name>` (interactive tmux attach) OR `gc session peek <name>` (view output without attach) |
| `gc session stop <name>` | `gc session close <name>` (permanent close) OR `gc session kill <name>` (force-kill; reconciler restarts) OR `gc session suspend <name>` (save state, free resources) |
| `gc orchestrate <...>` | No direct equivalent. W3 and C1 teach an orchestrator subsystem that was removed or reshaped in 0.15. Decide: rewrite to teach formula + `gc convoy` handoff, or document that orchestrate is no longer available. |

Regenerate the current hit list:

```bash
rg -ln 'gc watch|gc orchestrate|gc session stop' curriculum/ -g '*.md'
```

Roughly 40 `gc watch` hits plus `gc orchestrate` and `gc session stop` hits across L1/L2/L3/L4/W3/W4/C1 at last count. Every instance needs a semantic decision (attach vs peek, close vs kill vs suspend, rewrite orchestrate teaching vs drop it).

---

## 3. `includes = [...]` and `gc service restart` in curriculum PROMPT.md files

**Student impact:** these PROMPT.md files are instructions the student hands to an LLM agent (Claude, etc.) to guide lab work. If the LLM reads `includes = [...]` or `gc service restart`, it will likely reproduce that syntax in the student's `city.toml` or shell history — producing a config that doesn't parse (v2 uses `[rigs.imports.<binding>]`) or a command that doesn't run (v2 is `gc restart`). The student debugs the LLM's output rather than the lesson.

Three files contain mechanical-looking hits that are actually inside teaching blocks and should be reviewed together with the `[[agent]]` rewrites above (not auto-fixed):

- `curriculum/labs/L2/PROMPT.md` — `includes = [...]`, `gc service restart`
- `curriculum/labs/L3/PROMPT.md` — same
- `curriculum/labs/L4/PROMPT.md` — same

Mechanical replacements (`includes = [...]` → `[rigs.imports.<binding>]`, `gc service restart` → `gc restart`) are safe, but the surrounding prose often explains *why* a student is editing the city.toml a certain way. Prefer a full rewrite in step with the `[[agent]]` teaching rewrite above.

---

## 4. `packs/workshop/README.md` Discord integration claim

`packs/workshop/README.md:71` (the Communication table) lists Discord (`DISCORD_*` env var). There is no Discord doctor check, no Discord MCP server entry, no Discord env var use anywhere in the pack. Decide:

- (a) Discord integration is planned future work — leave the row with a note.
- (b) Discord is not planned — remove the row.

Pack authors should not ship docs for an integration that isn't actually wired.

---

## 5. `packs/workshop/overlay/.claude/settings.json` MCP list

The shipped MCP servers are: **datadog, github, grafana, linear, posthog, sentry, slack**. No gitlab. The README was updated to match (GitLab row is now "bd sync only"). Confirm this is the intended workshop ship before merge:

```bash
jq -r '.mcpServers | keys[]' packs/workshop/overlay/.claude/settings.json | sort
```

If the intent is to ship a GitLab MCP server, add it to `settings.json` and revert the README edit.

---

## 6. `activites/` → `activities/` directory rename

Two parallel directory trees exist on this branch with mechanical doc content fixed in both:

- `activites/workshops/W2/gascity/step_0/packs/` (checkpoint tree — misspelled)
- `activites/labs/L2/gascity/step_0/packs/` (checkpoint tree — misspelled)
- `activities/workshops/` (curriculum deliverables tree — correctly spelled)
- `activities/labs/`, `activities/capstone/C1/` (same)

The rename was explicitly deferred to its own PR per the original migration plan's Principle 1 (shape preservation). When you're ready to rename:

1. Decide whether to move just the checkpoint trees, or to consolidate with the correctly-spelled `activities/` tree.
2. Update every reference: `rg -l 'activites/'`.
3. Update the curriculum files that refer to checkpoint paths.
4. Ship as a separate PR to keep the rename diff separable from the schema migration.

---

## 7. `my-factory/pack.toml.template` double-import of `packs/all`

The template imports `packs/all` at workspace scope (`[imports.all] source = "../packs/all"`) AND the sibling `city.toml.template` includes it at rig scope via `default_rig_includes`. This is intentional per `workshop:#786` — Gas City 0.15.x doesn't expose pack commands from rig-scoped imports, so the workspace-scope import surfaces `gc all wake-downstream` as a CLI command while the rig-scope import composes the 8 agents into each rig.

Verify the `workshop:#786` issue description still matches this claim before workshop handoff. If upstream fixes the gap, the workspace-scope import can be dropped.

---

## 8. Reference project README assumptions

`reference-project/fired-up-pizza/README.md:19` correctly warns that `gc rig add --include` applies only at first-time rig registration and that post-registration pack changes go through `city.toml` edits. That advice matches gc 0.15.2 behavior. The "Adapting for Your Project" section (`:121`) still needs one last author pass to confirm the step ordering still matches what a student following the curriculum through L1–L4 will have wired up by that point.

**Student impact:** students who copy from this README as a template for their own project follow the setup in order. If "Adapting for Your Project" references configuration state that curriculum labs produce in a different order or with different names, the student's `city.toml` diverges and labs start failing with confusing "pack not found" errors.

---

## 9. Hit-count regeneration commands

The plan (`plans/fix-stale-docs.md`) cites specific hit counts for curriculum files. Those counts drift as the curriculum evolves. Always regenerate before acting on them:

```bash
# Per-file counts of phantom commands + [[agent]] teaching
rg -c 'gc watch|gc orchestrate|gc session stop|\[\[agent\]\]' curriculum/ -g '*.md'

# All curriculum files with mechanical-seeming hits (but which are teaching content)
rg -ln 'includes = \[|gc service restart' curriculum/ -g '*.md'
```

---

## 10. L1 intentionally skipped in automated coverage

The automated lesson coverage starts after students have produced their first
project-specific prose artifacts. L1's deliverables are prose-only student
artifacts:

- `activities/labs/L1/CLAUDE.md` — filled in by the student for their own project
- `activities/labs/L1/DECISIONS.md` — log of rule edits the student makes
- `my-factory/PROJECT_MANIFEST.md` — the student's project manifest

A runnable check for L1 would either (a) check file existence, which has little
value because those files come from the student's keyboard, or (b) ask an agent
to fabricate those files for a toy rig, which does not resemble the real lesson.

L1's only downstream consumer is the presence of a `CLAUDE.md` that sets
project rules for later labs. The bundled fixture already has its own
`CLAUDE.md`, so later automated checks do not need an L1 run to establish their
inputs.

If a future decision makes sense to add L1 coverage, the shape would likely be:
assert the student's CLAUDE.md/DECISIONS.md/PROJECT_MANIFEST.md exist at the
expected paths with non-trivial content as a precondition check. Not a priority
for v1 handoff.

---

## 11. Verification the mechanical doc-fix pass passed

These greps should return 0 hits outside `plans/`, this file, and `curriculum/**` (which is flagged above for author rewrite, not mechanical fix):

```bash
rg -n 'gc poke' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
rg -n 'examples/actual/' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
rg -n 'workshop\.default_rig_includes' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
rg -n 'overlays/default' packs/ -g '*.md'
rg -n '\./scripts/sync-' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
rg -n 'gc watch|gc orchestrate|gc session stop' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
rg -n 'gc service restart' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
```

Plus the full automated check suite:

```bash
run the repository migration check
run the repository smoke check
run the repository tutorial check
```

---

## 12. W1/W2/W3/W4 intentionally skipped in automated coverage

The automated coverage targets labs, not workshops. Workshops W1-W4 are
author-led teaching sessions whose exit criteria are knowledge and
comprehension, not runnable artifacts that a check can inspect:

- **W1 (Workflow Cards):** exit criterion is the student internalising the 8 card shapes. Artifact-wise it produces a filled-in workflow card per agent — prose authored by the student, not by the factory. Automated coverage would only be able to file-existence-check those cards, which is near-zero value.
- **W2 (Factory Wiring):** exit criterion is reading + discussing `activities/workshops/W2/README.md`. No factory state changes; `gc status` would be unchanged pre/post.
- **W3 (Conventions):** author-led doc walk-through of `packs/workshop/` conventions. No bead flow; nothing new to assert that `migration-check.sh` doesn't already cover.
- **W4 (Improver + Release-Gate):** teaches the improver loop and release-gate wiring; the live dynamics belong to C1, where they actually run end-to-end against a feature.

The labs (L1-L4 + C1 capstone) are where agent behavior can be observed
empirically. L1 is skipped for the reasons in section 10 above. L2, L3, L4,
and C1 are the live agent coverage targets.

If a workshop later grows a runnable exercise (for example, "W3 asks students
to add a pack and verify `gc status` reports it"), automated coverage becomes
worthwhile. Until then the skip is the honest choice.

---

## 13. gc 0.15.2 `gc rig add` path-canonicalization bug

On gc 0.15.2, running `gc rig add` right after `gc register` from a working directory under `/tmp/...` fails deterministically:

```
gc rig add: bead store: exec beads start: could not acquire dolt start lock
  (.../my-factory/.gc/runtime/packs/dolt/dolt.lock)
```

**Root cause (not what it looks like):** The error message blames the lock file, but the real culprit is path canonicalization. On macOS `/tmp` is a symlink to `/private/tmp`. `gc register` canonicalizes its cwd to `/private/tmp/...` before starting dolt, so the running `dolt sql-server` process has `--config /private/tmp/.../dolt-config.yaml` in its argv. When `gc rig add` runs next, it re-derives `CONFIG_FILE` from the un-canonicalized cwd (`/tmp/...`) and calls `verify_our_server` in `gc-beads-bd.sh`, which string-matches the process argv. The two paths don't match as strings, gc concludes "that dolt is not ours", falls through to start-a-new-dolt — which collides on `flock` with the real one — and dies blaming the lock.

Verified by running `gc dolt-state probe-managed --city /tmp/X --port <running-port>`: it correctly sees the dolt process but reports `port_holder_owned false` purely because of the `/tmp` vs `/private/tmp` prefix. Using the canonical `/private/tmp/...` cwd throughout makes `gc rig add` succeed with the existing dolt still running and serving beads (which is what we want — dolt *is* beads storage).

**Fix applied in automated coverage:** scratch roots are resolved through
`pwd -P` so every per-lesson scratch path is canonical before `gc register` or
`gc rig add` ever see it. No dolt killing, no respawn dance. Dolt stays up
across the whole run.

**Student-facing impact:** Any student whose `my-factory/` lives under a symlinked path (`/tmp/...`, or a project checkout under a `~` that resolves through a symlink) will hit this during L2 onward. The lab READMEs should either tell students to `cd "$(pwd -P)"` before `gc register`, or the upstream gc fix should canonicalize in `verify_our_server` / the dolt-state probe. Track at `workshop:gc-rig-add-path-canonicalization`.

Attempts that did **not** work (recorded so nobody re-tries them):
- 15s delay between register and rig-add — same failure; this is not a race.
- `gc stop` between them — dolt survives, lock persists.
- Killing dolt before rig-add — fixes the lock collision at the cost of leaving beads storage down; the supervisor respawns dolt but now there's a fresh race.

Remove this section once gc's rig-add canonicalizes paths before the ownership check.

---

## 14. Pipeline handoff: one fresh bead per stage (validated empirically)

Each pipeline stage gets its own fresh bead. Beads are not meant to be re-slung — each one represents a discrete unit of work for a specific agent, and handoff happens by creating a new bead for the next agent.

Validated live end-to-end on gc 0.15.2, Planner->Architect->Designer->Builder
with tests green:

```bash
# Root bead starts the pipeline.
bd create --title "Feature: <name>" --labels needs-plan
gc sling --nudge your-project--planner <root-bead>

# Each subsequent stage creates a fresh bead. Once the upstream agent
# has produced its artifact, file the next bead and sling.
bd create --title "Architecture: <name>" --labels needs-architecture
gc sling --nudge your-project--architect <new-bead>

bd create --title "Design: <name>" --labels needs-design
gc sling --nudge your-project--designer <new-bead>

bd create --title "Build: <name>" --labels ready-to-build
gc sling --nudge your-project--builder <new-bead>
```

The target agent's `scale_check` filters on the stage label plus `gc.routed_to` metadata (set by `gc sling`). It doesn't read the dep graph — so `--deps` is **optional audit metadata**, not a mechanical requirement. Students can add `bd link <new-bead> <upstream-bead>` later if they want the audit trail.

`--nudge` ensures the target session submits the prompt even if the tmux Enter keystroke races with Claude Code's welcome-screen animation (see §15).

### Flag corrections (fixed in this pass)

The canonical `bd create` flag name is NOT what several curriculum READMEs used to say. Correct name, verified against `bd create --help`:

| Wrong (as written) | Correct                       | Notes |
|--------------------|-------------------------------|-------|
| `--label <name>`   | `--labels <name>` (plural)    | Single-form errors out. |
| `--depends-on <id>`| `--deps blocks:<id>` (optional) | Downstream agents' `scale_check` doesn't read the dep graph, so student flows can omit it entirely. |

**Student impact of the pre-fix state:** students typing the wrong form got "unknown flag" and stalled at the first stage of any pipeline. Both forms were common across L2/L3/L4/C1 curriculum and activity READMEs.

Fix status: swept in this pass. Activity-side READMEs (`activities/labs/L{2,3,4}/`, `activities/capstone/C1/`) and curriculum-side READMEs (`curriculum/labs/L{2,3,4}/`, `curriculum/capstone/C1/`, `curriculum/workshops/W3/`) all corrected. If a new curriculum file lands with either wrong form, the greps in §9 will catch it.

### Automated coverage reuses student commands verbatim

The automated coverage uses exactly `bd create --title "..." --labels <label>`
with no `--deps`. The coverage and the READMEs use the same command shape, so
when the check passes, the student can copy the same sequence into their
factory and succeed.

---

## 15. gc sling race with Claude Code welcome-screen animation

Observed via `gc session peek <id>` on a stuck Planner session:

```
❯ Run 'gc prime', then check bd ready --label=needs-plan for work.
```

The prompt text was in the session's input buffer, but never submitted. "LAST ACTIVE" kept climbing with no session output. `gc sling` had been issued minutes earlier, reported `Slung <bead> → rig/planner.planner`, and everything looked healthy from the outside.

Root cause appears to be a race between the Enter keystroke `gc sling` injects via tmux and Claude Code's welcome-screen animation — if Enter arrives before the input area is ready to accept it, it gets dropped, and the session sits forever with a typed-but-not-submitted prompt.

**Workaround in automated coverage:** pass `--nudge` to `gc sling`, which
invokes the runtime provider's nudge path after routing. That path drives input
submission independently of the broken tmux keystroke path, so the session
starts processing regardless of whether the initial Enter was dropped.

**Student-facing guidance:** the activity READMEs for L2/L3/L4/C1 each have a "When an agent seems stuck" section that walks through the symptoms (no active session, bead assignee set, no artifact) and the recovery command sequence. See those README sections directly — students don't need to read this file to unstick themselves. Track upstream fix at `workshop:gc-sling-enter-race`; once gc submits Enter reliably the `--nudge` flag is no longer load-bearing.
