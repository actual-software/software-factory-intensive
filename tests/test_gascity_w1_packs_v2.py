"""Tests for gascity/packs/w1/ — Pack V2 single-pack structure.

Red phase: all tests fail until gascity/packs/w1/ is created.
Green phase: all tests pass after V2 pack is implemented.
"""

import os
import stat
import tomllib
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
W1_V2 = REPO_ROOT / "gascity" / "packs" / "w1"

AGENTS = [
    "planner", "architect", "builder", "designer", "validator",
    "reviewer", "deployer", "improver", "pm", "deacon", "witness",
]

# Agents with overlay dirs (all except deacon and witness)
OVERLAY_AGENTS = [
    "planner", "architect", "builder", "designer", "validator",
    "reviewer", "deployer", "improver", "pm",
]

# Agents that ship the actual skill in their overlay
SKILL_AGENTS = ["planner", "architect", "builder", "designer", "improver", "pm"]

# Order gate filenames per originating V1 pack
PACK_ORDERS = {
    "planner":   "planner-intake",
    "architect": "architect-guardrail-check",
    "builder":   "builder-intake",
    "designer":  "designer-intake",
    "validator": "validator-intake",
    "reviewer":  "reviewer-intake",
    "deployer":  "deployer-intake",
    "improver":  "improver-cooldown",
    "pm":        "pm-intake",
}

# V2 command subdirectories (namespaced <pack>-<verb>)
COMMANDS = [
    "planner-status",
    "architect-status", "architect-rules",
    "builder-status", "builder-build",
    "designer-status", "designer-designs",
    "validator-status", "validator-tests",
    "reviewer-status", "reviewer-verdicts",
    "improver-status", "improver-harvest",
    "pm-status", "pm-plan", "pm-tracker-sync",
]

DOCTOR_CHECKS = [
    "check-planner", "check-architect", "check-builder",
    "check-designer", "check-validator", "check-reviewer",
    "check-improver", "check-pm",
]

V1_PACK_NAMES = [
    "planner", "architect", "builder", "designer", "validator",
    "reviewer", "deployer", "improver", "pm", "supervisor", "all",
]


def load_toml(path: Path) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)


# ---------------------------------------------------------------------------
# 1. Pack root & single-pack structure
# ---------------------------------------------------------------------------

def test_w1_v2_dir_exists():
    assert W1_V2.is_dir()


@pytest.mark.parametrize("name", V1_PACK_NAMES)
def test_no_sub_pack_dirs(name):
    assert not (W1_V2 / name).is_dir(), (
        f"{name}/ must not exist as a sub-pack directory — use single flat pack"
    )


def test_pack_toml_exists():
    assert (W1_V2 / "pack.toml").is_file()


# ---------------------------------------------------------------------------
# 2. Schema V2 + no V1 legacy in pack.toml
# ---------------------------------------------------------------------------

def test_schema_is_v2():
    data = load_toml(W1_V2 / "pack.toml")
    assert data["pack"]["schema"] == 2


def test_no_inline_agent_table():
    data = load_toml(W1_V2 / "pack.toml")
    assert "agent" not in data, "Inline [[agent]] is V1 legacy — use agents/<name>/agent.toml"


def test_no_commands_table():
    data = load_toml(W1_V2 / "pack.toml")
    assert "commands" not in data, "[[commands]] is V1 legacy — use commands/<cmd>/run.sh"


def test_no_doctor_table():
    data = load_toml(W1_V2 / "pack.toml")
    assert "doctor" not in data, "[[doctor]] is V1 legacy — use doctor/<check>/run.sh"


def test_no_formulas_table():
    data = load_toml(W1_V2 / "pack.toml")
    assert "formulas" not in data, "[formulas] dir is V1 legacy — gc discovers formulas/ by convention"


# ---------------------------------------------------------------------------
# 3. V2 agent directory structure
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("name", AGENTS)
def test_agent_dir_exists(name):
    assert (W1_V2 / "agents" / name).is_dir()


@pytest.mark.parametrize("name", AGENTS)
def test_agent_toml_exists(name):
    assert (W1_V2 / "agents" / name / "agent.toml").is_file()


@pytest.mark.parametrize("name", AGENTS)
def test_prompt_template_exists(name):
    assert (W1_V2 / "agents" / name / "prompt.template.md").is_file()


# ---------------------------------------------------------------------------
# 4. agent.toml: no V1 overlay path
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("name", OVERLAY_AGENTS)
def test_agent_toml_overlay_dir_uses_v2_path(name):
    content = (W1_V2 / "agents" / name / "agent.toml").read_text()
    assert "overlays/default" not in content, (
        f"agents/{name}/agent.toml must not reference V1 overlays/default"
    )
    assert f"overlay/{name}" in content, (
        f"agents/{name}/agent.toml must set overlay_dir = \"overlay/{name}\""
    )


# ---------------------------------------------------------------------------
# 5. No V1 legacy directories at pack root
# ---------------------------------------------------------------------------

def test_no_prompts_dir_at_root():
    assert not (W1_V2 / "prompts").exists()


def test_no_overlays_dir_at_root():
    assert not (W1_V2 / "overlays").exists()


def test_no_formulas_orders_dir():
    assert not (W1_V2 / "formulas" / "orders").exists()


# ---------------------------------------------------------------------------
# 6. V2 overlay: per-agent subdirs
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("name", OVERLAY_AGENTS)
def test_overlay_agent_dir_exists(name):
    assert (W1_V2 / "overlay" / name).is_dir()


@pytest.mark.parametrize("name", OVERLAY_AGENTS)
def test_overlay_settings_json(name):
    assert (W1_V2 / "overlay" / name / ".claude" / "settings.json").is_file()


@pytest.mark.parametrize("name", SKILL_AGENTS)
def test_overlay_actual_skill(name):
    assert (W1_V2 / "overlay" / name / ".claude" / "skills" / "actual" / "SKILL.md").is_file()


# ---------------------------------------------------------------------------
# 7. V2 orders: flat files at orders/<gate>.toml
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("pack,gate", PACK_ORDERS.items())
def test_order_at_v2_location(pack, gate):
    assert (W1_V2 / "orders" / f"{gate}.toml").is_file(), (
        f"orders/{gate}.toml must exist (ported from {pack}/formulas/orders/{gate}/order.toml)"
    )


def test_planner_order_triggers_on_needs_plan():
    data = load_toml(W1_V2 / "orders" / "planner-intake.toml")
    assert "needs-plan" in data["order"]["check"]


def test_builder_order_triggers_on_ready_to_build():
    data = load_toml(W1_V2 / "orders" / "builder-intake.toml")
    assert "ready-to-build" in data["order"]["check"]


# ---------------------------------------------------------------------------
# 8. V2 commands: commands/<cmd>/run.sh
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("cmd", COMMANDS)
def test_command_has_v2_structure(cmd):
    run_sh = W1_V2 / "commands" / cmd / "run.sh"
    assert run_sh.is_file(), f"commands/{cmd}/run.sh must exist"
    assert os.stat(run_sh).st_mode & stat.S_IXUSR, f"commands/{cmd}/run.sh must be executable"


# ---------------------------------------------------------------------------
# 9. V2 doctor: doctor/<check>/run.sh
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("check", DOCTOR_CHECKS)
def test_doctor_has_v2_structure(check):
    run_sh = W1_V2 / "doctor" / check / "run.sh"
    assert run_sh.is_file(), f"doctor/{check}/run.sh must exist"
    assert os.stat(run_sh).st_mode & stat.S_IXUSR, f"doctor/{check}/run.sh must be executable"


# ---------------------------------------------------------------------------
# 10. Named sessions cover all agents
# ---------------------------------------------------------------------------

def test_named_sessions_cover_all_agents():
    data = load_toml(W1_V2 / "pack.toml")
    session_templates = {s["template"] for s in data["named_session"]}
    for name in AGENTS:
        assert name in session_templates, f"named_session for '{name}' missing from pack.toml"


# ---------------------------------------------------------------------------
# 11. Content preservation (spot-checks)
# ---------------------------------------------------------------------------

def test_all_formula_files_present():
    expected = [
        "mol-planner-prd",
        "mol-architect-review",
        "mol-build-from-spec",
        "mol-tdd-build",
        "mol-design-cycle",
        "mol-acceptance-tests",
        "mol-code-review",
        "mol-deployer-gate",
        "mol-feedback-harvest",
        "mol-plan-breakdown",
        "mol-deacon-patrol",
        "mol-witness-patrol",
    ]
    for name in expected:
        assert (W1_V2 / "formulas" / f"{name}.formula.toml").is_file(), (
            f"formulas/{name}.formula.toml is missing"
        )


def test_planner_formula_steps():
    data = load_toml(W1_V2 / "formulas" / "mol-planner-prd.formula.toml")
    step_ids = [s["id"] for s in data["steps"]]
    assert "intake" in step_ids
    assert "handoff" in step_ids


def test_planner_overlay_has_actual_skill():
    assert (W1_V2 / "overlay" / "planner" / ".claude" / "skills" / "actual" / "SKILL.md").is_file()
