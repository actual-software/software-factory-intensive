# Software Factory Manifest: [Project Name]

## Factory Overview

[Project name. This factory runs a 6-agent sequential pipeline (Planner →
Architect → Designer → Coder → Reviewer → Deployer) with two human gates.
Tech stack: [summary from PROJECT_MANIFEST.md].]

## Pipeline Sequence

1. **Planner**
   - Reads: feature request + PROJECT_MANIFEST.md
   - Writes: work-packages/[slug].md

2. **Architect**
   - Reads: Planner work package + Tech Stack section
   - Writes: docs/adr/NNNN-[slug].md

3. **Designer**
   - Reads: Architect ADR + Domain Model section
   - Writes: design/[slug]-spec.md

4. **Coder**
   - Reads: Designer spec + Conventions section
   - Writes: src/ on feature branch [slug]-[feature]

5. **Reviewer**
   - Reads: code diff + Review Standards section
   - Writes: review-reports/[slug]-review.md

6. **Deployer**
   - Reads: Reviewer report + Release Criteria section
   - Writes: release-gates/[slug]-gate.md

## Human Gates

- **Gate 1 — After Architect:** Human approves ADR before Designer runs.
- **Gate 2 — After Reviewer:** Human approves review report before Deployer runs.

## Per-Agent System Prompt Seeds

**Planner:** "[seed]"

**Architect:** "[seed]"

**Designer:** "[seed]"

**Coder:** "[seed]"

**Reviewer:** "[seed]"

**Deployer:** "[seed]"

## Quality Gates

[Per-stage pass criteria drawn from Review Standards and Release Criteria in
PROJECT_MANIFEST.md. Format: "Stage N (AgentName) passes when: [criteria]".]

## Orchestrator Configuration

- Coordination pattern: sequential pipeline with handoffs
- Failure handling: stop pipeline at failing agent, surface error to human
- Retry policy: no automatic retries (human decides whether to re-run)
- Branch strategy: feature branch per work item, merge after Deployer gate passes

## Conventions Reference

[Verbatim copy of Conventions section from PROJECT_MANIFEST.md.]
