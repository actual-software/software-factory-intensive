# Feedback Loop · Customer-Reported Points Discrepancy

**Category:** External
**Created:** 2026-04-16
**Source:** support email from Maria C., customer since 2024

---

## Signal

Source: support inbox (`support@fireduppizza.example`) forwarded to the oncall bead queue via `packs/workshop` Gmail integration.
Pattern: any customer email whose subject contains `points`, `loyalty`, or `rewards` AND whose body contains a specific order number.

Detection script: `feedback-loops/rules/triage-customer-points.sh`

```bash
#!/bin/bash
# triage-customer-points.sh — convert a support email into a bead.
# Expects the email ID as the only argument.

set -euo pipefail

EMAIL_ID=$1
SUBJECT=$(gmail-cli show "$EMAIL_ID" --field subject)
BODY=$(gmail-cli show "$EMAIL_ID" --field body)
ORDER_NUMBER=$(echo "$BODY" | grep -oE "FUP-ORDER-[0-9]+" | head -1)

bd create "Customer points discrepancy: $ORDER_NUMBER" \
  --description "$(cat <<EOF
From: $(gmail-cli show "$EMAIL_ID" --field from)
Subject: $SUBJECT
Order: $ORDER_NUMBER

Body:
$BODY

Signal origin: external (customer support)
EOF
)" \
  --labels "bug,loyalty,customer-reported"
```

## Trigger

One email matching the pattern. External loops are always high-touch — every customer-reported bug opens a bead, even if the bug is already known.

## Target

No automatic prompt edit. This loop's output is a new *bead*, not a prompt update. The Planner processes the bead like any other feature request.

Side effect: if the root cause turns out to be an Agent prompt flaw, this external loop may trigger a reactive loop (see `coder-missing-try-catch.md`) as a second-order effect.

## Action

1. Bead created in the ticket queue with label `customer-reported`.
2. Planner is slung on the bead within one business day — SLA baked into the `sync-customer-points` order in `packs/workshop/orders/`.
3. If the investigation shows the points were correctly awarded but the UI displayed the wrong balance, that's a Designer bug → new work package → Designer re-slung.
4. If the investigation shows the points themselves were wrong, that's a Coder bug → new work package + likely a reactive feedback loop on the specific mistake.
5. The customer is replied to with resolution + points correction within 48h. The reply text is drafted by the `customer-response` agent (if installed) or written by hand.

## Verification

- The bead produced by this loop is closed within 5 business days.
- If the root cause implicated an agent prompt, a reactive feedback loop is opened and cross-linked in the bead's comments.
- A weekly audit (`feedback-loops/rules/audit-external.sh`) confirms no unprocessed customer-reported beads are older than the SLA.

## History

| Date | Customer | Order | Root cause | Resolution |
|------|----------|-------|------------|------------|
| 2026-04-16 | Maria C. | FUP-ORDER-8421 | UI showed stale balance on confirmation page (cache miss on first render) | Designer spec updated to require balance fetch with `revalidateOnMount: true`; re-slung Coder; customer replied with corrected balance |
