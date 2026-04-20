# Troubleshooting Gas City (`gc`)

Issues that surface while installing, configuring, or running a Gas City factory with the `gc` CLI. See the top-level [README](../README.md) for `gc` install instructions; this guide is only for things that go wrong.

## Contents

- [Issue: `gc` command not found or wrong version](#issue-gc-command-not-found-or-wrong-version)
- [Issue: `gc rig add` fails with a missing `.gc/...` file](#issue-gc-rig-add-fails-with-a-missing-gc-file)
- [Issue: `gc rig add` reports "path does not exist"](#issue-gc-rig-add-reports-path-does-not-exist)
- [Issue: `gc start` succeeds but agents show as dead / red](#issue-gc-start-succeeds-but-agents-show-as-dead--red)
- [Issue: `gc start` fails with "standalone controller already running..."](#issue-gc-start-fails-with-standalone-controller-already-running)
- [Issue: `gc dashboard serve` fails with "address already in use"](#issue-gc-dashboard-serve-fails-with-address-already-in-use)
- [Issue: Two agents race on the same file in the rig](#issue-two-agents-race-on-the-same-file-in-the-rig)
- [Issue: Bead stuck on `ready-to-build`; no Coder session starts](#issue-bead-stuck-on-ready-to-build-no-coder-session-starts)
- [Issue: Reviewer keeps returning `request-changes` and the Coder re-cycles](#issue-reviewer-keeps-returning-request-changes-and-the-coder-re-cycles)

---

## Issue: `gc` command not found or wrong version

**Symptom:** `gc <anything>` prints `command not found`, runs the wrong binary, or `gc version` reports a version that doesn't match what the curriculum expects.

**Cause:** One of:

- A. `gc` is not on `$PATH`.
- B. `gc` is on `$PATH` but resolves to an old install.
- C. `gc` is aliased in your shell (commonly to `git commit`).

**Fix:**

1. `which gc` — if it prints nothing, `gc` isn't on `$PATH`. Install it per the [README](../README.md) and make sure the install dir is on `$PATH`.
2. If `which gc` prints a path, confirm the file exists and is executable: `ls -l "$(which gc)"`. `chmod +x` it if needed.
3. `gc version` — if it reports a stale version, reinstall per the [README](../README.md).
4. Check your shell config (`~/.zshrc`, `~/.bashrc`, `~/.zprofile`) for `alias gc=...`. If present, unalias it or rename the alias.

---

## Issue: `gc rig add` fails with a missing `.gc/...` file

**Symptom:** `gc rig add …` errors with a message about a missing file under `.gc/`, e.g. `.gc/gc-beads-bd`.

**Cause:** The factory directory has a `city.toml` but `gc init` was never run, so `.gc/` was never created.

**Fix:** From the factory directory:

```bash
gc init --file city.toml .
gc rig add "$(pwd)"   # or whichever rig path you were adding
```

If `gc init --file` conflicts with the existing `city.toml`, merge the two files by hand (start from the file `gc init` wants to write, then layer in your custom `[includes]` / `[agents]` entries).

---

## Issue: `gc rig add` reports "path does not exist"

**Symptom:** `gc rig add <path>` fails saying the path doesn't exist, even though you can `ls` it.

**Cause:** A relative path was passed from a directory where the rig isn't reachable, or the absolute path was typo'd.

**Fix:** Use an absolute path. `cd` into the rig first and use `$(pwd)`:

```bash
cd ~/Projects/actual-software/software-factory-intensive/reference-project
gc rig add "$(pwd)"
```

---

## Issue: `gc start` succeeds but agents show as dead / red

**Symptom:** `gc start` returns cleanly, but `gc status` shows every agent as dead (red in the dashboard). No sessions ever spin up.

**Cause:** Usually one of:

- The `includes` path in `city.toml` still has a placeholder like `/abs/path/to/...` and was never substituted.
- The `provider = "..."` in `city.toml` points at a CLI (`claude`, `codex`, …) that isn't installed or isn't on `$PATH`.

**Fix:**

1. `cat city.toml` and inspect every `includes = "..."` entry. For each one, `ls` the path. If `ls` fails, fix the path.
2. Check `provider = ...` — make sure the named CLI (`which claude`, `which codex`, etc.) resolves to an executable.
3. `gc restart`.

If agents still come up dead, `gc doctor --fix --city <factory-dir>` often surfaces the misconfiguration directly.

---

## Issue: `gc start` fails with "standalone controller already running..."

**Symptom:** `gc start` fails with an error like `gc start: standalone controller already running for ~/Projects/factory/workshop_w1/w1-gc-factory (PID 12345); stop it before registering with the supervisor`

**Cause:** The standalone controller is already running for the factory.

**Fix:**

```bash
gc stop
```

---

## Issue: `gc dashboard serve` fails with "address already in use"

**Symptom:** `gc dashboard serve …` exits immediately with `address already in use` or similar.

**Cause:** Another process (very often a dashboard left running from a previous session) is bound to port `8080`.

**Fix:**

```bash
lsof -i :8080            # find the offending process
kill <pid>               # stop it
gc dashboard serve --city <factory-dir>
```

Or run on a different port:

```bash
gc dashboard serve --city <factory-dir> --port 8081
```

---

## Issue: Two agents race on the same file in the rig

**Symptom:** Two Coder sessions pick up beads that both edit the same file (e.g. `src/menu/`). The later write wins; the earlier session errors out.

**Cause:** Parallel children of the same parent bead both landed in `ready-to-build` and two Coders claimed them simultaneously. The factory has no serialization by default in W1.

**Fix:** Close the stray bead and keep the surviving one:

```bash
bd close <stray-id> --reason "duplicate — lost race on src/menu/"
bd label add <kept-id> ready-to-build
```

The durable fix — serializing concurrent work via bead dependencies — is introduced in W3 (coordination primitives). For W1, this is expected-but-rare; just note the behavior.

---

## Issue: Bead stuck on `ready-to-build`; no Coder session starts

**Symptom:** The dashboard shows a bead labelled `ready-to-build`, but no Coder tmux session ever appears, and `gc status` shows the Coder idle.

**Cause:** The rig is missing dependencies the Coder needs to run the test suite at boot. The agent errors out immediately and never re-attempts until its deps are installed. Most common on a freshly-cloned repo where `npm ci` / `pip install` / `bundle install` has never run.

**Fix:** Install the rig's dependencies, then restart:

```bash
cd ~/Projects/actual-software/software-factory-intensive/reference-project
npm ci          # or the rig's equivalent
gc restart
```

Check `gc events --follow` while the Coder wakes — if it errors again, the install didn't cover what the Coder needed.

---

## Issue: Reviewer keeps returning `request-changes` and the Coder re-cycles

**Symptom:** The bead oscillates between `needs-review` and `ready-to-build`. The Reviewer flags the same finding every round; the Coder regenerates the same code.

**Cause:** The shipped Coder prompt is generic — for a given project it will keep hitting the same review blocker until the pack is customized. Customizing the Coder pack is L3's entire job.

**Fix:** For W1 / W2: nothing. Let it cycle a few rounds to see the loop, then move on. If it cycles more than three times on the same finding, stop the factory and flag it:

```bash
gc stop
```

For L3 and beyond: this is the signal to edit the Coder pack's prompt template to address the recurring finding.
