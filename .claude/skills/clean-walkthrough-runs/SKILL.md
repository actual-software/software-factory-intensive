---
name: clean-walkthrough-runs
description: Clean up and run this repo's tutorial walkthrough harness safely. Use before or after `test-harness/tutorial-walkthrough.sh`, `test-harness/behavioral-smoke.sh`, or `$validate-lesson-content`; when `sfi-walkthrough-*` cities, scratch Dolt/tmux/agent processes, or hook-owned walkthrough runs interfere; or when validating lesson snapshots in `test-harness/walkthrough-snapshots`.
---

# Clean Walkthrough Runs

## Overview

Use this skill to keep Software Factory Intensive walkthrough runs isolated. The harness creates registered `sfi-walkthrough-*` cities, Dolt servers, tmux sessions, event streams, scratch directories, and sometimes hook-owned smoke runs; stale state can make later lessons import the wrong pack, hang, or report invalid Dolt endpoints.

## Workflow

1. Inspect state before running walkthroughs:

   ```bash
   .claude/skills/clean-walkthrough-runs/scripts/cleanup_walkthrough_state.sh status
   ```

2. Stop unrelated hook-owned walkthroughs only when they are clearly test-owned and blocking this task:

   ```bash
   .claude/skills/clean-walkthrough-runs/scripts/cleanup_walkthrough_state.sh clean --kill --kill-hooks
   ```

3. Clean stale walkthrough cities and scratch-rooted runtime processes:

   ```bash
   .claude/skills/clean-walkthrough-runs/scripts/cleanup_walkthrough_state.sh clean --kill
   ```

4. Run the smallest walkthrough set that proves the task. Tee long runs to `/tmp` and monitor every 30-60 seconds:

   ```bash
   rm -f /tmp/sfi-walkthrough-L2.log
   set -o pipefail
   bash test-harness/tutorial-walkthrough.sh L2 2>&1 | tee /tmp/sfi-walkthrough-L2.log
   ```

5. After any failed or interrupted run, clean again before retrying or validating snapshots.

## Rules

- Never run multiple live walkthrough chains at once. They share `gc` registry state and `/tmp/sfi-tutorial-walkthrough`.
- Treat `.githooks/pre-commit -> test-harness/behavioral-smoke.sh -> tutorial-walkthrough.sh` as a live walkthrough chain. If it is unrelated and actively interfering, kill the hook-owned process tree with `--kill-hooks`.
- Do not kill arbitrary `gc`, `dolt`, `tmux`, or `claude` processes. Only kill processes whose command line references `/tmp/sfi-tutorial-walkthrough`, `sfi-walkthrough-*`, or this repo's behavioral smoke/walkthrough hook chain.
- If `gc sling ... --on <formula>` prints `Created ...` but not `Attached workflow ...`, treat it as a failed formula launch. Do not wait for artifacts.
- If `gc status` reports Dolt at `127.0.0.1:0` or "Dolt server unreachable" after an interrupted run, clean the walkthrough state before continuing.
- Snapshot validation is only valid for lessons with files under `test-harness/walkthrough-snapshots/<lesson>/`. Mark missing lessons blocked instead of inventing results.

## Useful Checks

```bash
gc cities
ps -axo pid,ppid,etime,state,command | rg 'pre-commit|behavioral-smoke|tutorial-walkthrough|sfi-tutorial-walkthrough|sfi-walkthrough'
find test-harness/walkthrough-snapshots -maxdepth 2 -type f | sort
```

Use `TUTORIAL_WALKTHROUGH_KEEP_SCRATCH=1` only for debugging a failure point. Clean retained scratch when done.
