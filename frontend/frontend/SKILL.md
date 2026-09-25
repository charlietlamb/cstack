---
name: frontend
description: Frontend engineering standards for React and TypeScript work, and the map of every frontend skill in cstack with when to use each. Use when building, reviewing, or refactoring frontend UI, forms, state, data fetching, hooks, or shared component logic, or when unsure which frontend skill applies.
---

# Frontend

This skill has two jobs. It sets the default standards for React and TypeScript work, and it routes to the other frontend skills. Every skill named here lives at `~/.agents/skills/<name>/SKILL.md`. Read a skill in full before applying it. Pick the narrowest skill that fits, and chain several only when the task spans them.

## Default approach

- Stay away from `useEffect`. Use it only to synchronize with external systems, and never for derived state, event handling, data fetching that belongs in TanStack Query, or logic that can run during render.
- Do not repeat yourself. Extract shared logic into typed helpers, shared components, or custom hooks when the duplication reflects the same product behavior.
- Keep components focused on rendering and composition. Move complex state, branching, and orchestration into custom hooks with clear inputs and return types.
- Prefer clean shared logic over one-off component-local code. Keep abstractions small, named after the domain behavior, and easy to test.
- Only use `useMemo` when it is clearly needed for expensive computation or referential stability. Do not wrap simple expressions or props by default.
- Use TanStack Form for forms, including validation, field state, submission state, and form-level orchestration.
- Use TanStack Query for querying, caching, mutations, invalidation, prefetching, and server-state lifecycle management.
- Use shadcn/ui components before creating custom UI primitives, and compose them with semantic tokens and accessible structure.
- Use the `cn` util for className concatenation and conditional classes.

## Which skill to use

### Code standards

Apply these whenever you write or change React code.

| Skill | Use it for |
|---|---|
| `opinionated` | The strict house rules: barely any `useEffect`, TanStack Form and Query, one component per file, no nested ternaries. It wins over every other skill on this page when they disagree. |
| `shadcn` | Adding, composing, styling, or debugging shadcn/ui components, and any project with a `components.json`. |
| `tanstack-query-best-practices` | Query keys, caching, mutations, invalidation, prefetching, SSR, and server state. |
| `vercel-react-best-practices` | React and Next.js performance: rendering, data fetching, bundle size. |
| `baseline-ui` | The non-negotiable UI floor in Tailwind projects: animation durations, type scale, component accessibility, layout anti-patterns. |

### Before building a new pattern

| Skill | Use it for |
|---|---|
| `mockup` | Exploring the design space: N intentionally different mockups (default 10) built in parallel as dev routes, compared in one gallery. |
| `references` | Studying how top products handle a pattern (steppers, onboarding, forms, flows) before building one. Needs the Mobbin MCP. Skip it when Mobbin isn't connected and say so. |
| `design-engineer` | Design-heavy work that needs several of the skills below at once. It orchestrates research, the `better-*` skills, and motion. |

### Previewing and iterating

| Skill | Use it for |
|---|---|
| `dev` | Every new or changed UI. A production-gated dev route renders the real components with typed static fixtures for every state, so you iterate in the browser before wiring real data. |

### Building, by domain

Apply the one that matches what you are touching.

| Skill | Use it for |
|---|---|
| `better-layout` | Grouping, alignment, spacing, reading order, progressive disclosure, breakpoints, RTL and logical properties. |
| `better-typography` | Fonts, type scale, heading hierarchy, wrapping, truncation, tabular numbers, text contrast. |
| `better-colors` | Palettes, semantic color tokens, light and dark themes, contrast, OKLCH. |
| `better-accessibility` | Focus states, keyboard support, ARIA, forms, screen readers, hit areas, reduced motion. |
| `better-writing` | Every user-facing string: button labels, errors, empty states, placeholders, settings labels. |
| `better-ui` | Visual polish: radius, shadows, borders, icons, hover states, micro-interactions. |

### Motion

Start at `emil`. It routes to `emil-design-eng`, `animations`, `find-animation-opportunities`, `improve-animations`, `review-animations`, and `animation-vocabulary`. Add `apple-design` for gesture-driven UI, springs, sheets, drag and swipe, momentum, and translucent depth.

### Reviewing and auditing

These skills are read-only on source. They report findings or write plans. Implement their output as a separate step.

| Skill | Scope | Output |
|---|---|---|
| `interface-review` | A change: uncommitted work, the current branch, or a PR. | Hands the affected surfaces to `better-interface`. |
| `better-interface` | A whole screen, flow, or feature across every `better-*` domain. | One ranked verdict. |
| `improve-ui` | An existing surface checked against its own design system. | Verified problems plus implementation plans. |
| `review-animations` | Motion code in a diff or file. | Flags against a strict bar. |
| `improve-animations` | All motion in a codebase. | A prioritized audit plus fix plans. |
| `find-animation-opportunities` | Places that lack motion. | Proposals with exact values, and many rejections. |

Correctness, tests, security, and general performance review belong to `/code-review` and to `interrogate`, not to these skills.

### Proving it works

| Skill | Use it for |
|---|---|
| `break-it` | Stress-testing a finished component with worst-case data, states, viewports, and interactions, proven in a real browser. |
| `react-doctor` | Scanning before a commit or after a feature: lint, accessibility, bundle size, architecture. The health score must not regress. |
| `create-verification-skill` | Generating a project `verify-*` skill once, so every agent can drive the app and capture evidence. |

## Typical flow

1. Non-trivial or risky work starts in `/poteto`. Its playbooks call these skills as their steps need them.
2. Before building a new pattern, run `references`. When the shape is open, run `mockup` and pick a direction.
3. Build the chosen UI on a `dev` route under `opinionated` and this skill's defaults, plus `shadcn` and `tanstack-query-best-practices` where they apply. Settle details with the matching `better-*` skills, then wire real data.
4. Add motion only through `emil`, and only where `find-animation-opportunities` would accept it.
5. Run `break-it` on the finished component, then `react-doctor`.
6. Before opening a PR, run `interface-review` on the branch.

## Precedence

1. The user's instructions and CLAUDE.md.
2. `opinionated`.
3. This skill's defaults.
4. The third-party standards: `shadcn`, `tanstack-query-best-practices`, `vercel-react-best-practices`.
5. The design, motion, and review skills.

## Review checklist

- Can this logic avoid `useEffect` by using render-time derivation, event handlers, TanStack Query, TanStack Form, or a custom hook?
- Is `useMemo` only used where it pays for itself?
- Is duplicated behavior extracted without creating a vague utility layer?
- Are forms powered by TanStack Form instead of local ad hoc form state?
- Is remote data modeled as server state with TanStack Query?
- Are shadcn/ui primitives used and composed before custom markup?
- Are className values composed with `cn` instead of manual string concatenation?
