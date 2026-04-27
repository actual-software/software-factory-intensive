# Labeled Beads — Canonical Handoff Protocol

Labels on beads are the handoff mechanism that connects the six agents of the software factory for the purpose of this intensive curriculum. Instead of each agent writing files or notes and hoping the next agent reads them, each agent watches the bead queue for a label aimed at it, does its work, and re-labels the bead for the next agent.

If you are building agents in this workshop, **labels are the contract**. Your agents' prompts filter the queue by label; the participant's packs' order gates fire on labels; the reference project's factory walks a feature from "needs-plan" to "ready-to-ship" by flipping labels one at a time.

---

## The six canonical labels

Every software factory built in this curriculum uses these six labels. They map one-to-one to the six essential agents.

| Label                | Meaning                                                            | Who adds it                     | Who consumes it |
|----------------------|--------------------------------------------------------------------|---------------------------------|-----------------|
| `needs-architecture` | Work requires architectural decisions before planning can proceed  | Planner (on drift) or human     | Architect       |
| `needs-plan`         | Work requires breakdown into smaller, buildable pieces             | Architect or human              | Planner         |
| `needs-design`       | Work requires UI/UX or component design before implementation      | Planner (or Architect)          | Designer        |
| `ready-to-build`     | Specs complete; implementation can start                           | Designer (or Planner, on skip)  | Coder           |
| `needs-review`       | Implementation complete; awaiting code review                      | Coder                           | Reviewer        |
| `ready-to-ship`      | Review passed; deployment is unblocked                             | Reviewer                        | Deployer        |

### Per-label details

**`needs-architecture`** — The bead calls for an architectural decision (new guardrails, a trust boundary, a tech choice) that must be resolved before a plan can be written. Added by the Planner when it detects "drift" (the current plan would violate or extend existing rules), or by a human when kicking off a feature that genuinely needs new rules. Consumed by the Architect.

**`needs-plan`** — The bead is a high-level goal that needs to be decomposed into concrete, individually-shippable child beads. Added by the Architect after a system-design step, or by a human when filing a feature request. Consumed by the Planner, which produces a tree of child beads each labeled for the next stage.

**`needs-design`** — A planned bead that has user-facing behavior requiring UI/UX design (wireframes, component specs, accessibility review) before the Coder should touch it. Added by the Planner (or the Architect if the design decision is architecturally load-bearing). Consumed by the Designer.

**`ready-to-build`** — The bead's specs are complete. The acceptance criteria, the design, and the architectural rules are all in place. Usually added by the Designer after finishing a design, but the Planner can add it directly when no design work is needed (pure backend work, internal tooling, etc.). Consumed by the Coder.

**`needs-review`** — The Coder has committed an implementation and wants a human-style review before it ships. Added by the Coder when their implementation is done and tests pass locally. Consumed by the Reviewer, which either approves it (moves to `ready-to-ship`) or sends it back (moves to `ready-to-build` with review notes).

**`ready-to-ship`** — The Reviewer has approved the change. The bead is cleared to be deployed. Added by the Reviewer on a passing review. Consumed by the Deployer, which runs the release gate (CI, smoke tests, tag, rollback plan) and, on success, closes the bead.

---

## Example lifecycle

A participant files a new feature. Here is the bead's walk through the factory:

1. **Human creates the bead** with `bd create --title "Add pizza topping customization" --label needs-plan`.
2. **Planner** picks it up via `bd ready --label needs-plan`, reads the acceptance criteria, decides new architectural rules are needed (toppings affect pricing, which needs an authoritative pricing rule), and re-labels: `bd label remove <id> needs-plan` → `bd label add <id> needs-architecture`.
3. **Architect** picks it up via `bd ready --label needs-architecture`, writes an ADR under `docs/decisions/`, and re-labels back to `needs-plan`.
4. **Planner** picks it up again, this time succeeds, and writes a plan producing three child beads:
   - Child A (backend pricing endpoint): `ready-to-build`
   - Child B (UI topping picker): `needs-design`
   - Child C (data migration): `ready-to-build`
   The root bead gets `bd dep add` edges to the three children and is closed. Each child walks independently from here.
5. **Designer** picks up Child B via `bd ready --label needs-design`, writes a component spec under `docs/designs/`, and re-labels to `ready-to-build`.
6. **Coder** picks up Children A, B, C (as they become available) via `bd ready --label ready-to-build`, implements each, commits, and re-labels each to `needs-review`.
7. **Reviewer** picks each up via `bd ready --label needs-review`. Suppose Child A passes and Child B fails (missing accessibility consideration):
   - Child A: re-label to `ready-to-ship`.
   - Child B: re-label back to `ready-to-build` with review notes in the bead; the Coder will pick it up again, fix, re-submit.
8. **Deployer** picks up Child A via `bd ready --label ready-to-ship`, runs the release gate, tags the release, writes a rollback plan, and closes the bead.
9. Child B re-walks steps 6–8. Child C walks steps 6–8.

At no point does any agent write a durable spec markdown to coordinate with another agent. The bead carries the state; the label carries the routing.

---

## How participants and agents interact with labels

**As a participant** (human in the loop), you use the `bd label` family:

```bash
# Add a label to start or advance work
bd label add <bead-id> needs-plan
bd label add <bead-id> ready-to-build

# Remove a label (usually when transitioning)
bd label remove <bead-id> needs-review

# Check what labels a bead has
bd label list <bead-id>

# See all labels currently in use across the factory
bd label list-all
```

You can also set labels atomically at creation time:

```bash
bd create --title "Add checkout flow" --label needs-plan
```

**As an agent** (one of the six), your pack's prompt template filters the queue by the label aimed at your role:

```bash
# The planner pack's startup loop
bd ready --label needs-plan

# The coder pack's startup loop
bd ready --label ready-to-build

# Filter to your role AND additional criteria (e.g. unassigned)
bd ready --label needs-review --unassigned
```

`--label` is an AND filter — the bead must have every label you specify. `--label-any` is an OR filter — the bead matches if it has any of the labels.

---

## Edge cases

**Reviewer rejects a change.** The Reviewer moves the bead back to `ready-to-build` with review findings captured in the bead's notes. The Coder picks it up, sees the most recent notes, fixes, re-labels to `needs-review`. Labels regress; that is normal and part of the design.

**Multiple labels on one bead.** A bead can carry more than one label at once — for example `needs-design` AND `needs-architecture` if a feature needs both before it can proceed. Agents using `bd ready --label <X>` will see it whenever their label is on the bead. Convention is to remove the label you just satisfied so the bead only appears in queues that still have work to do.

**Skipping stages.** Not every feature needs every stage. A pure backend change might go `needs-plan` → `ready-to-build` directly (the Planner decides no design work is needed). An urgent hotfix might be created with `ready-to-build` already set, bypassing Planner and Architect — at the cost of skipping those gates, which is why it's a deliberate choice, not a default.

**No label matches an agent's filter.** If the Coder polls `bd ready --label ready-to-build` and finds nothing, it simply waits (`sleep 60` and re-polls). This is the normal idle state — not an error.

**Label propagation to child beads.** When a parent bead is decomposed, children inherit labels from the parent by default (see `bd create --no-inherit-labels` to disable). The Planner typically *sets* child labels explicitly (`--set-labels ready-to-build`) rather than relying on inheritance, since each child is aimed at a specific next stage.

---

## How this integrates with agent prompts

Each shipped pack under `packs/<agent>/` has a prompt template at `prompts/<agent>.md.tmpl`. The template's **Startup** section points the agent at its inbound label:

- `packs/planner/prompts/planner.md.tmpl` → `bd ready --label needs-plan`
- `packs/architect/prompts/architect.md.tmpl` → `bd ready --label needs-architecture`
- `packs/designer/prompts/designer.md.tmpl` → `bd ready --label needs-design`
- `packs/coder/prompts/coder.md.tmpl` → `bd ready --label ready-to-build`
- `packs/reviewer/prompts/reviewer.md.tmpl` → `bd ready --label needs-review`
- `packs/deployer/prompts/deployer.md.tmpl` → `bd ready --label ready-to-ship`

The template's **Handoff** section names the outbound label the agent sets when it is done. Together, these two sections are the full contract between an agent and the rest of the factory — there is nothing else to coordinate.

When you customize a pack in a lab (L2, L3, L4), you are editing that pack's prompt template and (usually) its formula. The labels stay the same: you are changing *how* the agent does its work, not *where* its work comes from or where it sends it next. Changing labels means changing the factory's topology, which is a bigger surgery — do not do it inside a single agent's pack.

---

## Why this matters for Config Over Prompting

The **Config Over Prompting** discipline (see the top-level `README.md`) tells you to fix agent behavior by editing config, not by typing corrections into a chat. Labels are the most important config surface in the entire factory:

- If your Coder is running at the wrong time, you do not tell it "wait for the Reviewer" in a chat. You check that its inbound label is `ready-to-build` and that the Reviewer sets `ready-to-build` on a rejected review (not some ad-hoc tag).
- If your factory stalls on a feature, you do not prompt the stuck agent. You look at the bead's labels, find the label no agent is consuming, and fix the config gap.
- If you want to add a new agent, you do not extend an existing agent's prompt. You add the agent's pack with its own inbound + outbound labels, update the routing docs, and let the existing agents ignore the new one.

Labels turn "what should this agent do?" into a declarative, inspectable, testable config choice. That is the whole point.