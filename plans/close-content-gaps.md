# Plan: Close Content Gaps While Keeping FormulaV2 Architecture

## Context

The `csells/port-to-packs-v2` branch has a better architecture (FormulaV2 graphs, self-contained lesson packs, progressive complexity) but lost several teaching concepts from origin/main. This plan closes those gaps through a mix of pack fixes, curriculum deepening, and structural tightening — without reverting to label-based routing or adding new sessions.

The guiding principle: **FormulaV2 for routing is non-negotiable. Everything else from the original that made students learn better should come back.**

---

## Phase 1: Fix the Manifest Bug

The L4 and C1 reviewer/release-gate prompts never read `PROJECT_MANIFEST.md`. This means Review Standards and Release Criteria are decorative — changing them changes nothing. This is a bug, not a gap.

### 1a. L4 reviewer prompt — `packs/lessons/L4/agents/reviewer/prompt.template.md`

Add to **Inputs** section (after line 17):
```
- The project manifest at `docs/PROJECT_MANIFEST.md` or
  `my-factory/PROJECT_MANIFEST.md` — specifically the Review Standards
  section. If Review Standards exist, they are authoritative for this review.
```

Add to **Graph Work Process** (after step 3, "Read the upstream artifacts"):
```
3a. Read the project manifest. If a Review Standards section exists, use its
    categories and severity rules to structure findings. Cite the standard
    each finding violates.
```

### 1b. L4 release-gate prompt — `packs/lessons/L4/agents/release-gate/prompt.template.md`

Add to **Inputs** (after line 17):
```
- The project manifest at `docs/PROJECT_MANIFEST.md` or
  `my-factory/PROJECT_MANIFEST.md` — specifically the Release Criteria
  section. If Release Criteria exist, each criterion must appear in
  Required Checks with a PASS or FAIL verdict and evidence.
```

Add to **Graph Work Process** (after step 3):
```
3a. Read the project manifest. If a Release Criteria section exists,
    evaluate each criterion individually in Required Checks.
```

### 1c. C1 reviewer prompt — `packs/lessons/C1/agents/reviewer/prompt.template.md`

Same changes as 1a.

### 1d. C1 release-gate prompt — `packs/lessons/C1/agents/release-gate/prompt.template.md`

Same changes as 1b.

### Files changed
- `packs/lessons/L4/agents/reviewer/prompt.template.md`
- `packs/lessons/L4/agents/release-gate/prompt.template.md`
- `packs/lessons/C1/agents/reviewer/prompt.template.md`
- `packs/lessons/C1/agents/release-gate/prompt.template.md`

---

## Phase 2: Trim L1 to ~15 Minutes

**Problem:** Students currently go through W1 (~60 min), L1 (~45 min), and W2 (~45 min) before seeing agents run in L2. That's ~2.5 hours of design and setup.

**Root cause:** L1 asks students to write CLAUDE.md from scratch, fill in a detailed PROJECT_MANIFEST.md, and create a decision log. But W1 already produced the workflow card that seeds CLAUDE.md. L1 is duplicating work.

**Fix:** L1 becomes "convert your W1 output to agent config and stand up the runtime." The manifest starts minimal and grows incrementally (Review Standards added before L4, Release Criteria before C1).

### Rewritten L1 — `curriculum/labs/L1/README.md`

New structure (~15 min estimated):

```markdown
# L1 · Set Up the Factory Runtime

L1 converts the workflow card from W1 into agent-readable config and
registers your project with Gas City. You are not running agents yet —
that starts in L2.

## Goal

By the end of L1:
- Your W1 workflow card is converted to a CLAUDE.md
- A minimal project manifest is in place
- Gas City is registered with FormulaV2 enabled
- Your project rig is ready for L2

## 1. Convert Your Workflow Card to CLAUDE.md (~5 min)

Your W1 workflow card already contains your project rules. Convert it:

    cd /path/to/your-project
    $EDITOR CLAUDE.md

Map from your workflow card:

| W1 Section | CLAUDE.md Equivalent |
|------------|---------------------|
| Prompt Template | Project purpose, tech stack, build/test/lint commands |
| Context Reset Rule | Session lifecycle notes |
| Iteration Loop | Coding standards, source layout |
| Decision Checkpoint | Files agents must not edit, decisions requiring approval |

Keep it concrete. Every bullet should name a file, command, or specific rule.

## 2. Create a Minimal Project Manifest (~3 min)

    cd /path/to/software-factory-intensive
    cp curriculum/PROJECT_MANIFEST_TEMPLATE.md my-factory/PROJECT_MANIFEST.md
    $EDITOR my-factory/PROJECT_MANIFEST.md

Fill in only these sections now:
- overview
- tech stack
- project structure

You will add Review Standards before L4 and Release Criteria before C1,
when the agents that read them are introduced.

## 3. Register the City (~5 min)

    cp my-factory/pack.toml.template my-factory/pack.toml
    cp my-factory/city.toml.template my-factory/city.toml

Confirm FormulaV2 is enabled in `my-factory/city.toml`:

    [daemon]
    formula_v2 = true

Register and add your project rig:

    cd my-factory
    gc register .
    gc rig add /path/to/your-project
    gc doctor --fix
    gc status

## 4. Verify (~2 min)

    cd /path/to/your-project
    git status --short
    npm test   # or your project's equivalent

If a command fails, fix CLAUDE.md before moving on.

## Exit Criteria

- [ ] CLAUDE.md exists in the project rig with project-specific rules.
- [ ] my-factory/PROJECT_MANIFEST.md has overview, tech stack, project structure.
- [ ] my-factory/city.toml enables FormulaV2.
- [ ] my-factory/pack.toml selects ../packs/lessons/L2.
- [ ] gc status shows your city and project rig.

## Next

L2 is next. You keep this same rig, sync it to the L2 factory pack, and
sling your first feature request to the Planner.
```

### Also update
- `activities/labs/L1/README.md` — trim to match (remove DECISIONS.md as a required deliverable; students can still create one but it's not a gate)
- `curriculum/labs/L1/PROMPT.md` — update facilitation prompt for trimmed scope

### Files changed
- `curriculum/labs/L1/README.md`
- `activities/labs/L1/README.md`
- `curriculum/labs/L1/PROMPT.md` (if it exists)

---

## Phase 3: Config-Over-Chat + MCP Integration Exercises

The core discipline ("config persists, chat doesn't") is introduced in W1 but never practiced in the labs. The original curriculum also had students attach real MCP/CLI capabilities in L2 (planner + architect) and L3 (designer + coder). These combine naturally: adding an MCP to an agent overlay IS a config-over-chat exercise. The packs ship clean; students modify them.

### 3a. L2: Attach a Capability to Planner or Architect — `curriculum/labs/L2/README.md`

After Part 4 (Inspect The Artifacts), add:

```markdown
## Part 5: Attach a Real Capability

The planner and architect currently work from project context alone.
Ground one of them in a real external system.

### Choose one capability to attach

| Capability | Agent | What It Adds |
|-----------|-------|-------------|
| GitHub MCP | Architect | Read existing code, PRs, issues |
| Linear/Jira MCP | Planner | Pull real tickets as input |
| Context7 MCP | Architect | Up-to-date library docs |
| `actual status` CLI | Planner | Project health data |

### Wire it up

1. Inspect the workshop pack for examples:

       cat packs/workshop/overlay/.claude/settings.json | head -20

2. Add the MCP to your chosen agent's overlay:

       $EDITOR packs/lessons/L2/agents/planner/overlay/.claude/settings.json

   Add an mcpServers section. Example for GitHub:

       "mcpServers": {
         "github": {
           "type": "http",
           "url": "https://api.githubcopilot.com/mcp/",
           "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
         }
       }

3. Edit the agent's prompt to name the new capability:

       $EDITOR packs/lessons/L2/agents/planner/prompt.template.md

   Add one line to the Inputs section, e.g.: "When available, use the
   GitHub MCP to check existing code before scoping work."

4. Restart and re-sling:

       export GITHUB_TOKEN=<your-token>  # or whichever credential
       gc restart
       gc sling <rig>/factory.planner "Plan <another feature>" \
         --on mol-feature-intake

5. Compare the two plan artifacts. Did the external tool change the
   output? Record what you changed in activities/labs/L2/notes.md.

MCPs are the bridge between LLM knowledge and project-specific reality.
Without them, agents invent reality. With them, agents check reality.
```

Update exit criteria: "[ ] One capability attached and one prompt edit produced a visible artifact change."

### 3b. L3: Attach a Capability to Designer or Builder — `curriculum/labs/L3/README.md`

After step 6 (Inspect Outputs), add similar section. L3 adds designer and builder — students attach an MCP to one of those:

| Capability | Agent | What It Adds |
|-----------|-------|-------------|
| GitHub MCP | Builder | Create branches, read existing files |
| Sentry MCP | Builder | Check existing errors before coding |
| Context7 MCP | Designer | Up-to-date framework docs for design |

Same 5-step process: inspect workshop pack, add to overlay, edit prompt, restart, compare.

Update exit criteria: "[ ] One capability attached to designer or builder."

### 3c. L4: Manifest Load-Bearing Proof — `curriculum/labs/L4/README.md`

After step 6 (Inspect Outputs), add:

```markdown
## 7. Prove the Manifest is Load-Bearing

Before this step, flesh out `my-factory/PROJECT_MANIFEST.md`:
- Add at least 4 Review Standards with checkable rules and severity
- Add at least 6 Release Criteria with binary PASS/FAIL gates

Then re-sling with a new feature:

    gc sling <rig>/factory.planner \
      "Add a <different feature>" --on mol-delivery-review

Compare the review and release-gate artifacts from this run to the
previous run. The reviewer should cite your Review Standards. The
release gate should evaluate each Release Criterion.

If the manifest change produced no visible difference, the prompt needs
strengthening — which is itself a W4 feedback rule.
```

This is L4's config-over-chat exercise: students edit the manifest (config), see it change reviewer and release-gate behavior, and learn that the manifest is load-bearing, not decorative.

### Files changed
- `curriculum/labs/L2/README.md`
- `curriculum/labs/L3/README.md`
- `curriculum/labs/L4/README.md`
- `activities/labs/L2/README.md` (update exit criteria)
- `activities/labs/L3/README.md` (update exit criteria)
- `activities/labs/L4/README.md` (update exit criteria)

---

## Phase 4: Connect W1 to L2 Prompts

W1 already has a mapping table (lines 515-533) connecting workflow card sections to prompt sections. But L2 never asks students to make this connection themselves.

### 4a. L2 — `curriculum/labs/L2/README.md`

In Part 2 (Read The Lesson Pack), after listing the files to open, add:

```markdown
Compare the planner prompt to your W1 workflow card:

| Your Workflow Card | Planner Prompt Section |
|-------------------|----------------------|
| Prompt Template | `## Inputs` — what context the agent reads |
| Context Reset Rule | `wake_mode = "fresh"` in agent.toml |
| Iteration Loop | `## Graph Work Process` — the work loop |
| Decision Checkpoint | `## Role` — scope of authority, what to escalate |

Your workflow card described how *you* work with one agent. The planner
prompt describes how *the planner agent* works inside a factory. Same
structure, different scope.
```

### Files changed
- `curriculum/labs/L2/README.md`

---

## Phase 5: Enhance Observability

### 5a. Status commands — all four lesson packs

Replace static echo statements with live graph/bead state.

**Pattern for each `commands/status/run.sh`:**
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "<Formula-name> factory"
echo
echo "Formula: <formula-name>"
echo "Agents:  <agent list>"
echo
echo "Recent work:"
bd list --limit 5 2>/dev/null || echo "  (no beads yet)"
echo
echo "Active sessions:"
gc session list 2>/dev/null | head -10 || echo "  (none)"
```

Apply to:
- `packs/lessons/L2/commands/status/run.sh`
- `packs/lessons/L3/commands/status/run.sh`
- `packs/lessons/L4/commands/status/run.sh`
- `packs/lessons/C1/commands/status/run.sh`

### 5b. Observability table in L2 — `curriculum/labs/L2/README.md`

After Part 3 (Run The Formula), add:

```markdown
## Observability Commands

These are your windows into a running factory. Practice all six while L2
runs:

| Command | What It Shows |
|---------|---------------|
| `gc events --follow` | Live event stream (agent wakes, step transitions) |
| `gc session list` | Active and recent agent sessions |
| `gc session peek <id>` | Live view of what an agent is doing now |
| `gc graph <bead-id>` | Formula step state graph |
| `bd list` | All beads in the current rig |
| `bd show <id>` | Detailed bead state and metadata |

You will use these throughout L3, L4, and C1.
```

### 5c. Observability reminders in L3 and L4

After step 5 (Watch Progress) in each, add one line:
- L3: "Use all six observability commands from L2. Watch the four-agent handoff."
- L4: "Use the observability commands from L2. Watch for review findings and release verdicts."

### Files changed
- `packs/lessons/L2/commands/status/run.sh`
- `packs/lessons/L3/commands/status/run.sh`
- `packs/lessons/L4/commands/status/run.sh`
- `packs/lessons/C1/commands/status/run.sh`
- `curriculum/labs/L2/README.md`
- `curriculum/labs/L3/README.md`
- `curriculum/labs/L4/README.md`

---

## Phase 6: Deepen W2 and W3

### 6a. Capability inventory in W2 — `curriculum/workshops/W2/README.md`

Before step 2 (Map Roles To Artifacts), add:

```markdown
## 1a. Inventory Your Current Capabilities

Before mapping roles, catalog what your factory can use:

| Category | What You Have | Relevant Roles |
|----------|---------------|----------------|
| AI Models | Claude via Claude Code | All agents |
| CLI Tools | npm, gh, your test runner | Builder, Release Gate |
| MCP Servers | GitHub, Sentry, etc. | Reviewer, Architect |
| Project Instructions | CLAUDE.md, AGENTS.md | All agents |
| Knowledge Sources | PROJECT_MANIFEST.md, ADRs | Planner, Architect |
| External Services | Linear, Jira, etc. | Planner (via orders) |

Inspect the workshop pack to see what integrations are available:

    ls packs/workshop/orders/
    ls packs/workshop/overlay/

Compare your inventory to a lesson pack:

    find packs/lessons/L3 -maxdepth 3 -type f | sort

Map which tools would strengthen which roles in your factory-map.md.
```

Update `activities/workshops/W2/README.md` to add capabilities table as a deliverable subsection.

### 6b. Decision boundaries + orders in W3 — `curriculum/workshops/W3/README.md`

After step 3 (Decide Where Judgment Lives), add:

```markdown
## 3a. Define Decision Boundaries

For each category, decide what stays with you and what goes to agents:

| Decision | Human or Agent? | Rationale |
|----------|----------------|-----------|
| Database schema changes | Human | Irreversible |
| New dependencies | Human | Security burden |
| API contract changes | Human | Cross-system |
| Function internals | Agent (Builder) | Contained in scope |
| Test case design | Agent (Builder) | Follows acceptance criteria |
| Review severity | Agent (Reviewer) | Follows Review Standards |
| Release verdict | Agent (Release Gate) | Follows Release Criteria |

Customize for your project and add to formula-design.md. Connect this
to your W1 Decision Checkpoint — same concept, factory-level scope.
```

After step 6 (Compare Against C1), add:

```markdown
## 7. Orders as External Triggers

Formula graphs handle step-to-step coordination inside a factory run.
External events — new tickets arriving, periodic health checks — need
orders.

Inspect the workshop pack's tracker sync:

    cat packs/workshop/orders/sync-linear.toml

Notice the structure:
- `gate = "cooldown"` — fires after an interval elapses
- `interval = "5m"` — every 5 minutes
- `exec = "bd linear sync || true"` — the command to run

Orders are for real external triggers, not for passing work between
formula steps. In your formula-design.md, identify one external trigger
your factory would need and describe it as an order.

## Coordination Beyond Graphs

For observing and debugging agent work:

| Tool | Purpose |
|------|---------|
| `gc session peek <id>` | See what an agent is doing now |
| `gc events --follow` | Stream factory events |
| `gc graph <bead-id>` | Inspect formula step states |

These are observability tools, not workflow dispatch.
```

Update `activities/workshops/W3/README.md` to add decision boundaries and order design as deliverables.

### Files changed
- `curriculum/workshops/W2/README.md`
- `curriculum/workshops/W3/README.md`
- `activities/workshops/W2/README.md`
- `activities/workshops/W3/README.md`
- `curriculum/workshops/W2/PROMPT.md`
- `curriculum/workshops/W3/PROMPT.md`

---

## Phase 7: Measurement + Retrospective Loop (W4 + C1)

### 7a. Measurement in W4 — `curriculum/workshops/W4/README.md`

After step 4 (Apply One Small Rule), add:

```markdown
## 5. Measure One Improvement

A rule that doesn't change behavior isn't a rule yet. Pick one measurable
signal from your feedback rules:

1. Record the before-state from your most recent L4 or C1 run (e.g.,
   reviewer finding count, release gate verdict, test pass rate).
2. Apply the config change (step 4).
3. Re-sling the same formula with a similar feature request.
4. Record the after-state.

| Metric | Before | After | Change Applied | File |
|--------|--------|-------|----------------|------|
| | | | | |

Add a Measurement section to your feedback rule files after Verification:

    ## Measurement
    What metric did you check? What was the before/after?
```

Update exit criteria: "[ ] At least one rule includes before/after measurement from a factory run."

### 7b. Retrospective in C1 — `curriculum/capstone/C1/README.md`

After step 6 (Inspect Outputs), add:

```markdown
## 7. Write the Retrospective

Create activities/capstone/C1/retrospective.md:

    # Factory Run Retrospective

    ## Run Summary
    - Feature:
    - Root bead:
    - Formula: mol-release-delivery
    - Stages completed:

    ## What Worked
    - [observation with artifact evidence]

    ## What Didn't Work
    - [observation with root cause]

    ## W4 Improvement Criteria Applied

    Revisit your W4 feedback rules. For each rule you applied:

    | Rule | Signal Observed? | Metric Before | Metric After |
    |------|-----------------|---------------|--------------|

    ## Config Changes Made During This Run
    | File | Change | Why |
    |------|--------|-----|

    ## What I Would Change Before the Next Run
```

The W4 section is what connects the retrospective to the improvement loop. Students evaluate their C1 run against their own W4 criteria.

Update `activities/capstone/C1/README.md` exit criteria:
- "[ ] Retrospective exists with at least one W4 criterion evaluated."
- "[ ] At least one config change is documented with file and reason."

### Files changed
- `curriculum/workshops/W4/README.md`
- `curriculum/capstone/C1/README.md`
- `activities/workshops/W4/README.md`
- `activities/capstone/C1/README.md`
- `curriculum/workshops/W4/PROMPT.md`
- `curriculum/capstone/C1/PROMPT.md`

---

## Phase 8: Fix W1 Stale Reference

### 8a. W1 line 35 — `curriculum/workshops/W1/README.md`

Line 35 says "Enforced by orchestrator + feedback rules (W3/W4)". This should say "Enforced by formula graphs + feedback rules (W3/W4)" to match the new architecture.

### 8b. MCP mention in W2

The original curriculum mentioned MCP integration. Add a brief callout in W2 after the capability inventory:

```markdown
MCP servers give agents tool access to external systems (GitHub, Sentry,
issue trackers). The workshop pack at packs/workshop/ pre-configures
common integrations. When you're ready, add MCP servers to your lesson
pack's agent overlays. See packs/workshop/overlay/.claude/settings.json
for examples.
```

### Files changed
- `curriculum/workshops/W1/README.md`
- `curriculum/workshops/W2/README.md`

---

## Does This Close the Gap?

### What the original taught → how the new version covers it

| Original Concept | New Coverage | Status |
|-----------------|-------------|--------|
| Install Gas City, set up city | L1 (trimmed to 15 min) | Covered, faster |
| Run a demo factory (W1 "wow moment") | L2 (session 3, ~75 min into course) | Covered — 75 min vs original's ~120 min |
| Labeled beads / routing protocol | FormulaV2 graphs (L2+) | **Better** — declarative > label scanning |
| Observability (dashboard, bd, gc events) | L2 observability table + live status commands | Covered |
| Capability inventory | W2 tool catalog + inventory step | Covered |
| Map capabilities to stages | W2 factory-map.md | Covered |
| MCP/CLI integration | L2: attach MCP to planner/architect, L3: attach MCP to designer/builder | **Covered** — hands-on, same scope as original |
| 5 coordination channels | W3: FormulaV2 graphs + orders as external triggers | Covered (Mail/Nudge dropped — FormulaV2 does their job) |
| Decision boundaries | W3 decision boundary table | Covered |
| Improvement criteria with targets | W4 feedback rules + measurement step | Covered |
| Prove change moved metrics | W4 before/after measurement | Covered |
| PROJECT_MANIFEST.md creation | L1 (minimal) → L4 (flesh out before review) | Covered, incremental |
| Review Standards in manifest | L4 manifest proof exercise + fixed reviewer prompt | **Better** — actually proven load-bearing |
| Release Criteria in manifest | L4 manifest proof + fixed release-gate prompt | **Better** — actually used by agent |
| Attach MCP to agents | L2 + L3 hands-on exercises | **Covered** — same labs as original |
| Config-over-chat discipline | Every lab (L2, L3, L4) has explicit exercise | **Better** — practiced 3x vs mentioned 1x |
| Workflow card → agent prompts | W1 produces card, L2 explicitly maps it to prompts | **Better** — connection made explicit |
| Full factory run | C1 (7 agents, single gc sling) | Covered |
| Retrospective | C1 retrospective connected to W4 criteria | **Better** — closed improvement loop |
| Factory iterations log | C1 factory-iterations.md | Covered |
| Validator role | C1 (new, not in original) | **Gained** |
| Self-contained packs | All lessons | **Gained** — inspect one folder, see entire factory |
| Progressive complexity | 2→4→6→7 agents | **Gained** — vs original's all-at-once |

### What's genuinely lost
- **Mail and Nudge** — FormulaV2 handles what they did
- **Session attach for human steering** — mentioned as observability tool

### Verdict
Yes, this closes the gap. Every substantive teaching concept from the original is covered. Five concepts are covered **better** (config-over-chat, manifest proof, retrospective loop, W1→prompt connection, MCP as config-over-chat). The only things lost (Mail/Nudge) are replaced by FormulaV2.

---

## Complete File List

### Pack files (runtime)
| File | Change |
|------|--------|
| `packs/lessons/L4/agents/reviewer/prompt.template.md` | Add manifest reference |
| `packs/lessons/L4/agents/release-gate/prompt.template.md` | Add manifest reference |
| `packs/lessons/C1/agents/reviewer/prompt.template.md` | Add manifest reference |
| `packs/lessons/C1/agents/release-gate/prompt.template.md` | Add manifest reference |
| `packs/lessons/L2/commands/status/run.sh` | Live bead/session output |
| `packs/lessons/L3/commands/status/run.sh` | Live bead/session output |
| `packs/lessons/L4/commands/status/run.sh` | Live bead/session output |
| `packs/lessons/C1/commands/status/run.sh` | Live bead/session output |

### Curriculum READMEs
| File | Change |
|------|--------|
| `curriculum/labs/L1/README.md` | Trim to 15-min setup |
| `curriculum/labs/L2/README.md` | W1→prompt mapping, observability, MCP exercise (planner/architect) |
| `curriculum/labs/L3/README.md` | Observability reminder, MCP exercise (designer/builder) |
| `curriculum/labs/L4/README.md` | Observability reminder, manifest proof + config-over-chat |
| `curriculum/workshops/W1/README.md` | Fix stale "orchestrator" reference |
| `curriculum/workshops/W2/README.md` | Capability inventory, MCP mention |
| `curriculum/workshops/W3/README.md` | Decision boundaries, orders as triggers |
| `curriculum/workshops/W4/README.md` | Measurement step |
| `curriculum/capstone/C1/README.md` | Retrospective connected to W4 |

### Activity READMEs
| File | Change |
|------|--------|
| `activities/labs/L1/README.md` | Trim to match |
| `activities/labs/L2/README.md` | MCP + config-over-chat exit criterion |
| `activities/labs/L3/README.md` | MCP + config-over-chat exit criterion |
| `activities/labs/L4/README.md` | Manifest proof exit criterion |
| `activities/workshops/W2/README.md` | Capabilities deliverable |
| `activities/workshops/W3/README.md` | Decision boundaries + orders deliverables |
| `activities/workshops/W4/README.md` | Measurement exit criterion |
| `activities/capstone/C1/README.md` | Retrospective deliverable |

### PROMPT.md files
| File | Change |
|------|--------|
| `curriculum/labs/L1/PROMPT.md` | Update for trimmed scope |
| `curriculum/workshops/W2/PROMPT.md` | Inventory guidance |
| `curriculum/workshops/W3/PROMPT.md` | Decision boundaries + orders guidance |
| `curriculum/workshops/W4/PROMPT.md` | Measurement guidance |
| `curriculum/capstone/C1/PROMPT.md` | Retrospective guidance |

---

## Verification

### Runtime continuity (before and after)
```bash
run the lesson pack linter for L2 without the repository scan
run the lesson pack linter for L3 without the repository scan
run the lesson pack linter for L4 without the repository scan
run the lesson pack linter for C1 without the repository scan
run the repository migration check
run the repository smoke check
```

### No old patterns introduced
```bash
rg 'gc all wake-downstream|bd ready --label|bd create .*--labels?' curriculum activities packs/lessons
rg 'packs/all|default_rig_includes|wake-downstream' curriculum activities
rg 'orchestrator.yaml' curriculum activities  # except W1 historical mention
```

### Manual verification
- Run L4 with empty vs populated Review Standards — review findings should differ
- Run status command — should show live bead/session data
- Time L1 walkthrough — should complete in ~15 minutes
