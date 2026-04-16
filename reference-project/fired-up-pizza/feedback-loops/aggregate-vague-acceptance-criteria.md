# Feedback Loop · Vague Acceptance Criteria from Planner

**Category:** Aggregate
**Created:** 2026-04-10
**Last triggered:** 2026-04-15

---

## Signal

Source: `work-packages/*.md`
Pattern: Any work package where at least one Acceptance Criterion contains the words `fast`, `nice`, `clean`, `good`, `intuitive`, `simple`, or `obvious` — words that are not measurable.

Detection script: `feedback-loops/rules/detect-vague-acs.sh`

```bash
#!/bin/bash
# detect-vague-acs.sh — flags work packages with unmeasurable ACs.
# Exits 0 if clean; exits 1 (with file list) if vague terms found.

set -euo pipefail

VAGUE='\b(fast|nice|clean|good|intuitive|simple|obvious)\b'
OFFENDERS=$(grep -lniE "$VAGUE" work-packages/*.md 2>/dev/null || true)

if [[ -n "$OFFENDERS" ]]; then
  echo "Vague ACs found in:"
  echo "$OFFENDERS"
  exit 1
fi
```

## Trigger

Five occurrences across three or more different features within one calendar week. Aggregate loops require repetition — a single vague AC is a nit; a pattern means the Planner prompt is under-constrained.

As of 2026-04-15 the counter reached 5/5 — triggered.

## Target

Two files:

1. `packs/planner/prompts/planner.md` — Quality Gate section.
2. `docs/PROJECT_MANIFEST.md` — Success Criteria section.

## Action

**1. Tighten the Planner Quality Gate.** Append to `packs/planner/prompts/planner.md`:

```markdown
## Quality Gate: Measurable Acceptance Criteria

Every Acceptance Criterion must be *independently verifiable* by running a
command or inspecting a specific artifact.

BAD:  "Order lookup should be fast"
GOOD: "Order lookup by phone returns in <200ms on a 10k-order fixture"

BAD:  "UI looks nice"
GOOD: "Matches the visual style of src/components/OrderStatusCard.tsx —
       same spacing, same border radius, same typography"

Before finalizing a work package, re-read every AC and answer: 'what
command would prove this is met?' If the answer is 'ask a human,' rewrite
the AC until the answer is a command.
```

**2. Tighten the Project Manifest.** In `docs/PROJECT_MANIFEST.md`, update the Per-Feature Success section to include:

```markdown
- Every Acceptance Criterion names a measurable value or a comparable artifact.
- "Fast" is not a criterion; "<N ms" is a criterion.
- "Looks good" is not a criterion; "matches src/components/<FileName>.tsx" is a criterion.
```

Then regenerate any still-open work packages by re-slinging the Planner. Old work packages with vague ACs stay as-is (historical record), but any new run must satisfy the updated gate.

## Verification

- `feedback-loops/rules/detect-vague-acs.sh` passes on all new work packages committed after the rule landed.
- The 5/5 counter in the history table resets to 0/5 as new runs accumulate clean work packages.

## History

| Date | Feature | Vague terms found | Planner re-slung? |
|------|---------|-------------------|-------------------|
| 2026-04-10 | Loyalty Points v1 | "fast lookup", "nice balance UI" | Yes — manually re-prompted (pre-rule) |
| 2026-04-11 | Menu Category v1 | "clean edit flow" | Yes — manually re-prompted (pre-rule) |
| 2026-04-12 | Pizza Customization fixes | "intuitive toppings UI" | Yes — manually re-prompted (pre-rule) |
| 2026-04-14 | Order Status Polling | "good status indicator" | Yes — manually re-prompted (pre-rule) |
| 2026-04-15 | Order History | "fast pagination" | Yes — manually re-prompted (pre-rule). **Trigger fired.** |
| 2026-04-16 | (rule applied) | — | — |
