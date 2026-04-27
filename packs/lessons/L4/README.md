# Delivery Review Factory

This pack turns one feature request into a planned, designed, implemented, and
tested project change with review and release-gate records.

Runtime contents:

- `planner`: writes `docs/plans/<slug>.md`
- `architect`: writes `docs/architecture/<slug>.md`
- `designer`: writes `docs/designs/<slug>.md`
- `builder`: changes project code, runs tests, and commits the implementation
- `reviewer`: writes `docs/reviews/<slug>.md`
- `release-gate`: writes `docs/releases/<slug>.md`
- `mol-delivery-review`: graph that routes the work through those roles

The pack is self-contained. It does not import any other pack.
