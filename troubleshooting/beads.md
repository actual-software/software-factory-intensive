# Troubleshooting beads (`bd`)

Issues with the `bd` (beads) issue tracker that the factory uses to coordinate agents. For `bd` command reference, run `bd prime`; this guide is only for things that go wrong.

## Contents

- [Issue: `issue_prefix config is missing`](#issue-issue_prefix-config-is-missing)
- [Issue: Agent doesn't wake after `bd label add <id> <label>`](#issue-agent-doesnt-wake-after-bd-label-add-id-label)
- [Issue: `import-tickets.sh` prints "failed to create FUP-N" warnings](#issue-import-ticketssh-prints-failed-to-create-fup-n-warnings)

---

## Issue: `issue_prefix config is missing`

**Symptom:** One of:

- `gc doctor` reports `bd create: ... issue_prefix config is missing`.
- The supervisor logs `bd create: ... issue_prefix config is missing` for every internal order (`wisp-compact`, `dolt-health`, etc.) and the next `gc sling` fails to spawn agent sessions.
- `gc sling <rig>/factory.planner ... --on <formula>` fails with `database not initialized: issue_prefix config is missing`.

**Cause:** A beads database that the supervisor or a rig is trying to use was never fully initialized. There are two common scenarios:

- **A — City's beads database (e.g. `my-factory/`):** When the curriculum repo is cloned, `my-factory/` lives inside it and inherits the curriculum's git remote. The supervisor needs its own beads store, but `bd init` here refuses by default to avoid colliding with that remote.
- **B — Rig's beads database (your project repo):** `gc rig add` registered the rig but didn't fully bootstrap its beads database — usually because the rig's git remote made `bd init` refuse the implicit init.

**Fix:**

For **A — city's beads database**, from `my-factory/`:

```bash
git config beads.role maintainer
bd init --reinit-local --prefix mf --discard-remote --destroy-token DESTROY-mf
```

`mf` is the city's prefix; `DESTROY-mf` is the matching destroy-token format documented in `bd help init-safety`. This local-only init never affects the curriculum repo's git history (the city's `.beads/` is in `.gitignore`).

For **B — rig's beads database**, from the rig directory:

```bash
cd ~/path/to/your-project
git config beads.role maintainer
bd init --reinit-local --prefix <prefix>   # use the same prefix gc rig add reported
cd -                                       # back to my-factory
```

The exact prefix appeared in the `gc rig add` output (e.g. `Prefix: swp` for a project named `your-project`). `--reinit-local` replaced the deprecated `--force` in recent `bd` versions; if your `bd` is older, `--force` is equivalent.

After either fix, re-run the command that originally failed (`gc doctor`, `gc sling ...`).

---

## Issue: Agent doesn't wake after `bd label add <id> <label>`

**Symptom:** You add a label like `needs-plan` to a bead, but the agent that consumes that label (Planner in the example) never wakes. `gc events --follow` shows no reaction to the label flip.

**Cause:** Usually one of:

- The label isn't *exactly* the canonical value. `Needs-Plan`, `needs-plan ` (trailing space), or `needs_plan` all fail to match the order gate.
- The agent's order gate isn't registered — this happens when the factory was started before the rig was added via `gc rig add`, so `gc` never wired up the intake order.

**Fix:**

1. Check the label exactly:
   ```bash
   bd label list <id>
   ```
   Compare to the canonical vocabulary (see [docs/labeled-beads.md](../docs/labeled-beads.md)). If the label is off by capitalization / whitespace, remove it and re-add the canonical value:
   ```bash
   bd label remove <id> "<bad-label>"
   bd label add <id> needs-plan
   ```

2. Confirm the order gate exists:
   ```bash
   gc order list
   ```
   The consuming agent's intake order (e.g. Planner's `needs-plan` gate) must be present. If it's missing, the rig was registered after `gc start`. Restart the factory so orders re-register:
   ```bash
   gc restart
   ```

3. If neither surfaces the problem, `gc doctor --fix --city <factory-dir>` will often re-wire a half-registered rig.

---

## Issue: `import-tickets.sh` prints "failed to create FUP-N" warnings

**Symptom:** Running `import-tickets.sh` (or any seed script that creates beads in bulk) prints warnings like `failed to create FUP-2` for one or more tickets.

**Cause:** The `bd` database already has beads with matching titles from a previous workshop run. `bd create` refuses to create duplicates, so the script skips them.

**Fix:** Usually the import is still *good enough* — the script is idempotent-ish and the pre-existing beads already cover the skipped titles. Confirm with:

```bash
bd list
```

If FUP-1 through FUP-6 (or the expected ticket range) are all present, you can proceed.

If you want a clean slate, close or delete the stale beads first:

```bash
bd list --all
bd close <id> --reason "stale from prior workshop run"
# or, to remove entirely:
bd delete <id>
```

Then re-run the import.
