# Human Gate · approve_deploy

**Stage:** after Reviewer, before Deployer
**Bead command to approve:** `bd approve <bead-id>`
**Bead command to reject:** `bd reject <bead-id> --comment "..."`

---

## Why this gate exists

The Reviewer is authorized to produce an `APPROVE` verdict. The Deployer is authorized to push a release gate to PASS. But a human confirms the handoff between them because the Deployer's actions — merging to main, evaluating binary release criteria, marking a feature deployment-ready — are harder to reverse than the Reviewer's.

Specifically, this gate catches scenarios the Reviewer can't:

- Release criteria in `docs/PROJECT_MANIFEST.md` have been tightened since the last run, and the Reviewer didn't re-check them.
- An external dependency (Jira ticket, legal review, related PR) is still pending.
- A Medium-severity finding was acknowledged but not actually resolved.

---

## What the approver must verify

| Check | How to verify |
|-------|---------------|
| Reviewer verdict is `APPROVE` (not `REQUEST CHANGES`) | `head review-reports/<slug>-review.md` — first section is the verdict |
| No open High-severity findings | `grep -A1 "High" review-reports/<slug>-review.md` returns nothing *or* every High has a `Resolved:` line |
| Tests pass on the feature branch | `git checkout feat/<slug> && npm test` exits 0 |
| Branch is mergeable with main | `git fetch origin main && git merge-tree $(git merge-base feat/<slug> origin/main) feat/<slug> origin/main` shows no conflict markers |
| Related tickets closed / updated | `gh issue list --label "blocks:<slug>"` is empty |

---

## Worst case if the gate is skipped

The Deployer emits a PASS gate, a human treats the gate as the green light to merge, and the feature ships with an unresolved Medium finding that later produces a production incident. Recovery requires a hotfix branch, a patched release gate, and an apology to customers. The full incident review runs longer than the gate itself would have taken.

Historical anchor: this gate was added after an L4 run where the Reviewer approved a loyalty-points change that double-awarded points on retry. The test covered the happy path; no one noticed the retry case in the review report until a customer called out a points discrepancy 12 hours after deploy.

---

## When this gate can be removed

This gate can be lifted to fully automated only when **all three** of the following are true:

1. The Reviewer prompt has been updated to explicitly enforce every check in the table above (and has caught all three classes of finding at least once in prior runs).
2. The release criteria in `docs/PROJECT_MANIFEST.md` are stable across at least 5 consecutive feature runs (no manifest diff between capstone runs).
3. The team has appetite for the worst-case scenario above — i.e., a hotfix cycle per month is acceptable.

Until then, the ~2 minutes a human spends here is cheaper than the alternative.
