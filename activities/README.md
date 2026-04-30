# Activities

This directory holds the student-facing deliverables for each session. The long walkthroughs live in `../curriculum/`; runnable factory definitions live in `../packs/lessons/`.

## How Activities Relate To Packs

Activities are where you write notes, run reports, and local design artifacts. They are not where workflow routing lives.

For runnable labs, the active factory is selected from `my-factory/pack.toml`:

```toml
[defaults.rig.imports.factory]
source = "../packs/lessons/L3"
```

Students keep the same project rig across lessons. After changing the active lesson factory, sync the existing rig import:

```bash
cd ../my-factory
gc --rig your-project import remove factory
gc --rig your-project import add ../packs/lessons/L3 --name factory
```

Then sling one feature request to the formula entrypoint shown in the activity README.

## Typical Session Flow

1. Read the matching walkthrough under `../curriculum/`.
2. Write the requested activity deliverables in this directory.
3. For runnable labs, select the matching self-contained factory pack.
4. Sync the existing project rig's `factory` import.
5. Start the formula with `gc sling <rig>/factory.planner ... --on <formula>`.
6. Inspect progress with `gc events --follow`, `gc session list`, `gc session peek`, and `gc graph`.

## Sessions

| Session | Folder | Key deliverable |
|---|---|---|
| W1 | [`workshops/W1/`](workshops/W1/) | Workflow card for individual AI work |
| L1 | [`labs/L1/`](labs/L1/) | Project instructions, decision log, project manifest |
| W2 | [`workshops/W2/`](workshops/W2/) | Factory role and artifact map |
| L2 | [`labs/L2/`](labs/L2/) | Planner and Architect artifacts |
| L3 | [`labs/L3/`](labs/L3/) | Design spec and implementation |
| W3 | [`workshops/W3/`](workshops/W3/) | Formula graph design notes |
| L4 | [`labs/L4/`](labs/L4/) | Review report and release gate |
| W4 | [`workshops/W4/`](workshops/W4/) | Feedback-loop rule proposals |
| C1 | [`capstone/C1/`](capstone/C1/) | End-to-end run report and retrospective |
