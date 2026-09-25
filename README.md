# cstack

Charlie's agent skills, grouped by area. Inspired by [gstack](https://github.com/garrytan/gstack). [pstack](https://github.com/cursor/plugins/tree/main/pstack) is the gold standard for how skills here are written.

## Layout

```
<area>/<skill>/SKILL.md            a skill
<area>/<group>/<skill>/SKILL.md    a skill inside a group
<area>/agents/<agent>.md           a Claude Code subagent
```

| Area | Skills |
|---|---|
| `pstack/` | `/poteto` plus 47 vendored pstack skills (playbooks, principles, how, why, arena, swarm, interrogate, unslop, ...). Agents `poteto-agent`, `pstack-readonly`, `comment-sicko`. |
| `frontend/` | `/frontend` (standards plus a map of every skill below). `/dev` (production-gated preview routes with static fixtures), `/mockup` (N intentionally different mockups, default 10), `/break-it`. `/opinionated` (strict React and TypeScript standards) and the skills it pulls in: `frontend`, `shadcn`, `tanstack-query-best-practices`, `vercel-react-best-practices`, `react-doctor`, `baseline-ui`, `references`, `design-engineer`, `apple-design`, `improve-ui`, `interface-review`, and `better-accessibility`, `better-colors`, `better-interface`, `better-layout`, `better-typography`, `better-ui`, `better-writing`. `/emil` and the Emil skills it routes to: `emil-design-eng`, `animations`, `find-animation-opportunities`, `improve-animations`, `review-animations`, `animation-vocabulary`. |
| `backend/effect/` | `effect`, `effect-composition`, `effect-service-design`. |

Skill names must be unique across the repo. `install.sh` refuses to run when two collide.

## Install

```bash
./install.sh
```

Every skill is symlinked to `~/.agents/skills/<name>` and `~/.claude/skills/<name>`. Every agent is symlinked to `~/.claude/agents/<name>.md`. Edits in this repo are live. Re-run after adding, renaming, or deleting a skill. The installer prunes its own dead links and never touches a path it didn't create.

## pstack

`pstack/` is Lauren Tan's pstack for Cursor, vendored under its MIT license (`pstack/LICENSE`) and adapted for Claude Code.

- `/poteto` is the entry point. It loads `pstack/poteto/references/claude-code.md`, the adapter that maps Cursor tools, models, and paths to Claude Code, and then `poteto-mode` in full.
- `/setup-pstack` writes `~/.agents/pstack-models.md`, the model for each role. Values are `opus`, `sonnet`, `haiku`, `fable`, `inherit`, `codex[:model]`, or `grok[:model]`.
- Review panels (`interrogate`, `arena`, `architect`, cross-model checks) use Claude subagents plus GPT through `codex` and Grok through `grok`, run by `pstack/poteto/scripts/pstack-panel`.

Update from upstream:

```bash
./scripts/sync-pstack.sh          # latest main
./scripts/sync-pstack.sh <sha>    # a pinned commit
```

The sync replaces only the upstream-owned skills listed in `pstack/upstream/skills.txt`, rewrites `.cursor` paths to `.agents` and `.claude` paths, and fails if one is left unmapped. `poteto`, `agents/`, and the adapter are cstack-owned and never overwritten. The pinned commit is in `pstack/upstream/UPSTREAM`.

## Writing a skill

Follow pstack's `authoring-a-skill` playbook and `unslop`. Keep only prose that changes a decision. Delegate to other skills by path (`~/.agents/skills/<name>/SKILL.md`) instead of restating them. No em dashes, sentence-case headings, every claim backed by evidence.
