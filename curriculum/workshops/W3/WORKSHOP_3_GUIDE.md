# W3 · Architect Multi-Agent Coordination

> **Goal:**
Learn the distinct coordination channels a software factory uses to move information between specialists — mail, work items, files, and external services — and demonstrate your understanding by extending your factory with a new coordination channel adapted to your software project.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | Workshop |
| **Deliverable** | Your six-agent software factory extended with at least one new coordination channel, adapted to your project and documented alongside the channels already in use |

## Overview

A software factory is more than a set of specialists reading the same manifest. The specialists have to **coordinate** — announce that work is ready, pass artifacts, wait on each other, react to events that happen outside the factory's own walls. How that coordination flows is what decides whether the factory behaves like a pipeline or like six chatbots working in parallel.

W3 steps back from single-agent design and examines the four coordination channels a factory uses:

1. **Mail** — direct, point-to-point notifications between specialists (e.g. "the plan is ready")
2. **Work items** — a shared task store with labels/statuses that specialists read, claim, and update (the factory's assembly line)
3. **Files** — artifacts on disk that carry the actual content of a handoff (work packages, ADRs, specs, diffs)
4. **External services** — systems outside the factory that emit events into it or receive events from it (issue trackers, CI, chat, observability)

Through this workshop you will:
- Read each channel's role and when it's the right choice
- Audit which channels your current factory already uses and where
- Design and install one *new* coordination channel in your factory that your project actually benefits from
- Document the new channel alongside the existing ones so L2–L4 can extend it

> **Fired Up Pizza reference:** The reference factory exercises all four channels in small, concrete ways — mail handoffs between stages, labelled work items that drive wake-ups, files as the artifact substrate, and (optionally) external tools like Linear/Jira via MCP. Skim [`reference-project/fired-up-pizza/orchestrator.yaml`](../../../reference-project/fired-up-pizza/orchestrator.yaml) and the [factory-wiring doc](../../../reference-project/fired-up-pizza/docs/factory-wiring.md) if you want a concrete starting point — but do not copy its channel choices; your project's needs are different.

## The Four Coordination Channels

```
                ┌──────────────────────────┐
                │     Feature Request      │
                └────────────┬─────────────┘
                             │
                             ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │   mail ─────────▶   point-to-point notify                    │
  │                     "you're up"                              │
  │                                                              │
  │   work items ───▶   shared queue + status                    │
  │                     "this ticket is ready"                   │
  │                                                              │
  │   files ────────▶   durable artifacts                        │
  │                     "read my work package"                   │
  │                                                              │
  │   external ─────▶   bridges to non-factory systems           │
  │                     "Linear issue labelled 'factory-ready'"  │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
                             │
                             ▼
                       Functional Software
```

Every hand-off in a factory uses *at least one* channel, often two or more combined (e.g. a work item whose body references a file and that fires a mail notification on transition). Your job in this workshop is to know which channel carries which responsibility and to add one new one.

## Part 1: Install the W3 workspace (5 min)

> **Goal:** Stand up the W3 scratch workspace and carry forward the L1 factory so the channel work you do here targets your real project.

### Step 1: Install W3

```bash
# In your agent session, run:
/factory-activity-agent install W3
```

This scaffolds `~/Projects/factory/workshop_w3/w3-project/` and `~/Projects/factory/workshop_w3/w3-gc-factory/`.

### Step 2: Confirm prior artifacts were carried forward

The install step above automatically copies your L1 project's `docs/PROJECT_MANIFEST.md` and `docs/factory-pipeline.md` into the W3 workspace. Verify they arrived:

```bash
ls ~/Projects/factory/workshop_w3/w3-project/docs/
```

You should see both files. If you haven't installed L1 yet, the carry-forward is skipped silently — install L1 first if you want to work against your real project rather than an empty workspace.

### Step 3: Start the workshop's design doc

Create `docs/coordination-channels.md` in the W3 workspace. You'll fill it as you go — it's the deliverable of this workshop.

```bash
touch ~/Projects/factory/workshop_w3/w3-project/docs/coordination-channels.md
```

## Part 2: Read Each Coordination Channel (15 min)

> **Goal:** Understand, for each channel, what it's good at, where it breaks down, and what concrete mechanism implements it in your factory.

For each channel below, the questions you care about are the same:

- **What does it carry?** — the shape of the payload
- **When is it the right choice?** — the trade-off that makes it preferable to the others
- **How does it show up today?** — the framework-specific tool or file that implements it

### Channel 1: Mail

**What it carries:** Short, one-way notifications from one specialist to another. "The plan is ready, you're up." "Review request." "Deploy approved."

**When it's right:** You need to *wake* another specialist on a specific event but the event itself is not the payload. The real content lives elsewhere (a work item, a file); mail is the nudge that triggers the reader to go look.

**When it's wrong:** You're trying to carry state or history through the mail thread. Mail is fire-and-forget — if it's the *only* channel carrying a handoff, a missed mail equals a missed handoff.

**How it shows up in your factory (when running Gas City):** `gc mail send <agent> "<one-line notification>"` from the source stage, `gc mail inbox` from the receiving stage. The Planner's shipped prompt uses it; look at [`packs/planner/prompts/planner.md.tmpl`](../../../packs/planner/prompts/planner.md.tmpl) for an in-place example.

### Channel 2: Work Items

**What it carries:** The canonical record of "a piece of work that exists in the factory" — title, status, labels, assignee, dependencies, notes. Specialists read and write this record as they progress.

**When it's right:** The handoff is between *stages*, not specific agents, and the next specialist should only pick up when the item reaches a known state (e.g. a label like `needs-review`). Labels are the coordination signal; polling is the pickup mechanism.

**When it's wrong:** The payload is longer than a title + a couple of notes, or the handoff is a one-off notification that doesn't need a durable record.

**How it shows up in your factory (when running Gas City):** `bd` (beads) is the work-item store. Specialists create items with `bd create --label <next-stage-label>`, transition them with `bd update <id> --label`, and close them with `bd close <id>`. The shipped factory uses six canonical labels (`needs-plan`, `needs-architecture`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`) as its assembly line — see [`docs/labeled-beads.md`](../../../docs/labeled-beads.md) for the vocabulary.

### Channel 3: Files

**What it carries:** The actual content of a handoff — the work package, the ADR, the component spec, the diff, the review report, the release-gate decision. Files are the *substrate* of every meaningful hand-off.

**When it's right:** The content needs to outlive the hand-off (auditability), or needs to be read by *multiple* subsequent stages (e.g. the work package is read by every stage after the Planner), or a human will need to review it later.

**When it's wrong:** Content that's ephemeral (a transient notification, a session heartbeat). Writing a file for those is noise — use mail or a status update on a work item instead.

**How it shows up in your factory:** Plain files under your project workspace — `work-packages/<slug>.md`, `docs/adr/NNNN-<slug>.md`, `design/<slug>-spec.md`, `review-reports/<slug>-review.md`, `release-gates/<slug>-gate.md`. Each specialist's prompt names the exact path it reads and writes; the handoff contract is "the next specialist will find its input at this path."

### Channel 4: External Services

**What it carries:** Events crossing the boundary between your factory and the rest of your world — tickets from an issue tracker, CI results from a build system, alerts from observability, messages in a team chat.

**When it's right:** The source of truth already lives elsewhere and you don't want a second copy. Feature backlog in Linear? Read it directly. Build status in GitHub Actions? Let the factory poll or receive a webhook. An alert in Grafana? Convert it into a work item on arrival.

**When it's wrong:** You're using it as a general dumping ground because you haven't decided which internal channel should own a handoff. External services are for genuinely external events, not for avoiding the internal channels.

**How it shows up in your factory:** MCP servers (Linear MCP, GitHub MCP, Atlassian MCP, Grafana MCP, etc.) attached to specific stages, plus inbound bridges that convert external events into internal work items (e.g. a cron that turns a labelled Linear issue into a `needs-plan` bead). Your W2 `factory-pipeline.md` already listed the external services your stages need; W3 is where you decide which ones become active coordination channels.

### Record what you already have

In `docs/coordination-channels.md`, add a section:

```markdown
## Current Channel Inventory

| Channel | Where it's in use today | Example |
|---------|--------------------------|---------|
| Mail    |                          |         |
| Work items |                       |         |
| Files   |                          |         |
| External |                         |         |
```

Fill it from what you observed in W1 and what you wired in L1. This is your baseline — Part 3 extends it.

## Part 3: Pick and Design a New Coordination Channel (15 min)

> **Goal:** Identify one channel your project actually needs, decide where it enters the pipeline, and design its contract with the stages it will interact with.

### Step 1: Surface the candidate channels

Look at your `factory-pipeline.md` gap list (from W2) and your L1 Planner input wiring. Candidates typically fall into one of these shapes:

- **A missing external source** — a tool your team uses that the factory doesn't read yet (e.g. a `#product-requests` Slack channel, a Notion spec page, an Intercom conversation).
- **A missing internal notification** — two stages that silently depend on each other but have no mail today (e.g. Reviewer → Deployer with no "all green" notification).
- **A missing emission outward** — the factory produces something a team would benefit from seeing, but no external service receives it (e.g. release-gate results not posted back to the PR).
- **A missing file artifact** — a stage produces knowledge only in work-item notes that should live in a file instead (e.g. Reviewer findings that should become a historical review report).

Pick one that would measurably help your team within a week.

### Step 2: Answer the four design questions

In `docs/coordination-channels.md`, add:

```markdown
## New Channel: <name>

**Type:** mail | work items | files | external service

**Producer stage:** <which specialist emits on this channel>
**Consumer stage(s):** <which specialist(s) read it>

**Payload shape:** <what's in the message / item / file / event>

**Trigger:** <when is a message/event produced?>
**Pickup:** <how does the consumer know there's something to read?>

**Failure mode:** <what happens if the channel breaks — does the pipeline halt, silently drop work, or fall back to another channel?>
```

Each answer should be one or two sentences. If you can't write a failure-mode sentence, the channel is under-designed — think again before installing it.

### Step 3: Sanity-check against the other three channels

A new channel is most often the **combination** of two. Make sure you're not re-inventing something that's already doing the job:

- If you're adding *mail*, confirm the payload is genuinely a nudge and the real content lives in a work item or file.
- If you're adding *work items*, confirm an existing file + mail pair wouldn't carry the same information with less ceremony.
- If you're adding *files*, confirm the content has durability needs — not every hand-off deserves a file.
- If you're adding *external*, confirm you can't accomplish this by reading/writing a file your team already watches (CI logs, a markdown file in the repo, a README badge).

## Part 4: Install the New Channel in Your Factory (10 min)

> **Goal:** Turn the design from Part 3 into a working channel your factory actually uses.

The concrete work depends on the channel type. Pick the matching subsection.

### If your new channel is **mail**

1. Edit the producer stage's prompt to emit at the right moment:
   ```
   packs/<producer>/prompts/<producer>.md.tmpl
   → under the "Handoff" section, add:
     gc mail send <consumer> "<one-line payload>"
   ```
2. Edit the consumer stage's prompt to check `gc mail inbox` on wake-up (most shipped prompts already do this — confirm before adding).
3. Restart the factory: `/factory-activity-agent sling W3 planner --help` won't help here — restart the service with `cd ~/Projects/factory/workshop_w3/w3-gc-factory && gc stop && gc start`.

### If your new channel is **work items**

1. Decide the new label(s) you need. Add them to your manifest's `Labels` section so every stage knows their meaning.
2. Edit the producer stage's prompt to transition items to that label (`bd update <id> --label <new-label>` or create new items with `--label <new-label>`).
3. Edit the consumer stage's prompt (or its intake order gate) to poll on that label (`bd ready --label <new-label>`).
4. Seed one item with the new label and confirm the consumer wakes on it.

### If your new channel is **files**

1. Decide the file path format (e.g. `feedback-loops/<slug>.md`) and add the directory to your project workspace.
2. Edit the producer stage's prompt to write to that path as part of its output.
3. Edit the consumer stage's prompt's `Inputs you consume` section to include the new file as an input it reads.
4. Exercise the channel once — sling a task that produces the file, then sling the consumer and confirm it reads it.

### If your new channel is **external service**

1. Install the relevant MCP server (Linear, GitHub, Atlassian, Grafana, Slack, etc.) and authenticate.
2. Attach it to the correct stage(s). Authentication lives with the stage; stages that don't need the service should not have access.
3. Edit the stage's prompt to either (a) poll the service for events as an input source, or (b) emit to the service as part of its output.
4. Document the new external dependency in `docs/PROJECT_MANIFEST.md → Task Inputs` (if it's inbound) or add a new `External Emissions` section (if it's outbound).

### Verify end-to-end

Sling a small task that exercises the new channel:

```bash
/factory-activity-agent sling W3 <producer-stage> \
  "Exercise the new <channel-type> channel end-to-end for <your feature>. Do not do the full work — just the channel transition."
```

Watch the consumer stage in `/factory-activity-agent dashboard W3` to confirm the transition actually landed.

## Part 5: Document the Channel Alongside the Others (5 min)

> **Goal:** Make the new channel visible in the same place as the existing three, so L2–L4 can extend it instead of duplicating it.

Add the new channel to two places:

1. `docs/coordination-channels.md` — promote the "New Channel" section from Part 3 into the inventory table from Part 2.
2. `docs/PROJECT_MANIFEST.md` — in the appropriate section (`Task Inputs` for inbound, a new `External Emissions` section for outbound, or the existing `Conventions` section for an internal mail/file convention). The manifest is what every subsequent specialist reads on boot; if the channel isn't there, it doesn't exist as far as the factory is concerned.

Commit both files.

## Common Issues and Solutions

- **"My new channel duplicates an existing one."** Good — spotting that is the point of Part 3 Step 3. Keep the existing channel; use W3 to pick a different gap.
- **"I installed an MCP but the stage can't see it."** Most often, auth happened in your user session but not in the stage's spawned session. Authenticate from inside the stage (sling a dry-run that calls the MCP) and confirm persisted credentials.
- **"The consumer never wakes on the new label."** Check that the label is in the consumer's intake order gate (or that the consumer's prompt polls it). A label nobody's watching produces silent stalls.
- **"The channel works once and then never again."** Usually a prompt change that didn't get persisted to the pack, or a channel that depends on state outside the repo. Re-read your prompts from the factory workspace (not your editor's open tab) to confirm the config is what the agent sees.

## Exit Criteria

Before leaving this workshop, verify all of these:

- [ ] `docs/coordination-channels.md` exists with the inventory table plus your new channel's four-question design
- [ ] The new channel is exercised end-to-end at least once, with evidence in the dashboard or event log
- [ ] `docs/PROJECT_MANIFEST.md` records the new channel in the section that makes sense for its type
- [ ] You can articulate, in one sentence per channel, why each of the four channels is used where it is in your factory

## Quick Reference: What You Built

| Artifact | Location | What It Holds |
|----------|----------|---------------|
| W3 workspace | `~/Projects/factory/workshop_w3/` | Scratch project + factory for this workshop |
| `docs/coordination-channels.md` | Inside the W3 project workspace | Inventory of all four channels and the new one you added |
| Updated `docs/PROJECT_MANIFEST.md` | Inside the W3 project workspace | Canonical record of the new channel |
| Channel edits | `packs/<stage>/prompts/<stage>.md.tmpl` (for internal channels) or MCP config (for external) | The actual wiring |

## Next Steps

**[L2](../../labs/L2/LAB_2_GUIDE.md)** deploys the Planner and Architect packs against your project and is the first session that *depends* on coordination: Planner → Architect is a handoff where at least two channels must agree. You'll extend the Planner pack with the Architect-aware mail/work-item transitions you designed here.

**[L3](../../labs/L3/LAB_3_GUIDE.md)** and **[L4](../../labs/L4/LAB_4_GUIDE.md)** continue the pattern, adding Designer + Coder and Reviewer + Deployer respectively. Each of those sessions will reuse the channel you added in W3 if it was general-purpose, or demonstrate a parallel channel for the stages it installs.

Bring to L2:

- [ ] `docs/coordination-channels.md` committed in your project
- [ ] Updated `docs/PROJECT_MANIFEST.md` reflecting the new channel
- [ ] One exercised transition on the new channel (a work item, a file, a sent mail, or an external event) you can point to
