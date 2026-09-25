---
name: dev
description: Build new or changed UI on a dev route with static fixture data, preview every state in the running app, and iterate there before wiring real data. Dev routes are gated out of production. Use for /dev, "make a dev route", "preview this UI", "let me see it with fake data", or whenever new UI needs iteration before it is connected to the backend.
argument-hint: "[feature]"
---

# Dev

Preview new UI on a dev route that renders the real components with static data. Iterate on the route until the UI is right, then wire it to real data. The dev route stays as a permanent preview.

## Phase 0. Find the convention

1. Look for existing dev routes before creating anything. Common places are `src/routes/dev/`, `app/dev/`, and `pages/dev/`. Look for fixture files (`*-fixtures.ts`) and preview helpers (a preview screen, a viewport hook, a theme toggle) near them.
2. If a convention exists, match it exactly: file layout, naming, helpers, and page chrome. In anpord that is `apps/web/src/routes/dev/<feature>.tsx`, `apps/web/src/components/dev/<feature>-fixtures.ts`, `PreviewScreen`, and `ThemeToggle`.
3. If none exists, create the layout below for the project's router and say that you created it.

## Phase 1. Gate `/dev` out of production

Gate once, in a layout route that wraps every dev route. Never gate each page separately.

- TanStack Router. Add `routes/dev/route.tsx` whose `beforeLoad` throws `notFound()` when `import.meta.env.DEV` is false.
- Next.js app router. Add `app/dev/layout.tsx` that calls `notFound()` when `process.env.NODE_ENV === "production"`.
- Other routers. Wrap the dev routes in one parent route with the same check.

If the gate is new, prove it once. Build for production, serve the build, and confirm `/dev/<feature>` returns the not-found page. Paste the result.

## Phase 2. Fixtures

1. Write `<feature>-fixtures.ts` next to the existing fixtures, or in `components/dev/`.
2. Type every fixture with the real domain types. Import the types and use `satisfies`, so a schema change breaks the fixture at compile time.
3. Use realistic data. Write real-looking names, emails, dates, counts, and statuses. Never write `foo`, `test`, or lorem ipsum.
4. Export one fixture per state the UI can be in: `default`, `empty`, `loading`, `error`, `single`, `many`, and `worstCase`. `break-it` extends `worstCase` later.

## Phase 3. The route

1. Render the production components. Never copy a component into the dev route. Every change made while iterating lands in the real component file.
2. If a component fetches its own data, split it into a view that takes props and a container that fetches. The dev route renders the view with fixtures. This split is the `opinionated` rule of keeping query logic out of rendering.
3. No network. The route must render with the backend stopped. Pass fixtures as props. Mock the query layer only when the view cannot take data as props.
4. Show every state. Either render the states in labeled sections on one page, or add a `?state=` search param with a switcher. Match what the project already does.
5. Add the theme toggle and a viewport control when the project has them.
6. If the project has a dev index page, add the new route to it.

## Phase 4. Iterate

Run the loop in a real browser. Reading the code is not evidence of how the UI looks.

1. Open `/dev/<feature>` with Claude in Chrome, the built-in browser, or Playwright.
2. Screenshot every state at 375px and at 1440px, in light and dark.
3. Change the real component, reload, and screenshot again. Compare before and after.
4. Apply the matching `better-*` and `emil` skills as the design firms up. `frontend` maps which skill covers what.
5. When the design is settled, run `break-it` on the route.

## Finish

1. Typecheck and lint pass.
2. Reply with the route URL, the fixture file, the states covered, and the final screenshots. Label anything not verified in the browser as unverified.
3. Keep the route and fixtures. They are the preview for every future change to this UI.
