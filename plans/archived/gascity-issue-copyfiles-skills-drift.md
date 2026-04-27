# Config-drift drain loop on every tmux session after 1.0: `stageHookFiles` races `materialize-skills` PreStart

## Summary

On gc 1.0.x, every tmux session whose `workDir != scopeRoot` gets stuck in a `config-drift` drain/respawn loop. The drift field is `CopyFiles`, and the drifting entry is `RelDst=".../.claude/skills"`.

Root cause: `stageHookFiles` in `cmd/gc/cmd_start.go` appends a `Probed: true` CopyEntry for the session workdir's `.claude/skills/` directory and computes its `ContentHash` at **template-resolve time** — i.e., *before* the Stage-2 `gc internal materialize-skills` PreStart runs. Immediately after session spawn, the PreStart writes into that same directory. The next reconciler tick re-computes `ContentHash` against the freshly-written content, sees it differs from the stored hash, and drains as `config-drift`.

This cannot self-resolve: every respawn stores a hash *before* the PreStart writes, and the PreStart always writes *after*. It's also redundant — skill drift is already covered by `FingerprintExtra["skills:*"]` entries populated by `mergeSkillFingerprintEntries` a few lines later (`template_resolve.go:383`).

This is a regression vs v1.0-rc1; the Actual Software Factory Intensive live lesson check passed end-to-end on -rc1 (commit `a4d0542`) and fails on 1.0.1 100% of the time.

Related prior fix: `c4bb343d` ("fix: cache last-good skill catalog to stop FPExtra drift oscillation") landed Apr 19 and solved the same class of bug in `FPExtra`; the drift has since migrated to `CopyFiles` via the new skills CopyEntry in `stageHookFiles`.

## Evidence

### 1. Drift log pattern is consistent with real on-disk mutation, not hash non-determinism

From `~/.gc/supervisor.log`, same city, sequential architect sessions:

```
session -50n: stored=e8cafad777b3 current=6d5d9aacb451
session -ti0: stored=6d5d9aacb451 current=028abb9c9c44
```

`stored(N+1) == current(N)` — the hash at session N+1's spawn time equals the hash the reconciler saw at N's drain. That's only possible if the content on disk IS changing, specifically between spawn-time-hash and reconciler-tick-hash, and then stabilising between drain and next spawn.

### 2. mtime evidence pins the mutator to post-spawn

Scratch retained from a failing run:

```
.gc/settings.json                                     mtime=20:27:13  (stable since gc register)
.gc/agents/rig/architect/.claude/skills/              mtime=20:28:14
.gc/agents/rig/architect/.claude/skills/actual/SKILL.md  mtime=20:29:XX (updated on each respawn)
```

Session spawn was 20:28:12. Skills dir was first written 2s later (the PreStart window). SKILL.md is rewritten on each respawn.

### 3. HashPathContent is deterministic for these inputs

Replicating `runtime.HashPathContent` in Python against the on-disk content produces exactly the SHA-256 reported in the drift-log diag:

```
drift-log current: 1ae6eb5e696a0da4bf4d89afce1c229c3d93cb6076983e3e5f837f19e3e62346
python recomp:    1ae6eb5e696a0da4bf4d89afce1c229c3d93cb6076983e3e5f837f19e3e62346
```

So the hash function is fine. It's the input (the directory content at reconciler time vs. at spawn time) that differs.

### 4. It's not walkthrough-specific

The same log on this host shows drift for architect sessions in completely unrelated scratch cities. Every architect session drifts — regardless of city shape.

## Repro

Any tmux-backed session where `workDir != scopeRoot` and the agent has assigned skills is sufficient. The SFI live lesson check below is a deterministic repro:

```bash
git clone https://github.com/gastownhall/software-factory-intensive
cd software-factory-intensive
run the retained-scratch live lesson check for my-factory
```

Observe in `~/.gc/supervisor.log`:

```
Woke session 'rig/architect.architect-1'
session lifecycle: op=start wave=0 session=architect__architect-sw12-nnc ... outcome=success
config-drift architect__architect-sw12-nnc: stored=... current=... drifted fields: CopyFiles
  config-drift-diag ... CopyFiles: stored-hash=X current-hash=Y
    CopyFiles[N]: RelDst=".../.claude/skills" ContentHash="..."
Draining session 'architect__architect-sw12-nnc': config-drift
... (loops forever)
```

`assignedWorkBeads` never advances past the initial routed bead — every wake gets drained before it can touch work.

## Root cause in source

**`cmd/gc/cmd_start.go:834-841`** (introduced post-1.0-rc1):

```go
// Stage Claude skills directory (if materialized).
skillsDir := filepath.Join(workDir, ".claude", "skills")
if info, err := os.Stat(skillsDir); err == nil && info.IsDir() {
    copyFiles = append(copyFiles, runtime.CopyEntry{
        Src: skillsDir, RelDst: path.Join(relWorkDir, ".claude", "skills"),
        Probed: true, ContentHash: runtime.HashPathContent(skillsDir),
    })
}
```

This runs inside `stageHookFiles`, called from `templateResolver.resolveTemplate` at `cmd/gc/template_resolve.go:178` — i.e., *during* template resolve, which is *before* session start.

**`cmd/gc/template_resolve.go:373-403`** then configures the Stage-2 materializer to run as a PreStart:

```go
if isStage2EligibleSession(p.sessionProvider, cfgAgent) {
    ...
    desired := effectiveSkillsForAgent(...)
    if len(desired) > 0 {
        fpExtra = mergeSkillFingerprintEntries(fpExtra, desired)  // ← the proper drift channel
        if canonWorkDir != scopeRoot {
            ...
            expandedPreStart = appendMaterializeSkillsPreStart(
                expandedPreStart, materializeAgent, workDir)      // ← the writer
        }
    }
}
```

So for every Stage-2-eligible session with `workDir != scopeRoot` (every tmux agent in every rig-scoped setup):

1. `stageHookFiles` hashes `workDir/.claude/skills/` → stored.
2. `appendMaterializeSkillsPreStart` queues a command that will write into that exact path.
3. Session spawns; tmux starts PreStart subprocess; `gc internal materialize-skills` writes into `workDir/.claude/skills/`.
4. Next reconciler tick re-hashes `workDir/.claude/skills/` → different → drift → drain.
5. Respawn (GOTO 1).

Compounding: skill drift is already tracked by `FingerprintExtra["skills:*"]` entries (line 383 `mergeSkillFingerprintEntries`), so the `CopyFiles` entry is **redundant**. It doesn't protect against anything FPExtra doesn't already cover.

## Recommended fix

**Remove the skills CopyEntry from `stageHookFiles`.** Skill drift detection belongs entirely to `FPExtra["skills:*"]`, which is populated at the same template-resolve callsite and is robust against the write-order race because its inputs are the catalog state, not the on-disk materialised tree.

### Patch

`cmd/gc/cmd_start.go`:

```diff
@@ -832,13 +832,10 @@ func stageHookFiles(copyFiles []runtime.CopyEntry, cityPath, workDir string) []r
        }
    }

-   // Stage Claude skills directory (if materialized).
-   skillsDir := filepath.Join(workDir, ".claude", "skills")
-   if info, err := os.Stat(skillsDir); err == nil && info.IsDir() {
-       copyFiles = append(copyFiles, runtime.CopyEntry{
-           Src: skillsDir, RelDst: path.Join(relWorkDir, ".claude", "skills"),
-           Probed: true, ContentHash: runtime.HashPathContent(skillsDir),
-       })
-   }
+   // Intentionally NOT staging workDir/.claude/skills/ here. That path is
+   // written by the Stage-2 PreStart command queued in
+   // template_resolve.go (appendMaterializeSkillsPreStart) *after* this
+   // hash would be taken, which produces unavoidable config-drift.
+   // Skill drift is covered by FingerprintExtra["skills:*"] entries
+   // populated by mergeSkillFingerprintEntries on the same resolve pass.
    // cityDir-based hooks: claude (.gc/settings.json).
    // Skip if settingsArgs already added it.
    // These are city-root relative, so no relWorkDir prefix needed.
```

### Narrower alternative (if you want to preserve the CopyEntry for non-Stage-2 sessions)

Gate the append on `!isStage2EligibleSession && canonWorkDir == scopeRoot`:

```go
// Stage Claude skills directory only when nothing else writes to it post-spawn.
skillsDir := filepath.Join(workDir, ".claude", "skills")
if info, err := os.Stat(skillsDir); err == nil && info.IsDir() &&
    !willMaterializerWriteSkills(sessionProvider, cfgAgent, workDir, scopeRoot) {
    copyFiles = append(copyFiles, runtime.CopyEntry{ ... })
}
```

But this requires plumbing `sessionProvider`, `cfgAgent`, and `scopeRoot` into `stageHookFiles`, which currently only takes `cityPath, workDir`. The full removal is simpler and loses no coverage (FPExtra already catches skill changes).

## Tests to confirm

### New Go unit test — `cmd/gc/cmd_start_test.go`

```go
// Regression: stageHookFiles must NOT emit a CopyEntry for
// workDir/.claude/skills/. That path is written by the Stage-2
// materializer PreStart, which mutates the directory after this
// hash would be taken, causing an inescapable config-drift loop.
// Skill drift detection is the responsibility of FPExtra["skills:*"].
func TestStageHookFilesDoesNotStageSkillsDir(t *testing.T) {
    tmp := t.TempDir()
    cityPath := tmp
    workDir := filepath.Join(tmp, ".gc", "agents", "rig", "architect")
    skillsDir := filepath.Join(workDir, ".claude", "skills")
    if err := os.MkdirAll(skillsDir, 0o755); err != nil {
        t.Fatal(err)
    }
    // Put a dummy skill under it so stat passes.
    if err := os.MkdirAll(filepath.Join(skillsDir, "plan"), 0o755); err != nil {
        t.Fatal(err)
    }
    if err := os.WriteFile(
        filepath.Join(skillsDir, "plan", "SKILL.md"),
        []byte("---\nname: plan\n---\n"), 0o644); err != nil {
        t.Fatal(err)
    }

    got := stageHookFiles(nil, cityPath, workDir)

    for _, cf := range got {
        if strings.HasSuffix(cf.RelDst, ".claude/skills") {
            t.Fatalf("stageHookFiles emitted skills CopyEntry %+v; "+
                "expected skills to be tracked only via FPExtra[\"skills:*\"] "+
                "(see stageHookFiles-drains-tmux-skill-sessions regression)",
                cf)
        }
    }
}
```

### Integration test — two reconciler ticks on an untouched session

Harness sketch (pseudocode; fit the existing `cmd/gc/session_lifecycle*_test.go` style):

```go
// Regression: a freshly-started tmux session whose workDir != scopeRoot
// and that has assigned skills must not drain as config-drift on the
// first reconciler tick.
func TestReconcilerNoConfigDriftAfterStage2Materialize(t *testing.T) {
    env := newTestEnv(t)
    env.registerCity(...)
    env.addRig(...)
    env.assignSkillToAgent("architect", "plan")  // stage-2 path exercised

    // Spawn the session via the normal path.
    session := env.wakeSession("rig/architect.architect-1")

    // Run PreStart manually (simulates tmux) — this writes into
    // workDir/.claude/skills/.
    env.runPreStartFor(session)

    // Run ONE reconciler tick.
    drifted := env.reconcileOnce()

    if drifted.Contains(session.ID) {
        t.Fatalf("reconciler drained %s as config-drift immediately after "+
            "Stage-2 materialize; drift fields: %v (this is the "+
            "stageHookFiles/materialize-skills race)", session.ID, drifted[session.ID])
    }

    // Also run a second tick to confirm steady state.
    drifted = env.reconcileOnce()
    if drifted.Contains(session.ID) {
        t.Fatalf("reconciler drained %s on second tick", session.ID)
    }
}
```

### End-to-end repro from SFI live lesson check (post-fix gate)

After patching, verify against the SFI live lesson check (exercises the exact production shape: rig-scoped agent + per-agent workDir + assigned skills):

```bash
# Before: my-factory loops forever on config-drift.
# After: completes within ~10 minutes.
cd software-factory-intensive
run the live lesson check for my-factory
```

Pass criterion: the `rig-<beadID>` bead produced by the walkthrough's `bd create` gets picked up by the architect session, handed off with a `needs-plan` / `needs-design` / `ready-to-build` child bead label, and `~/.gc/supervisor.log` contains zero `config-drift ... CopyFiles` lines for the run.

### Supervisor-log assertion

Add a CI check that parses `~/.gc/supervisor.log` after any integration run and fails on:

```
config-drift .*: .* drifted fields: CopyFiles
  .*CopyFiles: stored-hash=.* current-hash=.*
    .*RelDst=".*/.claude/skills"
```

This would have caught the regression between -rc1 and 1.0.1.

## Blast radius

Anyone with `gc >= 1.0.0` (possibly -rc2/-rc3 too; I only confirmed -rc1 clean and 1.0.1 broken) running tmux sessions with assigned skills and `workDir != scopeRoot` is affected. That's the default shape for every rig-scoped factory. Workaround for users on 1.0.1 today: roll back to v1.0-rc1 until patched.

## Impact on the Software Factory Intensive workshop

Zero of the 5 workshop lessons (`my-factory`, `L2`, `L3`, `L4`, `C1`) run end-to-end on gc 1.0.1. All 5 lessons use the same factory shape — rig-scoped tmux agents with assigned skills (`workDir != scopeRoot` + `isStage2EligibleSession == true` + non-empty `desired` skills) — which is exactly the condition that triggers the drift.

Evidence that the drift is not workshop-specific:

- `~/.gc/supervisor.log` on this host shows `config-drift` on the architect session in multiple unrelated scratch cities. Any new session with the shape above drifts.
- The prior FPExtra drift fix (`c4bb343d`, Apr 19) solved the same class of bug in a different field; every workshop run after `c4bb343d` but before a CopyFiles-side fix will fail the same way.

The workshop dispatcher halts the chain on first failure, so `my-factory L2 L3 L4 C1` fails at `my-factory` and the later lessons never attempt their bodies. Running lessons in isolation doesn't help either because each lesson requires state from the prior lesson's chain (rig, factory, bead IDs produced by real agent handoffs), which the drift loop prevents from being produced.

The `a4d0542` commit ("Adapt walkthroughs to Gas City 1.0-rc1 launchd supervisor") in the SFI repo confirms all 5 lessons passed on v1.0-rc1. The regression window is `v1.0-rc1..v1.0.1`.
