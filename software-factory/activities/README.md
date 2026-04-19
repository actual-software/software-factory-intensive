# Activities

This directory is where you do your work for each session of the Software Factory Intensive. It is separate from `../curriculum/`, which contains the walkthroughs you *read*, and separate from `../packs/`, which contains the canonical, shipped agent packs.

| Tree | What goes here |
|------|----------------|
| `baseline/B1/` | Baseline factory setup — GasCity install + first factory |
| `workshops/W1..W4/` | Deliverables from each workshop (design docs, config files, feedback-loop notes) |
| `labs/L1..L4/` | Deliverables from each lab plus any customised pack copies |
| `capstone/C1/` | Capstone run report and retrospective |

## The additive, independent model

Every session ships a ready-to-use reference pack under `../packs/<agent>/`. The curriculum is designed so that **skipping a session does not break the pipeline** — you just include the shipped pack as-is instead of your own customised copy.

Within a session you can customise a pack two ways:

1. **Copy it** — `cp -r ../../packs/<agent> packs/<agent>/` inside the session's activity folder, edit your copy, and point `../../my-factory/city.toml`'s `includes` at `../activities/<session>/packs/<agent>` instead of the shipped `../packs/<agent>`.
2. **Leave it alone** — include the shipped pack directly and focus on the workshop's conceptual deliverables.

Either way, at the end of the session you **update `../my-factory/city.toml`** to reflect which packs the factory should run. Each session's README tells you the exact lines.

## Typical session flow

1. Open `../curriculum/<session>/README.md` and read the walkthrough.
2. Work inside this session's folder (`activities/<session>/`). Most sessions ask for one or two markdown deliverables (a workflow card, a factory-wiring doc, an orchestrator.yaml, a feedback-loop note).
3. For labs that deploy a new agent: copy the shipped pack into `activities/<session>/packs/<agent>/`, customise, and wire it into `../my-factory/city.toml`. (If you skip customisation, just wire the shipped `../packs/<agent>` path directly.)
4. Run `gc service restart && gc doctor` from `../my-factory/` to reload the city.

## Getting un-stuck

If a session breaks your factory:

1. `git checkout activities/<session>/packs/` to discard the customised pack copy.
2. Edit `../my-factory/city.toml` so the include points at `../packs/<name>` (shipped) instead of `../activities/<session>/packs/<name>` (your copy).
3. `gc service restart` from `my-factory/`.

You lose the customisation but keep a working factory, and you can retry the customisation later.

## Sessions

| Session | Folder | Key deliverable |
|---------|--------|-----------------|
| B1 | [`baseline/B1/`](baseline/B1/) | Baseline factory setup — GasCity install + working factory |
| W1 | [`workshops/W1/`](workshops/W1/) | Workflow card — single-agent workflow discipline |
| W2 | [`workshops/W2/`](workshops/W2/) | Factory wiring — per-agent table + integration points |
| W3 | [`workshops/W3/`](workshops/W3/) | `orchestrator.yaml` + gate justification doc |
| W4 | [`workshops/W4/`](workshops/W4/) | Feedback-loops — reactive / aggregate / external rules |
| L1 | [`labs/L1/`](labs/L1/) | Filled-in `CLAUDE.md` + `DECISIONS.md` log |
| L2 | [`labs/L2/`](labs/L2/) | First work package + ADR; Planner + Architect packs wired |
| L3 | [`labs/L3/`](labs/L3/) | Design spec + implementation; Designer + Builder packs wired |
| L4 | [`labs/L4/`](labs/L4/) | Review report + release gate; Reviewer + Release-Gate packs wired |
| C1 | [`capstone/C1/`](capstone/C1/) | Factory run report + retrospective card |
