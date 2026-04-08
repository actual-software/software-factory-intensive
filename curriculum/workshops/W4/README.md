# W4 · Create Continuous Improvement Loops

> **Goal:** Design feedback mechanisms that allow your factory to learn from failures and automatically improve its configuration—reducing manual intervention over time.

| | |
|---|---|
| **Day** | Day 2 |
| **Time** | 11:45 - 12:30 |
| **Type** | WORKSHOP |
| **Deliverable** | Feedback loop design + automated improvement rules |

---

## The Problem: Factories That Don't Learn

**Without feedback loops:**
```
Test fails → Human debugs → Human updates AGENTS.md → Human re-runs
Test fails again → Human debugs again → Repeat forever
```

**With feedback loops:**
```
Test fails → Factory logs failure pattern → Factory updates AGENTS.md automatically → Re-runs
Same pattern fails → Factory escalates to human with context
```

---

## Three Types of Runtime Signals

### 1. Quality Gate Failures
**What:** Tests fail, lint errors, build breaks, coverage drops

**Example Signal:**
```json
{
  "type": "test_failure",
  "stage": "coder",
  "test": "src/__tests__/search.test.ts",
  "error": "TypeError: Cannot read property 'filter' of undefined",
  "line": 42,
  "frequency": 3  // Failed 3 times in last 5 runs
}
```

**Feedback Action:**
- If same error repeats 3+ times → Add explicit guidance to Coder AGENTS.md
- Example: "Always check if array exists before calling .filter()"

---

### 2. Review Findings
**What:** Reviewer agent catches repeated patterns

**Example Signal:**
```json
{
  "type": "review_pattern",
  "stage": "reviewer",
  "issue": "Missing error handling in async functions",
  "frequency": 5,  // Found in 5 different PRs
  "severity": "high"
}
```

**Feedback Action:**
- Add to Coder AGENTS.md: "All async functions MUST have try-catch blocks"
- Add automated check: Gate fails if async function lacks try-catch

---

### 3. Deployment Errors
**What:** Production issues, rollbacks, performance problems

**Example Signal:**
```json
{
  "type": "deployment_failure",
  "stage": "devops",
  "error": "Database migration timeout",
  "rollback": true,
  "feature": "user-search"
}
```

**Feedback Action:**
- Add to Architect AGENTS.md: "Database migrations must complete in <5 seconds or use background job"
- Add to Designer AGENTS.md: "Flag migrations in design doc for DevOps review"

---

## Feedback Loop Architecture

```
Runtime Event (test fail, review issue, deploy error)
      ↓
Event Logger (bd event log --type=[type])
      ↓
Pattern Detector (analyze frequency, severity)
      ↓
Rule Generator (create AGENTS.md update)
      ↓
Apply Update (git commit to AGENTS.md)
      ↓
Trigger Re-run (gc sling [agent] [bead])
      ↓
Verify Fix (check if issue resolved)
```

---

## Automated Feedback Rules

### Rule 1: Repeated Test Failures
**Trigger:** Same test fails 3+ times across different features

**Action:**
```bash
#!/bin/bash
# scripts/feedback/test-failure-rule.sh

ERROR_PATTERN="$1"  # e.g., "Cannot read property 'filter' of undefined"
FREQUENCY="$2"

if [ "$FREQUENCY" -ge 3 ]; then
  echo "Adding error handling guidance to AGENTS.md..."
  
  cat >> AGENTS.md << EOF

## Common Pitfalls (Auto-Generated)

### Array Operations
**Issue:** TypeError when calling array methods on undefined
**Fix:** Always validate array exists before operations
\`\`\`typescript
// BAD
const results = data.filter(x => x.active);

// GOOD
const results = (data || []).filter(x => x.active);
\`\`\`
**Frequency:** Caught $FREQUENCY times
EOF

  git add AGENTS.md
  git commit -m "feedback: Add array validation guidance (auto-generated)"
fi
```

---

### Rule 2: Security Patterns from Reviews
**Trigger:** Reviewer flags security issue 2+ times

**Action:**
```bash
#!/bin/bash
# scripts/feedback/security-pattern-rule.sh

ISSUE_TYPE="$1"  # e.g., "SQL injection risk"
FREQUENCY="$2"

if [ "$FREQUENCY" -ge 2 ]; then
  echo "Adding security check to quality gates..."
  
  cat >> .github/workflows/security-check.yml << EOF
    - name: Check for SQL injection patterns
      run: |
        if grep -r "SELECT.*${" src/; then
          echo "ERROR: Template literals in SQL detected"
          exit 1
        fi
EOF

  git add .github/workflows/security-check.yml
  git commit -m "feedback: Add automated SQL injection check"
fi
```

---

### Rule 3: Performance Regressions
**Trigger:** Deployment causes latency spike

**Action:**
```bash
#!/bin/bash
# scripts/feedback/performance-rule.sh

ENDPOINT="$1"  # e.g., "/api/search"
LATENCY_MS="$2"  # e.g., 850ms
THRESHOLD=500

if [ "$LATENCY_MS" -gt "$THRESHOLD" ]; then
  echo "Adding performance requirement to AGENTS.md..."
  
  cat >> AGENTS.md << EOF

## Performance Requirements (Auto-Generated)

### API Endpoints
All API endpoints must respond in <500ms (P95).

**Failed Check:** $ENDPOINT took ${LATENCY_MS}ms after deployment.

**Required Actions:**
- Designer: Include performance budgets in implementation plans
- Coder: Profile code before committing
- Reviewer: Check for N+1 queries, inefficient loops
EOF

  git add AGENTS.md
  git commit -m "feedback: Add performance requirements for $ENDPOINT"
fi
```

---

## Workshop Activity: Design Your Feedback Loops

### Part 1: Identify Failure Patterns (15 min)

**Think about your past projects. What errors happened repeatedly?**

Examples:
- "Forgot to add error handling to API calls" (happened 5 times)
- "Didn't check for null before accessing properties" (happened 10 times)
- "Forgot to update documentation when code changed" (happened constantly)
- "Tests didn't cover edge cases" (happened often)

**For each pattern, document:**
```markdown
## Pattern: [Name]

**Symptom:** [What breaks or fails?]
**Frequency:** [How often does this happen?]
**Current Fix:** [What do you do manually to fix it?]
**Proposed Automation:** [How could factory detect and fix this automatically?]
```

**Deliverable:** List of 3 failure patterns with proposed automations.

---

### Part 2: Write One Feedback Rule (20 min)

**Pick your most frequent failure pattern** and write a script that:

1. **Detects the pattern** (parse logs, check git history, analyze test results)
2. **Determines if it's recurring** (frequency threshold)
3. **Updates AGENTS.md** (add specific guidance)
4. **Commits the change** (auto-commit with explanation)

**Template:**
```bash
#!/bin/bash
# scripts/feedback/[your-pattern]-rule.sh

# 1. Detect
PATTERN="[what to search for]"
COUNT=$(git log --grep="$PATTERN" --since="7 days ago" | grep -c "commit")

# 2. Check frequency
THRESHOLD=3
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  
  # 3. Update AGENTS.md
  cat >> AGENTS.md << 'EOF'
## [Your Agent] Common Pitfall

**Issue:** [Description]
**Fix:** [Specific guidance]
**Example:**
\`\`\`
[Code example]
\`\`\`
EOF

  # 4. Commit
  git add AGENTS.md
  git commit -m "feedback: Add guidance for [pattern] (auto-detected $COUNT occurrences)"
  
  echo "Feedback rule applied: [pattern] guidance added"
fi
```

**Test it:**
```bash
bash scripts/feedback/[your-pattern]-rule.sh
cat AGENTS.md  # Verify guidance was added
```

---

## Difference Between Feedback and Manual Correction

### ❌ Manual Correction (Doesn't Scale)
```
Test fails → Human opens AGENTS.md → Human types fix → Human commits
```

**Problem:** Requires human every time. Doesn't learn patterns.

### ✅ Automated Feedback (Scales)
```
Test fails → Logger captures error → Script detects pattern → Script updates AGENTS.md → Auto-commits
```

**Benefit:** Factory improves itself. Humans only intervene for NEW patterns.

---

## When to Escalate to Humans

**Automate when:**
- Pattern seen 3+ times
- Fix is straightforward (add check, update guidance)
- Low risk (won't break other things)

**Escalate when:**
- New pattern (first occurrence)
- Fix requires architectural decision
- Conflicting guidance (two rules contradict)
- High risk (could break existing features)

**Example Escalation:**
```bash
# In your feedback script
if [ "$COUNT" -ge 3 ]; then
  # Automate: Add guidance
  echo "Auto-fixing repeated pattern..."
elif [ "$COUNT" -eq 1 ]; then
  # Escalate: Notify human
  bd create "Review new failure pattern: $PATTERN" \
    --requires-approval \
    --assignee austin@actual.ai \
    --description "New pattern detected. Needs human review before automating."
fi
```

---

## Integrating Feedback with Gas City

### Step 1: Log Events
```bash
# In your agent scripts
if ! npm test; then
  bd event log \
    --type test_failure \
    --stage coder \
    --error "$(npm test 2>&1)" \
    --bead-id $BEAD_ID
fi
```

### Step 2: Run Feedback Analyzer (Cron Job)
```bash
# crontab entry: Run every hour
0 * * * * cd ~/my-city && ./scripts/analyze-feedback.sh
```

### Step 3: Apply Rules
```bash
#!/bin/bash
# scripts/analyze-feedback.sh

# Query events from last 7 days
bd event list --since 7d --type test_failure > /tmp/test-failures.log

# Run pattern detectors
./scripts/feedback/test-failure-rule.sh
./scripts/feedback/security-pattern-rule.sh
./scripts/feedback/performance-rule.sh

echo "Feedback analysis complete"
```

---

## Recommended Prompts

### When Designing Feedback Loops
```
I run a software factory with 6 agents (Planner, Architect, Designer, Coder, Reviewer, DevOps).

I want to automate learning from these recurring issues:
1. [Pattern 1]: Happens [X] times per week
2. [Pattern 2]: Happens [Y] times per week
3. [Pattern 3]: Happens [Z] times per week

For each pattern, help me design:
1. How to detect it automatically (what logs/signals to monitor)
2. What threshold triggers automated fix (how many occurrences?)
3. What change to make to AGENTS.md (specific guidance to add)
4. When to escalate to human instead of auto-fixing
```

### When Writing Feedback Rules
```
I need a bash script that:
1. Detects when [specific error] occurs repeatedly
2. Checks if it's happened >= 3 times in the last 7 days
3. If yes, appends this guidance to AGENTS.md:
   [specific guidance text]
4. Commits the change with explanatory message

The error pattern I'm looking for: [pattern description]
The log file location: [path]

Generate the complete bash script.
```

---

## Exit Criteria

✅ Identified 3 recurring failure patterns from past projects  
✅ Wrote 1 automated feedback rule script  
✅ Tested feedback rule successfully updates AGENTS.md  
✅ Documented when to automate vs. escalate to human  

---

## Next Steps

In **C1 (Capstone)**, you'll run your complete factory end-to-end. Feedback loops you design here will help the factory self-improve during the run, reducing the need for manual intervention.
