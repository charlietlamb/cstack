# pstack on Claude Code

pstack was written for Cursor. This file maps every Cursor-specific instruction to its Claude Code equivalent. Read it once per session before following any pstack skill. When a pstack skill and this file disagree about a tool, a model, or a path, this file wins. When the user's own CLAUDE.md disagrees with pstack about style or process, the user wins.

## Where things live

cstack installs every skill as a symlink at `~/.agents/skills/<name>/` and mirrors it at `~/.claude/skills/<name>/`, so Claude Code discovers it. The vendored skills already had their `.cursor` paths rewritten at sync time.

- Skills: `~/.agents/skills/<name>/SKILL.md`.
- Playbooks: `~/.agents/skills/poteto-mode/playbooks/<name>.md`.
- Principles: `~/.agents/skills/principle-<name>/SKILL.md`.
- Relative paths inside a skill (`references/rubric.md`, `playbooks/feature.md`, `scripts/watch-pr/watch-pr`) resolve against that skill's own directory.
- The pstack guide: the `upstream/docs/guide/` directory in the cstack repo. Resolve it with `readlink ~/.agents/skills/poteto`.
- The panel helper: `~/.agents/skills/poteto/scripts/pstack-panel`.
- Model config: `~/.agents/pstack-models.md`.

## Tools

| pstack says | Do this in Claude Code |
|---|---|
| `Task` tool | The Agent tool. |
| `subagent_type: generalPurpose` | `subagent_type: "general-purpose"`. |
| `subagent_type: "poteto-agent"` | `subagent_type: "poteto-agent"`. |
| `readonly: true` | `subagent_type: "pstack-readonly"` (no Edit or Write). Use `Explore` only for pure code search. |
| `readonly: false`, agent mode | `general-purpose` or `poteto-agent`. |
| `run_in_background: true` | Same parameter on the Agent tool. You get a notification when it finishes. Never poll. |
| `environment: "cloud"`, cloud workers | A local background agent. Give any agent that writes files `isolation: "worktree"`. |
| `cloud_base_branch` | Create the worktree from that branch yourself, then point the agent at it. |
| Resume a subagent | SendMessage to the agent's id. |
| `AskQuestion` | AskUserQuestion. |
| A todo list | Your task or todo tool if the session has one. Otherwise keep a numbered checklist in your reply and update it as steps finish. Copied playbook steps and `skip: <reason>` lines still apply. |
| Cursor's `/loop` | The `/loop` skill. Use ScheduleWakeup for dynamic pacing and Monitor to wake on an event such as CI, a merge, or a log line. |
| Cursor's built-in `create-skill` | The `anthropic-skills:skill-creator` skill if it is available. Otherwise follow `~/.agents/skills/poteto-mode/playbooks/authoring-a-skill.md` by hand. |
| `/deslop` from `cursor-team-kit` | The built-in `/simplify` skill over the diff. |
| `control-ui` from `cursor-team-kit` | A project `verify-*` skill if one exists. Otherwise Claude in Chrome, the built-in browser, or Playwright through `npx playwright`. |
| `control-cli` from `cursor-team-kit` | A tmux session you start and own: `tmux new -d -s <name>`, `tmux send-keys`, `tmux capture-pane -p`. |
| Origin forge (`origin pr ...`) | Not installed. Use `gh`. |
| Bugbot, agentic security review | Any bot or human review comments on the PR. The same skeptical triage applies. |
| Many parallel agents for one fan-out | For more than about 5 workers, use the Workflow tool. The user invoking a pstack skill that calls for the fan-out is the opt-in. Otherwise send several Agent calls in one message. |

## Paths

The sync already rewrote Cursor paths to these. The table covers any that slip through.

| Cursor path | cstack path |
|---|---|
| `~/.cursor/skills/`, `~/.cursor/plugins/` | `~/.agents/skills/` |
| `.cursor/skills/<name>/` | `.agents/skills/<name>/` in the project. Also symlink `.claude/skills/<name>` to it, because Claude Code only discovers `.claude/skills/`. |
| `~/.cursor/rules/pstack-models.mdc` | `~/.agents/pstack-models.md` |
| `.cursor/rules/*.mdc`, always-applied rules | `AGENTS.md` or `CLAUDE.md` in the project |
| `.cursor/worktrees/` | `.claude/worktrees/` plus anything `git worktree list` reports |
| `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/`. The slug is the absolute cwd with every non-alphanumeric character replaced by `-`, leading slash included, so `/Users/you/proj` becomes `-Users-you-proj`. Each session is one `<session-id>.jsonl`. The current session is the most recently modified file there. Subagent transcripts sit in `<session-id>/subagents/`. |
| "the current agent's store" (orchestrate) | `.cstack/` in the repo root. Add it to `.git/info/exclude`. |

The transcript scoping rule still holds. Read only the current project's directory. Never glob across `~/.claude/projects/*/`.

## Models

pstack assigns models by role. The config file `~/.agents/pstack-models.md` holds one `role: value` line per role, with the same role names as the `/setup-pstack` rule. A role with no line uses the default below.

Values:

- `opus`, `sonnet`, `haiku`, `fable`. A Claude subagent. Pass the value as the Agent tool's `model`.
- `inherit` (also accept `inherit-parent` and `auto`). A Claude subagent with `model` omitted.
- `codex` or `codex:<model>`. A GPT seat through the panel helper.
- `grok` or `grok:<model>`. A Grok seat through the panel helper.

Cursor slugs map by family when they appear in a skill: `claude-*-max` means `opus`, `gpt-*` means `codex`, `grok-*` means `grok`.

| Role | Default |
|---|---|
| `feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb` | `sonnet` |
| `judgment and prose`, `hardest tasks` | `opus` |
| `how explorer`, `why investigators`, `swarm workers` | `sonnet` |
| `how explainer`, `why synthesizer` | `opus` |
| `reflect tooling` | `codex` |
| `reflect judgment, divergent, synthesizer` | `opus` |
| `arena runners`, `architect runners`, `interrogate reviewers` | `opus, codex, grok` |
| `arena cross-judge pool` | `codex, grok, opus` |

Code-writing delegates are always Claude subagents, because only they share this session's tools, permissions, and worktree isolation. External seats review, judge, sketch designs, and write arena candidates inside a worktree you create for them.

"A different model family" (cross-judge, show-me-your-work's trail reviewer, the eval judge) means a `codex` or `grok` seat. Use `opus` only when neither CLI is installed, and say so in the reply.

## Running an external seat

```bash
~/.agents/skills/poteto/scripts/pstack-panel <seat> <prompt-file> <out-file> [--cwd DIR] [--write]
```

1. Write the seat's full prompt to a file under the session scratchpad, or under `/tmp/pstack-<slug>/` when there is no scratchpad. Inline the diff or name exact file paths. The seat starts with no context.
2. Run one call per seat. Run several at once with Bash `run_in_background: true`, or with `&` and `wait` in one command. The wall clock for a large review can reach 10 minutes, so pass a long Bash timeout.
3. Seats are read-only by default (codex `read-only` sandbox, grok `plan` mode). Pass `--write` together with `--cwd <worktree>` only for an arena or architect candidate that must produce files, and only in a worktree made for that seat.
4. Read `<out-file>` for the result. `<out-file>.log` holds the raw run. Exit code 3 means the CLI is missing, and exit code 4 means the seat produced nothing. Either way, run that seat on `opus` instead and say so.
5. You own every seat's output. Judge it, don't forward it.

## Sticky mode

Cursor keeps `/poteto-mode` on through a mode flag. Claude Code has no mode flag. After `/poteto` runs, stay in the mode for the rest of the session. Apply it when a playbook matches or a task needs rigor. Stay out of the way on casual turns. Drop it when the user opts out. If context was compacted and you can no longer see `~/.agents/skills/poteto-mode/SKILL.md` in the conversation, Read it and this file again before the next playbook step.

## Session rules that still apply

- The Claude Code harness rules on confirming risky or outward-facing actions stand. pstack's "Always pause" list is a subset of them.
- Commits and PRs follow the user's CLAUDE.md. That includes any rule about attribution trailers.
- Opening a PR still means the user asked for one, or the running playbook's grant covers it.
