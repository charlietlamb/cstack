---
name: break-it
description: Adversarial frontend stress test. Feeds a UI worst-case data, states, viewports, and interactions, proves every break with a screenshot from a real Chrome instance, fixes the root cause, and proves the fix with a second screenshot. Use for /break-it, "break it", "try to break this", "stress test the UI", "worst case data", or after building a component, page, or list view.
argument-hint: "[component, page, or route]"
---

# Break it

Act as the most hostile user and dataset this UI will meet. The goal is to find every way it falls apart, prove each one, and fix it. Confirming that it works is not the goal.

The quality of the attack plan decides the value of this skill. A long name is the floor. Think slowly and go deep before touching code.

Skills this one uses, each at `~/.agents/skills/<name>/SKILL.md`:

- `principle-prove-it-works` and `principle-fix-root-causes`. Read both before Phase 3.
- A project `verify-*` skill if one exists. Otherwise offer `create-verification-skill` once.
- `swarm` for Phase 3 when the attack plan has more than about 15 scenarios.
- `opinionated` and `emil` when fixing React components or motion.
- `show-me-your-work` when the user steps away during the run.

Open a todo list with one item per phase before starting.

## Phase 0. Scope

1. Find the target. If the user named nothing and the recent diff doesn't make it obvious, ask.
2. Read the component and everything it renders: props, types, data source, children, styles, virtualization, and formatting helpers for dates, currency, and names.
3. Find the data shape: API types, schema, mocks, fixtures, stories. List every field a user or an external system controls. Those fields are the attack surface.
4. Find how to run it: dev command, route, port, story, or test page.
5. Write the target brief. Name what renders, which fields display, where the data comes from, and every assumption the code makes without checking. Examples are "a name always has a space", "the avatar URL always loads", "the list stays under 100 items", and "status is one of 3 values". Each assumption is a target.

## Phase 1. Attack plan

For every displayed field and every state, work through the categories below. Skip a category only when it cannot apply, and write the reason. Use real-world data shapes, not only synthetic ones: `Aleksandra Wiśniewska-Kowalczyk`, `Jo`, `Christopher Alexander Montgomery III`, `bartholomew.fitzgerald@northwind-industries-holdings.example.com`, an invitation that expired 12 days ago.

### Data extremes

- Length. Empty, 1 character, typical, 60 or more, 300 or more, and one unbroken token with no spaces such as a long email, URL, hash, or German compound word.
- Names. Mononyms, 5-part names, hyphens, apostrophes (`O'Brien`), suffixes (`III`, `Jr.`), all caps, all lowercase, leading and trailing whitespace.
- Initials and avatars. A one-word name, a name that starts with an emoji or digit, a non-Latin first letter, a missing avatar, a broken image URL, a huge image, a transparent image.
- Unicode. Accents, CJK, Arabic and Hebrew, mixed RTL and LTR, emoji ZWJ sequences and flags, combining characters, zero-width spaces.
- Emails and URLs. A long local part, chained subdomains, plus-addressing, IDN domains, uppercase.
- Numbers. 0, 1, negative, decimals, 1,000,000 and up, `NaN`, pluralization (`1 members`).
- Dates. Now, far past, far future, invalid, other timezones, expired, about to expire.
- Enums. Every known value plus one the code doesn't handle.
- Nullability. Every optional field as `null`, `undefined`, and missing.
- Collections. 0, 1, exactly one page, one page plus 1, 10,000, duplicates, identical names.
- Injection-shaped text. `<script>`, `<img onerror>`, `{{ }}`, markdown, HTML entities. All of it must render as literal text.

### States

- Loading, skeletons, throttled network, a request that never resolves.
- Empty, zero results after a filter, a first-time user.
- Errors. 500, 401, 403, timeout, malformed response, partial data.
- An optimistic update that fails and must roll back.
- Stale data during a background refresh, and data that changes while a menu is open.

### Viewport and accessibility

- Widths 320, 375, 768, 1024, 1440, and 2560, plus a narrow container inside a wide page.
- 200% zoom and a large system font size.
- Keyboard only. Tab order, visible focus, Escape closes menus, no focus traps.
- Labels on icon buttons, alt text, landmark roles.
- `prefers-reduced-motion`, dark mode, high contrast.
- Touch targets under 44px.

### Interaction abuse

- Double and triple submit, rapid toggling, clicks during loading.
- Pasting 10,000 characters, rich text, and newlines into single-line fields.
- Back, forward, refresh mid-action, a new tab, a deep link to a state.
- Several menus or popovers open at once, scrolling with a popover open, resizing with things open.

Write the attack plan as a numbered list. Each scenario states the exact data or action and the failure you predict, labeled as a guess. A non-trivial component usually needs 30 or more scenarios. If the plan fits on one screen, go back and think harder. Continue without waiting for approval unless the user asked to review the plan.

## Phase 2. Fixtures

1. Build one worst-case dataset that covers every data scenario. Put it next to the existing fixtures, or in `<component>.worst-case.ts`. Type it with the real data type so it cannot drift from the schema.
2. Add a switch between normal and worst-case data that needs no code edit. Match what the project already uses: a query param such as `?fixture=worst-case`, a dev-only toggle, or a story. Keep it out of production builds.
3. Add a way to force each state: mock handlers, a fixture flag, or browser network throttling.

## Phase 3. Break it in a real browser

Drive a real Chrome instance and look at the pixels. Reading the code is not evidence of a layout.

1. Start the dev server if it isn't running. Kill only what you started.
2. Drive the page with the project's `verify-*` skill if one exists. Otherwise use Claude in Chrome, the built-in browser, or Playwright through `npx playwright`.
3. For each scenario:
   - Load the page with the fixture, state, viewport, or interaction.
   - Save a screenshot to `.break-it/<target>/before/NN-<scenario>.png`.
   - Inspect the screenshot. Look for overflow, clipping, overlap, text cut mid-word without an ellipsis, misaligned rows, layout shift, content pushed off-screen, horizontal scroll, broken avatars, wrong plurals, and raw `undefined`, `null`, `NaN`, or `Invalid Date`.
   - Read the console for errors and warnings.
   - For interaction and accessibility scenarios, perform the action for real.
4. Record each result as BROKE, HELD, or INCONCLUSIVE. INCONCLUSIVE is not a pass.

With more than about 15 scenarios, run them through `swarm`, one worker per category, each worker with its own browser instance and output folder.

Severity:

- P0. A crash, unreadable data, an impossible action, or injected markup that executes.
- P1. Visibly broken layout, lost or misleading content, or an accessibility blocker.
- P2. Usable but wrong: awkward wrapping, inconsistent truncation, minor overflow.
- P3. Polish.

## Phase 4. Report

Send the break report before fixing anything.

```
BREAK REPORT: <target>
Scenarios run: N. Broke: M (P0 a, P1 b, P2 c, P3 d). Inconclusive: k.

#  Sev  Scenario                        What broke                     Evidence
1  P0   name = "<img onerror=...>"      markup executed                .break-it/<target>/before/01.png
2  P1   70-char email, no spaces        status pill pushed off-screen  .break-it/<target>/before/02.png

Held: <scenarios that passed, one line>
Inconclusive: <scenarios and why>
```

Ask whether to fix everything, only P0 and P1, or specific numbers.

## Phase 5. Fix and prove it

For each approved issue, one at a time:

1. Find the root cause in the component, per `principle-fix-root-causes`. Never fix a break by softening the fixture.
2. Fix it with the smallest change that removes the cause. Typical fixes are `min-width: 0` on flex children, `overflow-wrap: anywhere` for unbroken tokens, `text-overflow: ellipsis` with the full value in a `title` or tooltip, line clamping, `minmax(0, 1fr)` in grids, an explicit branch for unknown enum values, fallbacks for missing data, correct plurals, and disabling a control while it submits. Match the project's styling system.
3. If the break has a cheap local test path, follow `tdd`, so the failing test lands before the fix.
4. Re-run the same scenario and save `.break-it/<target>/after/NN-<scenario>.png`.
5. Re-check the normal data at the same viewport. The fix must not regress the normal case.
6. Mark the issue fixed only when the after screenshot shows it resolved.

## Finish

1. Add `.break-it/` to `.gitignore` if it isn't there.
2. Offer to keep the worst-case fixture and switch as a permanent dev tool.
3. Reply with the scope and fixture location, then a table of issue, root cause, fix, and before and after screenshot paths. End with what is still open or inconclusive. Label every claim as measured, inferred, or a guess.

## Rules

- Every claimed break and every claimed fix has a screenshot path.
- Never weaken a fixture to make the UI pass.
- Touch only the target. Report problems in shared components instead of fixing them in passing.
