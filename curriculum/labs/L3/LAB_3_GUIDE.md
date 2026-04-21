# L3 · Deploy Designer + Coder Agents [UNDER CONSTRUCTION]

> **Note:** This lab is under construction. It will be updated in the future.

> **Goal:** Extend your software factory with the next two specialists, and demonstrate that it can now carry a planned feature from concept through to a committed implementation.

| | |
|---|---|
| **Estimated duration** | ~75 minutes |
| **Type** | LAB |
| **Deliverable** | Working Designer + Coder agents, with at least one supported MCP server each |

## Overview

L2 built the thinking half of the factory — the Planner scopes, the Architect decides. L3 builds the doing half. You'll install the Designer (turns an ADR + work package into an implementable spec) and the Coder (turns a spec into code + tests), and you'll give each a **real MCP server** so the spec and the code are anchored to systems outside the LLM's head.

Through this lab you will:
- Install and run the Designer and Coder against your project
- Attach at least one MCP server to each, chosen to ground that agent in your team's reality
- Run a feature from the ADR you produced in L2 all the way to a committed implementation with passing tests
- Iterate on one failure by editing the agent's prompt (not the chat) and re-running

> **Fired Up Pizza reference:** For a finished spec/code pair produced by this stage pair, see [`reference-project/fired-up-pizza/design/loyalty-points-spec.md`](../../../reference-project/fired-up-pizza/design/loyalty-points-spec.md) and the reference source tree under [`reference-project/fired-up-pizza/src/`](../../../reference-project/fired-up-pizza/src/). Use it as shape reference — your MCP-backed specs and code will look different because they are grounded in your systems, not pizza shop metadata.

## What You'll Build

```
    work-packages/<slug>.md   docs/adr/NNNN-<slug>.md
           (from L2)                (from L2)
                │                      │
                └──────────┬───────────┘
                           ▼
                ┌──────────────────────┐
                │   Designer (L3)      │  ←  MCP: e.g. Figma,
                │                      │     design-system repo,
                │   produces:          │     a screenshot tool
                │   design/<slug>-     │
                │     spec.md          │
                └──────────┬───────────┘
                           │  handoff (file)
                           ▼
                ┌──────────────────────┐
                │   Coder (L3)         │  ←  MCP: e.g. GitHub,
                │                      │     Postgres (staging),
                │   produces:          │     Context7, Sentry
                │   src/** + tests     │
                │   on feature branch  │
                └──────────────────────┘
```

Each attached MCP is the bridge between the model's generic knowledge and your team's specific reality: a design system your Designer should honor, a schema your Coder should query against instead of guess at, an API doc set your Coder should consult when deciding call shapes.

## Part 1: Install the L3 Factory (10 min)

> **Goal:** Bring up the factory with Designer and Coder active and carry forward the L2 artifacts the new stages will consume.

### Step 1: Install L3

```bash
# In your agent session, run:
/factory-activity-agent install L3
```

Creates `~/Projects/factory/lab_l3/l3-project/` and `~/Projects/factory/lab_l3/l3-gc-factory/` with the Planner, Architect, Designer, and Coder packs wired.

### Step 2: Confirm L2 artifacts were carried forward

The install step above bulk-copies `~/Projects/factory/lab_l2/l2-project/` into the L3 workspace — source, manifest, work packages, ADRs, iteration log, factory-pipeline, and coordination-channels all flow through.

Spot-check:

```bash
ls ~/Projects/factory/lab_l3/l3-project/docs/         # manifest + docs
ls ~/Projects/factory/lab_l3/l3-project/work-packages/
ls ~/Projects/factory/lab_l3/l3-project/docs/adr/
```

If L2 wasn't installed, the carry-forward is skipped silently — install L2 first.

### Step 3: Verify the Designer and Coder are up

```bash
/factory-activity-agent status L3
```

Expect `planner`, `architect`, `designer`, `builder` (the shipped name for Coder) all listed.

## Part 2: Read the Designer and Coder (10 min)

> **Goal:** Know what each stage reads and produces so the MCPs you attach are the right fit.

| Stage | Prompt file | Reads | Produces | Decides |
|-------|-------------|-------|----------|---------|
| **Designer** | [`packs/designer/prompts/designer.md.tmpl`](../../../packs/designer/prompts/designer.md.tmpl) | Work package, ADRs, manifest, existing source tree, design system | `design/<slug>-spec.md` — purpose, location, props, state, layout, interactions, edge cases | *What precisely gets built, where does it live, how does it look and behave?* |
| **Coder** | [`packs/builder/prompts/builder.md.tmpl`](../../../packs/builder/prompts/builder.md.tmpl) | Spec, work package, ADRs, manifest, existing source tree, `package.json` scripts | Commits on a feature branch — implementation + tests | *How does the spec translate into code that matches this project's conventions and passes its gates?* |

Notice: the Designer's output is a single file; the Coder's output is a set of commits. The coordination channels from W3 (files + work items) carry both.

## Part 3: Attach an MCP to Each Agent (20 min)

> **Goal:** Ground the Designer and Coder in systems outside the LLM so their artifacts reflect your team's real sources of truth.

Open `docs/factory-pipeline.md` and read the Designer and Coder rows from W2. Every candidate MCP your team already uses lives there.

### Step 1: Pick and install the Designer's MCP

Typical picks, in order of how often they actually change outcomes:

- **Figma MCP** — if your team works from Figma designs, this lets the Designer read the actual frames instead of inventing layouts
- **A design-system MCP** (custom, reading your component library repo) — so the Designer cites real components by name
- **A screenshot/browsing MCP** — so the Designer can reference current-state screenshots of your app when specifying layout changes
- **Context7** — for any design conventions documented in third-party libraries you use (Tailwind, Radix, shadcn)

Install the MCP per its documentation, then confirm the Designer can reach it by slinging a dry-run:

```bash
/factory-activity-agent sling L3 designer \
  "Dry run: use the <MCP name> and report what you can read. Do not produce a spec."
```

### Step 2: Wire the MCP into the Designer's prompt

Edit `packs/designer/prompts/designer.md.tmpl`:

```markdown
## Inputs you consume
  + <MCP name> for <what it provides, e.g. "Figma frames for any ticket linked to a design file">

## Work loop
  2. Research.
     + "Open the Figma frame referenced in the work package and transcribe
        component names, props, and states into the spec."
```

Restart the factory: `cd ~/Projects/factory/lab_l3/l3-gc-factory && gc stop && gc start`.

### Step 3: Pick and install the Coder's MCP

Typical picks:

- **GitHub MCP** — for branch creation, PR opening, and reading existing files without full checkout
- **Postgres (staging) MCP** — so the Coder can introspect the real schema before writing queries instead of guessing columns
- **Context7** — for library-specific syntax lookups (Next.js 16, React 19, etc.)
- **Sentry MCP** — for when the feature fixes a bug; the Coder can read the original error with stack frame context
- **A custom CLI wrapped as an MCP** — if your team has an internal tool (e.g. a schema generator, an internal API client), expose it via MCP

Install and dry-run the same way:

```bash
/factory-activity-agent sling L3 builder \
  "Dry run: use the <MCP name> and report what you can read. Do not write code."
```

### Step 4: Wire the MCP into the Coder's prompt

Edit `packs/builder/prompts/builder.md.tmpl`:

```markdown
## Inputs you consume
  + <MCP name> for <what it provides, e.g. "Postgres schema introspection on the staging DB">

## Work loop
  2. Plan.
     + "Before writing queries, introspect the target table via <MCP> and
        confirm column names/types. Never invent a schema shape."
```

Restart the factory again.

### Step 5: Sanity-check end-to-end

Sling a combined dry-run that exercises both agents against a small slice of the L2 work package + ADR:

```bash
/factory-activity-agent sling L3 designer \
  "Dry run: propose the one-paragraph approach for <feature> using your MCP access, no spec."

/factory-activity-agent sling L3 builder \
  "Dry run: propose the files you would touch for <feature> using your MCP access, no commits."
```

## Part 4: Run a Feature Through Designer → Coder (25 min)

> **Goal:** Trace one feature from its ADR to a passing commit, showing the MCPs changed the shape of the artifacts.

### Step 1: Sling the Designer

Use the L2 work package + ADR as input:

```bash
/factory-activity-agent sling L3 designer \
  "Produce the component spec for <feature>, grounded in the MCP access you were given."
```

Read `design/<slug>-spec.md`. Confirm it:
- cites the work package and ADR by path,
- names real components from your design system (if a design-system MCP is attached),
- specifies a `Location` path that matches your project's conventions.

### Step 2: Sling the Coder

```bash
/factory-activity-agent sling L3 builder \
  "Implement <feature> from design/<slug>-spec.md. Write tests for every acceptance criterion in the work package. Commit on a feature branch."
```

Read the diff. Run the project's own test / lint / build commands from inside the project workspace:

```bash
cd ~/Projects/factory/lab_l3/l3-project
npm run lint && npm test && npm run build      # or your project's equivalents
```

Every command should pass. If they don't, that's the next iteration input.

### Step 3: Iterate via config, not chat

If the spec is ambiguous, fix the Designer's prompt (`## Constraints` or the relevant step of `## Work loop`). If the code misses an acceptance criterion, fix the Coder's prompt to require a per-AC test mapping. Re-sling the failed stage.

Log each iteration in `docs/factory-iterations.md` — one line, what changed, what prompt file.

## Common Issues and Solutions

- **"The Designer spec has no real component names."** The design-system MCP isn't actually being consulted. Check that the prompt explicitly directs the agent to use it, not just lists it as an input.
- **"The Coder wrote queries against a schema that doesn't exist."** The Postgres MCP isn't wired, or the prompt doesn't require introspection before writing. Edit the prompt to make introspection a hard gate.
- **"Tests pass but the feature is wrong."** The work package's acceptance criteria were ambiguous. Edit the Planner's prompt (back in L2) to tighten AC format, then re-sling *the Planner*. L3 iterations can expose L2 weaknesses — follow them upstream.
- **"MCP auth drops between sessions."** Authenticate from inside the agent's session (`gc session peek <rig>/<stage>`), not from your local shell.
- **"Lint or typecheck fails on the Coder's output."** Add those commands to the Coder's `## Constraints` so it runs them before completing. A reviewer-caught lint failure is a Coder prompt bug.

## Exit Criteria

Before leaving this lab, verify all of these:

- [ ] `/factory-activity-agent status L3` shows `designer` and `builder` running
- [ ] Each agent has at least one MCP wired and passing a dry-run
- [ ] `design/<slug>-spec.md` exists, cites the work package + ADR, and names real components
- [ ] Coder's commits on a feature branch pass the project's own test / lint / build gates
- [ ] At least one iteration logged in `docs/factory-iterations.md` since L2

## Quick Reference: What You Built

| Artifact | Location | What It Does |
|----------|----------|--------------|
| L3 factory | `~/Projects/factory/lab_l3/l3-gc-factory/` | Factory with Planner → Architect → Designer → Coder active |
| Designer MCP wiring | `packs/designer/prompts/designer.md.tmpl` | Bridges Designer to your visual / design-system sources |
| Coder MCP wiring | `packs/builder/prompts/builder.md.tmpl` | Bridges Coder to your real data / codebase sources |
| Component spec | `design/<slug>-spec.md` | Concrete implementable description of the feature |
| Feature branch + tests | Your project's git tree under the L3 workspace | The actual code, grounded in MCP-sourced truth |

## Next Steps

**[L4](../L4/LAB_4_GUIDE.md)** installs the Reviewer and Deployer against your project. Both read the `PROJECT_MANIFEST` for their standards (Review Standards and Release Criteria respectively), and the Reviewer will inspect the exact feature branch you produced in this lab.

Bring to L4:

- [ ] A running L3 factory with the feature branch from Part 4 committed
- [ ] Updated `docs/factory-pipeline.md` reflecting the Designer + Coder MCPs
- [ ] Your iteration log with at least one L3 entry
