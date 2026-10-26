# My Factory

This directory is the Gas City city root students register and run from.

## Setup

```bash
cd my-factory
cp pack.toml.template pack.toml
cp city.toml.template city.toml
gc register .
gc rig add ~/path/to/your-repo
```

Formula v2 is enabled once in `city.toml`. Lesson selection also happens in
`city.toml`, via the rig's `factory` import:

```toml
[[rigs]]
name = "<rig>"  # your rig: the basename gc rig add derives (see: gc rig list)
[rigs.imports.factory]
source = "../packs/lessons/L2"
```

When switching lessons, change that source path and apply it:

```bash
gc restart
```

Then start the lesson through its documented formula entrypoint, for example:

```bash
gc sling planner "Add a small feature" --on mol-feature-delivery
```

Use `gc events --follow`, `gc session list`, `gc session peek <session-id>`,
`gc graph <workflow-bead-id>`, and `bd list` to inspect progress.
