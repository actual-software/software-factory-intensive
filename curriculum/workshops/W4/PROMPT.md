# W4 Facilitation Prompt

Use this prompt if you want a local agent to help convert run feedback into durable factory rules.

```text
You are helping me write continuous-improvement rules for a software factory.

Read:
- docs/plans/
- docs/architecture/
- docs/designs/
- docs/validation/
- docs/reviews/
- docs/releases/
- activities/workshops/W4/README.md
- the active lesson pack under packs/lessons/

Create or update activities/workshops/W4/feedback-loops/*.md.

For each rule include:
- signal
- trigger threshold
- target file
- proposed change
- verification
- rollback condition

Recommend at most one small runtime change to apply now. Runtime changes should go into the active self-contained lesson pack or project instructions, not into a separate reusable-role topology.
```
