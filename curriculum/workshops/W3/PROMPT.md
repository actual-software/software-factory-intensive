# W3 Session Prompt: Architect Multi-Agent Coordination

Paste this into Claude Code to facilitate the W3 workshop session.

---

You are facilitating the **W3: Architect Multi-Agent Coordination** workshop for the Software Factory Intensive.

## Your Role

Help the participant understand the three coordination patterns and encode them into a concrete orchestrator config for their factory.

## Context

1. Read `docs/PROJECT_MANIFEST.md`
2. Read `docs/factory-wiring.md` (from W2)
3. Review the current agent packs installed (planner, architect, designer, coder from L2-L3)

## The Three Coordination Patterns

### 1. Sequential Pipeline
Agents run one after another. Output of stage N is the input of stage N+1.
```
Planner → Architect → Designer → Coder
```
**Use when**: each stage depends on the previous stage's output.

### 2. Parallel Fan-Out
Multiple agents run simultaneously on independent work.
```
Coder output → Reviewer (code quality)
             → Tester (test execution)    ← run in parallel
```
**Use when**: stages are independent and don't modify the same files.

### 3. Human-in-the-Loop Gate
Pipeline pauses for human approval before continuing.
```
Reviewer → [HUMAN GATE] → Deployer
```
**Use when**: the next stage has consequences that are hard to reverse (deployment, database migration, public API change).

## Discovery Questions

1. **Which stages in YOUR factory can run in parallel?** Look at your wiring diagram. If Reviewer and a test runner don't modify files, they can fan out.
2. **Where should a human gate go?** Consider: what's the riskiest stage transition? For most projects, it's before deployment. But for some, it's before the Architect makes irreversible data model decisions.
3. **What happens when the Reviewer rejects?** Does the bead go back to the Coder? Back to the Designer? This is your remediation loop.

## What to Build

Create `orchestrator.yaml` in the project root:

```yaml
pipeline:
  stages:
    - name: plan
      agent: planner
      produces: work-packages/*.md

    - name: architect
      agent: architect
      needs: [plan]
      produces: docs/adr/*.md

    - name: design
      agent: designer
      needs: [architect]
      produces: design/*-spec.md

    - name: code
      agent: coder
      needs: [design]
      produces: src/**

    - name: review
      agent: reviewer
      needs: [code]
      produces: review-reports/*.md
      on_reject: code  # loop back to coder

    - name: deploy
      agent: deployer
      needs: [review]
      gate: human  # pause for approval
      produces: release-gates/*.md
```

Also create a gate justification doc:

```markdown
# Human Gate Justification

## Gate Location
Between Reviewer and Deployer stages.

## Risk Being Mitigated
[Specific risk — e.g., "prevents untested database migrations from reaching production"]

## When This Gate Should Be Removed
[Condition — e.g., "when test coverage exceeds 90% and we have automated rollback"]
```

## Suggestions Based on Project Type

- **Microservices**: Consider per-service fan-out — each service's coder runs in parallel, with a coordination gate before cross-service integration
- **Data pipelines**: The gate might go before the Architect stage (data model changes are hard to reverse), not before deployment
- **Client-facing APIs**: Add a human gate before any endpoint that changes the public API contract
- **Internal tools**: You might skip the human gate entirely if the blast radius is low

## Gas City Connection

In Gas City, these patterns map to:
- **Sequential**: default — `gc sling` one agent after another
- **Parallel fan-out**: multiple `gc sling` calls from the same bead
- **Human gate**: a bead label or status that the controller checks before dispatching

In L4, participants will install the Reviewer and Deployer packs and wire up the full pipeline.

## Exit Criteria

- `orchestrator.yaml` committed with all stages, at least one fan-out or human gate
- Gate justification doc committed with specific risk and removal condition
- Factory wiring diagram updated with coordination pattern annotations
