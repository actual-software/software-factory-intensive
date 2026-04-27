# Git hooks

Repo-local hooks that run fast repository checks before a commit lands.

## Enable (once per clone)

```bash
git config core.hooksPath .githooks
```

That's it. No Python `pre-commit` tool, no `npm install`, no framework. Just bash + git.

## What runs

The `pre-commit` hook inspects `git diff --cached --name-only` and runs only
the checks whose scope could be affected by the staged files:

| Check | Runs when any of these are staged |
|---|---|
| Pack structure check | `packs/**`, legacy activity pack copies, internal checks, `.githooks/**` |
| Behavioral smoke check | above, plus `my-factory/*.template`, `my-factory/.gitignore` |
| Tutorial dry-run check | above, plus `my-factory/README.md`, selected activity READMEs, `installation.md` |

A commit touching only `curriculum/**` markdown or `plans/**` skips these
checks entirely. A commit touching runtime pack files runs all three
(~3-5 min).

## What does not run pre-commit

Live agent runs do not run pre-commit. They require authenticated provider
sessions and spend real tokens, so run them manually before release cuts.

See the internal QA docs for the full testing story.

## Bypass

Standard git escape hatch:

```bash
git commit --no-verify
```

Use sparingly. If a check is flaking repeatedly, fix the check rather than
routinely bypassing.

## Disable

```bash
git config --unset core.hooksPath
```
