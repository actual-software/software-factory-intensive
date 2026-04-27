---
name: validate-lesson-content
description: Harvest walkthrough snapshot output and update curriculum READMEs to match what walkthroughs actually produce. Walkthroughs save their output to test-harness/walkthrough-snapshots/<lesson>/. This skill reads those snapshots, compares against README claims, and updates the READMEs so students see accurate commands and output. Use whenever editing curriculum READMEs, walkthrough scripts, or lesson packs. Also trigger on "validate lessons", "update lesson content", "sync READMEs with walkthroughs", "curriculum drift", or any question about whether what students are told to do matches reality.
---

# Validate Lesson Content

Walkthroughs are the source of truth. READMEs must match what walkthroughs produce.

## How it works

1. **Walkthroughs run** (`test-harness/tutorial-walkthrough.sh L1 L2 L3 L4 C1`) and save structured output to `test-harness/walkthrough-snapshots/<lesson>/`
2. **This skill reads those snapshots** and compares against curriculum README claims
3. **This skill updates the READMEs** to match reality when they've drifted

The skill never runs walkthroughs itself. If snapshots are missing or stale, tell the user to run the walkthroughs first.

## Hard Boundary: No Internal Test Leakage

Internal automation and captured output are validation inputs only. They are not
part of the curriculum narrative.

This skill and `test-harness/**` are private QA tooling, not workshop material.
They must contain the exact paths, commands, snapshot names, process names, and
failure modes needed to manage the harness correctly.

When editing student-facing workshop Markdown, including `README.md`,
`activities/**`, `curriculum/**`, `packs/**`, `my-factory/**`, and
`reference-project/**`, do not mention:

- `test-harness`
- walkthrough scripts or the walkthrough harness
- snapshot files or snapshot directories
- validation runs, test fixtures, run IDs, scratch paths, or harness-only feature choices

Translate validation evidence into normal workshop language. For example:

- Bad: "The walkthrough snapshots produce these artifact sections."
- Good: "A complete L4 run should produce artifacts with these sections."
- Bad: "The walkthrough uses this example."
- Good: "Use an example like this."

Before reporting validation complete, scan every student-facing Markdown file
you edited for those banned terms. If any appear, rewrite the prose before
finishing.

## Snapshot Location

```
test-harness/walkthrough-snapshots/
  L1/
    gc-status.txt          # output of gc status
    git-status.txt         # output of git status --short
    node-test.txt          # output of node --test
    city.toml              # actual city config
    pack.toml              # actual pack config
    PROJECT_MANIFEST.md    # actual manifest
    CLAUDE.md              # actual project instructions
  L2/
    gc-sling.txt              # output of gc sling command
    gc-status.txt             # output of gc status
    plans-<slug>.md           # ALL plan artifacts (first run + MCP re-sling)
    plans-<slug>-sections.txt # section headers for each plan
    architecture-<slug>.md    # ALL architecture artifacts
    architecture-<slug>-sections.txt
  L3/
    gc-sling.txt
    plans-<slug>.md           # ALL plans (first run + skill re-sling)
    plans-<slug>-sections.txt
    architecture-<slug>.md    # ALL architecture artifacts
    architecture-<slug>-sections.txt
    designs-<slug>.md         # ALL design artifacts
    designs-<slug>-sections.txt
    node-test.txt
    builder-commit.txt
  L4/
    gc-sling.txt
    plans-<slug>.md           # ALL plans (first run + manifest proof re-sling)
    plans-<slug>-sections.txt
    architecture-<slug>.md, designs-<slug>.md
    reviews-<slug>.md         # ALL reviews (first run + manifest proof)
    releases-<slug>.md        # ALL releases
    *-sections.txt            # section headers for each artifact
    node-test.txt
    builder-commit.txt
    PROJECT_MANIFEST.md       # the manifest with Review Standards
  C1/
    (same pattern as L4 plus:)
    validation-<slug>.md
    validation-<slug>-sections.txt
    retrospective.md

  Naming convention: `<type>-<slug>.md` + `<type>-<slug>-sections.txt`.
  Every artifact from every formula run is saved — first run AND re-slings.
  If a lesson runs the formula twice (MCP re-sling, manifest proof, skill
  re-sling), both runs' artifacts appear with different slugs.

  Agent session transcripts are saved under `sessions/`:
  ```
  L2/sessions/planner.txt    # planner's full conversation including tool calls
  L2/sessions/architect.txt  # architect's full conversation
  L3/sessions/builder.txt    # builder's conversation — check for skill usage
  ```
  Session transcripts prove causal impact: grep for MCP tool calls
  ("Called context7"), skill references, or manifest citations.
```

## Lesson map

| Lesson | README | Walkthrough |
|--------|--------|-------------|
| L1 | `curriculum/labs/L1/README.md` | `test-harness/walkthroughs/L1.sh` |
| L2 | `curriculum/labs/L2/README.md` | `test-harness/walkthroughs/L2.sh` |
| L3 | `curriculum/labs/L3/README.md` | `test-harness/walkthroughs/L3.sh` |
| L4 | `curriculum/labs/L4/README.md` | `test-harness/walkthroughs/L4.sh` |
| C1 | `curriculum/capstone/C1/README.md` | `test-harness/walkthroughs/C1.sh` |

## What to check and fix

### 1. Command matching (static — no snapshots needed)

Compare README `bash` code blocks against walkthrough commands:

- **Formula names**: `--on <formula>` must match across README, walkthrough, and `packs/lessons/<lesson>/formulas/*.toml`
- **Agent targets**: `<rig>/factory.<agent>` must exist under `packs/lessons/<lesson>/agents/`
- **Infrastructure commands**: `cp *.template`, `gc register`, `gc rig add`, `gc doctor`, `gc status`, `gc restart`, `gc --rig import add/remove` — README commands need walkthrough equivalents
- **Config-over-chat**: if README says edit a prompt and re-sling, walkthrough must too

### 2. Output matching (requires snapshots)

Read the snapshot files and compare against README claims:

**Artifact sections**: The README says "The plan should include: goal, user stories, acceptance criteria." Read `walkthrough-snapshots/<lesson>/plan-sections.txt` — does it list `## Goal`, `## User Stories`, `## Acceptance Criteria`? If the agent used different headers (e.g., "## Objective" instead of "## Goal"), **update the README** to match what the agent actually produces, or flag a prompt fix.

**gc status output**: The README says `gc status` shows the city and rig. Read `walkthrough-snapshots/<lesson>/gc-status.txt`. Does the listed agent set match what the README claims? Update if not.

**gc sling output**: Read `walkthrough-snapshots/<lesson>/gc-sling.txt`. Does the sling output format match what the README describes?

**Test output**: Read `walkthrough-snapshots/<lesson>/node-test.txt`. Does the README's expected test output match?

**Formula graph**: The README shows `plan -> architecture`. Read the formula TOML to verify the graph matches. Also check that the agent list in the README matches the agents in the snapshot's `gc-status.txt`.

**Manifest load-bearing proof** (L4 only): Read `walkthrough-snapshots/L4/review2-sections.txt` and `review2-artifact.md`. Does the second review cite Review Standards? If yes, the README's claim is validated. If not, flag it.

### 3. Causal impact validation (requires snapshots)

Every student exercise that modifies agent configuration must **materially affect** the agent's output. If a step says "add an MCP server" or "edit the prompt," the resulting artifact must contain evidence that the change mattered. Configuration changes that don't visibly affect output are not teaching exercises — they're busywork.

**MCP server integration**: If the walkthrough adds an MCP server (e.g., Context7) and edits a prompt to use it, the post-MCP artifact must contain content that could only come from querying that MCP. For Context7 specifically, look for references to specific API signatures, version-specific features, or documentation details that the agent wouldn't know from training data alone. Read the post-MCP artifact and grep for evidence. If none is found, the MCP exercise is broken — either the prompt isn't directive enough ("use Context7 to look up X") or the MCP server didn't contribute.

**Prompt edits**: If the walkthrough edits a prompt and re-slings, diff the pre-edit and post-edit artifacts. The post-edit artifact must be visibly different in a way that traces to the prompt change. If the artifacts are structurally identical, the prompt edit didn't matter.

**Manifest changes** (L4): If the walkthrough writes Review Standards to the manifest, the post-manifest review artifact must cite those standards by name. Grep for the standard text (e.g., "JSDoc", "hardcoded credentials") in the review artifact.

**How to check**: For each config-change exercise in the walkthrough, read both the pre-change and post-change artifacts from the snapshots. If the post-change artifact doesn't contain evidence of the change's impact, flag it:

```
✗ MCP exercise: Context7 MCP added to planner overlay, but plans-undo-redo.md
  contains no references to node:test API details from Context7 docs.
  The MCP config was wired but never used. Fix: make the prompt directive
  ("use Context7 to look up X") not passive ("when available, use Context7").
```

### 4. What to do when they don't match

**If the README is wrong** (agent produces different output than what the README claims):
- Update the README to match the snapshot. The walkthrough output is truth.
- Example: README says "## Goal" but snapshot shows "## Objective" → update README to say "## Objective"

**If the walkthrough is wrong** (walkthrough doesn't exercise a README command):
- Update the walkthrough to exercise the command
- Re-run the walkthrough to generate new snapshots

**If the prompt is wrong** (agent produces poor output that neither README nor walkthrough should accept):
- Flag it as a prompt issue, don't update the README to match bad output

**If a config change has no causal impact** (MCP added but not used, prompt edited but output unchanged):
- Make the prompt more directive so the agent actually uses the capability
- Re-run the walkthrough and verify the new artifact shows evidence of impact
- The exercise is not done until the config change visibly changes the output

### 5. Structural matching (static)

- Every README part with commands needs a walkthrough step
- Every exit criterion needs a walkthrough assertion
- Step counts should be consistent

## Output format

```
=== L2 Lesson Content Validation ===

Commands (static):
  ✓ gc sling ... --on mol-feature-intake — README:115, walkthrough:128
  ✓ gc events --follow — README:121, walkthrough:start_event_stream

Output (from snapshots):
  ✓ Plan sections match: Goal, User Stories, Acceptance Criteria
  ✗ README says "scope boundary" but plan-sections.txt shows "## Scope" — UPDATE README line 166
  ✓ Architecture sections match: Context, Options Considered, Decision

Updates applied:
  ✓ curriculum/labs/L2/README.md line 166: "scope boundary" → "scope"

Findings: 0 error(s), 1 update(s)
```

## Prerequisites

If snapshots don't exist at `test-harness/walkthrough-snapshots/<lesson>/`, tell the user:

```
Snapshots missing for <lesson>. Run the walkthrough first:

  bash test-harness/tutorial-walkthrough.sh <lesson>

Then invoke this skill again.

```

The walkthroughs automatically save snapshots after each successful run.
