# Fired Up Pizza

Reference project for the Software Factory Intensive workshop. A pizza restaurant web app built entirely by a 6-agent Gas City software factory.

## Quick Start

### 1. Set up Gas City

```bash
# Install Gas City (macOS)
brew install gastownhall/gascity/gascity

# Initialize a city
gc init ~/pizza-factory
```

### 2. Add agents incrementally (or all at once)

```bash
cd ~/pizza-factory

# Option A: Add agents one at a time (matches the lab progression)
gc rig add /path/to/fired-up-pizza --include /path/to/packs/planner
gc rig add /path/to/fired-up-pizza --include /path/to/packs/architect
# ... add designer, coder, reviewer, deployer as needed

# Option B: Add all 6 agents at once
gc rig add /path/to/fired-up-pizza --include /path/to/packs/fired-up-pizza
```

### 3. Import the ticket backlog

```bash
cd /path/to/fired-up-pizza
bash /path/to/packs/fired-up-pizza/scripts/import-tickets.sh tickets.md
bd list
```

### 4. Run the factory

```bash
# Sling the first ticket to the planner
gc sling fired-up-pizza/planner <bead-id>

# Watch the pipeline
gc events --follow
gc session list
gc session peek <agent>      # Watch an agent work
```

## Project Structure

```
fired-up-pizza/
  src/                        # Application code (Coder output)
  docs/
    PROJECT_MANIFEST.md       # Tech stack, conventions, review standards, release criteria, success metrics
    adr/                      # Architecture Decision Records (Architect output)
  work-packages/              # Planner output
  design/                     # Designer output
  review-reports/             # Reviewer output
  release-gates/              # Deployer output
  tickets.md                  # Initial feature backlog
  CLAUDE.md                   # Agent instructions
  package.json                # Node.js project
```

## The 6-Agent Pipeline

| Stage | Agent | Input | Output |
|-------|-------|-------|--------|
| 1. Plan | Planner | Feature request | `work-packages/<slug>.md` |
| 2. Architect | Architect | Work package | `docs/adr/NNNN-<slug>.md` |
| 3. Design | Designer | Work package + ADR | `design/<slug>-spec.md` |
| 4. Code | Coder | Component spec | `src/` implementation |
| 5. Review | Reviewer | Code diff + spec | `review-reports/<slug>-review.md` |
| 6. Deploy | Deployer | Review report | `release-gates/<slug>-gate.md` |

## Adapting for Your Project

This reference is designed to be forked and modified:

1. Replace `docs/PROJECT_MANIFEST.md` with your project's tech stack and domain model
2. Replace `tickets.md` with your feature backlog
3. Adjust agent prompts in `packs/fired-up-pizza/prompts/` for your conventions
4. Update `docs/REVIEW_POLICY.md` and `docs/RELEASE_CRITERIA.md` for your standards
5. Re-run the factory against your codebase

The agent prompts, manifests, and policies are the config layer. Change behavior by editing these files — not by re-prompting agents.

## Workshop Curriculum

This project is used across the Software Factory Intensive:

- **W1/L1**: Individual workflow optimization against this codebase
- **W2/L2**: Deploy Planner + Architect agents (produces work packages + ADRs)
- **L3**: Deploy Designer + Coder agents (produces specs + implementation)
- **W3/L4**: Orchestration and Reviewer + Deployer agents
- **C1**: Full factory run for a new feature (Order History page)
