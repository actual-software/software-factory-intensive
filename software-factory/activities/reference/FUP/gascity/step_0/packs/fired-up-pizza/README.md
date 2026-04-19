# fired-up-pizza (composite pack)

Bundles the **6 essential Agent Operations** for the Fired Up Pizza
reference project. Same six leaf packs as `../all`, plus a doctor
check that verifies the rig's scaffold (`docs/PROJECT_MANIFEST.md`,
`package.json`) is in place, and a ticket-import helper for the
project's `tickets.md` backlog.

## When to use this vs. `../all`

| Pack | Use when |
|------|----------|
| `../all` | You are standing the factory up against any arbitrary rig (your own project, a lab scaffold, etc.). |
| `fired-up-pizza` | You are running the factory specifically against `software-factory/reference-project/`. Adds the reference-scaffold doctor check + a `tickets.md` importer. |

## Bundled agents

Identical to `../all`:

| Operation | Pack | Label gate |
|-----------|------|------------|
| Architect | `../architect` | `needs-architecture` |
| Plan / Work Breakdown | `../planner` | `needs-plan` |
| UI/UX Design | `../designer` | `needs-design` |
| Code | `../coder` | `ready-to-build` |
| Code Review (incl. AC verification) | `../reviewer` | `needs-review` |
| Deploy | `../deployer` | `ready-to-ship` |

The optional 7th agent (improver) is not bundled. Add it explicitly
if you want a continuous-improvement loop.

## Manual stand-up

The canonical way to bring this factory up is the
`curriculum-agent install` workflow once the fired-up-pizza install
route ships. Until then, or to inspect the pack interactively, you
can stand it up directly with the `gc` CLI:

```bash
# 1. Create a factory workspace dir (anywhere outside the repo is fine)
mkdir -p ~/Projects/factory/fired-up-pizza/fup-gc-factory
cd ~/Projects/factory/fired-up-pizza/fup-gc-factory

# 2. Write a city.toml that includes this pack
cat > city.toml <<'TOML'
[workspace]
name = "fup-factory"
provider = "claude"
includes = ["/abs/path/to/software-factory/packs/fired-up-pizza"]

[session]
startup_timeout = "3m"
TOML

# 3. Register the reference project as the rig
gc rig add /abs/path/to/software-factory/reference-project

# 4. Register + start the factory
gc register .
gc start
gc status        # confirm all six agents are running
```

Point the `includes` line at wherever you cloned this repo — the
relative path form `../../packs/fired-up-pizza` also works if your
factory dir sits next to `software-factory/`.

## Doctor check

`fired-up-pizza/doctor/check-project.sh` verifies the rig has the
two artifacts that every agent in this pack assumes:

- `docs/PROJECT_MANIFEST.md` — tech stack + conventions that every
  agent reads before writing output
- `package.json` — the Node.js scaffold the coder/reviewer stack
  against

If either is missing, `gc doctor` flags the gap before the factory
starts claiming work.

## Importing the initial backlog

The reference project ships an opinionated starter backlog in
`reference-project/tickets.md`. Import it into the rig's bead store
once, from the rig's working directory:

```bash
cd /abs/path/to/software-factory/reference-project
bash ../packs/fired-up-pizza/scripts/import-tickets.sh tickets.md
bd list   # confirm the imported feature beads
```

Then label the first bead `needs-plan` to kick the pipeline off —
the Planner will wake on the next order-gate tick.

## Handoff flow

Identical to the diagram in `../all/README.md` — the bead walks
`needs-plan → needs-architecture? → needs-design? → ready-to-build
→ needs-review → ready-to-ship` by each agent relabeling at its
stage. There is no master orchestrator. Rewire by changing labels,
not by editing this pack.
