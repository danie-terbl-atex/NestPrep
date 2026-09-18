# functions — NullState app `nestprep` (Cloud Functions)

Cloud Functions for the NullState app **nestprep**: TypeScript, 2nd generation, holding only what
Firestore Security Rules cannot express (foundation ADR-0002 in the vault at
`../../nullstate-vault/`). Before any task run the **nullstate-memory** skill; after any change
update the vault in the same change. The root `CLAUDE.md` one level up has the full contract.

## Running this part

Node 22 is the deployed runtime (`engines` in `package.json`); Node 24 runs it locally without
complaint. Firebase CLI 15.

```sh
npm install
npm run build          # tsc -p tsconfig.build.json → lib/
npm run lint           # eslint (strictTypeChecked) + prettier --check
npm test               # vitest, pure functions only — needs nothing running
npm run test:rules     # firestore.rules, allowed and denied, around the emulator
npm run test:emulator  # the callables end to end, around the emulator
npm run test:all       # all three, in that order
npm run seed           # three signed-in users, against a running Auth emulator
npm run serve          # build, then the functions emulator alone
```

`firebase emulators:start --project nestprep-643b7` from the repo root runs Functions together
with Auth and Firestore. The project id is the real one (foundation ADR-0008); nothing reaches the
cloud because the client redirects every service.

## Shape

- `src/<feature>/` — one folder per feature (`ENG-04`); `src/index.ts` only re-exports and sets
  global options.
- A callable parses its input with a zod schema at the edge and never casts (`ENG-09`). Errors go
  through `household/errors.ts`: one `refuse('<reason>')` that puts the reason in the error's
  `details`, because three different refusals share the gRPC code `already-exists` and the client
  has to tell them apart to choose copy (`BE-04`).
- Anything touching more than one document is a transaction (`BE-06`).
- Secrets are Functions parameters or secret bindings, never `.env` in git (`ENG-18`). None exist yet.
- `tsconfig.json` covers `src/`, `test/` and the config files for the editor and ESLint;
  `tsconfig.build.json` is what `tsc` emits from, and it includes `src/` only.

## Things that bite on this codebase

- `lib/` is build output and gitignored; deploy runs `lint` and `build` first via `firebase.json`.
- **The Functions emulator runs `lib/`, not `src/`.** Editing TypeScript changes nothing in a
  running suite until `npm run build`. This bites hardest when mutation-testing: break a rule in
  `src/`, run the integration tests, watch them all pass, and conclude the tests are weak — when in
  fact the mutation never reached the emulator. Build, wait a few seconds for the reload, then run.
- Three vitest configs, three `include` globs. A test file in the wrong folder runs in the wrong
  suite: `test/unit/` needs nothing, `test/rules/` and `test/emulator/` need the emulator around
  them.
- `tools/` is plain Node, not part of the TypeScript program, so ESLint's type-aware rules are off
  for it — see `eslint.config.mjs`.
