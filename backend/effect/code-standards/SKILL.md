---
name: code-standards
description: Structural standards for TypeScript and Effect codebases: single responsibility, open/closed, small scoped files, and preferring Effect's built-ins over hand-rolled logic. Use when writing or reviewing any TypeScript module, especially services, layers, and schema definitions. Read before creating a new file or when a file grows past ~150 lines.
---

# Code Standards

Applies to every TypeScript file in the repo. Pairs with the `effect` and
`effect-composition` skills — read those for Effect idiom, this for structure.

## Single Responsibility

One file, one reason to change.

- A file that defines domain types, runs queries, and shapes HTTP responses has
  three reasons to change. Split it.
- Name the file after the one thing it does. If the honest name needs "and" or
  "utils", the file is doing too much.
- A service module wires dependencies and exposes behaviour. It does not also
  own SQL construction, cache key formats, or serialisation.

Split a service by the shape of its work:

```
src/
  schema.ts        # contracts, derived types
  errors.ts        # tagged errors
  keys.ts          # cache key construction
  repository.ts    # persistence, returns domain values
  service.ts       # orchestration, spans, logs
  layer.ts         # composition
```

## Open/Closed

Extend by adding, not by editing.

- Prefer a new module over a new branch in an existing `switch`.
- Add capability by composing another `Layer`, not by widening an existing one.
- When behaviour varies, pass it in (a `Schedule`, a resolver, a strategy) rather
  than growing conditionals inside the callee.
- Tagged unions over boolean flags: adding a case should be additive and
  exhaustiveness-checked, not a new `if` in five places.

## File Size

- Target under 150 lines. Past 200, split before adding more.
- A file you must scroll to understand is already too large.
- Extracting three lines used twice is premature; extracting a coherent
  responsibility is not. Split along seams, not line counts.

## Use Effect's Built-Ins

Never hand-roll what Effect provides. Check the API before writing a helper.

| Instead of | Use |
| --- | --- |
| `Date.now()`, `new Date()` | `Clock.currentTimeMillis` |
| `Math.random()`, `crypto.randomUUID()` | `Random`, or an injected id service |
| manual retry loops | `Effect.retry` + `Schedule` |
| `try/catch` around promises | `Effect.tryPromise` |
| `Promise.all` | `Effect.all` (set `concurrency`) |
| `setTimeout` | `Effect.sleep`, `Effect.timeout` |
| ad hoc `Error` subclasses | `Data.TaggedError` |
| nullable returns | `Option` |
| hand-written validators | `Schema` |
| `process.env` reads | `Config` |
| manual resource cleanup | `Effect.acquireRelease` |
| bare `console.log` | `Effect.log*` + `Effect.annotateLogs` |
| caching by hand | `Effect.cached`, `Effect.cachedWithTTL` |

Reach for the platform before the ecosystem, and the ecosystem before your own
implementation.

## Schema At Boundaries

Anything crossing a process boundary — HTTP, queue, cache payload, SDK contract —
is defined with `effect/Schema`, in a shared package, and types are derived.

```ts
export const PromptView = Schema.Struct({
  name: Schema.String,
  version: Schema.Int,
});

export type PromptView = typeof PromptView.Type;
```

Never hand-write an interface that duplicates a schema. Decode at the edge so the
inside of the system holds only validated values.

Internal-only shapes that never cross a boundary may stay plain interfaces.

## Renaming Across Files

Never rename a symbol with a blanket find/replace. It rewrites declarations but
leaves bodies referencing the old name, which silently resolves to a global
(`name`, `length`, `status`) instead of failing — the code compiles and does the
wrong thing at runtime.

Rewrite each affected file deliberately, then verify with the repo's typecheck script
before moving on. If more than a handful of files are affected, rewrite whole
files rather than patching lines.

## Naming

- Files kebab-case, matching their main export.
- Import from defining modules; do not add re-exports or barrel files.
- No `utils.ts`, `helpers.ts`, `misc.ts`, `common.ts` — name the responsibility.
- Tagged errors read as facts: `PromptNotFound`, `VersionConflict`.
- Spans read `Service.method`: `Prompts.create`.

## Comments

Explain *why*, never *what*. A comment restating the code is noise; a comment
naming a constraint, an invariant, or a rejected alternative earns its place.
Prefer clearer names and smaller functions over explanation.

Code is expected to read for itself. Before writing a comment, try a clearer
name or a smaller function — that is almost always the better fix.

Enforced by the repo's comment check where one exists (`check:comments` in the default stack, run in `pre-commit`):

- **No `//` line comments.** `/* */` only. The exceptions are `biome-ignore`
  directives and `/// <reference>` pragmas, which are functional.
- **No comment block longer than three lines.** A rationale essay above a
  function is the smell this catches; if the reasoning genuinely needs more
  room, it belongs in a doc or a commit message, not the source.

Write a comment only when the code cannot state the thing itself:

| Earns its place | Delete it |
| --- | --- |
| A vendor or protocol quirk (`Anthropic reports cache tokens beside input, not inside it`) | Anything restating the identifier's own name |
| Why a value must be `null` rather than `0` | `@param`/`@returns` that repeat the types |
| A CVE or security invariant behind a design | Narrative history of what once broke |
| A rejected alternative someone would otherwise re-attempt | Design-philosophy essays |

Published SDK API may keep a one-line JSDoc where it aids autocomplete for
consumers outside this repo. Nothing else does.

## Validation

After any structural change, run the repo's own gates. Read the `scripts` in the root `package.json` and run whichever of these exist: `check` (lint and format), `typecheck`, `test`, `knip` (unused files, deps, exports), and `check:comments`. Name any of the five that the repo lacks in your reply instead of skipping it silently.
