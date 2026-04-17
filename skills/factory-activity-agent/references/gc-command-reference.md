# gc CLI Command Reference (v0.14.1)

Complete command reference for the Gas City CLI. Load this file when you need full flag details or usage examples beyond the quick reference in SKILL.md.

## Lifecycle Commands

### `gc init <dir>`
Initialize a new factory workspace (city).

```bash
gc init ~/Projects/factory/my-factory
# Prompts for template selection (1=blank, 2=starter, 3=claude)
echo "3" | gc init ~/Projects/factory/my-factory  # Non-interactive: select claude template
```

### `gc register <dir>`
Register a factory with the machine-wide supervisor so it can be started/stopped.

```bash
gc register ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc unregister <dir>`
Remove a factory from the supervisor. Does not delete files.

```bash
gc unregister ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc start`
Start all agent sessions in the factory. Requires being in a factory directory or using `--city`.

```bash
gc start
gc start --city ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc stop`
Stop all agent sessions.

```bash
gc stop
gc stop --city ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc restart`
Restart all agent sessions (stop + start).

```bash
gc restart
```

### `gc suspend`
Suspend the factory — all agents are effectively paused. State is preserved.

```bash
gc suspend
```

### `gc resume`
Resume a suspended factory.

```bash
gc resume
```

## Operations Commands

### `gc status`
Show city-wide status overview including agent states, rig status, and service health.

```bash
gc status
gc status --city ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc sling <rig/agent> "<prompt>"`
Route work to a specific agent. Can route an existing bead or create one from text.

```bash
# Route a text prompt (creates a bead automatically)
gc sling w2-project/architect "Design a REST API for user management"

# Route an existing bead
gc sling w2-project/builder SFI-abc123

# Route a formula
gc sling mayor code-review --formula
```

Flags:
- `--formula` — instantiate a formula instead of routing a bead

### `gc doctor [--fix]`
Check workspace health. Verifies dependencies, configuration, authentication.

```bash
gc doctor           # Check only
gc doctor --fix     # Auto-fix issues where possible
```

### `gc dashboard serve`
Start the web dashboard for monitoring. Serves on http://localhost:8080.

```bash
gc dashboard serve
gc dashboard serve --city ~/Projects/factory/workshop_w2/w2-gc-factory
```

### `gc rig add <path>`
Add a project directory as a rig to the factory.

```bash
gc rig add ~/Projects/factory/workshop_w2/w2-project
```

### `gc rig list`
List rigs registered in the current factory.

### `gc config`
Inspect and validate city configuration (city.toml).

```bash
gc config
```

### `gc cities`
List all registered cities (factories) on this machine.

```bash
gc cities
```

### `gc events`
Show the event log for the current factory.

```bash
gc events
```

### `gc prime <agent>`
Output the full behavioral prompt for an agent. Useful for debugging agent behavior.

```bash
gc prime w2-project/architect
```

## Session Commands

### `gc session new`
Create a new chat session from an agent template.

```bash
gc session new
```

### `gc session attach <id>`
Attach to (resume) an existing chat session.

```bash
gc session attach <session-id>
```

### `gc session list`
List all chat sessions (active and suspended).

```bash
gc session list
```

### `gc session suspend`
Suspend a running session (save state, free resources).

```bash
gc session suspend
```

### `gc session nudge <id> "<message>"`
Send a text message to a running session without attaching.

```bash
gc session nudge <session-id> "Please also add error handling"
```

## Formula Commands

### `gc formula list`
List available formulas in the current factory.

```bash
gc formula list
```

### `gc formula show <name>`
Show the compiled recipe for a formula (steps, agents, dependencies).

```bash
gc formula show code-review
```

### `gc formula cook <name>`
Instantiate a formula — creates beads and routes work according to the recipe.

```bash
gc formula cook code-review
```

## Order Commands

### `gc order list`
List available orders (scheduled and event-driven dispatch rules).

### `gc order check`
Check which orders are currently due to run.

### `gc order run <name>`
Execute an order manually.

### `gc order history`
Show order execution history.

## Advanced Commands

### `gc convoy`
Manage convoys — graphs of related work items that move through the pipeline together.

### `gc converge create`
Create a convergence loop for bounded iterative refinement.

### `gc converge status`
Show convergence loop status.

### `gc converge approve`
Approve and close a convergence loop.

### `gc converge iterate`
Force the next iteration of a convergence loop.

### `gc mail`
Send and receive messages between agents and humans.

### `gc hook`
Check for available work. Used with `--inject` for Stop hook output.

### `gc nudge`
Inspect and deliver deferred nudges.

### `gc service restart`
Restart the Gas City supervisor service (machine-wide).

```bash
gc service restart
```

### `gc supervisor`
Manage the machine-wide supervisor process.

### `gc pack`
Manage remote pack sources.

### `gc agent`
Manage agent configuration within a factory.

### `gc bd`
Run `bd` (beads CLI) in the correct rig directory context.

### `gc version`
Print the gc CLI version.

```bash
gc version
# Expected output for this curriculum: v0.14.1
```

## Global Flags

These flags work with any command:

| Flag | Purpose |
|------|---------|
| `--city <path>` | Path to the city directory (default: walk up from cwd) |
| `--rig <name>` | Rig name or path (default: discover from cwd) |
| `-h, --help` | Help for the command |

## city.toml Configuration

The factory workspace is configured via `city.toml`:

```toml
[workspace]
name = "w2-gc-factory"
provider = "claude"
start_command = "/path/to/claude"

[[rigs]]
name = "w2-project"
path = "/Users/you/Projects/factory/workshop_w2/w2-project"
includes = ["packs/actual/all"]
```

Key sections:
- `[workspace]` — factory name, provider, CLI binary path
- `[[rigs]]` — project repos attached to the factory
- `includes` — pack paths to load for each rig
