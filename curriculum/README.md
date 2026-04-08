# Curriculum Guide

This directory contains the rubrics, instructions, and facilitation prompts for each session of the Software Factory Intensive.

## Session Types

### WORKSHOPS (W1-W4)

Instructor-led concept and design sessions. Participants learn a principle, then produce a design artifact (diagram, config file, feedback loop). Workshops build understanding -- they don't deploy running agents.

- **No packs installed** during workshops
- Output is documentation and config files committed to the repo
- Scored on clarity and completeness of design artifacts

### LABS (L1-L4)

Hands-on build sessions with committed, running artifacts. Participants install agent packs, run agents against real features, and iterate on config until output meets quality gates.

- **Packs installed incrementally**: L2 adds planner + architect, L3 adds designer + coder, L4 adds reviewer + deployer
- Output is working agent runs with committed artifacts
- Scored on runs-to-passing and config discipline (no ad-hoc prompting)

### CAPSTONE (C1)

Full factory run assessment. All six agents run end-to-end on a new feature, driven entirely by config built across Days 1-2.

- **All 6 packs active**
- Scored on stages reached, zero ad-hoc prompts, and report quality

## Session Structure

Each session directory contains:

| File | Purpose |
|------|---------|
| `README.md` | Rubric — goal, acceptance criteria, evaluation table, exit criteria |
| `PROMPT.md` | Facilitation prompt — paste into Claude Code to guide the session |

The PROMPT.md includes:
- Discovery questions to surface project-specific decisions
- Concrete build steps with Gas City commands
- Suggestions tailored to different project types (React, API, infra, mobile, etc.)
- Config discipline checkpoints

## Progression

```
Day 1                                          Day 2
─────                                          ─────
W1: Individual workflow                        W3: Multi-agent coordination
 └→ L1: CLAUDE.md + first feature              └→ L4: Reviewer + Deployer packs
     └→ W2: 6-agent architecture                   └→ W4: Feedback loops
         └→ L2: Planner + Architect packs              └→ C1: Full factory run
             └→ L3: Designer + Coder packs
```

Each session builds on the previous. Exit criteria gates determine whether a participant is ready for the next session -- unmet gates trigger help-desk escalation, not skips.

## Scoring

| Scale | Description |
|-------|-------------|
| 0 pts | Not attempted or missing |
| 50% | Partial -- present but incomplete |
| 100% | Complete -- meets all criteria |

Each activity is scored out of 100 points. Rankings are within pods (1-5) and across pods (1-10). Top artifacts are shared with the full cohort.

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

All participants should complete the [Project Manifest Template](./PROJECT_MANIFEST_TEMPLATE.md) before arriving. The manifest covers:
- Tech stack and project structure
- Task inputs (what each agent stage receives)
- Services to connect (GitHub, Jira, cloud providers, etc.)
- Success criteria (per-feature and factory-level)
- Review standards and release criteria

The reference project ([Fired Up Pizza](../reference-project/fired-up-pizza/)) has a completed manifest as an example.
