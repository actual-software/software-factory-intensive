# actual-factory (composition pack)

Brings up all 8 Agent Operations of the Actual Software Factory in
one include. Depends on the 8 sibling leaf packs under
`examples/actual/`.

## Usage

```toml
# city.toml at the top level of examples/actual/
[workspace]
name = "actual-factory"
provider = "claude"
includes = ["all"]
```

Or from outside this directory, with an absolute or relative path:

```toml
includes = ["/abs/path/to/gascity/examples/actual/all"]
```

## The 8 agents

| Operation | Pack | Label gate |
|-----------|------|------------|
| Architect | `../architect` | `needs-architecture` |
| Plan / Work Breakdown | `../pm` | `needs-pm` |
| UI/UX Design | `../designer` | `needs-design` |
| Validate / Test Cases | `../validator` | `needs-tests` |
| Build Code | `../builder` | `ready-to-build` |
| Code Review | `../reviewer` | `needs-review` |
| Deploy / Release Gate | `../release-gate` | `ready-to-ship` |
| Improve / Feedback Loop | `../improver` | cooldown (24h) |

## Handoff flow

```
(user or tracker issue)
    │
    ▼  needs-architecture
architect  ───────────►  needs-pm  ─►  pm
    ▲                                      │
    │ (hand-back)                          ▼
    │                          needs-design / needs-tests / ready-to-build
    │                                      │
    │                      ┌───────────────┼───────────────┐
    │                      ▼               ▼               ▼
    │                  designer       validator         builder
    │                      │               │               │
    │                      └───►           └───►           │
    │                      ready-to-build  ready-to-build  │
    │                                                      ▼
    │                                              needs-review
    │                                                      │
    │                                                      ▼
    │                                                  reviewer
    │                                            ┌─────────┴─────────┐
    │                                            ▼                   ▼
    │                                  ready-to-build           ready-to-ship
    │                                  (back to builder)             │
    │                                                                ▼
    │                                                         release-gate
    │                                                                │
    │                                                                ▼
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
