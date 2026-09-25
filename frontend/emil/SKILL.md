---
name: emil
description: Front door for the Emil Kowalski design-engineering skills in cstack. Routes a UI polish, animation, or motion request to the right skill (emil-design-eng, animations, find-animation-opportunities, improve-animations, review-animations, animation-vocabulary). Use for /emil, "make this feel like Emil would", UI polish, motion, easing, springs, or "what's this animation called".
argument-hint: "[request]"
---

# Emil

Route the request to one skill below, Read its `SKILL.md` in full, and follow it. Each skill lives at `~/.agents/skills/<name>/SKILL.md`. Pick one. Chain a second only when the request spans two rows, and say which two you chose and why.

| The user wants | Skill |
|---|---|
| Taste, polish, and component design decisions, or the philosophy behind them | `emil-design-eng` |
| To build or tune an animation: easing, springs, transforms, clip-path, gestures, performance | `animations` |
| To know where motion would help and where it would hurt. Read-only | `find-animation-opportunities` |
| An audit of all motion in a codebase plus fix plans another agent can execute. Read-only on source | `improve-animations` |
| A review of animation code in a diff or file against a strict bar | `review-animations` |
| The name of an effect they can only describe ("the bouncy thing when a popover opens") | `animation-vocabulary` |

## Rules

- Restraint first. Before adding motion, ask whether the interaction needs it. `find-animation-opportunities` rejects more than it proposes, and that is the intended outcome.
- `find-animation-opportunities`, `improve-animations`, and `review-animations` never edit source. If the user wants the change made, finish the read-only skill first, then implement its output as a separate step.
- Every motion change gets checked in a real browser before it counts as done. Use the same Chrome setup as `break-it`, and check `prefers-reduced-motion`.
- For React and TypeScript structure around the animated component, `opinionated` applies alongside these.
