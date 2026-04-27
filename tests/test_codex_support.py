"""Tests for codex provider support in W1 gascity packs."""

import tomllib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
W1_PACKS_DIR = REPO_ROOT / "activities" / "workshops" / "W1" / "gascity" / "step_0" / "packs"


def load_toml(path: Path) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)


# --- city.toml ---


def test_codex_provider_exists():
    data = load_toml(W1_PACKS_DIR / "city.toml")
    assert "codex" in data.get("providers", {}), "[providers.codex] missing from city.toml"


def test_codex_provider_command():
    data = load_toml(W1_PACKS_DIR / "city.toml")
    assert data["providers"]["codex"]["command"] == "codex"


def test_claude_provider_preserved():
    data = load_toml(W1_PACKS_DIR / "city.toml")
    assert "claude" in data.get("providers", {}), "[providers.claude] must remain in city.toml"


def test_workspace_install_hooks_includes_codex():
    data = load_toml(W1_PACKS_DIR / "city.toml")
    hooks = data.get("workspace", {}).get("install_agent_hooks", [])
    assert "codex" in hooks, "workspace.install_agent_hooks must include 'codex'"


def test_workspace_install_hooks_includes_claude():
    data = load_toml(W1_PACKS_DIR / "city.toml")
    hooks = data.get("workspace", {}).get("install_agent_hooks", [])
    assert "claude" in hooks, "workspace.install_agent_hooks must include 'claude'"


# --- architect/pack.toml ---


def test_architect_has_no_claude_only_model_default():
    data = load_toml(W1_PACKS_DIR / "architect" / "pack.toml")
    agent = data["agent"][0]
    option_defaults = agent.get("option_defaults", {})
    assert option_defaults.get("model") != "opus", (
        "option_defaults.model='opus' is claude-specific and breaks codex; "
        "move model defaults to [providers.*] in city.toml"
    )
