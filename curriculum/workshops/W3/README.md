# W3 · Architect Multi-Agent Coordination

> **Goal:** Learn how to orchestrate multiple agents working together in Gas City—understanding when agents run sequentially, in parallel, or with human gates.

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 9:30 - 10:15 |
| **Type** | WORKSHOP |
| **Deliverable** | Coordination patterns documented for your factory |

---

## Three Core Coordination Patterns

### 1. Sequential Pipeline
**When:** Each stage depends on the previous stage completing.

**Example:** Planner → Architect → Designer → Coder

**In Gas City:**
```bash
# Create beads with dependencies
bd create "Plan feature" --id plan-123
bd create "Architect feature" --depends-on plan-123 --id arch-456
bd create "Design feature" --depends-on arch-456 --id design-789

# Sling to agents
gc sling planner plan-123
gc sling architect arch-456  # Waits until plan-123 closes
gc sling designer design-789  # Waits until arch-456 closes
```

**Use When:**
- Output of Stage N is required input for Stage N+1
- No way to parallelize work
- Order matters

---

### 2. Parallel Fan-Out
**When:** Multiple agents can work simultaneously on independent tasks.

**Example:** After Designer creates plan, Coder implements WHILE DevOps prepares infrastructure.

**In Gas City:**
```bash
# Create parent bead
bd create "Implement feature" --id feature-999

# Create parallel child beads
bd create "Write code" --depends-on feature-999 --id code-111
bd create "Setup infrastructure" --depends-on feature-999 --id infra-222

# Both run in parallel
gc sling coder code-111 &
gc sling devops infra-222 &
```

**Use When:**
- Tasks are independent
- No shared resources that conflict
- Faster completion matters

**Caution:**
- Ensure no race conditions (e.g., both agents modifying same file)
- Have a "join" point where parallel work merges

---

### 3. Human-in-the-Loop Gate
**When:** Critical decision needs human judgment before proceeding.

**Example:** Architect proposes expensive infrastructure change → Human approves → DevOps implements.

**In Gas City:**
```bash
# Create bead that blocks until human acts
bd create "Review architecture proposal" \
  --requires-approval \
  --assignee austin@actual.ai \
  --id review-333

# Agent creates proposal
gc sling architect review-333

# Agent posts result, bead enters "needs approval" state
bd show review-333
# Status: Waiting for approval from austin@actual.ai

# Human reviews and approves
bd approve review-333 --comment "Approved, proceed with migration"

# Next stage unblocks
bd create "Implement migration" --depends-on review-333 --id migrate-444
gc sling devops migrate-444
```

**Use When:**
- Decision has significant cost/risk
- Requires domain expertise agents don't have
- Compliance/security review needed
- Creative direction requires taste judgment

---

## Orchestrator Configuration

Gas City uses `orchestrator.yaml` to define coordination rules.

**Example orchestrator.yaml:**
```yaml
# Sequential pipeline for standard feature development
pipelines:
  - name: "feature-pipeline"
    trigger: 
      bead_label: "feature-request"
    stages:
      - agent: planner
        output: work-package
      - agent: architect
        depends_on: [planner]
        output: adr
      - agent: designer
        depends_on: [architect]
        output: design-doc
      - agent: coder
        depends_on: [designer]
        output: code
      - agent: reviewer
        depends_on: [coder]
        gate: approval_required
      - agent: devops
        depends_on: [reviewer]
        output: deployment

# Parallel work for hotfixes (skip planning/design)
  - name: "hotfix-pipeline"
    trigger:
      bead_label: "hotfix"
    stages:
      - agent: coder
        output: code
      - agent: reviewer
        depends_on: [coder]
        parallel: true
      - agent: security-scan
        depends_on: [coder]
        parallel: true
      - agent: devops
        depends_on: [reviewer, security-scan]  # Join point
        gate: manual_deploy

# Human gates for high-risk changes
gates:
  - name: "architecture-review"
    required_for: ["database-migration", "api-breaking-change"]
    approvers: ["austin@actual.ai", "team-lead@actual.ai"]
    
  - name: "production-deploy"
    required_for: ["production"]
    approvers: ["devops-oncall"]
```

---

## Workshop Activity: Design Your Coordination

### Part 1: Identify Patterns in Your Feature (15 min)

**For the feature you designed in W2, answer:**

1. **Which stages MUST run sequentially?**
   - List stage pairs where Stage B absolutely needs Stage A's output
   - Example: "Coder needs Designer's plan"

2. **Which stages COULD run in parallel?**
   - List stages that don't depend on each other
   - Example: "Writing tests in parallel with writing docs"

3. **Where should human gates go?**
   - Architectural decisions with cost implications?
   - Security-sensitive changes?
   - Production deployments?
   - Example: "Human approves ADR before Designer starts"

**Deliverable:** Coordination map for your feature.

---

### Part 2: Write Orchestrator Rules (15 min)

**Create a simplified orchestrator.yaml** for your feature:

```yaml
pipelines:
  - name: "[your-feature]-pipeline"
    trigger:
      bead_label: "[your-label]"
    stages:
      - agent: [agent-1]
        output: [artifact-1]
      
      - agent: [agent-2]
        depends_on: [[agent-1]]
        gate: [approval_required | none]
        output: [artifact-2]
      
      # ... continue for all 6 agents

gates:
  - name: "[gate-name]"
    required_for: ["[stage-label]"]
    approvers: ["[your-email]"]
```

**Test your logic:**
- Can any stage start before its dependencies finish? (Should be NO)
- Do parallel stages join before the next sequential stage? (Should be YES)
- Are human gates at meaningful decision points? (Should be YES)

---

## Deciding Where to Put Human Gates

### ✅ Good Reasons for Human Gates
- **High cost**: "This will spin up 20 new servers"
- **Irreversible**: "This deletes customer data"
- **Requires taste**: "Choose between these 3 UX designs"
- **Compliance**: "Legal must review this contract change"

### ❌ Bad Reasons for Human Gates
- **"Just to be safe"**: Adds friction without clear benefit
- **Lack of trust in agents**: Fix agent config instead
- **"We've always done it this way"**: Automation is the goal
- **Checking every step**: Defeats purpose of software factory

### The Test
Ask: "If this step ran at 3am when I'm asleep, what's the worst that could happen?"

- **Minor bug gets deployed**: Acceptable (can rollback), no gate needed
- **$10,000 AWS bill**: Not acceptable, gate required
- **Wrong button color shipped**: Acceptable (can fix next deploy), no gate
- **Customer PII exposed**: Not acceptable, security review gate required

---

## Recommended Prompts

### When Designing Coordination
```
I'm building a software factory with 6 agents: Planner, Architect, Designer, Coder, Reviewer, DevOps.

My feature: [describe feature]

Help me determine:
1. Which stages must run sequentially (Stage B needs Stage A's output)
2. Which stages could run in parallel (independent work)
3. Where I should put human approval gates (high-risk decisions)

For each human gate, explain what risk it mitigates.
```

### When Writing Orchestrator Config
```
I need an orchestrator.yaml config for Gas City.

My coordination map:
- Sequential: [list sequential dependencies]
- Parallel: [list parallel stages]
- Human gates: [list where gates go]

Generate an orchestrator.yaml file following Gas City's format.
Include comments explaining each coordination decision.
```

---

## Common Coordination Mistakes

### Mistake 1: Too Many Human Gates
**Symptom:** Every stage requires approval  
**Problem:** Factory can't run autonomously  
**Fix:** Only gate truly high-risk decisions  

### Mistake 2: Missing Dependencies
**Symptom:** Coder starts before Designer finishes  
**Problem:** Coder makes architectural decisions without guidance  
**Fix:** Explicit `depends_on` in orchestrator.yaml  

### Mistake 3: Parallel Work on Same Files
**Symptom:** Two agents modify same code simultaneously  
**Problem:** Merge conflicts, wasted work  
**Fix:** Ensure parallel work touches different files  

### Mistake 4: No Join Point After Fan-Out
**Symptom:** Parallel stages complete, but next stage starts before all finish  
**Problem:** Missing work, incomplete context  
**Fix:** Use `depends_on: [agent-1, agent-2]` to wait for all  

---

## Exit Criteria

✅ Coordination map identifies sequential, parallel, and gated stages  
✅ Orchestrator.yaml drafted for your feature  
✅ Human gates justified with risk analysis  

---

## Next Steps

In **L4**, you'll implement this coordination using Gas City's orchestrator. Your coordination design will determine how smoothly your factory runs end-to-end.
