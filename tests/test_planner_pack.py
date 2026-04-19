"""Tests for the planner agent pack structure and configuration."""

import os
import stat

from conftest import PACKS_DIR, load_toml


PLANNER_DIR = PACKS_DIR / "planner"


# --- pack.toml ---


def test_pack_toml_exists():
    assert (PLANNER_DIR / "pack.toml").is_file()


def test_pack_toml_required_fields():
    data = load_toml(PLANNER_DIR / "pack.toml")
    assert data["pack"]["name"] == "actual-planner"
    assert data["pack"]["schema"] == 1

    agent = data["agent"][0]
    assert agent["name"] == "planner"
    assert agent["scope"] == "rig"
    assert agent["wake_mode"] == "fresh"
    assert agent["prompt_template"] == "prompts/planner.md.tmpl"
    assert agent["overlay_dir"] == "overlays/default"

    assert data["formulas"]["dir"] == "formulas"


# --- Order gate ---


def test_order_toml_triggers_on_needs_plan():
    data = load_toml(PLANNER_DIR / "formulas" / "orders" / "planner-intake" / "order.toml")
    order = data["order"]
    assert order["gate"] == "condition"
    assert "needs-plan" in order["check"]
    assert order["formula"] == "mol-planner-prd"
    assert order["pool"] == "planner"


# --- Formula ---


def test_formula_has_required_steps():
    data = load_toml(PLANNER_DIR / "formulas" / "mol-planner-prd.formula.toml")
    step_ids = [s["id"] for s in data["steps"]]
    assert "intake" in step_ids
    assert "research" in step_ids
    assert "draft-prd" in step_ids
    assert "handoff" in step_ids


def test_formula_handoff_labels():
    data = load_toml(PLANNER_DIR / "formulas" / "mol-planner-prd.formula.toml")
    handoff_step = next(s for s in data["steps"] if s["id"] == "handoff")
    desc = handoff_step["description"]
    assert "needs-architecture" in desc
    assert "needs-design" in desc


# --- Prompts ---


def test_prompt_template_exists():
    assert (PLANNER_DIR / "prompts" / "planner.md.tmpl").is_file()


def test_prompt_simple_exists():
    assert (PLANNER_DIR / "prompts" / "planner.md").is_file()


# --- Doctor & Commands ---


def test_doctor_script_exists_and_executable():
    path = PLANNER_DIR / "doctor" / "check-planner.sh"
    assert path.is_file()
    mode = os.stat(path).st_mode
    assert mode & stat.S_IXUSR, "check-planner.sh must be executable"


def test_status_command_exists():
    assert (PLANNER_DIR / "commands" / "status.sh").is_file()


# --- Overlay ---


def test_overlay_settings_json_exists():
    assert (PLANNER_DIR / "overlays" / "default" / ".claude" / "settings.json").is_file()


def test_overlay_has_actual_skill():
    assert (PLANNER_DIR / "overlays" / "default" / ".claude" / "skills" / "actual" / "SKILL.md").is_file()


def test_overlay_no_tracker_skill():
    tracker_dir = PLANNER_DIR / "overlays" / "default" / ".claude" / "skills" / "tracker-to-beads"
    assert not tracker_dir.exists(), "Planner should not ship tracker-to-beads skill"
