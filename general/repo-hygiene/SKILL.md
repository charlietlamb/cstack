---
name: repo-hygiene
description: Habits that keep a codebase readable as it grows. Where a test lives, what a function is called, where helpers go, when a long file should split, config over magic numbers, where errors and docs live, and the gates before a change lands. Use when adding a file, naming a function, or reviewing a module that has grown hard to follow. Pairs with code-standards, which owns module shape, and repo-map, which owns where packages and cross-cutting concerns live.
---

# Repo hygiene

`code-standards` decides how a module is shaped. `repo-map` decides where things live across packages. This skill covers the small habits that decide whether the next file is readable. The rules assume the default stack in `repo-map`. When the repo already does something different on purpose, follow the repo and say so.

## Tests live in `tests/`, mirroring `src/`

```
packages/<pkg>/src/services/trial-runner.ts
packages/<pkg>/tests/services/trial-runner.test.ts
```

A reader finds the test for a file by swapping `src` for `tests` and adding `.test`. Tests next to their subjects double every directory listing.

One exception. A test that must reach a module's private surface may sit beside it, so the module doesn't widen its API just for the test. Write down why in the file.

## Name a function by what it does

A name that only describes the return type (`answerOf`, `asStoredTrial`) hides whether the function reads, decodes, computes, or fetches.

| Instead of | Write | Because |
|---|---|---|
| `asStoredTrial` | `decodeStoredTrial` | It decodes and can fail. |
| `answerOf` | `readAnswer` | It reads from storage. |
| `credentialOf` | `resolveCredential` | It returns an effect that can fail. |
| `readinessOf` | `describeUnreadiness` | It returns problems, not readiness. |
| `reasonOf` | `describeFailure` | It renders a message for a person. |

An `*Of` name is fine for a plain lookup where the noun says everything, such as `cellKeyOf(parts)`. Read the body before renaming. Be most suspicious of a name that describes the opposite of what the function returns.

Never rename with a blanket find and replace. It rewrites the declaration and can leave the body pointing at a global with the old name (`name`, `length`, `status`), which compiles and does the wrong thing. Rename one file at a time and typecheck between files. Check the new name is free across the repo before renaming into it.

## Utilities do not sit above business logic

A file should open with the thing it is named for. Move scaffolding out by what it is:

```
domain/      pure values, errors, keys, types
utils/       shaping and formatting with no dependencies
services/    behavior, spans, logs
layer.ts     composition
```

A small helper used by one file may stay in that file, below the main export.

## A line count is a prompt, not a verdict

A long file is worth opening. It is not automatically worth splitting.

Leave it alone when the length is the responsibility:

- A port or contract: its types, its tag, and the one layer that implements it.
- A vendored primitive. Splitting it breaks the next upgrade.
- Data such as icon paths and fixtures.

Split it when it opens with something other than the thing it is named for, or holds several components with the exported one last.

## Config, not a number at the top of a file

`const ROLE_CACHE_CAPACITY = 4096` states neither its unit nor its reason.

- A value that differs per deployment is an Effect `Config`.
- A span of time is a `Duration`, so the unit lives in the type. Write `Duration.hours(1)`, never `60 * 60`.
- A true constant stays, next to what it configures.

## Errors belong to their domain

- Domain errors are `Data.TaggedError` in the owning package's `domain/errors.ts`, with no status codes.
- Transport errors live in the shared schema package with their HTTP status.
- One mapper file per domain in the server's HTTP layer turns domain errors into transport errors. Handlers pipe through it and never map inline.
- The mapper switches on `_tag` with a `default` branch of `error satisfies never`, so a new domain error is a type error instead of a silent 500.
- A store failure is a defect. Log it, then `Effect.die`.
- Boundary validation, such as a request over a limit or an unknown id, stays in the handler. It was never a domain failure.

## Docs sit beside what they document

A README about an auth flow goes in the auth folder, where someone changing the flow will see it. A central docs folder drifts out of date unread.

## Comments carry why, never what

Keep a comment only for a constraint, an invariant, or a rejected alternative. Delete comments that restate the code. `code-standards` has the full rule.

## Before a change lands

Read the root `package.json` scripts and run whichever of these exist: `typecheck`, `check`, `check:comments`, `knip`, `test`. Name any that are missing.

- A refactor that changes a test count changed behavior. Stop and find out why before touching the test.
- A dynamic `import()` isn't checked by the compiler. After moving a file, grep for its old path as a string.
