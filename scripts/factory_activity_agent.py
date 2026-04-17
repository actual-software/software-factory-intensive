#!/usr/bin/env python3
"""Factory Activity Agent — install or delete Gas City factory setups for activities."""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

SFI_DIR = Path(__file__).resolve().parent.parent
HOME = Path.home()
FACTORY_ROOT = HOME / "Projects" / "factory"

ACTIVITY_MAP = {
    "W1": ("workshops", "workshop_w1"),
    "W2": ("workshops", "workshop_w2"),
    "W3": ("workshops", "workshop_w3"),
    "W4": ("workshops", "workshop_w4"),
    "L1": ("labs", "lab_l1"),
    "L2": ("labs", "lab_l2"),
    "L3": ("labs", "lab_l3"),
    "L4": ("labs", "lab_l4"),
    "C1": ("capstone", "capstone_c1"),
    "B1": ("baseline", "baseline_b1"),
}


def run(cmd, cwd=None, *, dry_run=False, check=True, input_text=None, shell=False):
    """Run a command, or print it in dry-run mode."""
    label = f"  [cwd: {cwd}]" if cwd else ""
    if isinstance(cmd, list):
        display = " ".join(cmd)
    else:
        display = cmd
    if dry_run:
        print(f"[dry-run] {display}{label}")
        return None
    print(f"==> {display}{label}")
    return subprocess.run(
        cmd, cwd=cwd, check=check, input=input_text, text=True, shell=shell,
    )


def resolve_paths(activity):
    """Return (category, slug, alias_lower, project_dir, factory_dir, packs_src)."""
    category, slug = ACTIVITY_MAP[activity]
    alias_lower = activity.lower()
    slug_dir = FACTORY_ROOT / slug
    project_dir = slug_dir / f"{alias_lower}-project"
    factory_dir = slug_dir / f"{alias_lower}-gc-factory"
    packs_src = SFI_DIR / "activities" / category / activity / "gascity" / "step_0" / "packs"
    return category, slug, alias_lower, project_dir, factory_dir, packs_src


def install(activity, dry_run=False):
    _, _, alias_lower, project_dir, factory_dir, packs_src = resolve_paths(activity)

    # Validate packs source exists
    if not packs_src.exists():
        print(f"Error: Activity {activity} has no gascity packs at {packs_src}")
        sys.exit(1)

    city_toml_src = packs_src / "city.toml"
    if not city_toml_src.exists():
        print(f"Error: No city.toml template at {city_toml_src}")
        sys.exit(1)

    # Check if this activity is already installed
    already_installed = (
        not dry_run
        and factory_dir.exists()
        and (factory_dir / "city.toml").exists()
        and (project_dir / ".git").exists()
    )
    if already_installed:
        print(f"\nActivity {activity} is already installed at {factory_dir.parent}")
        print("  Skipping install to preserve user modifications.")
        print(f"  To reinstall, first run: python3 {__file__} delete {activity}")
        return

    # --- Step 1: Init Factory and Project ---
    print("\n##### Init Factory and Project")
    run(["mkdir", "-p", str(project_dir)], dry_run=dry_run)
    run(["git", "init"], cwd=str(project_dir), dry_run=dry_run)
    run(
        f'echo "3" | gc init {factory_dir}',
        dry_run=dry_run, shell=True,
    )

    # --- Step 2: Configure Factory ---
    print("\n##### Configure Factory")
    run(
        ["cp", str(city_toml_src), str(factory_dir / "city.toml")],
        dry_run=dry_run,
    )

    # Specialize city.toml — set workspace name
    city_toml_dest = factory_dir / "city.toml"
    if dry_run:
        print(f'[dry-run] Specialize city.toml: set [workspace] name = "{alias_lower}-gc-factory"')
    else:
        content = city_toml_dest.read_text()
        content = re.sub(
            r'^(name\s*=\s*)"[^"]*"',
            f'\\1"{alias_lower}-gc-factory"',
            content,
            count=1,
            flags=re.MULTILINE,
        )
        city_toml_dest.write_text(content)

    run(
        ["rsync", "-av", f"{packs_src}/", f"{factory_dir}/packs/actual/"],
        dry_run=dry_run,
    )

    # --- Step 3: Register City ---
    print("\n##### Register City")
    run(["gc", "stop"], cwd=str(factory_dir), dry_run=dry_run, check=False)
    run(["gc", "register", str(factory_dir)], dry_run=dry_run, check=False)
    run(["gc", "service", "restart"], dry_run=dry_run, check=False)
    run(["gc", "status"], dry_run=dry_run, check=False)
    run(["gc", "doctor", "--fix"], dry_run=dry_run, check=False)

    # --- Step 4: Add Rig ---
    print("\n##### Add Rig")
    run(["gc", "rig", "add", str(project_dir)], cwd=str(factory_dir), dry_run=dry_run, check=False)

    # Insert includes into the [[rigs]] block that gc rig add just created.
    # The [[rigs]] block has name and path lines — add includes after the path line.
    # Note: [workspace] also has an includes line, so we can't just check for the string globally.
    if dry_run:
        print(f'[dry-run] Insert includes = ["packs/actual/all"] into [[rigs]] block in city.toml')
    else:
        content = city_toml_dest.read_text()
        # Check if the [[rigs]] block already has includes
        rigs_match = re.search(
            r'^\[\[rigs\]\].*?(?=^\[|\Z)',
            content,
            flags=re.MULTILINE | re.DOTALL,
        )
        if rigs_match and "includes" not in rigs_match.group():
            # Insert includes after the path line within the [[rigs]] block
            content = re.sub(
                r'(^\[\[rigs\]\].*?^path\s*=\s*"[^"]*")',
                r'\1\nincludes = ["packs/actual/all"]',
                content,
                count=1,
                flags=re.MULTILINE | re.DOTALL,
            )
            city_toml_dest.write_text(content)

    # --- Step 5: Patch convoy ---
    print("\n##### Patch convoy")
    run(
        ["bd", "config", "set", "types.custom", "convoy"],
        cwd=str(factory_dir), dry_run=dry_run,
    )
    run(
        ["bd", "config", "set", "types.custom", "convoy"],
        cwd=str(project_dir), dry_run=dry_run,
    )

    # --- Step 6: Restart Factory ---
    print("\n##### Restart Factory")
    run(["gc", "stop"], cwd=str(factory_dir), dry_run=dry_run, check=False)
    run(["gc", "start"], cwd=str(factory_dir), dry_run=dry_run, check=False)
    run(["gc", "restart"], cwd=str(factory_dir), dry_run=dry_run, check=False)

    # --- Step 7: Start Dashboard ---
    print("\n##### Startup Gascity Dashboard")
    if dry_run:
        print(f"[dry-run] gc dashboard serve  [cwd: {factory_dir}]")
    else:
        subprocess.Popen(
            ["gc", "dashboard", "serve"],
            cwd=str(factory_dir),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    print("\n  Dashboard: http://localhost:8080")

    # --- Step 8: Verify suggestion ---
    sling_prompt = (
        "Set up this project: "
        "1) Add a .gitignore with canonical best-practice defaults "
        "(OS files, editor files, language build artifacts, env files, node_modules, __pycache__, .DS_Store, etc). "
        "2) Add a README.md that describes this as the "
        f"{alias_lower}-project workspace for the {activity} activity in the Software Factory Intensive, "
        "and include a Next Steps section with instructions to explore the factory agents."
    )
    print("\n##### Sling Setup Task")
    run(
        ["gc", "sling", f"{alias_lower}-project/architect", sling_prompt],
        cwd=str(project_dir), dry_run=dry_run, check=False,
    )


def delete(activity, dry_run=False):
    _, slug, _, _, factory_dir, _ = resolve_paths(activity)
    slug_dir = FACTORY_ROOT / slug

    print(f"\n##### Deleting activity {activity}")

    # Stop factory
    if factory_dir.exists() or dry_run:
        run(["gc", "stop"], cwd=str(factory_dir), dry_run=dry_run, check=False)

    # Unregister
    run(["gc", "unregister", str(factory_dir)], dry_run=dry_run, check=False)

    # Remove directories
    if dry_run:
        print(f"[dry-run] rm -rf {slug_dir}")
    else:
        if slug_dir.exists():
            shutil.rmtree(slug_dir)
            print(f"  Removed {slug_dir}")
        else:
            print(f"  {slug_dir} does not exist, nothing to remove.")


def main():
    parser = argparse.ArgumentParser(
        description="Install or delete Gas City factory setups for activities.",
    )
    parser.add_argument(
        "action",
        choices=["install", "delete"],
        help="Action to perform",
    )
    parser.add_argument(
        "activity",
        choices=sorted(ACTIVITY_MAP.keys()),
        help="Activity alias (e.g. W2, L2, C1)",
    )
    parser.add_argument(
        "--mode",
        choices=["dry-run"],
        default=None,
        help="Optional mode (dry-run prints commands without executing)",
    )

    args = parser.parse_args()
    dry_run = args.mode == "dry-run"

    if not dry_run and not shutil.which("gc"):
        print("Error: 'gc' (Gas City CLI) not found on PATH.")
        sys.exit(1)

    if args.action == "install":
        install(args.activity, dry_run=dry_run)
    elif args.action == "delete":
        delete(args.activity, dry_run=dry_run)


if __name__ == "__main__":
    main()
