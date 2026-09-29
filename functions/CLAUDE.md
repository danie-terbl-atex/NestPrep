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
npm run rules:build    # firestore.rules and storage.rules from ../rules/ partials (foundation ADR-0012, ADR-0013)
npm run rules:check    # exit 1 if either committed rules file is out of date
npm run test:rules     # builds the rules, then firestore.rules *and* storage.rules, allowed and denied
npm run test:emulator  # the callables end to end, around the emulator
npm run test:all       # all three, in that order
npm run seed           # three signed-in users, against a running Auth emulator
npm run serve          # build, then the functions emulator alone
npm run beta-numbers   # print the weekly beta numbers (after `npm run build`; `-- --recount` recounts first)
npm run grant-analytics-reader -- <email> [--revoke]   # who may open the Beta numbers screen
```

The two analytics tools (product-analytics ADR-0001) read `lib/`, so build first. Against the
real project they use Google application-default credentials (`gcloud auth
application-default login`); against the emulator set `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`
(and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099` for the grant). `NESTPREP_PROJECT` overrides the
project id; nothing else is configurable. They print counts and account uids only.

`firebase emulators:start --project nestprep-643b7` from the repo root runs Functions together
with Auth and Firestore. The project id is the real one (foundation ADR-0008); nothing reaches the
cloud because the client redirects every service.

## Shape

- `src/<feature>/` — one folder per feature (`ENG-04`); `src/index.ts` only re-exports and sets
  global options.
- `src/shared/admin_app.ts` is the one lazily-initialised admin app; `firestore.ts` and `auth.ts`
  are the two handles taken from it. `auth()` exists for two jobs: writing the `households` custom
  claim that Storage Security Rules read, because they cannot read Firestore (documents ADR-0001),
  and opening and closing kid devices — their users, their `kidProfile` claim and the custom token
  that signs them in (accounts ADR-0003). **`createCustomToken` on Cloud Functions needs the runtime
  service account to hold Service Account Token Creator on itself**; without it `redeemKidPairing`
  refuses with `signInUnavailable`. The emulator needs nothing.
- A callable parses its input with a zod schema at the edge and never casts (`ENG-09`). Errors go
  through `household/errors.ts`: one `refuse('<reason>')` that puts the reason in the error's
  `details`, because three different refusals share the gRPC code `already-exists` and the client
  has to tell them apart to choose copy (`BE-04`).
- Anything touching more than one document is a transaction (`BE-06`).
- `src/product_analytics/` holds the only non-callables: three Firestore triggers and one daily
  schedule. They take their region and limits from the same global options, and a Firestore
  trigger must run in the database's region or it never fires.
- Secrets are Functions parameters or secret bindings, never `.env` in git (`ENG-18`). Calendar sync
  (`src/calendar_sync/`, calendar ADR-0003 in the vault) is the first to have any; the names are
  below and the values live nowhere in the repo or the vault.
- Calendar sync talks to Google, Microsoft Graph and pasted ICS links only through
  `calendar_sync/http_client.ts` — a timeout, a size cap, no silent redirects — and every provider
  is an adapter tested against canned responses (`BE-09`). A pasted link is checked against
  private and loopback addresses on every hop (`link_guard.ts`); loopback is allowed only when
  `FUNCTIONS_EMULATOR` is `true`, which is how the emulator tests serve a calendar from this machine.
- `tsconfig.json` covers `src/`, `test/` and the config files for the editor and ESLint;
  `tsconfig.build.json` is what `tsc` emits from, and it includes `src/` only.

## Configuration (`BE-16`)

| Name                               | Kind                        | Used by                                                                      | Unset means                                                     |
| ---------------------------------- | --------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `CALENDAR_GOOGLE_CLIENT_ID`        | string param, default empty | calendar sync                                                                | Google Calendar says _not set up yet_                           |
| `CALENDAR_MICROSOFT_CLIENT_ID`     | string param, default empty | calendar sync                                                                | Outlook says _not set up yet_                                   |
| `CALENDAR_GOOGLE_CLIENT_SECRET`    | Secret Manager secret       | `calendarOAuthCallback`, `syncCalendarConnection`, `syncCalendarsOnSchedule` | must exist to deploy; the value `unset` reads as not configured |
| `CALENDAR_MICROSOFT_CLIENT_SECRET` | Secret Manager secret       | the same three                                                               | the same                                                        |
| `CALENDAR_FUNCTIONS_BASE_URL`      | string param, default empty | the OAuth redirect and the feed link                                         | derived: `https://africa-south1-<project>.cloudfunctions.net`   |

The OAuth redirect URI to register with Google and Microsoft is
`https://africa-south1-nestprep-643b7.cloudfunctions.net/calendarOAuthCallback` (or
`<CALENDAR_FUNCTIONS_BASE_URL>/calendarOAuthCallback`).

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
- **The emulator asks the real Secret Manager for a bound secret it has no local value for.** The
  calendar sync Functions bind two, so every emulator run logs _Unable to access secret
  environment variables from Google Cloud Secret Manager_ until the API is enabled. It is noise,
  not a failure: the value reads as empty and the provider as not set up, which is what the
  emulator tests assert.
  To silence it, put `CALENDAR_GOOGLE_CLIENT_SECRET=unset` and
  `CALENDAR_MICROSOFT_CLIENT_SECRET=unset` in `functions/.secret.local` (git-ignored).
- **`writes_are_atomic.test.ts` reads every `.set(`, `.update(`, `.delete(` in `src/` as a
  Firestore write.** A `Map`, a `Hash` or a `URLSearchParams` written that way fails it; calendar
  sync uses records, `crypto.hash()` and `new URLSearchParams({...})` for that reason.
