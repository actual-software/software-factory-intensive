# Coordination Channels · Fired Up Pizza

The W3 deliverable. Names which Gas City primitive carries each handoff between
the six factory agents, and the fallback used when the primary is unavailable.
Every later curriculum artifact (per-pack prompts, formula orders, mail flows)
honours the choices recorded here.

Agents in this factory coordinate through the named channels below. Every
handoff between stages maps to exactly one primary channel, with a fallback
named for when the primary is unavailable.

---

## Channel Inventory

| Channel | Where it lives | What it carries | Who reads it |
|---------|----------------|-----------------|--------------|
| **Tasks**         | `.beads/` + status labels (`needs-plan`, `needs-architecture`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`) | Work-in-progress handoffs; the status transition *is* the handoff | Every agent (via `bd ready --label=<label>`) |
| **Mail**          | `gc mail inbox <agent>`                  | Durable async notes — heads-ups, priority shifts, change-of-direction context | Mayor (human inbox); Reviewer ↔ Coder context exchanges |
| **Orders**        | `packs/actual/*/formulas/orders/*.toml`  | Condition-gated wakes (status labels) and cooldown-gated sweeps (improver, ADR re-index) | Supervisor (the `gc` daemon) |
| **Nudge**         | `gc nudge`, `gc session nudge`           | Missed-wake recovery; targeted "check your inbox" pokes | Supervisor (sweep) and humans (targeted) |
| **Session attach**| `gc session attach <id>`                 | Human steers one agent's live tmux for debugging or unblocking | Humans only |

---

## Preferences by Handoff

Which channel carries each handoff in this factory, and what it degrades to
if the primary is unavailable. Reasons cite the trade-off (persistence ×
timing × addressing) that drove the choice.

| Handoff | Primary channel | Fallback | Why |
|---------|-----------------|----------|-----|
| Planner → Architect          | Tasks (`needs-architecture` label) | `gc sling` to architect pool | Decision exists as a work unit; status transition is the cleanest handoff and leaves an audit trail on the bead |
| Planner → Designer           | Tasks (`needs-design` label) | `gc sling` to designer pool | Same shape as Planner → Architect; the work unit is a child bead the Planner already created |
| Architect → Coder            | Tasks (`ready-to-build` label) | `gc sling` to builder pool | The ADR is referenced from the bead, so the label flip carries enough context |
| Designer → Coder             | Tasks (`ready-to-build` label) | `gc sling` to builder pool | The spec path is in the bead notes; flipping the label is enough to wake the Coder via its `condition` order |
| Coder → Reviewer             | Tasks (`needs-review` label) | `gc sling` to reviewer pool | Reviewer's `reviewer-intake` order watches `needs-review`; the label *is* the wake |
| Reviewer → Coder (REQUEST_CHANGES) | Tasks (`ready-to-build` label + bead note pointing to review report) | Mail to `<rig>/builder` | Looping back through the same task preserves continuity; mail is the fallback when the bead's note field is at its size limit |
| Reviewer → Deployer          | Tasks (`ready-to-ship` label) | `gc sling` to release-gate pool | Deployer's `release-gate-intake` order watches `ready-to-ship`; deterministic handoff |
| Deployer → Mayor (deploy ready) | Mail to `mayor`                      | Session attach for a human verification | Mayor is a human — mail is the right durable, asynchronous channel; attach is reserved for "right now" steering |
| Improver → All stages (loop) | Mail (subject `factory-improvement: <signal>`) to the targeted agent | A `feedback-loops/` rule promoted to the agent's prompt on next iteration | The improver's role is suggestion, not directive; mail keeps the recipient in control of when to act |
| Any stage → Mayor (blocked)  | Mail to `mayor` with `subject: blocked`  | Cron'd `gc nudge mayor` after 6h | Blocks need durable persistence; nudges are the safety net if mail goes unread |

---

## Wired Configuration Changes (W3 Step 3)

These are the actual edits made to the shipped factory to honour the
preferences above. Each is reproducible from the file paths shown.

### Reviewer → Coder loop-back uses a sharper condition gate

`packs/actual/builder/formulas/orders/builder-rework/order.toml` was tightened
so the Coder only wakes on a `ready-to-build` task that **also** has a
`previously-reviewed` bead label, distinguishing first-pass builds from
rework loops:

```toml
[order]
description = "Wake the builder for review-driven rework cycles"
formula = "mol-rework"
gate = "condition"
check = "gc bd --rig fup-project list --label=ready-to-build,previously-reviewed --status=open --no-assignee --json 2>/dev/null | jq -e 'length > 0' > /dev/null 2>&1"
pool = "builder"
```

### Improver harvests review reports on a 6-hour cooldown

`packs/actual/improver/formulas/orders/improver-cooldown/order.toml`
shortened from a 24h cooldown to 6h so feedback rules surface within a
single working day rather than the next:

```toml
[order]
description = "Run the feedback harvest every 6 hours"
formula = "mol-feedback-harvest"
gate = "cooldown"
interval = "6h"
pool = "improver"
```

### Mail subject convention

A subject prefix convention was added to the Reviewer and Improver prompts so
that mail recipients can filter by intent:

- `review-followup: <slug>` — Reviewer asking the Coder for a follow-up
- `factory-improvement: <signal>` — Improver suggesting a config change
- `blocked: <reason>` — Any agent flagging a hard block to Mayor

---

## Failure-Mode Sanity Checks

Each preference above was checked against the three failure modes in W3 Part 4:

1. **Conflicting information across channels.** A task in `ready-to-ship` is
   canonical. If a follow-up mail says "actually still blocked", the task
   wins until its label is moved back. The Reviewer prompt is pinned to this
   rule under `## Constraints`.
2. **Timing that stalls or thrashes.** The 6h improver cooldown was chosen
   because the average loop-back arc on Fired Up Pizza features is two days;
   any tighter and the improver would re-fire on the same un-acted signal.
3. **Runaway loops.** The Improver mails the Mayor (a human), never another
   agent — eliminating the prompt-mails-prompt cycle the W3 insight warns
   against.
