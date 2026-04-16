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
Enforced by orchestrator + feedback rules (W3/W4)
```

---

## Prerequisites

- [ ] [Project Manifest](../../PROJECT_MANIFEST_TEMPLATE.md) filled in — you'll reference your tech stack and conventions when writing your card
- [ ] Your project repo cloned locally
- [ ] An AI coding assistant you've used enough to have opinions about

**Note:** You do *not* install any Gas City packs in this workshop — this is all design work. Installation starts in L1.

---

## Reference: What "Mature" Looks Like

Before you write your own card, skim the finished equivalent in the reference project:

- [`reference-project/fired-up-pizza/workflow-card.md`](../../../reference-project/fired-up-pizza/workflow-card.md) — a completed `workflow-card.md` for the Fired Up Pizza project

That card is exactly what this session asks you to produce for your own project — same four sections, project-specific content. Your `workflow-card.md` lives in your *project* repo (not the city). In L1 you'll evolve it into agent instructions (`CLAUDE.md` / `AGENTS.md`) that target the `dev-agent` Gas City configuration.

---

## Step 1: Answer the Discovery Questions (~10 min)

Answer these three questions. Keep answers specific — *file paths, commit ranges, ticket IDs.* Vague answers fail this step.

1. **Think of a recent AI coding session that frustrated you.** What went wrong?
   - Common answers: vague output, lost context, hallucinated APIs, wrong framework version.
   - Bad answer: "Claude is dumb." Push yourself: what would the agent have needed to know in order to not be dumb?
2. **What did you do when the agent went off track?**
   - Did you re-prompt? Start a new session? Paste more code?
   - Most people admit: re-prompting, 3–5 times, until it "sort of worked." That's the anti-pattern this card will replace.
3. **How do you currently provide context to your agent?**
   - Pasting full files? Referencing paths? Linking to tickets? Re-typing the same framing every session?

**Deliverable:** Three bullet-point answers, captured in a scratch doc or your notebook. Used as raw material for the card.

---

## Step 2: Draft Your Workflow Card (~20 min)

Create `workflow-card.md` in the root of your project repo with these four sections:

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

### Good Example (reference only — don't copy verbatim)

```markdown
# My AI Workflow Card

## 1. Prompt Template
Every prompt to Claude includes:
- File path or feature name (e.g. `src/components/Cart.tsx`, FUP-3)
- Acceptance criteria verbatim from the ticket
- Stack constraints: "TypeScript strict, Tailwind, no inline styles"
- Link to our component style guide if UI work
- Name 2 similar files to read first for pattern-matching

## 2. Context Reset Rule
Start a fresh session when:
- The conversation has 10+ back-and-forths
- The agent starts repeating itself or contradicting earlier answers
- I switch to a different feature or different file
- The agent proposes something wildly off-base — lost context is cheaper to throw away

## 3. Iteration Loop
1. Agent reads the spec (ticket + linked files) and proposes an approach.
2. I confirm or redirect the approach *before* any code is written.
3. Agent writes code in small slices (one component / one function at a time).
4. I run `npm test` and `npm run lint` after each slice.
5. If a slice fails: I update the spec with the missing constraint, reset, retry — I do *not* type a correction into chat.
6. If a slice passes: commit with a conventional-commit message, move to next slice.

## 4. Decision Checkpoint
I decide:
- Database schema changes
- New package/dependency additions
- API contract changes (URLs, request/response shapes)
- Architecture patterns for new features

Agent decides:
- Function-level implementation details
- Test cases and fixture design
- Error-message wording
- File organization within a component directory
```

### Tailor to Your Project Type

| Project type | What to emphasize in the card |
|--------------|-------------------------------|
| React / TypeScript | Constrain to existing component patterns under `src/components/`; forbid inventing new utility files without asking |
| Backend API | Context reset rule: "start fresh when switching between routes and middleware"; list the testing command explicitly |
| Monorepo | Specify which package the agent is allowed to modify per session — lock scope per feature |
| Infra / IaC | Require the agent to `terraform plan` (or equivalent dry-run) before any apply; checkpoint before state changes |
| Mobile | Force the agent to confirm target platform(s) and minimum OS version in every prompt |
| Issue tracker in use | Prompt template must reference the ticket ID (`FUP-4`, `PROJ-123`) as the Spec field |

### Quality Bar for the Card

- [ ] Every field names a *concrete* thing (a command, a path, a ticket ID). No generic phrases like "good context" or "clear prompts."
- [ ] The Iteration Loop says what happens *when a slice fails* — that's the moment ad-hoc prompting usually sneaks in.
- [ ] The Decision Checkpoint lists *at least three specific categories* under "I decide" and three under "Agent decides."
- [ ] Maximum 4 sections. Maximum one page. If you need more, you're over-engineering.

---

## Step 3: Self-Review the Card (~15 min)

Read your `workflow-card.md` back to yourself as if you were a stranger who knows your tech stack but not your codebase. Ask:

> **"Could I follow this card to implement a feature on this project and get the result I'd accept — without asking a single question?"**

For every section, find the first sentence or bullet that would force you to stop and ask a question. Rewrite it to be unambiguous. Iterate until each section reads as a self-contained, executable instruction.

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

---

## Connection to Gas City

You didn't run any `gc` commands this session — intentional. W1 is a design workshop. But the card you just wrote maps directly to concepts you'll install in L1:

| Workflow Card Section | L1 & Beyond Equivalent |
|-----------------------|------------------------|
| Prompt Template | The `## Role` and `## Inputs` sections of `CLAUDE.md` — plus each agent pack's `prompts/<agent>.md` file |
| Context Reset Rule | Gas City `idle_timeout` in `city.toml`, plus per-agent session lifecycle rules |
| Iteration Loop | The bead → sling → watch → review → iterate-config loop (L1 Step 4–7) |
| Decision Checkpoint | Human-gate beads (`--requires-approval`) in W3; review policies in `docs/REVIEW_POLICY.md` |

Skim [`packs/planner/prompts/planner.md`](../../../packs/planner/prompts/planner.md) to see the mature, per-agent form of a workflow card. Notice how it specifies Inputs, Output Format, Quality Gate, and Process — the same four axes you just wrote for yourself.

---

## Using Your Local Agent for This Session

Rather than providing drafting prompts inline, every session ships with a sister `PROMPT.md` file: [`curriculum/workshops/W1/PROMPT.md`](./PROMPT.md). Paste it into Claude Code (or your preferred CLI coding agent) at the start of the session. It knows how to walk you through these steps, pull context from your Project Overview, and keep your card concrete.

If you want to work without the facilitation prompt, the four quality-bar items above are sufficient guidance on their own.

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
Prompt:     src/components/Cart.tsx + FUP-3 ACs + "TS strict, Tailwind" + "see src/components/Menu.tsx"
```

The value of the template is that it's *boring and invariant*. You never have to think about "what context should I give?" — you fill in the blanks. In L1, the template becomes the "Role" and "Iteration Rule" sections of `CLAUDE.md`. In L2+, it becomes each pack's `## Inputs` section.

If you notice yourself thinking "I'll just dash off a quick prompt without the template this time," that's a signal you've found a case the template doesn't cover. Update the template — don't skip it.

---

## Exit Criteria

- [ ] `workflow-card.md` committed to your project repo with all 4 sections filled in
- [ ] Every section references something concrete (path / command / ticket)
- [ ] You can re-read the card as a stranger to the codebase and not have to stop to ask a question
- [ ] You can state in one sentence what your Context Reset Rule is

---

## Common Issues & Solutions

### Issue: My card is basically "use AI well."
**Solution:** You wrote down principles instead of rules. Rewrite each bullet to start with an imperative verb and name a specific thing: "Include the Jira ticket ID in the prompt", not "include helpful context."

### Issue: I don't have a Context Reset Rule — I just keep going.
**Solution:** That *is* your current reset rule ("never"), and it's probably why you waste time untangling polluted sessions. Pick *any* trigger — 10 messages, or switching files, or lint-failing twice — and commit to it for a week.

### Issue: I'm writing 8 sections because my workflow is complex.
**Solution:** It isn't. You're hiding decisions under categories. Merge related sections. The 4-section cap exists because L1's agent instructions use the same structure, and your agent will read every section on every run.

### Issue: A reviewer (or your re-read) said "looks fine" without engaging.
**Solution:** Force specificity: "Read section 3 aloud. What's the first question you'd still need to ask?"

---

## Next Steps

In **L1** (next), you'll:
1. Install Gas City and add your project as a rig
2. Convert `workflow-card.md` into agent instructions (`CLAUDE.md` / `AGENTS.md`) tailored for a `dev-agent`
3. Pick a small ticket, sling it to the agent, and watch the iteration loop run
4. Update the instructions file when output is wrong — never touch the chat

The card you just wrote is the blueprint. L1 puts it to work.
