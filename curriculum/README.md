# Software Factory Intensive

**Activity Rubric & Framework**

April 21-22, 2025 · Seattle, WA · Actual AI

Reference Project: Fired Up Pizza · 50 participants · 10 pods x 5

| | |
|---|---|
| **Date** | April 21-22, 2025 |
| **Location** | Seattle, WA |
| **Format** | In-Person · Hands-On |
| **Participants** | 50 engineers · 10 pods x 5 |

## Framework & Rubric Legend

| Term | Definition |
|------|-----------|
| **Activity Types** | WORKSHOP = instructor-led concept & design session. LAB = hands-on build with committed artifacts. CAPSTONE = full-factory run assessment. |
| **Grading Scale** | Each criterion scored 0-max points. Partial credit awarded at 50% threshold. Total = 100 pts per activity. |
| **Ranking** | Within each pod (5 participants), activities ranked 1-5. Across pods, ranked 1-10. Top artifact shared with full cohort. |
| **Significance** | Foundational > High > Critical > Summative. Significance determines whether a failed exit-criteria gate blocks the next activity. |
| **Exit Criteria** | Binary gate. Unmet exit criteria trigger a help-desk escalation -- not a skip. Every activity has exactly one exit-criteria statement. |
| **Reference Project** | Fired Up Pizza: a pizza restaurant web app used when participants lack a personal project or need a controlled baseline. |
| **Config Discipline** | Core principle: agent behavior is changed via AGENTS.md / CLAUDE.md / orchestrator.yaml -- NEVER via ad-hoc re-prompting. This is scored in every lab. |

## Activity Overview

| ID | Day | Time | Type | Title |
|----|-----|------|------|-------|
| [W1](workshops/W1-optimize-individual-workflow.md) | Day 1 | 10:30-11:30 | WORKSHOP | Optimize the Individual AI Workflow |
| [L1](labs/L1-build-structured-dev-loop.md) | Day 1 | 11:30-12:30 | LAB | Build a Structured Development Loop |
| [W2](workshops/W2-design-6-agent-factory.md) | Day 1 | 1:30-2:15 | WORKSHOP | Design the 6-Agent Software Factory |
| [L2](labs/L2-deploy-planner-architect.md) | Day 1 | 2:15-3:30 | LAB | Deploy Planner + Architect Agents |
| [L3](labs/L3-deploy-designer-coder.md) | Day 1 | 3:45-5:00 | LAB | Deploy Designer + Coder Agents |
| [W3](workshops/W3-architect-multi-agent-coordination.md) | Day 2 | 9:30-10:15 | WORKSHOP | Architect Multi-Agent Coordination |
| [L4](labs/L4-deploy-reviewer-devops.md) | Day 2 | 10:30-11:45 | LAB | Deploy Reviewer + DevOps Agents |
| [W4](workshops/W4-continuous-improvement-loops.md) | Day 2 | 11:45-12:30 | WORKSHOP | Create Continuous Improvement Loops |
| [C1](capstone/C1-run-factory-end-to-end.md) | Day 2 | 1:30-3:00 | CAPSTONE | Run the Software Factory End-to-End |

## Scoring Summary & Significance Matrix

| ID | Title | Day | Type | Significance | Blocks Next? |
|----|-------|-----|------|-------------|-------------|
| W1 | Optimize the Individual AI Workflow | Day 1 | WORKSHOP | Foundational | No |
| L1 | Build a Structured Development Loop | Day 1 | LAB | High | YES |
| W2 | Design the 6-Agent Software Factory | Day 1 | WORKSHOP | Architectural | YES |
| L2 | Deploy Planner + Architect Agents | Day 1 | LAB | High | YES |
| L3 | Deploy Designer + Coder Agents | Day 1 | LAB | Medium-High | YES |
| W3 | Architect Multi-Agent Coordination | Day 2 | WORKSHOP | Critical | YES |
| L4 | Deploy Reviewer + DevOps Agents | Day 2 | LAB | High | YES |
| W4 | Create Continuous Improvement Loops | Day 2 | WORKSHOP | Strategic | No |
| C1 | Run the Software Factory End-to-End | Day 2 | CAPSTONE | Summative | No |

## The Config Discipline Principle

The single most important discipline this workshop teaches is: **change agent behavior through config, not through ad-hoc prompting.**

AGENTS.md, CLAUDE.md, and orchestrator.yaml are the source of truth for agent behavior. When an agent produces wrong output, the fix is to update its config and re-run -- not to type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

## Prerequisite Materials

All members of the audience should come prepared with a project manifest, which describes the project that they want to apply their gas city to. This is described in the [PROJECT_MANIFEST_TEMPLATE.md](./PROJECT_MANIFEST_TEMPLATE.md).
