# Retrospective Card · Capstone Run (Order History)

**Run:** 2026-04-16 Order History page
**Factory Run Report:** [`factory-run-report.md`](./factory-run-report.md)
**Author:** the founder + the dev-agent observing alongside

---

## Keep

**Pack prompts are the unit of truth.** Every correction during this run was a prompt edit, committed with a conventional message, linked back to the bead. When the Architect proposed a single-option ADR, the muscle memory was *edit `packs/lessons/C1/agents/architect/prompt.template.md`* — not *re-prompt the agent*. That's the W1→C1 discipline paying off. The two prompt edits are now ambient: the next feature run inherits them for free.

## Change

**Measurable imperatives, not aspirations.** The Architect prompt already said "consider alternatives." That's an aspiration. The fix was "list at least three alternatives when a scaling question exists; one-option ADRs are rejected." That's an imperative with a count and a rejection rule. Next time through each pack's prompt file, flag any line that doesn't name a specific number, file, or rejection condition — those are the vague rules that will bite on the next feature.

## Question

**When does a prompt edit become a feedback loop?** Two edits during this run are currently logged only in `DECISIONS.md`. The reactive feedback loop pattern from W4 suggests promoting them to `feedback-loops/<slug>.md` files once they've held up across a couple of runs. Is there a threshold — one other feature's worth of evidence? three? — that should trigger promotion automatically? Leaving as an open thread to revisit after the next two factory runs.

---

## One-line summary (for the team)

The factory produced a release-ready order-history page in 78 minutes with zero ad-hoc prompts; two prompt edits were needed and both are now permanent config. Next change: tighten the remaining aspirational lines in the pack prompts before the next run.
