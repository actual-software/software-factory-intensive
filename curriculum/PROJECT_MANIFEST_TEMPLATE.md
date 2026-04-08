# Project Manifest Template

**Purpose:** This template helps you prepare the essential information about your software project before attending the Software Factory Intensive. Your completed manifest becomes the single source of truth that every agent in your factory reads — it defines tech stack, conventions, review standards, release criteria, and success metrics.

**Instructions:** Fill out each section below for the project you plan to use during the intensive. If you don't have a project, you may use the reference project (Fired Up Pizza) provided during the workshop.

---

## Project Information

### Name of Software Project

```
[Your answer here]
```

### Objective of the Project
*What does this software do? What problem does it solve? Who are the users?*

```
[Your answer here - 2-3 sentences]
```

---

## Technical Context

### Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | | |
| Styling | | |
| Backend | | |
| Database | | |
| Testing | | |
| Linting | | |

### Project Structure
*Describe your directory layout — where does code live, where do docs go?*

```
[Your directory tree here]
```

### Domain Model
*What are the core entities and their relationships?*

```
[Your domain model here]
```

### Conventions
*File naming, commit messages, branch naming, API patterns, etc.*

```
[Your conventions here - bullet points]
```

### Constraints
*Hard limits on the project — what is explicitly out of scope or disallowed?*

```
[Your constraints here - bullet points]
```

### Previous Architectural or Design Decisions
*Significant technical decisions already made that affect how the factory should operate.*

```
[Your decisions here - bullet points]
```

---

## Task Inputs

*Define what goes into each task at each stage of the factory pipeline. This tells agents what to expect and where to find their inputs.*

| Agent | Receives | From |
|-------|----------|------|
| Planner | Feature request | [Where do feature requests come from? Jira, Linear, GitHub Issues, manual?] |
| Architect | Work package | `work-packages/<slug>.md` |
| Designer | Work package + ADR | `work-packages/` + `docs/adr/` |
| Coder | Component spec + test cases | `design/<slug>-spec.md` + work package |
| Reviewer | Code diff + spec + review standards | Feature branch + `design/` + this manifest |
| Deployer | Review report + release criteria | `review-reports/` + this manifest |

---

## Services to Connect

*List all external services your project uses. These determine which Gas City integrations to configure.*

| Service | Purpose | Config Required |
|---------|---------|-----------------|
| [e.g., GitHub] | [Source control, PRs] | [GITHUB_TOKEN] |
| [e.g., Jira] | [Issue tracking] | [JIRA_URL, JIRA_API_TOKEN] |
| [e.g., AWS S3] | [File storage] | [AWS credentials] |
| [e.g., Vercel] | [Deployment] | [VERCEL_TOKEN] |
| [e.g., Sentry] | [Error tracking] | [SENTRY_AUTH_TOKEN] |
| | | |

---

## Success Criteria

### Per-Feature Success
*How do you know a single feature is done?*

- [ ] [e.g., All acceptance criteria from work package met]
- [ ] [e.g., Code review approved with no high-severity findings]
- [ ] [e.g., All tests pass]
- [ ] [e.g., Deployed to staging and smoke tests pass]

### Factory-Level Success
*How do you know the factory itself is working?*

- [ ] [e.g., Feature completed with zero ad-hoc prompts]
- [ ] [e.g., All 6 pipeline stages produced artifacts]
- [ ] [e.g., Handoffs between agents used defined artifact paths]

---

## Review Standards

*What does your Reviewer agent check? Define severity levels so findings are actionable.*

### Spec Compliance

```
[e.g., Every prop from the component spec must be implemented]
[e.g., Edge cases (empty, error, loading) must be handled]
```

### Style

```
[e.g., No inline styles]
[e.g., Components under 200 lines]
[e.g., No `any` types in TypeScript]
```

### Security

```
[e.g., No user input rendered without sanitization]
[e.g., API endpoints validate all inputs]
[e.g., SQL queries use parameterized statements]
```

### Severity Scale

- **Low**: [e.g., style nit, minor improvement]
- **Medium**: [e.g., missing test, incomplete error handling]
- **High**: [e.g., security issue, data corruption risk, spec violation]

---

## Release Criteria

*What must be true before a feature is deployment-ready? The Deployer agent evaluates these as binary PASS/FAIL gates.*

### Required (all must PASS)

1. [e.g., All acceptance criteria met]
2. [e.g., Review approved with no open high-severity findings]
3. [e.g., Tests pass]
4. [e.g., Lint clean]
5. [e.g., Branch mergeable with main]

### Informational (reported but non-blocking)

- [e.g., Test coverage percentage]
- [e.g., Bundle size delta]

---

## Development Workflow

### Current Development Process
*How do you currently build and ship features?*

```
[Your answer here - 2-3 sentences]
```

### Pain Points or Bottlenecks
*What slows you down today?*

```
[Your answer here - bullet points]
```

---

## Factory Goals

### What do you hope your software factory will automate?

```
[Your answer here - bullet points]
```

### What should NOT be automated?

```
[Your answer here - bullet points]
```

---

## Repository Information

- **Repository URL:** `[GitHub/GitLab/etc URL or "Private"]`
- **Primary language(s):** `[e.g., TypeScript, Python, Go]`
- **Deployment target:** `[e.g., AWS, Vercel, self-hosted]`

## Team Context

- **Team size:** `[Number of engineers]`
- **Release cadence:** `[e.g., Daily, weekly, monthly]`
- **Current AI tools in use:** `[e.g., GitHub Copilot, Claude Code, none]`

---

## Pre-Workshop Checklist

- [ ] Completed this project manifest (all sections above)
- [ ] Identified 2-3 features or user stories to use as test cases
- [ ] Confirmed access to your project repository
- [ ] Installed Gas City: `brew install gastownhall/gascity/gascity`
- [ ] Installed Claude Code (or your preferred coding agent)

**Bring this completed manifest to the workshop!**
