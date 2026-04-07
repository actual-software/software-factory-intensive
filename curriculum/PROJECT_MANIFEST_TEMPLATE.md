# Project Manifest Template

**Purpose:** This template helps you prepare the essential information about your software project before attending the Software Factory Intensive. Coming prepared with this information ensures you can immediately apply the workshop learnings to your actual work.

**Instructions:** Fill out each section below for the project you plan to use during the intensive. If you don't have a project, you may use the reference project (Fired Up Pizza) provided during the workshop.

---

## Project Information

### Name of Software Project
*What is your project called?*

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

### Services Used
*List all external services, APIs, databases, or platforms your project uses to operate and build the software.*

**Examples:** AWS S3, Stripe API, PostgreSQL, GitHub Actions, Vercel, Auth0, SendGrid, etc.

```
- [Service 1]: [Purpose]
- [Service 2]: [Purpose]
- [Service 3]: [Purpose]
...
```

### Dependencies
*List software libraries, frameworks, or other codebases your project depends on.*

**Examples:** React, Next.js, Django, Express, TensorFlow, etc.

```
- [Dependency 1]: [Version if relevant]
- [Dependency 2]: [Version if relevant]
- [Dependency 3]: [Version if relevant]
...
```

### Previous Architectural or Design Decisions
*Describe any significant technical decisions that have already been made that would affect how a software factory should operate.*

**Examples:**
- "We use a microservices architecture with 5 separate services"
- "All data must remain in EU data centers for GDPR compliance"
- "We follow trunk-based development with feature flags"
- "PRs require 2 approvals and must pass 95% test coverage"

```
[Your answer here - bullet points preferred]
```

---

## Development Workflow

### Current Development Process
*How do you currently build and ship features?*

**Examples:**
- "Designer creates Figma mockups → Engineer implements → QA tests → Deploy to staging → Production"
- "Product manager writes user stories → Team picks from backlog → Individual engineers implement and deploy"

```
[Your answer here - 2-3 sentences]
```

### Pain Points or Bottlenecks
*What slows you down today? Where do errors occur most frequently?*

```
[Your answer here - bullet points]
```

---

## Gas City Factory Goals

### What do you hope your software factory will automate?
*Be specific about which parts of your development workflow you want the factory to handle.*

**Examples:**
- "Automate code generation from design specs"
- "Auto-generate unit tests for new features"
- "Automatically review PRs for architectural consistency"
- "Generate deployment scripts and infrastructure config"

```
[Your answer here - bullet points]
```

### What should NOT be automated?
*What decisions or tasks require human judgment?*

```
[Your answer here - bullet points]
```

---

## Additional Context

### Repository Information
*If applicable:*

- **Repository URL:** `[GitHub/GitLab/etc URL or "Private"]`
- **Primary programming language(s):** `[e.g., TypeScript, Python, Go]`
- **Deployment target:** `[e.g., AWS, Vercel, self-hosted]`

### Team Context
*Optional but helpful:*

- **Team size:** `[Number of engineers]`
- **Release cadence:** `[e.g., Daily, weekly, monthly]`
- **Current AI tools in use:** `[e.g., GitHub Copilot, ChatGPT, Claude Code, none]`

---

## Pre-Workshop Checklist

Before arriving at the workshop, ensure you have:

- [ ] Completed this project manifest
- [ ] Identified 2-3 specific features or user stories you could use as test cases
- [ ] Gathered any relevant documentation (architecture diagrams, API docs, coding standards)
- [ ] Confirmed you have access to your project repository (if using your own project)
- [ ] Installed required tools: Git, Docker (if applicable), your preferred code editor
- [ ] Reviewed the [Gas City Setup Guide](../GAS_CITY_SETUP_GUIDE.md) (optional but recommended)

---

**Bring this completed manifest to the workshop!** We will reference it throughout the intensive as we build your software factory.
