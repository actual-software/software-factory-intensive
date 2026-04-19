# actual-factory (composition pack)

Brings up the **6 essential Agent Operations** of the Actual Software
Factory in one include. Depends on the 6 sibling leaf packs under
`software-factory/packs/`. The optional 7th — improver — is opt-in,
not bundled here.

## Usage

```toml
# city.toml at the top level of software-factory/packs/
[workspace]
name = "actual-factory"
provider = "claude"
includes = ["all"]
```

Or from outside this directory, with an absolute or relative path:

```toml
includes = ["/abs/path/to/software-factory/packs/all"]
```

To add the optional improver, include it explicitly alongside `all`:

```toml
includes = ["all", "../improver"]
```

## The 6 essential agents (bundled)

| Operation | Pack | Label gate |
|-----------|------|------------|
| Architect | `../architect` | `needs-architecture` |
| Plan / Work Breakdown | `../planner` | `needs-plan` |
| UI/UX Design | `../designer` | `needs-design` |
| Code | `../coder` | `ready-to-build` |
| Code Review (incl. AC verification) | `../reviewer` | `needs-review` |
| Deploy | `../deployer` | `ready-to-ship` |

## Optional 7th agent (opt-in)

| Operation | Pack | Label gate |
|-----------|------|------------|
| Improve / Feedback Loop | `../improver` | cooldown (24h) |

Introduced in W4. Add it to your `includes` only if your factory
needs the continuous-improvement loop — the 6 essentials run
end-to-end without it.

## Handoff flow

```
(user or tracker issue)
    │
    ▼  needs-architecture
architect  ───────────►  needs-plan  ─►  planner
    ▲                                      │
    │ (hand-back)                          ▼
    │                          needs-design / ready-to-build
    │                                      │
    │                      ┌───────────────┴───────────────┐
    │                      ▼                               ▼
    │                  designer                          coder
    │                      │                               │
    │                      └─►  ready-to-build  ──────────►│
    │                                                      ▼
    │                                              needs-review
    │                                                      │
    │                                                      ▼
    │                                                  reviewer
    │                                                  (also verifies
    │                                                   AC coverage)
    │                                            ┌─────────┴─────────┐
    │                                            ▼                   ▼
    │                                  ready-to-build           ready-to-ship
    │                                  (back to coder)               │
    │                                                                ▼
    │                                                            deployer
    │                                                                │
    │                                          (optional 7th)        ▼
    │                                                         needs-improve
    │                                                                │
    │                                                                ▼
    │                                                           improver
    │                                                                │
    └────────────────────────────────────────────────────────────────┘
                          (loop back to any upstream agent)
```

## Why this is a pack and not a master formula

The whole factory runs on **label-based handoff**. There is no master
orchestrator, no pipeline DAG hardcoded anywhere. Each pack's order
gate watches for its own label. Rewire the flow by changing labels,
not by editing Go or TOML.

This honors Gas City's core invariant: **ZERO hardcoded roles**.
Every leaf pack is self-describing. This composition pack just
bundles them for convenience.
