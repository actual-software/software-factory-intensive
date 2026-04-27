# W1 · Optimize the Individual AI Workflow

> **Goal:** Turn the way you already use an AI coding assistant into written, reusable rules — so the next session (L1) can hand those rules to an agent and watch it work without you at the keyboard.

| | |
|---|---|
| **Estimated duration** | ~60 minutes |
| **Type** | WORKSHOP |
| **Deliverable** | `workflow-card.md` committed to your project repo |

---

## Why This Workshop Exists

The factory is six agents — but each one is still, fundamentally, "a Claude session you've configured well." If you can't get a *single* agent to do what you want reliably and repeatably, a factory of six won't rescue you. It'll multiply the chaos.

The enemy you're unlearning today is **ad-hoc prompting**: fixing bad agent output by typing a correction into the chat. Every time you do that, you lose information — the correction only lives in your head and the current session's context. When that session ends, the correction is gone. *Config persists. Chat doesn't.*

This workshop produces a one-page `workflow-card.md` that encodes **your** discipline for working with an AI assistant. It's the seed for `CLAUDE.md` / `AGENTS.md` in L1, and the mental model you'll apply six times over across W2–L4.

Writing a workflow card feels like overkill the first time. It isn't. Every bullet you commit now saves you from re-deciding the same thing mid-session for weeks afterward. By the time you reach L3 and are running four agents in parallel, the discipline you build here is the difference between a factory that produces work and a factory that produces confusion.

---

## What You'll Build

```
Your workflow (in your head)
      ↓
Written down as workflow-card.md (this workshop)
      ↓
Handed to Claude Code as CLAUDE.md (L1)
      ↓
Split across 6 agent prompts in packs/ (L2-L4)
      ↓
Enforced by formula graphs + feedback rules (W3/W4)
```

The card is a single markdown file, ~50–100 lines, committed to your project repo. It has exactly four sections. It is scoped to *one* project — not a universal AI-assistant manifesto. When you pick up a second project, you'll write a second card.

---

## Prerequisites

Before starting, verify each of these:

| Prerequisite | How to verify | If it's missing |
|--------------|---------------|-----------------|
| Project Manifest filled in | `cat ~/path/to/your-repo/docs/PROJECT_MANIFEST.md` shows tech stack, conventions, domain model | Copy from [`curriculum/PROJECT_MANIFEST_TEMPLATE.md`](../../PROJECT_MANIFEST_TEMPLATE.md) and fill it in — 15 min max |
| Your project repo cloned locally | `cd ~/path/to/your-repo && git status` runs cleanly | `git clone <your-repo-url>` and verify you can commit from this checkout |
| An AI coding assistant you've used | You can name at least 3 sessions where the agent produced useful code, and at least 1 where it went off the rails | If you haven't used one seriously, spend 30 min before this workshop doing a small task with Claude Code or similar |
| A scratch doc or notebook | Any plain text or markdown file you can jot notes into | Create `~/scratch/w1-notes.md` or open a fresh note in your editor of choice |
| Fired Up Pizza reference open (recommended) | [`reference-project/fired-up-pizza/workflow-card.md`](../../../reference-project/fired-up-pizza/workflow-card.md) open in a second editor window | Read it once end-to-end; you'll use it as a pattern |

**Note:** You do *not* install any Gas City packs in this workshop — this is all design work. Installation starts in L1. If you've already installed Gas City, leave it alone for the next hour.

---

## Reference: What "Mature" Looks Like

Before you write your own card, skim the finished equivalent in the reference project:

- [`reference-project/fired-up-pizza/workflow-card.md`](../../../reference-project/fired-up-pizza/workflow-card.md) — a completed `workflow-card.md` for the Fired Up Pizza project

That card is exactly what this session asks you to produce for your own project — same four sections, project-specific content. Your `workflow-card.md` lives in your *project* repo (not the city). In L1 you'll evolve it into agent instructions (`CLAUDE.md` / `AGENTS.md`) that target the built-in `claude` agent.

Notice a few things as you read the reference:

- **Every bullet names a concrete artifact** — `src/pages/MenuPage.tsx`, `FUP-3`, `npm run lint && npm run type-check && npm test`. There are no abstractions like "relevant files" or "proper testing."
- **The Iteration Loop section tells you exactly what to do when a gate fails** — `git reset --hard HEAD` and re-sling, *not* type a correction into chat. That sentence is doing most of the work.
- **The Decision Checkpoint lists five "I decide" items and five "agent decides" items** — not three vague categories. The specificity is what makes it actionable.

Your own card should look structurally identical. The content will differ; the shape won't.

---

## The Running Example: Fired Up Pizza's Cart Total Feature

Throughout this workshop, we use a single running example: **you're about to build the shopping cart total line on Fired Up Pizza's customer-facing menu page.** The ticket is `FUP-3`. The feature needs to sum selected menu items, apply a size multiplier, add toppings, and display a running total in cents (formatted as dollars).

Why this example? It's small enough to imagine in 60 seconds, but it hits every sharp edge of the AI workflow:

- There's a **specific target file** (`src/components/Cart.tsx`) — so the Prompt Template has something to reference.
- There are **existing reference files** (`src/components/MenuCard.tsx`, `src/components/OrderStatus.tsx`) that show the pattern.
- There are **project conventions** (prices in cents, Tailwind utility classes, no inline styles) that the agent will forget if you don't remind it.
- There's a **decision boundary** (does the cart total live in Context or local state?) that you want the agent to escalate — not decide itself.

If you're working against your own project, substitute your own small feature — but pick one that has at least one "the agent will probably get this wrong" risk. A genuinely trivial feature ("change button color") won't produce a useful workflow card because there's nothing for the card to *protect* against.

For the rest of this document, when you see "the Cart Total feature," substitute your own feature name.

---

## Step 1: Answer the Discovery Questions (~10 min)

Before you can write rules, you need to know which rules. The Discovery Questions surface the anti-patterns you're already living with. Keep answers specific — *file paths, commit ranges, ticket IDs.* Vague answers fail this step.

### Step 1.1: Capture a recent frustrating session (~3 min)

Think of a recent AI coding session that frustrated you. Write down, in your scratch doc:

- **When it happened** (date, rough time).
- **What you were trying to do** (the feature or task, in one sentence).
- **Where it went wrong** (the specific moment you realized the agent was off track).

Example:

```
- 2026-04-10 afternoon
- Adding a new API route for topping inventory updates
- Agent invented a Zod schema helper (`z.priceInCents()`) that doesn't exist.
  I'd told it "use Zod" but never told it which helpers exist in our codebase.
```

**Common answers:** vague output, lost context, hallucinated APIs, wrong framework version, agent confidently used a library version that doesn't match our lockfile.

**Bad answer:** "Claude is dumb." Push yourself: what would the agent have needed to know in order to not be dumb? The answer is almost always *a fact that lives in your head but not in any file the agent reads.*

### Step 1.2: Capture what you did next (~3 min)

When the agent went off track, what did you do?

- Did you re-prompt?
- Did you start a new session?
- Did you paste more code, or paste the error?
- Did you give up and write the code yourself?

Write it down honestly. Example:

```
- Re-prompted 4 times. Each re-prompt added one missing constraint
  ("use our Zod helpers, not z.priceInCents"; "read src/schemas/money.ts";
  "the return type needs to be Result<T>, not T"). Session was 35 minutes
  by the time it worked. I did not commit any of those constraints to a file.
```

Most people admit: re-prompting, 3–5 times, until it "sort of worked." That's the anti-pattern this card will replace. Every one of those re-prompts is a constraint that should have been in the system prompt from the start — but ended up lost in a chat buffer that was discarded when the tab closed.

### Step 1.3: Capture how you currently provide context (~4 min)

How do you currently provide context to your agent?

- Pasting full files into the chat?
- Referencing paths like `src/components/Cart.tsx` and hoping the agent opens them?
- Linking to tickets? Quoting ACs verbatim, or summarizing?
- Re-typing the same framing sentences every session ("we use TypeScript strict, Tailwind, no inline styles")?

Write down three bullets describing your current practice, without judging it:

```
- I paste the current file's full contents when asking for changes.
- I mention the ticket ID but don't paste the acceptance criteria.
- I never tell the agent our stack constraints — I assume it'll infer from the file extension.
```

**Deliverable for Step 1:** Nine bullet-point answers across the three questions, captured in your scratch doc. This is the raw material for the card — not the card itself.

### Pitfall: Writing principles instead of observations

"I try to be specific" is a principle. "I paste the current file's full contents when asking for changes" is an observation. Workflow cards are built from observations, not principles. Principles can't be encoded in a config file — observations can be.

---

## Step 2: Draft Your Workflow Card (~20 min)

Create `workflow-card.md` at `activities/workshops/W1/workflow-card.md` (inside this repo) using the template below. Spend about 5 minutes per section. Write the content inline — don't try to outline first and flesh out later.

```bash
cd ~/path/to/your-repo
touch workflow-card.md
```

Open it in your editor and paste this scaffold:

```markdown
# My AI Workflow Card

## 1. Prompt Template
[What you include in every prompt. Be concrete — name the fields.]

## 2. Context Reset Rule
[When you start a fresh session vs. continue. Include specific triggers.]

## 3. Iteration Loop
[Your standard N-step process from "agent writes code" to "code is merged."]

## 4. Decision Checkpoint
[Which decisions you make yourself; which you delegate to the agent.]
```

Now fill in each section in order.

### Step 2.1: Write the Prompt Template (~5 min)

The Prompt Template section answers: **what fields are in every prompt I send to the agent?**

This is structural — it names the *fields*, not the values. For the Cart Total feature, a prompt instantiated from the template looks like this:

```
Target: src/components/Cart.tsx (FUP-3)
ACs: [pasted verbatim from the ticket]
Stack constraints: React 18 + TS strict, Tailwind utilities only,
  no inline styles, no `any`.
Reference files: src/components/MenuCard.tsx, src/components/OrderStatus.tsx
Testing hint: Vitest + RTL. Co-located Cart.test.tsx.
```

The template describes the shape — `Target`, `ACs`, `Stack constraints`, `Reference files`, `Testing hint`. The prompt substitutes real values.

Write your section now. Example from the Fired Up Pizza reference:

```markdown
## 1. Prompt Template

Every prompt I paste into Claude Code for this project includes, in order:

- **Target**: a file path under `src/` or a ticket ID (`FUP-3`, etc.). No "the cart thing."
- **Acceptance criteria**: pasted verbatim from the ticket. If I'm inventing the AC on the fly, I write them down first and paste the exact text.
- **Stack constraints**: "React 18 + TypeScript strict, Tailwind CSS utility classes, no inline styles, no `any` types." These never change.
- **Reference files**: two similar existing files the agent should read first for pattern-matching.
- **Testing hint**: "Vitest + React Testing Library. Co-located `<Name>.test.tsx` file."
```

**What's happening here:** Each bullet names a concrete field, and the text after the colon describes exactly what goes in that field. The agent (and future-you) can read this and instantiate a prompt without any guesswork.

**Pitfall:** Don't write "include relevant context." Include relevant context is what you're already doing, and it's why you're in this workshop. Be specific about *which* context fields matter.

### Step 2.1a: Worked Example — Instantiating the Template

Once your Prompt Template is written, test it by instantiating a full prompt for the Cart Total feature. This is the prompt you'd actually paste into Claude Code if you were starting the work right now:

```
Target: src/components/Cart.tsx (FUP-3)

Acceptance criteria (verbatim from FUP-3):
- Cart component displays a running total in the header bar.
- Total is computed as: sum(item.priceCents * sizeMultiplier + sum(topping.priceCents)).
- Total is formatted as a dollar string with two decimals (e.g. "$14.50").
- Empty cart shows "$0.00", not a blank string.
- Total updates within 16ms of any cart mutation.

Stack constraints:
- React 18 + TypeScript strict mode.
- Tailwind CSS utility classes only. No inline styles. No CSS files.
- Prices stored as integer cents; never mix cents and dollars in the same function.
- No `any` types. Use `Result<T>` wrapper for any fallible operation.

Reference files (read these first):
- src/components/MenuCard.tsx — for the existing price formatting helper usage.
- src/components/OrderStatus.tsx — for the header-bar layout pattern.

Testing hint: Vitest + React Testing Library. Co-located `Cart.test.tsx`.
Cover empty cart, single item, item with toppings, size multiplier edge cases.
```

**What's happening here:** Every field from your template is present. Every value is concrete. A fresh Claude Code session given this prompt has no ambiguity about what to do, which files to read, or what guardrails to respect. The agent doesn't need to ask you a question to start work.

Compare this to the prompt you *would* have written without a template — probably two sentences, missing the stack constraints, with "see the Cart component" instead of the file path. The template is the forcing function that makes the concrete prompt easy to produce.

**Pitfall:** If instantiating the template is painful — if you find yourself typing the same stack constraints for the tenth time — that's a signal those constraints belong in `CLAUDE.md` (L1), not in every prompt. The template is meant to be the *minimum* fields for a single task; long-lived constraints graduate to the agent instructions file.

### Step 2.2: Write the Context Reset Rule (~5 min)

The Context Reset Rule section answers: **when do I throw away the current session and start fresh?**

Most people's current reset rule is "never" — they keep piling onto the same session until Claude starts contradicting itself. That's context pollution. The cost of a polluted session is always higher than the cost of re-establishing context in a new session.

Write triggers — conditions that, when observed, cause you to reset. Example:

```markdown
## 2. Context Reset Rule

I start a fresh Claude Code session when any of these triggers:

- The conversation has 10+ back-and-forths. Context has drifted.
- The agent contradicts something from earlier in the same session. Context is polluted.
- I'm switching from a customer-facing feature to a staff-facing feature (or vice versa). The domain model in scope is different.
- The agent proposes something I'd reject (new dependency, new architecture pattern, schema change). Better to throw away the session and restart with that constraint encoded up front.

I do **not** reset between small slices of the same feature — resetting too aggressively loses useful context.
```

**What's happening here:** The bullets name observable triggers, not vibes. "Context has drifted" is not a trigger; "10+ back-and-forths" is. An agent (or a facilitator, or future-you) can check whether a trigger has fired.

Notice the negative rule at the end: "I do *not* reset between small slices." Negative rules are as important as positive ones — they prevent the over-correction that happens when people learn a new discipline and apply it too aggressively.

**Pitfall:** Triggers that depend on you noticing something ("when the agent starts sounding confused") are weak. Replace them with triggers that can be measured ("after 2 consecutive failing lint runs").

### Step 2.3: Write the Iteration Loop (~5 min)

The Iteration Loop section answers: **what steps does the agent go through, from receiving a task to merging the result?**

This is the longest section — it has numbered steps, and each step names a concrete action. For the Cart Total feature, the loop is:

1. Agent reads the spec (ticket + reference files), writes a 3-line plan.
2. I confirm or redirect the plan.
3. Agent writes one slice (one component, one hook, or one test — never more).
4. I run `npm run lint && npm run type-check && npm test`. All three must exit 0.
5. If a gate fails: update the spec or `CLAUDE.md`, `git reset --hard HEAD`, re-sling. Never type a correction into chat.
6. If a gate passes: commit with a conventional message, move to next slice.
7. All slices landed: agent opens a PR; I review; issues that would repeat go into `CLAUDE.md`, not into PR comments.

Example section from the Fired Up Pizza reference:

```markdown
## 3. Iteration Loop

Every feature follows this loop. If I skip a step I have to say why in the commit body.

1. **Plan first.** The agent reads the spec and the two reference files, then writes a 3-line plan as a bead comment before any code.
2. **I confirm or redirect** the plan. If the plan invents new patterns or touches files outside scope, I reject and clarify.
3. **Agent writes code in one-slice increments.** A slice is one component, one hook, one route, or one test. Never all three at once.
4. **I run the gates after every slice**: `npm run lint && npm run type-check && npm test`. All three must exit 0.
5. **If a gate fails**, I update the spec or `CLAUDE.md` with the missing constraint, `git reset --hard HEAD`, and re-sling. I do not type "oh and also please X" into chat.
6. **If a gate passes**, the agent commits with a conventional message (`feat(cart): show order total`) and moves to the next slice.
7. **When all slices land**, the agent opens a PR. I review; if I find issues that would repeat, I push them into `CLAUDE.md` rather than leaving a PR comment.
```

**What's happening here:** Step 5 is the load-bearing step. It's the moment ad-hoc prompting usually sneaks in, and it's where most workflow cards fall silent. By spelling out "update the spec or `CLAUDE.md`, `git reset --hard HEAD`, re-sling," you're encoding the discipline that separates a factory from a chat.

**Pitfall:** "Run the tests" is not a step. "Run `npm run lint && npm run type-check && npm test` and require all three to exit 0" is a step. The specific command and the specific success criterion are what make it enforceable.

### Step 2.3a: Worked Example — A Gate Failure, Handled Two Ways

Consider the same Cart Total feature. The agent produces code. You run `npm run type-check`. It fails with:

```
src/components/Cart.tsx:42:15 - error TS2345: Argument of type 'number' is
  not assignable to parameter of type 'Cents'. Cents is a branded type.
```

**The ad-hoc response (what your card is replacing):**

```
You: "Oh — we have a branded Cents type. Please use that instead of `number`."
Agent: [fixes the file, produces a patch]
You: type-check again... passes.
[Session continues. The constraint "use Cents branded type, not number"
 lives nowhere except in this chat history. Next session, the agent will
 re-invent the same bug. You'll paste the correction again. And again.]
```

**The disciplined response (what your card encodes):**

```
You: [don't type anything to the agent]
You: Open CLAUDE.md. Add to the "Project conventions" section:
     - "All monetary values use the `Cents` branded type from
       src/types/money.ts. Never pass raw `number` to any function
       whose parameter is typed `Cents`."
You: git add CLAUDE.md && git commit -m "docs(claude): require Cents branded type for money"
You: git reset --hard HEAD (in the project repo — throw away the bad patch)
You: re-sling the bead (or re-run the prompt)
Agent: reads the updated CLAUDE.md, produces new code that uses `Cents` correctly.
       type-check passes first try.
[The constraint now lives in CLAUDE.md. Every future session inherits it.
 You pay the correction cost once, not N times.]
```

**What's happening here:** The disciplined path is ~3× slower *this time* and ~100× faster *over the next six months*. That asymmetry is the reason the Iteration Loop section of your card insists on the disciplined path. Without the card, you'd default to ad-hoc; with the card, the disciplined path is the named, expected behavior.

When you write your own Iteration Loop, make sure step 5 is unambiguous about this choice. A card that says "handle test failures appropriately" preserves the ambiguity the anti-pattern thrives in.

### Step 2.4: Write the Decision Checkpoint (~5 min)

The Decision Checkpoint section answers: **which decisions do I keep for myself, and which does the agent own?**

Two lists. No ambiguity. Every decision the team will hit in the next six months should fall clearly into one bucket.

Example from the Fired Up Pizza reference:

```markdown
## 4. Decision Checkpoint

Decisions I keep for myself (the agent may propose; I decide):

- Database schema changes (we only have `orders`, `menu_items`, `toppings` — adding a column is a decision).
- New package or dependency additions. npm registry is rich; bar for pulling something in is high.
- API contract changes (URL shape, request/response shape). Any change here potentially breaks the frontend-backend contract.
- Architecture patterns I haven't used elsewhere in the codebase (new state-management approach, new layout pattern, new routing scheme).
- Anything that touches money formatting or order total math.

Decisions the agent owns:

- Function-level implementation details within a file.
- Test case design (which cases to write, how to structure fixtures).
- Error-message wording for user-facing error states (as long as it matches the existing voice — cheerful, specific, non-technical).
- File organization *within* a component directory.
- Choosing between equivalent idiomatic approaches in React or TypeScript.
```

**What's happening here:** The "I keep for myself" list is your leverage point — it's where you insert yourself into the loop to prevent the agent from making a choice that's expensive to reverse. The "agent owns" list is equally important: it says "don't stop the agent for this; let it decide." Without the second list, the agent will constantly pause for confirmations on things you don't care about.

**Pitfall:** If you list fewer than three items on either side, you haven't thought hard enough. Sit with it for another two minutes. The goal is a card a stranger could read and predict, with ~90% accuracy, which side of the line a novel decision will land on.

### Tailor to Your Project Type

| Project type | What to emphasize in the card |
|--------------|-------------------------------|
| React / TypeScript | Constrain to existing component patterns under `src/components/`; forbid inventing new utility files without asking |
| Backend API | Context reset rule: "start fresh when switching between routes and middleware"; list the testing command explicitly |
| Monorepo | Specify which package the agent is allowed to modify per session — lock scope per feature |
| Infra / IaC | Require the agent to `terraform plan` (or equivalent dry-run) before any apply; checkpoint before state changes |
| Mobile | Force the agent to confirm target platform(s) and minimum OS version in every prompt |
| Issue tracker in use | Prompt template must reference the ticket ID (`FUP-4`, `PROJ-123`) as the Spec field |
| CLI tool | Prompt template must reference the subcommand namespace; Iteration Loop must include a `--help` output check |
| Data pipeline | Decision Checkpoint must include "any change to schema, partitioning, or retention" as a human-decides item |

If your project matches multiple rows, pull constraints from each.

### Quality Bar for the Card

- [ ] Every field names a *concrete* thing (a command, a path, a ticket ID). No generic phrases like "good context" or "clear prompts."
- [ ] The Iteration Loop says what happens *when a slice fails* — that's the moment ad-hoc prompting usually sneaks in.
- [ ] The Decision Checkpoint lists *at least three specific categories* under "I decide" and three under "Agent decides."
- [ ] Maximum 4 sections. Maximum one page of scroll. If you need more, you're over-engineering.
- [ ] The card references at least one file path, at least one command, and at least one ticket-ID format.

---

## Step 3: Self-Review the Card (~15 min)

Read your `workflow-card.md` back to yourself as if you were a stranger who knows your tech stack but not your codebase. Ask:

> **"Could I follow this card to implement a feature on this project and get the result I'd accept — without asking a single question?"**

For every section, find the first sentence or bullet that would force you to stop and ask a question. Rewrite it to be unambiguous. Iterate until each section reads as a self-contained, executable instruction.

### Step 3.1: The Stranger Test (~5 min)

Print the card (or view it in a separate window, in monospace). For each bullet, play a mental dialogue:

- **Stranger:** "What does 'relevant files' mean?"
- **You:** "It means files similar to the one the agent is modifying."
- **Stranger:** "How do I find them?"
- **You:** "Grep for similar component patterns."
- **Stranger:** "Grep for what, exactly?"

If you can imagine a second question the stranger would still have, the bullet isn't specific enough. Replace "relevant files" with "two sibling files under `src/components/` that already implement a similar pattern (e.g., `MenuCard.tsx`, `OrderStatus.tsx`)."

### Step 3.2: The Failing-Gate Test (~5 min)

Re-read Section 3 (Iteration Loop). Simulate this scenario: the agent writes code, you run the gates, and `npm run type-check` fails.

Walk through the card step by step:

- Does the card tell you what to do next? (Reset? Re-prompt? Edit `CLAUDE.md`?)
- Does it tell you *where* to record the missing constraint?
- Does it tell you how to verify you fixed the root cause, not just the symptom?

If any of those answers is "the card doesn't say," add the answer to Section 3 now. This is the test that catches the most common workflow-card failure mode: the card describes the happy path but goes silent when something breaks.

### Step 3.3: The One-Sentence Test (~5 min)

Without looking at the card, say out loud: "My Context Reset Rule is _________." Then re-open the card and check whether you said the same thing it says.

If you can't state it from memory in one sentence, the section is too sprawling or too vague. Merge bullets, cut exceptions, pick the single strongest trigger and lead with it.

Do the same for the Decision Checkpoint: "The one category of decision I always keep for myself is _________."

### Pitfall: Reviewing for polish, not for ambiguity

Self-review feels productive when you're fixing typos and reformatting bullets. It isn't. The only edits that matter at this stage are the ones that remove a question a stranger would still have. Force yourself to find at least three of those; if you can't, assume you're skimming, not reviewing.

---

## Step 4: Commit the Card (~5 min)

```bash
cd ~/path/to/your-repo
git checkout -b workflow-card
git add workflow-card.md
git commit -m "docs: add AI workflow card (W1)"
git push -u origin workflow-card
```

**Why commit in a branch?** The card is a living artifact. Treating it as PR-worthy from day one reinforces that changes to how-you-work-with-agents deserve the same scrutiny as code changes. In L1 this same discipline applies to `CLAUDE.md`.

### Step 4.1: Open a PR against main (optional, ~2 min)

If your project has any collaborators — even just future-you — open a PR against `main` rather than merging directly. The PR description should include:

```markdown
## What
Adds `workflow-card.md` — the agreed rules for working with an AI coding
assistant on this project.

## Why
Captures four things in one place:
- Prompt Template (what every prompt must include)
- Context Reset Rule (when to start a fresh session)
- Iteration Loop (the slice-test-commit cycle)
- Decision Checkpoint (what I decide vs. what the agent decides)

This is the seed for `CLAUDE.md` / `AGENTS.md` (see W1 README for the
curriculum context).
```

The PR is deliberately tiny — just the one file. That's the point. Small, reviewable, mergeable.

### Step 4.2: Verify the artifact

```bash
git log --oneline -1
ls -la workflow-card.md
wc -l workflow-card.md
```

You should see a commit with your message, a file with non-zero size, and a line count somewhere between 40 and 120. Cards shorter than 40 lines usually skipped a section; cards longer than 120 usually bled into agent-instruction territory and should be trimmed.

---

## Connection to Gas City

You didn't run any `gc` commands this session — intentional. W1 is a design workshop. But the card you just wrote maps directly to concepts you'll install in L1:

| Workflow Card Section | L1 & Beyond Equivalent |
|-----------------------|------------------------|
| Prompt Template | The `## Role` and `## Inputs` sections of `CLAUDE.md` — plus each lesson pack's `agents/<role>/prompt.template.md` file |
| Context Reset Rule | Gas City `idle_timeout` in `city.toml`, plus per-agent session lifecycle rules |
| Iteration Loop | The bead → sling → watch → review → iterate-config loop (L1 Step 4–7) |
| Decision Checkpoint | Human-gate beads (`--requires-approval`) in W3; review policies in `docs/REVIEW_POLICY.md` |

Skim [`packs/lessons/L2/agents/planner/prompt.template.md`](../../../packs/lessons/L2/agents/planner/prompt.template.md) to see the mature, per-agent form of a workflow card. Notice how it specifies Inputs, Output Format, Close Behavior, and Process — the same axes you just wrote for yourself, but specialized to a single agent role.

The progression you'll see across the curriculum is:

- **W1 (now):** one card, one project, one human in the loop.
- **L1:** the same card, split into `CLAUDE.md` (role, rules, pipeline) for a single `claude` agent.
- **L2–L4:** six agent packs, each with its own six-section prompt — but each pack's prompt is structurally the same as your card's four sections, scaled up.
- **W3 / W4:** formula design and feedback loops — which are just *the card's Iteration Loop*, promoted from "a thing you do manually" to "a thing the factory does automatically."

If any of that feels abstract right now, good. It's meant to. Come back to this table after L2 and it'll read very differently.

---

## Using Your Local Agent for This Session

Rather than providing drafting prompts inline, every session ships with a sister `PROMPT.md` file: [`curriculum/workshops/W1/PROMPT.md`](./PROMPT.md). Paste it into Claude Code (or your preferred CLI coding agent) at the start of the session. It knows how to walk you through these steps, pull context from your Project Overview, and keep your card concrete.

If you want to work without the facilitation prompt, the four quality-bar items above are sufficient guidance on their own. Many participants find it easier to write the first draft alone and then ask the local agent to critique it for specificity — which is itself a tiny instance of the Iteration Loop you're designing.

---

## Industry Context: Why "Individual Workflow" Comes First

The W1 → W2 → L1 order is intentional and evidence-based. A few sources worth skimming:

- [**GitHub — "Does AI actually boost developer productivity? The evidence says yes."**](https://github.blog/news-insights/research/does-ai-actually-boost-developer-productivity-the-evidence-says-yes/) — surveys and experiments consistently find that developers who work deliberately with AI (written rules, named workflows) sustain productivity gains, while ad-hoc users regress.
- [**Stanford CRFM — "Holistic Evaluation of Language Models"**](https://crfm.stanford.edu/helm/latest/) — when evaluating LLM-driven coding, context handling is repeatedly the dominant variable. Your Context Reset Rule is the mitigation developers apply in practice.
- [**Anthropic — "Claude Code: Best practices for agentic coding"**](https://www.anthropic.com/engineering/claude-code-best-practices) — recommends starting every agent-assisted workflow with (1) a written spec, (2) a named iteration loop, and (3) explicit decision boundaries. Those are exactly the four sections of your workflow card.
- [**Cognition — "Don't Build Multi-Agents"**](https://cognition.ai/blog/dont-build-multi-agents) — post-mortems on failed autonomous runs overwhelmingly trace back to missing decision boundaries. Your Decision Checkpoint section is the guard rail.

If you find yourself thinking "is this overkill for a single-agent workflow?", the answer is: every one of these sources is about single agents. Scaling to six multiplies the cost of missing the discipline.

---

## Inline Insight: Why "Prompt Template" Isn't "Prompt"

A prompt template is structural — it names the fields every prompt must include. A prompt is instantiated from the template for a specific task.

```
Template:   [File path] + [Acceptance criteria] + [Stack constraints] + [Reference files]
Prompt:     src/components/Cart.tsx + FUP-3 ACs + "TS strict, Tailwind" + "see src/components/MenuCard.tsx"
```

The value of the template is that it's *boring and invariant*. You never have to think about "what context should I give?" — you fill in the blanks. In L1, the template becomes the "Role" and "Iteration Rule" sections of `CLAUDE.md`. In L2+, it becomes each pack's `## Inputs` section.

If you notice yourself thinking "I'll just dash off a quick prompt without the template this time," that's a signal you've found a case the template doesn't cover. Update the template — don't skip it.

---

## Inline Insight: What "Specific" Actually Means

"Be specific" is the most-given and least-actionable piece of advice in the workflow-card genre. Here's a more useful operationalization: **a bullet is specific if and only if it survives search-and-replace.**

- "Include relevant context" → replace "context" with "cartographic metadata" and the sentence still parses. Not specific.
- "Include the acceptance criteria verbatim from the Jira ticket" → replace any noun and the sentence breaks. Specific.

The test works because specificity is the property of referring to exactly one concrete thing in the world. Generic nouns ("context," "patterns," "conventions") refer to many things, so they tolerate substitution. Concrete nouns (`src/components/Cart.tsx`, `FUP-3`, `npm run type-check`) don't.

Apply the test to every bullet in your card. Bullets that pass become the ones the agent (and future-you) can actually act on. Bullets that fail become the ones that feel productive to write and produce no behavior change.

---

## Inline Insight: The Cost Asymmetry of Config vs. Chat

Ad-hoc prompting feels cheap in the moment and expensive in aggregate. Config changes feel expensive in the moment and cheap in aggregate. The workshop is an attempt to make you *feel* the second curve, not just know about it.

Concretely:

- A chat correction costs ~30 seconds to type. A config change costs ~5 minutes to write, review, and commit. The chat correction looks like a 10× win per incident.
- But chat corrections don't compound. Every new session re-pays the full cost of every correction you've ever made, because none of them survived.
- Config changes compound. Every session after the change inherits the new constraint for free. If you hit the same correction 10 times in a month, the break-even is at incident #2, and everything after is pure profit.

The card you're writing today is the substrate that makes config changes durable. Without it, a correction you want to persist has nowhere to live — so it ends up in chat by default. With it, every correction has a home: the Prompt Template field, the Context Reset trigger, the Iteration Loop step, or the Decision Checkpoint list.

When you hit a correction in L1 and feel the "it's faster to just type it here" pull, remember: the pull is real, and it's lying about the cost.

---

## Inline Insight: Why Iteration Loops Fail Silently

The classic failure mode of a workflow card isn't "the card is wrong." It's "the card is silent."

Watch yourself during a real session. The moment you skip a step of your card — because it's Friday, because the task is small, because you're tired — is the moment the card stops being a card and starts being decoration. Every skipped step is a small debt you pay back later in a polluted session, a hallucinated API, or a PR comment you have to re-explain three times.

Two defenses:

- **Make skipped steps visible.** Section 3 of the Fired Up Pizza reference says: "If I skip a step I have to say why in the commit body." That single sentence converts a private rationalization ("it was fine, I didn't need to run type-check") into a public artifact (a commit message that reads "feat(cart): show order total — skipped type-check because this is a comment-only change"). Skipped steps you have to justify get skipped less.
- **Make the loop mechanical, not judgmental.** "Run the gates *after every slice*" is mechanical — you either did or you didn't. "Run the gates *when appropriate*" is judgmental — every skip is defensible. Judgment is what you're trying to offload into the card; if the card defers to judgment at the critical moment, it's not doing its job.

When you re-read your Iteration Loop, ask of every step: *is this mechanical or judgmental?* Convert judgmental steps to mechanical ones until none remain.

---

## Test Scenarios

Before you consider the card done, stress-test it against three scenarios. For each, read the card and narrate out loud (or to the facilitation prompt) what you would do. If the card doesn't give you a clear answer, edit the card — don't patch the scenario with extra reasoning in your head.

### Scenario 1: A teammate borrows your card for their own project

Imagine a teammate clones your repo, reads your workflow card, and asks: *"Can I apply this to my own React + TypeScript side project?"*

- **Expected outcome:** They can reuse the shape (4 sections, same headings) but must replace every bullet with their own project's specifics. The card should be obviously project-specific — not a universal template.
- **What it tests:** Whether your bullets reference *this* project's files, tickets, and commands, or whether they accidentally read as generic advice.
- **If the card fails:** Look for bullets that could apply to any project unchanged. Those are the ones to rewrite with concrete names.

### Scenario 2: The agent proposes adding a new npm dependency

Imagine it's your next working session. The agent is implementing the Cart Total feature and proposes adding `lodash.sumby` to the package.json because it's "a utility library everyone uses."

- **Expected outcome:** Your Decision Checkpoint section should fire — "new package/dependency additions" is in the "I decide" list. You reject, the agent implements the summation without the dependency.
- **What it tests:** Whether your Decision Checkpoint categories match the decisions the agent will actually try to make.
- **If the card fails:** If your Decision Checkpoint doesn't mention dependencies, add that bullet now. It's one of the most common places agents over-reach.

### Scenario 3: Two gate failures in a row, same failure mode

Imagine you run `npm run type-check` and it fails. You update `CLAUDE.md` with a new constraint, `git reset --hard HEAD`, re-sling. The agent produces new code. You run `npm run type-check` again — it fails again, same error.

- **Expected outcome:** Your Iteration Loop, or your Context Reset Rule, should tell you what to do: reset the session entirely (the second failure suggests context pollution, not a missing constraint). Either the Context Reset Rule has a trigger like "two consecutive gate failures with the same error" or the Iteration Loop has an escape-hatch step.
- **What it tests:** Whether your card handles the repeated-failure case, or whether it silently assumes the first fix always works.
- **If the card fails:** Add an explicit step: "If the same gate fails twice in a row, reset the session before trying again — the constraint you added in pass 1 isn't being picked up."

Run through all three mentally. If any scenario leaves you guessing, edit the card before moving to the exit criteria.

---

## Your Final File Structure

After completing W1, your project repo should contain:

```
your-repo/
├── workflow-card.md               # ← Just committed, on the `workflow-card` branch
├── docs/
│   └── PROJECT_MANIFEST.md        # Already filled in before the workshop
├── src/ ...                       # Your existing code (untouched)
└── ... (rest of your repo)
```

Your scratch doc (Discovery Questions notes) stays outside the repo — that's fine. It's raw material, not an artifact.

No Gas City directory is created this session. No agents are installed. No beads exist. All of that starts in L1, and the card you just wrote is the primary input to L1 Step 2 ("Convert `workflow-card.md` into `CLAUDE.md`").

---

## Quality Bar

When you review your own output, check:

- **Section coverage** — All 4 sections present and non-empty. Each has at least three bullets (for Prompt Template / Decision Checkpoint) or three numbered steps (for Iteration Loop) or three triggers (for Context Reset).
- **Specificity** — Every bullet names a concrete artifact: a file path, a command, a ticket ID, a number, or a named convention. Bullets that could survive noun-substitution fail this bar.
- **Failure-mode coverage** — The Iteration Loop says what happens when a gate fails. The Context Reset Rule covers both "start fresh" triggers and "don't reset" exceptions.
- **Project specificity** — The card only makes sense for *this* project. A copy-pasted universal template fails this bar.
- **One-page scroll** — You can scroll from top to bottom of the rendered card in one screen at normal zoom. If not, trim.
- **Committed to a branch** — The card is on a feature branch, not on main. Evidence of config discipline from day one.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| I can't commit because `workflow-card.md` is in `.gitignore` | Remove the file glob from `.gitignore`. Workflow cards are source-controlled artifacts — their history is the audit trail for how your AI workflow evolved. |
| My editor keeps autoformatting the markdown and breaking code fences | Disable "format on save" for `.md` files in the project, or commit the file and then review the diff before re-editing. Your autoformatter is probably fine; most breakage is from trailing-whitespace rules on list items. |
| I wrote the card but it still feels abstract | Open the Fired Up Pizza reference side by side and compare your Section 3 line-by-line. The reference's bullets start with imperative verbs and name commands. If yours don't, the Stranger Test will fail. |
| The card references a file that doesn't exist yet (`src/components/Cart.tsx`) | That's okay — the card is aspirational as well as descriptive. Just make sure the path is plausible (follows your project's directory conventions). If it's purely invented, replace it with a file that *does* exist and serves the same pattern-matching purpose. |
| I can't decide if my Context Reset Rule should include "at the start of each day" | It shouldn't — that's a schedule, not a trigger. Reset triggers describe the state of the session, not the clock. If you want a daily refresh, put that in `CLAUDE.md` later as an agent lifecycle rule. |
| My Iteration Loop has 12 steps | You're including steps that belong in `CLAUDE.md` (the agent's process) rather than your own (the human's process). The Loop section describes what happens between slinging work and merging it — not the internal steps the agent takes. Cut to 5–7. |
| I don't know which commands to put in the Iteration Loop because my project doesn't have tests yet | Put in the commands you'd run if you had tests (`npm test`), plus a note that tests are aspirational. Then add "set up test infrastructure" to your backlog. A card that acknowledges a gap is stronger than a card that silently omits it. |
| The PROMPT.md sister file seems to duplicate the README | It does, intentionally. The README is the written guide; PROMPT.md is the facilitator script for your local agent. You can use either or both. They cover the same steps at different levels of prescription. |
| I have two projects and want one card to cover both | Don't. Write two cards. The whole point is project-specific discipline — a card that averages two projects will be useless for both. |

---

## Exit Criteria

- [ ] `workflow-card.md` committed to your project repo with all 4 sections filled in
- [ ] Every section references something concrete (path / command / ticket)
- [ ] You can re-read the card as a stranger to the codebase and not have to stop to ask a question
- [ ] You can state in one sentence what your Context Reset Rule is
- [ ] Your Decision Checkpoint has at least three entries under "I decide" and three under "Agent decides"
- [ ] The card is on a feature branch (`workflow-card` or equivalent), pushed to origin
- [ ] The Iteration Loop tells you explicitly what to do when a gate fails

---

## Common Issues & Solutions

### Issue: My card is basically "use AI well."

**Solution:** You wrote down principles instead of rules. Rewrite each bullet to start with an imperative verb and name a specific thing: "Include the Jira ticket ID in the prompt," not "include helpful context." If a bullet could survive replacing its nouns with any other nouns, it's a principle, not a rule.

### Issue: I don't have a Context Reset Rule — I just keep going.

**Solution:** That *is* your current reset rule ("never"), and it's probably why you waste time untangling polluted sessions. Pick *any* trigger — 10 messages, or switching files, or a lint run failing twice in a row — and commit to it for a week. You can refine after you have a week of data. The worst reset rule is the one that sounds reasonable but you never actually enforce.

### Issue: I'm writing 8 sections because my workflow is complex.

**Solution:** It isn't. You're hiding decisions under categories. Merge related sections. The 4-section cap exists because L1's agent instructions use the same structure, and your agent will read every section on every run. An agent reading 8 sections of card instructions is an agent reading 8 sections of noise — the signal-to-noise ratio drops, and output quality with it.

### Issue: A reviewer (or your re-read) said "looks fine" without engaging.

**Solution:** Force specificity: "Read section 3 aloud. What's the first question you'd still need to ask?" If they say "nothing," ask them to implement the Cart Total feature using only the card as context. When they hit a question — and they will — add the answer to the card.

### Issue: My Decision Checkpoint has everything under "I decide."

**Solution:** You haven't tried letting the agent decide anything yet, and the card is codifying that. Force at least three concrete "agent decides" items — test case structure, error message wording, within-file organization are all safe starting points. The card is how you build trust in the agent, one delegated-decision category at a time.

### Issue: My Prompt Template lists 12 fields.

**Solution:** You're confusing *what the agent needs to know* with *what you want the agent to acknowledge*. Prune ruthlessly — only fields that, if omitted, would cause the agent to produce worse output belong in the template. "Reminder to use conventional commits" is a `CLAUDE.md` rule, not a prompt template field.

### Issue: The Iteration Loop step for "when a gate fails" is vague or missing.

**Solution:** This is the single most common gap. Rewrite step 5 to name (a) the specific file you edit, (b) the specific git command you run, and (c) the specific trigger for re-sling. "If a gate fails, update `CLAUDE.md` with the missing constraint, `git reset --hard HEAD`, and re-sling the bead" is a passing step. "Adjust the plan and retry" is a failing step.

### Issue: I wrote the card for "AI in general" instead of this project.

**Solution:** Workflow cards are per-project. A universal card is a collection of principles — useful as a blog post, useless as a config artifact. Delete every bullet that doesn't reference something specific to this codebase, and rewrite.

### Issue: My card contradicts my Project Manifest.

**Solution:** The Manifest is the source of truth for tech stack and conventions; the card is your *process* for working with an agent against those conventions. If they conflict — e.g., Manifest says "prices in cents" and your card never mentions currency — update the card to reference the Manifest's convention. The two documents together form the agent's ground truth.

### Issue: I'm worried the card will go stale.

**Solution:** It will, and that's fine. The card is a living artifact — every L1+ session that edits `CLAUDE.md` is, indirectly, a signal that your original card needs an update. Plan to re-read it at the start of L1 and again at the start of L3; those are the natural re-calibration points.

---

## Command Cheat Sheet

W1 has very few commands — it's a design workshop — but the git workflow for the branch and commit matters enough to lay out explicitly:

```bash
# STEP 2 — Create the workflow card
cd ~/path/to/your-repo
touch workflow-card.md
# (edit workflow-card.md in your editor — fill in all 4 sections)

# STEP 3 — Self-review (no commands; this is reading and rewriting)

# STEP 4 — Commit and push
cd ~/path/to/your-repo
git checkout -b workflow-card
git add workflow-card.md
git commit -m "docs: add AI workflow card (W1)"
git push -u origin workflow-card

# STEP 4.2 — Verify
git log --oneline -1
ls -la workflow-card.md
wc -l workflow-card.md            # expect 40–120 lines

# OPTIONAL — Open a PR against main
# (Use your git host's UI or `gh pr create`, if installed)
gh pr create --title "docs: add AI workflow card (W1)" \
  --body "Seed document for CLAUDE.md / AGENTS.md — see W1 README."
```

No `gc` commands this session. No `bd` commands. No agent slinging. The only ceremony is the branch-commit-push loop, which itself is the smallest instance of the Iteration Loop your card encodes.

---

## Quick Reference: What You Built

| Component | File / Location | What It Does |
|-----------|-----------------|--------------|
| Workflow Card | `workflow-card.md` (root of project repo) | One-page document with 4 sections encoding your AI-assistant discipline |
| Section 1 — Prompt Template | `## 1. Prompt Template` | Lists the fields every prompt must include (Target, ACs, Stack, References, Testing) |
| Section 2 — Context Reset Rule | `## 2. Context Reset Rule` | Lists the triggers that cause you to start a fresh session |
| Section 3 — Iteration Loop | `## 3. Iteration Loop` | Numbered steps from spec → plan → slice → gate → commit → PR, including the gate-fail branch |
| Section 4 — Decision Checkpoint | `## 4. Decision Checkpoint` | Two lists: decisions you keep, decisions the agent owns |
| Scratch doc | `~/scratch/w1-notes.md` (or equivalent) | Raw material from Discovery Questions — not committed, but referenced while drafting |
| Branch | `workflow-card` (in your project repo) | Feature branch for the card commit, treating the card as PR-worthy code |
| Commit | `docs: add AI workflow card (W1)` | Single commit adding the file — the audit trail for the card's origin |
| Reference card | `reference-project/fired-up-pizza/workflow-card.md` | The finished example you pattern-matched against |
| PROMPT.md (sister file) | `curriculum/workshops/W1/PROMPT.md` | Optional facilitator prompt to paste into Claude Code while drafting |

---

## Next Steps

In **L1** (next), you'll:

1. Install Gas City and add your project as a rig.
2. Convert `workflow-card.md` into agent instructions (`CLAUDE.md` / `AGENTS.md`) tailored for the `claude` agent.
3. Pick a small ticket, sling it to the agent, and watch the iteration loop run.
4. Update the instructions file when output is wrong — never touch the chat.

The card you just wrote is the blueprint. L1 puts it to work.

After L1, the progression continues:

- **W2** — map the six-agent factory to your project's domain. Your workflow card's Decision Checkpoint becomes the starting point for agent-role boundaries.
- **L2** — install Planner + Architect. Each one gets its own six-section prompt, structurally identical to your four-section card.
- **L3** — install Designer + Coder. Now four agents are reading your conventions; the card's Stack constraints field is the common spine.
- **L4** — install Reviewer + Release Gate. The Iteration Loop you wrote becomes the formula graph's schedule.
- **W3 / W4 / C1** — formula design, feedback loops, and capstone. The card hasn't gone anywhere; it's just been promoted from a document you read to a system you run.

Every session from here builds on this one. Keep the card open in a tab.
