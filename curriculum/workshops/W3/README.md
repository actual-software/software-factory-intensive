# W3 · Architect Multi-Agent Coordination

> **Goal:** Learn how to orchestrate multiple agents working together in Gas City — understanding when agents run sequentially, where human gates fire, how state moves between agents via beads, and how to capture all of this in a single declarative `orchestrator.yaml` committed alongside your pack configs.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `orchestrator.yaml` draft + gate justification notes committed at `activities/workshops/W3/` |

---

## Session workspace note

Pack naming: references to *Coder* and *Deployer* in this README map to the shipped packs **`packs/builder`** and **`packs/release-gate`** respectively. Other agent packs keep their curriculum names. W3 is a design session — no pack is installed and `my-factory/city.toml` is not touched. Orchestrator + gate docs live at `../../../activities/workshops/W3/`.

---

## Architecture Diagram

```
                           ┌─────────────────────────────────┐
                           │        ORCHESTRATOR              │
                           │   (orchestrator.yaml rules)      │
                           │                                  │
                           │   • routes beads                 │
                           │   • enforces depends_on          │
                           │   • fires human gates            │
                           │   • applies on_reject rules      │
                           └───────────────┬─────────────────┘
                                           │  dispatches
                                           ▼
      ┌────────────────────────────────────────────────────────────────┐
      │                                                                  │
      │  Feature Request (bead)                                          │
      │        │                                                          │
      │        ▼                                                          │
      │  ┌───────────┐   WP      ┌────────────┐  ADR    ┌────────────┐   │
      │  │ PLANNER   │ ────────► │ ARCHITECT  │───────► │ DESIGNER   │   │
      │  │ (agent)   │           │ (agent)    │         │ (agent)    │   │
      │  └───────────┘           └────────────┘         └─────┬──────┘   │
      │                                                        │ spec    │
      │                                                        ▼         │
      │  ┌───────────┐  release  ┌────────────┐  report ┌────────────┐   │
      │  │ DEPLOYER  │◄───────── │ REVIEWER   │◄──────  │  CODER     │   │
      │  │ (agent)   │           │ (agent)    │  code   │ (agent)    │   │
      │  └─────┬─────┘           └──────┬─────┘         └────────────┘   │
      │        │                        │                                 │
      │        │                        │  on_reject → loop back to Coder │
      │        │                        └────────────────────────┐       │
      │        ▼                                                  ▼       │
      │   [HUMAN GATE]                                        bead state  │
      │   approve_deploy                                      transitions │
      │                                                                    │
      └────────────────────────────────────────────────────────────────────┘
                  │
                  ▼
           ┌─────────────┐
           │ Production  │
           └─────────────┘

Legend:
  WP  = work-packages/<slug>.md          (Planner artifact)
  ADR = docs/adr/NNNN-<slug>.md           (Architect artifact)
  spec = design/<slug>-spec.md            (Designer artifact)
  code = src/** + tests                   (Coder artifact)
  report = review-reports/<slug>.md       (Reviewer artifact)
  release = release-gates/<slug>.md       (Deployer artifact)

Arrows carry beads. Beads carry state. The orchestrator never touches code directly —
it only moves beads between agents and fires gates.
```

---

## Prerequisites

Before starting this workshop, verify each of these:

| Prerequisite | How to verify | If it's missing |
|-------------|---------------|-----------------|
| W1 complete | You have a `workflow-card.md` in your repo | Skim the [W1 README](../W1/) — 10 min |
| W2 complete | You have a wiring diagram with 6 agent roles and handoff contracts | Go back and complete [W2](../W2/) — the contracts are W3's input |
| L1 complete | `ls ~/path/to/your-repo/CLAUDE.md` → file exists | Complete L1 first; W3 references `CLAUDE.md` conventions |
| Project Manifest | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` → filled in | Copy from `curriculum/PROJECT_MANIFEST_TEMPLATE.md` and fill in |
| Skeleton scaffold | `ls ~/path/to/your-repo/work-packages/` → directory exists | `mkdir -p ../../path/to/your-repo/{work-packages,docs/adr,design,review-reports,release-gates,feedback-loops}` |
| An editor open | You can edit YAML files comfortably | Any editor — this workshop produces a single `orchestrator.yaml` and a short markdown file |

You do **not** need L2 complete to finish W3 — the output is a design artifact, not code. But W3 is where you decide how L2–L4's agents will chain together, so doing W3 *before* L2 gives you a roadmap; doing it *after* gives you a retrospective. Either is valid.

---

## The Running Example: Fired Up Pizza Loyalty Points

Throughout this workshop, we continue threading the **Loyalty Points** feature for Fired Up Pizza — the same feature used in W2 and L2. This makes the coordination map concrete: we're not coordinating "some feature" in the abstract; we're deciding how a specific, realistic feature flows through six agents.

If you're working against your own project, substitute your own feature — but use a feature that has:

- **At least one architectural decision** (so the Architect has something meaningful to do)
- **At least one high-risk step** (so there's a plausible human gate)
- **At least one step that could reasonably fail review** (so your `on_reject` loop is real, not theatrical)

The Loyalty Points feature satisfies all three: the storage decision is a real architectural question, the schema migration is a high-risk step, and the points-calculation code is easy to get subtly wrong — making a reviewer rejection plausible.

---

## Part 0: Read the Shipped Coordination Primitives (~5 min)

Before designing your own coordination, read what Gas City already ships. There are three primitives that your `orchestrator.yaml` composes.

### Step 1: Open the sync-jira Order

Orders are Gas City's built-in periodic trigger. Open this file end-to-end:

[`packs/workshop/orders/sync-jira/order.toml`](../../../packs/workshop/orders/sync-jira/order.toml)

```toml
[order]
description = "Bidirectional Jira sync — pull new tickets, push status updates"
gate = "cooldown"
interval = "5m"
exec = "bd jira sync || true"
```

**What's happening here:** This declarative block says: "every 5 minutes, if the cooldown gate allows it, run `bd jira sync`." The `gate = "cooldown"` field is a coordination primitive — it prevents the order from firing faster than `interval`, even if something else triggers it. Your `orchestrator.yaml` borrows this `gate` concept for per-stage gates (e.g., `gate = "human"` for human approvals).

### Step 2: Review the Bead Dependency Primitive

Gas City's `bd` CLI has a `--depends-on` flag:

```bash
bd create "Architect decision" --depends-on plan-123 --id arch-456
```

**What's happening here:** The dependent bead stays in `blocked` state until `plan-123` closes. This is the coordination primitive for **sequential pipelines**. Orchestrator `depends_on` entries compile to exactly this — a chain of blocked beads that unblock in order.

### Step 3: Review the Approval Bead Primitive

Gas City supports approval beads via `--requires-approval`:

```bash
bd create "Deploy to prod" --requires-approval --assignee austin@actual.ai --id deploy-789
```

**What's happening here:** The bead enters `needs-approval` state and sits there until `bd approve deploy-789` is called. This is the primitive for **human gates**. Your orchestrator's `gate: human` entries compile to this.

### Step 4: Internalize the Three-Primitive Rule

These three primitives (periodic orders, dependent beads, approval beads) are **everything you have** for coordination. There is no fourth mechanism. If your design needs "agent re-invokes itself on failure" or "two agents share a variable in memory," you're outside the primitives — which means you should redesign, because those patterns will not compile to Gas City.

### Step 5: Read the Existing Agent Packs Once More

You read these in L2. Re-skim them now with coordination in mind, because each one declares a contract the orchestrator will rely on:

- [`packs/planner/pack.toml`](../../../packs/planner/pack.toml) — `name = "planner"` is what `agent: planner` in your `orchestrator.yaml` will resolve to. `max_active_sessions = 1` means one bead at a time; the orchestrator will queue additional planner beads rather than run them concurrently.
- [`packs/architect/pack.toml`](../../../packs/architect/pack.toml) — same shape. The `idle_timeout = "1h"` field determines how long the agent's tmux session lingers; longer timeouts reduce cold-start overhead for rapid stage transitions.
- [`packs/designer/pack.toml`](../../../packs/designer/pack.toml), [`packs/builder/pack.toml`](../../../packs/builder/pack.toml), [`packs/reviewer/pack.toml`](../../../packs/reviewer/pack.toml), [`packs/release-gate/pack.toml`](../../../packs/release-gate/pack.toml) — the remaining four. You'll install the last two in L4, but the contracts are already defined.

Your `orchestrator.yaml` should treat the `[[agent]].name` values in these files as the **only** valid values for the `agent:` field in a stage. If you write `agent: plannr` by typo, `gc orchestrate apply` will fail at load time, not at runtime — which is the behavior you want.

---

## The Three Core Coordination Concepts

Your `orchestrator.yaml` will compose three coordination concepts, each mapped to one of the primitives you just read. We'll build up the file one concept at a time.

---

### Concept 1: Sequential Chaining (~5 min)

**When:** Stage B cannot start until Stage A has produced its artifact. Order matters; output of Stage N is the input of Stage N+1.

**Primitive used:** `bd create --depends-on`

**Fired Up Pizza example:**

```
Planner writes work-packages/loyalty-points-system.md
         ↓  (Architect cannot start without the work package)
Architect writes docs/adr/0001-loyalty-points-storage.md
         ↓  (Designer cannot start without the ADR)
Designer writes design/loyalty-points-spec.md
         ↓  (Coder cannot start without the design spec)
Coder writes src/loyalty/ + tests
```

**Expressed in orchestrator.yaml:**

```yaml
pipeline:
  stages:
    - name: plan
      agent: planner
      produces: work-packages/*.md

    - name: architect
      agent: architect
      needs: [plan]
      produces: docs/adr/*.md

    - name: design
      agent: designer
      needs: [architect]
      produces: design/*-spec.md

    - name: code
      agent: coder
      needs: [design]
      produces: src/**
```

**What's happening here:** `needs: [plan]` means this stage's bead is created with `--depends-on <plan-bead-id>`. The orchestrator won't sling this stage's bead to its agent until the prerequisite bead closes. `produces:` is a glob that documents what artifact this stage creates — the orchestrator uses it to verify the agent actually wrote something before marking the stage complete.

**Use sequential chaining when:**

- The downstream agent reads the upstream agent's artifact as part of its inputs
- Skipping an upstream stage would force the downstream agent to make decisions outside its scope (e.g., Coder guessing at architecture)
- The order is semantic, not just historical — reversing it would produce wrong output

**Do NOT use sequential chaining when:**

- Stage B could start with partial information from Stage A (the dependency is incidental)
- Two stages read the same upstream but don't read each other (those are candidates for parallel execution, a sibling pattern — but in W3 you will intentionally keep the pipeline linear; parallel fan-out is deferred until L4, where you'll have the full 6-agent runtime to test it safely)

> **Inline Insight: The Linear Pipeline Is the Honest Default**
>
> It's tempting to design a parallel-heavy coordination map to "save time." Resist this in W3. The six-agent factory's value is the *artifact trail*, not raw throughput. Every parallel fan-out adds a join point, and every join point is a place where state can desync between agents. Start linear. Add parallelism only once you have a working linear pipeline and a specific bottleneck you've observed — not guessed.

---

### Concept 2: Human Gates (~5 min)

**When:** The next stage has consequences that are hard or impossible to reverse, and no amount of agent improvement makes the decision safe to automate.

**Primitive used:** `bd create --requires-approval`

**Fired Up Pizza example:** After the Reviewer approves the code, we **do not** automatically deploy to production. A human reviews the release-gate document, checks the database migration plan, and calls `bd approve` before the Deployer actually runs.

**Expressed in orchestrator.yaml:**

```yaml
pipeline:
  stages:
    # ... (plan, architect, design, code from Concept 1)

    - name: review
      agent: reviewer
      needs: [code]
      produces: review-reports/*.md
      on_reject: code  # if reviewer rejects, loop back to coder

    - name: deploy
      agent: deployer
      needs: [review]
      gate: human            # pause until bd approve is called
      approvers:
        - austin@actual.ai
      produces: release-gates/*.md
```

**What's happening here:** `gate: human` tells the orchestrator to create this stage's bead with `--requires-approval`. It sits in `needs-approval` state with the reviewer's report attached as context. An approver (you, in the solo case; a team lead or security reviewer in production) runs `bd approve <bead-id> --comment "reviewed migration plan, proceed"` and only then does the Deployer get to run.

**Gate placement decision tree for the Loyalty Points feature:**

| Stage transition | Worst-case if it runs unattended | Gate needed? |
|---|---|---|
| Planner → Architect | Bad work package leads to a bad ADR — caught later, easy to redo | No |
| Architect → Designer | Bad ADR leads to a bad spec — caught later | No |
| Designer → Coder | Bad spec leads to bad code — caught by Reviewer | No |
| Coder → Reviewer | Reviewer is the check — no gate before the check | No |
| Reviewer → Deployer | Unreviewed migration hits production, corrupts points balances, cannot rollback without customer-visible incident | **Yes** |
| Deployer → Production | Same reason — covered by the same gate | (combined with above) |

So for Loyalty Points, **exactly one human gate** is justified: before the Deployer.

### The "while I was asleep" test

For each candidate gate, ask yourself: *"If this step ran while I was asleep, what's the worst that could happen?"*

Walk through the Loyalty Points feature stage by stage:

| Step | While-I-was-asleep outcome | Acceptable? |
|---|---|---|
| Planner writes wrong work package | Architect or Designer catches it, re-sling with revised description | Yes, no gate |
| Architect writes a weak ADR | Self-review catches it; worst case, spec gets re-drafted | Yes, no gate |
| Designer writes a wrong spec | Coder or Reviewer catches it; feature branch, nothing in production | Yes, no gate |
| Coder writes a subtle points-calculation bug | Reviewer catches it; if not, Deployer catches it in staging | Yes, no gate |
| Reviewer incorrectly approves broken code | Automated deploy pushes broken points-ledger migration to prod; customers lose/gain wrong points; cannot rollback without data loss | **No — gate required** |

This exercise is the single most important deliverable of Concept 2. **Write the answer down** — it becomes the gate justification doc you commit alongside `orchestrator.yaml`.

### What makes a good gate

**Good reasons for human gates:**

- **High cost**: "This spins up 20 new servers / costs $N per month"
- **Irreversible**: "This deletes customer data / runs a schema migration that drops a column"
- **Requires taste**: "Choose between these 3 UX mockups" — agents can surface the tradeoffs but not make the call
- **Compliance**: "Legal must review this contract change / public API surface change"

**Bad reasons for human gates:**

- **"Just to be safe"**: Adds friction without clear benefit. The factory runs slower and you start to ignore gates.
- **Lack of trust in agents**: Fix the agent config instead. If the Reviewer keeps approving bad code, the Reviewer's prompt needs more specific quality rules — that's a config-discipline problem, not a gate problem.
- **"We've always done it this way"**: Automation is the goal. A gate you don't have a written justification for is theater.
- **Checking every step**: Defeats the purpose of a software factory. If you need to check every step, you don't trust the pipeline, and you should go back to W2 and re-examine the handoff contracts.

> **Inline Insight: Gates Are for Risks Agents Can't See, Not Risks They Might Make**
>
> A gate before the Reviewer because "the Coder might make a mistake" is the wrong shape. The Reviewer exists precisely to catch coder mistakes — that's an agent-level control, not a human-level control. A gate before the Deployer because "deployed code might corrupt the points ledger and we cannot rollback customer-visible state changes" is the right shape: the *consequence* is outside what any agent can see (it's business-state, not code-state).

---

### Concept 3: Cross-Agent State (Beads as State) (~5 min)

**When:** Stage B needs to know something that Stage A discovered. There is no shared memory, no global variable, no in-flight handshake. **All cross-agent state lives in beads, artifacts, or commits.**

**Primitive used:** bead descriptions, bead comments, and committed artifacts (work packages, ADRs, specs, reports).

**Fired Up Pizza example:** The Architect decides to use a separate `points_ledger` table (from L2). The Designer needs to know this to write the right spec. The Coder needs to know this to write the right schema. The Reviewer needs to know this to check the migration. How does the decision travel?

**Answer:** Through the committed ADR. The Designer's bead description says "Read `docs/adr/0001-loyalty-points-storage.md` before writing the spec." The ADR is state, the bead is the pointer to that state, and the orchestrator's job is to make sure the pointer is correct.

**Expressed in orchestrator.yaml:**

```yaml
pipeline:
  stages:
    - name: plan
      agent: planner
      produces: work-packages/*.md
      bead_template: |
        Feature request: {{feature_title}}
        {{feature_description}}
        Write the work package to work-packages/<slug>.md per your prompt.

    - name: architect
      agent: architect
      needs: [plan]
      produces: docs/adr/*.md
      bead_template: |
        Read the work package at {{plan.produced_path}}.
        Read CLAUDE.md for tailored ADR baselines.
        Produce an ADR at docs/adr/NNNN-<slug>.md.

    - name: design
      agent: designer
      needs: [architect]
      produces: design/*-spec.md
      bead_template: |
        Read {{plan.produced_path}} and {{architect.produced_path}}.
        Produce a spec at design/<slug>-spec.md per your prompt.

    - name: code
      agent: coder
      needs: [design]
      produces: src/**
      bead_template: |
        Read {{design.produced_path}}, {{architect.produced_path}},
        and {{plan.produced_path}}.
        Implement per the spec. Do not make architectural decisions.
```

**What's happening here:** `bead_template` is a parameterized description for the bead the orchestrator creates when dispatching a stage. `{{plan.produced_path}}` is interpolated from the upstream stage's produced artifact. This is how state flows: the upstream stage produces a file, commits it, closes its bead; the orchestrator interpolates the file path into the downstream stage's bead description; the downstream agent reads the file.

**Why this matters:** There is no magic "context injection." The Designer does not have a memory of the ADR — it re-reads the file each time. This is by design. It means you can re-run any stage independently by re-creating its bead, and you can debug a failure by reading the bead description plus the artifact paths it points to. Nothing is hidden.

**The three kinds of cross-agent state:**

1. **Artifact state** — files committed to the repo (work packages, ADRs, specs, code, review reports). Durable; survives agent restarts. This is where 95% of your state should live.
2. **Bead state** — title, description, status, comments, `depends_on` relationships. Durable; managed by Gas City. Use this for *pointers to artifacts* and *stage metadata*, not for the artifacts themselves.
3. **Session state** — what's in the agent's tmux session while it's running. **Ephemeral.** Do not rely on it. When the session times out (`idle_timeout = "1h"`), it's gone.

If you find yourself wanting to pass something between agents that isn't a file or a bead field, stop. Either (a) make it a file, or (b) make it a bead comment. There is no third option.

> **Inline Insight: No Hidden Handoffs**
>
> Every state transition between agents should produce a file a human can open. If the Architect's decision only exists in the Designer's bead description, you've hidden a handoff — and when something goes wrong in week 6, you'll have no audit trail. This is why W2's handoff contracts specify *artifact paths*, not "the Designer will know about the decision." Your `orchestrator.yaml` should reference every handoff artifact by path, and if a stage has no artifact path, that stage is broken.

### Worked Example: Tracing State Through the Loyalty Points Pipeline

To make "beads as state" concrete, trace exactly how the Architect's storage decision travels from stage to stage in the Loyalty Points feature:

1. **Architect stage runs.** The Architect agent reads the work package, decides on `points_ledger` table (Option 2 from L2), writes `docs/adr/0001-loyalty-points-storage.md`, commits it, closes its bead.
2. **Orchestrator observes the close.** It reads the closed bead's `produced_path` field (set by the agent's Process step: "update the bead with the artifact path before closing").
3. **Orchestrator creates the Designer bead.** It interpolates `{{architect.produced_path}}` = `docs/adr/0001-loyalty-points-storage.md` into the `bead_template`, producing a description like: "Read `work-packages/loyalty-points-system.md` and `docs/adr/0001-loyalty-points-storage.md`. Produce a spec at `design/loyalty-points-spec.md`."
4. **Designer agent runs.** It opens both files (fresh — no memory of previous stages), reads the ADR, sees "decision: `points_ledger` table," writes a spec that conforms.
5. **Designer closes its bead**, setting `produced_path` = `design/loyalty-points-spec.md`.
6. **Orchestrator creates the Coder bead** with all three upstream paths. Coder reads all three, implements. And so on.

Notice what is **not** happening:

- There is no shared memory between the Architect and the Designer. They may run minutes or hours apart, in different tmux sessions.
- There is no orchestration-level "decision object" — the decision is the committed ADR file, full stop.
- There is no "pass arguments between agents." There are only bead descriptions, which point to files.

If the Designer's spec contradicts the ADR, the bug is in the Designer's prompt (doesn't read the ADR carefully enough) or in the Coder's prompt (doesn't follow the spec). It is never a "state transmission" bug, because there is no state transmission channel to break.

---

## Workshop Activity — Part 1: Draft Your orchestrator.yaml (~15 min)

Now you compose the three concepts into a single file.

### Step 1: Create the File

```bash
cd ~/path/to/your-repo
touch orchestrator.yaml
```

### Step 2: Write the Full Pipeline

Open `orchestrator.yaml` and write your six-stage pipeline. Work in three passes, adding one concept at a time so that each intermediate version is independently verifiable.

#### Pass A: Sequential chain only (no gates, no remediation)

Start with just the four design-and-build stages and confirm the structure parses:

```yaml
version: 1

pipeline:
  name: feature-pipeline
  trigger:
    bead_label: feature-request

  stages:
    - name: plan
      agent: planner
      produces: work-packages/*.md

    - name: architect
      agent: architect
      needs: [plan]
      produces: docs/adr/*.md

    - name: design
      agent: designer
      needs: [architect]
      produces: design/*-spec.md

    - name: code
      agent: coder
      needs: [design]
      produces: src/**
```

**What's happening here:** Four stages, each waiting on the previous. No remediation, no gates, no human intervention. Save the file and run `python3 -c "import yaml; yaml.safe_load(open('orchestrator.yaml'))"` to confirm it parses.

#### Pass B: Add review + remediation loop

Now append the review stage with its `on_reject` loop:

```yaml
    - name: review
      agent: reviewer
      needs: [code]
      produces: review-reports/*.md
      on_reject: code
      bead_template: |
        Review the code produced against {{design.produced_path}}.
        Write review-reports/<slug>.md with approve/request_changes verdict.
```

**What's happening here:** `on_reject: code` is the single most important field in the whole file. Without it, a Reviewer rejection dead-ends the pipeline — the feature is stuck, and a human has to manually re-sling the Coder. With it, the orchestrator automatically creates a new Coder bead with the review report attached, and the Coder iterates until the Reviewer approves (or until the retry budget is exhausted, which you'll wire up in L4).

#### Pass C: Add the human gate + gate metadata

Finally, append the deploy stage with its gate, and add the `gates:` block at the bottom:

```yaml
    - name: deploy
      agent: deployer
      needs: [review]
      gate: human
      approvers:
        - austin@actual.ai
      produces: release-gates/*.md

gates:
  - name: approve_deploy
    required_for: [deploy]
    approvers:
      - austin@actual.ai
    justification_doc: docs/gates/approve_deploy.md
```

**What's happening here:** The `gate: human` on the stage and the `gates:` entry at the bottom are redundant on purpose. The stage-level field tells the orchestrator *when* to pause; the top-level `gates:` entry is where approvers, escalation, and justification-doc references live centrally, so a reviewer can audit all gates by grepping the `gates:` block.

#### The complete file

Here is the full result — the target you should arrive at by the end of Pass C:

```yaml
# orchestrator.yaml — Fired Up Pizza factory coordination
# Generated in W3; refined in L4.

version: 1

pipeline:
  name: feature-pipeline
  trigger:
    bead_label: feature-request

  stages:
    - name: plan
      agent: planner
      produces: work-packages/*.md
      bead_template: |
        Feature request: {{feature_title}}
        {{feature_description}}
        Produce a work package at work-packages/<slug>.md per your prompt.

    - name: architect
      agent: architect
      needs: [plan]
      produces: docs/adr/*.md
      bead_template: |
        Read the work package at {{plan.produced_path}}.
        Read CLAUDE.md for tailored ADR baselines.
        Produce an ADR at docs/adr/NNNN-<slug>.md per MADR template.

    - name: design
      agent: designer
      needs: [architect]
      produces: design/*-spec.md
      bead_template: |
        Read {{plan.produced_path}} and {{architect.produced_path}}.
        Produce a spec at design/<slug>-spec.md per your prompt.

    - name: code
      agent: coder
      needs: [design]
      produces: src/**
      bead_template: |
        Read {{design.produced_path}} (primary),
        {{architect.produced_path}}, and {{plan.produced_path}}.
        Implement per the spec. Run lint, tests, build before committing.

    - name: review
      agent: reviewer
      needs: [code]
      produces: review-reports/*.md
      on_reject: code
      bead_template: |
        Review the code produced against {{design.produced_path}}.
        Write review-reports/<slug>.md with approve/request_changes verdict.

    - name: deploy
      agent: deployer
      needs: [review]
      gate: human
      approvers:
        - austin@actual.ai
      produces: release-gates/*.md
      bead_template: |
        Evaluate release readiness against {{review.produced_path}}.
        Produce release-gates/<slug>.md.
        Human approval required before production deploy.

gates:
  - name: approve_deploy
    required_for: [deploy]
    approvers:
      - austin@actual.ai
    justification_doc: docs/gates/approve_deploy.md
```

**What's happening here:** Read the file top to bottom:

- `version: 1` is the schema version. Keep it at 1 for the duration of the curriculum.
- `pipeline.name` is the identifier the orchestrator uses when logging. One pipeline per file is the simplest shape; you can have multiple (e.g., a `hotfix-pipeline`) but don't in W3.
- `trigger.bead_label` is the label on a bead that kicks the pipeline off. When you create a bead with `bd create "..." --label feature-request`, the orchestrator picks it up and starts at the `plan` stage.
- Each `stage` has: a name, an agent (matches the `[[agent]].name` in a pack's `pack.toml`), a `needs` list (compiles to `--depends-on`), a `produces` glob, an optional `gate`, and a `bead_template`.
- `on_reject: code` in the `review` stage is the **remediation loop**: if the Reviewer's verdict is `request_changes`, the orchestrator opens a new `code` bead pointing back to the same feature. This is how the pipeline self-corrects without human intervention.
- `gates:` at the bottom declares approval metadata that the `gate: human` stages reference. Keep a justification doc per gate — empty justification = theatrical gate.

### Step 3: Write the Gate Justification Doc

Any stage with `gate: human` needs a justification committed alongside. Create `docs/gates/approve_deploy.md`:

```markdown
# Gate: approve_deploy

## Stage
Between `review` and `deploy` in the feature-pipeline.

## Risk Being Mitigated
A schema migration for the points_ledger table is irreversible without
customer-visible data loss. The Reviewer can verify the code compiles
and tests pass, but cannot verify that production database state
matches staging — a human must inspect the release-gate document
(which includes the migration plan and rollback strategy) before
the Deployer is allowed to run.

## Evidence This Gate Is Necessary
- Dropping a points_ledger row in production loses real customer points,
  which is indistinguishable from theft from the customer's perspective.
- SQLite does not support `DROP COLUMN` without a table rebuild, so a
  failed migration requires restore-from-backup, not simple rollback.
- The Reviewer's acceptance criteria do not include database state
  verification — that is explicitly out of scope for code review.

## When This Gate Should Be Removed
When ALL of the following are true:
1. Automated rollback is in place (daily backups + tested restore path)
2. Staging environment mirrors production schema exactly and runs the
   same migration first
3. The points_ledger ledger is append-only (no destructive writes),
   making migrations additive rather than destructive
4. Test coverage on the migration path exceeds 90%

## Approvers
- austin@actual.ai (primary)
- team-lead@actual.ai (fallback, if primary is unavailable >24h)
```

**What's happening here:** This document is the *receipt* for the gate. In six months, when a new engineer asks "why is there a manual approval step here, it slows us down," this doc is the answer. The **removal condition** is the most important section — it prevents the gate from becoming permanent infrastructure.

### Step 4: Validate Your YAML Parses

Before committing, confirm the file is syntactically valid:

```bash
python3 -c "import yaml; yaml.safe_load(open('orchestrator.yaml'))" && echo OK
```

You should see `OK`. If you see a traceback, the YAML is malformed — usually an indentation mismatch under `stages:` or a missing colon after a key. Fix the line number the traceback points at.

Also do a quick structural check:

```bash
grep -c "^    - name:" orchestrator.yaml   # should print 6
grep -c "gate: human" orchestrator.yaml    # should print >= 1
grep -c "on_reject:" orchestrator.yaml     # should print >= 1
```

If any of these counts are zero, re-read the example above — you've likely dropped a whole section.

### Step 5: Commit

```bash
cd ~/path/to/your-repo
git checkout -b w3-orchestrator
git add orchestrator.yaml docs/gates/approve_deploy.md
git commit -m "feat(orchestrator): draft feature-pipeline with deploy gate"
```

**Why commit now?** The `orchestrator.yaml` is the source of truth for coordination. In L4 you'll apply it (`gc orchestrate apply`) and the actual runtime behavior will be compared against this file. Committing it now means the diff of *intended* vs *actual* coordination is always in the git log.

### Per-Stage Design Checklist

Before you finalize the YAML, walk each stage against this checklist. It's the same rubric you'll apply in L4 when stages fail and you need to diagnose why.

| Stage | Agent reads | Agent writes | Gate? | Remediation target |
|---|---|---|---|---|
| plan | bead description, `docs/PROJECT_MANIFEST.md` | `work-packages/<slug>.md` | No | (none — first stage; rejection means re-draft feature request and start over) |
| architect | work package, `CLAUDE.md`, existing ADRs | `docs/adr/NNNN-<slug>.md` | No | (none — if ADR is weak, re-sling the Architect with a stronger bead description) |
| design | work package, ADR, `CLAUDE.md` | `design/<slug>-spec.md` | No | (none — if spec is weak, re-sling the Designer) |
| code | design spec, ADR, work package | `src/**`, tests | No | (covered by review's `on_reject`) |
| review | code, tests, design spec | `review-reports/<slug>.md` | No | `code` (via `on_reject`) |
| deploy | review report | `release-gates/<slug>.md`, tagged release | **Human** (`approve_deploy`) | (none — if deploy fails, investigate manually; rollback is outside the orchestrator) |

If your row doesn't match this pattern for one of these stages, you've diverged — that's fine if you have a reason (write it in `DECISIONS.md`), but a divergence without a reason is usually a mistake.

---

## Workshop Activity — Part 2: Self-Review (~10 min)

Re-read your `orchestrator.yaml` and answer three questions. Write the answers in a scratch file or your `DECISIONS.md` — they will inform L4.

### Question 1: Can any stage start before its declared dependencies finish?

Trace every `needs:` by hand. For each stage, list the files its `bead_template` references and confirm every one of those files is produced by a stage in its `needs` list (or by a prerequisite of a stage in its `needs` list).

For the Loyalty Points example:

| Stage | References | Comes from | Declared in `needs`? |
|---|---|---|---|
| plan | (none — trigger bead) | — | N/A |
| architect | `{{plan.produced_path}}`, `CLAUDE.md` | plan stage, pre-existing | Yes |
| design | `{{plan.produced_path}}`, `{{architect.produced_path}}` | plan (transitive), architect | Yes (architect transitively covers plan) |
| code | `{{design.produced_path}}`, `{{architect.produced_path}}`, `{{plan.produced_path}}` | all three upstream | Yes (design transitively covers architect and plan) |
| review | code produced artifact, `{{design.produced_path}}` | code, design | Yes (code transitively covers design) |
| deploy | `{{review.produced_path}}` | review | Yes |

If any row has "No" in the last column, your dependency graph is broken — fix the `needs:` entry before moving on.

### Question 2: Is every human gate justified?

Apply the "while I was asleep" test to each gate. If two of your five gates fail the test, they're theatrical, not protective — cut them.

In the Loyalty Points example there is exactly one gate (`approve_deploy`). Confirm:
- Worst-case failure: unreviewed migration corrupts points data → not acceptable
- Agent-level mitigation possible? No — agents cannot verify production DB state
- Removal condition specified? Yes — see `docs/gates/approve_deploy.md`

### Question 3: What happens if Stage B crashes mid-run?

The orchestrator needs **at least one** of:
- A named retry policy (e.g., "if the agent exits non-zero, re-sling the bead up to 3 times")
- A state-reset step (e.g., "if the code stage fails, delete the partial artifact and re-create the bead")
- An escalation rule (e.g., "if retries exhaust, change the bead assignee to the human operator and stop the pipeline")

For W3, you only need to *identify* which of these you'll use. You'll implement it in L4. Write your choice in the `DECISIONS.md` scratch — e.g., "stage failures: re-sling up to 2 times; on the 3rd failure, assign the bead to me for manual review."

If any question yields "I hadn't thought about that," revise the config before moving on to L4.

### Question 4 (bonus, no points): Does every stage's output have exactly one downstream consumer?

This is a smell-check, not a hard rule. For each stage, ask: "which downstream stages read this artifact?" If a stage's artifact is read by zero downstream stages, the stage is dead weight — either the downstream stages need to add it to their `bead_template`, or the stage itself is unnecessary. If a stage's artifact is read by *many* downstream stages (more than two), you've created an implicit dependency fan-out that makes the pipeline brittle — changes to that artifact's format will ripple everywhere.

In the Loyalty Points example:

| Artifact | Read by | Smell |
|---|---|---|
| `work-packages/loyalty-points-system.md` | architect, designer (transitive via ADR), coder (transitive via spec) | Fine — direct readers are ~2, transitive reads are via intermediary artifacts |
| `docs/adr/0001-loyalty-points-storage.md` | designer, coder | Fine |
| `design/loyalty-points-spec.md` | coder, reviewer | Fine |
| `review-reports/<slug>.md` | deployer, (and the `on_reject` loop back to coder) | Fine |
| `release-gates/<slug>.md` | nobody downstream (end of pipeline) | Fine — terminal artifacts are expected |

If your project's answer has a row with "nobody, but it's not terminal," cut that stage.

---

## Common Issues & Solutions

| Issue | Symptom | Fix |
|---|---|---|
| **Too many human gates** | Every stage requires approval; the factory can't run autonomously overnight | Apply the "while I was asleep" test. Cut any gate that doesn't answer "unacceptable" to the worst case. Aim for one gate, max two. |
| **Missing dependency** | Coder starts before Designer finishes, produces code that doesn't match the spec | Explicit `needs:` in `orchestrator.yaml`. Trace Question 1 above. Check that every `{{upstream.produced_path}}` reference has a matching `needs:` entry. |
| **No join point after a fan-out** | A downstream stage starts before all parallel stages finish, loses context from one of them | W3 intentionally keeps the pipeline linear. If you added parallel stages anyway, make the downstream stage's `needs:` list all parallel siblings, not just one. |
| **Gate approver is a single person** | Pipeline blocks indefinitely when the approver is on vacation | Add a fallback approver to the `approvers:` list in `gates:`. Document the escalation path in the justification doc. |
| **`bead_template` references a file the upstream stage doesn't produce** | Downstream agent reads a missing file, hallucinates its contents | Open each `bead_template`, list every path reference, cross-check against `produces:` globs upstream. Fix by adjusting either the template or the upstream produces. |
| **No remediation loop on the review stage** | Reviewer rejects; the pipeline halts; you have to manually re-sling the Coder | Add `on_reject: code` to the `review` stage. The orchestrator auto-creates a new `code` bead with the review report attached. |
| **Gate justification doc is empty / "just to be safe"** | Six months later, nobody remembers why this gate exists; it gets ignored and approved reflexively | Write the removal condition before you add the gate. If you can't write a removal condition, the gate is theater — remove it. |
| **Orchestrator references an agent that isn't installed** | `gc orchestrate apply` errors with "unknown agent: reviewer" | Check `gc status` lists the agent. If not, you haven't installed that pack yet (Reviewer and Deployer come in L4). That's fine for W3 — the orchestrator is a design artifact at this point, not yet applied. |
| **`produces:` glob is too loose** | Multiple files match; the orchestrator can't decide which is "the" artifact | Make the glob specific (e.g., `work-packages/loyalty-points-system.md` instead of `work-packages/*.md`) when you know the slug, or have the agent's prompt commit exactly one file per sling. |
| **Gate approver = person who wrote the code** | You approve your own changes; the gate adds no safety | In the solo workshop case this is unavoidable — note it in the justification doc as "solo gate: approver and code author are the same for now; upgrade to two-approver when team grows." |
| **`bead_template` interpolates a variable the orchestrator doesn't know** | Bead gets created with literal `{{foo.produced_path}}` in the description; agent sees the placeholder and may treat it as literal text | Valid variables are: `{{feature_title}}`, `{{feature_description}}`, and `{{<stage_name>.produced_path}}` where `<stage_name>` is a stage declared earlier in the pipeline. Nothing else is interpolated. Typos here fail silently at apply time. |
| **Pipeline kicks off on every bead, including stale ones** | Old closed feature requests get re-run weekly | Constrain `trigger.bead_label` narrowly (e.g., `factory-intake` rather than a broad `bug`). Also ensure your issue-tracker sync order only labels *new* items, not historical ones — check the sync order config. |
| **`needs:` list references a stage that doesn't exist** | `gc orchestrate apply` errors with "unknown stage: desgin" (typo of `design`) | The orchestrator validates stage names at apply time. Fix the typo. Prefer copy/paste over retyping stage names. |
| **Remediation loop creates an infinite cycle** | `on_reject: code` → Coder fails → Reviewer rejects again → Coder again, forever | Add a retry budget in the `on_reject` target. Easiest pattern: once a stage's bead has been re-created N times for the same feature, stop and assign to a human. You'll implement this in L4; in W3 just note which stage has the loop so it's easy to find. |
| **YAML treats `no` as boolean false** | A stage named `no-op` or a bead_template containing `no` on its own line becomes `false`, silently | Always quote stage names and free-form strings. Use `name: "plan"` with quotes if you want to be defensive. The `|` block-scalar form (used for `bead_template:`) avoids this for multi-line strings. |

---

## Connection to Gas City

Your `orchestrator.yaml` isn't aspirational — every field in it compiles to Gas City primitives that ship today:

| Orchestrator field | Gas City primitive | File or command |
|---|---|---|
| `agent: planner` | `[[agent]]` block in a pack | [`packs/planner/pack.toml`](../../../packs/planner/pack.toml) — the `name = "planner"` line |
| `needs: [plan]` | `bd create --depends-on` | Applied at runtime by the orchestrator when it creates the stage's bead |
| `gate: human` + `approvers:` | `bd create --requires-approval --assignee` | Applied at runtime; the bead enters `needs-approval` state |
| `on_reject: code` | Auto-creation of a new bead for the named stage when a verdict bead closes with `request_changes` | Applied at runtime by the orchestrator loop |
| `trigger.bead_label` | Label filter on incoming beads (e.g., from `bd jira sync`) | Matches the label set by issue-tracker sync orders |
| `bead_template` | The `--description` passed to `bd create` | Interpolated per-stage when the upstream bead closes |
| `produces: *.md` | Artifact verification after the bead closes | The orchestrator checks `git log` for files matching the glob before marking the stage complete |

**Where to look in the repo:**

- [`packs/planner/pack.toml`](../../../packs/planner/pack.toml), [`packs/architect/pack.toml`](../../../packs/architect/pack.toml), [`packs/designer/pack.toml`](../../../packs/designer/pack.toml), [`packs/builder/pack.toml`](../../../packs/builder/pack.toml), [`packs/reviewer/pack.toml`](../../../packs/reviewer/pack.toml), [`packs/release-gate/pack.toml`](../../../packs/release-gate/pack.toml) — each defines one of the six agents referenced in your pipeline. Notice the `provider = "claude"` convention on `[[agent]]` blocks; other providers are supported, and the orchestrator is runner-agnostic.
- [`packs/workshop/orders/sync-jira/order.toml`](../../../packs/workshop/orders/sync-jira/order.toml) — the shape of a declarative periodic trigger. Your `trigger.bead_label` works the same way: it watches for beads and kicks off the pipeline.
- [`packs/workshop/orders/sync-linear/`](../../../packs/workshop/orders/sync-linear/), [`packs/workshop/orders/sync-github/`](../../../packs/workshop/orders/sync-github/), [`packs/workshop/orders/sync-gitlab/`](../../../packs/workshop/orders/sync-gitlab/) — same pattern, different issue trackers. Whichever tracker you use, feature requests enter the factory via one of these orders.
- [`packs/workshop/pack.toml`](../../../packs/workshop/pack.toml) — the workshop pack's doctor checks. `gc doctor` runs these before you start; a broken issue-tracker connection is caught here, not at orchestration time.

**The declarative form is the source of truth.** Commands like `gc orchestrate apply` just *apply* the YAML — they don't add behavior that isn't in the file. If a stage doesn't run, the YAML is wrong (or missing).

> **Inline Insight: Config Discipline Extends to Orchestration**
>
> L1 taught you to update `CLAUDE.md` instead of re-prompting. L2 taught you to update the pack's prompt file instead of editing the artifact directly. W3's rule is the same shape: **if the factory's coordination is wrong, update `orchestrator.yaml` and re-apply. Never hand-edit bead states or hand-sling agents out of order.** The moment you start manually coordinating, you've stopped running a factory and started running a workshop by hand — which defeats the whole point.

---

## Recommended Prompts

Use these with Claude Code if you want to accelerate the design work. They're not required — the manual path (read the concepts, write the YAML, self-review) works too.

### When Designing Coordination

```
I'm building a software factory with 6 agents in Gas City: Planner,
Architect, Designer, Coder, Reviewer, Deployer.

My feature: [paste feature description]

Using the three coordination concepts (sequential chaining, human
gates, cross-agent state via beads/artifacts), help me determine:

1. Which stages must run sequentially (Stage B reads Stage A's artifact)
2. Where human gates belong (apply the "while I was asleep" test)
3. What artifact flows through each handoff (be specific: filenames)

For each human gate, write a one-sentence worst-case scenario that
justifies the gate and a one-sentence condition under which the gate
could be safely removed.
```

### When Writing orchestrator.yaml

```
I need an orchestrator.yaml for Gas City.

My coordination decisions:
- Stages (in order): plan, architect, design, code, review, deploy
- Human gates: [list stages with gates, one per line]
- Remediation: review rejects loop back to [stage name]

Generate a complete orchestrator.yaml using Gas City's schema:
- pipeline.stages[] with name, agent, needs, produces, bead_template
- gates[] with name, required_for, approvers, justification_doc
- on_reject links where appropriate

Reference artifact paths like work-packages/<slug>.md, docs/adr/*.md,
design/*-spec.md, src/**, review-reports/*.md, release-gates/*.md.

Do not invent fields not used in the curriculum's examples.
```

---

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `orchestrator.yaml` exists in your repo root with all 6 stages
- [ ] Every stage has `agent`, `produces`, and (except `plan`) `needs`
- [ ] At least one stage has `gate: human` with matching `approvers`
- [ ] Every human gate has a justification doc at `docs/gates/<gate-name>.md` with a worst-case scenario AND a removal condition
- [ ] At least one stage has `on_reject:` pointing to a prior stage (the remediation loop)
- [ ] Self-review Question 1 (dependencies) traced by hand — no "No" rows
- [ ] Self-review Question 2 (gate justification) — every gate survives the "while I was asleep" test
- [ ] Self-review Question 3 (crash recovery) — named strategy written down
- [ ] `orchestrator.yaml` + justification doc(s) committed on branch `w3-orchestrator`

**W3 blocks L4.** L4 is where you install the Reviewer and Deployer packs and run `gc orchestrate apply orchestrator.yaml` against the factory you've been building. Without a committed `orchestrator.yaml`, L4's first step fails.

---

## Command Cheat Sheet

Every command you'd run during (or immediately after) this workshop:

```bash
# PART 0 — Read shipped primitives (no commands; just read files)
# - packs/workshop/orders/sync-jira/order.toml
# - packs/planner/pack.toml (and siblings)

# PART 1 — Draft orchestrator.yaml
cd ~/path/to/your-repo
git checkout -b w3-orchestrator
# (edit orchestrator.yaml — follow the Loyalty Points example)
# (edit docs/gates/approve_deploy.md — write the justification)

# Verify YAML parses (optional but recommended)
python3 -c "import yaml; yaml.safe_load(open('orchestrator.yaml'))" && echo OK

# Commit
git add orchestrator.yaml docs/gates/approve_deploy.md
git commit -m "feat(orchestrator): draft feature-pipeline with deploy gate"

# PART 2 — Self-review (no commands; trace the three questions by hand)

# Verify readiness for L4
ls orchestrator.yaml                                    # exists
ls docs/gates/                                          # has at least one justification doc
grep -c "^    - name:" orchestrator.yaml                # 6 stages
grep -c "gate: human" orchestrator.yaml                 # at least 1

# Push branch so L4 can resume from it
git push -u origin w3-orchestrator

# (Deferred until L4, for reference — do NOT run now)
# gc orchestrate apply orchestrator.yaml
# gc orchestrate status
```

---

## Quick Reference: What You Produced

| Component | File | What It Does |
|---|---|---|
| Orchestrator spec | `orchestrator.yaml` | Declarative coordination rules for the whole factory: sequential chain, human gate, remediation loop |
| Gate justification | `docs/gates/approve_deploy.md` | Receipt for the single human gate: worst-case risk + removal condition + approver list |
| Self-review notes | `DECISIONS.md` (W3 entry) | Answers to the three self-review questions, informing L4 |
| Branch | `w3-orchestrator` | Committed, pushed, ready for L4 to resume from |
| Stage count | 6 | plan, architect, design, code, review, deploy |
| Gate count | 1 (`approve_deploy`) | Before Deployer — schema migration irreversibility |
| Remediation loop count | 1 (`review` → `code` via `on_reject`) | Reviewer rejections auto-create new Coder bead |

---

## Next Steps

In **L4**, you'll:

- Install the Reviewer and Release-Gate (Deployer) packs (`packs/reviewer`, `packs/release-gate`) so all six agents referenced in your `orchestrator.yaml` are live
- Run `gc orchestrate apply orchestrator.yaml` to register the pipeline with Gas City
- Trigger the full pipeline end-to-end with a single `bd create --label feature-request` call — the orchestrator will chain Planner through Deployer automatically, pausing only at your human gate
- Observe the `on_reject` remediation loop in action when the Reviewer rejects a deliberately-broken implementation
- Implement the crash-recovery strategy you chose in Self-Review Question 3
- Compare the real runtime behavior against your `orchestrator.yaml` — any mismatch is either a config bug (update the YAML) or an orchestrator bug (open an issue upstream in Gas City)

**Bring to L4:** your committed `orchestrator.yaml`, the gate justification doc, and the three self-review answers. Between W3 and L4, revisit the "while I was asleep" test every time you add a stage or a gate — it's the single question that separates a real factory from a ceremony.

Also in **W4**, you'll take what you've built here and add *feedback rules* to close the loop: when a deployed feature underperforms or produces incidents, how does that signal make it back into the pipeline to change future coordination? W3's `on_reject` is the simplest feedback rule; W4 generalizes it.
