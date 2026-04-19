# W2 · From Individual AI Workflow to Software Factory Pipeline

> **Goal:** Make the jump from "I chat with one AI and paste corrections until it gets the answer right" to "I configure a six-agent factory in files and let it run." By the end of this session your project repo is **factory-ready**: a filled `docs/PROJECT_MANIFEST.md`, a validated local AI toolset, and a committed `docs/FACTORY_READY.md` checklist that L1 will read as its prerequisite.

| | |
|---|---|
| **Estimated duration** | ~45 minutes |
| **Type** | Workshop |
| **Deliverable** | A factory-ready project workspace — clean repo, filled manifest, authenticated provider CLI, verified `gc` / `bd` / `factory-activity-agent`, and `docs/FACTORY_READY.md` committed — that L1 can install the 6-agent factory against without extra scrambling |

---

## Session workspace note

W2 is not an activity you install. Nothing new lands in `~/Projects/factory/`. The whole session takes place inside **your own project repo** — the one you brought to the workshop. You use your existing individual-AI workflow (Claude Code or Codex in chat mode, one prompt at a time) for the last time; L1 is the session where the factory takes over.

* **Your project repo:** `~/path/to/your-project` (whatever you brought). Everything W2 produces lands here under `docs/`.
* **Project Overview (you should already have):** `docs/PROJECT_OVERVIEW.md` in your repo — loose, 5 sections. If it's missing, see [`software-factory/PROJECT_OVERVIEW_TEMPLATE.md`](../../../PROJECT_OVERVIEW_TEMPLATE.md) for the template.
* **Project Manifest (you will produce):** `docs/PROJECT_MANIFEST.md` — structured skeleton every factory agent reads. See [`software-factory/PROJECT_MANIFEST_TEMPLATE.md`](../../../PROJECT_MANIFEST_TEMPLATE.md) for the schema.
* **Factory-ready checklist (you will commit):** `docs/FACTORY_READY.md` — short proof-of-preparation doc. L1's prerequisites check looks for this.

**Canonical references** — keep both open in tabs:

1. [`software-factory/LABELED_BEADS.md`](../../../LABELED_BEADS.md) — the handoff protocol that replaces chat memory and markdown docs.
2. [`software-factory/factory-activity-agent/SKILL.md`](../../../factory-activity-agent/SKILL.md) — the skill you installed in W1; every lab from here on uses it.

---

> **Agent Guide** — If an AI coding agent is walking you through this session, look for **`> Agent Guide: …`** callouts inline at specific steps. They are additive to the step instructions — you still do the work. An agent reading this README should start by opening the participant's `docs/PROJECT_OVERVIEW.md` so every manifest suggestion is grounded in their actual project. If the overview is missing, stop and have the participant fill one out first; generating a manifest from a blank overview is the exact anti-pattern this workshop is teaching away from.

---

## Where This Workshop Sits

In **W1** you installed the `factory-activity-agent` skill and watched the Fired-Up Pizza reference factory move a feature bead through six agents without typing a single prompt after the initial `bd label add`. You have the mental picture: labels on a bead, agents waking on order-gate matches, artifacts landing in canonical locations.

W2 takes you from "I've seen a factory run" to "I am preparing my project to host its own factory." The session is short, mostly discussion and setup, and the Big Reveal is subtle: **the factory only exists because the *inputs* to the factory (your manifest, your repo state, your tool auth) are in a shape the factory can operate on.** A sloppy manifest is why a factory stalls; a half-authenticated CLI is why an agent dies on startup. W2 is where you pay that debt before L1 installs anything.

After W2, you'll move to L1, where David walks the room through standing up the 6-agent factory against the project you just prepared here.

---

## Part 1: The Two Paradigm Shifts (~8 min)

Two things change between W1's reference factory and L1's factory-on-your-project. Internalize both or L1 will feel like typing `gc` commands without knowing why.

### Shift 1: Config Over Prompting

In an individual AI workflow, when the model produces wrong output, you type a correction into the chat and try again. The fix is ephemeral — it lives in a message buffer that disappears when the session ends. The same mistake will recur on the next bead, and on the one after that.

In a software factory, when an agent produces wrong output, you edit its **pack** — the declarative config that defines its role, inputs, output format, quality gate, and process. The fix is committed, versioned, and repeats on every future run of that agent. The agent inherits the fix the next time it wakes.

The packs you'll edit starting in L2 are under `software-factory/packs/<agent>/` — one directory per agent, with a `pack.toml` (metadata + overlay config), a `prompts/<agent>.md.tmpl` (the system prompt), and optionally `formulas/`, `commands/`, `doctor/`, `overlays/`. Every pack has the same six-section prompt: **Role, Inputs, Output Format, Quality Gate, Process, Config Discipline**. When an agent misbehaves, you ask: *which of these six sections needs to change?*

> **Inline Insight: "Config" is not just prompts.**
> A pack can carry hooks (pre/post-session shell scripts), order gates (label filters that decide when the agent wakes), formulas (multi-step molecules), skills (slash commands the agent can call), permissions (what the runner CLI is allowed to do), and settings overlays. All of them are config. When you feel the urge to paste "also, please remember to..." into chat, the discipline is: stop, find the config surface, edit it, rerun.

### Shift 2: Coordination via Labeled Beads, Not Durable Markdowns

In an individual AI workflow, context passes through chat memory — the model "remembers" because the messages are still in the context window. When the session ends or the window overflows, you paste the forgotten context back in. A single-threaded conversation is the entire coordination mechanism.

In a software factory with six agents, each agent runs in its own session, on its own schedule, against its own order gate. There is no shared chat memory. If the Planner left a note for the Designer, the Designer has to find it somewhere — not in any agent's head.

The answer is **labeled beads**. Each bead is one unit of work; its labels are its state; each agent watches `bd ready --label <inbound>` for work aimed at it. The Planner writes findings into the bead's notes, re-labels `needs-plan` → `ready-to-build` (or whatever's next), and exits. The Coder wakes on its order gate match, reads the bead's notes + diff + manifest, does the work, re-labels to `needs-review`, exits. No long-lived per-feature markdown gets passed between agents — the bead is the handoff.

Open [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) now and skim:

1. The **six canonical labels** table (`needs-plan`, `needs-architecture`, `needs-design`, `ready-to-build`, `needs-review`, `ready-to-ship`).
2. The **example lifecycle** — a bead walking the factory end-to-end.
3. The section **"Why labels replaced durable markdowns"** — the four failure modes the label protocol fixes.

Do not memorize. You should walk out able to name, for any label, (a) who adds it and (b) who consumes it. Every factory touch point you meet from here on is an instance of this protocol.

> **Inline Insight: The bead is the only memory.**
> Cross-agent state lives on the bead — labels, notes, dependencies, assigned rig. If a fact about the feature matters to a downstream agent, it goes on the bead (via `bd label`, `bd note`, or as a cross-reference into a canonical on-disk artifact the agent will look up). "The Planner said in chat that refunds are out of scope" is useless to the Architect; "the Planner's bead notes list refunds under `OUT`" is authoritative.

---

## Part 2: What Individual Workflows Can't Do (~7 min)

You don't need to be convinced the factory is better than chat. You need to see, concretely, which tasks bust the individual workflow — so you recognize them when they hit you in L1–L4 and know why the factory gives them somewhere to go.

### Parallelism

In chat, you run one task at a time. If you want the Architect and the Designer to work on sibling pieces of the same feature simultaneously, you physically can't — you are the bottleneck. In the factory, two agents can be in `working` state on the dashboard at once because they're filtering different labels off the same backlog. You saw this in W1 Part 3 Step 4 (the "two agents in working state simultaneously" note).

### Continuity across sessions

In chat, your context vanishes when the window closes. If you reopen a new session tomorrow to keep working on yesterday's feature, you paste yesterday's context back in — and miss a chunk, and the model picks a different path. In the factory, every agent's context is rebuilt from files (manifest + bead notes + pack prompts) on every invocation. The factory doesn't "remember" — it *re-reads*, and the files don't forget.

### Fanning out / fanning in

In chat, one prompt produces one answer. If your feature decomposes into three children (backend, UI, migration), you either (a) handle the three in three separate chats and manually reconcile, or (b) ask one chat to handle all three and get worse output than three specialized agents would give. In the factory, the Planner decomposes the parent bead into children with different labels, and the child beads fan out to different agents and fan back in at `ready-to-ship`.

### Verifiable, replayable runs

In chat, if last Tuesday's run produced a good result, you can't rerun the same thing tomorrow with confidence. The model is non-deterministic, the prompt is gone, the context is gone. In the factory, the bead, its notes, the packs' prompts, and the commits are all in git. You can `git checkout` an earlier SHA and re-sling. You know which run produced which outcome. You can diff two factory configurations and reason about what changed.

### When to stop using chat

The moment you hit any of those four — parallelism, continuity, fan-out, replay — you are outside the chat workflow's comfort zone. The rest of the workshop is about giving yourself the factory so those four stop hurting.

> **Agent Guide:** If the participant looks unconvinced, prompt them to name the last time *they* hit one of these four failure modes on their own project. Make it concrete: "two days ago I opened three Claude Code windows to parallelize three branches" is the real data. Link that experience to the primitive the factory adds (beads with sibling labels) so the rest of W2 lands.

---

## Part 3: Prepare Your Project (~20 min)

This is the hands-on bulk of the session. You will work in your own repo, using your existing individual-AI tool (Claude Code, Codex, or whatever you brought). The goal at the end of this part is: your repo state plus your local tool state plus your config all line up with what L1 expects as prerequisites.

### Step 1: Verify the W1 Baseline Is Still Green (~2 min)

Everything you installed in W1 should still work. Quick re-verification:

```bash
# factory-activity-agent skill is resolved
ls -l ~/.claude/skills/factory-activity-agent         # (or ~/.codex/skills/factory-activity-agent)

# gc is on PATH at the curriculum-pinned version
gc version                                       # expect: gascity 0.14.1

# bd is on PATH
bd --version

# Provider CLI is authenticated (example for Claude Code)
claude --version
# Run a trivial prompt to confirm auth:
echo "say hi" | claude -p
```

If any row fails, fix it now — no downstream step of W2 will succeed with a broken W1 baseline. See `factory-activity-agent/SKILL.md` → *Prerequisites* for the pinned-version install recipe.

> **Agent Guide:** If `claude -p` returns an auth error, walk the participant through `claude auth login` (or `codex login` for Codex). Do not proceed until the trivial prompt returns a non-empty response.

### Step 2: Ensure a Project Overview Exists (~3 min)

Every factory agent ultimately routes through your `docs/PROJECT_MANIFEST.md`. That manifest is generated from a short free-form narrative document: `docs/PROJECT_OVERVIEW.md`. Before you can generate the manifest, you need the overview.

```bash
cd ~/path/to/your-project
ls docs/PROJECT_OVERVIEW.md
```

If it exists, skim it quickly to confirm it still describes the project as you intend to build it — projects drift between "what you wrote down" and "what you're actually doing" faster than you'd think. Tighten it if it's stale.

If it doesn't exist, create it now. The template is at [`software-factory/PROJECT_OVERVIEW_TEMPLATE.md`](../../../PROJECT_OVERVIEW_TEMPLATE.md) — five sections, loose structure, no schema to follow. A completed example lives at [`software-factory/reference-project/docs/PROJECT_OVERVIEW.md`](../../../reference-project/docs/PROJECT_OVERVIEW.md). Aim for one page; not a spec.

```bash
mkdir -p docs
cp ~/Projects/actual-software/software-factory-intensive/software-factory/PROJECT_OVERVIEW_TEMPLATE.md docs/PROJECT_OVERVIEW.md
# Fill in the five sections. Plain English. Keep it short.
```

This is the **last** document you will hand-write for the factory. Everything else — the manifest, any ADRs, specs, review reports — the factory produces from here on.

### Step 3: Generate Your Project Manifest (~8 min)

This is the one time in the weekend you get to use a chat-style individual-AI workflow with intent. You are going to point Claude Code (or Codex) at your repo, ask it to read the overview + the codebase, and produce `docs/PROJECT_MANIFEST.md` against the shipped schema.

The schema is defined in [`software-factory/PROJECT_MANIFEST_TEMPLATE.md`](../../../PROJECT_MANIFEST_TEMPLATE.md). Read through it once so you know what the agent is about to fill in — Tech Stack, Project Structure, Domain Model, Conventions, Constraints, Task Inputs, Services to Connect, Success Criteria, Review Standards, Release Criteria.

Then, from your project repo, launch Claude Code (or your preferred CLI agent) and run a single prompt against it:

```text
Read docs/PROJECT_OVERVIEW.md and the repository, then generate docs/PROJECT_MANIFEST.md
using the schema at
~/Projects/actual-software/software-factory-intensive/software-factory/PROJECT_MANIFEST_TEMPLATE.md.

Fill every section. For anything you can't determine from the overview or the code,
insert `TBD — <specific follow-up question>` so I can resolve it later. Do not invent
entities, tech choices, or constraints that aren't grounded in what you read.

When done, commit the result with message:
  docs: generate project manifest from overview

Stop for confirmation before committing.
```

When the agent finishes, **read the manifest top to bottom**. Things to check:

- **Tech Stack** — are the versions right? (The agent sometimes guesses from `package.json` names and gets majors wrong on transitive deps.)
- **Domain Model** — are the entities real? (Drop any invented ones; the Reviewer will enforce this list in L4.)
- **Conventions** — match your actual commit / branch / naming style, not an industry default.
- **Review Standards** and **Release Criteria** — these two sections are the Reviewer's and Deployer's rubrics in L4. If they're thin, the agents downstream will be thin. Beef them up.

Any section you can't fully fill today, leave as `TBD — <question>`. L2's Architect agent can resolve TBDs on your behalf later.

Commit once you're satisfied:

```bash
git add docs/PROJECT_MANIFEST.md
git commit -m "docs: generate project manifest from overview"
```

> **Agent Guide:** After the agent produces the draft, ask the participant: "Which three sections would you push back on the most?" Make them read and critique — not just scroll. The exercise of finding three weak sections now is what keeps the factory from shipping generic reviews in L4.

### Step 4: Validate Your Local AI Toolset (~5 min)

The factory, when it runs in L1, will spawn sessions of your provider CLI (Claude Code, Codex, etc.) one per agent. Each spawn needs the same permissions and auth the CLI has when you run it interactively. A missing tool permission or an unauthenticated provider is the single most common cause of a red agent in L1 — catch it now.

Confirm each row. If your provider is Codex, substitute the equivalent commands.

| Check | How to verify | Why it matters |
|-------|---------------|----------------|
| Provider CLI auth is valid | `echo "say hi" \| claude -p` returns non-empty | Every agent will fail on startup if auth is expired. |
| CLI can read your repo | `claude -p "list the top-level directories of $(pwd)"` returns a plausible listing | Confirms filesystem access + working-directory handoff. |
| CLI can write to your repo | `claude -p "create a throwaway file at /tmp/sfi-w2-test.txt containing 'ok'"` then `cat /tmp/sfi-w2-test.txt` | Confirms the runner isn't sandboxed away from filesystem writes. |
| CLI can run shell commands | `claude -p "run 'git status' and summarize the output"` | Coder, Reviewer, Deployer all shell out for git/tests/linters. |
| Memory / global settings are sane | `cat ~/.claude/CLAUDE.md` (or equivalent) — skim for overrides that would conflict with factory behavior | A global "always ask before running git" rule will hang the Coder agent. |

If any row fails, fix it before moving on. Common fixes:

- **Expired auth:** `claude auth login`.
- **Filesystem denied:** check `~/.claude/settings.json` → `permissions` block; relax for the workshop, tighten later.
- **Global CLAUDE.md conflicts:** move conflicting rules behind a project scope or comment out for the workshop.

> **Agent Guide:** If the participant's global `~/.claude/CLAUDE.md` has rules that would block the factory (e.g., "always confirm before editing"), call it out explicitly: "this rule will turn into six stuck agents in L1 — decide now whether to scope it or suspend it." Don't silently edit their config.

Clean up the throwaway file:

```bash
rm -f /tmp/sfi-w2-test.txt
```

### Step 5: Confirm Repo Hygiene (~2 min)

L1 will register your project as a Gas City *rig*. Rigs work best against a clean git state — the factory will branch off from wherever you are, and surprises in your uncommitted working tree become surprises in agent output.

```bash
cd ~/path/to/your-project
git status
```

You want to see either a clean tree or changes you're actively aware of. Stash or commit anything you don't want the factory to read. Also confirm:

- You're on the branch you intend to run the factory on (usually `main` or a feature branch of your choice, not a scratch experiment branch).
- Your `.gitignore` isn't excluding `docs/` (agents need to read the manifest).
- You've recently pulled, so `bd dolt push` (when it comes up in L2+) doesn't collide.

```bash
git pull --rebase
git status                    # clean tree (or expected in-progress changes only)
git log --oneline -3          # you recognize the last three commits
```

---

## Part 4: Commit the Factory-Ready Checklist (~5 min)

The concrete artifact W2 leaves in your repo is a short committed checklist that L1 reads as its prerequisite. Keep it tight — this is not a design doc. It's an evidence file.

### Step 1: Create `docs/FACTORY_READY.md`

Copy this template into your project repo. Fill in each row with a brief, honest answer — `Yes`, `No`, a version number, a path, a one-liner. Leave nothing as placeholder.

```markdown
# Factory-Ready Checklist

Captured at the end of W2 as the prerequisite evidence for L1. Regenerate
this file whenever your toolset changes materially.

## Tool Baseline

- [ ] `gc version` prints `gascity 0.14.1`
- [ ] `bd --version` runs
- [ ] `~/.claude/skills/factory-activity-agent` (or Codex equivalent) resolves to the SFI repo
- [ ] Provider CLI: <name + version>, authenticated against <account>
- [ ] `echo "say hi" | <cli> -p` returns non-empty

## Project State

- [ ] Branch: <branch>
- [ ] Working tree clean (or: expected in-progress changes only)
- [ ] Last commit I can describe: <SHA short + one line>
- [ ] `docs/PROJECT_OVERVIEW.md` exists and reflects current intent
- [ ] `docs/PROJECT_MANIFEST.md` generated and committed at <SHA>
- [ ] Remaining `TBD` items in manifest: <count, brief list>

## Factory Wiring (context only — L1 installs)

- [ ] I can name each of the 6 canonical labels and which agent consumes each
- [ ] I accept that agent behavior changes via pack config, not chat

## One-Line Summary

<Your feature-and-first-bead intent in one sentence.>
```

### Step 2: Commit it

```bash
cd ~/path/to/your-project
git add docs/FACTORY_READY.md
git commit -m "docs: W2 factory-ready checklist"
```

If your L1 prerequisites check runs `ls docs/FACTORY_READY.md` and `grep -c '\[x\]' docs/FACTORY_READY.md` — that's all it's checking. The checklist exists; you filled it in honestly.

> **Agent Guide:** If any row says `No` or `TBD`, resolve it now. W2 runs only once in the workshop; the one session that's designed to absorb missing prereqs is over when lunch ends. A participant who leaves with `No` rows will get stuck in L1.

---

## Common Issues & Solutions

### Issue 1: The individual-AI agent produced a manifest with invented entities

**Cause:** The Project Overview was vague, so the agent filled in plausible-but-wrong defaults for Domain Model.

**Fix:** Edit the Overview to name real entities first. Re-run the manifest generation prompt. Don't try to hand-patch the manifest — it'll drift from the overview and the next manifest refresh will overwrite you anyway.

### Issue 2: `claude -p` returns auth errors

**Cause:** Expired session, or you installed Claude Code after your token was issued.

**Fix:** `claude auth login`. If that fails, delete the credentials file under `~/.claude/` and re-auth.

### Issue 3: Global `CLAUDE.md` rules will block the factory

**Cause:** Your global `~/.claude/CLAUDE.md` has rules like "always confirm before `git commit`" or "never run shell commands without asking," which the factory's autonomous agents will trip over.

**Fix:** Either (a) move those rules into a project-scoped `CLAUDE.md` in a different repo, or (b) comment them out for the duration of the workshop and restore after. The factory can't operate with a confirmation step between every action.

### Issue 4: My repo is on a feature branch that isn't mergeable

**Cause:** Mid-refactor, merge conflicts with main, work-in-progress that isn't ready to show agents.

**Fix:** Create a W2-specific branch off a clean SHA and run the factory there. `git switch -c factory-prep && git reset --hard <clean-sha>`. The factory branches from wherever the rig is; you want that wherever to be clean.

### Issue 5: `docs/PROJECT_MANIFEST.md` is huge (>300 lines)

**Cause:** Your project is big, and the manifest faithfully captures all of it.

**Fix:** It's fine to be long, but prune the **Domain Model** and **Tech Stack** sections to the 10–15 core entities / libraries the factory will actually touch. Agents read the manifest on every wake; an oversize manifest slows every agent down.

### Issue 6: I don't have a Project Overview and didn't bring one

**Cause:** Missed the pre-workshop prep.

**Fix:** Use the next 8 minutes to write a one-page Overview from scratch using the template. Lean on the five sections literally — don't freestyle. Then proceed to Step 3.

### Issue 7: The provider CLI works interactively but the factory will probably spawn it differently

**Cause:** Factory sessions run in a non-interactive shell; some CLIs behave differently than in your terminal.

**Fix:** Confirm the non-interactive path works: `echo "say hi" | claude -p` (or `codex exec` for Codex). This is the path L1 will exercise. If interactive works but `-p` fails, your CLI is misconfigured for headless use — fix it now.

### Issue 8: My repo doesn't have `docs/` yet

**Cause:** Small project, never needed a docs directory.

**Fix:** `mkdir -p docs` and commit. The factory expects `docs/PROJECT_MANIFEST.md` at that path specifically — don't relocate it.

### Issue 9: I want to use my IDE's AI (not Claude Code / Codex CLI)

**Cause:** Hoping an IDE extension (Cursor, Continue, etc.) will play the role of the agent runner.

**Fix:** For the workshop, use a CLI runner — the factory spawns CLI processes per agent and IDE extensions aren't addressable that way. Once the factory works, you can absolutely keep your IDE AI for other purposes.

### Issue 10: Manifest template says "generated in L1"; L1 says "completed in W2" — which is right?

**Cause:** Slight drift between the template's old note and the current session flow.

**Fix:** Trust the session flow: W2 generates the manifest, L1 consumes it. (The template will be refreshed in a follow-up bead; the generation step belongs where you do it with an individual AI, and L1 is where you run the factory on what W2 produced.)

---

## Exit Criteria

Before leaving W2, verify all of these:

- [ ] `docs/PROJECT_OVERVIEW.md` exists in your project repo and is current.
- [ ] `docs/PROJECT_MANIFEST.md` exists, every section filled (or marked `TBD — <question>`), committed to a known SHA.
- [ ] `docs/FACTORY_READY.md` exists, every row answered, committed.
- [ ] `echo "say hi" | claude -p` (or Codex equivalent) returns non-empty output.
- [ ] `gc version` prints `gascity 0.14.1`.
- [ ] `bd --version` runs cleanly.
- [ ] `ls -l ~/.claude/skills/factory-activity-agent` resolves to the SFI repo (Codex equivalent: `~/.codex/skills/`).
- [ ] Your project repo's working tree is clean (or has only the three commits from this session).
- [ ] You can name, from memory, the six canonical labels and which agent consumes each.
- [ ] You agree, in your own words, that agent behavior changes via **pack config**, not chat.

If any row is unchecked, resolve it now — L1 opens in 5 minutes and assumes every row above is green.

---

## Concept Check (before moving to L1)

> **Agent Guide:** Before declaring the session complete, ask the participant to answer each bullet below out loud without re-reading. If they can't, revisit the matching section.

- **Why is the Project Manifest committed as a file, not kept in chat memory?** Because every factory agent reads it on every wake; chat memory doesn't persist across agent sessions, and agents run in separate processes anyway.
- **When an agent produces wrong output, do you re-prompt it or edit the pack?** Edit the pack. Always. Chat corrections evaporate; pack edits are versioned and repeat.
- **Name the six canonical labels and who consumes each.** `needs-plan` → Planner; `needs-architecture` → Architect; `needs-design` → Designer; `ready-to-build` → Coder; `needs-review` → Reviewer; `ready-to-ship` → Deployer.
- **Where does the Coder get the Planner's findings?** Off the bead — notes + labels + cross-references to on-disk artifacts. Never from chat.
- **Why is the factory-ready checklist committed rather than held in your head?** Because L1 reads it to decide whether to proceed, and because committing a small artifact is the habit the rest of the workshop builds on.

---

## Command Cheat Sheet

```bash
# --- Part 3: prepare your project ---

cd ~/path/to/your-project

# Verify W1 baseline
gc version                                                   # gascity 0.14.1
bd --version
ls -l ~/.claude/skills/factory-activity-agent                       # resolves to SFI repo
echo "say hi" | claude -p                                     # non-empty response

# Ensure Project Overview exists
mkdir -p docs
cp ~/Projects/actual-software/software-factory-intensive/software-factory/PROJECT_OVERVIEW_TEMPLATE.md docs/PROJECT_OVERVIEW.md
# Edit docs/PROJECT_OVERVIEW.md — fill 5 sections

# Generate Project Manifest via individual-AI CLI
# (inside Claude Code / Codex, with your project repo as the working directory)
# Prompt: see Part 3 Step 3

# Commit the manifest
git add docs/PROJECT_MANIFEST.md
git commit -m "docs: generate project manifest from overview"

# --- Part 4: factory-ready checklist ---

# Create docs/FACTORY_READY.md from the template in Part 4 Step 1
# Fill in every row
git add docs/FACTORY_READY.md
git commit -m "docs: W2 factory-ready checklist"

# --- Sanity checks ---
git log --oneline -3
git status                                                    # clean
```

No `gc sling`, no `bd create`, no pack edits this session — those all start in L1 and L2.

---

## Quick Reference: What You Prepared

| Artifact | Location | Read by |
|----------|----------|---------|
| Project Overview | `docs/PROJECT_OVERVIEW.md` | You + individual-AI (input to Manifest generation) |
| Project Manifest | `docs/PROJECT_MANIFEST.md` | Every factory agent in L1–L4 |
| Factory-ready checklist | `docs/FACTORY_READY.md` | L1 prerequisites check |
| Provider CLI (authenticated) | your shell | Every agent spawn in L1–L4 |
| `factory-activity-agent` skill (from W1) | `~/.claude/skills/factory-activity-agent` | Every lab install / doctor / status call |
| Labeled-beads protocol (memorized) | [`LABELED_BEADS.md`](../../../LABELED_BEADS.md) | You, when reading agent behavior |

---

## Next Steps

**L1** — David installs the 6-agent factory on your project. The installer reads your repo, registers it as a rig, copies the shipped packs, and spins up all six agents. Your `docs/FACTORY_READY.md` is what L1's prerequisites check looks for; everything else you did in W2 (clean repo, manifest, auth) is what makes the install succeed on the first try instead of the third.

**Bring to L1:**

- [ ] Your project repo path, committed and clean.
- [ ] `docs/PROJECT_MANIFEST.md` committed.
- [ ] `docs/FACTORY_READY.md` committed.
- [ ] A one-sentence description of the first feature you want to walk through the factory (not required for L1 itself, but you'll want it by L2's Planner step).

Take a short break if you're ahead — L1 is 60 minutes of active factory setup and you want the attention budget intact.
