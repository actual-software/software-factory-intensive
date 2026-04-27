"""Test that factory_activity_agent.py default_sling_target points to planner."""

import re

from conftest import REPO_ROOT


def _read_agent_script() -> str:
    return (REPO_ROOT / "scripts" / "factory_activity_agent.py").read_text()


def test_default_sling_target_is_planner():
    content = _read_agent_script()
    # Dry-run print line
    dry_run_matches = re.findall(r'default_sling_target\s*=\s*.*?/(\w+)"', content)
    assert len(dry_run_matches) >= 2, "Expected at least 2 default_sling_target references"
    for match in dry_run_matches:
        assert match == "planner", f"Expected 'planner' but found '{match}'"


def test_default_sling_target_not_architect():
    content = _read_agent_script()
    # Ensure no reference to /architect" in sling target lines
    sling_lines = [
        line for line in content.splitlines()
        if "default_sling_target" in line and "architect" in line.lower()
    ]
    assert len(sling_lines) == 0, f"Found architect references in sling target: {sling_lines}"
