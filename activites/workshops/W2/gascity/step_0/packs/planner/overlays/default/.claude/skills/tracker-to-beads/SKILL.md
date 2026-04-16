---
name: tracker-to-beads
description: >-
  Convert issues from an external tracker (Jira, Linear, GitHub Issues,
  or any skill matching `tracker-*`) into Beads (`bd`) so the downstream
  builder agent can consume them uniformly. Probes for sibling skills,
  invokes their `list-issues` verb, and writes an idempotent mapping
  manifest at `.actual/planner/tracker-sync.json`. Use when a planner
  needs to bridge a tracker-first workflow into a bd-first agent
  pipeline.
argument-hint: "[probe|import|status]"
---

# tracker-to-beads

Bridge skill that makes external trackers look like beads.

## Contract

This skill expects **zero, one, or more sibling skills** in the same
`.claude/skills/` directory with names matching:

- `jira`
- `linear`
- `github-issues`
- `tracker-*` (any prefix match)

Each sibling tracker skill must expose a `list-issues` verb that
prints JSON to stdout with the shape:

```json
[
  {
    "id": "PROJ-123",
    "title": "Add user profile page",
    "url": "https://...",
    "body": "full issue body markdown",
    "labels": ["frontend", "p1"]
  },
  ...
]
```

Any sibling whose `list-issues` exits non-zero or prints invalid JSON
is ignored with a warning — it does NOT fail the formula.

## Commands

### `probe`

Lists all sibling tracker skills detected in the current
`.claude/skills/` search path.

```bash
./scripts/probe.sh
```

Exit codes:
- 0 — at least one tracker was found (prints names to stdout)
- 0 — no trackers found (prints `none` to stdout, still 0 — probing
  is informational, not an error)

### `import`

Runs probe, then for each tracker invokes `list-issues`, and for each
issue either creates a new bead or updates the existing mapped bead.
Writes the mapping manifest to `.actual/planner/tracker-sync.json`.

```bash
./scripts/import.sh
```

Re-runs are idempotent: issues already in the manifest are updated
in place rather than re-created.

### `status`

Prints a short summary of the current manifest.

```bash
./scripts/status.sh   # (shipped as commands/tracker-sync.sh in the planner pack)
```

## Why this exists

The Actual Software Factory is bd-first: the **builder** agent reads
beads and only beads. But most real teams use Jira / Linear / GitHub
Issues as their source of truth. Rather than teach every agent to
talk to every tracker, the **planner** owns the boundary: trackers in,
beads out.

This lets users run the factory in three modes with no config change:

1. **Pure bd-first** — no tracker skills installed; planner only
   processes beads that already exist. `import` no-ops.
2. **Hybrid** — one or more tracker skills installed; planner pulls
   in external issues at the start of each breakdown run.
3. **Pure tracker-first** — tracker skills installed, no manual bead
   creation; the only way work enters the factory is via `import`.

## Labels written on converted beads

Every bead created by this skill carries:

| Label | Example | Purpose |
|-------|---------|---------|
| `source:<tracker>` | `source:jira` | Provenance |
| `tracker-key:<id>` | `tracker-key:PROJ-123` | Upstream ID for idempotent re-runs |
| `needs-plan` | (fixed) | Routes the new bead to the planner's own queue |

Additional labels from the tracker issue are preserved verbatim.

## Guarantees

- **Never fails the formula.** Missing trackers, bad JSON, and network
  errors are logged but exit 0.
- **Idempotent.** The manifest is keyed by tracker + upstream id;
  re-runs update rather than duplicate.
- **No credentials.** This skill handles zero authentication — it
  delegates entirely to the sibling tracker skills, which are
  expected to manage their own auth.
