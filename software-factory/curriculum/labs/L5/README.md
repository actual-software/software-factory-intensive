# L5 / C1 · Run the Software Factory End-to-End

> **What you'll do:** Take a brand-new feature request — one your factory has never seen — and walk it through all six of the agents you customised across L2–L4, driven entirely by label flips on a single bead. The feature enters labelled `needs-plan` and leaves with either a closed bead and a tagged release, or a partial walk whose stall point is the most honest signal your factory will generate this week. W4 participants may have an Improver agent observing in the background. No ad-hoc prompts, no hand-edits in `src/` — every correction is a pack-prompt or formula edit on the agent that produced the fault.

| | |
|---|---|
| **Estimated duration** | ~90 minutes |
| **Type** | LAB / CAPSTONE |
| **Deliverable** | One bead walked through the factory on labels alone (any distance counts), a `docs/factory-runs/<date>-<slug>.md` run record, and a Keep / Change / Question retrospective committed alongside it |

---

## Session workspace note

* **Pack locations (shipped):** `packs/planner/`, `packs/architect/`, `packs/designer/`, `packs/coder/`, `packs/reviewer/`, `packs/deployer/` — and, if W4 is done, `packs/improver/` — all under the `software-factory/` tree. Prompt templates are `packs/<agent>/prompts/<agent>.md.tmpl`; formulas are `packs/<agent>/formulas/mol-<name>.formula.toml`; order gates are `packs/<agent>/formulas/orders/<agent>-intake/order.toml`.
* **Gas City workspace:** `my-factory/` — this is where `city.toml` lives. Every `gc` command below is run from that folder unless otherwise noted.
* **Your deliverables this session:** `docs/factory-runs/<date>-<slug>.md` and `docs/retrospectives/<date>-capstone.md` inside your **project rig** (the repo the factory is building). Plus any pack-prompt / formula commits you make when recovering from stalls.
* **No new pack work.** L5 doesn't customise any new packs — it runs the pipeline you already built. If a step stalls and the fix is a pack edit, that edit is a commit in `my-factory/packs/<agent>/`, same as every earlier lab.

**Canonical reference:** keep [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) open in another tab for the entire session. The capstone is the first time you see *all six* labels flip on the same bead back-to-back. If you forget which agent consumes which label, that doc is the one-page answer.

---

> **Agent Guide** — If an AI coding agent is guiding you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. This is the one session where "I'll finish it later" is disallowed: the run record and the retrospective card must be committed before the session ends, whether or not the bead reaches the deployer. An agent reading this README should first run `gc doctor` and `bd list --label=needs-plan` in the participant's factory — the capstone runs against the participant's *real* packs and their *real* project manifest, not against a scripted example.

---

## Architecture Diagram

The entire factory, compressed into one picture. Every arrow going *down* is a label flip on a bead (the routing signal). Every box is an agent woken by its order gate when the inbound label shows up on a `bd ready` query.

```
           (human files a feature bead with --label needs-plan)
                                 │
                                 ▼  needs-plan
               ┌────────────────────────────────┐
               │        PLANNER AGENT            │
               │  bd ready --label=needs-plan    │
               │                                  │
               │  writes docs/plans/<slug>.md     │
               │  creates child beads labelled    │
               │  needs-architecture /            │
               │  needs-design /                  │
               │  ready-to-build                  │
               └────┬────────┬────────────┬──────┘
                    │        │            │
      needs-        │        │ needs-     │ ready-to-
      architecture  │        │ design     │ build
                    ▼        │            │
   ┌────────────────────┐    │            │
   │  ARCHITECT AGENT    │   │            │
   │  bd ready           │   │            │
   │   --label=needs-    │   │            │
   │   architecture      │   │            │
   │                     │   │            │
   │  writes docs/       │   │            │
   │  architecture +     │   │            │
   │  docs/rules + syncs │   │            │
   │  CLAUDE.md / AGENTS │   │            │
   │  via actual adr-bot │   │            │
   │                     │   │            │
   │  relabels bead →    │   │            │
   │  needs-plan (back)  │   │            │
   └──────────┬──────────┘   │            │
              │              │            │
              └──→ planner runs again on the richer context ──┐
                                 │                              │
                                 ▼                              │
                     (children flow outward)                    │
                                 │                              │
                    ┌────────────┴─────────────┐                │
                    ▼                          ▼                │
           ┌───────────────────┐      (ready-to-build path      │
           │  DESIGNER AGENT    │       skips the designer)     │
           │  bd ready          │               │               │
           │   --label=needs-   │               │               │
           │   design           │               │               │
           │                    │               │               │
           │  writes docs/      │               │               │
           │  designs/<slug>.md │               │               │
           │                    │               │               │
           │  relabels →        │               │               │
           │  ready-to-build    │               │               │
           └──────────┬─────────┘               │               │
                      │                         │               │
                      └──────────┬──────────────┘               │
                                 │                              │
                                 ▼  ready-to-build              │
               ┌────────────────────────────────┐               │
               │          CODER AGENT            │               │
               │  bd ready --label=ready-to-     │               │
               │          build                  │               │
               │                                  │               │
               │  writes code + tests on a        │               │
               │  feature branch                  │               │
               │                                  │               │
               │  relabels → needs-review         │               │
               └───────────────┬──────────────────┘               │
                               │                                  │
                               ▼  needs-review                    │
               ┌────────────────────────────────┐                 │
               │        REVIEWER AGENT           │                 │
               │  bd ready --label=needs-review  │                 │
               │                                  │                 │
               │  writes findings + verdict into  │                 │
               │  bead notes                      │                 │
               └───────────┬────────┬──────────────┘               │
                    pass   │        │ request-changes              │
                           ▼        ▼                              │
                   ready-to-ship    ready-to-build ───→ back to coder
                           │
                           ▼  ready-to-ship
               ┌────────────────────────────────┐
               │        DEPLOYER AGENT           │
               │  bd ready --label=ready-to-ship │
               │                                  │
               │  runs checks → smoke → version   │
               │  → tag → rollback-plan          │
               │                                  │
               │  closes root bead,               │
               │  emits needs-improve bead        │
               └───────────────┬──────────────────┘
                               │
                               ▼  needs-improve (optional)
                  ┌────────────────────────────┐
                  │     IMPROVER AGENT (W4)     │
                  │  wakes on 24h cooldown or   │
                  │  manual harvest.            │
                  │  reads bead notes, mail,    │
                  │  deploy gates.              │
                  │  writes docs/feedback/      │
                  │  <date>.md; files new       │
                  │  labelled beads for humans  │
                  │  to accept or reject.       │
                  └────────────────────────────┘
```

There are no SPEC.md / ARCHITECTURE.md / REVIEW.md documents being passed between agents. Every handoff is a label flip on the same bead; every finding / plan / verdict / rollback plan lives in that bead's notes. The artifacts written to the project rig (`docs/plans/`, `docs/architecture/`, `docs/designs/`, `docs/releases/`) are for humans and downstream agents to **read**, not to route on. See [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) for why the factory runs this way.

---

## Prerequisites

Before starting the capstone, verify each row. If any row fails, fix it *before* filing the feature bead — a misconfigured factory at T+0 produces garbage signal that makes the retrospective useless.

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| Gas City running | `gc status` shows your city and all agents present | `gc service start` from `my-factory/` |
| All six packs wired | `gc doctor` green for `planner`, `architect`, `designer`, `coder`, `reviewer`, `deployer` | If a pack is failing, swap back to the shipped path in `city.toml` and `gc service restart` — shipped always passes `gc doctor`. The capstone works against shipped packs; it works *better* with your customised ones. |
| Project manifest tight | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` — the tech stack, review standards, and release criteria sections have testable rules, not "code should be clean" | Tighten before starting. The planner and architect read it as their primary context; the reviewer reads the standards section as its rubric; the deployer reads the release-criteria section for its gate checks. Vague manifest → vague factory. |
| `docs/rules/` populated | `ls ~/path/to/your-repo/docs/rules/` returns at least one `.md` | If empty, either re-run the L2 architect on a seed bead or `echo "# Project rules" > docs/rules/baseline.md` — designer, coder, and reviewer all read this directory. |
| Tailored ADRs synced | `actual status` in your project rig shows CLAUDE.md / AGENTS.md consistent with `docs/adr/` | Re-run `actual adr-bot` (see L2 Part 2). If the `actual` CLI isn't installed the check is skipped gracefully; the capstone still runs but the coder won't refuse on drift. |
| Clean working tree | `git -C ~/path/to/your-repo status` clean; `git -C my-factory status` clean | Commit or stash pending work. A dirty tree when the coder opens a feature branch invites merge headaches you don't want to debug under a 90-minute clock. |
| Optional: improver wired | `gc doctor` green for `improver` and `bd list --label=needs-improve --status=open` has at least one bead left over from L4 | Not required. If W4 was skipped, the Improver simply isn't part of the run. Note this in the run record under *Prior-session deviations*. |

**What "all six packs wired" means in practice.** Your `my-factory/city.toml` reaches every pack the factory needs, whether you point at shipped or customised copies:

```toml
includes = [
    # shipped or customised — same contract either way
    "../software-factory/packs/planner",    # or "packs/planner" if you copied locally
    "../software-factory/packs/architect",
    "../software-factory/packs/designer",
    "../software-factory/packs/coder",
    "../software-factory/packs/reviewer",
    "../software-factory/packs/deployer",
    # optional — only if W4 is done
    "../software-factory/packs/improver",
]
```

---

## The Feature (Pick This Before the Bead)

The capstone deliberately uses a feature you have **not** touched in L2–L4. If the prior labs drove a write-path feature (loyalty points, order creation, inventory mutation), pick a read-path feature now — and vice versa. A factory that ships two different feature types is an actual factory; a factory that ships the same shape twice is an elaborate prompt.

### For Fired Up Pizza (reference project)

**Feature:** Order history page — customers view past orders by phone number.

A customer navigates to `/orders/history`, enters a phone number, and sees their past orders with items, totals, date, and status. The feature:

- Touches both backend (new lookup endpoint on an existing table) and frontend (new page + form + list).
- Requires at least one architectural decision (rate-limiting against phone-number enumeration; the data-access pattern).
- Has acceptance criteria that are objectively testable (given phone X: see orders Y, Z; given unknown phone: see empty state; given invalid format: see validation error).
- Is medium complexity — roughly the same scope as the L2–L4 loyalty-points feature, but in a different slice of the app.

L2–L4 already drove the loyalty feature (a write-path, points-ledger mutation). Order history is a read-path feature (indexed lookups, empty states, pagination). The contrast is the point.

### For your own project

Pick an equivalent. It should:

- **Touch both sides** of your architecture (backend + frontend, service + client, core + worker — whatever your analogue is).
- **Require an architectural decision.** Something the architect will need to open `docs/adr/` and reason about.
- **Have testable AC.** "Given X, system returns Y" — not "the UX feels better."
- **Be 90-minute scope.** If you have to squint at the manifest to figure out where the code lives, the feature is too big.
- **Live in a different area** than the L2–L4 thread. The capstone tests factory generality, not factory memory.

Write the feature description as a markdown block before you run `bd create`. You'll paste it into the bead's notes.

---

## The Rules (Config Discipline)

Three rules. Every decision you make in the next 90 minutes comes back to one of them.

### Rule 1: No ad-hoc prompting.

If an agent produces wrong output — missing sections, wrong directory, vague reasoning — the fix is **always** a pack edit followed by re-arming the agent (add the label back; the order gate picks it up again). Never type corrections into `gc watch <agent>`. Never prefix an instruction with "also please remember to…".

**Why.** The factory you run today has to run tomorrow without you watching. A chat-message correction evaporates the moment the session ends; a prompt-file diff is committed, reviewable, and inherited by every future run.

### Rule 2: All fixes via config.

If tests fail after the coder runs, if the reviewer flags an issue, if the deployer gate refuses — the fix is a **prompt update**, a **formula update**, a **manifest update**, or a **rules-file update**. Never a manual code edit in your rig's `src/`.

**Why.** A manual code edit ships the fix for this feature and loses it for every future feature. A pack edit ships the fix into every subsequent factory run. The whole point of the factory is that corrections compound; hand-edits erase that property.

### Rule 3: Log everything in bead notes and in the run record.

Findings, verdicts, gate checks, rollback plans — all live in the bead's notes via `bd update --notes`. The `docs/factory-runs/<date>-<slug>.md` record is a **live log** updated as the run unfolds, not a post-hoc write-up. At T+90 the record should already be 80% complete; the last 10 minutes are for the retrospective and the "what I'd change" lines.

**Why.** Memory of what happened during a 90-minute run decays inside hours. A change you made at T+20 blurs into the one at T+45. If the record is your working document during the run, it captures the truth; if you write it at T+85 from memory, it captures fiction.

---

## Part 0: Pre-Run Setup (~10 min)

> **Agent Guide:** Before the participant runs a single command, have them read the feature back to you out loud — user story, acceptance criteria, constraints. Push for medium complexity in a *different area of the codebase* than the L2–L4 runs. Also open the run record in a split pane now; it's a live log, not a write-up.

### Step 1: Start the run record

In your **project rig** (not `my-factory/`):

```bash
cd ~/path/to/your-repo
mkdir -p docs/factory-runs docs/retrospectives
```

Create `docs/factory-runs/$(date +%Y-%m-%d)-<feature-slug>.md` with the skeleton below and open it in a split pane:

```markdown
# Factory Run — <feature name>

**Date:** 2026-04-22
**Bead ID:** (fill in after Step 2)
**Prior-session deviations:** (e.g. "W4 skipped — no improver observing")
**Run status:** IN_PROGRESS | COMPLETE | PARTIAL

---

## Label Walk

| T+min | Stage | Agent | Inbound label | Outbound label | Artifact | Config iterations |
|-------|-------|-------|---------------|----------------|----------|-------------------|

## Pack edits made during the run

| Commit | Pack | What the finding required |
|--------|------|---------------------------|

## Ad-hoc prompts used

0 (target) — if non-zero, list each and the pack edit that would prevent it.

## Human interventions

| T+min | Why | Action taken | Duration |
|-------|-----|--------------|----------|
```

### Step 2: File the root bead

```bash
cd ~/path/to/your-repo
bd create \
  --title "Feature: Order history page" \
  --label needs-plan \
  --notes "$(cat <<'EOF'
user_story:
  As a returning customer
  I want to look up my past orders by phone number
  So that I can re-order favourites and check recent order status

acceptance_criteria:
- Customer on /orders/history sees a phone-number input
- Valid phone with orders: list orders newest-first with items, total, date, status
- Valid phone with no orders: empty state with link to menu
- Invalid phone format: inline validation error, no lookup
- Endpoint is rate-limited to prevent phone-number enumeration

constraints:
- Use the existing orders table (no schema migration unless ADR justifies)
- Lookup must be O(log n); add an index if needed
- UI consistent with the order-confirmation page (Tailwind, no new tokens)

success_metrics:
- Lookup P95 < 200ms for up to 10,000 orders
- Page loads in < 1s on a mid-tier phone
EOF
)"
```

Note the bead ID that comes back. Paste it into the run record's **Bead ID** field. This is the anchor for every subsequent label flip.

### Step 3: Open the observation panes

```bash
# Pane A — every city event in real time
gc events --follow

# Pane B — active sessions (refresh as needed)
gc status

# Pane C — the bead itself
watch -n 5 "bd show <bead-id>; echo '---'; bd label list <bead-id>"
```

Pane C is the single most important view in the capstone. The labels on the bead tell you where the feature is in the pipeline; the notes tell you what each agent found. If you can only keep one pane visible, keep this one.

---

## Part 1: Watch the Factory Run (~55 min)

> **Agent Guide:** Before every label flip, ask the participant: "Which agent is about to wake, and what artifact will it produce?" If they can't name the agent and the path (e.g. `architect → docs/architecture/<topic>.md`), open `LABELED_BEADS.md` together before letting the next agent run.

The factory is now autonomous. You do not `gc sling` anything — the order gates in each pack's `formulas/orders/<agent>-intake/order.toml` poll `bd ready --label=<inbound>` every few seconds, and the agent wakes the moment its label shows up on the queue. Your job for the next 55 minutes is to **observe**, **record**, and **recover** (if an agent stalls).

### Stage 1 — Planner wakes on `needs-plan`

**What to watch:** the planner reads the bead's notes, `docs/PROJECT_MANIFEST.md`, `docs/architecture/*.md`, and `docs/rules/*.md`. It runs `mol-plan-breakdown` (intake → clarify → decompose → dep-graph → handoff).

**Expected outcome:** a new file `docs/plans/<slug>.md`, plus one or more child beads. Each child is labelled either:
- `needs-architecture` — if the planner detected drift from existing rules;
- `needs-design` — if the child has user-facing behaviour;
- `ready-to-build` — if the child is pure backend or internal work.

**Log it:** add a row to the run record:

```
| T+5 | Plan | planner | needs-plan | needs-design, ready-to-build | docs/plans/order-history.md + 2 children | 0 |
```

**If it stalls** (no output after ~5 min, or output is missing a section): see *Part 2: When an Agent Stalls*.

### Stage 2 — Architect wakes on `needs-architecture` (conditional)

If the planner filed a `needs-architecture` child, the architect wakes next. It runs `mol-architect-review`, produces `docs/architecture/<topic>.md` and `docs/rules/<topic>.md`, syncs CLAUDE.md / AGENTS.md via `actual adr-bot`, and relabels the child back to `needs-plan` so the planner can re-decompose against the richer context.

**What to watch:** the key output is the ADR under `docs/architecture/`. Open it; the decision + consequences section should name the rule-file additions. Then open the rule file.

**If no architecture child was filed,** skip this stage entirely. Record in the run record: `Architecture stage: not triggered (planner's decomposition did not flag drift).`

### Stage 3 — Designer wakes on `needs-design`

The designer reads the child bead, `docs/plans/<slug>.md`, the design system rules, and any existing components. It runs `mol-design-cycle` (intake → wireframe → a11y-check → handoff), writes `docs/designs/<slug>.md`, and relabels the child `ready-to-build`.

**What to watch:** the design doc's **a11y section**. Without explicit a11y bullets the coder has nothing to write tests against; a designer spec with no a11y coverage is the single most common upstream cause of coder stalls.

### Stage 4 — Coder wakes on `ready-to-build`

The coder runs `mol-code-from-spec` (intake → actual-adr-check → plan → implement → self-test → handoff). It creates a feature branch, writes code + tests, commits, and relabels the bead `needs-review`.

**What to watch:** three things, in order:

1. **actual-adr-check.** The bead notes should record `adr_check: ok` (or a documented hand-back to architect). If this step is missing the coder is writing against stale rules.
2. **self-test.** The coder runs the `test_cmd` pinned in the formula (see L3 Part 3 Step 1). A green self-test is a hard predictor of a green reviewer run.
3. **The commit message.** Conventional-commits format, one-liner references the bead ID. The deployer reads this at version-bump time.

### Stage 5 — Reviewer wakes on `needs-review`

The reviewer runs `mol-code-review` (intake → style → security → spec/AC → verdict). It reads the diff, the design doc, the project rules, and the bead notes. It writes four finding buckets (`style_findings`, `security_findings`, `spec_findings`, `verdict`) into the bead notes and relabels either:

- `ready-to-ship` — verdict `pass`, bead advances to the deployer.
- `ready-to-build` — verdict `request-changes`, bead goes back to the coder.

**If the reviewer bounces the bead,** read the findings in `bd show <bead-id>`, identify the upstream cause (coder prompt gap, designer spec gap, or manifest rule gap), and apply a **config edit** — never a hand-edit to `src/`. Re-arm by adding `ready-to-build` back. Log both the finding and the pack commit in the run record's *Pack edits made during the run* table.

### Stage 6 — Deployer wakes on `ready-to-ship`

The deployer runs `mol-deployer` (intake → checks → smoke → version → tag → rollback-plan). It writes gate checks, a semver bump, a git tag, and — crucially — a **rollback plan** into the bead notes *before* the deploy trigger, not after. It then closes the bead and emits a fresh bead labelled `needs-improve` for the optional improver.

**What to watch:** the rollback plan section. "Roll back somehow" is not a plan; "Revert tag v1.4.2, no migrations to reverse, no feature flags to toggle" is. If the plan is vague, that's a deployer-prompt issue — see L4 Scenario B.

### Stage 7 — (optional) Improver observes on cooldown

If W4 is done and `packs/improver/` is included, the improver either wakes on its 24-hour cooldown or you can trigger a live harvest:

```bash
cd my-factory
sh packs/improver/commands/harvest.sh 1h
```

It reads bead notes, mail, and deploy-gate metadata from the run, classifies the signals, and files new beads (each with a canonical label) representing proposed config changes to the six essential agents. These beads are **proposals for humans to review**, not auto-applied edits. See W4 Part 3 for the accept/reject workflow.

If W4 is skipped, the `needs-improve` bead from Stage 6 simply sits in the queue — that's fine, it's a durable breadcrumb for a future Improver run.

---

## Part 2: When an Agent Stalls (mail, nudge, re-label)

> **Agent Guide:** The instinct to type into an agent's session to unstick it is the single strongest pull of the whole workshop. Catch the participant the moment their hand hovers over `gc watch <agent>` to type a correction. Redirect to one of the three recovery patterns below.

A "stall" is 5+ minutes of no session activity, or output that immediately fails its own quality gate. There are three legitimate recovery actions, in order of preference.

### Recovery 1: Re-label (when the agent finished but wrote the wrong outbound label)

Most common. Example: the designer finished a design but relabelled `needs-plan` instead of `ready-to-build`.

```bash
bd label remove <bead-id> needs-plan
bd label add <bead-id> ready-to-build
```

The coder's order gate picks it up on the next poll. This is a **free** recovery — you don't even restart the agent. Record it in *Human interventions* with duration ~30 seconds.

### Recovery 2: Config edit + re-arm (when the agent produced wrong output)

When the output is wrong in a way a prompt or formula edit would prevent. Example: the reviewer approved a diff with a string-concatenated SQL query.

```bash
# 1. Identify the pack that owns the finding
cd my-factory
$EDITOR packs/reviewer/formulas/mol-code-review.formula.toml  # or prompts/, as the case requires

# 2. Commit the edit with a message naming the finding
git add packs/reviewer
git commit -m "chore(reviewer): BLOCKER on any SQL built via string concatenation"

# 3. Restart the service so the new config loads
gc service restart

# 4. Re-arm the agent: add its inbound label back
bd label add <bead-id> needs-review
```

The agent runs again on the same bead with the new rule. Record the commit hash in the run record's *Pack edits made during the run* table.

### Recovery 3: Mail + nudge (when the agent is stuck on something the bead can't carry)

When an agent needs context that doesn't belong in the bead itself — e.g. an architect wants the planner to clarify scope before committing to an ADR, or a reviewer wants the coder to explain a non-obvious choice.

```bash
# Send mail from one agent's inbox to another (you can impersonate either side in the capstone)
gc mail send architect --to planner \
  --subject "Clarify scope on <bead-id>" \
  --body "The plan references 'normalize phone numbers' but doesn't specify E.164 vs. local format. Resolve before I ADR."

# Then nudge the target agent to re-read its mail
gc nudge planner
```

The planner wakes, reads its inbox, updates the plan, and re-advances. Mail is the escape valve for coordination that doesn't fit on a label — it should be rare (0–2 uses in a clean capstone). If you're using mail more than twice, the agents' prompts are probably missing a reading list that should have caught the question upstream.

### What not to do

- **Don't `gc sling <agent> <bead>`** as a first response to a stall. Slinging is for manual debugging (L2 Scenario 2 style); in the capstone the order gates should be waking the agents on their own. If they aren't, `gc doctor` will tell you why — usually a missing binary or a mistyped label.
- **Don't type into `gc watch <agent>`** to correct the agent's output. Ad-hoc prompts are Rule 1 violations; they also don't persist across runs, so "fixing" one bead leaves every future bead broken in the same way.
- **Don't hand-edit files in your rig's `src/`** to make a test pass. Rule 2. The coder's next run on any bead regenerates the same bug.

---

## Part 3: Close the Run & Retrospective (~15 min)

> **Agent Guide:** Do not let the participant skip this step, even if the bead is still in-flight at T+85. A partial record with honest state is an audit trail; a discarded partial run is wasted learning. The record and the retrospective must be committed before the session ends.

### Step 1: Finish the run record

In the run record, mark status:

- `COMPLETE` — the bead reached `closed` after the deployer ran.
- `PARTIAL` — the bead is in-flight somewhere in the pipeline. Name the stage in the *Run status* line: `PARTIAL — stalled at reviewer on request-changes loop`.

Fill in the remaining columns. A partial record is valuable **because** it names the stall point; don't retroactively invent outcomes for stages that didn't run.

### Step 2: Write the Keep / Change / Question card

Create `docs/retrospectives/$(date +%Y-%m-%d)-capstone.md`:

```markdown
# Capstone Retrospective

**Run:** <feature name>
**Date:** 2026-04-22
**Run status:** COMPLETE | PARTIAL

- **Keep:** One thing the factory did well and will keep doing. Be specific:
  what did the factory's config produce that you didn't have to intervene
  on? (e.g. "The reviewer caught an AC-coverage gap I would have missed —
  L4's AC-rubric tightening is paying off.")

- **Change:** One thing the factory got wrong that a pack edit would fix.
  Name the pack, the finding, and the edit you'd make. (e.g. "Designer
  produced a spec with no error-state wireframe. Tightening mol-design-
  cycle.formula.toml wireframe step to require one-per-state would prevent
  this.")

- **Question:** One thing you genuinely don't know how to resolve from the
  run. Not a complaint — a research question. (e.g. "When the reviewer
  bounces the bead twice on the same finding, what's the escalation path?
  Re-slinging is still hand-editing by another name.")
```

### Step 3: Commit both artifacts

```bash
cd ~/path/to/your-repo
git add docs/factory-runs/ docs/retrospectives/
git commit -m "docs(capstone): factory run record + retrospective — <feature>"

# And any pack edits made during the run
cd ../my-factory  # or wherever my-factory lives
git status
# review the pending prompt/formula commits from Part 2 Recovery 2
# ensure each has a chore(<agent>): message naming the finding
git push
```

A capstone that ended with a partial run, one pack commit, and two committed docs is a successful capstone. A capstone that shipped to prod but left the commits unpushed is not.

---

## What You Built (across L1–L5)

If this is the last session you're doing in the workshop, take five minutes here to look at what lives on disk now. Every row below is something the factory did not have at the start of Day 1.

| Layer | File / Location | What it is |
|-------|-----------------|-----------|
| Workspace | `my-factory/city.toml` | The factory's wiring — six pack includes plus (optional) improver |
| Planner | `my-factory/packs/planner/` | Your customised planner; reads manifest + rules; decomposes beads |
| Architect | `my-factory/packs/architect/` | Customised architect; writes ADRs + rules; syncs via `actual adr-bot` |
| Designer | `my-factory/packs/designer/` | Customised designer; wireframes + a11y audits |
| Coder | `my-factory/packs/coder/` | Customised coder; commits code + tests against ACs |
| Reviewer | `my-factory/packs/reviewer/` | Customised reviewer; four-lens verdict (style + security + spec/AC + engineering) |
| Deployer | `my-factory/packs/deployer/` | Customised deployer; tags releases + writes rollback plans |
| Improver (optional) | `my-factory/packs/improver/` | Optional 7th; classifies runtime signals into proposed config changes |
| Project manifest | `~/path/to/your-repo/docs/PROJECT_MANIFEST.md` | Tech stack + review standards + release criteria (read by all agents) |
| Rules | `~/path/to/your-repo/docs/rules/*.md` | Project-specific guardrails populated by the architect |
| ADRs | `~/path/to/your-repo/docs/architecture/*.md` + `docs/adr/*.md` | Architectural decisions; synced into CLAUDE.md / AGENTS.md |
| Plans | `~/path/to/your-repo/docs/plans/*.md` | Planner-produced decomposition records |
| Designs | `~/path/to/your-repo/docs/designs/*.md` | Designer-produced wireframes + a11y audits |
| Releases | `~/path/to/your-repo/docs/releases/v*.md` | Deployer-produced release notes + rollback plan |
| Feedback | `~/path/to/your-repo/docs/feedback/*.md` | (If improver is wired) harvested signals + classifications |
| Run records | `~/path/to/your-repo/docs/factory-runs/*.md` | One record per capstone-style end-to-end run |
| Retrospectives | `~/path/to/your-repo/docs/retrospectives/*.md` | Keep / Change / Question cards per run |

Every handoff between those agents is a label flip on a bead. Every finding is a note on that bead. The coordination surface of the whole factory is the six canonical labels in [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) plus the mail inboxes; there is no central state, no SPEC.md, no orchestrator service. That is the factory. It's yours.

---

## Inline Insight: Why the Capstone Uses a Feature You Haven't Seen Before

L2 through L4 used the loyalty-points thread. That thread taught you the primitives — how a `needs-plan` bead becomes a design, how a design becomes code, how code becomes a release. But because you watched each stage iteratively on the same feature, it's easy to leave the labs with a factory that works on *the loyalty feature* and not for *arbitrary features*.

The capstone feature deliberately lives in a different slice of your codebase. Order history is a **read-path feature** (lookups, indexing, empty states) where loyalty points was a **write-path feature** (mutations, ledgers, consistency). If your factory runs cleanly on both, you've validated that the configuration generalises. If it stumbles, the stumble location tells you exactly which agent's prompt has a write-path-only assumption baked in. That signal is more valuable than a successful run on the same feature would have been.

## Inline Insight: Why Partial Completion Still Teaches You What You Need

You might not reach the deployer in 90 minutes. This is not a failure condition — it's the most common outcome on a first capstone run, and the run record is calibrated to reward it.

The value of the capstone is in the *signal it generates*, not the *stages it completes*. A run that stalls at the coder because the designer spec was under-specified tells you more about your factory than a run that ships to production on luck. The stall point is the exact coordinate of the weakest link.

Commit what you have. If you finished planner + designer + coder and the reviewer is still bouncing at T+85, mark the record `PARTIAL — stalled at reviewer request-changes loop`, note why in the retrospective's *Change* bullet, and commit. Next week you run again; the stall moves downstream. Three runs in, you'll be hitting the deployer reliably. The only wrong outcome is an uncommitted run — those erase themselves from memory inside 48 hours.

## Inline Insight: Why You Don't Type `gc sling` During the Capstone

In L2–L4 you sometimes slung agents manually to test a specific prompt edit. That was training. The capstone is the first session where the factory *is supposed to run itself*, with order gates waking agents on their own labels and no human in the dispatch loop.

If you catch yourself typing `gc sling <agent> <bead>` during the capstone, stop and ask why. The two legitimate reasons: (a) the order gate is broken and you're debugging it (check `gc doctor`); (b) you need a surgical re-run of one step after a pack edit and you don't want to wait for the next poll. Any other reason is a Rule 1 violation dressed up in CLI form — you're overriding the factory's contract to satisfy an impatience the factory is supposed to eliminate.

---

## Common Issues & Solutions

### Issue 1: A bead sits on a label and no agent wakes

**Cause:** Either the label on the bead doesn't match what the agent's order gate polls, or the agent isn't running.

**Fix:** `bd ready --label=<the-label> --limit=1` — if it returns the bead, the order-gate condition is met; check `gc doctor` for the agent's `check-<agent>` script. If it returns nothing, `bd label list <bead-id>` — watch for trailing spaces, case mismatches, or a label typo. Labels are case-sensitive.

### Issue 2: Reviewer keeps bouncing the bead on the same finding

**Cause:** You're hand-fixing the code, or the pack edit you did doesn't actually address the finding.

**Fix:** `git log my-factory/packs/coder my-factory/packs/reviewer` for the duration of the bounces. If there are zero commits matching the finding, you hand-fixed. If there's one commit, read it — does it make the rule explicit, or is it still interpretable? Make the edit literal (see L4 Scenario C for the pattern).

### Issue 3: Deployer sets `version_after` = `version_before`

**Cause:** The coder's commit message didn't follow conventional-commits (`feat:` / `fix:` / `chore:`), so the version-bump step had no signal.

**Fix:** Tighten the coder prompt to require conventional-commits (see L4 Issue 5). Re-arm the coder with `ready-to-build`; the next commit will bump correctly.

### Issue 4: Rollback plan says "Data migrations to reverse: unknown"

**Cause:** The deployer couldn't confidently enumerate migration state. This is a safety-first default — the formula prefers "unknown" over a plan it can't verify.

**Fix:** Add a project-specific hint to `packs/deployer/prompts/deployer.md.tmpl`: "Migrations live in `db/migrations/*.sql`. Diff HEAD vs. the previous tag to list new migrations." Re-arm with `ready-to-ship`.

### Issue 5: `actual-adr-check` aborts the coder run with "drift"

**Cause:** CLAUDE.md / AGENTS.md are out of sync with `docs/adr/` — an ADR changed but the sync never ran.

**Fix:** `cd ~/path/to/your-repo && actual adr-bot sync` (see L2 Part 2 Step 1). Then re-arm the coder with `ready-to-build`. The coder's next run sees consistent state and proceeds.

### Issue 6: Improver proposes a bead that would loosen a tailored ADR

**Cause:** The improver is doing its job — classifying a signal — but the proposal conflicts with a baseline the architect committed to. This is expected; it's exactly why every improver proposal goes through a human gate.

**Fix:** Close the proposed bead with a reason: `bd close <bead-id> --reason "conflicts with tailored ADR <path>; escalate via new architecture bead if still needed"`. A rejected proposal is the gate working, not a failure.

### Issue 7: Planner produces zero child beads

**Cause:** The feature is smaller than the planner's threshold for decomposition, or the bead description was too thin to plan against.

**Fix:** If the feature is genuinely atomic, relabel the bead directly to the first non-planner label it needs (`needs-design` or `ready-to-build`) and note the skip in the run record's *Human interventions* table. If the description is thin, add to the notes (`bd update --notes "..."`) and re-arm with `needs-plan`.

### Issue 8: Mail sent between agents sits unread

**Cause:** Agents read their mail during specific formula steps (usually `intake`). An agent in cooldown or mid-run won't check mail until the next intake.

**Fix:** `gc nudge <agent>` wakes the target agent explicitly. If it still doesn't read mail, check that the formula's `intake` step includes a `gc mail inbox --agent <self>` call — the shipped formulas do; a customisation may have dropped it.

---

## Quality Bar

When you review your capstone output, check each:

- **Labels drove everything.** `gc events --follow` output for the root bead shows `label_added` / `label_removed` events at every handoff. No `gc sling <agent> <bead>` in the history except in Recovery 2 retries.
- **Findings live in bead notes.** `bd show <bead-id>` renders `plan`, `design`, `impl_plan`, `self_test`, `adr_check`, `style_findings`, `security_findings`, `spec_findings`, `verdict`, `gate_checks`, `version_before`/`after`, and `rollback_plan` — all for one bead. A missing note means the corresponding formula step didn't run.
- **Config-first fixes.** `git log my-factory/packs/` over the run duration has at least one commit whose message names a finding from the run. `git log ~/path/to/your-repo/src/` has **zero** commits attributable to fixing a finding.
- **Run record honest.** If the run was partial, the status field says `PARTIAL` and the missing stages are listed as "not reached." A record that marks every row `PASS` when the reviewer never ran is fiction.
- **Retrospective specific.** Keep / Change / Question bullets name concrete packs, files, or findings. "Keep: shipping faster" is vague; "Keep: the reviewer's AC-coverage rule from L4 caught the uncovered-state bug" is actionable.
- **Pushed.** `git -C ~/path/to/your-repo status` and `git -C my-factory status` both say "up to date with origin." A capstone stranded on a local branch erases itself.

---

## Concept Check (before closing the capstone)

> **Agent Guide:** Before declaring the session complete, ask the participant to explain each bullet in their own words, without re-reading. If they can't, revisit the matching section before running the Exit Criteria check.

- **Why the capstone uses a feature you haven't seen before.** (A rehearsed feature tests memory; a new feature tests the factory.)
- **Why `gc sling` should be rare in the capstone.** (Order gates wake agents automatically; manual slinging is for debugging, not for the normal pipeline.)
- **What a "pass" from the deployer actually proves.** (Only that the release-criteria in the manifest were met — not that the feature is good; that's the reviewer's job.)
- **Why the retrospective asks for a Keep, a Change, and a Question.** (Keep validates what compounds, Change surfaces what doesn't, Question flags what you couldn't resolve alone and will need outside signal for.)
- **Why a partial run is a committable success.** (A partial record with an honest stall point is an audit trail; a discarded partial run is wasted learning.)
- **What the Improver does and does not do.** (Classifies runtime signals and files labelled beads for humans to accept or reject; **does not** edit prompts or code directly.)

---

## Exit Criteria

You pass the capstone when all of these are true. Check them off as you go.

- [ ] **Feature bead created** with explicit acceptance criteria + constraints + success metrics in the notes (not a one-line description)
- [ ] **At least one label flip recorded** on the bead — `needs-plan` → *something*. A factory that just re-reads its own inbound label is not a factory.
- [ ] **Zero ad-hoc prompts** typed into any `gc watch <agent>` session during the run
- [ ] **Zero hand-edits to `src/`** in your rig (manual edits to *prompts*, *formulas*, *rules*, and *manifest* are encouraged; manual edits to agent-produced code are not)
- [ ] **Run record committed** at `docs/factory-runs/<date>-<slug>.md` in your rig — even if status is `PARTIAL` and most rows are blank
- [ ] **Retrospective card committed** at `docs/retrospectives/<date>-capstone.md` — Keep / Change / Question all populated
- [ ] **Any pack edits pushed** — if you ran Recovery 2 during the run, the resulting `chore(<agent>):` commits are on the remote
- [ ] **Both repos in sync with origin** — `git -C ~/path/to/your-repo status` and `git -C my-factory status` both say "up to date"

If all eight are checked, you've passed. If the reviewer or deployer stages didn't run, you've still passed — partial runs are first-class outcomes, and the stall point is your most valuable signal for what to fix before next week.

---

## Command Cheat Sheet

Every command you might use during the capstone, grouped by purpose.

```bash
# ----- Pre-run setup -----
cd ~/path/to/your-repo
mkdir -p docs/factory-runs docs/retrospectives
$EDITOR docs/factory-runs/$(date +%Y-%m-%d)-<slug>.md    # start the run record

# ----- File the root bead -----
bd create --title "Feature: <name>" --label needs-plan \
  --notes "user_story:
... 
acceptance_criteria:
- ...
constraints:
- ...
success_metrics:
- ..."

# ----- Observation panes (run in parallel) -----
gc events --follow                                # every city event
gc status                                          # active sessions + packs
watch -n 5 "bd show <bead-id>; echo ---; bd label list <bead-id>"

# ----- Recovery 1: re-label -----
bd label remove <bead-id> <wrong-label>
bd label add <bead-id> <right-label>

# ----- Recovery 2: config edit + re-arm -----
cd my-factory
$EDITOR packs/<agent>/prompts/<agent>.md.tmpl    # or formulas/mol-*.formula.toml
git add packs/<agent>
git commit -m "chore(<agent>): <what the finding required>"
gc service restart
bd label add <bead-id> <the-agent's-inbound-label>

# ----- Recovery 3: mail + nudge -----
gc mail send <from-agent> --to <target-agent> \
  --subject "..." --body "..."
gc nudge <target-agent>

# ----- Inspect the walk -----
bd show <bead-id>                 # current notes + labels + status
bd label list <bead-id>           # labels only
bd list --status=closed --since="1 hour ago"      # closed by the deployer?
bd list --label=needs-improve --since="1 hour ago" # improver's inbox
gc mail inbox --agent <any>       # any outstanding coordination messages

# ----- (Optional) harvest on demand if improver is wired -----
cd my-factory
sh packs/improver/commands/harvest.sh 1h
gc watch improver

# ----- Close the run -----
cd ~/path/to/your-repo
$EDITOR docs/factory-runs/<date>-<slug>.md        # fill in final status + tables
$EDITOR docs/retrospectives/<date>-capstone.md    # Keep / Change / Question
git add docs/factory-runs/ docs/retrospectives/
git commit -m "docs(capstone): factory run record + retrospective — <feature>"
git push
cd ../my-factory
git push                                           # any Recovery-2 pack commits
```

---

## Next Steps

The capstone ends here. Your factory continues.

### This week

1. **Push everything.** Every `chore(<agent>):` commit, the run record, the retrospective, and any ADR / rules / manifest edits the agents made. The diff from the start of L2 to the end of L5 is the most valuable artifact of the intensive.
2. **Archive the run log.** `gc events --dump --since 2h > ~/path/to/your-repo/docs/factory-runs/$(date +%Y-%m-%d)-events.log` — every event for later inspection if a future run regresses.

### Next week

1. **Run the factory on a real backlog ticket** — not a toy feature. The smoothness of the real-ticket run tells you whether the factory is ready for daily work.
2. **Act on your retrospective's *Change* bullet.** Whatever stalled most is your highest-leverage config target. Fix it before the second real-ticket run.

### Next month

1. **Roll up** `docs/factory-runs/` into a three-data-point trend: average config iterations per stage, average human intervention time, percentage of runs reaching the deployer. Three points are enough to see direction.
2. **Add a feedback rule** for any failure pattern that recurred across two or more runs. Keep the catalog small and specific; noisy rules create noise, not learning.
3. **Consider the Improver.** If you skipped W4, the `needs-improve` beads the deployer is emitting are sitting in the queue unread. Wire the improver and let it run for a week; even if you reject every proposal, the classified summary of your factory's runtime signals is worth the 30 minutes of W4.

### Ongoing

- **Promote recurring findings into ADRs.** A finding that the reviewer flags five times across five features is no longer a finding — it's a principle. Move the guidance into a `docs/adr/NNNN-*.md`, let `actual adr-bot` sync it into CLAUDE.md / AGENTS.md, and the coder will respect it without the reviewer having to bounce.
- **Treat pack files like source code.** They go through PR review. They have owners. They get refactored when they hit ~200 lines — extract shared sections into a common include file all packs reference.
- **Audit `git log --grep="chore("` weekly.** Bad config edits quietly drift the factory; the only cure is weekly review of what's been committed to `packs/` and why.

---

## Final Note

The capstone is not a milestone — it's a baseline. After you run it today, you should be able to run it again next week on a different feature and spend less time. Three months from now, the same run should take 20 minutes of human attention instead of 90. Six months from now, your factory should be running end-to-end on tickets while you're asleep, and the first sign of a problem is a bead sitting in `needs-review` — with findings already written by the reviewer — when you open your laptop in the morning.

If your factory is getting faster per run, you're doing this right. If it's getting slower, the config is drifting faster than it's adapting — audit the pack commits, prune the improver proposals that didn't pan out, and tighten the manifest.

That's the whole discipline: **labels as handoffs, config as the scaling axis, findings in bead notes**. The capstone is the first place you prove it. Every run after is the evidence.
