# Release Criteria

Gate criteria evaluated by the Deployer agent before a feature is marked deployment-ready.

## Required (all must PASS)

1. **Acceptance criteria met** — every AC in the work package is satisfied
2. **Review approved** — review report verdict is APPROVE (no open high-severity findings)
3. **Tests pass** — `npm test` exits 0
4. **Lint clean** — `npm run lint` exits 0
5. **No untracked files** — `git status` shows clean working tree within feature scope
6. **Branch mergeable** — no merge conflicts with main

## Informational (reported but non-blocking)

- Test coverage percentage
- Bundle size delta
- Number of new dependencies added
- Performance regression indicators
