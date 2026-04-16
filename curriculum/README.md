# Curriculum Guide

This directory contains the guided steps and facilitation prompts for each session of the Software Factory Intensive. Each session's `README.md` is a self-paced walkthrough — commands, code snippets, and insights — that a participant follows independently.

## Session Types

### WORKSHOPS (W1-W4)

Concept and design sessions. Participants learn a principle, then produce a design artifact (diagram, config file, feedback loop). Workshops build understanding -- they don't deploy running agents.

- **No packs installed** during workshops
- Output is documentation and config files committed to the repo

### LABS (L1-L4)

Hands-on build sessions with committed, running artifacts. Participants install agent packs, run agents against real features, and iterate on config until output meets quality gates.

- **Packs installed incrementally**: L2 adds planner + architect, L3 adds designer + coder, L4 adds reviewer + deployer
- Output is working agent runs with committed artifacts

### CAPSTONE (C1)

Full factory run. All six agents run end-to-end on a new feature, driven entirely by config built across the prior sessions.

- **All 6 packs active**

## Session Structure

Each session directory contains:

| File | Purpose |
|------|---------|
| `README.md` | Walkthrough — goal, estimated duration, guided steps, exit criteria |
| `PROMPT.md` | Facilitation prompt — paste into your AI assistant to guide the session |

The PROMPT.md includes:
- Discovery questions to surface project-specific decisions
- Concrete build steps with Gas City commands
- Suggestions tailored to different project types (React, API, infra, mobile, etc.)
- Config discipline checkpoints

## Progression

```
W1: Individual workflow
 └→ L1: CLAUDE.md + first feature
     └→ W2: 6-agent architecture
         └→ L2: Planner + Architect packs
             └→ L3: Designer + Coder packs
                 └→ W3: Multi-agent coordination
                     └→ L4: Reviewer + Deployer packs
                         └→ W4: Feedback loops
                             └→ C1: Full factory run
```

Each session builds on the previous. Exit criteria gates determine whether you're ready for the next session — unmet gates mean revisit the current session before moving on.

## Significance Matrix

| ID | Type | Significance | Blocks Next? |
|----|------|-------------|-------------|
| W1 | WORKSHOP | Foundational | No |
| L1 | LAB | High | YES |
| W2 | WORKSHOP | Architectural | YES |
| L2 | LAB | High | YES |
| L3 | LAB | Medium-High | YES |
| W3 | WORKSHOP | Critical | YES |
| L4 | LAB | High | YES |
| W4 | WORKSHOP | Strategic | No |
| C1 | CAPSTONE | Summative | No |

## Prerequisite Materials

All participants should complete the [Project Manifest Template](./PROJECT_MANIFEST_TEMPLATE.md) before starting. The manifest covers:
- Tech stack and project structure
- Task inputs (what each agent stage receives)
- Services to connect (GitHub, Jira, cloud providers, etc.)
- Success criteria (per-feature and factory-level)
- Review standards and release criteria

The reference project ([Fired Up Pizza](../reference-project/fired-up-pizza/)) has a completed manifest as an example.
