---
name: poteto
description: Enter poteto mode on Claude Code. Loads the full pstack workflow (poteto-mode, its 23 playbooks, and 23 principles) with the Claude Code adapter, then stays on for the session. Use for /poteto, "poteto mode", "work like poteto", or any task that needs rigor, verification, and evidence.
disable-model-invocation: true
argument-hint: "[task]"
---

# Poteto

Run pstack's `poteto-mode` on Claude Code. pstack is Lauren Tan's (poteto) skill set for Cursor, vendored into cstack under its MIT license. This skill is the Claude Code front door.

## Start

1. Read `~/.agents/skills/poteto/references/claude-code.md` in full. It maps every Cursor tool, model, and path to Claude Code. Keep it in force for the whole session.
2. Read `~/.agents/skills/poteto-mode/SKILL.md` in full. That skill is the mode. Follow its Non-negotiables, Principles index, Autonomy, Subagents, Writing the reply, Comments, and Playbooks sections as written, translated through the adapter.
3. Read `~/.agents/pstack-models.md` if it exists. It sets the model for each role. With no file, use the adapter's defaults. Mention `/setup-pstack` once if the file is missing and the task spawns subagents.
4. If the user passed a task, match it to a playbook, open that playbook file, and copy its steps into the todo list verbatim before anything else. If no task was passed, reply with one line saying poteto mode is on and wait.

## Staying in the mode

The mode stays on for the rest of the session. Apply it when a playbook matches or a task needs rigor. Stay out of the way on casual turns. Drop it when the user opts out. After context compaction, repeat steps 1 and 2 before the next playbook step.

"new task" from the user means re-match a playbook instead of continuing the current one.

## Precedence

1. The user's instructions and CLAUDE.md.
2. The Claude Code harness rules on risky and outward-facing actions.
3. The adapter.
4. pstack.
