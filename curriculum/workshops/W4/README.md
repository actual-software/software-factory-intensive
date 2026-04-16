# W4 · Create Continuous Improvement Loops

> **What you'll build:** A set of feedback rules that let your factory learn from its own signals — reviewer findings, deploy gate failures, production incidents, and user reports — and automatically update the agent prompts, project manifest, or gate criteria that caused the problem. By the end of this workshop, you'll have one or more `feedback-loops/*.md` rule files committed, at least one agent prompt updated to encode a learning, and a clear mental model of which loops are safe to automate vs. which must escalate to a human.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `feedback-loops/*.md` rule files, one updated agent prompt, and a harm-case table committed at `activities/workshops/W4/feedback-loops/` |

---

## Session workspace note

Pack naming: references to *Coder* and *Deployer* in this README map to the shipped packs **`packs/builder`** and **`packs/release-gate`** respectively. Prompt templates live at `packs/<name>/prompts/<name>.md.tmpl`. W4 edits **existing** pack prompts (the ones L3/L4 wired in) — it does not add new entries to `../../../my-factory/city.toml`. Your W4 feedback-loop notes live at `../../../activities/workshops/W4/feedback-loops/`.

---

## Architecture Diagram

```
                ┌──────────────────────────────────────────────┐
                │             FACTORY RUN (N)                   │
                │                                                │
                │  Planner → Architect → Designer →              │
                │  Coder → Reviewer → Deployer                   │
                │                                                │
                └──────────────┬───────────────────────────────┘
                               │
                               │  emits signals
                               ▼
        ┌───────────────────────────────────────────────────────┐
        │                   SIGNAL STREAM                        │
        │                                                         │
        │  • Review findings     (review-reports/<slug>.md)       │
        │  • Gate results        (release-gates/<slug>.md)        │
        │  • Deploy errors       (CI logs, rollback events)       │
        │  • Production incidents (observability alerts, bugs)    │
        │  • User reports        (bugs filed against the product) │
        │                                                         │
        └──────────────┬──────────────────────────────────────────┘
                       │
                       │  three loop categories
                       ▼
   ┌─────────────────────────────────────────────────────────────┐
   │                                                               │
   │  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐    │
   │  │   REACTIVE    │   │  AGGREGATE    │   │    EXTERNAL     │    │
   │  │              │   │              │   │                │    │
   │  │  Single-run  │   │  Patterns    │   │  Prod events   │    │
   │  │  signal →    │   │  across many │   │  / user bugs   │    │
   │  │  prompt edit │   │  runs →      │   │  → new bead →  │    │
   │  │              │   │  manifest    │   │  feed Planner  │    │
   │  │              │   │  update      │   │                │    │
   │  └──────┬───────┘   └──────┬───────┘   └────────┬───────┘    │
   │         │                  │                    │             │
   └─────────┼──────────────────┼────────────────────┼─────────────┘
             │                  │                    │
             ▼                  ▼                    ▼
       ┌──────────────────────────────────────────────────┐
       │           CONFIG UPDATES (git commits)             │
       │                                                    │
       │   packs/<agent>/prompts/<agent>.md                 │
       │   docs/PROJECT_MANIFEST.md                         │
       │   feedback-loops/<slug>.md                         │
       │                                                    │
       └──────────────┬───────────────────────────────────┘
                      │
                      │  take effect on next sling
                      ▼
                ┌─────────────────────────────┐
                │    FACTORY RUN (N+1)          │
                │  …improved by construction    │
                └─────────────────────────────┘
```

---

## Prerequisites

Before starting this workshop, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| L4 complete | `ls ~/path/to/your-repo/review-reports/ ~/path/to/your-repo/release-gates/` → each has at least one `.md` file | Go back and complete L4 so you have real reviewer and deployer output to learn from |
| At least one full pipeline run | `git log --oneline` shows commits from all six agents | Run a feature through Planner → Architect → Designer → Coder → Reviewer → Deployer end-to-end |
| Project Manifest | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` → filled in | Copy from [`curriculum/PROJECT_MANIFEST_TEMPLATE.md`](../../PROJECT_MANIFEST_TEMPLATE.md) and complete the tech stack, conventions, review standards, and release criteria sections |
| Skeleton scaffold present | `ls ~/path/to/your-repo/feedback-loops/` → directory exists (may only contain `.gitkeep`) | `mkdir -p ../../path/to/your-repo/feedback-loops` |
| Access to prior signals | `ls review-reports/ release-gates/` → real output files, not placeholders | Re-run your agents on a feature so they emit real artifacts; feedback rules without real signal data are just theory |

---

## The Running Example: A Recurring Reviewer Finding

Throughout this workshop we use a single concrete scenario so the steps stay grounded.

**Scenario.** You ran Fired Up Pizza through the factory three times: once for the Loyalty Points feature (L2–L4), once for an Order History page, and once for a Menu Category filter. Each time the Reviewer produced a report. When you grep across all three reports you notice the same finding keeps showing up:

```
review-reports/loyalty-points-review.md:    - Missing try/catch on async handler in src/api/loyalty.ts:42 (severity: medium)
review-reports/order-history-review.md:     - Missing try/catch on async handler in src/api/orders.ts:118 (severity: medium)
review-reports/menu-category-review.md:     - Missing try/catch on async handler in src/api/menu.ts:67 (severity: medium)
```

The Coder keeps shipping unhandled async functions. The Reviewer keeps catching them. The human keeps approving the fix. This is the exact shape of problem feedback loops are for: a *known, recurring, cheap-to-encode* pattern that you want the factory to correct on its own from run N+1 onward.

If you're working against your own project, pick an analogous pattern from your review reports. If you haven't accumulated three runs yet, pick a plausible candidate from the Reviewer's Common Findings section — missing null checks, inconsistent error shapes, forgotten loading states, etc.

We'll thread this "missing try/catch" pattern through the workshop as our reactive-loop example. Later we'll layer on an aggregate loop (five runs in a row flagged the same thing → update the manifest) and an external loop (a user files a bug about a 500 error → open a new bead and feed it back to the Planner).

---

## Part 0: Read the `feedback-loops/` Skeleton (~5 min)

Before designing any rules, read what's already in the repo.

### Step 1: Open the Skeleton Directory

```bash
cd ~/path/to/your-repo
ls -la feedback-loops/
```

You should see at minimum:

```
feedback-loops/
  .gitkeep
```

If your skeleton ships a `README.md`, open it and read it. If not, the directory is empty by design — W4 is where you fill it in.

**What's happening here:** The skeleton reserves the `feedback-loops/` directory the same way it reserved `work-packages/` before L2, `design/` before L3, and `review-reports/` before L4. Each directory is the *output contract* of a specific agent or activity. `feedback-loops/` is unusual because it isn't produced by one agent — it's produced by a human (you) synthesizing patterns across all six agents' outputs.

### Step 2: Skim the Review Reports and Gate Files

Your feedback rules are only as good as the signals you have. Look at what's already there:

```bash
ls review-reports/
ls release-gates/
```

Open one review report and one gate file end-to-end. You're looking for two things:

1. **Recurring phrasing.** Does the Reviewer say "missing error handling" the same way each time, or does it vary ("try/catch absent", "async without rejection handling")? Consistent phrasing is what makes aggregate loops possible.
2. **Structured severity.** Are findings tagged `low/medium/high`? Feedback rules should mostly ignore `low` and always escalate `high`.

If phrasing is inconsistent or severity is absent, that's your first feedback rule candidate — but not the one we're working on today. Note it for later and move on.

### Step 3: Skim the Factory Run Report Format

You'll meet this file properly in C1, but the concept matters here: after every full factory run, the human writes (or generates) a short summary of what happened — which gates fired, which beads reopened, which findings recurred. Feedback rules read from those summaries too. For now, the artifacts in `review-reports/` and `release-gates/` are your Run Reports.

**What's happening here:** A feedback rule is a deterministic response to a signal that already exists in the repo. If the signal isn't written down as a committed artifact, you can't write a rule against it. This is why L4's output (structured review reports, structured gate files) is the prerequisite for W4.

---

## Part 1: Design Your Signal → Target → Action Map (~15 min)

Every feedback rule has the same three parts:

```
Signal (what happened, in what file, how often)
    → Target (which config file needs to change)
        → Action (what specific change, expressed as a diff or an inserted line)
```

Your deliverable for Part 1 is `feedback-loops/factory-feedback.md` — a table that maps at least three signals to targets and actions, plus two harm cases.

### Step 1: Create the File

```bash
cd ~/path/to/your-repo
cat > feedback-loops/factory-feedback.md << 'EOF'
# Factory Feedback Loops

## Signal → Target → Action Map

| # | Signal Type | Threshold | Config Target | Update Action | Category |
|---|-------------|-----------|---------------|---------------|----------|
| 1 | Reviewer finds missing try/catch on async handler | 2 occurrences across different features | `packs/builder/prompts/builder.md.tmpl` (Rules section) | Add: "Wrap every `async` route handler in try/catch. On error, log and respond with the project's standard error envelope." | Reactive |
| 2 | Deploy gate fails on "tests pass" with intermittent timeout | 3 timeouts in last 10 gates | `docs/PROJECT_MANIFEST.md` (Release Criteria) | Add: "Test runs must set a 30-second timeout per test and retry once on timeout; three consecutive timeouts block deploy." | Aggregate |
| 3 | Production 500 error on `/api/orders` reported by user | 1 user report (any severity) | New bead in Gas City, assigned to Planner | Create bead with reproduction steps, link to observability trace, mark `--requires-approval` | External |

## Encoded Rule

Rule #1 is our first encoded rule. We updated `packs/builder/prompts/builder.md.tmpl` in the same commit as this file. See the Rules section for the new bullet.

## Harm Cases

### Harm Case 1: Prompt bloat
- **What could go wrong**: If we append a rule every time any finding recurs twice, the Coder prompt grows unbounded. After 40 rules, the prompt is so long that Claude deprioritizes early sections.
- **Mitigation**: Cap the Rules section at 15 bullets. When adding a new bullet would exceed the cap, open a bead titled "Coder prompt consolidation" for a human to review and merge related rules.

### Harm Case 2: Contradicting a tailored ADR
- **What could go wrong**: A feedback rule learned from our project might contradict a tailored ADR from `actual adr-bot` in `CLAUDE.md`. For example, the Reviewer might flag raw SQL often enough that we add "always use the ORM" — but a tailored ADR says "parameterized raw SQL is fine for read-only admin reports."
- **Mitigation**: Before encoding any rule, grep `CLAUDE.md` for conflicting guidance. If a conflict exists, do not auto-commit; file a bead for human adjudication.
EOF
```

**What's happening here:** You're creating the artifact *before* you think about implementation. This is the same discipline from L2 — the Planner writes the work package, the Architect reads it, and nothing happens ad hoc. Here the table is the plan and the rule files that come later are the implementation.

### Step 2: Customize the Table for Your Project

The three rows above are illustrative. Replace them with signals you've actually observed in your own `review-reports/` and `release-gates/` directories:

1. Open a review report. Find the most recurring finding. That's a reactive-loop candidate.
2. Look across five release gates. Find the most common failure reason. That's an aggregate-loop candidate.
3. Think about the last time a human reported a bug to you about something the factory had shipped. That's an external-loop candidate.

Rewrite the rows so every cell is project-specific. Don't skip cells — the value of this table is that it forces you to be concrete about what triggers the rule and what it changes.

### Step 3: Confirm Each Row Has a Clear Target File

Each row's "Config Target" column must name a real file path in your repo. Verify:

```bash
ls packs/builder/prompts/builder.md.tmpl            # for row 1
ls docs/PROJECT_MANIFEST.md                 # for row 2
# row 3 has no single target file — it creates a new bead, which is fine
```

If a target is "the Coder's behavior" without a file path, that's not a feedback rule — that's a wish. Either find the right file, or delete the row.

### Step 4: Confirm Each Row Has a Thresholded Trigger

"Every time this happens" is not a threshold. The threshold column must be a number (occurrences, percentages, elapsed time). Examples:

- `2 occurrences across different features` — reactive
- `3 timeouts in last 10 gates` — aggregate
- `1 user report (severity >= medium)` — external

If a row says "whenever this happens", rewrite it as "on the first occurrence" and force yourself to decide whether that's really the right threshold.

**What's happening here:** Thresholds are the safety valve. A threshold of 1 means you trust the signal absolutely. A threshold of 5 means you want to see a pattern before acting. An aggressive threshold + a noisy signal is how feedback loops poison their own configuration. The table forces you to declare your risk tolerance per rule.

---

## Part 2: Reactive Loops — Single-Run Signals (~8 min)

A reactive loop fires on a signal from a single factory run. The source is usually the Reviewer (a finding) or the Deployer (a failed gate). The target is almost always an agent prompt. The action is always a small prompt edit.

### Step 1: Write the Reactive Rule File

Create `feedback-loops/reactive-async-error-handling.md`:

```markdown
# Reactive Loop: Async Error Handling

Source: original
Created: 2026-04-21
Author: austin

---

## Trigger

The Reviewer's report contains the phrase `missing try/catch` OR `unhandled async`
in any finding with severity >= medium.

## Threshold

Fires on the **second** occurrence across different features (i.e., different
`review-reports/*.md` files). A single finding is noise; two is a pattern.

## Target

`packs/builder/prompts/builder.md.tmpl` → Rules section.

## Action

Append this bullet to the Rules section (only if an equivalent bullet is not
already present):

> - Wrap every `async` route handler and every `async` database call in a
>   try/catch. On error, log with context and return the project's standard
>   error envelope (`{ error: { code, message } }`). Never let an async
>   function reject unhandled.

## Commit Message

`feedback(coder): encode async error-handling rule from review pattern`

## Reversal

If the rule causes false positives (Coder over-handles errors, wrapping things
that should throw), revert with `git revert <commit>` and file a bead to
re-scope the rule.

## Harm Cases

1. **Over-catching.** Wrapping every async call in try/catch can swallow real
   bugs. Mitigation: the rule specifies "log with context" — so errors are
   visible in observability even when caught.
2. **Prompt creep.** This bullet adds ~4 lines to the Coder prompt. With 20
   similar rules, the prompt becomes unwieldy. Mitigation: pair this rule
   with the "prompt consolidation" loop (see `factory-feedback.md` Harm Case 1).
```

**What's happening here:** The rule file is itself a markdown document, not a script. That's intentional. The "execution" of the rule is a human (or, later, a designated `actual feedback-bot` if you install it) reading this file, checking the trigger against the current `review-reports/`, and applying the action. The file records *what* the rule does and *why* — the source of truth for auditability.

### Step 2: Apply the Rule Manually

Now follow your own rule. Open `packs/builder/prompts/builder.md.tmpl`:

```bash
$EDITOR packs/builder/prompts/builder.md.tmpl
```

Find the Rules section. Append the new bullet:

```markdown
## Rules

- Follow the spec exactly. If the spec is wrong, note it but implement as written.
- Never modify files outside the scope of your bead's feature.
- If you need a dependency, add it via package manager and document in the commit.
- All code changes must be on a feature branch, never directly on main.
- Wrap every `async` route handler and every `async` database call in a
  try/catch. On error, log with context and return the project's standard
  error envelope (`{ error: { code, message } }`). Never let an async
  function reject unhandled.
```

Save and close.

### Step 3: Commit the Rule File and the Prompt Update Together

```bash
git add feedback-loops/reactive-async-error-handling.md packs/builder/prompts/builder.md.tmpl
git commit -m "feedback(coder): encode async error-handling rule from review pattern"
```

Committing the rule file and the prompt update in the same commit is the audit trail. When someone asks "why did we add this rule to the Coder prompt?", `git log -p packs/builder/prompts/builder.md.tmpl` points them at the feedback loop artifact that explains the *why*.

---

> **Insight: reactive loops are cheap.**
>
> A reactive loop touches exactly one prompt file and takes roughly ten minutes from signal to committed rule. That's the cheapest unit of self-improvement the factory has. Spend them liberally on recurring `medium`-severity findings. Don't spend them on `high` findings — those almost always deserve escalation to a human architect, not a one-line prompt bullet.

---

### Step 4: Verify the Rule Takes Effect on the Next Sling

The next time you sling the Coder on any feature, it should now produce code with try/catch on async handlers. Verify by re-running the last failing feature:

```bash
# pick any closed bead whose review report flagged the async issue
gc sling builder my-factory-<bead-id>
gc watch coder
```

When the Coder finishes, grep the output:

```bash
grep -c "try {" src/api/*.ts
```

The count should be higher than before the rule. If it's the same, the prompt update didn't take — check that you saved the file, that Gas City is loading the right pack path (`gc rig list`), and that the file you edited is the one Gas City reads (not a stale copy in a different directory).

---

## Part 3: Aggregate Loops — Pattern-Across-Runs Signals (~8 min)

An aggregate loop fires when a pattern appears across many runs, not just one. The target is usually `docs/PROJECT_MANIFEST.md` (because the learning is about the project as a whole) or a pack's `pack.toml` (because the learning is about how an agent is invoked, not what it does). Aggregate loops are more expensive than reactive loops — they require you to look across files and count — but they catch patterns that no single finding would surface.

### Step 1: Identify the Aggregate Pattern

For our running example, we'll use the test-timeout pattern: the Deployer's release gate has failed the "Tests pass" criterion three times in the last ten gates, and every time the failure reason was an intermittent test timeout, not a real assertion failure.

Check your gate files:

```bash
grep -l "timeout" release-gates/*.md
```

You should see multiple files. Open a few and confirm the phrasing is consistent ("test timeout", "timed out", etc.).

### Step 2: Write the Aggregate Rule File

Create `feedback-loops/aggregate-test-timeouts.md`:

```markdown
# Aggregate Loop: Intermittent Test Timeouts

Source: original
Created: 2026-04-21
Author: austin

---

## Trigger

The Deployer's gate file contains `Tests pass | FAIL` AND the failure evidence
mentions `timeout` (not `assertion` or `unhandled exception`).

## Threshold

Fires when the trigger appears in **3 or more of the last 10 gate files**.
Anything less is within expected flake rate.

## Target

`docs/PROJECT_MANIFEST.md` → Release Criteria section.

## Action

Add a Test Timeout Policy subsection:

> ### Test Timeout Policy
>
> - Each test sets a 30-second timeout.
> - On timeout, the test runner retries once.
> - Three consecutive timeouts on the same test mark it quarantined and block
>   the deploy until a human triages.

Also update `packs/release-gate/prompts/release-gate.md.tmpl` Quality Gate to reference
this policy:

> 7. Test Timeout Policy is honored (see manifest Release Criteria §Test
>    Timeout Policy).

## Commit Message

`feedback(manifest): add test timeout policy from aggregated gate failures`

## Reversal

If the policy turns out to cause legitimate tests to flake-quarantine, revert
the manifest change and adjust the threshold upward (5 consecutive timeouts).

## Harm Cases

1. **Hiding real bugs.** A genuinely slow query becomes "just a timeout" and
   gets retried forever. Mitigation: after 3 consecutive timeouts the test is
   quarantined — a human must look at it before the next deploy.
2. **False coverage.** Retrying once hides instability. Mitigation: the gate
   file still records the retry, so weekly audit catches drift.
```

### Step 3: Apply the Rule

Update `docs/PROJECT_MANIFEST.md` by appending a `Test Timeout Policy` subsection under Release Criteria. Update `packs/release-gate/prompts/release-gate.md.tmpl` Quality Gate to add item 7 referencing the manifest.

Commit all three files together:

```bash
git add feedback-loops/aggregate-test-timeouts.md docs/PROJECT_MANIFEST.md packs/release-gate/prompts/release-gate.md.tmpl
git commit -m "feedback(manifest): add test timeout policy from aggregated gate failures"
```

**What's happening here:** Aggregate loops update the *project manifest* rather than a single agent prompt because the learning is cross-cutting. The Coder, Reviewer, and Deployer all need to know about the timeout policy. By putting it in the manifest — which every agent already reads — one update propagates to all of them. If you put it in the Deployer prompt alone, the Coder still writes tests without timeouts and the Reviewer still doesn't flag them.

---

> **Insight: aggregate loops are disciplined.**
>
> Aggregate loops are where you keep the factory from generating rule sprawl. Every time a reactive loop looks like it should fire, ask: "is this really one-off, or is it the fifth time this shape of thing has happened?" If it's the fifth time, skip the reactive loop and write an aggregate one that generalizes. Five narrow reactive rules are always worse than one correct aggregate rule.

---

### Step 4: Record the Threshold Observation

Add a line to the rule file documenting the specific gate files that triggered it:

```markdown
## Triggering Observations

- `release-gates/loyalty-points-gate.md` (2026-04-10) — Tests pass | FAIL | test timeout in checkout-flow.test.ts
- `release-gates/order-history-gate.md` (2026-04-14) — Tests pass | FAIL | test timeout in pagination.test.ts
- `release-gates/menu-category-gate.md` (2026-04-18) — Tests pass | FAIL | test timeout in category-filter.test.ts
```

This record is what lets a future reviewer (or a future you) decide whether the rule is still justified. If six months pass and none of the triggering conditions recur, the rule can probably be retired.

---

## Part 4: External Loops — Production and User Signals (~8 min)

External loops fire on signals that come from *outside* the factory: production observability alerts, user-reported bugs, SRE incidents, support tickets. The target is never an agent prompt directly — it's a new bead that flows back through the factory starting at the Planner. External loops are the most expensive because they require the factory to process a full pipeline just to learn one thing.

### Step 1: Identify the External Signal Source

What observability do you trust as a signal source? Options:

| Signal source | Trustworthiness | Typical delay |
|---------------|-----------------|---------------|
| User bug report (filed via in-app form) | High (explicit user harm) | Minutes |
| Grafana / Datadog alert on error rate | Medium (needs tuning) | Seconds |
| PagerDuty incident | High (already triaged by SRE) | Seconds |
| Support ticket with engineering escalation | High (human-verified) | Hours |
| GitHub issue from internal user | Medium (noisy) | Hours |

For our running example, we'll use **user bug report** as the source. The user reported that placing an order returns a 500 error when the cart total exceeds $200. We have a trace and a reproduction.

### Step 2: Write the External Rule File

Create `feedback-loops/external-user-bug-to-bead.md`:

```markdown
# External Loop: User Bug Report → New Bead

Source: original
Created: 2026-04-21
Author: austin

---

## Trigger

A user bug report is filed through the in-app `/feedback` form OR a Grafana
alert fires on `http_errors{route="/api/orders"} > 5/min` for 5 minutes.

## Threshold

Fires on the **first occurrence** (this is a user-harm signal — no batching).

## Target

Create a new bead in Gas City assigned to the Planner. Do not edit any prompt
or config directly — let the full pipeline process it.

## Action

```bash
bd create "Bug: Order placement 500s on totals > \$200" \
  --description "$(cat <<'BEAD'
## Symptom
POST /api/orders returns 500 when cart total exceeds 20000 cents.

## Reproduction
1. Add 10 large pizzas to cart (total ~25000 cents)
2. Submit checkout
3. Observe 500 response

## Trace
grafana-prod trace abc123 (link to observability)

## User Impact
One user report so far, but any high-ticket order will hit this.
Ship-blocking for catering orders.

## Expected
POST /api/orders should succeed for any valid total under the account's limit.
BEAD
)" \
  --requires-approval \
  --priority high
```

Then sling it to the Planner as normal (`gc sling planner <bead-id>`). From
there it flows through the full pipeline.

## Commit Message

`feedback(external): record bug-to-bead external loop for order 500s`

## Reversal

External loops don't need reversal — the fix is whatever the Planner produces
and the Reviewer approves. If the pipeline produces a wrong fix, that's a
*separate* feedback signal (reviewer finding, deploy gate, or repeat user
report) and becomes its own loop.

## Harm Cases

1. **Duplicate beads.** The same bug reported by ten users creates ten beads.
   Mitigation: before creating the bead, grep open beads for the same trace
   or route. If one exists, comment on it rather than creating a new one.
2. **Low-signal user reports.** A user complaint about UI polish is not a
   bug. Mitigation: the trigger specifies observability corroboration OR an
   in-app form with repro steps — not generic complaints.
```

### Step 3: Note What's Not Being Updated

Read your rule file again. Note what it does *not* do:

- It does not update any agent prompt.
- It does not update the project manifest.
- It does not edit any code.

All it does is create a new bead. The bead then flows through the factory, and the factory produces a fix. If, during that fix, the Reviewer catches a *new* recurring finding — say, "missing numeric overflow check on order totals" — that becomes a new reactive loop in the future.

External loops are the entry point for work from outside the factory. They're not automation — they're *conversion* of a signal into a work item the factory already knows how to process.

---

> **Insight: external loops are expensive.**
>
> A reactive loop is one prompt edit. An aggregate loop is one manifest edit. An external loop is a full trip through all six agents — that's Planner, Architect, Designer, Coder, Reviewer, Deployer — before the user's problem is fixed. That's hours of agent time and roughly $5–$20 of LLM spend per external loop. Treat external loops as scarce. Only fire them on signals you genuinely trust. Everything that can be solved with a reactive or aggregate loop should be.

---

### Step 4: Commit the External Rule File

```bash
git add feedback-loops/external-user-bug-to-bead.md
git commit -m "feedback(external): record bug-to-bead external loop for order 500s"
```

Note we did *not* actually create the bead in this step — the rule file documents *how* to react when a user report comes in. The actual bead creation happens in response to a real signal, when the signal fires.

---

## Part 5: Encode One Rule and Tie It All Together (~6 min)

You now have three rule files:

```
feedback-loops/
  factory-feedback.md                       # signal → target → action table
  reactive-async-error-handling.md          # reactive example
  aggregate-test-timeouts.md                # aggregate example
  external-user-bug-to-bead.md              # external example
```

### Step 1: Pick Your Most-Impactful Rule

Re-read your `factory-feedback.md` table. Of the three rules, which one would save you the most time over the next month? For most participants, it's the reactive loop (async error handling, or whatever your equivalent is) — because the trigger fires often and the fix is mechanical.

Mark your chosen rule as "ENCODED" in `factory-feedback.md`:

```markdown
## Encoded Rules

| # | Rule | Status | Encoded At |
|---|------|--------|------------|
| 1 | Reactive: async error handling | ENCODED | packs/builder/prompts/builder.md.tmpl (Rules, bullet 5) |
| 2 | Aggregate: test timeout policy | ENCODED | docs/PROJECT_MANIFEST.md (Release Criteria §Test Timeout Policy) |
| 3 | External: user bug to bead | DOCUMENTED ONLY | (fires on real signal; no config change yet) |
```

### Step 2: Commit the Status Update

```bash
git add feedback-loops/factory-feedback.md
git commit -m "docs(feedback): mark reactive and aggregate rules as encoded"
```

### Step 3: Verify the Chain of Artifacts

Run:

```bash
git log --oneline --grep="feedback" -- feedback-loops/ packs/ docs/PROJECT_MANIFEST.md
```

You should see at least four commits:

```
abc1234 docs(feedback): mark reactive and aggregate rules as encoded
def5678 feedback(external): record bug-to-bead external loop for order 500s
9012345 feedback(manifest): add test timeout policy from aggregated gate failures
fedcba9 feedback(coder): encode async error-handling rule from review pattern
```

This commit log is your factory's self-improvement history. Every commit with prefix `feedback(...)` is a point where the factory learned something. Audit it weekly.

---

## Common Issues & Solutions

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Rule fires on noise | After encoding the async try/catch rule, the Coder now wraps every literal `async` keyword, including arrow callbacks that can't throw | Rewrite the rule bullet to narrow scope: "async route handlers AND async database calls." Re-sling and verify. |
| Threshold too aggressive | A reactive rule fires on the first occurrence and adds a prompt bullet the team later disagrees with | Raise the threshold from 1 to 2 or 3. Document the revised threshold in the rule file and in `factory-feedback.md`. Old rule bullet stays if it's still valid. |
| Prompt bloat | `packs/builder/prompts/builder.md.tmpl` has grown to 200 lines and Claude starts ignoring earlier bullets | File a bead titled "Coder prompt consolidation." A human reviews the Rules section and merges related bullets into higher-level guidance. Then delete superseded feedback rule files or mark them as consolidated. |
| Contradicting a tailored ADR | A feedback rule says "always use the ORM" but `CLAUDE.md`'s tailored ADRs allow parameterized raw SQL for admin reports | Do not encode the rule. File a bead for human adjudication: "Feedback rule conflicts with tailored ADR §sql-parameterization — decide which wins." Escape hatch is always human review. |
| Rule target file doesn't exist | Rule says update `packs/reviewer/prompts/reviewer.md` but that path isn't in your repo | Confirm the pack is installed (`gc rig list`). If it's included by `--include` from a shared directory, either edit the source or copy the pack into your repo for local overrides. Update the rule's Target to match. |
| No signals to learn from | `review-reports/` and `release-gates/` are empty because you haven't run a full feature yet | Go back and run a feature end-to-end (L2 → L3 → L4). Feedback loops without real signal data are theory, not practice. |
| Rule doesn't take effect after editing the prompt | Re-slinging the Coder produces the same un-handled async code | Gas City may have cached the old pack. Run `gc restart`. If still broken, verify with `gc rig list` which prompt file it's actually loading and confirm you edited that one. |
| Aggregate rule double-counts a single flaky test | The test timeout appears three times in three different gate files, but it's always the *same* test | Narrow the threshold: "3 distinct tests, not 3 occurrences of the same test." Add a distinctness check to the rule's threshold definition. |
| External loop creates duplicate beads | Five users report the same bug, producing five beads | Add a deduplication check to the rule: "before creating bead, search for existing open beads by trace ID or route path. If found, append a comment to that bead instead." |
| Can't tell which rules are still justified | Six months later, `feedback-loops/` has 20 rule files and no one knows which are live | Add a `Last Triggered` field to each rule file. Run a monthly review: any rule without a triggering observation in 90 days is marked `DORMANT` in `factory-feedback.md` and flagged for removal. |
| Feedback commit is rolled back by another agent | The Coder's next run reverts the Rules section somehow | The Coder should never be slung at prompt files. Add a rule to `packs/builder/prompts/builder.md.tmpl`: "Never modify files under `packs/`, `docs/`, or `feedback-loops/` — those are configuration, not code." |

---

## Example `feedback-loops/` Files (Full Reference)

Here are three complete rule files in the Fired Up Pizza voice, ready to copy and adapt.

### Example 1: Reactive — Loyalty Point Overflow

```markdown
# Reactive Loop: Loyalty Point Integer Overflow

Source: original
Created: 2026-04-22
Author: austin

---

## Trigger
Reviewer finding includes "integer overflow" OR "negative balance" on any
file under `src/api/loyalty.ts`.

## Threshold
2 occurrences across different features.

## Target
`packs/builder/prompts/builder.md.tmpl` Rules section.

## Action
Append:
> - Loyalty point math uses `BigInt` for balance storage. Points earned per
>   order are capped at 100,000 per transaction to protect the ledger from
>   overflow. See ADR-0001 for the rationale.

## Commit Message
`feedback(coder): require BigInt for loyalty point math`
```

### Example 2: Aggregate — Menu Category Duplicate Slugs

```markdown
# Aggregate Loop: Menu Category Slug Collisions

Source: original
Created: 2026-04-22
Author: austin

---

## Trigger
Reviewer findings across `review-reports/` mention "duplicate slug" OR
"slug collision" on menu category features.

## Threshold
3 occurrences in the last 30 days.

## Target
`docs/PROJECT_MANIFEST.md` Conventions section.

## Action
Add a subsection:
> ### Slug Uniqueness
> All user-visible slugs (menu categories, promos, customer URLs) are unique
> at the database level. The Designer's component spec must include a unique
> constraint for any new slug field. The Architect's ADR must identify the
> namespace of uniqueness (global vs. per-store).

## Commit Message
`feedback(manifest): require unique slugs globally for user-visible resources`
```

### Example 3: External — Order Confirmation Email Missing

```markdown
# External Loop: Order Confirmation Email Missing → New Bead

Source: original
Created: 2026-04-22
Author: austin

---

## Trigger
User report through `/feedback` form mentions "didn't get email" or
"no confirmation" about order placement.

## Threshold
1 user report with order ID attached.

## Target
New bead assigned to Planner.

## Action
Create a bead titled "Bug: Order confirmation email missing for order
<id>", include the user's trace, and mark `--priority medium`. Do not
edit any prompt — let the pipeline process it.

## Commit Message
`feedback(external): record missing-email bug-to-bead loop`
```

These three examples map one-to-one to the three loop categories. Copy them as templates for your own rules.

---

## How Feedback Rules Interact with Tailored ADRs

Feedback rules should *complement*, not compete with, tailored ADRs from `actual adr-bot`:

| Signal source | Lives in | Updated when |
|---------------|----------|--------------|
| `actual adr-bot` tailored ADRs | `# Tailored ADRs` section of `CLAUDE.md` | You run `actual adr-bot` (manual or cron) |
| Feedback rule updates | `packs/<agent>/prompts/<agent>.md` or `docs/PROJECT_MANIFEST.md` | Whenever a feedback rule fires |
| Project ADRs | `docs/adr/NNNN-*.md` | Architect writes during L2 flow |

**Order of precedence** (encoded in your Reviewer's prompt):

1. Project ADRs (most specific to this project)
2. Feedback rule updates (learned from this project's history)
3. Tailored industry ADRs (baseline)

When a feedback rule detects a pattern that *contradicts* a tailored ADR, the rule should **not** silently auto-commit. It should file a bead for human review: "Feedback rule wants to change §serde-deny-unknown-fields, but that contradicts tailored ADR §json-strict-parsing." This is the escape hatch from baseline drift.

---

## Gas City Integration (Optional)

If you want feedback rules to run on a schedule instead of only when you manually inspect signals, wire the analyzer into Gas City as an order. The skeleton reserves the slot:

```toml
# orders/feedback-analyze/order.toml
[order]
name = "feedback-analyze"
description = "Read review reports and gate files; apply rules from feedback-loops/"
schedule = "0 * * * *"           # hourly
agent = "devops"                 # any idle agent can run it
message = "Scan review-reports/ and release-gates/ for patterns matching triggers in feedback-loops/*.md. For each match above threshold, produce the action described in the rule file and open a bead for human review."
```

Note: we never auto-commit config changes from a cron-driven order. The order's job is to *propose* changes via a bead. A human (or a designated `actual feedback-bot` agent if you install one) reviews the bead and commits if the proposal looks correct. This is the one-human-per-rule safety valve.

---

## Quick Reference: The Three Loop Categories

| Category | Trigger source | Threshold type | Target | Cost | When to use |
|----------|---------------|----------------|--------|------|-------------|
| **Reactive** | Single run's review report or gate file | Small N (1–3 occurrences) | One agent prompt file | Low (~10 min) | Mechanical, recurring findings with clear prompt fix |
| **Aggregate** | Pattern across 5+ runs | Large N + time window (e.g., 3 in 10 gates) | Project manifest or multiple prompts | Medium (~20 min) | Cross-cutting conventions that multiple agents need |
| **External** | Production event, user bug, SRE incident | 1 occurrence with corroborating data | New bead to Planner (full pipeline re-run) | High (full factory trip, $5–$20 LLM) | Real user harm or high-trust observability signal |

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `feedback-loops/factory-feedback.md` committed with at least 3 signal → target → action rows
- [ ] At least one rule file committed per loop category (reactive, aggregate, external)
- [ ] At least one rule marked `ENCODED` in `factory-feedback.md`, with a real diff in the target config file (prompt or manifest)
- [ ] At least two Harm Cases documented in `factory-feedback.md` with mitigations
- [ ] Commit log shows `feedback(...)` commits for every rule file and every applied change
- [ ] A re-sling of an affected agent (Coder in the running example) produces output reflecting the encoded rule

**W4 feeds C1.** The feedback rules you design here will run in the background during C1's end-to-end factory run. Any rule that fires during C1 will produce a visible diff in the project config, and you'll audit those diffs as part of the C1 retrospective. Without at least one encoded rule, C1 has nothing to audit.

---

## Next Steps

In **C1 (Capstone)**, you'll run your complete factory end-to-end on a new feature, and the feedback loops you designed here will help the factory self-improve during the run:

- Every reactive rule you encoded will take effect on the first Coder run
- Every aggregate rule you encoded will apply to the first Deployer run
- Any external-loop-shaped signals during C1 (you file a bug against your own feature, for instance) will create a new bead and test the full external path

Bring to C1:

- `feedback-loops/factory-feedback.md` committed with at least 3 rows and 2 harm cases
- At least one rule marked `ENCODED` with a real diff in the target config
- A clean `gc status` showing all six agents still idle and ready

---

## Command Cheat Sheet

Every command you ran during this workshop, in order:

```bash
# PART 0 — Read the skeleton
ls feedback-loops/
ls review-reports/
ls release-gates/

# PART 1 — Design the map
cat > feedback-loops/factory-feedback.md << 'EOF'
... (signal → target → action table with 3 rows and 2 harm cases) ...
EOF

# PART 2 — Reactive loop
cat > feedback-loops/reactive-async-error-handling.md << 'EOF'
... (reactive rule file) ...
EOF
$EDITOR packs/builder/prompts/builder.md.tmpl    # append new Rules bullet
git add feedback-loops/reactive-async-error-handling.md packs/builder/prompts/builder.md.tmpl
git commit -m "feedback(coder): encode async error-handling rule from review pattern"

# Verify it took effect on next sling
gc sling builder my-factory-<bead-id>
gc watch coder
grep -c "try {" src/api/*.ts

# PART 3 — Aggregate loop
grep -l "timeout" release-gates/*.md
cat > feedback-loops/aggregate-test-timeouts.md << 'EOF'
... (aggregate rule file with Triggering Observations) ...
EOF
$EDITOR docs/PROJECT_MANIFEST.md                       # add Test Timeout Policy
$EDITOR packs/release-gate/prompts/release-gate.md.tmpl             # add Quality Gate item 7
git add feedback-loops/aggregate-test-timeouts.md docs/PROJECT_MANIFEST.md packs/release-gate/prompts/release-gate.md.tmpl
git commit -m "feedback(manifest): add test timeout policy from aggregated gate failures"

# PART 4 — External loop (rule file only; bead created on real signal)
cat > feedback-loops/external-user-bug-to-bead.md << 'EOF'
... (external rule file) ...
EOF
git add feedback-loops/external-user-bug-to-bead.md
git commit -m "feedback(external): record bug-to-bead external loop for order 500s"

# PART 5 — Encode one rule and update status
$EDITOR feedback-loops/factory-feedback.md             # mark rules ENCODED
git add feedback-loops/factory-feedback.md
git commit -m "docs(feedback): mark reactive and aggregate rules as encoded"

# Audit trail
git log --oneline --grep="feedback" -- feedback-loops/ packs/ docs/PROJECT_MANIFEST.md
```

---

## Quality Bar

When you review your own output, check:

- **Signal specificity.** Every trigger names the exact phrase or field to look for, not a concept. "Missing error handling" is too vague; "`missing try/catch` in a finding with severity >= medium" is specific.
- **Threshold rigor.** Every rule has a number in its threshold. "Sometimes" is not a threshold. "2 occurrences across different features" is.
- **Target precision.** Every rule points at one file path. Rules that target "the Coder's behavior" without a file path are wishes, not rules.
- **Action diff-ability.** Every action produces a visible diff in the target file. If you can't picture `git diff` output after applying the rule, the action isn't concrete enough.
- **Harm case honesty.** Every rule has at least one realistic way it could be wrong and a mitigation for that case. "No harm possible" is almost never true.
- **Auditability.** Every encoded rule is traceable via `git log --grep="feedback"`. Anyone reading the log can reconstruct why the config looks the way it does.

---

## Where Feedback Rules Live in Your Factory

After W4, your repo's `feedback-loops/` directory should look something like:

```
feedback-loops/
  factory-feedback.md                           # signal → target → action map + encoded status + harm cases
  reactive-async-error-handling.md              # reactive example
  aggregate-test-timeouts.md                    # aggregate example
  external-user-bug-to-bead.md                  # external example
  (more rule files as you learn more patterns)
```

Each rule file is a self-contained markdown document with Trigger, Threshold, Target, Action, Commit Message, Reversal, and Harm Cases. The `factory-feedback.md` file is the index — table of all rules, their status, and the harm cases that apply to the set as a whole.

This mirrors the slot the skeleton reserved in `reference-project/fired-up-pizza/feedback-loops/` and matches the pattern of every other agent-output directory: one index file (`factory-feedback.md`), plus one file per concrete artifact (each individual rule).

---

## Industry Context: Why Feedback Telemetry Beats Better Models

Continuous improvement loops in agentic systems are still early. A few reference points informed this workshop:

- **AI-native development research** generally finds that feedback telemetry — being able to see the agent's failures in a structured way — is higher-leverage than upgrading the underlying model. Agents that can see their own failure modes improve faster than agents that can't.
- **Evaluation frameworks** treat every run as a datapoint and re-run evaluations on prompt changes. Your W4 rules are the low-tech equivalent: log the failure, detect the pattern, update the config, verify the fix.
- **Reports on agentic code review** find that explicit "pattern → prompt update" pipelines cut reviewer false-positive rates significantly over months. The mechanism is identical to what you're designing: codify recurring findings into enforced rules.

The takeaway: auto-updating `packs/<agent>/prompts/*.md` or `docs/PROJECT_MANIFEST.md` is safe *only* when there's a human-in-the-loop escalation path for new patterns and a way to detect contradictions with tailored ADRs. The rule files you wrote in this workshop are how that escalation path is made durable and auditable.
