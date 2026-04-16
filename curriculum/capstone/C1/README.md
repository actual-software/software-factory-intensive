# C1 · Run the Software Factory End-to-End

> **Goal:** Execute a complete, autonomous factory run from feature request to deployed code—validating that all agents, coordination, and feedback loops work together without manual intervention.

| | |
|---|---|
| **Estimated duration** | ~90 minutes |
| **Type** | CAPSTONE |
| **Deliverable** | Deployed feature + Factory Run Report |

---

## What Success Looks Like

```
[T+0min] Feature request submitted as bead
[T+5min] Planner produces work package
[T+10min] Architect produces ADR
[T+15min] Designer produces implementation plan
[T+45min] Coder produces code + tests
[T+60min] Reviewer approves PR
[T+75min] DevOps deploys to staging
[T+85min] Smoke tests pass
[T+90min] DevOps deploys to production
```

**Zero ad-hoc prompts. Zero manual code fixes. Pure config-driven execution.**

---

## Prerequisites

✅ All labs complete (L1-L4): 6 agents configured
✅ All workshops complete (W2-W4): Coordination + feedback designed
✅ Gas City running with `orchestrator.yaml` configured
✅ Project repository set up as rig
✅ Deployment pipeline ready (staging + production) — or at minimum CI + a sandbox deploy target
✅ (Optional) [`packs/workshop`](../../../packs/workshop/) integrations connected — enables ticket sync, observability, and status reporting to external systems
✅ (Optional) `actual adr-bot` has been run so `CLAUDE.md` contains tailored industry ADRs alongside project ADRs

---

## Gas City Capabilities Used in the Capstone

This is the first session where you use Gas City's full orchestration surface, not just individual `gc sling` calls.

| Command | What it does |
|---------|--------------|
| `gc orchestrate --pipeline feature-pipeline --bead <id>` | Kick off the orchestrator.yaml pipeline from W3 |
| `bd list --status needs-approval` | Poll for human-gate beads |
| `bd approve <bead> --comment "..."` | Release a human gate |
| `bd event list --since 1h` | Inspect feedback signals the factory emitted |
| `gc events --follow` | Stream every city-level event |
| `gc session list` / `gc session peek <agent>` | See and attach to any running agent session |

If your orchestrator isn't wired up, you can still run the capstone **manually sequenced** — sling each stage's bead by hand after the previous bead closes. Report this in your Factory Run Report under "Config Discipline."

---

## Walkthrough: Use the Composite Pack for One-Shot Setup

If you've made it this far, you've installed six packs individually (`planner`, `architect`, `designer`, `coder`, `reviewer`, `deployer`). The [`packs/fired-up-pizza/`](../../../packs/fired-up-pizza/) composite pack bundles all six so that a new participant (or your production rig next Monday) can bootstrap in one command:

```bash
gc rig add ~/path/to/your-repo --include /path/to/software-factory-intensive/packs/fired-up-pizza
```

Read the bundle's [`pack.toml`](../../../packs/fired-up-pizza/pack.toml) — it's 20 lines, mostly `includes = ["../planner", ...]` — to understand how composite packs work. Then build a similar composite for your own factory (`packs/my-factory/pack.toml`) so future participants installing your rig get all 6 agents with one call.

---

## Reference: What a Successful Capstone Looks Like

The reference project's directory state after a completed capstone run:

```
reference-project/fired-up-pizza/
  work-packages/order-history.md                ← Planner output
  docs/adr/0005-order-history-storage.md         ← Architect output
  design/order-history-spec.md                   ← Designer output
  src/features/order-history/*                   ← Coder output (branch merged)
  review-reports/order-history-review.md         ← Reviewer output
  release-gates/order-history-gate.md            ← Deployer output
  factory-runs/capstone-2026-04-22-order-history.md  ← Your report
```

Seven artifacts. Each one references the previous by ID. Compare your run's output to this shape — if any directory stays empty, you have a stage that didn't run or an output-path mismatch.

---

## The Capstone Challenge

### Your Mission
Implement a NEW feature (not loyalty points—pick something fresh) using ONLY your factory configuration. No manual coding allowed.

**Feature Requirements:**
- Small enough to complete in 90 minutes
- Touches backend + frontend (or equivalent for your stack)
- Requires at least one architectural decision
- Has testable acceptance criteria

**Example Features:**
- "Add export to CSV button on reports page"
- "Implement forgot password flow"
- "Add dark mode toggle to settings"
- "Enable filtering by date range in search"

---

## Step 1: Submit Feature Request (~5 min)

Create the initial bead with a clear feature request:

```bash
cd ~/my-city
bd create "Feature: [Your Feature Name]" \
  --label "capstone-feature" \
  --description "$(cat <<'EOF'
# Feature Request: [Name]

## User Story
**As a** [user type]  
**I want** [capability]  
**So that** [benefit]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Constraints
- Must integrate with [existing system]
- Performance: [requirement]
- Security: [requirement]

## Success Metrics
- [How will we know this works?]
EOF
)"
```

Note the bead ID. This is your factory's starting point.

---

## Step 2: Start the Factory Pipeline (~2 min)

If you have `orchestrator.yaml` configured:

```bash
gc orchestrate --pipeline feature-pipeline --bead [bead-id]
```

This kicks off the entire pipeline automatically.

**OR manual mode** (if orchestrator not ready):

```bash
gc sling planner [bead-id]
```

---

## Step 3: Monitor Factory Progress (Real-Time)

Open multiple terminal windows to watch each agent:

```bash
# Terminal 1: Overall status
watch -n 5 'bd list --status open | tail -20'

# Terminal 2: Planner
gc watch planner

# Terminal 3: Architect
gc watch architect

# Terminal 4: Designer
gc watch designer

# Terminal 5: Coder
gc watch coder

# Terminal 6: Reviewer
gc watch reviewer

# Terminal 7: DevOps
gc watch devops
```

**Do NOT intervene unless:**
1. Agent gets stuck (no activity for 10+ minutes)
2. Feedback loop detects pattern requiring human decision
3. Human approval gate reached (e.g., architecture review)

---

## Step 4: Track Artifacts as They're Created

As the factory runs, verify artifacts appear:

```bash
# Work package (from Planner)
ls -l work-packages/
cat work-packages/[your-feature].md

# ADR (from Architect)
ls -l docs/adr/
cat docs/adr/[number]-[your-feature].md

# Design doc (from Designer)
ls -l design-docs/
cat design-docs/[your-feature].md

# Code (from Coder)
git log --oneline feature/[your-feature]
git diff main...feature/[your-feature]

# PR (from Coder)
gh pr list | grep [your-feature]

# Review (from Reviewer)
gh pr view [pr-number] --comments

# Deployment logs (from DevOps)
bd show [deploy-bead-id]
```

---

## Step 5: Handle Human Gates (If Configured)

If your orchestrator includes human approval gates:

```bash
# Check for beads awaiting approval
bd list --status needs-approval

# Review the decision
bd show [bead-id]
cat [artifact-path]  # Read ADR or other decision document

# Approve or reject
bd approve [bead-id] --comment "Approved: [reason]"
# OR
bd reject [bead-id] --comment "Blocked: [reason]"
```

**Approval Guidelines:**
- Approve if: Decision is sound, risks acceptable, aligns with architecture
- Reject if: High risk not mitigated, violates architectural principles, needs more analysis

---

## Step 6: Watch Feedback Loops Activate (Optional)

If you implemented feedback loops in W4:

```bash
# Monitor feedback events
bd event list --since 1h --type test_failure
bd event list --since 1h --type review_pattern

# Check if feedback rules triggered
git log --grep="feedback:" --since="1 hour ago"

# See what guidance was auto-added
git diff HEAD~1 AGENTS.md
```

**Expect:**
- If test fails repeatedly → AGENTS.md updated automatically
- If reviewer catches pattern → Quality gate added automatically
- Factory re-runs after feedback applied

---

## Step 7: Verify Deployment

Once DevOps completes:

**Check staging:**
```bash
curl https://staging.yourapp.com/api/[your-endpoint]
# OR
open https://staging.yourapp.com/[your-feature-path]
```

**Check production:**
```bash
curl https://yourapp.com/api/[your-endpoint]
# OR
open https://yourapp.com/[your-feature-path]
```

**Check monitoring:**
- Open your monitoring dashboard
- Verify new metrics appear
- Confirm alerts configured

---

## Step 8: Complete Factory Run Report (~15 min)

Document the factory run:

```markdown
# Factory Run Report: [Feature Name]

**Date:** [YYYY-MM-DD]  
**Duration:** [X minutes]  
**Bead ID:** [initial-bead-id]  
**Outcome:** ✅ Success | 🔄 Partial | ❌ Failed

---

## Stages Executed

| Stage | Agent | Duration | Status | Output Artifact |
|-------|-------|----------|--------|-----------------|
| Planning | Planner | 5 min | ✅ | work-packages/[name].md |
| Architecture | Architect | 5 min | ✅ | docs/adr/[num]-[name].md |
| Design | Designer | 5 min | ✅ | design-docs/[name].md |
| Implementation | Coder | 30 min | ✅ | feature/[name] branch |
| Review | Reviewer | 10 min | ✅ | PR approval |
| Deployment | DevOps | 15 min | ✅ | Staging + Production |

**Total Time:** [X minutes]

---

## Quality Gates

| Gate | Status | Notes |
|------|--------|-------|
| Build | ✅ Pass | No errors |
| Lint | ✅ Pass | 0 warnings |
| Type Check | ✅ Pass | No type errors |
| Tests | ✅ Pass | 87% coverage |
| Review | ✅ Approved | Minor comments addressed |
| Staging Tests | ✅ Pass | All smoke tests passed |
| Production Health | ✅ Healthy | No errors after 5 min |

---

## Artifacts Produced

- [x] Work Package: `work-packages/[name].md`
- [x] ADR: `docs/adr/[number]-[name].md`
- [x] Design Doc: `design-docs/[name].md`
- [x] Feature Branch: `feature/[name]`
- [x] Pull Request: #[number]
- [x] Staging Deployment: [URL]
- [x] Production Deployment: [URL]
- [x] Monitoring Dashboard: [URL]

---

## Feedback Loops Triggered

1. **Test Failure Pattern Detected (Iteration 2)**
   - Error: "Null reference in component mount"
   - Action: Auto-added null check guidance to AGENTS.md
   - Result: Coder re-ran, issue resolved

2. **Review Pattern Detected**
   - Issue: Missing error boundary
   - Action: Added requirement to Designer template
   - Result: Future features will include error boundaries

3. **[Add more as applicable]**

---

## Human Interventions

| When | Why | Action Taken | Duration |
|------|-----|--------------|----------|
| T+10min | Architecture approval gate | Reviewed ADR, approved database choice | 3 min |
| T+75min | Production deploy gate | Reviewed staging metrics, approved deploy | 2 min |

**Total Human Time:** 5 minutes

---

## Config Discipline

- **Ad-hoc prompts used:** 0 ✅
- **Manual code fixes:** 0 ✅
- **Config iterations:** 2 (both via AGENTS.md updates)

---

## What Worked Well

1. [What went smoothly?]
2. [What surprised you positively?]
3. [What validated your factory design?]

---

## What Needs Improvement

1. [What broke or got stuck?]
2. [What took longer than expected?]
3. [What would you change in AGENTS.md?]

---

## Lessons Learned

### For Future Factory Runs
- [Specific improvement to make]
- [Configuration to update]
- [Process to refine]

### For Production Use
- [What's ready to use daily]
- [What needs more testing]
- [What requires human oversight still]

---

## Next Steps

- [ ] Update AGENTS.md with lessons learned
- [ ] Add feedback rule for [new pattern discovered]
- [ ] Refine orchestrator.yaml timing
- [ ] Test factory on [next feature type]

---

**Factory Status:** [Ready for Production | Needs Refinement | Prototype Complete]
```

Save as: `factory-runs/capstone-[date]-[feature-name].md`

---

## Quality Bar

When you review your run, verify:

- **Stages Completed** — All 6 stages (Planner through DevOps) executed
- **Quality Gates** — All gates pass (or auto-remediate via feedback)
- **Artifacts Produced** — All 7 artifacts present and cross-referenced (work package, ADR, design spec, code, review report, release gate, run report)
- **Config Discipline** — Zero ad-hoc prompts and zero manual code edits
- **Factory Run Report** — Complete documentation with insights

---

## Common Issues & Troubleshooting

### Issue: Agent gets stuck, no progress for 10+ minutes
**Solution:**
1. Check agent logs: `gc watch [agent-name]`
2. Verify bead dependencies: `bd show [bead-id]`
3. Check if waiting on approval: `bd list --status needs-approval`
4. If truly stuck, check AGENTS.md for ambiguous guidance

### Issue: Quality gate fails repeatedly (same error)
**Solution:**
1. Check if feedback loop should have caught this (run `bd event list`)
2. Manually update AGENTS.md with specific fix
3. Reset and re-run from failed stage
4. Add feedback rule to catch this pattern in future

### Issue: Coordination problem (wrong stage runs first)
**Solution:**
1. Check `orchestrator.yaml` dependencies
2. Verify bead `depends_on` relationships: `bd show [bead-id]`
3. Update orchestrator and restart: `gc restart`

### Issue: Deployment fails in staging
**Solution:**
1. Check DevOps logs for error details
2. Do NOT manually fix—update DevOps AGENTS.md with missing checks
3. Rollback staging, re-run DevOps bead

---

## Exit Criteria

✅ **Full success:**
- All 6 stages execute
- Feature deployed to at least staging
- Quality gates pass (or auto-remediated via feedback)
- Factory Run Report completed
- Zero manual code edits (AGENTS.md / `CLAUDE.md` updates allowed)

❌ **Needs rework:**
- Human manually writes code (breaks config discipline)
- Pipeline blocks with no path forward
- Deployed code doesn't meet acceptance criteria

🔄 **Partial:**
- Feature works but required >3 manual AGENTS.md iterations
- Deployed to staging but not production
- Some quality gates bypassed

---

## After the Capstone

### Immediate
1. **Commit all configs**: Push AGENTS.md, orchestrator.yaml, feedback scripts
2. **Archive factory run**: Save complete logs and report
3. **Update documentation**: Note what worked, what needs improvement

### Next Week
1. **Test on real work**: Run factory on actual team feature
2. **Refine based on capstone learnings**
3. **Add more feedback rules** for patterns discovered
4. **Train team members** on using the factory

### Next Month
1. **Measure impact**: Time saved, quality improvements, velocity increase
2. **Expand factory**: Add specialized agents (security, performance, docs)
3. **Share learnings**: Write about your factory, help others build theirs

---

## Post-Capstone: Evolving Your Factory

Once the capstone run lands, your factory is a living system. Three follow-through habits separate factories that *scale* from factories that *atrophy*:

### 1. Re-run `actual adr-bot` weekly

Your codebase changes; industry baselines shift; tailored ADRs go stale. Schedule a weekly order:

```toml
# my-factory/orders/adr-refresh/order.toml
[order]
name = "adr-refresh"
schedule = "0 9 * * 1"     # every Monday 9am
agent = "architect"
message = "Run `actual adr-bot` to refresh tailored ADRs in CLAUDE.md. Commit diffs for review."
```

This makes the Actual ADR system an ongoing input to your factory, not a one-time setup.

### 2. Promote recurring feedback-rule patterns into ADRs

A feedback rule that fires 5+ times a month is no longer a "pitfall" — it's an architectural principle. Promote it:

1. Move the rule's guidance from `CLAUDE.md`'s auto-generated section into a new ADR under `docs/adr/`
2. Remove the feedback rule (it's now permanent, not patrolling)
3. Note the promotion in `DECISIONS.md`

### 3. Measure factory velocity

Capture these metrics after every capstone-style run:

- **Stages-to-passing:** How many slings did each stage need? Target: 1.2 average across stages.
- **Human gate seconds:** Time from bead → `needs-approval` → approved. Long waits = gate is too frequent or approver is overloaded.
- **Config-discipline ratio:** Commits tagged `chore:` / `docs:` updating `CLAUDE.md` vs. total commits. High ratio = healthy config-first culture.

Track these in a `factory-runs/metrics.md` rolling table. Over 6 runs you'll see whether your factory is getting faster (good) or whether you're tightening rules faster than the factory adapts (rebalance).

---

## Industry Landscape: Where Software Factories Are Going

Your factory is ahead of most production teams right now. A few signals for what comes next:

- **Cognition AI (Devin)** demonstrated the first commercial agent that can complete a full feature autonomously — from Jira ticket to shipped PR. Your 6-agent factory is the composable, transparent, self-hostable answer to that model. Devin is opaque; your factory is every artifact on disk.
- **GitHub's Copilot Workspace** is productizing the Planner → Architect → Designer → Coder flow as a single end-to-end UX. Your factory lets you swap each stage's implementation independently — Copilot is monolithic, yours is Unix-philosophy.
- **AWS Bedrock AgentCore and Google Vertex AI Agent Builder** are making the primitives (MCP, tool access, memory) cloud-native. Your `packs/workshop/` already uses MCP for Sentry/DataDog/Grafana/Slack — the same mechanism these clouds commercialize.
- **IBM's "Software Engineering Agents" research** argues that the 10x productivity bump comes not from better single agents but from **better handoff artifacts**. Your work packages, ADRs, design specs, and release gates are exactly the handoff layer they describe.
- **McKinsey's 2025 State of AI** reports that early adopters of agentic pipelines see 40–60% cycle-time reduction on bug-fix workflows and 15–25% on feature development. The variance is explained by *config discipline*: teams that maintain declarative configs see higher retention of gains over 6 months.

The thesis of this intensive — **config over prompting, artifacts as handoffs, config-discipline as the scaling axis** — is the consensus direction. You've built it from first principles.

---

## Congratulations!

You've built a complete software factory from scratch. You now have:
- ✅ 6 working agents with clear responsibilities
- ✅ Coordination patterns for managing complex workflows
- ✅ Feedback loops for continuous improvement
- ✅ A deployed feature proving the system works

**This is just the beginning.** As you use your factory daily, it will learn, improve, and become indispensable to your development process.

Welcome to the future of software development. 🚀
