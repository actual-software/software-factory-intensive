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

# Maps category to the singular uppercase prefix used in GUIDE filenames.
# e.g. "workshops" -> "WORKSHOP", so W2 -> WORKSHOP_2_GUIDE.md
CATEGORY_GUIDE_PREFIX = {
    "workshops": "WORKSHOP",
    "labs": "LAB",
    "capstone": "CAPSTONE",
    "baseline": "BASELINE",
}


def find_guide(activity):
    """Find the GUIDE.md file for an activity. Returns (Path, content) or (None, None)."""
    category, _ = ACTIVITY_MAP[activity]
    prefix = CATEGORY_GUIDE_PREFIX.get(category)
    if not prefix:
        return None, None
    # Extract the number from the activity (e.g. "W2" -> "2", "L3" -> "3")
    number = activity[1:]
    guide_name = f"{prefix}_{number}_GUIDE.md"
    guide_path = SFI_DIR / "activities" / category / activity / guide_name
    if guide_path.exists():
        return guide_path, guide_path.read_text()
    # Fallback: glob for any *GUIDE*.md in the activity directory
    activity_dir = SFI_DIR / "activities" / category / activity
    guides = list(activity_dir.glob("*GUIDE*"))
    if guides:
        return guides[0], guides[0].read_text()
    return None, None


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


def generate_readme(activity, alias_lower, guide_filename, guide_content=None):
    """Generate the README.md content with self-help prompts."""
    category, slug = ACTIVITY_MAP[activity]
    project_name = f"{alias_lower}-project"
    factory_name = f"{alias_lower}-gc-factory"

    # Extract the activity title from the GUIDE's first heading
    activity_title = f"{activity} Activity"
    if guide_content:
        for line in guide_content.splitlines():
            line = line.strip()
            if line.startswith("# "):
                activity_title = line.lstrip("# ").strip()
                break

    guide_line = ""
    if guide_filename:
        guide_line = f"- **[{guide_filename}]({guide_filename})** — Complete activity guide with deliverables and instructions\n"

    return f"""# {project_name}

> **{activity_title}** — Software Factory Intensive

This is the project workspace for **{activity_title}**. It is managed by a Gas City
factory (`{factory_name}`) with AI agents that plan, design, build, review, and validate work.

{guide_line}
## Directory Structure

```
{slug}/
├── {project_name}/          # This repo — your working project
│   ├── README.md            # This file
│   ├── .gitignore           # Standard ignores
│   ├── .beads/              # Beads issue tracker database
│   └── .claude/             # Claude Code agent configuration
└── {factory_name}/          # Gas City factory workspace
    ├── city.toml            # Factory configuration
    └── packs/actual/        # Agent packs (planner, architect, builder, etc.)
```

## Next Steps

### Check factory status
```bash
gc status --city ~/Projects/factory/{slug}/{factory_name}
```

### See what agents are available
```bash
gc status
```

### Route work to an agent
```bash
gc sling {project_name}/architect "Describe the task here"
gc sling {project_name}/planner "Break down this feature into tasks"
gc sling {project_name}/builder "Implement the login page"
```

### Open the dashboard
```bash
gc dashboard serve --city ~/Projects/factory/{slug}/{factory_name}
# Then open http://localhost:8080
```

### List available formulas
```bash
gc formula list
gc formula show <name>
gc formula cook <name>
```

### Check and manage work items
```bash
bd ready              # Show tasks ready to work on
bd list               # List all issues
bd list --status=in_progress  # See active work
bd show <id>          # View issue details
bd stats              # Project statistics
```

---

## Self-Help: Copy-Paste Prompts

Every task below shows two ways to do it:
- **LLM prompt** — paste into Claude Code or any agent with the factory-activity-agent skill
- **CLI command** — run directly in your terminal to learn the underlying tools

---

### Status & Navigation

**Check all factory statuses**

LLM prompt:
```
/factory-activity-agent status
```
CLI command:
```bash
gc status --city ~/Projects/factory/{slug}/{factory_name}
```

**List all installed activities**

LLM prompt:
```
/factory-activity-agent list
```
CLI command:
```bash
bash skills/factory-activity-agent/scripts/status.sh --list
```

**Check which agents are running in this factory**

LLM prompt:
```
Use factory-activity-agent skill to show me the status of {activity}
```
CLI command:
```bash
gc status --city ~/Projects/factory/{slug}/{factory_name}
```

**List all registered cities**

LLM prompt:
```
What gc cities are registered?
```
CLI command:
```bash
gc cities
```

**View the event log for this factory**

LLM prompt:
```
Show me the gc event log for {activity}
```
CLI command:
```bash
gc events --city ~/Projects/factory/{slug}/{factory_name}
```

---

### Diagnostics & Recovery

**Run full environment diagnostic**

LLM prompt:
```
/factory-activity-agent doctor
```
CLI command:
```bash
gc doctor --fix --city ~/Projects/factory/{slug}/{factory_name}
```

**Run comprehensive environment check (gc, python, bd, cities, packs)**

LLM prompt:
```
Run the factory-activity-agent diagnose script and tell me if anything is broken
```
CLI command:
```bash
bash skills/factory-activity-agent/scripts/diagnose.sh
```

**Factory won't start — check config**

LLM prompt:
```
My {activity} factory won't start. Diagnose and fix it.
```
CLI command:
```bash
gc config --city ~/Projects/factory/{slug}/{factory_name}
gc doctor --fix --city ~/Projects/factory/{slug}/{factory_name}
```

**Restart the gc supervisor service**

LLM prompt:
```
Restart the gc supervisor service for all factories
```
CLI command:
```bash
gc service restart
```

**Stop and restart all agents in this factory**

LLM prompt:
```
Stop and restart all agents in my {activity} factory
```
CLI command:
```bash
gc stop --city ~/Projects/factory/{slug}/{factory_name}
gc start --city ~/Projects/factory/{slug}/{factory_name}
```

**Dashboard won't start (port 8080 in use)**

LLM prompt:
```
The gc dashboard won't start on port 8080. Find what's using it and fix it.
```
CLI command:
```bash
lsof -i :8080
kill <PID>
gc dashboard serve --city ~/Projects/factory/{slug}/{factory_name}
```

---

### Beads Issue Tracker

**See what work is ready**

LLM prompt:
```
What beads issues are ready to work on in {activity}?
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd ready
```

**List all issues**

LLM prompt:
```
Show me all beads issues for {activity}
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd list
```

**Check active work in progress**

LLM prompt:
```
What work is currently in progress in {activity}?
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd list --status=in_progress
```

**View issue details**

LLM prompt:
```
Show me the details of beads issue <id>
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd show <id>
```

**Project statistics**

LLM prompt:
```
Show me beads stats for {activity}
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd stats
```

**Beads database seems broken — diagnose**

LLM prompt:
```
The beads database in {activity} seems broken. Diagnose and fix it.
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd doctor
```

**Sync beads with remote**

LLM prompt:
```
Sync beads for {activity} with the remote
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd dolt pull && bd dolt push
```

**Find stale or orphaned issues**

LLM prompt:
```
Find stale and orphaned beads issues in {activity}
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd stale && bd orphans
```

**Search for an issue by keyword**

LLM prompt:
```
Search beads for "keyword" in {activity}
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd search "keyword"
```

**View blocked issues and their dependencies**

LLM prompt:
```
What issues are blocked in {activity} and why?
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name} && bd blocked
```

---

### Routing Work to Agents

**Send work to the architect**

LLM prompt:
```
/factory-activity-agent sling {activity} architect "Design the architecture for {activity_title}"
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name}
gc sling {project_name}/architect "Design the architecture for {activity_title}"
```

**Send work to the planner**

LLM prompt:
```
/factory-activity-agent sling {activity} planner "Break down {activity_title} into implementation tasks"
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name}
gc sling {project_name}/planner "Break down {activity_title} into implementation tasks"
```

**Send work to the builder**

LLM prompt:
```
/factory-activity-agent sling {activity} builder "Implement the next ready task for {activity_title}"
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name}
gc sling {project_name}/builder "Implement the next ready task for {activity_title}"
```

**Send work to the reviewer**

LLM prompt:
```
/factory-activity-agent sling {activity} reviewer "Review the latest changes for {activity_title}"
```
CLI command:
```bash
cd ~/Projects/factory/{slug}/{project_name}
gc sling {project_name}/reviewer "Review the latest changes for {activity_title}"
```

**List and nudge running sessions**

LLM prompt:
```
List all gc sessions and nudge the stuck one
```
CLI command:
```bash
gc session list --city ~/Projects/factory/{slug}/{factory_name}
gc session nudge <id> "Are you still working on this?"
```

---

### Formulas & Automation

**List available formulas**

LLM prompt:
```
What gc formulas are available in {activity}?
```
CLI command:
```bash
gc formula list --city ~/Projects/factory/{slug}/{factory_name}
```

**Show formula details**

LLM prompt:
```
Show me the details of formula <name>
```
CLI command:
```bash
gc formula show <name> --city ~/Projects/factory/{slug}/{factory_name}
```

**Run a formula**

LLM prompt:
```
Cook the formula <name> in {activity}
```
CLI command:
```bash
gc formula cook <name> --city ~/Projects/factory/{slug}/{factory_name}
```

---

### Reinstall or Reset

**Delete and reinstall this activity (DESTRUCTIVE — removes all files)**

LLM prompt:
```
/factory-activity-agent delete {activity}
/factory-activity-agent install {activity}
```
CLI command:
```bash
bash skills/factory-activity-agent/scripts/delete.sh {activity}
bash skills/factory-activity-agent/scripts/install.sh {activity}
```

---

### Troubleshooting Quick Reference

| Symptom | LLM Prompt | CLI Fix |
|---------|-----------|---------|
| `gc: command not found` | `Is gc installed? Run diagnostics.` | `brew install gastownhall/gascity/gascity` |
| `gc doctor` shows failures | `/factory-activity-agent doctor` | `gc doctor --fix` |
| Dashboard won't start | `The gc dashboard won't start. Fix it.` | `lsof -i :8080 && kill <PID>` |
| `gc sling` hangs | `My sling to {activity} architect is hanging. Diagnose.` | `gc status` then `gc doctor` |
| Factory won't start | `My {activity} factory won't start. Fix it.` | `gc config` then `gc service restart` |
| Beads sync issues | `Sync beads for {activity} with remote` | `bd dolt pull && bd dolt push` |
| Agent not responding | `Restart all agents in {activity}` | `gc stop && gc start` |
| Need command reference | `Show me the gc command reference from the factory-activity-agent skill` | `gc --help` |
"""


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

    # --- Step 8: Copy GUIDE.md, generate README.md, and sling setup task ---
    print("\n##### Inject Activity Guide")
    guide_path, guide_content = find_guide(activity)
    guide_filename = None
    if guide_content and not dry_run:
        guide_filename = guide_path.name
        guide_dest = project_dir / guide_filename
        guide_dest.write_text(guide_content)
        print(f"  Copied {guide_filename} -> {guide_dest}")
    elif guide_content and dry_run:
        guide_filename = guide_path.name
        print(f"[dry-run] Copy {guide_path} -> {project_dir / guide_filename}")
    else:
        print(f"  Warning: No GUIDE.md found for {activity}, skipping guide injection")

    print("\n##### Generate README.md")
    readme_content = generate_readme(activity, alias_lower, guide_filename, guide_content)
    if dry_run:
        print(f"[dry-run] Write README.md to {project_dir / 'README.md'}")
    else:
        (project_dir / "README.md").write_text(readme_content)
        print(f"  Wrote README.md -> {project_dir / 'README.md'}")

    sling_prompt = (
        "Set up this project: "
        "1) Add a .gitignore with canonical best-practice defaults "
        "(OS files, editor files, language build artifacts, env files, node_modules, __pycache__, .DS_Store, etc). "
        "2) A README.md already exists in the project root. Do NOT overwrite or replace it. "
        "Read it and if any section is incomplete or could use project-specific details "
        "(e.g. the Directory Structure section after files are created), "
        "update those sections in place. Preserve all existing content."
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
