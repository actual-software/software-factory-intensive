# L4 · Deploy Reviewer + Deployer Agents

> **What you'll build:** The final two agents of the 6-agent pipeline — a **Reviewer** that reads the coder's diff and verifies both code quality *and* acceptance-criteria coverage, and a **Deployer** that quality-gates the release, writes a rollback plan, and ships. By the end of this lab a bead walks from `needs-review` → `ready-to-ship` → closed on your own project, driven entirely by label flips.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Customised `reviewer` + `deployer` packs scoped to your project, plus one bead that walked the full review→ship handoff end-to-end |

---

## Session workspace note

* **Pack locations (shipped):** `packs/reviewer/` and `packs/deployer/` under the `software-factory/` tree. Prompt templates are `packs/<agent>/prompts/<agent>.md.tmpl` (the `.tmpl` suffix is the Gas City template extension).
* **Gas City workspace:** `my-factory/` — this is where `city.toml` lives. Every `gc` command below is run from that folder unless otherwise noted.
* **Your deliverables this session:** `notes.md` plus customised pack copies. If your workshop uses an activity folder (`activities/labs/L4/`), put them there; otherwise keep your customised pack copies anywhere tracked by git.
* **Wiring the packs:** at the end of the session, `my-factory/city.toml`'s `includes` should reach the `reviewer` and `deployer` packs — either the shipped copies or your customised copies.

If a pack edit breaks your factory, swap back to the shipped pack path in `city.toml` and `gc service restart` — the shipped packs always pass `gc doctor`.

**Canonical reference:** this is the first lab where label-driven handoffs show up in earnest. Keep [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) open in another tab — it's the authoritative doc for the six labels, who adds each one, and who consumes it. Everything below assumes you've skimmed it.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. L4 is the strictest session for config discipline: **review findings are fixed by editing the coder or reviewer prompt, never by hand-editing the code under review.** An agent reading this README should open `docs/PROJECT_MANIFEST.md` first — especially the Review Standards and Release Criteria sections — since the reviewer and deployer read those as their rubric.

---

## Architecture Diagram

```
                                  (coder, L3)
                                       │
                                       ▼  needs-review
                  ┌──────────────────────────────────────┐
                  │           REVIEWER AGENT              │
                  │                                        │
                  │  Order gate: bd ready --label=needs-   │
                  │              review --limit=1          │
                  │                                        │
                  │  Reads:                                 │
                  │    • the bead (title, notes, ACs)       │
                  │    • the coder's diff (git log --grep)  │
                  │    • docs/rules/*.md                    │
                  │    • the existing test suite            │
                  │                                        │
                  │  Runs mol-code-review: intake → style   │
                  │  → security (OWASP Top 10) → spec/AC    │
                  │  → verdict                              │
                  │                                        │
                  │  Writes findings into bead notes        │
                  └────────────────────┬───────────────────┘
                          pass │       │ request-changes
                               ▼       ▼
                  ready-to-ship       ready-to-build
                               │       │
                               │       └──► back to coder
                               ▼
                  ┌──────────────────────────────────────┐
                  │           DEPLOYER AGENT              │
                  │                                        │
                  │  Order gate: bd ready --label=ready-   │
                  │              to-ship --limit=1         │
                  │                                        │
                  │  Runs mol-deployer: intake → checks →   │
                  │  smoke → version → tag → rollback plan  │
                  │                                        │
                  │  Writes verdict + rollback plan into    │
                  │  bead notes; tags commit; closes root   │
                  │  bead; emits a needs-improve bead for   │
                  │  the optional Improver                  │
                  └──────────────────────────────────────┘
                                       │
                                       ▼  needs-improve (optional 7th agent, W4)
```

Nothing in this diagram is a durable markdown document. Every handoff is a **label flip on the same bead**, and every finding / verdict / rollback plan is a **note on that bead**. That is the new paradigm the factory runs on — see [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for why.

---

## Prerequisites

Before starting this lab, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| Gas City running | `gc status` shows your city and at least the `dev-agent` is up | Re-run `gc service start` from `my-factory/` |
| Upstream packs wired | `gc rig list` for your project rig shows `planner`, `architect`, `designer`, `coder` | If you skipped L2/L3, wire the shipped packs from `packs/<name>` — L4 doesn't require *your* customisations, only that the four upstream packs are included |
| A feature branch with coder output | `git -C ~/path/to/your-repo log --oneline` shows a commit referencing a bead you still have open (or a synthetic one you create for this lab) | See *"No coder output handy?"* below |
| `docs/rules/` exists in your repo | `ls ~/path/to/your-repo/docs/rules/` returns at least one `.md` file | Create one: `echo "# Project review rules" > docs/rules/review.md` — the reviewer will read whatever you put there |
| Bead with acceptance criteria | `bd show <bead-id>` shows ACs in either the description or notes | Add them: `bd update <id> --notes "acceptance_criteria:\n- <criterion 1>\n- <criterion 2>"` |

If any row fails, stop and fix it. L4 is the thinnest lab in terms of new Gas City primitives (you already know `gc rig add --include`, order gates, and `bd label`), but it is the most demanding in terms of upstream artifact quality. Vague acceptance criteria produce a vague reviewer verdict; a missing `docs/rules/` gives the reviewer nothing to check against.

### No coder output handy?

If L3's coder artifacts aren't present (you skipped L3, or you dropped the branch), create a small synthetic change to exercise the pipeline:

```bash
cd ~/path/to/your-repo
git switch -c l4-demo
echo "export const greet = (name: string) => \`hello, \${name}\`;" > src/greet.ts
git add src/greet.ts && git commit -m "feat(greet): add greet() helper (refs <bead-id>)"
```

Then create the bead (`bd create --title "Demo: greet()" --label needs-review --notes "acceptance_criteria:\n- greet(name) returns 'hello, <name>'\n- exported from src/greet.ts"`). That is enough for the reviewer to have something to chew on.

---

## Part 0: Read the Shipped Packs (~5 min)

Before installing anything, read what you're about to install. Both packs ship with a prompt template, a formula, an order gate, a doctor check, and one or two commands.

### Step 1: Open the reviewer pack

Three files in order:

1. [`packs/reviewer/pack.toml`](../../../packs/reviewer/pack.toml) — metadata. Note `wake_mode = "fresh"` (every wake re-derives state from the bead; there are no cached status files) and the nudge that tells the agent to `bd ready --label=needs-review`.
2. [`packs/reviewer/prompts/reviewer.md.tmpl`](../../../packs/reviewer/prompts/reviewer.md.tmpl) — the system prompt. Skim the *Primary focus* block: **code review AND acceptance-criteria coverage in one agent**. The former `validator` pack folded into this one in the 6+1 model — there is no separate validator.
3. [`packs/reviewer/formulas/mol-code-review.formula.toml`](../../../packs/reviewer/formulas/mol-code-review.formula.toml) — the 5-step work loop: intake → style → security → spec (AC coverage) → verdict. Every step writes findings into bead notes via `bd update --notes`.

And the order gate that decides *when* the reviewer wakes:

[`packs/reviewer/formulas/orders/reviewer-intake/order.toml`](../../../packs/reviewer/formulas/orders/reviewer-intake/order.toml)

```toml
[order]
description = "Wake the reviewer when any bead is labelled needs-review"
formula = "mol-code-review"
gate = "condition"
check = "bd ready --label=needs-review --limit=1 | grep -q ."
pool = "reviewer"
```

**What's happening here:** The reviewer doesn't need explicit `gc sling` commands. The order gate polls `bd ready --label=needs-review`; as soon as a bead shows up with that label, the reviewer's mol-code-review formula runs. That's the handoff contract — the label *is* the trigger.

### Step 2: Open the deployer pack

Same five files, different work:

1. [`packs/deployer/pack.toml`](../../../packs/deployer/pack.toml) — metadata. The nudge points at `bd ready --label=ready-to-ship`.
2. [`packs/deployer/prompts/deployer.md.tmpl`](../../../packs/deployer/prompts/deployer.md.tmpl) — persona is **Release Engineer + DevOps Engineer**. Note the hard constraint: *every release must have a rollback plan recorded before shipping.*
3. [`packs/deployer/formulas/mol-deployer.formula.toml`](../../../packs/deployer/formulas/mol-deployer.formula.toml) — the 6-step work loop: intake → checks (CI, blockers) → smoke → version (semver bump) → tag (commit, tag, release notes) → rollback-plan (rollback command + create `needs-improve` bead + close root bead).
4. [`packs/deployer/formulas/orders/deployer-intake/order.toml`](../../../packs/deployer/formulas/orders/deployer-intake/order.toml) — order gate polling `bd ready --label=ready-to-ship`.

Notice the three formula vars at the top of `mol-deployer.formula.toml`:

```toml
[vars]
[vars.version_file]      # Path to the rig's version file (e.g. VERSION, package.json)
[vars.smoke_cmd]         # Command that runs smoke tests — empty means skip
[vars.deploy_cmd]        # Command that triggers the actual deploy — empty means tag-only
```

These three vars are the **main customisation surface** for the deployer — they make the same shipped formula work for a Go service with `VERSION` + `make smoke`, a Node service with `package.json` + `npm run smoke`, or a tag-only repo with both commands empty.

You're done reading. Now install.

---

## Part 1: Include the Packs and Wire `city.toml` (~10 min)

### Step 1: Decide shipped vs. customised

You have two choices for each pack:

**(a) Shipped as-is.** Include the pack directly from `packs/reviewer/` and `packs/deployer/`. Fastest path — good for a first green run.

**(b) Copy and customise.** Copy the pack into your activities folder (or anywhere under git), edit the prompt or formula vars, and include your copy. This is what Parts 2 and 3 below actually teach — the lab's main deliverable is a *customised* copy.

Most participants do (a) first to confirm the pipeline runs, then switch to (b). The swap is one line in `city.toml`.

### Step 2: Copy the packs into your workspace

```bash
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/reviewer packs/reviewer
cp -rf ../software-factory/packs/deployer packs/deployer
```

(Exact source path depends on your checkout — adjust to point at `packs/reviewer/` and `packs/deployer/` in the software-factory tree.)

### Step 3: Add the includes

Open `my-factory/city.toml` and add two entries to `includes`:

```toml
includes = [
    "../packs/planner",      # from L2 (shipped or your copy)
    "../packs/architect",    # from L2
    "../packs/designer",     # from L3
    "../packs/coder",        # from L3
    "packs/reviewer",        # NEW — your copy under my-factory/packs/
    "packs/deployer",        # NEW
]
```

If you're running shipped only (Step 1a), skip the copy and point the includes at the shipped paths (e.g. `"../software-factory/packs/reviewer"`).

### Step 4: Restart and verify

```bash
gc service restart
gc doctor
gc status
```

`gc doctor` should be green for all six agents. `gc status` should list `reviewer` and `deployer` alongside the upstream four. If either is missing, `gc doctor`'s output names the failing check — usually a missing binary (`bd`, `gc`, `git`, `jq`; `gh` is optional but recommended).

### Step 5: Commit the wiring

```bash
cd my-factory
git add city.toml packs/reviewer packs/deployer
git commit -m "chore(L4): wire reviewer + deployer packs into my-factory"
```

---

## Part 2: Customise the Reviewer (~15 min)

> **Agent Guide:** Before the participant edits anything, ask them: "Which review findings matter most for your project that a linter can't catch?" Then: "What acceptance-criteria coverage gap would you want the reviewer to flag?" Naming these out loud before editing keeps the customisation grounded in real project risk instead of generic 'code quality' language.

The reviewer's behaviour comes from three places:
- `packs/reviewer/prompts/reviewer.md.tmpl` — the persona, the primary focus, the work loop's narrative structure
- `packs/reviewer/formulas/mol-code-review.formula.toml` — the step-by-step procedure and verdict logic
- `docs/rules/*.md` in your own project rig — the project-specific rubric

You'll make one edit to each.

### Step 1: Tighten the reviewer prompt for your project

Open `my-factory/packs/reviewer/prompts/reviewer.md.tmpl` in your editor. The current *Primary focus* block:

```markdown
> Automated review — style, security, spec compliance, and
> acceptance-criteria coverage. Prevent non-compliant code from
> advancing to deployment.
```

Append one project-specific sentence that narrows what the reviewer looks hardest at. Example for a TypeScript web app:

```diff
 > Automated review — style, security, spec compliance, and
 > acceptance-criteria coverage. Prevent non-compliant code from
-> advancing to deployment.
+> advancing to deployment. For this project, the highest-risk class of
+> defect is auth-scoped data exposure — every new query that reads a
+> `userId`-keyed table must be inside a scoped handler. Flag any
+> unscoped read as blocker.
```

Substitute your own high-risk class. Aim for one sentence that tells the reviewer what to weight hardest.

### Step 2: Add a project-specific rule file

The reviewer's intake step reads `docs/rules/*.md` in your project rig. That's where your project-specific rubric lives — the reviewer reads it every run, so changes propagate without editing the pack.

```bash
cd ~/path/to/your-repo
mkdir -p docs/rules
cat > docs/rules/review.md <<'EOF'
# Review Rules

## Security
- Every API endpoint that takes a userId in path, query, or body MUST
  verify the authenticated user matches. Unscoped reads are blockers.
- All SQL uses parameterized placeholders. String-concatenated SQL is
  a blocker finding.

## AC coverage
- Every acceptance criterion on the bead must be exercised by at least
  one test. Missing coverage is a request-changes, not a pass.

## Style
- Prefer named constants in `src/<feature>/constants.ts` over magic
  numbers.
- Exported functions in `src/` have explicit return types.
EOF
git add docs/rules/review.md
git commit -m "docs(rules): seed review rules for the reviewer agent"
```

Substitute rules appropriate to your stack. Keep them specific and actionable — "code should be clean" is useless; "no `any` in exported types" is enforceable.

### Step 3: Tweak the verdict logic (optional)

Open `my-factory/packs/reviewer/formulas/mol-code-review.formula.toml` and find the `verdict` step's decision rule:

```
- Any blocker in security_findings → **request-changes**.
- Any `tests_green: false` → **request-changes**.
- Any `uncovered_criteria` other than "none" → **request-changes**.
- Otherwise → **pass**.
```

If your project has its own definition of "blocker" (e.g. any `major` security finding, not just `blocker`), edit the rule here. Most projects don't need this — the default is intentionally strict.

### Step 4: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor            # should still be green
git add packs/reviewer
git commit -m "chore(reviewer): tighten focus + add scoped-read rule"
```

---

## Part 3: Customise the Deployer (~10 min)

> **Agent Guide:** Before the participant edits anything, ask them to state — out loud, in one sentence each — (a) where the project's version lives, (b) whether there's a smoke-test command, and (c) whether `git tag` is the deploy trigger or there's a separate deploy command. If they can't answer any of the three, the deployer's formula vars will be guesses. Pause and figure them out.

The deployer's behaviour comes from two places:
- `packs/deployer/prompts/deployer.md.tmpl` — the persona and constraints
- `packs/deployer/formulas/mol-deployer.formula.toml` — in particular the three formula vars (`version_file`, `smoke_cmd`, `deploy_cmd`) that make the shipped formula fit your project

### Step 1: Set the formula vars

Open `my-factory/packs/deployer/formulas/mol-deployer.formula.toml`. Find the `[vars]` block and update the defaults to match your project:

```diff
 [vars]
 [vars.version_file]
 description = "Path to the rig's version file"
-default = "VERSION"
+default = "package.json"      # or Cargo.toml, pyproject.toml, VERSION, etc.

 [vars.smoke_cmd]
 description = "Command that runs smoke tests against the built artifact. Empty = skip."
-default = ""
+default = "npm run smoke"     # empty if you don't have a smoke target

 [vars.deploy_cmd]
 description = "Command that triggers the actual deploy. Empty = tag-only."
-default = ""
+default = ""                  # leave empty for tag-only releases
```

Don't set a `deploy_cmd` unless you have a real one wired up — the workshop factory is tag-only for most participants, and that is fine. A tag-only release still produces a rollback plan and closes the bead.

### Step 2: Add a project-specific release constraint

Open the deployer prompt and tighten the *Constraints* block. Example:

```diff
 > No manual steps in the release pipeline. Every release is
 > rollback-capable. Reproducibility over convenience. Every change
-> must be version-controlled.
+> must be version-controlled. For this project, any release that
+> touches a database migration MUST list the data-migration backout
+> command in the rollback plan, not just the git revert.
```

Project-specific constraints go here; generic ones are already in the shipped prompt.

### Step 3: Restart and commit

```bash
cd my-factory
gc service restart
gc doctor
git add packs/deployer
git commit -m "chore(deployer): set version_file=package.json, require migration backout in rollback plan"
```

---

## Part 4: Walk a Bead Through the Handoff (~20 min)

> **Agent Guide:** Once the participant creates the `needs-review` bead, resist the urge to `gc sling` it manually. The point of this lab is to see that **labels alone drive the handoff.** If the reviewer doesn't wake within ~60s, the problem is the order gate or `gc doctor`, not a missing sling.

You'll file one bead, watch it walk from `needs-review` → `ready-to-ship` → closed, and inspect every note it accumulates along the way.

### Step 1: Create the `needs-review` bead

Either label an existing bead (your L3 coder bead, if you have one) or create a fresh one. Using the synthetic example from Prerequisites:

```bash
cd my-factory
bd create \
  --title "Review: greet() helper" \
  --label needs-review \
  --notes "acceptance_criteria:
- greet(name) returns 'hello, <name>'
- exported from src/greet.ts
- has a unit test in tests/greet.test.ts"
```

If you're relabeling an existing bead from L3:

```bash
bd update <your-coder-bead-id> --add-label needs-review
```

Either way, the reviewer's order gate (`bd ready --label=needs-review --limit=1 | grep -q .`) will match within the gate's poll interval, and mol-code-review will start.

### Step 2: Watch the reviewer work

```bash
gc status                           # reviewer should flip to working
gc session peek <rig>/reviewer      # snapshot of the tmux session
gc events --follow                  # stream events from another terminal
bd show <bead-id>                   # notes accumulate as each step completes
```

The reviewer walks its five steps. Each step writes findings into the bead's notes:

```
style_findings:
  - low src/greet.ts:3 missing explicit return type on exported function
security_findings:
  - (none — no I/O in this change)
spec_findings:
  - tests_green: true
  - uncovered_criteria: none
verdict: pass
```

When the verdict is computed, the reviewer relabels:
- **pass** → `remove needs-review`, `add ready-to-ship`
- **request-changes** → `remove needs-review`, `add ready-to-build` (back to the coder)

Wait until the reviewer returns to idle and the bead's labels have flipped. Inspect:

```bash
bd label list <bead-id>
bd show <bead-id> | grep -E 'verdict|review_round'
```

If the verdict is `request-changes`, jump to **Part 5: Fix via Config** — that is the main pedagogical moment of this lab.

### Step 3: Watch the deployer work

The deployer's order gate is now matching (because the bead just got `ready-to-ship`). Within a poll interval, `gc status` shows the deployer working. Its six steps each extend the bead's notes:

```
gate_checks: pass
smoke: pass                # or "(skipped)" if smoke_cmd was empty
version_before: 0.1.3
version_after: 0.1.4
rollback_plan: |
  Previous tag: v0.1.3
  Command: git revert --no-edit v0.1.4
  Data migrations to reverse: none
  Feature flags to flip: none
```

On success, the deployer:
1. Creates a version commit and a git tag (e.g. `v0.1.4`).
2. Writes `docs/releases/v0.1.4.md` (release notes).
3. Creates a `needs-improve` child bead so the optional Improver (introduced in W4) can watch the release.
4. Closes the root bead.

Verify:

```bash
bd show <bead-id>                   # status should be CLOSED
bd label list <bead-id>             # ready-to-ship removed; no labels remaining
git -C ~/path/to/your-repo tag -l | tail -3
bd list --label needs-improve       # should show the new improver bead
```

You have just watched the pipeline run on nothing but label flips. No `gc sling` was run manually in this part. That is the paradigm.

### Step 4: Capture the run in `notes.md`

For your activity deliverable, drop a short `notes.md` noting:
- The bead id you walked through
- Time from `needs-review` to `closed` (run `bd show` at each stage and note timestamps)
- Any findings the reviewer caught and what you did about them

---

## Part 5: Fix via Config (~15 min)

> **Agent Guide:** This is the strictest part of the curriculum. The instant the participant opens a source file to hand-fix a reviewer finding, stop them, roll the edit back, and redirect them to `packs/coder/prompts/coder.md.tmpl`. No exceptions. If they argue "just this once," that's exactly the habit the workshop is trying to break.

When the reviewer returns `request-changes`, the instinct is to open `src/` and fix it. **Don't.** The whole point of the factory is that improvements persist as agent config, not one-off manual edits. Hand-fix today, the next feature has the same bug tomorrow.

The discipline is:

1. Read each finding. Decide: is it a coder gap, a designer gap, or a reviewer gap?
2. Edit the relevant pack's prompt or formula to make that behaviour the default from now on.
3. Relabel the bead back (`bd label add <id> ready-to-build`) and let the coder pick it up again — or, for the demo case, manually re-trigger the coder via the order gate.
4. After the coder re-submits, relabel to `needs-review` and let the reviewer re-verify.

Three realistic scenarios follow.

### Scenario A — Security finding: unscoped read

The reviewer flagged `blocker src/api/loyalty.ts:34 redeem endpoint reads points_ledger without auth scope`.

**Wrong fix:** open `src/api/loyalty.ts`, add an `if (req.user.id !== req.body.userId) return 403`, commit, re-submit.

**Right fix:** edit `my-factory/packs/coder/prompts/coder.md.tmpl` so the coder never writes an unscoped read in the first place. Append to its rules:

```markdown
- Every API handler that accepts a userId parameter (in path, query, or
  body) MUST verify req.user.id === userId. If the spec does not specify
  auth behaviour, assume the authenticated user is the only valid
  actor and return 403 otherwise.
```

Commit the prompt change, re-trigger the coder against the same bead, and the next submission will have the check. Future features inherit the rule automatically.

### Scenario B — AC coverage gap

The reviewer flagged `uncovered_criteria: - refund reverses earned points`.

**Wrong fix:** write a test yourself and commit it.

**Right fix:** this is a coder gap (the coder owns test authorship). Add to `my-factory/packs/coder/prompts/coder.md.tmpl`:

```markdown
- Before marking a bead ready for review, enumerate every acceptance
  criterion in the bead notes. For each, write at least one test that
  references the criterion by wording or name. If you can't write a
  test for a criterion, relabel the bead `needs-design` with a note
  explaining why — don't pass the bead to review with gaps.
```

Re-trigger the coder. The new rule forces the test to exist before the bead ever reaches the reviewer again.

### Scenario C — Reviewer too lenient

The reviewer said `pass`, but you can eyeball the diff and see a string-concatenated SQL query that should have been flagged.

**Wrong fix:** lower the reviewer's bar to match what it caught.

**Right fix:** tighten `my-factory/packs/reviewer/formulas/mol-code-review.formula.toml` step 3 (Security) to explicitly require the check:

```diff
 **1. Injection.** Any concatenated SQL / shell / HTML / JSON /
-   template strings? Use parameterized queries / proper escapers.
+   template strings? Use parameterized queries / proper escapers.
+   BLOCKER finding for any SQL built via string concatenation — even
+   if the inputs are internal. No exceptions.
```

Re-trigger the reviewer. Now the finding surfaces.

### The Rule

At least **one** reviewer finding in your run must be resolved via a prompt or formula edit — not a hand-edit in `src/`. That is the deliverable of this lab. Run `git log packs/coder/prompts/ packs/reviewer/` at the end of the session; you should see at least one commit whose message names the finding the edit addresses.

---

## Inline Insight: Why Labels Beat Durable Markdowns

Earlier factory iterations passed context between agents via long-lived markdown docs (`review-reports/<slug>-review.md`, `release-gates/<slug>-gate.md`). That worked for a linear single-threaded flow but collapsed as the factory grew: two beads in different stages couldn't be distinguished without parsing the doc's internal state; two agents writing the same file collided; agents didn't know when they were "up" without scanning docs for cues.

Labels fix all of that. A bead is one unit of work; its labels are its state; `bd ready --label <name>` is a natural queue per agent. The coordination surface shrinks from "every agent knows every doc path and every section contract" to "every agent knows its one inbound label and its one outbound label." Findings still exist — they just live in the bead's notes rather than a separate file — and the *label* carries the routing signal.

See [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for the canonical six-label contract.

## Inline Insight: Why the Reviewer Owns AC Coverage

In the 6+1 factory there is no separate `validator` agent. Acceptance-criteria verification got folded into the reviewer because separating them produced a worse factory in practice: a standalone validator either duplicated the reviewer's intake step (reading the diff, running the suite) or it ran first and sat idle while the reviewer re-read the same files. Merging the two meant one pass over the code, four personas' worth of lens (engineering manager + principal engineer + security engineer + QA engineer), and one verdict.

The tradeoff: a single agent that does too much drifts toward being lenient on any one axis. The countermeasure is the reviewer's quality gate — the verdict rule in `mol-code-review.formula.toml` is the same four rules regardless of whether the failure came from a style issue or a missing AC test. Pass means *all four*; any one fails means request-changes. Stricter-by-construction beats having a separate agent you'd have to coordinate with.

## Inline Insight: Why the Deployer Writes a Rollback Plan Before Shipping

Mol-deployer's step 6 (`rollback-plan`) runs *before* the deploy trigger, not after. That ordering is deliberate: if you wait until after a deploy to write the rollback plan, you are writing it under pressure from whatever incident is unfolding, and you are writing it without the benefit of having just seen which tag/command/flag changed. By the time you need the rollback, you've lost the context.

Writing the plan at tag-time — while everything is still fresh — forces the deployer to articulate the rollback in terms of artifacts that already exist (the previous tag, the migration files, the feature-flag names) instead of narrating what you'd *do* in a hypothetical incident. This is also why `needs-improve` is a separate bead created at this step: the production watch is somebody else's job (the optional Improver), and the deployer's responsibility ends once the rollback plan is recorded.

---

## Common Issues & Solutions

### Issue 1: Reviewer never wakes after you label a bead `needs-review`

**Cause:** The order gate either can't find `bd`, or the label syntax on the bead doesn't match. `bd ready --label=needs-review --limit=1` on the command line returns nothing.

**Fix:** Run `bd ready --label=needs-review --limit=1` manually. If it returns a result but the agent still doesn't wake, `gc doctor` will show the `check-reviewer` script failing — usually a missing binary. If the command returns nothing, double-check `bd label list <bead-id>` — a trailing space or the label being case-mismatched prevents matching.

### Issue 2: Reviewer verdict is `pass` but the diff is obviously broken

**Cause:** Either the reviewer's `docs/rules/*.md` didn't get read (empty directory in the rig), or the finding you'd expect isn't covered by the formula's security step.

**Fix:** `ls docs/rules/` in the rig — should list at least one `.md`. Then grep the finding keyword in `mol-code-review.formula.toml` — if it's not mentioned, add it to the security step (Scenario C above).

### Issue 3: Reviewer keeps flipping the bead back to `ready-to-build`

**Cause:** The coder is regenerating the same bug because the coder prompt wasn't updated — you fixed the symptom, not the rule.

**Fix:** Every reviewer `request-changes` should result in at least one commit to `packs/coder/prompts/coder.md.tmpl` (or the formula). Check `git log my-factory/packs/coder/`; if it shows no recent commits matching your findings, you're hand-editing code that the coder will overwrite next round.

### Issue 4: Deployer fails at the `checks` step with `blocked by: <other-bead>`

**Cause:** Some other bead is labelled `blocker` and depends on the one you're shipping.

**Fix:** `bd dep blockers <bead-id>` shows the list. Either close the blockers first, or remove the `blocker` label if it was a false positive. The deployer is intentionally strict here — shipping past an open blocker is a category of production incident.

### Issue 5: Deployer sets `version_after` = `version_before`

**Cause:** The version bump logic in the `version` step didn't see a `feat`, `fix`, or `breaking` signal. Usually the coder's commit didn't follow conventional-commits format.

**Fix:** Two options. (a) Tighten the coder prompt to require conventional-commits format (`chore:` vs `feat:` vs `fix:`) — this is a pure config fix. (b) Hard-default the version bump in `mol-deployer.formula.toml` step 4 to `patch` when the commit type is unrecognised, rather than no-bump. Either fix is a config edit; don't re-tag by hand.

### Issue 6: Rollback plan says "Data migrations to reverse: unknown"

**Cause:** The deployer couldn't confidently enumerate migration state. This is a safety-first default — it would rather say "unknown" than commit to a plan it can't verify.

**Fix:** Add a project-specific hint to the deployer prompt: "Migrations live in `db/migrations/*.sql`. Compare HEAD vs the previous tag to list any new migrations." Then the deployer has a place to look.

### Issue 7: `needs-improve` bead was created but no improver is wired

**Cause:** You didn't install the improver pack — that's fine. It is the **optional 7th** agent (see [`packs/README.md`](../../../packs/README.md)), introduced in W4, and the factory runs end-to-end without it.

**Fix:** No fix needed in L4. The `needs-improve` bead will sit idle until a future session adds the improver. If it clutters `bd ready`, filter your queries (`--label-not needs-improve`).

### Issue 8: You hand-edited code and the reviewer re-approved

**Cause:** You broke the lab's core discipline. The code edit works for this bead; the next bead will re-introduce the bug.

**Fix:** Revert the hand-edit (`git checkout -- <file>`) and go back to Scenarios A/B/C above. The only *durable* fix is a prompt or formula edit.

---

## Quality Bar

When you review your own output, check:

- **Labels drove everything.** Search `gc events --follow` output for this bead — you should see `label_added` / `label_removed` events at every handoff. No `gc sling reviewer <bead>` in the history.
- **Verdict evidence lives in bead notes.** `bd show <bead-id>` should render a block with `style_findings`, `security_findings`, `spec_findings`, `verdict`, and (after shipping) `gate_checks`, `version_before`/`after`, and `rollback_plan`. If any is missing, the formula step that was supposed to write it didn't run — inspect `gc events`.
- **AC coverage was checked.** `spec_findings.uncovered_criteria` is present on a pass verdict, set to `none`.
- **Config-discipline evidence.** At least one commit in `git log my-factory/packs/` names a reviewer finding the edit addresses. Zero commits in `git log ~/path/to/your-repo/src/` attributable to "fixing a reviewer finding."
- **Rollback plan is concrete.** The plan names the previous tag by number, the git command verbatim, and explicitly lists migrations and flags (even if "none"). A plan that says "roll back somehow" is not a plan.

---

## Concept Check (before moving to W4)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain each bullet in their own words, without re-reading. If they can't, revisit the matching section.

- **Why labels are the handoff contract instead of a durable markdown doc.** (State machine, one inbound label per agent, natural queue via `bd ready --label`.)
- **Why the reviewer owns AC coverage in the 6+1 model.** (One pass over the code, all four personas, stricter verdict rule. No separate validator.)
- **Why the deployer writes a rollback plan before the deploy trigger.** (Articulating the plan while context is fresh, not during an incident.)
- **Why fixing a reviewer finding by editing `src/` is a false economy.** (The current bead is fixed; the next bead re-introduces the same bug. Prompt edits persist across bead lifetimes.)
- **What the `needs-improve` bead is for.** (Handoff to the optional Improver in W4; the deployer's responsibility ends at tag + rollback plan.)

---

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `gc doctor` is green for `reviewer` and `deployer` alongside the four upstream packs
- [ ] `my-factory/city.toml` includes the reviewer and deployer packs (shipped or your customised copies)
- [ ] At least one bead walked from `needs-review` → `ready-to-ship` → closed on nothing but label flips — no manual `gc sling` commands
- [ ] The closed bead's notes contain `style_findings`, `security_findings`, `spec_findings`, `verdict`, `gate_checks`, `version_before`/`after`, and `rollback_plan`
- [ ] A git tag was created on your rig (e.g. `vX.Y.Z`) and `docs/releases/vX.Y.Z.md` exists
- [ ] A `needs-improve` bead exists (whether or not an improver is wired)
- [ ] At least one commit in `git log my-factory/packs/` resolves a reviewer finding via a prompt / formula edit (zero hand-edits to your rig's `src/` files attributable to findings)
- [ ] Both customised packs are committed to git

**L4 completes the 6-agent pipeline.** The factory can now take a feature bead from intake (`needs-plan`) all the way to a tagged release with a rollback plan — without a human touching the code. W4 and L5/C1 add the optional improver and exercise the whole pipeline end-to-end.

---

## Command Cheat Sheet

Every command you ran during this lab, in order:

```bash
# PART 0 — read the packs (no commands — just read the files)

# PART 1 — include + wire
cd my-factory
mkdir -p packs
cp -rf ../software-factory/packs/reviewer packs/reviewer
cp -rf ../software-factory/packs/deployer packs/deployer
$EDITOR city.toml                              # add "packs/reviewer" + "packs/deployer" to includes
gc service restart
gc doctor
gc status
git add city.toml packs/reviewer packs/deployer
git commit -m "chore(L4): wire reviewer + deployer packs"

# PART 2 — customise reviewer
$EDITOR packs/reviewer/prompts/reviewer.md.tmpl   # tighten Primary focus for your project
cd ~/path/to/your-repo
mkdir -p docs/rules
$EDITOR docs/rules/review.md                      # seed project-specific review rules
git add docs/rules/review.md && git commit -m "docs(rules): seed review rules"
cd -                                              # back to my-factory
gc service restart && gc doctor
git add packs/reviewer && git commit -m "chore(reviewer): tighten focus"

# PART 3 — customise deployer
$EDITOR packs/deployer/formulas/mol-deployer.formula.toml   # set version_file, smoke_cmd, deploy_cmd
$EDITOR packs/deployer/prompts/deployer.md.tmpl              # add project-specific constraint
gc service restart && gc doctor
git add packs/deployer && git commit -m "chore(deployer): set vars + release constraint"

# PART 4 — walk a bead through the handoff
bd create --title "Review: <feature>" --label needs-review \
  --notes "acceptance_criteria:
- <criterion 1>
- <criterion 2>"
gc status                                # watch reviewer wake + run
bd show <bead-id>                        # findings accumulate in notes
bd label list <bead-id>                  # flipped to ready-to-ship on pass
gc status                                # watch deployer wake + run
bd show <bead-id>                        # status closed; verdict + rollback_plan in notes
git -C ~/path/to/your-repo tag -l        # new tag exists
bd list --label needs-improve            # improver bead created

# PART 5 — fix via config (when reviewer returns request-changes)
$EDITOR my-factory/packs/coder/prompts/coder.md.tmpl        # add the durable rule
git -C my-factory add packs/coder/prompts/coder.md.tmpl
git -C my-factory commit -m "chore(coder): require <the rule>"
bd label add <bead-id> ready-to-build    # re-arm the coder
# (coder re-runs, re-submits, bead flips back to needs-review; reviewer re-verifies)
```

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Reviewer pack | `packs/reviewer/` | Defines the Reviewer agent: prompt template, formula, order gate, doctor check, commands |
| Reviewer prompt | `packs/reviewer/prompts/reviewer.md.tmpl` | Persona, primary focus, work loop narrative. Absorbed the former validator's AC-coverage responsibility. |
| Reviewer formula | `packs/reviewer/formulas/mol-code-review.formula.toml` | 5-step work loop: intake → style → security → spec/AC → verdict |
| Reviewer order gate | `packs/reviewer/formulas/orders/reviewer-intake/order.toml` | Polls `bd ready --label=needs-review`; wakes the reviewer on match |
| Deployer pack | `packs/deployer/` | Defines the Deployer agent |
| Deployer prompt | `packs/deployer/prompts/deployer.md.tmpl` | Release Engineer + DevOps Engineer persona; rollback-required constraint |
| Deployer formula | `packs/deployer/formulas/mol-deployer.formula.toml` | 6-step work loop: intake → checks → smoke → version → tag → rollback-plan |
| Deployer order gate | `packs/deployer/formulas/orders/deployer-intake/order.toml` | Polls `bd ready --label=ready-to-ship`; wakes the deployer on match |
| Project review rules | `docs/rules/*.md` in your rig | Project-specific rubric the reviewer reads every run |
| Bead notes | `bd show <bead-id>` | Where findings, verdict, gate_checks, and rollback_plan live — no durable markdown docs |
| Release tag + notes | `git tag` + `docs/releases/vX.Y.Z.md` | Deployer-produced release artifacts |
| `needs-improve` bead | `bd list --label needs-improve` | Handoff to the optional Improver (W4) |

---

## Next Steps

After L4, your factory can take a feature bead from `needs-plan` through to a tagged release on labels alone. Two sessions remain:

- **W4** — introduces the optional 7th agent, the **Improver**, which consumes `needs-improve` beads produced by the deployer and feeds production signal back into agent prompts. The factory runs without it; the improver is what turns the factory into a *learning* factory.
- **L5** — the Capstone. Combine everything you've built and run a real feature end-to-end.

The pattern you practised in L2, L3, and L4 is the same: read pack → install pack → customise prompt and formula → watch a bead walk through on labels alone → fix findings by editing config, never by hand-editing output. L5 is that loop at scale.
