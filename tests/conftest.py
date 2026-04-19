"""Shared fixtures for planner pack tests."""

import tomllib
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKS_DIR = REPO_ROOT / "activities" / "workshops" / "W3" / "gascity" / "step_0" / "packs"


def load_toml(path: Path) -> dict:
    """Load and parse a TOML file."""
    with open(path, "rb") as f:
        return tomllib.load(f)


@pytest.fixture
def packs_dir() -> Path:
    return PACKS_DIR


@pytest.fixture
def planner_dir() -> Path:
    return PACKS_DIR / "planner"
