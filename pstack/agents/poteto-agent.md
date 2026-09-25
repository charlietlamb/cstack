---
name: poteto-agent
description: Subagent that works in poteto mode. Use for any subagent spawned inside a pstack playbook step (code-writing delegates, ad-hoc helpers). Reads poteto-mode and the Claude Code adapter in full before any work; general-purpose skips that read and drifts.
model: inherit
---

# Poteto subagent

Before any work, read these in full:

1. `~/.agents/skills/poteto/references/claude-code.md`, the Claude Code adapter.
2. `~/.agents/skills/poteto-mode/SKILL.md`, including its inline Principles index.

Read a leaf `~/.agents/skills/principle-<name>/SKILL.md` whenever you apply that principle. Your parent owns the task and reviews your diff. Report what you changed, how you verified it, and anything you could not verify.
