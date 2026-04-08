# Project Manifest: [Your Project Name]

Fill this out before the workshop. This becomes the single source of truth that every agent in your factory reads. See `reference-project/fired-up-pizza/docs/PROJECT_MANIFEST.md` for a completed example.

---

## Overview

What does this software do? Who are the users?

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | |
| Backend | |
| Database | |
| Testing | |

## Project Structure

```
[Your directory tree]
```

## Domain Model

```
[Core entities and their relationships]
```

## Conventions

- [File naming, commit messages, branch naming, API patterns]

## Constraints

- [What is explicitly out of scope or disallowed]

---

## Task Inputs

Where do feature requests come from, and how do they flow through the factory?

| Agent | Receives | From |
|-------|----------|------|
| Planner | Feature request | [Jira, Linear, GitHub Issues, manual?] |
| Architect | Work package | `work-packages/<slug>.md` |
| Designer | Work package + ADR | `work-packages/` + `docs/adr/` |
| Coder | Component spec | `design/<slug>-spec.md` |
| Reviewer | Code + spec | Feature branch + `design/` |
| Deployer | Review report | `review-reports/` |

## Services to Connect

| Service | Purpose |
|---------|---------|
| [e.g., GitHub] | [Source control] |
| [e.g., Jira] | [Issue tracking] |

## Success Criteria

How do you know a feature is done?

- [ ] Acceptance criteria met
- [ ] Code review approved
- [ ] Tests pass
- [ ] [Your additional criteria]

How do you know the factory is working?

- [ ] Zero ad-hoc prompts needed
- [ ] All 6 stages produced artifacts

---

## Review Standards

What should the Reviewer agent check?

- **Spec compliance**: [e.g., every prop implemented, edge cases handled]
- **Style**: [e.g., no inline styles, components under 200 lines]
- **Security**: [e.g., inputs sanitized, queries parameterized]

Severity: **Low** (nit) · **Medium** (missing test) · **High** (security issue)

## Release Criteria

What must pass before deployment?

1. [e.g., All acceptance criteria met]
2. [e.g., Review approved, no high-severity findings]
3. [e.g., Tests and lint pass]
4. [e.g., Branch mergeable with main]

---

## Pre-Workshop Checklist

- [ ] This manifest is complete
- [ ] 2-3 features identified as test cases
- [ ] Project repo cloned and accessible
- [ ] `brew install gastownhall/gascity/gascity`
- [ ] Claude Code installed
