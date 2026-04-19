# actual-designer

The **UI/UX Design** agent of the Actual Software Factory. One of the
leaf Agent-Operation packs under `software-factory/packs/`. Maps to
the "Design" operation at https://www.actual.ai/softwarefactory.

## Persona

UI/UX Designer + Accessibility Engineer. User-centered,
accessibility-first, usability advocate. Targets WCAG 2.1 AA. Works
within the existing design system rather than inventing new patterns.

## What it does

- Reads beads labelled `needs-design`
- Writes wireframes and interaction specs under
  `.actual/designs/<slug>.md` (ASCII sketches, component reuse lists,
  interaction tables)
- Audits each design against WCAG 2.1 AA (focus order, ARIA,
  contrast, keyboard nav, screen-reader labels)
- Hands off to the coder via `ready-to-build`

## How to run

```bash
gc rig add /path/to/your/project
gc start software-factory/packs/
```

Standalone:
```toml
[workspace]
includes = ["software-factory/packs/designer"]
```

## Handoff

- **coder** via `ready-to-build`
