---
name: mockup
description: Build N intentionally different mockups of one feature as dev routes with static data, built by parallel agents in the current workspace, and present them in a gallery for comparison. Defaults to 10. Use for /mockup, "give me N mockups", "explore designs for X", "show me different directions", or before committing to a UI shape.
argument-hint: "[count] [feature]"
---

# Mockup

Explore the design space for one feature before committing to a shape. Each mockup takes a different position on how the feature should work. The deliverable is a gallery at `/dev/<feature>-mockups` that shows every mockup with its thesis, so the user can compare them side by side.

This skill applies `principle-exhaust-the-design-space` from pstack. It builds on `dev` for routes, fixtures, and the production gate. Read both at `~/.agents/skills/<name>/SKILL.md` before starting.

## Inputs

- The feature. If it is unclear what the feature must do, ask before Phase 1.
- The count. Use the number the user gave, or 10.
- Any constraints the user gave, such as "must fit in a sidebar" or "use the existing table".

Open a todo list with one item per phase.

## Phase 1. Ground

1. Read the existing UI around the feature, the design system (tokens, shadcn components, shared layout), and the domain types for its data.
2. Find the dev route convention and the production gate per `dev` Phases 0 and 1. Add the gate if it is missing.
3. If the Mobbin MCP is connected, run `references` for the pattern and note what the best products do.

## Phase 2. Write the theses

Before any code, write one thesis per mockup. A thesis is one sentence that states what the design bets on, followed by its position on each axis below.

| Axis | Example positions |
|---|---|
| Layout | Table, card grid, list with detail pane, board, timeline, single focused view |
| Primary information | What the eye lands on first, and what is demoted |
| Density | Compact and scannable, balanced, or spacious and focused |
| Interaction | Inline editing, modal, side sheet, command palette, drag and drop, wizard |
| Disclosure | Everything visible, progressive, or on demand |
| Visual treatment | Flat, bordered, elevated, typographic, data-forward |

Rules for the set:

- Every pair of mockups differs on at least two axes, and one of them is Layout, Primary information, or Interaction.
- Two mockups that a user would describe with the same sentence are one mockup. Rewrite one of them.
- Color, spacing, or radius alone never makes a mockup different.
- Include one conservative mockup that extends the current UI, and at least one that breaks from it.

Show the theses as a numbered table. Continue without waiting for approval unless the user asked to review the theses first.

## Phase 3. Shared setup

The parent writes these files before any agent starts. Agents never edit them.

1. `<feature>-mockup-fixtures.ts`, per `dev` Phase 2. Every mockup renders the same data so the comparison is fair. Include the `default`, `empty`, and `many` states at minimum.
2. `mockups/<feature>/registry.ts`, which lists each mockup's number, slug, name, thesis, and component import.
3. The gallery route `/dev/<feature>-mockups`, which renders from the registry.

## Phase 4. Build in parallel

Spawn one agent per mockup in a single message. All agents work in the current workspace, with no worktrees, so the gallery previews every mockup live as it lands.

- Each agent owns exactly one file, `mockups/<feature>/<nn>-<slug>.tsx`, next to the other dev components. It creates that file and touches nothing else. Shared files, production components, and other mockups are read-only to it. This is `principle-separate-before-serializing-shared-state`: disjoint files remove the need to coordinate.
- Each brief stands alone. It contains the thesis and axis positions, the fixture import path, the design system components to use, the file it owns, and the rule that it renders from fixtures with no network.
- Mockups compose existing design system components and tokens. They may build new markup inside their own file. They never modify a shared component. An agent that needs a shared component to change reports that instead of making the change.
- Use `poteto-agent` subagents by default. For more divergence, assign some mockups to `codex` or `grok` seats through `pstack-panel` with `--write --cwd <repo root>`, with the same one-file rule written into the brief. The pstack adapter covers the panel.
- For more than about 5 mockups, fan out with the Workflow tool per the pstack adapter.

## Phase 5. Gallery

Match the project's existing gallery pattern if it has one. In anpord that is `/dev/headers` and `/dev/dithers`. Otherwise build:

- A grid of cards. Each card shows the mockup scaled down, its number, name, and thesis.
- A full view at `?id=<slug>`, with arrow keys to step through the mockups and Escape to return to the grid.
- A state switcher across the shared fixture states, and the theme toggle.

## Phase 6. Verify

1. Typecheck and lint pass across every mockup file.
2. Open the gallery in a real browser. Screenshot every mockup full size at 1440px and at 375px.
3. Compare the screenshots against the theses. If two mockups look alike, or a mockup doesn't express its thesis, rebuild it with a sharper brief. Record which ones you rebuilt.
4. A mockup that fails to build or render counts as missing, not done. Rerun it once, then report it.

## Report

Reply with:

- The gallery URL.
- A table of number, name, thesis, the axes it differs on, and its screenshot path.
- Your pick and why, judged against what the feature needs, labeled as your judgment.
- Anything that failed, was rebuilt, or is unverified.

Keep every mockup. Once the user picks one, build it properly on the feature's `dev` route with the production components.
