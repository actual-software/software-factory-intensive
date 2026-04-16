# My Factory — Workspace Quickstart

This folder is your **Gas City workspace** for the Software Factory Intensive. Everything in here is yours to edit. You add pack includes to `city.toml` as you progress through the curriculum; your per-session deliverables land in the sibling `../activities/` tree.

| File | Purpose |
|------|---------|
| `city.toml` | Top-level workspace config. Add pack includes here as sessions ship them. |
| `PROJECT_MANIFEST.md` | Manifest template for your project. Filled in during L1, read by every agent. |
| `README.md` | You are here. |

## Prerequisites

See [`../installation.md`](../installation.md) for the full dependency list. Minimum:

* Gas City (`brew install gastownhall/gascity/gascity`)
* A CLI coding agent (Claude Code, Codex, etc.) installed and authenticated
* `git`, `tmux`, `jq`, `dolt` (pulled in automatically on macOS)

## Quickstart

### 1. Verify Gas City

```bash
brew update
brew upgrade gascity
gc version
```

### 2. Register this workspace

Run this from the `my-factory/` directory (this file's directory):

```bash
cd my-factory
gc register .
```

`gc register` tells the long-running Gas City supervisor that this directory is a city it should manage. No new files are created — your existing `city.toml` is used as-is.

Expected output (abbreviated):

```
  ✓ city-structure — city.toml present
  ✓ city-config — city.toml loaded (0 agents, 0 rigs)
  ✓ config-valid — agents, rigs, and services valid
  ✓ controller — controller running (sessions managed)
  ✓ beads-store — store accessible
```

Any warning about `check-core-tools` means a dependency is missing — re-check `installation.md`.

### 3. Add your project as a rig

A *rig* is a project repo that the factory's agents will operate on. You can add one inline in `city.toml`, or via the CLI:

```bash
gc rig add ../../path/to/your-project
```

Or edit `city.toml` directly and add a `[[rigs]]` block (example commented out in the file). Either way, paths are resolved relative to `my-factory/`.

After editing, restart the city so it re-reads the config:

```bash
gc service restart
gc status
gc doctor
```

### 4. Add agent packs as you progress

Packs are added incrementally. You **do not** include all of them up front — each curriculum session ships the pack you need, plus the exact `includes` line to paste.

The shipped packs live at `../packs/<name>/` and are ready to use as-is. When a session wants you to customise a pack, copy it into `../activities/<session>/packs/<name>/`, edit that copy, and point `city.toml` at the copy instead.

| Session | Agent added | Pack path (shipped) | Label gate |
|---------|-------------|---------------------|------------|
| L2 | Planner | `../packs/planner` | `needs-plan` |
| L2 | Architect | `../packs/architect` | `needs-architecture` |
| L3 | Designer | `../packs/designer` | `needs-design` |
| L3 | Builder (Coder) | `../packs/builder` | `ready-to-build` |
| L4 | Reviewer | `../packs/reviewer` | `needs-review` |
| L4 | Release-Gate (Deployer) | `../packs/release-gate` | `ready-to-ship` |

Each session's `README.md` under `../activities/` tells you the exact lines to add to `city.toml` and which paths to customise if you want to deviate from the shipped defaults.

### 5. Start the factory

```bash
gc start
gc status
```

`gc status` lists declared agents and their current state. You can also open the dashboard:

```bash
gc dashboard serve
# http://localhost:8080
```

### 6. Create your first task

From inside a rig (your project repo), file a bead and sling it at an agent:

```bash
cd ../../path/to/your-project
bd create --title "Your first feature" --label needs-architecture
gc sling your-project--architect <bead-id>
```

The shipped pipeline uses **label-based handoff** — when the architect closes the bead with `needs-plan`, the planner picks it up, and so on. There is no master orchestrator; flow is emergent from labels.

## Where do my deliverables live?

* **Curriculum outputs** (workflow cards, orchestrator files, feedback-loop notes) → `../activities/<workshop-or-lab>/`
* **Customised packs** (if you diverge from the shipped defaults) → `../activities/<session>/packs/<agent>/`
* **Factory-generated artifacts** (work packages, ADRs, design specs, review reports, release gates) → inside your rig (your project repo), under the directories named in `PROJECT_MANIFEST.md`

The shipped reference project at `../reference-project/fired-up-pizza/` shows completed examples of each artifact type.

## Getting un-stuck

Every session is designed to be independent and additive. If a session goes sideways:

1. Revert your customisations under `../activities/<session>/packs/` with `git checkout`.
2. Point `city.toml`'s `includes` at the shipped pack (`../packs/<name>`) instead of your copy.
3. Run `gc service restart && gc doctor` — the shipped pack is always green.
4. Continue to the next session. You can revisit the broken session later without blocking progress.

## References

* Gas City quickstart: https://github.com/gastownhall/gascity/blob/main/docs/getting-started/quickstart.md
* Gas City pack authoring: https://github.com/gastownhall/gascity/blob/main/docs/getting-started/coming-from-gastown.md
* Reference project: [`../reference-project/fired-up-pizza/`](../reference-project/fired-up-pizza/)
