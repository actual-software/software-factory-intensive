# Project Manifest: [Your Project Name]

<!-- Copy from curriculum/PROJECT_MANIFEST_TEMPLATE.md and fill in. -->
<!-- This file is the single source of truth for all agent behavior. -->
<!-- Review standards, release criteria, and success metrics all live here. -->

## Overview

[What does this software do? Who are the users?]

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | | |
| Backend | | |
| Database | | |
| Testing | | |

## Project Structure

```
[Your directory tree]
```

## Domain Model

```
[Your core entities and relationships]
```

## Conventions

- [File naming, commit messages, branch naming]

## Constraints

- [Hard limits and explicit exclusions]

---

## Task Inputs

| Agent | Receives | From |
|-------|----------|------|
| Planner | Feature request | |
| Architect | Work package | `work-packages/<slug>.md` |
| Designer | Work package + ADR | `work-packages/` + `docs/adr/` |
| Coder | Component spec + test cases | `design/<slug>-spec.md` + work package |
| Reviewer | Code diff + spec + review standards | Feature branch + `design/` + this manifest |
| Deployer | Review report + release criteria | `review-reports/` + this manifest |

## Services to Connect

| Service | Purpose | Config Required |
|---------|---------|-----------------|
| | | |

## Success Criteria

### Per-Feature Success

- [ ] All acceptance criteria from work package met
- [ ] Code review approved with no high-severity findings
- [ ] Tests pass
- [ ] Lint clean

### Factory-Level Success

- [ ] Feature completed with zero ad-hoc prompts
- [ ] All 6 pipeline stages produced artifacts

---

## Review Standards

### Spec Compliance

- [What must match the component spec?]

### Style

- [Your style rules]

### Security

- [Your security checks]

### Severity Scale

- **Low**: [definition]
- **Medium**: [definition]
- **High**: [definition]

---

## Release Criteria

### Required (all must PASS)

1. [Criterion 1]
2. [Criterion 2]

### Informational (non-blocking)

- [Metric 1]
