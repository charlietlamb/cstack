---
name: repo-map
description: The default file structure and cross-package architecture rules (workspace layout, dependency direction, actor, identifiers, ids, schemas, errors, services, HTTP API, cache), plus a generator that writes a project-local map of a specific repo. Use before adding a package, a service, an API endpoint, a table, or anything that needs an id or crosses a process boundary, and for "map this repo" or "generate a repo map".
argument-hint: "[generate]"
---

# Repo map

Two jobs. The rules below are the default architecture for new and existing repos on the default stack. The generator at the end writes a map of one specific repo, with its real packages, ports, and commands.

When a repo already has a local map, read it first. Its facts win over the defaults here. When a repo deviates from a rule on purpose, follow the repo and say so.

Pairs with `code-standards` for module shape, `repo-hygiene` for day-to-day habits, and `effect` and `effect-composition` for Effect idiom. Each lives at `~/.agents/skills/<name>/SKILL.md`.

## Default stack

Bun workspaces and Turbo. An Effect backend, a TanStack Start frontend, Drizzle on Postgres, Redis for cache, Better Auth.

## Workspace layout

```
apps/
  server/            HTTP handlers and layer composition
  web/               TanStack Start frontend
packages/
  schema/            wire contracts, branded types, HTTP API groups, auth middleware tag
  ids/               prefixed id generation
  db/                Drizzle schema, pool, migrations
  cache/             Redis behind a Cache tag
  auth/              auth, sessions
  ui/                shared React components
  sdk/               published client, if the product has one
  <domain>/          one package per business domain
scripts/             repo tooling
```

Dependency direction:

- `schema` and `ids` depend on nothing. Everything may import them. Keep them that way.
- Infrastructure packages (`db`, `cache`, `auth`) never import a domain package.
- Domain packages import `schema`, `ids`, and infrastructure. A domain package never imports another domain package's internals.
- Apps compose packages. Nothing imports from an app.
- Import from the defining module. No barrel files or re-exports.

## Domain package layout

```
packages/<domain>/
  src/
    domain/          errors, views, keys, pure types
    repositories/    one per table, returns Option, no business rules
    services/        one per responsibility, owns spans and logs
    layer.ts         composition; internals must not leak into requirements
  tests/             mirrors src/
```

- One repository per table. A repository that owns two tables needs a stated reason, such as a write that must record its own audit event.
- Services take `Actor` first, carry one `Effect.withSpan("Service.method")`, and annotate logs with the organization id.
- `layer.ts` provides repositories and id generation beneath the services, so callers only supply `Database` and `Cache`.

## Actor

`Actor` is the authenticated caller: `{ id: UserId, organizationId: OrganizationId }`.

- Define it once in `schema`. Never redeclare it.
- Brand both ids so they cannot be swapped.
- Decode it at the auth boundary in the server and provide it as `CurrentActor`.
- Every service method that touches organization data takes `Actor` first.
- `actor.organizationId` scopes every query. `actor.id` goes to `created_by`, `updated_by`, and audit rows.
- Don't call it `user`. `user` is the person record, and an actor may later be an API key.

## Identifiers

Rows that callers address by a handle carry three fields.

| Field | Example | Role |
|---|---|---|
| `internal_id` | `pmt_9EKR3ZHZ…` | Primary key. Every foreign key points here. Immutable. |
| `id` | `hello-world` | The handle in API paths and the SDK. Slug-shaped, unique per organization, mutable. |
| `name` | `Hello World` | Display text. Not an identifier, not unique. |

- Foreign keys reference `internal_id`, so renaming a handle never rewrites another table.
- Cache keys use the public `id`, so a lookup is one cache read. A rename invalidates both the old and new handle.
- Wire contracts expose `id` and `name`. `internal_id` never crosses the wire.
- Rows nobody names (versions, events, sessions) only need `internal_id`.

## Ids

All generated ids come from `ids`. Never call `crypto.randomUUID()` or `Math.random()` directly.

- Prefixes live in one file in `ids`. Add entries. Never rename one, because prefixes are stored in rows and customer integrations.
- Prefixes are descriptive, not minimal. Prefer `chev` over `evt`, so a generic prefix stays free for a generic concept.
- The suffix is Crockford base32 generated through Effect's `Random`, so a seeded runtime gives stable ids in tests.

## Schema

`effect/Schema` at every process boundary: HTTP, cache payloads, queue messages, SDK contracts.

- Contracts live in `schema`, never in a domain package.
- Derive types with `export type X = typeof X.Type`. Never hand-write a duplicate interface.
- Brand any `string` or `number` that could be confused with another, such as `UserId`, `OrganizationId`, or `VersionNumber`.
- Decode at the edge. Never cast with `as`.
- A timestamp that crosses both the store and the cache uses `Schema.Union(Schema.DateFromSelf, Schema.Date)`. Rows arrive as `Date` and cached JSON as an ISO string. Picking one silently breaks the other path.
- URL params arrive as strings. Use a `FromString` variant of the branded type.

## Errors

- Domain errors are `Data.TaggedError` in the owning package's `domain/errors.ts`, with no status codes.
- Transport errors are `Schema.TaggedError` in `schema`, annotated with their HTTP status.
- One mapper file per domain in the server's HTTP layer. Handlers never construct HTTP errors.
- A store failure is a defect (`Effect.die`), not a client error.

## HTTP API

- One group per surface in `schema`, composed in one `api.ts`.
- One handler file per group in the server.
- Authentication goes through middleware. Handlers never read headers.
- Adding a surface touches four places: a new group file, `api.ts`, a new handler file, and the server's API layer. Nothing else changes.

## Cache

- The cache is never load-bearing. A Redis failure logs and falls back to a store read.
- `get` and `set` take a `Schema`. Payloads are decoded, never cast.
- Keys come from the owning package's `domain/keys.ts`. Every key for one entity shares a prefix, so one write can invalidate all of them.
- With `REDIS_URL` unset, the cache is a no-op, so local dev runs without Redis.

## Validation

Read the root `package.json` scripts and run whichever of these exist: `check`, `typecheck`, `test`, `knip`. Run the repo's React doctor script for React changes. Name any gate the repo lacks.

## Generate a map for this repo

Run this on "map this repo", "generate a repo map", `/repo-map generate`, or when a repo has no local map and the task crosses packages.

1. Name the skill `<repo>-map`, after the repo directory, such as `anpord-map`. Never name it `repo-map`, which would shadow this skill.
2. Interview the repo, not the user. Ask only what the code cannot answer.
   - Workspaces from the root `package.json` and `turbo.json`.
   - Each package: its name, what it owns, and its internal dependencies, read from each `package.json`.
   - Apps: framework, dev command, and port.
   - Every root script, grouped as dev, gates, database, and tooling.
   - Where the rules above live in this repo: the `Actor` definition, the id prefix file, the error mappers, the API composition file, cache keys.
   - Every deviation from the rules above.
   - Local setup that isn't obvious: env vars, seed scripts, test organizations, keys.
3. Write `.agents/skills/<repo>-map/SKILL.md` in the repo, and symlink `.claude/skills/<repo>-map` to it so Claude Code discovers it. Sections:
   - **Packages.** A table of package, what it owns, and what it depends on.
   - **Apps.** Framework, dev command, port.
   - **Where the rules live.** Real paths for each cross-cutting rule.
   - **Deviations.** Each one with its reason if the code or git history shows it.
   - **Commands.** The gates and dev commands, copied from `package.json`.
   - **Local setup.** Only what a new agent would get wrong.
   Every path, command, and port must be one you read in the repo. Never write a placeholder.
4. Point to this skill for the rules instead of copying them.
5. Prove the map. Check that every path it names exists and every command it names is a real script. Run one dev command, and one gate if it is cheap.
6. Reply with the map's path, the deviations found, and anything you couldn't determine.
