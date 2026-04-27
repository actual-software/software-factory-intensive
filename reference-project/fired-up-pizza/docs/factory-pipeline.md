# Factory Pipeline · Fired Up Pizza

The W2 deliverable. Enumerates every capability the founder relied on during the
solo-AI phase (see [`workflow-card.md`](../workflow-card.md)) and places it on a
specific stage of the 6-agent factory. Every later curriculum artifact
(`orchestrator.yaml`, per-pack prompts, feedback loops) derives from this file.

---

## Current Workflow Inventory

Capabilities that powered the solo Claude Code workflow before the factory existed.
One line per entry; the next agent (or the founder three months later) should be
able to act on each entry without additional context.

### Models

- `claude-opus-4-7` — reasoning-heavy turns: planning, architecture, review.
- `claude-sonnet-4-6` — bulk coding, spec drafting, test generation.
- `claude-haiku-4-5` — quick lookups, commit-message drafting, CI-log summarization.

### Skills / slash commands

- `/simplify` — post-edit pass that reviews changed code for dead paths and over-engineering.
- `/security-review` — invoked after every `src/api/` change, before opening a PR.
- `/init` — one-time, for bootstrapping `CLAUDE.md` from `workflow-card.md`.
- Project-local convention: a 3-line plan is written as a bead comment before any code (from [workflow-card.md §3](../workflow-card.md)).

### MCP servers / integrations

- **GitHub MCP** — PR open/read, branch diff inspection, issue cross-reference.
- **Filesystem MCP** (local) — `src/` tree reads, `grep`-style searches.
- **SQLite inspector** (via `better-sqlite3` CLI shim) — ad-hoc queries against the local DB while debugging.

### Memory / persistence

- [`CLAUDE.md`](../CLAUDE.md) — project-wide agent instructions (pipeline, rules, money-formatting convention).
- [`docs/PROJECT_MANIFEST.md`](./PROJECT_MANIFEST.md) — tech stack, domain model, review standards, release criteria.
- [`docs/PROJECT_OVERVIEW.md`](./PROJECT_OVERVIEW.md) — human-facing scope and constraints.
- [`DECISIONS.md`](../DECISIONS.md) — running log of `CLAUDE.md` / pack-prompt edits keyed to beads.
- `docs/adr/` — one ADR per accepted architectural decision (e.g. `0001-loyalty-points-storage.md`).

### Knowledge sources

- `docs/adr/` — authoritative prior decisions. Every agent reads the index before producing new output.
- `tickets.md` — backlog feeding the Planner. Source for bead imports.
- Similar-file references — e.g. `src/db/orders.ts` for DB-layer style, `src/components/OrderStatusCard.tsx` for UI style.
- `feedback-loops/` — reactive, aggregate, and external rules promoted from recurring `DECISIONS.md` edits.

### Tools / CLIs

- `bd` (beads) — issue tracker. Single bead threads every stage of a feature.
- `gc` (Gas City) — agent-session manager. `gc sling`, `gc events`, `gc session peek`.
- `actual adr-bot` — seeds ADR skeletons from a work package's Open Questions.
- `gh` — PR creation, status checks, review comment pulls.
- `git` + conventional-commit discipline (`feat:`, `fix:`, `docs:`, `refactor:`).
- `npm` scripts: `lint`, `type-check`, `test`, `build`, `dev`. All must exit 0 before a commit lands.

### Playbook / rules

- Run `npm run lint && npm run type-check && npm test` after every slice; never type "oh and also please X" into chat.
- On gate failure: update `CLAUDE.md` or the relevant pack prompt, `git reset --hard HEAD`, re-sling.
- Prices are integer cents internally; render via `formatCents(n)` from `src/utils/format.ts`. Never `parseFloat` on a price field.
- Every SQL query uses `db.prepare(...).all(?)`; never string-interpolate user input.
- Feature branches only (`feat/<slug>`, `fix/<slug>`); `main` is protected.
- Each bead ID flows through every stage's artifact (work package → ADR → design spec → branch → review → gate).

---

## Shared Knowledge Base

These artifacts are read by **every** stage. Listed once here; each row in the
mapping table below references them rather than repeating the list.

| Artifact | Purpose | Writer | Readers |
|----------|---------|--------|---------|
| `docs/PROJECT_MANIFEST.md` | Tech stack, domain model, review standards, release criteria | founder (manual) | all 6 agents |
| `CLAUDE.md` | Cross-cutting agent rules (money format, SQL idiom, branch hygiene) | founder (manual) | all 6 agents |
| `docs/adr/` | Accepted architectural decisions | architect | architect, designer, coder, reviewer |
| `DECISIONS.md` | Log of pack-prompt edits keyed to beads | the founder, on every sling edit | everyone for audit; no agent writes it |
| `feedback-loops/` | Reactive / aggregate / external rules | promoted manually from `DECISIONS.md` | whichever agent the rule targets |
| `bd` (beads DB) | Single source of truth for feature state | every stage updates on handoff | every stage reads on entry |

---

## Pipeline Mapping

Each capability from the inventory lands on one stage. Shared artifacts (above)
are referenced, not repeated. The *Connections* column names the upstream and
downstream artifacts — this is what the orchestrator wires together in W3.

| Agent | Model | Tools / MCPs | Knowledge / memory | Connections |
|-------|-------|--------------|--------------------|-------------|
| **Planner** | `claude-opus-4-7` (scoping requires multi-step reasoning) | `bd` (read backlog, claim bead, add plan comment); GitHub MCP (ticket cross-reference); filesystem MCP | `tickets.md`; `docs/PROJECT_OVERVIEW.md`; prior work packages for precedent | **In:** feature request (bead). **Out:** work package (goal, stories, acceptance criteria, scope boundary). **Next:** architect |
| **Architect** | `claude-opus-4-7` (trade-off analysis; rejected-option rationale must be defensible) | `actual adr-bot` (seed ADR skeleton); filesystem MCP (prior-decision index); `/security-review` on schema changes | Prior architectural decisions; project manifest constraints; work package Open Questions | **In:** work package. **Out:** architectural decision record (one per open decision). **Gate:** human approval. **Next:** designer |
| **Designer** | `claude-sonnet-4-6` (spec drafting is structured, not research-heavy) | Filesystem MCP (sibling-file pattern search); Tailwind config lookup | Similar-file references; project manifest Conventions; relevant architectural decision | **In:** work package + architectural decision. **Out:** component / module spec. **Next:** coder |
| **Coder** | `claude-sonnet-4-6` (fast iteration on scoped slices) | `npm run lint \| type-check \| test \| build`; `better-sqlite3` CLI shim; `git` (branch + conventional commits); GitHub MCP (push, open PR); `/simplify` after each slice | Project agent rules (money-cents, SQL-parameterized, no-`any`, no-inline-styles); referenced similar files; co-located test patterns | **In:** design spec. **Out:** feature branch — implementation + tests. **Next:** reviewer |
| **Reviewer** | `claude-opus-4-7` (careful reasoning; precedent-aware severity judgement) | `git diff`; `/security-review`; `npm run lint \| test`; GitHub MCP (inline review comments) | Project review standards + severity scale; prior-violation feedback loops; tailored ADRs in agent rules | **In:** code diff + design spec. **Out:** review report with verdict. **On reject:** route back to coder (max 3 retries). **Gate:** human approval. **Next:** deployer |
| **Deployer** | `claude-haiku-4-5` (deterministic checks; scripted verdicts — no reasoning tax) | `npm run build`; `git status`, `git merge-tree` (conflict detection); `gh pr checks`; `bd approve` | Project release criteria (required + informational) | **In:** review report + feature branch state. **Out:** release gate report (PASS/FAIL per criterion). **Next:** merge to `main`, close bead |

**Rules of thumb that shaped the placements above:**

1. Every inventory entry has at least one home. Shared artifacts live in the Shared Knowledge Base; per-stage tools live in the table.
2. A capability lands on the **narrowest** stage that needs it. `/security-review` and the severity scale belong to the Reviewer, not "every stage." `actual adr-bot` belongs to the Architect.
3. Memory is project-level, not stage-level. `CLAUDE.md`, `PROJECT_MANIFEST.md`, and `docs/adr/` are shared — they're listed once above and referenced from each row.

---

## Missing Capabilities

Gaps surfaced while filling out the table. Each one is either essential for the
factory to run autonomously or blocks a specific stage from emitting its
artifact without a human in the loop. For each gap, a tentative implementation
strategy is noted so L1–L4 can close them.

| Capability | Why it's missing | Needed by | Tentative implementation |
|------------|------------------|-----------|--------------------------|
| **Automated manifest-update check** | `PROJECT_MANIFEST.md` Domain Model drifts from schema when a migration lands (caught manually during loyalty-points run) | Reviewer | A pre-review script diffs `src/db/schema.sql` against the Domain Model section; Reviewer blocks if they disagree. Add as a reactive `feedback-loops/manifest-schema-drift.md` rule |
| **Bead-to-branch linker** | Coder sometimes pushes a branch whose name doesn't match the bead slug; Deployer then can't auto-close the bead | Coder → Deployer | Git `pre-push` hook validates `feat/<slug>` matches an open bead; Deployer's `bd approve` step fails loudly if the linkage is missing |
| **ADR index regeneration** | `docs/adr/` has no index; Architect reads filenames and can miss a superseded decision | Architect | Generate `docs/adr/INDEX.md` from front-matter on every architect run; ship as part of the architect pack |
| **Accessibility scanner** | Reviewer caught missing `aria-live` / `aria-busy` manually on two runs (loyalty-points, order-history) — neither was spec-mandated | Reviewer | Add `axe-core` under `npm run a11y` and run during review; elevate Low-severity a11y findings to Medium after one grace release |
| **Cross-stage observability** | `gc events` shows per-agent turns but not end-to-end feature latency (slings-per-feature, time-in-review) | All stages (shared) | Emit a single event stream keyed by bead ID; surface a dashboard from `gc session list --bead <id>`. Shared manifest item, not per-agent |
| **Prompt-edit promotion threshold** | The Order-History retro asked: "when does a `DECISIONS.md` entry become a `feedback-loops/` rule?" — still unanswered | Shared (process, not agent) | Rule of thumb: promote after the same correction recurs across two features. Encode in the retrospective-card template |
