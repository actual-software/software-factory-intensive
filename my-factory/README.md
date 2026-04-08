# My Factory

This is your workspace for the Software Factory Intensive. Start here with your own project.

## Setup

```bash
# 1. Fill in your project manifest
#    Edit docs/PROJECT_MANIFEST.md with your project details
#    (use curriculum/PROJECT_MANIFEST_TEMPLATE.md as a guide)

# 2. Initialize a Gas City
gc init ~/my-city

# 3. Add this directory as a rig
cd ~/my-city
gc rig add ~/path/to/my-factory

# 4. Agent packs are added incrementally during the labs:
#    L2: gc rig add ~/path/to/my-factory --include packs/planner
#    L2: gc rig add ~/path/to/my-factory --include packs/architect
#    L3: gc rig add ~/path/to/my-factory --include packs/designer
#    L3: gc rig add ~/path/to/my-factory --include packs/coder
#    L4: gc rig add ~/path/to/my-factory --include packs/reviewer
#    L4: gc rig add ~/path/to/my-factory --include packs/deployer
```

## Structure

```
my-factory/
  docs/
    PROJECT_MANIFEST.md   ← Fill this in first
    adr/                  ← Architect output goes here
  work-packages/          ← Planner output
  design/                 ← Designer output
  review-reports/         ← Reviewer output
  release-gates/          ← Deployer output
  feedback-loops/         ← W4 continuous improvement
  CLAUDE.md               ← Agent instructions (fill in during L1)
```

## Reference

See `reference-project/fired-up-pizza/` for a completed example of what your factory produces.
