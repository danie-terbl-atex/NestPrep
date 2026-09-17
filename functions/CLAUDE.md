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
npm test               # vitest, pure functions only
npm run serve          # build, then the functions emulator alone
```

`firebase emulators:start --project demo-nestprep` from the repo root runs Functions together with
Auth and Firestore.

## Shape

- `src/<feature>/` — one folder per feature (`ENG-04`); `src/index.ts` only re-exports and sets
  global options.
- A callable parses its input at the edge and never casts (`ENG-09`); errors are `HttpsError` with
  a code and a user-facing message, and the client maps codes to copy (`BE-04`).
- Anything touching more than one document is a transaction (`BE-06`).
- Secrets are Functions parameters or secret bindings, never `.env` in git (`ENG-18`). None exist yet.
- `tsconfig.json` covers `src/`, `test/` and the config files for the editor and ESLint;
  `tsconfig.build.json` is what `tsc` emits from, and it includes `src/` only.

## Things that bite on this codebase

- `lib/` is build output and gitignored; deploy runs `lint` and `build` first via `firebase.json`.
- `ping` is the foundation smoke test and goes with the diagnostics feature in accounts phase 1.
