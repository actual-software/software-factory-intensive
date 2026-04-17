# Curriculum Guide

This directory contains the guided steps for each session of the Software Factory Intensive. Each session's `README.md` is a self-paced walkthrough — commands, code snippets, and insights — that a participant follows independently. Every README also includes an **Agent Facilitation Guide** near the top: if a participant asks an AI coding agent to walk them through the session, the guide tells the agent how to ask guiding questions, verify understanding at pivotal steps, and enforce the session's exit criteria — additive to the step-by-step instructions, not a replacement.

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

Each session directory contains a single `README.md` — the walkthrough — with **Agent Guide** callouts interleaved alongside the participant steps. The callouts are what you'd previously find in a separate `PROMPT.md`; they now live inline next to the steps they apply to, so an agent walking a participant through the session gets the right guidance at the right moment.

Each README includes:
- A short preamble at the top telling an agent to look for `> **Agent Guide:** …` callouts.
- Inline Agent Guide callouts at pivotal steps — guiding questions to ask, config-discipline anti-patterns to flag.
- A **Concept Check** block just before the Exit Criteria, listing the core ideas the participant must articulate before moving to the next session.

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

## Prerequisite Materials

Before starting the curriculum, write a **Project Overview** for the software project you'll build your factory around. Use [`PROJECT_OVERVIEW_TEMPLATE.md`](./PROJECT_OVERVIEW_TEMPLATE.md) as the starting point — it's a short five-section brief (what it does, goals, scope, users, domain context). Keep it terse; the manifest is where structure goes.

The overview is what *you* write. The structured [`PROJECT_MANIFEST_TEMPLATE.md`](./PROJECT_MANIFEST_TEMPLATE.md) — a skeleton every factory agent reads — is generated from your overview by your local coding agent during L1. Don't hand-fill the manifest yourself.

The reference project ([Fired Up Pizza](../reference-project/fired-up-pizza/)) has both:
- [`docs/PROJECT_OVERVIEW.md`](../reference-project/fired-up-pizza/docs/PROJECT_OVERVIEW.md) — the kind of brief you should arrive with
- [`docs/PROJECT_MANIFEST.md`](../reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md) — what your agent will generate from it
