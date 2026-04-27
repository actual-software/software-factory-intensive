# Calculator

Minimal JavaScript calculator project.

This project is intentionally tiny: just enough structure for agents to produce
meaningful planning artifacts and implementation changes.

## Contents

| Path | Purpose |
|---|---|
| `package.json` | Makes this a recognizable Node.js project |
| `src/calculator.js` | Basic calculator functions |
| `test/calculator.test.js` | Passing tests that demonstrate the test conventions |
| `CLAUDE.md` | Minimal project rules agents read for context |

## Why Node.js

The package.json + src/ + test/ shape is intentionally small and uses Node's
built-in test runner.
