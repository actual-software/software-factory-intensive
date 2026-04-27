# Fix stale docs on csells/port-to-packs-v2 before workshop-author handoff (v4)

## Context

The Pack v1 → v2 migration on branch `csells/port-to-packs-v2` landed with correct TOML (`gc doctor` on a fresh clone + templates reports **33 passed, 12 warnings, 2 failed**). The two failures — `system-formulas` (cleared by `gc doctor --fix`) and `beads-store` (cleared by `chmod 700 .beads` + `gc start` running dolt) — are expected pre-fixup state. The migration and smoke checks both pass. Schema, agent/command/doctor/order/formula layouts, and import syntax check out against `~/temp/gascity` source and installed `gc 0.15.0`.

The **docs** carry three classes of bugs:

1. **Wrong CLI invocations** — commands that don't exist (`gc poke`, `gc watch`, `gc orchestrate`, `gc session stop`) or that now require flags (`gc service restart <name>`).
2. **Stale v1 paths and syntax** — `examples/actual/`, `includes = [...]`, `./scripts/sync-*`, `overlays/default/`, flat `commands/*.sh`, `[[agent]]` blocks, `prompt_template =`, `overlay_dir =`.
3. **Wrong or unverifiable runtime claims** — what `gc register` mutates, what `gc doctor` output students should expect, which MCP servers ship, which deprecation-warning text gc 0.15 actually emits.

**Review-council history:**
- **v1** — Claude + Gemini flagged a bogus `city.toml.template:19` fix (GitHub issue ref `workshop:#781`, not a property name) and a scope gap: stale content spans `curriculum/**`, `activities/**`, `activites/` checkpoints.
- **v2** — broadened scope. Codex round 2 found: (a) `gc rig add --include` is a no-op on existing rigs (`cmd_rig.go:265-267`); (b) three phantom commands (`gc watch` 40 hits, `gc orchestrate`, `gc session stop`) pepper curriculum; (c) L3, L4, C1 also teach `[[agent]]` blocks.
- **v3** — moved all curriculum to author-rewrite, used `[rigs.imports.<binding>]` for mid-rig pack swaps, switched verification to `rg -n` with `-g` excludes.
- **v4 (this plan)** — Claude + Codex round-3 findings applied:
  - Added L2/L3/L4 PROMPT.md to author-notes (also contain `includes = [...]` / `gc service restart`).
  - Retargeted `activities/README.md` fix to line 17 (real stale prose) instead of 20/26/34.
  - Rewrote `bd config` deletion rationale: my-factory/ DOES have ancestor store at repo-root `.beads/`; bug is "writes to wrong store" not "no ancestor store."
  - Dropped `.gitattributes` chmod fallback (git doesn't preserve dir perms; `.beads/` is gitignored anyway).
  - Fixed `gc doctor >` redirect to `2>&1` (gc doctor writes to STDERR).
  - Fixed `gc service restart` regex to catch `&& gc doctor` pattern, added `-g '!curriculum/**'` exclude.
  - Replaced `tree` dependency with `find` / `rg --files` in verification.
  - Corrected `gc start <path>` rationale — shape is valid in 0.15; stale pattern is the path `examples/actual/` only.
  - Added `reference-project/fired-up-pizza/README.md` to in-scope sweep (line 23 `gc rig add --include` on existing rig; line 35 stale `scripts/import-tickets.sh`).
  - Dropped stale hit counts in favor of grep-driven regeneration.
  - Added `.tmp/` .gitignore entry (scratch review-city directory found uncommitted at repo root).

**Goal:** every docs claim in the branch verifiable against `gc 0.15.0` and the current on-disk state. No changes to TOML, scripts, or pack structure.

**Out of scope:** `activites/` → `activities/` directory rename (own PR per original migration Principle 1). Fix stale doc content inside whichever tree contains it without merging, moving, or renaming directories.

## Verified bugs to fix, by file

### Tier 1 — student-facing quickstart (will bite on first run)

**`my-factory/README.md`**
- Line ~96: delete the `gc poke   # or wait for the 30s patrol tick` line entirely. `gc poke` doesn't exist as a top-level command (only `gc convoy poke` exists, and it's control-dispatch-specific). "Wait up to 30s for the patrol tick" is already the correct action; no replacement command.
- Line ~129: sentence says `gc poke forces a reconcile tick but does not re-read pack files.` Phantom-command leftover. **Fix:** rewrite to "`gc convoy poke` only re-dispatches pending convoy work; there is no user-facing force-reload for pack/config in 0.15.x — the 30s patrol tick is the reload trigger."
- Line ~106: prints `⚠ v2-default-rig-import-format — workshop.default_rig_includes is deprecated…`; real text from `gc doctor` is `workspace.default_rig_includes`. **Fix:** change `workshop.` → `workspace.`. Also append the real `hint: run "gc doctor --fix" to rewrite safe mechanical cases` line.
- Lines ~13, ~44: claim `pack.toml` is "mutated by `gc register --name`." Verified in `~/temp/gascity/cmd/gc/cmd_register.go:26-29` — only `city.toml` workspace.name is persisted. **Fix:** line ~13 — drop "mutated by `gc register --name`" from the `pack.toml` row. Line ~44 — rewrite to "`gc register --name` mutates `city.toml` workspace.name only; `gc rig add` appends `[[rigs]]` to `city.toml`. `pack.toml` is not mutated by either."
- Line ~75: first `bd config set types.custom "convoy"` runs from `my-factory/`. bd walks up looking for `.beads/`; **the repo root does have a `.beads/` directory** (it's gitignored at `.gitignore:5` but exists on any machine where someone has done prior bd work). So the command resolves — but writes to the **factory repo's store** instead of the student's rig. The second line (inside `~/Projects/your-project`) writes to the correct per-rig store. **Fix:** delete the first line.
- Lines ~101-114 ("Expected `gc doctor` output"): names only 2 warnings; reality is 2 failed + 12 warnings. **Fix:** rewrite to show real counts (33 pass / 12 warn / 2 fail on fresh clone). Explain:
  - `system-formulas` fails until `gc doctor --fix` runs (re-materializes built-in formulas).
  - `beads-store` fails until `chmod 700 .beads` is run (fresh clones always have the default 0755 mode; this is a permission-bit gap that git can't ship around) AND a dolt server is running (from `gc start`).
  - Most remaining 12 warnings are missing integration tokens (`GITHUB_TOKEN`, `LINEAR_API_KEY`, cloud CLIs) — safe to ignore unless that integration is needed.
  - Two deprecation warnings (`v2-default-rig-import-format`, `v2-workspace-name`) are intentional per migration plan gap ledger entries G5/#781 and G8/#600.
- Add explicit `chmod 700 .beads` step to the quickstart sequence, between `gc rig add` and `gc start`.

**`README.md` (top-level)**
- Line ~116: repeats the `pack.toml` mutation claim from `my-factory/README.md:13`. **Fix:** same correction.

### Tier 2 — pack-level READMEs

**`packs/workshop/README.md`** (line numbers approximate; executor should expect ±3 drift)
- ~Line 12-14: says the workshop pack is wired via `city.toml` includes. Actual wiring: `my-factory/pack.toml.template` imports `[imports.workshop] source = "../packs/workshop"` at workspace scope. **Fix:** update.
- ~Line 16: `gc service restart` bare; requires `<name>`. **Fix:** replace with `gc restart` (whole-city).
- ~Line 71: "Discord | `DISCORD_*` | env var" row — no Discord doctor check, no MCP entry, no env var use. **Do not auto-fix.** Flag for workshop author.
- ~Line 78: "GitLab | MCP server + bd sync" — `packs/workshop/overlay/.claude/settings.json` has MCP for github, sentry, posthog, datadog, grafana, slack, linear only. **Fix:** change GitLab row to "bd sync only."
- ~Line 88: sample `gc doctor` output shows unprefixed check ids; real output is `workshop:check-core-tools`. **Fix:** prefix sample to match.
- ~Lines 103-131: Pack Structure tree shows v1 layout. **Fix:** regenerate from actual on-disk structure via `find packs/workshop -maxdepth 3 -not -path '*/.*'` (do NOT use `tree` — not installed in this environment).

**`packs/planner/README.md`**
- ~Line 4: `examples/actual/` → `packs/`.
- ~Line 40: `./scripts/sync-actual-skill.sh` → `./assets/sync-actual-skill.sh`.
- ~Lines 89, 99: `[workspace] includes = ["examples/actual/planner"]` standalone example. **Fix:** drop the standalone TOML block; replace with `gc rig add <project> --include ../packs/planner` (first-time rig registration only; `--include` is a no-op on existing rigs per `cmd_rig.go:265-267`).

**`packs/builder/README.md`** — same class at lines ~4, ~48, ~56, ~63.

**`packs/designer/README.md`** — lines ~4, ~27, ~33 (includes fix — v3-plan missed line 33).

**`packs/validator/README.md`, `packs/reviewer/README.md`, `packs/release-gate/README.md`, `packs/improver/README.md`** — each has the stale line-4 preamble. Full-file scan for other `examples/actual/`, `./scripts/sync-`, `includes = [` while editing.

**`reference-project/fired-up-pizza/README.md`** — in scope per round-3 finding. Two hits to fix:
- ~Line 23: tells reader to re-run `gc rig add --include ...` on an existing rig. No-op per `cmd_rig.go:265-267`. **Fix:** rewrite to use `[rigs.imports.<binding>]` edited directly in `city.toml`, or explain that `--include` only applies at first-time registration.
- ~Line 35: references `packs/fired-up-pizza/scripts/import-tickets.sh` — real path on v2 is the pack command `gc fired-up-pizza import-tickets`. **Fix:** update invocation.

### Tier 3 — activities tree (mechanical sweep)

**`activities/README.md`** — "Typical session flow" and "Getting un-stuck" blocks.
- Line ~27: `gc service restart && gc doctor` → `gc restart && gc doctor`.
- Line ~35: `gc service restart` → `gc restart`.
- **Line 17** (primary stale prose): tells readers to point `my-factory/city.toml`'s `includes` at activity packs. v2 has no `includes = [...]` at city-level; rig-scope wiring is `[rigs.imports.<binding>] source = "..."`. **Fix:** rewrite line 17 to describe the `[rigs.imports.<binding>]` approach; lines 20, 26, 34 are downstream references to this prose and become correct once line 17 is rewritten (verify in edit pass).

**`activities/labs/L1/README.md` through `L4/README.md`** (phantom commands are in `curriculum/`, not `activities/`, so these are clean of `gc watch` / `gc orchestrate`; verify with grep during execution). Mechanical sweep:
- `gc service restart` → `gc restart` (including `&& gc doctor` variants).
- `gc poke` → remove (wait or `gc restart`; no replacement command).
- `examples/actual/` → `packs/`.
- `./scripts/sync-actual-skill.sh` → `./assets/sync-actual-skill.sh`.
- `overlays/default/` → `overlay/`.
- Empty `includes = []` snippets: delete the whole snippet (a rig with no imports is represented by absence of `[rigs.imports.*]`, not an empty stanza).
- Populated `includes = [...]` blocks → `[rigs.imports.<binding>] source = "..."` rewrite.

**`activities/workshops/W1-W4/README.md` and PROMPT.md** — same mechanical sweep. Note: line 70 `gc poke` is in the misspelled `activites/` tree, not here (v2-plan had the path wrong).

**`activities/workshops/W4/README.md:20`** — prose-only reference "The includes list ... does not change in W4." **Fix:** rewrite to the v2 equivalent phrasing.

**`activities/capstone/C1/README.md`** — `includes = [` city.toml example; rig-scoped rewrite.

### Tier 3b — `activites/` (sic) checkpoint trees (mechanical)

The directory rename is out of scope; doc content inside is in scope.
- `activites/workshops/W2/README.md:70` — `gc poke`; mechanical sweep.
- `activites/labs/L2/README.md:69` — `gc poke`; mechanical sweep.
- `activites/workshops/W2/gascity/step_0/packs/README.md` — checkpoint packs-root index. Stale `examples/actual/`, `./scripts/sync-actual-skill.sh`, `gc start examples/actual/`, `includes = [`. (v3-plan's glob `packs/*/README.md` missed this; use `**/README.md`.)
- `activites/labs/L2/gascity/step_0/packs/README.md` — same.
- `activites/workshops/W2/gascity/step_0/packs/<agent>/README.md` (all subdirs) — per-agent mechanical sweep.
- `activites/labs/L2/gascity/step_0/packs/<agent>/README.md` (all subdirs) — same.

### Tier 4 — minor nits

- **`my-factory/pack.toml.template:14-15`** — `workshop:#786` double-import comment. Framing accurate per `~/temp/gascity/internal/config/pack.go:880-883` dedup. Leave; verify upstream issue description matches before handoff.
- **`plans/port-to-packs-v2.md`** — historical migration reasoning; contains intentional v1 references. Leave untouched; exclude from verification greps.
- **`.gitignore`** — add `.tmp/` entry. A scratch `.tmp/review-city/` directory (`city.toml`, `pack.toml`, symlinked `packs`, plus `formulas/`, `hooks/`, `orders/`, `prompts/`) exists at repo root from earlier review work, uncommitted but also unignored. Not student-facing but shouldn't be tracked.

## Curriculum — ALL author rewrite

The entire `curriculum/**/*.md` tree is OUT of mechanical sweep. Every curriculum file contains one or more of:
- Teaching content around v1 `[[agent]]` blocks (L1, L3, L4, W3, C1).
- Phantom gc commands requiring semantic (not mechanical) replacement:
  - `gc watch <agent>` — no such command. Real equivalents depend on intent: `gc session attach` (interactive) or `gc session peek` (view without attach).
  - `gc orchestrate ...` — no such top-level command. W3 and C1 teach an orchestrator subsystem that has no corresponding v2 command.
  - `gc session stop <name>` — no such subcommand. Real: `close`, `kill`, `suspend`.

**Do not auto-fix any file under `curriculum/`.** Flag each file in `WORKSHOP_AUTHOR_NOTES.md` (step 11). Use `rg -n 'gc watch|gc orchestrate|gc session stop|\[\[agent\]\]' curriculum/ -g '*.md'` at execution time to regenerate the current hit map (hand-written counts go stale).

## Non-issues (explicitly not fixing)

- **`activites/` vs `activities/` directory rename** — out of scope.
- **W2 deployer prompt** — `agent.toml`, `overlay/`, `prompt.md` all exist. Complete.
- **`$GC_CITY_PATH` / `$PACK_DIR` framing** in `packs/all/pack.toml:14-16` — verified accurate.
- **Hot-reload table** in `my-factory/README.md:117-128` — verified accurate.
- **Discord row** (`packs/workshop/README.md:71`) — flag for author; do not edit.
- **`city.toml.template:19`** — contains GitHub issue ref `workshop:#781`, NOT the property name. Leave untouched.

## Execution plan

Per-file atomic edits. Each step's commit scoped to one logical area.

1. **`my-factory/README.md`** — all 6 Tier 1 fixes (including the new chmod 700 step and doctor-output rewrite).
2. **`README.md`** — Tier 1 fix.
3. **`packs/workshop/README.md`** — Tier 2 fixes. Regenerate Pack Structure tree via `find packs/workshop -maxdepth 3 -not -path '*/.*'`. Flag Discord row in commit message.
4. **`packs/{planner,builder,designer,validator,reviewer,release-gate,improver}/README.md`** — mechanical Tier 2 fixes including `designer/README.md:33`.
5. **`reference-project/fired-up-pizza/README.md`** — Tier 2 fixes (line 23, line 35).
6. **`activities/README.md`** — Tier 3 rewrite targeting line 17 primarily.
7. **`activities/labs/L{1,2,3,4}/**/*.md`** — mechanical Tier 3 sweep.
8. **`activities/workshops/W{1,2,3,4}/**/*.md`** — mechanical Tier 3 sweep (includes W4:20 prose).
9. **`activities/capstone/C1/README.md`** — Tier 3 rewrite.
10. **`activites/workshops/W2/README.md`, `activites/labs/L2/README.md`** — Tier 3b fixes.
11. **`activites/workshops/W2/gascity/step_0/packs/**/README.md`, `activites/labs/L2/gascity/step_0/packs/**/README.md`** — Tier 3b sweep.
12. **`.gitignore`** — add `.tmp/`.
13. **Flag file (new)**: `WORKSHOP_AUTHOR_NOTES.md` at repo root. Sections:
    - **Curriculum files requiring rewrite**: regenerate list at execution time via `rg -l 'gc watch|gc orchestrate|gc session stop|\[\[agent\]\]' curriculum/ -g '*.md'`. Expected hits (verify):
      - `curriculum/labs/L1/README.md` — `[[agent]]` tuning exercise + `gc watch` + `gc session stop`.
      - `curriculum/labs/L1/PROMPT.md` — check for includes / service-restart.
      - `curriculum/labs/L2/README.md` — `gc watch`.
      - `curriculum/labs/L2/PROMPT.md` — `includes = [...]`, `gc service restart`.
      - `curriculum/labs/L3/README.md` — `[[agent]]` instruction + `gc watch`.
      - `curriculum/labs/L3/PROMPT.md` — `includes = [...]`, `gc service restart`.
      - `curriculum/labs/L4/README.md` — `[[agent]]` instruction + `gc watch`.
      - `curriculum/labs/L4/PROMPT.md` — `includes = [...]`, `gc service restart`.
      - `curriculum/workshops/W3/README.md` — orchestrator references `[[agent]].name` + `gc orchestrate`.
      - `curriculum/workshops/W4/README.md` — `gc watch`.
      - `curriculum/capstone/C1/README.md` — `[[agent]]` city.toml example + `gc watch` + `gc orchestrate`.
      - (Re-grep at execution; this list may grow/shrink.)
    - **Specific bugs needing curriculum-author judgment** (not mechanical find-and-replace):
      - W3 orchestrator exercise: the `[[agent]].name` binding concept doesn't map to v2. Decide: rewrite to teach `agents/<n>/` directory binding, or document that orchestrate was removed.
      - L1 `[[agent]]`-block tuning: rewrite around `agents/<n>/agent.toml` tuning, not pack.toml.
      - L3/L4/C1 teaching content: same treatment.
      - Phantom-command replacements: `gc watch` → `gc session attach` (interactive) or `gc session peek` (view-only) — pick per instructional intent.
    - **`packs/workshop/README.md:71` Discord row** — verify whether Discord integration is planned; if not, remove row.
    - **`activites/` rename decision** — separate follow-up PR.
    - **`packs/workshop/README.md` MCP list** — confirm the shipped settings.json MCP set (github/sentry/posthog/datadog/grafana/slack/linear) matches intended workshop ship.

## Verification

Run from repo root after all edits. All greps use `rg -n` (ripgrep) with `-g` excludes; expected exceptions are `plans/`, `WORKSHOP_AUTHOR_NOTES.md`, and `curriculum/**` for patterns that are curriculum-only (`[[agent]]`, phantom commands, some `includes`).

1. **Stale-string greps** (must return 0 hits outside exceptions):
   ```bash
   rg -n 'gc poke' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
   rg -n 'gc service restart' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**' | rg -v 'gc service restart [A-Za-z_-]'
   rg -n 'examples/actual/' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   rg -n 'workshop\.default_rig_includes' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   rg -n 'overlays/default' packs/ -g '*.md'
   rg -n '\./scripts/sync-' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   rg -n 'includes = \[' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
   rg -n 'schema = 1' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   rg -n 'prompt_template =|overlay_dir =|formulas/orders/|\.formula\.toml' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   ```
   Note: the `gc service restart` grep uses a two-stage filter — match all occurrences, then exclude ones that are followed by what looks like a valid service name (`[A-Za-z_-]` word char). This catches `gc service restart && ...`, `gc service restart$`, and `gc service restart ;` while allowing `gc service restart foo`.

2. **Phantom-command greps** (must be clean outside `curriculum/` + exceptions):
   ```bash
   rg -n 'gc watch' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
   rg -n 'gc orchestrate' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
   rg -n 'gc session stop' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md' -g '!curriculum/**'
   rg -n 'gc start examples/actual' -g '*.md' -g '!plans/**' -g '!WORKSHOP_AUTHOR_NOTES.md'
   ```
   (`gc start <path>` is valid in 0.15 — only `gc start examples/actual/...` is stale because of the path, not the shape.)

3. **Fresh-clone smoke** — reproduce handoff experience:
   ```bash
   rm -rf /tmp/sfi-handoff
   git clone /Users/csells/Code/actual-software/software-factory-intensive /tmp/sfi-handoff
   cd /tmp/sfi-handoff/my-factory && cp pack.toml.template pack.toml && cp city.toml.template city.toml
   gc doctor > /tmp/doctor-before-start.txt 2>&1    # 2>&1 required — gc doctor writes to stderr
   ```
   - **3a.** Confirm counts match what the updated README promises (e.g., "33 passed, 12 warnings, 2 failed" on a fresh clone before `gc doctor --fix` / `chmod` / `gc start`).
   - **3b.** Confirm warning anchor IDs (`v2-default-rig-import-format`, `v2-workspace-name`) appear with `workspace.default_rig_includes` text (not `workshop.`).
   - **3c.** Verify the full setup sequence: `gc doctor --fix` (clears `system-formulas`), `chmod 700 /tmp/sfi-handoff/.beads`, `gc rig add <testproject>`, `gc start`, re-run `gc doctor`. Confirm `beads-store` and `system-formulas` both clear. Confirm the updated README's explanation matches this reality.

4. **MCP claim check**:
   ```bash
   jq -r '.mcpServers | keys[]' packs/workshop/overlay/.claude/settings.json | sort
   ```
   Must exactly match the list of MCP-enabled services the workshop README now claims.

5. **Pack Structure check**:
   ```bash
   find packs/workshop -maxdepth 3 -not -path '*/.*' | sort
   ```
   Output must match the rewritten tree in `packs/workshop/README.md`.

6. **Existing checks** — the tutorial, migration, and smoke checks still pass.

7. **Workshop-author notes file** — `WORKSHOP_AUTHOR_NOTES.md` exists at repo root. Curriculum file list in it matches current grep output.

8. **`.gitignore` check** — `git status` shows no untracked `.tmp/` entries; `git check-ignore .tmp/` returns successfully.
