# W2 · Design the 6-Agent Software Factory — Activity

**Walkthrough:** [`../../../curriculum/workshops/W2/README.md`](../../../curriculum/workshops/W2/README.md)
**Reference example:** [`../../../reference-project/fired-up-pizza/docs/factory-wiring.md`](../../../reference-project/fired-up-pizza/docs/factory-wiring.md)

## Deliverable

One file in this folder:

* `factory-wiring.md` — a per-agent table for the six agents (PM, Architect, Designer, Builder, Reviewer, Release-Gate) showing input artifact, output artifact, config file, and the integration surface each agent touches (e.g. Jira, Slack, GitHub).

The six agents map to these shipped packs:

| Role in the curriculum | Pack path |
|------------------------|-----------|
| PM | `../../../packs/pm` |
| Architect | `../../../packs/architect` |
| Designer | `../../../packs/designer` |
| Builder (Coder) | `../../../packs/builder` |
| Reviewer | `../../../packs/reviewer` |
| Release-Gate (Deployer) | `../../../packs/release-gate` |

## Workspace wiring

W2 is a design session — no pack is installed yet, so `../../../my-factory/city.toml` stays empty. The next lab (L2) adds the first two packs.

## Exit criteria

* [ ] `factory-wiring.md` exists and covers all six agents.
* [ ] Each row names a concrete artifact path (e.g. `work-packages/<slug>.md`) and a concrete prompt file (e.g. `../../../packs/builder/prompts/builder.md.tmpl`).
* [ ] Integration surface column lists the specific external services your project touches — not generic "any tracker".

## Skipped this session?

L2 onwards work without a wiring doc, but you'll reinvent the table in your head every time. If you skip W2, at minimum skim the reference `factory-wiring.md` before L2 so you know which files you're about to edit.
