# L4 · Deploy Reviewer + DevOps Agents

> **Goal:** Complete the factory pipeline with automated code review and deployment—ensuring quality and delivering to production without manual intervention.

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 10:30 - 11:45 |
| **Type** | LAB |
| **Deliverable** | Working Reviewer + DevOps agents + deployed feature |

---

## What You'll Build

```
PR created (from L3)
      ↓
Reviewer Agent performs code review
      ↓
Produces: Review comments, approval/rejection
      ↓
(If approved)
      ↓
DevOps Agent handles deployment
      ↓
Produces: Deployment, monitoring setup, docs update
      ↓
Feature live in production
```

---

## Prerequisites

✅ L3 complete (feature implemented, PR created)  
✅ Gas City running with Designer + Coder agents  
✅ Access to deployment environment (staging/production)  

---

## Step 1: Add Reviewer Agent

**city.toml:**
```toml
[[agent]]
name = "reviewer"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "1h"
role = "reviewer"
```

**AGENTS.md:**
```markdown
## Reviewer Agent

### Role
You perform thorough code reviews ensuring quality, adherence to standards, and architectural consistency.

### Review Checklist
1. **Architectural Consistency:** Does code follow ADR decisions?
2. **Code Quality:** Clean, readable, well-structured?
3. **Test Coverage:** >= 80%, tests meaningful?
4. **Security:** No secrets, injection risks, auth properly checked?
5. **Performance:** No obvious bottlenecks, efficient algorithms?
6. **Documentation:** Public APIs documented, complex logic explained?
7. **Error Handling:** Edge cases covered, errors logged?

### Review Process
1. Read PR description, work package, ADR, design doc
2. Review changed files systematically
3. Run quality gates locally
4. Test functionality if possible
5. Leave inline comments on specific issues
6. Provide summary with approve/request changes decision

### Comment Template
\`\`\`markdown
## Review Summary

**Status:** ✅ Approved | 🔄 Changes Requested | ❌ Blocked

### Strengths
- [What was done well]

### Issues Found
- **[Severity]** [Location]: [Issue description]

### Checklist Results
- [x] Architectural consistency
- [x] Code quality
- [ ] Test coverage (currently 65%, needs 80%)
- [x] Security
- [x] Performance
- [x] Documentation
- [x] Error handling

### Recommendation
[Approve and merge | Request changes | Block due to [reason]]

**References:** WP-[ID], ADR-[ID], Design-[ID]
\`\`\`

### Output Location
Post review as GitHub PR comment
```

---

## Step 2: Add DevOps Agent

**city.toml:**
```toml
[[agent]]
name = "devops"
dir = "your-repo-name"
provider = "claude"
idle_timeout = "2h"
role = "devops"
```

**AGENTS.md:**
```markdown
## DevOps Agent

### Role
You handle deployment, infrastructure setup, monitoring, and operational documentation for approved features.

### Responsibilities
1. Merge approved PRs
2. Deploy to staging environment
3. Run smoke tests
4. Deploy to production (if staging passes)
5. Set up monitoring/alerts for new features
6. Update operational documentation

### Deployment Checklist
- [ ] PR approved by Reviewer
- [ ] All CI/CD checks pass
- [ ] Merge to main branch
- [ ] Deploy to staging
- [ ] Run smoke tests (critical paths)
- [ ] Verify monitoring dashboards
- [ ] Deploy to production
- [ ] Verify production health
- [ ] Update runbooks/docs

### Deployment Script Template
\`\`\`bash
#!/bin/bash
set -euo pipefail

# Deploy [Feature Name]
# WP-[ID] | ADR-[ID]

echo "Deploying to staging..."
./scripts/deploy.sh --env=staging --feature=[name]

echo "Running smoke tests..."
./scripts/smoke-test.sh --env=staging

if [ $? -eq 0 ]; then
  echo "Staging passed. Deploying to production..."
  ./scripts/deploy.sh --env=production --feature=[name]
  
  echo "Verifying production..."
  ./scripts/health-check.sh --env=production
  
  echo "Deployment complete!"
else
  echo "Staging tests failed. Rollback initiated."
  ./scripts/rollback.sh --env=staging
  exit 1
fi
\`\`\`

### Monitoring Setup
For each new feature, add:
- **Metrics:** Usage counts, latency, error rates
- **Alerts:** Error rate > 1%, latency > 500ms
- **Dashboards:** Feature-specific panel in main dashboard

### Documentation Updates
Update these files post-deployment:
- `CHANGELOG.md`: Add entry for new feature
- `docs/deployment.md`: Note any new deployment steps
- `docs/monitoring.md`: Document new metrics/alerts
- `docs/runbooks/[feature].md`: Create operational runbook
```

---

## Step 3: Create Review Bead

```bash
cd ~/my-city
bd create "Review: Loyalty Points PR" \
  --description "$(cat <<'EOF'
Review the PR for loyalty points implementation.

PR: [paste GitHub PR URL]

Perform complete code review following checklist in AGENTS.md.

References:
- Work Package: work-packages/loyalty-points-system.md
- ADR: docs/adr/0001-loyalty-points-storage.md
- Design: design-docs/loyalty-points-implementation.md

Post review as PR comment with approve/request changes decision.
EOF
)" \
  --depends-on [coder-bead-id]
```

---

## Step 4: Sling to Reviewer

```bash
gc sling reviewer [review-bead-id]
gc watch reviewer
```

Reviewer will:
1. Clone PR branch
2. Review code against checklist
3. Run quality gates
4. Post review comment on GitHub

---

## Step 5: Check Review Results

View the PR on GitHub. The Reviewer should have posted a comment with:
- ✅ Approval OR 🔄 Change requests
- Inline comments on specific issues
- Checklist results
- Recommendation

**If changes requested:**
1. Update AGENTS.md with clearer guidance for Coder
2. Create new implementation bead
3. Repeat from Step 8 of L3

**If approved:** Proceed to deployment.

---

## Step 6: Create Deployment Bead

```bash
bd create "Deploy: Loyalty Points to Production" \
  --description "$(cat <<'EOF'
Deploy approved loyalty points feature following deployment checklist.

PR: [GitHub URL - must be approved]

Steps:
1. Merge PR to main
2. Deploy to staging
3. Run smoke tests
4. If pass, deploy to production
5. Verify production health
6. Set up monitoring for new feature
7. Update documentation (CHANGELOG, deployment guide, runbook)

Follow deployment process in AGENTS.md exactly.
EOF
)" \
  --depends-on [review-bead-id]
```

---

## Step 7: Sling to DevOps

```bash
gc sling devops [deploy-bead-id]
gc watch devops
```

DevOps agent will execute full deployment pipeline.

---

## Step 8: Verify Deployment

**Check staging:**
```bash
curl https://staging.yourapp.com/api/loyalty-points/balance?userId=test
```

**Check production:**
```bash
curl https://yourapp.com/api/loyalty-points/balance?userId=test
```

**Check monitoring:**
Open your monitoring dashboard and verify new metrics appear.

---

## Step 9: Review Documentation Updates

```bash
git pull origin main
cat CHANGELOG.md | head -20
cat docs/deployment.md | grep -A 5 "loyalty"
ls docs/runbooks/
```

Verify DevOps agent added:
- [ ] CHANGELOG entry
- [ ] Deployment notes
- [ ] Monitoring setup documented
- [ ] Operational runbook created

---

## Step 10: Close All Beads

```bash
bd close [review-bead-id] --comment "Code review complete, approved"
bd close [deploy-bead-id] --comment "Deployed to production successfully"
```

---

## Recommended Prompts

### For Reviewer Agent
```
Perform a complete code review of PR: [URL]

Review against these artifacts:
- Work Package: [path]
- ADR: [path]
- Design Doc: [path]

Use the review checklist from AGENTS.md.

Post your review as a PR comment with:
1. Summary (approve/request changes)
2. Inline comments on issues
3. Checklist results
4. Recommendation

Be thorough but constructive.
```

### For DevOps Agent
```
Deploy the approved feature: [name]

PR: [URL] (verified approved)

Follow deployment checklist in AGENTS.md:
1. Merge PR
2. Deploy to staging
3. Smoke test
4. Deploy to production
5. Verify health
6. Set up monitoring
7. Update docs

Report back with deployment status and any issues encountered.
```

---

## Evaluation Rubric

| Criterion | Points | Scoring |
|-----------|--------|---------|
| **Review Quality** | 30 pts | Comprehensive checklist, specific actionable feedback |
| **Deployment Success** | 30 pts | Feature live in production, health checks pass |
| **Monitoring Setup** | 20 pts | Metrics, alerts, dashboards configured |
| **Documentation** | 20 pts | CHANGELOG, deployment guide, runbook updated |

**Total:** 100 points

---

## Exit Criteria

✅ Code review posted on PR  
✅ Feature deployed to production  
✅ Production health checks pass  
✅ Monitoring configured  
✅ Documentation updated  
✅ All beads closed  

---

## Common Issues & Solutions

### Issue: Reviewer too lenient/strict
**Solution:** Add specific thresholds to AGENTS.md: "Block if test coverage < 80%. Request changes if > 3 security issues found."

### Issue: Deployment fails mid-process
**Solution:** Add rollback instructions to AGENTS.md: "If any step fails, run ./scripts/rollback.sh immediately."

### Issue: Monitoring not set up
**Solution:** Make it explicit in checklist: "Create dashboard panel named '[Feature Name] Metrics' with these exact queries: [list queries]."

### Issue: Documentation incomplete
**Solution:** Template exact format expected: "CHANGELOG entry must include: date, feature name, work package ID, user-facing changes."

---

## Next Steps

After L4, your complete factory pipeline is:
1. ✅ Planner → breaks down work
2. ✅ Architect → makes decisions
3. ✅ Designer → plans implementation
4. ✅ Coder → writes code
5. ✅ Reviewer → ensures quality
6. ✅ DevOps → deploys + monitors

You now have an end-to-end software factory! In the workshops (W2-W4) and capstone (C1), you'll optimize coordination, continuous improvement, and run the full factory autonomously.
