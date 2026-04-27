# Feature Delivery Factory

This pack turns one feature request into a planned, designed, implemented, and
tested project change.

Runtime contents:

- `planner`: writes `docs/plans/<slug>.md`
- `architect`: writes `docs/architecture/<slug>.md`
- `designer`: writes `docs/designs/<slug>.md`
- `builder`: changes project code, runs tests, and commits the implementation
- `mol-feature-delivery`: graph that routes the work through those roles

The pack is self-contained. It does not import any other pack.
