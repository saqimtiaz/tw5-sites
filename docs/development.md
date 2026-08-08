# Local Development Guide: tw5-sites

This document covers how to iterate on `tw5-sites` locally — both in isolation
(using the in-repo fixture site) and against a real consumer repo like
`Samtavisi` — without the slow edit → commit → push → re-pin loop that git
dependencies normally require.

## Why this needs a doc

`tw5-sites` is consumed by other repos (e.g. `Samtavisi`) as a git dependency
via npm. That's great for reproducible builds, but painful for development:
by default, testing a change means pushing a commit, updating the SHA pin in
the consumer's `package.json`, and reinstalling — for every single iteration.

This doc describes two workflows that avoid that:

1. **Fixture-based testing** — exercise `tw5-sites`'s build script against a
   minimal site that lives inside the `tw5-sites` repo itself. Use this for
   day-to-day development and CI.
2. **Linked consumer testing** — point a real consumer repo (e.g.
   `Samtavisi`) at your local working copy of `tw5-sites`. Use this to
   validate against a real site before cutting a release.

Use (1) most of the time. Reach for (2) before merging anything that might
affect real consumers, or when debugging something fixture testing can't
reproduce.

---

## 1. Fixture-based testing (primary workflow)

### Setup (one-time)

Create a minimal fixture site inside the `tw5-sites` repo:

```
tw5-sites/
  test-fixtures/
    minimal-site/
      tiddlers/        # a handful of representative tiddlers
      public/          # minimal static files, if your build copies these
      plugins/          # only if you need to test site-level plugin merging
```

**Where to start:** since `Samtavisi` is already small, extract a trimmed
subset of it as the starting point rather than building a fixture from
scratch. Treat this as a one-time copy, not a live link:

```bash
mkdir -p tw5-sites/test-fixtures/minimal-site
cp -r Samtavisi/tiddlers tw5-sites/test-fixtures/minimal-site/
cp -r Samtavisi/public tw5-sites/test-fixtures/minimal-site/ 2>/dev/null || true
```

Then trim it down:
- Keep just enough tiddlers to exercise the interesting paths (a page tagged
  `$:/tags/site-page`, whatever drives the sitemap, etc.) — a handful is
  enough, not the whole site.
- Remove anything specific to Samtavisi's real content (real contact info,
  branding, unrelated pages).
- Commit it into `tw5-sites` and treat it from that point on as owned by
  `tw5-sites`, not synced from `Samtavisi`. It will drift from the real site
  over time — that's expected and fine, since its job is to exercise the
  build script's logic, not mirror production content.

### Running the build against the fixture

```bash
cd tw5-sites
./bin/build.sh fixture-site ./test-fixtures/minimal-site
```

Since the script self-locates `FRAMEWORK_ROOT` via `realpath` on its own
path, running it directly from within the repo works exactly the same way
it would when installed as a dependency — no special-casing needed.

### Adding this to CI

Run the fixture build on every PR to `tw5-sites`, so breakage is caught
before it reaches any consumer:

```yaml
# example CI step
- run: npm install
- run: ./bin/build.sh fixture-site ./test-fixtures/minimal-site
- run: test -f ./test-fixtures/minimal-site/dist/index.html  # sanity check
```

Add more `test -f` / content-grep assertions over time as you find bugs —
each bug you catch in a consumer repo is worth turning into a fixture
assertion so it can't regress silently.

### When to update the fixture

Update it when you add a build feature that needs new fixture content to
exercise (e.g. a new template that depends on a tiddler field the current
fixture doesn't have). Don't re-sync it from `Samtavisi` wholesale — add
just what the new test needs.

---

## 2. Linked consumer testing (pre-release validation)

Use this when you want to validate a `tw5-sites` change against a real,
full-sized site before committing to a version bump.

### Option A: `npm link`

From `tw5-sites`:
```bash
npm link
```

From `Samtavisi`:
```bash
npm link tw5-sites
```

This replaces `Samtavisi/node_modules/tw5-sites` with a symlink to your
local `tw5-sites` working copy. Changes you make to `tw5-sites` are
reflected immediately — no reinstall needed. The `tw5-sites-build` bin
resolves the same way it does in a normal install, so `npm run build` in
`Samtavisi` exercises your local changes directly.

**Caveat:** `npm link` bypasses `node_modules` resolution nuances that only
show up in a real install (e.g. hoisting behavior, `secure-contact` being
resolved from a different location than it would in production). If you
change anything related to dependency resolution itself, verify with a real
install (Option B) before merging.

**Undoing it:**
```bash
# from Samtavisi
npm unlink tw5-sites
npm install   # restores the real git-dependency install
```

### Option B: local `file:` dependency

For a lighter-weight alternative to `npm link` that's closer to a real
install, point `Samtavisi`'s `package.json` at your local path temporarily:

```json
"dependencies": {
  "tw5-sites": "file:../tw5-sites"
}
```

```bash
npm install
```

This does a real install (not a symlink to source in the same way `link`
does — npm may copy or symlink depending on version), which more closely
approximates production resolution, including how `secure-contact` gets
hoisted. Remember to revert this line before committing — it's a local-only
override.

### Validating before a release

1. Make your change in `tw5-sites`.
2. Test against the fixture (`./bin/build.sh` as above).
3. Link into `Samtavisi` (or another real consumer) and run its full build.
4. Diff the output `dist/` against a build from the previous `tw5-sites`
   version to confirm the change is scoped as expected.
5. Once satisfied, commit, tag a version (see below), and update the pin in
   `Samtavisi`'s `package.json`.

---

## 3. Versioning and pinning (context for the above)

- Reference `tw5-sites` and `secure-contact` from consumers by tag or full
  commit SHA, not by branch — branches are mutable and make builds
  non-reproducible.
- Commit `package-lock.json` in consumer repos and use `npm ci` in
  CI/deploy, so the resolved commit doesn't silently drift even if a
  `package.json` range or branch ref is loose.
- After validating a change via the linked-consumer workflow above, tag a
  release in `tw5-sites` (`git tag vX.Y.Z && git push --tags`) and bump the
  pin in the consumer's `package.json` explicitly, rather than tracking a
  moving branch.

---

## Quick reference

| Task                                   | Command                                                                 |
|-----------------------------------------|--------------------------------------------------------------------------|
| Build fixture site                      | `./bin/build.sh fixture-site ./test-fixtures/minimal-site` (from `tw5-sites`) |
| Link local `tw5-sites` into a consumer  | `npm link` (in `tw5-sites`), then `npm link tw5-sites` (in consumer)    |
| Undo link                               | `npm unlink tw5-sites` then `npm install` (in consumer)                 |
| Real-install local test                 | `"tw5-sites": "file:../tw5-sites"` in consumer's `package.json`, then `npm install` |
| Confirm resolved install location       | `npm ls tw5-sites secure-contact` (in consumer)                        |