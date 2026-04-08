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

## Activity Overview

Each session has a README (rubric, instructions, evaluation) and a PROMPT.md (paste into Claude Code to facilitate the session).

| ID | Day | Time | Type | Title | Packs Used |
|----|-----|------|------|-------|------------|
| [W1](workshops/W1/) | Day 1 | 10:30-11:30 | WORKSHOP | Optimize the Individual AI Workflow | -- |
| [L1](labs/L1/) | Day 1 | 11:30-12:30 | LAB | Build a Structured Development Loop | -- |
| [W2](workshops/W2/) | Day 1 | 1:30-2:15 | WORKSHOP | Design the 6-Agent Software Factory | -- |
| [L2](labs/L2/) | Day 1 | 2:15-3:30 | LAB | Deploy Planner + Architect Agents | `packs/planner`, `packs/architect` |
| [L3](labs/L3/) | Day 1 | 3:45-5:00 | LAB | Deploy Designer + Coder Agents | `packs/designer`, `packs/coder` |
| [W3](workshops/W3/) | Day 2 | 9:30-10:15 | WORKSHOP | Architect Multi-Agent Coordination | -- |
| [L4](labs/L4/) | Day 2 | 10:30-11:45 | LAB | Deploy Reviewer + DevOps Agents | `packs/reviewer`, `packs/deployer` |
| [W4](workshops/W4/) | Day 2 | 11:45-12:30 | WORKSHOP | Create Continuous Improvement Loops | -- |
| [C1](capstone/C1/) | Day 2 | 1:30-3:00 | CAPSTONE | Run the Software Factory End-to-End | All 6 (or `packs/fired-up-pizza`) |

## The Config Discipline Principle

The single most important discipline this workshop teaches is: **change agent behavior through config, not through ad-hoc prompting.**

AGENTS.md, CLAUDE.md, and orchestrator.yaml are the source of truth for agent behavior. When an agent produces wrong output, the fix is to update its config and re-run -- not to type a correction into the chat. This discipline is the bridge between individual AI use and a factory that runs 24/7 without a human at the keyboard.

## Prerequisite Materials

All participants should come prepared with a completed [Project Manifest](./PROJECT_MANIFEST_TEMPLATE.md), which describes the project they want to build their software factory around. The manifest defines tech stack, conventions, task inputs, services to connect, review standards, release criteria, and success metrics.

## Agent Packs

Each factory agent is its own Gas City pack, adoptable incrementally across the labs:

| Pack | Agent | Added In |
|------|-------|----------|
| `packs/planner` | Planner — feature requests → work packages | L2 |
| `packs/architect` | Architect — work packages → ADRs | L2 |
| `packs/designer` | Designer — work packages + ADRs → component specs | L3 |
| `packs/coder` | Coder — specs → implementation | L3 |
| `packs/reviewer` | Reviewer — code review against specs + standards | L4 |
| `packs/deployer` | Deployer — release gate evaluation | L4 |
| `packs/fired-up-pizza` | All 6 bundled (for reference project) | C1 |
