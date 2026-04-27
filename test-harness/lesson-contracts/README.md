# Lesson Contracts

These TOML files are the expected lesson shapes consumed by
`test-harness/lesson-pack-lint.py`.

Each contract names:

- the self-contained lesson pack directory
- the entry FormulaV2 graph
- the rig-scoped roles the pack must define locally
- the student/instructor docs that must match the lesson flow
- the minimum graph steps, dependencies, binding-qualified routes, and artifact
  contracts

Use these contracts for red-green migration work. Update a contract only when
the teaching architecture changes; otherwise, make the lesson content satisfy
the contract.
