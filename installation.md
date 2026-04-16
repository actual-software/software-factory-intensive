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

Gas City is the orchestration framework this workshop is built on. It manages agents, packs, rigs, and beads.

```bash
# macOS / WSL / Linux (with Homebrew)
brew install gastownhall/gascity/gascity

# Verify
gc --version
```

Gas City brings in the core tool dependencies it needs: `tmux`, `jq`, `git`, `dolt`. On macOS they are installed as Homebrew dependencies. On Linux, install any missing ones via your package manager.

Confirm everything is wired up:

```bash
gc doctor
```

All `check-core-tools` lines should show `✓`. Warnings for optional integrations (Jira, Linear, Sentry, etc.) are expected at this point — you'll enable those later.

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

## 5. Clone This Repo

```bash
git clone https://github.com/actual-software/software-factory-intensive.git
cd software-factory-intensive
```

You'll reference `reference-project/fired-up-pizza/` as a completed example, and copy `my-factory/` into your own project during L1.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `gc: command not found` | Homebrew didn't link the binary. Run `brew link gascity` or ensure `$(brew --prefix)/bin` is on `$PATH`. |
| `gc doctor` fails `check-core-tools` | Install the missing tool via `brew install <tool>` (macOS) or your package manager (Linux). |
| Windows `gc` runs but hangs | You're likely running from PowerShell. Switch to the WSL shell. |
| Provider not recognized | Check your `provider = "..."` value matches one in the [Gas City provider registry](https://github.com/gastownhall/gascity/blob/73f09ddd78fed9b90e0589b324255c36d030eb46/internal/config/provider.go#L203-L209). |
