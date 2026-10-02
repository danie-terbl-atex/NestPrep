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
npm run seed           # three fixed-uid users and the demo household, against a running suite (build first)
npm run seed:cloud-demo      # the live demo family in the real project (build first; foundation ADR-0019)
npm run teardown:cloud-demo  # dry run; `-- --confirm` removes exactly what seed:cloud-demo made
npm run emulators      # build, start the suite importing/exporting ../emulator-data, then seed (foundation ADR-0018)
npm run emulators:lan  # the same on 0.0.0.0, through a generated ../firebase.lan.json
npm run serve          # build, then the functions emulator alone
npm run beta-numbers   # print the weekly beta numbers (after `npm run build`; `-- --recount` recounts first)
npm run grant-analytics-reader -- <email> [--revoke]   # who may open the Beta numbers screen
npm run deletion-requests [-- --erase <id> --confirm | --close <id>]   # the web page's deletion requests (after `npm run build`)
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
  `shared/http_client.ts` — a timeout, a size cap, no silent redirects — and every provider
  is an adapter tested against canned responses (`BE-09`). A pasted link is checked against
  private and loopback addresses on every hop (`link_guard.ts`); loopback is allowed only when
  `FUNCTIONS_EMULATOR` is `true`, which is how the emulator tests serve a calendar from this machine.
- `src/notifications/` is the one channel every reminder is delivered through (notifications
  ADR-0001 to ADR-0003 in the vault): `composeMorningDigests` (every 15 min) and
  `deliverNotifications` (every 5 min) are schedules whose bodies — `runMorningDigest`,
  `runNotificationDelivery` — the emulator suite drives with a fixed clock and a recording
  `PushSender`; `notifyShiftHandover`, `notifyChoreCheck` and `notifyRewardRequest` are triggers;
  `sendTestNotification` is the callable. **Only `fcm_push_sender.ts` knows FCM exists**, and it
  never throws: an outage is an outcome. Every producer goes through `deliverDrafts`, which writes
  one `notificationInbox` item per person and dispatches at most once. FCM needs no parameter here:
  Android works with the project's own credentials; iOS needs an APNs auth key uploaded in the
  Firebase console. In the emulator a send reaches for the real FCM with whatever
  application-default credentials the machine has — none means a logged, retried, then `failed`
  push, and the inbox still has it.
- `tsconfig.json` covers `src/`, `test/` and the config files for the editor and ESLint;
  `tsconfig.build.json` is what `tsc` emits from, and it includes `src/` only.

## Configuration (`BE-16`)

| Name                                                                            | Kind                                           | Used by                                                                      | Unset means                                                      |
| ------------------------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `CALENDAR_GOOGLE_CLIENT_ID`                                                     | string param, default empty                    | calendar sync                                                                | Google Calendar says _not set up yet_                            |
| `CALENDAR_MICROSOFT_CLIENT_ID`                                                  | string param, default empty                    | calendar sync                                                                | Outlook says _not set up yet_                                    |
| `CALENDAR_GOOGLE_CLIENT_SECRET`                                                 | Secret Manager secret                          | `calendarOAuthCallback`, `syncCalendarConnection`, `syncCalendarsOnSchedule` | must exist to deploy; the value `unset` reads as not configured  |
| `CALENDAR_MICROSOFT_CLIENT_SECRET`                                              | Secret Manager secret                          | the same three                                                               | the same                                                         |
| `CALENDAR_FUNCTIONS_BASE_URL`                                                   | string param, default empty                    | the OAuth redirect and the feed link                                         | derived: `https://africa-south1-<project>.cloudfunctions.net`    |
| `SUBSCRIPTIONS_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_YEARLY_PRODUCT_ID`           | string params, default empty                   | subscriptions                                                                | premium says _isn't available yet_                               |
| `SUBSCRIPTIONS_PRICING_TEST`                                                    | string param, default `off`                    | the paywall's offer                                                          | everybody in cohort `a` (yearly first); `on` splits by household |
| `SUBSCRIPTIONS_TEST_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_TEST_YEARLY_PRODUCT_ID` | string params, default empty                   | cohort `b` of the pricing test                                               | cohort `b` is offered cohort `a`'s products                      |
| `SUBSCRIPTIONS_ANDROID_PACKAGE`, `SUBSCRIPTIONS_IOS_BUNDLE_ID`                  | string params, default `io.nullstate.nestprep` | verification                                                                 | the app's own ids                                                |
| `SUBSCRIPTIONS_APPLE_APP_ID`                                                    | string param, default empty                    | App Store notifications                                                      | a production notification's app id is not checked                |
| `SUBSCRIPTIONS_APPLE_ISSUER_ID`, `SUBSCRIPTIONS_APPLE_KEY_ID`                   | string params, default empty                   | the App Store Server API                                                     | renewal status comes only from notifications                     |
| `SUBSCRIPTIONS_APPLE_PRIVATE_KEY`                                               | Secret Manager secret                          | `verifyPurchase`, `appStoreNotifications`, `reconcileSubscriptions`          | must exist to deploy; the value `unset` reads as not configured  |
| `AI_MODEL`                                                                      | string param                                   | every AI call (`src/ai/`)                                                    | `gemini-2.5-flash`                                               |
| `AI_LOCATION`                                                                   | string param                                   | every AI call — the Vertex region the request is processed in                | `europe-west4` (Gemini is not offered in `africa-south1`)        |
| `AI_IMAGE_MODEL`                                                                | string param                                   | `lunchPhoto` (`src/ai/imagen_model.ts`)                                      | `imagen-4.0-generate-001`                                        |
| `AI_IMAGE_LOCATION`                                                             | string param                                   | `lunchPhoto` — the Vertex region the picture is made in                      | `europe-west4`                                                   |
| `CHECKERS_API_KEY`, `CHECKERS_PROFILE_TOKEN`                                    | string params, default empty                   | Add to Checkers (`src/checkers/`)                                            | every Checkers callable refuses with `checkers-down`, logged     |
| `CHECKERS_APP_VERSION`, `CHECKERS_APP_VERSION_CODE`                             | string params, default empty                   | the same                                                                     | the same                                                         |
| `CHECKERS_SESSION_KEY`                                                          | Secret Manager secret (32 bytes, base64)       | `checkersRequestOtp`, `checkersVerifyOtp`, `checkersPushToCart`              | must exist to deploy; missing or malformed refuses loudly        |

Subscriptions (subscriptions ADR-0001 in the vault) reach Google Play as **the Functions runtime
service account**, through application-default credentials — there is no key file. It works once
that account is invited into the Play Console with _View financial data_ and _Manage orders and
subscriptions_; until then the Play API answers 401/403, `verifyPurchase` refuses with
`storeUnreachable`, and the phone keeps the purchase to verify again. Real-time Developer
Notifications arrive on the Pub/Sub topic `play-billing` (deploying `playBillingNotifications`
creates it). App Store Server Notifications v2 go to
`https://africa-south1-nestprep-643b7.cloudfunctions.net/appStoreNotifications`, for production and
sandbox alike. Apple's signed transactions are verified against Apple Root CA - G3, pinned in
`src/subscriptions/apple/apple_root_certificate.ts`; the test chain in `test/fixtures/apple/` is
made for the tests and trusted by nothing else.

Home care's translation (home-care ADR-0006 in the vault) reaches Google Cloud Translation v3 as
**the Functions runtime service account** too — no key, no parameter. It works once the Cloud
Translation API is enabled on the project and that account holds `roles/cloudtranslate.user`; until
then Google answers 403, `translateHomeCareTexts` refunds the month's characters and refuses with
`translationUnavailable`, and the helper reads English with the reason. Under the emulator the
`EmulatorTranslator` answers `[zu] …` and nothing reaches Google.

Add to Checkers (`src/checkers/`, the Checkers build contract in the vault) links a member's own
Checkers Sixty60 account by SMS code and fills **their** cart — cart only, never a slot, checkout or
payment. The four string params are the Sixty60 Android app's public client identity (the same in
every install); their values live only in the git-ignored `.env.nestprep-643b7`, never here or in
the vault. The session is an hour with no refresh; it and the three Checkers identifiers are sealed
with AES-256-GCM under `CHECKERS_SESSION_KEY` in `checkersLinks/{uid}`, which no client may read. Only
`http_checkers_login.ts` and `http_checkers_shop.ts` talk to Checkers, through `shared/http_client.ts`;
under the emulator `EmulatorCheckers` answers instead (code `123456`, no SMS, no real cart). Behind
the `addToCheckers` flag, except link status and unlink. Codes are limited to three per account and
three per number per fifteen minutes (`rateLimits`). Weighed (`KG`) products are skipped, not
guessed at. Rotating the key signs every member out of Checkers (their links stop opening).

The OAuth redirect URI to register with Google and Microsoft is
`https://africa-south1-nestprep-643b7.cloudfunctions.net/calendarOAuthCallback` (or
`<CALENDAR_FUNCTIONS_BASE_URL>/calendarOAuthCallback`).

## Account data, rate limits and App Check (accounts ADR-0006)

- `src/account_data/` is Delete my account, Download my data and the public deletion-request
  endpoint. Erasing reads the plan again on the server and refuses if the households it would end
  differ from the ones the person agreed to; the order is households → records outside them →
  `users/{uid}` → the Auth user last, and every step is safe to re-run. **A new collection that
  holds a person's data belongs in its inventory**: `personal_refs.ts` for a document keyed by the
  member id, `authored_records.ts` for a record stamped with its author —
  `test/unit/account_data_exports.test.ts` fails when a rules partial stamps authorship on a
  collection the export does not list.
- An export is written to Storage at `accountExports/{uid}/…`, readable by that account for one
  hour (`rules/storage/paths/account_exports.rules`) and swept hourly. It is the Functions' first
  server-side Storage use (`shared/storage.ts`); in the emulator the runtime is given no bucket, so
  it falls back to `<project>.firebasestorage.app`, and `npm run test:emulator` now starts Storage.
- Web deletion requests land in `accountDeletionRequests` and are dealt with by
  `tools/deletion-requests.mjs` after the address is confirmed by email.
- `shared/rate_limit.ts` counts attempts in `rateLimits/{hash}` — `redeemKidPairing` and the web
  request per address and overall, exports per account. Each document carries `expiresAt`; a
  Firestore **TTL policy on `rateLimits.expiresAt`** removes them (console, once — an outside ask).
- `shared/app_check.ts`: `APP_CHECK_ENFORCED` is `false`. Flipping it to `true` and deploying makes
  every callable refuse a request without a valid App Check token — only after the console's App
  Check metrics show nearly all requests verified (foundation's App Check ADR).

Runtime switches that are **documents, not parameters**, so they bite on the next call with no
deploy (foundation ADR-0014, ADR-0015), both set by hand in the console and unreadable by clients:

- `appConfig/flags` — one boolean per V2 capability (`snapSchoolLetter`, …). Absent means on under
  the emulator and **off in the cloud**.
- `appConfig/ai` — `enabled`, `features.schoolLetter`, `features.planMyWeek`, `features.lunchPhoto`,
  `monthlyCalls.free` and `monthlyCalls.premium`. Absent means on, 10 calls a month free and 100
  premium. `enabled: false` (or any `enabled` that is not a boolean) stops every AI call before it
  costs anything.

## AI (`src/ai/`, foundation ADR-0015)

Every model call goes through `runAiCall` — never Vertex directly. It checks the kill switch, claims
one of the household's monthly calls in a transaction (`households/{h}/aiUsage/{YYYY-MM}`, a line
per call under `calls/`), asks the model with timeouts and retries, parses the JSON answer with zod,
and refunds the call if it failed. A feature supplies only a `ModelRequest` (system text, parts,
a `responseSchema`, a `feature` label) and a zod schema, and sends the model the minimum (the ADR's
POPIA section). Vertex is reached as the Functions' service account — **no API key exists**; the
runtime service account needs `roles/aiplatform.user`. Under the emulator the model is
`EmulatorModel`, which answers from `aiEmulator/{feature}.reply` (or fails with `failWith`), so no
test or local run reaches Vertex or bills anything.

A picture goes through `runImageCall` — the same switch, claim and refund, with an `ImageModel`
(Imagen in the cloud; under the emulator `EmulatorImageModel`, which returns
`assets/emulator_lunch_photo.jpg` unless `aiEmulator/{feature}.failWith` says otherwise).
`lunchPhoto` (lunch-box ADR-0015) caches each box's picture by combination: catalogue-only boxes at
`lunchPhotos/{key}` (shared by every household), anything else at `households/{h}/lunchPhotos/{key}`
— a Firestore document no client reads, and a `.jpg` of the same name in Storage.

## Things that bite on this codebase

- `lib/` is build output and gitignored; deploy runs `lint` and `build` first via `firebase.json`.
- **The Functions emulator runs `lib/`, not `src/`.** Editing TypeScript changes nothing in a
  running suite until `npm run build`. This bites hardest when mutation-testing: break a rule in
  `src/`, run the integration tests, watch them all pass, and conclude the tests are weak — when in
  fact the mutation never reached the emulator. Build, wait a few seconds for the reload, then run.
- Three vitest configs, three `include` globs. A test file in the wrong folder runs in the wrong
  suite: `test/unit/` needs nothing, `test/rules/` and `test/emulator/` need the emulator around
  them.
- **The seed reads `lib/`** (`tools/demo-household.mjs` takes grants, claims, the entitlement and the
  flag list from the Functions' own code), so it writes the shapes the callables write. Change a
  household-level shape in `src/` and the seed follows on the next build — no second copy.
- **The cloud demo seed** (`tools/seed-cloud-demo.mjs`, one module per area in `tools/cloud-demo/`)
  writes five `demo-` accounts and the household `demo-oak-street` into the real project, through
  the same `lib/` code, around the current week; its password comes only from the gitignored
  `app/demo_logins.json`. It needs application-default credentials **with a quota project**
  (`GOOGLE_CLOUD_QUOTA_PROJECT=nestprep-643b7`), or Identity Toolkit refuses. A reseed never sets an
  existing account's password (that signs every phone out) unless passed `-- --reset-password`.
  It refuses an address another uid holds and any id not starting `demo-`. A new feature's demo
  documents go in `tools/cloud-demo/` (foundation ADR-0019).
- `tools/` is plain Node, not part of the TypeScript program, so ESLint's type-aware rules are off
  for it — see `eslint.config.mjs`.
- **The emulator asks the real Secret Manager for a bound secret it has no local value for.** The
  calendar sync Functions bind two, so every emulator run logs _Unable to access secret
  environment variables from Google Cloud Secret Manager_ until the API is enabled. It is noise,
  not a failure: the value reads as empty and the provider as not set up, which is what the
  emulator tests assert.
  To silence it, put `CALENDAR_GOOGLE_CLIENT_SECRET=unset`,
  `CALENDAR_MICROSOFT_CLIENT_SECRET=unset`, `SUBSCRIPTIONS_APPLE_PRIVATE_KEY=unset` and
  `CHECKERS_SESSION_KEY=unset` (the emulator then seals with a fixed local key) in
  `functions/.secret.local` (git-ignored).
- **Two emulator suites on one machine share project id `nestprep-643b7`.** The rules and emulator
  harnesses read `FIRESTORE_EMULATOR_HOST`, `FIREBASE_STORAGE_EMULATOR_HOST` and
  `FUNCTIONS_EMULATOR_HOST`; `emulators:exec` sets the first two but **not** the Functions one, so a
  test run on other ports beside a running dev suite calls the dev suite's Functions on 5001 and
  writes into its data. Pass `FUNCTIONS_EMULATOR_HOST=127.0.0.1:<port>` in the exec'd command.
- **Vertex refused a `responseSchema` carrying `maxItems`** (400, _invalid argument_, 2026-09-29).
  Bound lists where the answer is parsed instead.
- **`writes_are_atomic.test.ts` reads every `.set(`, `.update(`, `.delete(` in `src/` as a
  Firestore write.** A `Map`, a `Hash` or a `URLSearchParams` written that way fails it; calendar
  sync uses records, `crypto.hash()` and `new URLSearchParams({...})` for that reason.
