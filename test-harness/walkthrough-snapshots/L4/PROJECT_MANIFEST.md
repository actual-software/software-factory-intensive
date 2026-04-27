# Project Manifest

## Overview
Calculator library with basic arithmetic operations.

## Tech Stack
Node.js, native test runner.

## Review Standards

| Category | Rule | Severity |
|----------|------|----------|
| Style | All exported functions must have JSDoc comments | Medium |
| Security | No hardcoded credentials or secrets | Critical |
| Correctness | All error paths must be handled explicitly | High |
| Testing | New public functions must have corresponding test cases | High |

## Release Criteria

| Criterion | Gate |
|-----------|------|
| All tests pass | PASS/FAIL |
| No Critical review findings | PASS/FAIL |
| Implementation matches design spec | PASS/FAIL |
| Code committed to a branch | PASS/FAIL |
| Review verdict is not REQUEST_CHANGES | PASS/FAIL |
| No TODO comments in new code | PASS/FAIL |
