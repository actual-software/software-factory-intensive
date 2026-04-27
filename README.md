# Software Factory Intensive

Hands-on curriculum for building small software factories with Gas City.

The active curriculum is built around self-contained lesson packs. Each runnable lab has one complete factory under `packs/lessons/<lesson>/`: agents, prompts, formulas, doctors, and commands live together so students can inspect the whole system without chasing shared pack imports.

## Before You Start

Install Gas City and the supporting tools:

```bash
brew install gastownhall/gascity/gascity
gc version
```

You also need a CLI coding agent installed and authenticated. The lesson content is written around Gas City concepts rather than one provider.

Bring a real project or use the bundled fixture/reference material. Before the first lab, write a short project overview from [`curriculum/PROJECT_OVERVIEW_TEMPLATE.md`](curriculum/PROJECT_OVERVIEW_TEMPLATE.md).

## Architecture

The student path is:

```text
choose lesson factory pack -> sync the existing project rig -> sling one request -> formula routes work
```

The factory path is not based on hand-made stage queues. Formulas define the workflow graph; beads record runtime work and artifacts; labels are metadata for searching and reporting.

## Repo Layout

```text
software-factory-intensive/
├── my-factory/                 # city templates and quickstart
├── packs/
│   ├── lessons/
│   │   ├── L2/                 # planner + architect factory
│   │   ├── L3/                 # planner + architect + designer + builder
│   │   ├── L4/                 # delivery review factory
│   │   └── C1/                 # end-to-end release factory
│   └── workshop/               # optional service-integration helpers
├── curriculum/                 # long-form walkthroughs
├── activities/                 # student deliverables and short instructions
└── reference-project/          # example project artifacts
```

## Lesson Packs

Each lesson pack is portable factory code. The folder name may include a lesson number for navigation, but files inside the pack should read like production factory definitions: no prompt should tell an agent it is in a class, lab, or workshop.

| Lesson | Factory Pack | Entry Formula | Entry Target |
|---|---|---|---|
| L2 | `packs/lessons/L2` | `mol-feature-intake` | `<rig>/factory.planner` |
| L3 | `packs/lessons/L3` | `mol-feature-delivery` | `<rig>/factory.planner` |
| L4 | `packs/lessons/L4` | `mol-delivery-review` | `<rig>/factory.planner` |
| C1 | `packs/lessons/C1` | `mol-release-delivery` | `<rig>/factory.planner` |

## Quickstart

Create local runtime config from the templates:

```bash
cp my-factory/pack.toml.template my-factory/pack.toml
cp my-factory/city.toml.template my-factory/city.toml
```

Register the city and add your project rig:

```bash
cd my-factory
gc register .
gc rig add ~/Projects/your-project
gc doctor --fix
```

The default template selects the L2 factory:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L2"
```

When you move to another runnable lesson, update that source path and sync the existing rig:

```bash
gc --rig your-project import remove factory
gc --rig your-project import add ../packs/lessons/L3 --name factory
```

Then sling work to the lesson formula:

```bash
gc sling planner \
  "Add a percent operation: percent(whole, fraction) returns whole*fraction/100" \
  --on mol-feature-delivery
```

Watch progress with:

```bash
gc events --follow
gc session list
gc session peek your-project/factory.planner
gc graph <workflow-bead-id>
```

Start with [`curriculum/workshops/W1/README.md`](curriculum/workshops/W1/README.md), then follow the session map in [`curriculum/README.md`](curriculum/README.md).
