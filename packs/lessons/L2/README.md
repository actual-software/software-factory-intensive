# Feature Intake Factory

This pack is a small feature-intake factory. It contains a planner, an
architect, their prompts, and a formula graph that turns a feature request
into planning and architecture artifacts.

The workflow route is:

```text
plan -> architecture
```

Import the pack into a project rig with the `factory` binding, then run the
planner through that binding:

```bash
gc sling planner "Plan loyalty points for Fired Up Pizza"
```

The formula routes work to `factory.planner` and then `factory.architect`.
