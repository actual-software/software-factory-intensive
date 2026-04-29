# Installation

Install these before starting the curriculum. All sessions assume the tools below are on your `$PATH` and authenticated.

---

## 1. Operating System

| OS | Supported? | Notes |
|----|-----------|-------|
| macOS | Yes | Works as-is. Homebrew recommended. |
| Linux | Yes | Works as-is. Install dependencies via your package manager. |
| Windows | Via WSL only | Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install), then run every command from inside the WSL shell. Native Windows PowerShell is not supported. |

---

## 2. Gas City

Gas City is the orchestration framework this workshop is built on. It manages agents, packs, rigs, and beads. Please follow the steps below to install Gas City, and refer to the [Gas City documentation](https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md) for additional details.

```bash
# macOS / WSL / Linux (with Homebrew)
brew install gastownhall/gascity/gascity

# Verify (must report >= 1.0.0)
gc version
```

If you already have an older version of Gas City installed, you may need to uninstall it and install the latest version:
```bash
brew uninstall gascity
brew install gastownhall/gascity/gascity

# or
brew link --overwrite gascity
```

Gas City brings in the core tool dependencies it needs: `tmux`, `jq`, `git`, `dolt`. On macOS they are installed as Homebrew dependencies. On Linux, install any missing ones via your package manager.

Confirm everything is wired up:

```bash
gc doctor
```

All `check-core-tools` lines should show `✓`. Two deprecation warnings are **expected** for the factory's intentional v1-shape workarounds (documented in `my-factory/README.md`):

- `v2-default-rig-import-format` — tracked at [workshop:#781](https://github.com/gastownhall/gascity/issues/781)
- `v2-workspace-name` — tracked at [comment on #600](https://github.com/gastownhall/gascity/issues/600)

Warnings for optional integrations (Jira, Linear, Sentry, etc.) are also expected at this point — you'll enable those later.

---

## 3. CLI Coding Agents

You need **at least one** CLI coding agent. Multiple agents give broader capabilities and redundancy — different models have different strengths.

### Recommended

- **Claude Code** (`brew install anthropic/tap/claude`) — subscribe to Claude Max 20×
- **Codex CLI** — subscribe to Codex Pro 20× or similar

### Minimum

One of the above at a paid tier sufficient for sustained multi-agent runs.

### Others (compatibility not guaranteed)

- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [OpenCode](https://github.com/opencode-ai/opencode)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli)
- [Cursor](https://www.cursor.com/) (agents mode)

For the authoritative list of providers Gas City natively supports — along with the `provider = "..."` value to put in `city.toml` — see [`internal/config/provider.go#L203-L209`](https://github.com/gastownhall/gascity/blob/73f09ddd78fed9b90e0589b324255c36d030eb46/internal/config/provider.go#L203-L209) in the Gas City source.

---

## 4. Authenticate

Each agent provider has its own auth flow. After installing:

```bash
# Claude Code
claude login

# Codex
codex login

# (repeat per provider)
```

Then confirm Gas City can see the authenticated CLI:

```bash
gc doctor
```

---

## 5. Python installation

[Python 3.8+](https://www.python.org/downloads/) is required to run the factory-activity-agent script, which makes the curriculum setup and teardown much easier. You can check your Python version with `python3 --version`.

---

## 6. Clone This Repo

```bash
git clone https://github.com/actual-software/software-factory-intensive.git
cd software-factory-intensive
```

Your Gas City factory lives at `my-factory/` — you'll copy the committed templates and register it in L1 (or see [`my-factory/README.md`](my-factory/README.md) for the step-by-step). Your per-session deliverables land under `activities/`. See `reference-project/fired-up-pizza/` for a completed example.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `gc: command not found` | Homebrew didn't link the binary. Run `brew link gascity` or ensure `$(brew --prefix)/bin` is on `$PATH`. |
| `gc doctor` fails `check-core-tools` | Install the missing tool via `brew install <tool>` (macOS) or your package manager (Linux). |
| Windows `gc` runs but hangs | You're likely running from PowerShell. Switch to the WSL shell. |
| Provider not recognized | Check your `provider = "..."` value matches one in the [Gas City provider registry](https://github.com/gastownhall/gascity/blob/73f09ddd78fed9b90e0589b324255c36d030eb46/internal/config/provider.go#L203-L209). |
