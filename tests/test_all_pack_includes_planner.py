"""Test that the all/pack.toml composition includes the planner pack."""

from conftest import PACKS_DIR, load_toml


def test_all_pack_includes_planner():
    data = load_toml(PACKS_DIR / "all" / "pack.toml")
    includes = data["pack"]["includes"]
    assert "../planner" in includes
