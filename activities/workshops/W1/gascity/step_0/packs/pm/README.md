# actual-pm

The **Plan / Work-Breakdown** agent of the Actual Software Factory.
One of eight Agent-Operation packs under `examples/actual/`. Maps to
the "Plan" operation at https://www.actual.ai/softwarefactory.

## Persona

Product Manager + Program Manager. Writes user stories with
measurable acceptance criteria. Tracks dependencies. Flags risks
early. Never writes implementation code. Anchor personas are defined
in `actual-factory/extensions/factory-vscode/shared/actual-agents/built-in-agents.ts`.

## What it does

- Reads beads labelled `needs-pm` (from the architect or from a
  user)
- Optionally imports issues from an external tracker (Jira / Linear /
  GitHub Issues / any `tracker-*` skill) via the bundled
  `tracker-to-beads` skill
- Breaks each goal into 3-10 child beads with measurable acceptance
  criteria
- Wires a dependency graph with `bd dep add`
- Labels children for routing:
  - `needs-design` → **designer**
  - `needs-tests` → **validator**
  - `ready-to-build` → **builder**
- Writes a human-readable plan under `.actual/plans/<slug>.md`

## The two skills this pack ships

### 1. `actual` (vendored from upstream)

The standard [actual-software/actual-skill](https://github.com/actual-software/actual-skill)
companion for the `actual` CLI. The pm uses it to read the rig's
current `CLAUDE.md` / `AGENTS.md` for architectural context.

To re-vendor:
```bash
./scripts/sync-actual-skill.sh
```

### 2. `tracker-to-beads` (pack-local)

Bridges external trackers into `bd`. **The builder downstream only
ever reads beads**, so everything that comes from a tracker must pass
through this conversion.

The skill probes `.claude/skills/` for any sibling matching:

- `jira`
- `linear`
- `github-issues`
- `tracker-*`

If none are found, import is a no-op and the pm just processes
whatever `needs-pm` beads already exist. If one or more are found,
the skill invokes their `list-issues` verb and materializes each
issue as a bead, recording the mapping in
`.actual/pm/tracker-sync.json` so re-runs are idempotent.

**Tracker skill contract.** Any sibling tracker skill wanting to
integrate must expose `scripts/list-issues.sh` (or `list-issues`)
that prints a JSON array to stdout:

```json
[
  {
    "id": "PROJ-123",
    "title": "Add user profiles",
    "url": "https://...",
    "body": "full markdown body",
    "labels": ["frontend", "p1"]
  }
]
```

Any tracker whose script exits non-zero or prints invalid JSON is
ignored with a warning. The pm **never** fails its formula for
tracker reasons.

Manual import (bypassing the formula):
```bash
./commands/tracker-sync.sh
```

## How to run

As part of the full factory:
```bash
gc rig add /path/to/your/project
gc start examples/actual/
```

Standalone:
```toml
# city.toml
[workspace]
includes = ["examples/actual/pm"]
```

Manual dispatch:
```bash
gc sling <rig>/pm --on mol-plan-breakdown --var slug=user-profiles
```

## What it does NOT do

- Write code, design UI, author tests, or make architecture decisions.
- Handle tracker authentication (sibling tracker skills own that).
- Re-create beads that already exist in the sync manifest.

## Handoff

- **designer** via `needs-design`
- **validator** via `needs-tests`
- **builder** via `ready-to-build`
- **architect** via `needs-architecture` (if the pm discovers an
  architectural question mid-breakdown and has to hand it back up)
