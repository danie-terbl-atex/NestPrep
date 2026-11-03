# functions — NullState app `nestprep` (Cloud Functions)

Cloud Functions for the NullState app **nestprep**: TypeScript, 2nd generation, holding only what
Firestore Security Rules cannot express (foundation ADR-0002 in Godfather; this repo is the
`nestprep` software node). Before any task call `route`; after any change update Godfather in the
same change. The root `CLAUDE.md` one level up has the full contract.

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
npm run seed:catalogue       # dry run; `-- --confirm` publishes recipes and starter boxes to the real project (build first)
npm run seed:premium-codes -- --shared THANDI30 --label "…" --days 30   # or --unique <n> --out <file.csv>; emulator unless --project nestprep-643b7 --yes (build first)
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
  (`src/calendar_sync/`, calendar ADR-0003 in Godfather) is the first to have any; the names are
  below and the values live nowhere in the repo or Godfather memory.
- Calendar sync talks to Google, Microsoft Graph and pasted ICS links only through
  `shared/http_client.ts` — a timeout, a size cap, no silent redirects — and every provider
  is an adapter tested against canned responses (`BE-09`). A pasted link is checked against
  private and loopback addresses on every hop (`link_guard.ts`); loopback is allowed only when
  `FUNCTIONS_EMULATOR` is `true`, which is how the emulator tests serve a calendar from this machine.
- `src/notifications/` is the one channel every reminder is delivered through (notifications
  ADR-0001 to ADR-0003 in Godfather): `composeMorningDigests` (every 15 min) and
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

| Name                                                                            | Kind                                              | Used by                                                                                | Unset means                                                                                                          |
| ------------------------------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `CALENDAR_GOOGLE_CLIENT_ID`                                                     | string param, default empty                       | calendar sync                                                                          | Google Calendar says _not set up yet_                                                                                |
| `CALENDAR_MICROSOFT_CLIENT_ID`                                                  | string param, default empty                       | calendar sync                                                                          | Outlook says _not set up yet_                                                                                        |
| `CALENDAR_GOOGLE_CLIENT_SECRET`                                                 | Secret Manager secret                             | `calendarOAuthCallback`, `syncCalendarConnection`, `syncCalendarsOnSchedule`           | must exist to deploy; the value `unset` reads as not configured                                                      |
| `CALENDAR_MICROSOFT_CLIENT_SECRET`                                              | Secret Manager secret                             | the same three                                                                         | the same                                                                                                             |
| `CALENDAR_FUNCTIONS_BASE_URL`                                                   | string param, default empty                       | the OAuth redirect and the feed link                                                   | derived: `https://africa-south1-<project>.cloudfunctions.net`                                                        |
| `SUBSCRIPTIONS_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_YEARLY_PRODUCT_ID`           | string params, default empty                      | subscriptions                                                                          | premium says _isn't available yet_                                                                                   |
| `SUBSCRIPTIONS_PRICING_TEST`                                                    | string param, default `off`                       | the paywall's offer                                                                    | everybody in cohort `a` (yearly first); `on` splits by household                                                     |
| `SUBSCRIPTIONS_TEST_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_TEST_YEARLY_PRODUCT_ID` | string params, default empty                      | cohort `b` of the pricing test                                                         | cohort `b` is offered cohort `a`'s products                                                                          |
| `SUBSCRIPTIONS_ANDROID_PACKAGE`, `SUBSCRIPTIONS_IOS_BUNDLE_ID`                  | string params, default `io.nullstate.nestprep`    | verification                                                                           | the app's own ids                                                                                                    |
| `SUBSCRIPTIONS_APPLE_APP_ID`                                                    | string param, default empty                       | App Store notifications                                                                | a production notification's app id is not checked                                                                    |
| `SUBSCRIPTIONS_APPLE_ISSUER_ID`, `SUBSCRIPTIONS_APPLE_KEY_ID`                   | string params, default empty                      | the App Store Server API                                                               | renewal status comes only from notifications                                                                         |
| `SUBSCRIPTIONS_APPLE_PRIVATE_KEY`                                               | Secret Manager secret                             | `verifyPurchase`, `appStoreNotifications`, `reconcileSubscriptions`                    | must exist to deploy; the value `unset` reads as not configured                                                      |
| `AI_MODEL`                                                                      | string param                                      | every AI call (`src/ai/`)                                                              | `gemini-2.5-flash`                                                                                                   |
| `AI_LOCATION`                                                                   | string param                                      | every AI call — the Vertex region the request is processed in                          | `europe-west4` (Gemini is not offered in `africa-south1`)                                                            |
| `AI_IMAGE_MODEL`                                                                | string param                                      | `lunchPhoto` (`src/ai/gemini_image_model.ts`)                                          | `gemini-3.1-flash-image`                                                                                             |
| `AI_IMAGE_LOCATION`                                                             | string param                                      | `lunchPhoto` — the Vertex region the picture is made in                                | `global` (the image model is served nowhere else)                                                                    |
| `AI_DECISION_MODEL`                                                             | string param                                      | every decision (`src/ai/run_decision_call.ts`)                                         | `jev-latest`                                                                                                         |
| `TYPESAFE_API_KEY`                                                              | Secret Manager secret                             | `buildLunchWeek`, `rankProductMatches` (Jev, foundation ADR-0022)                      | must exist to deploy; missing refuses with `aiUnavailable`, logged                                                   |
| `CHECKERS_API_KEY`, `CHECKERS_PROFILE_TOKEN`                                    | string params, default empty                      | Add to Checkers (`src/checkers/`)                                                      | every Checkers callable refuses with `checkers-down`, logged                                                         |
| `CHECKERS_APP_VERSION`, `CHECKERS_APP_VERSION_CODE`                             | string params, default empty                      | the same                                                                               | the same                                                                                                             |
| `CHECKERS_SESSION_KEY`                                                          | Secret Manager secret (32 bytes, base64)          | `checkersRequestOtp`, `checkersVerifyOtp`, `checkersPushToCart`                        | must exist to deploy; missing or malformed refuses loudly                                                            |
| `PNP_SESSION_KEY`                                                               | Secret Manager secret (32 bytes, base64)          | `pnpStartLink`, `pnpCompleteLink`, `pnpPushToCart`                                     | must exist to deploy; missing or malformed refuses `pnp-down`, logged                                                |
| `ASSISTANTS_ORIGIN`                                                             | string param                                      | `assistantAuth`, `assistantMcp` (issuer; resource is `<origin>/mcp`)                   | `https://nestprep-643b7.web.app`                                                                                     |
| `ASSISTANTS_ALLOW_LOOPBACK`                                                     | string param, default `false`                     | `assistantAuth` — `http://localhost:*/callback` redirects (Claude Code)                | only Claude's and ChatGPT's own callbacks are accepted                                                               |
| `ASSISTANTS_TOKEN_KEY`                                                          | Secret Manager secret (32 bytes, base64)          | `assistantAuth` — seals a refresh's pair for its one-minute retry window               | must exist to deploy; missing or malformed fails refreshes, logged                                                   |
| `PREMIUM_EMAIL_PEPPER`                                                          | Secret Manager secret (long random string)        | every Premium voucher Function and `seed:premium-codes`                                | must exist to deploy; missing refuses loudly (the emulator uses a fixed pepper); **never rotated without a re-hash** |
| `RESEND_API_KEY`                                                                | Secret Manager secret                             | `sendVoucherEmailCode`                                                                 | must exist to deploy; `unset` makes every send fail `unavailable`, logged                                            |
| `PREMIUM_EMAIL_FROM`                                                            | string param, default empty                       | `sendVoucherEmailCode` — the Resend sender, e.g. `NestPrep <hello@…>`                  | every send fails `unavailable`, logged                                                                               |
| `STORE_INVOKER_SERVICE_ACCOUNT`                                                 | string param, default empty                       | `issuePremiumVouchers`, `voidFrameVoucher` — the store's runtime service account email | every store call is refused 403, logged                                                                              |
| `PREMIUM_TESTER_UIDS`                                                           | string param, comma-separated uids, default empty | test-order vouchers                                                                    | nobody may see or claim a test voucher                                                                               |

Subscriptions (subscriptions ADR-0001 in Godfather) reach Google Play as **the Functions runtime
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

Home care's translation (home-care ADR-0006 in Godfather) reaches Google Cloud Translation v3 as
**the Functions runtime service account** too — no key, no parameter. It works once the Cloud
Translation API is enabled on the project and that account holds `roles/cloudtranslate.user`; until
then Google answers 403, `translateHomeCareTexts` refunds the month's characters and refuses with
`translationUnavailable`, and the helper reads English with the reason. Under the emulator the
`EmulatorTranslator` answers `[zu] …` and nothing reaches Google.

Add to Checkers (`src/checkers/`, the Checkers build contract in Godfather) links a member's own
Checkers Sixty60 account by SMS code and fills **their** cart — cart only, never a slot, checkout or
payment. The four string params are the Sixty60 Android app's public client identity (the same in
every install); their values live only in the git-ignored `.env.nestprep-643b7`, never here or in
Godfather memory. The session is an hour with no refresh; it and the three Checkers identifiers are sealed
with AES-256-GCM under `CHECKERS_SESSION_KEY` in `checkersLinks/{uid}`, which no client may read. Only
`http_checkers_login.ts` and `http_checkers_shop.ts` talk to Checkers, through `shared/http_client.ts`;
under the emulator `EmulatorCheckers` answers instead (code `123456`, no SMS, no real cart). Behind
the `addToCheckers` flag, except link status and unlink. Codes are limited to three per account and
three per number per fifteen minutes (`rateLimits`). Weighed (`KG`) products are skipped, not
guessed at. Rotating the key signs every member out of Checkers (their links stop opening).

Add to Pick n Pay (`src/pnp/`, add-to-pnp ADR-0001 to ADR-0005 in Godfather) links a member's own
pnp.co.za account and fills **their** cart from the lunch box's _Plan my week_ — cart only, never a
slot, fulfilment option, checkout or payment. The member signs in on PnP's own page in the app's web
view; the app relays only the code and the `state`. `pnpStartLink` keeps the PKCE verifier, state and
nonce sealed for 15 minutes; `pnpCompleteLink` swaps the code for tokens and seals the access and
refresh tokens under `PNP_SESSION_KEY` in `pnpLinks/{uid}`, which no client may read. **PnP's OIDC
client id and secret are not configuration**: they are read at runtime from PnP's own
`/pnphybris/v2/pnp-spa/config` (served to every browser), remembered an hour per instance, never
logged. Only `http_pnp_login.ts` and `http_pnp_shop.ts` talk to PnP, through `shared/http_client.ts`;
under the emulator `EmulatorPnp` answers instead (code `emulator-code`, nothing reaches PnP). A push
raises each product's line to at least the asked packs by entry guid (PnP's add increments), within
the cart's item cap and each product's order limit; weighed (`_KGM`, average-weight) products are
skipped, and a line PnP takes short (`noStock`, `lowStock`, `maxOrderQuantityExceeded`) or refuses with
a 4xx is that item's skip, never the whole push's. A cart with no store refuses
`pnp-no-delivery-address`. **A token refresh saves only by compare-and-swap** on the sealed session it
refreshed from, so an unlink or an erasure that lands mid-push stays done, and a rival refresh's rotated
token is adopted, never lost. Sealed values carry their purpose in the AAD (`pnp:pending:<uid>`,
`pnp:session:<uid>`); Checkers keeps its plain-uid AAD. Behind the `addToPnp`
flag, except link status and unlink. Rotating the key signs every member out of PnP. Shared with
Checkers: `shared/session_crypto.ts`, `shared/sealed_json.ts` and `src/cart_push/` (reading the list,
the push's answer shape).

Assistants (`src/assistants/`, assistants ADR-0001 to ADR-0005 in Godfather) are NestPrep in Claude
and ChatGPT. `assistantAuth` is NestPrep's own OAuth 2.1 authorization server (europe-west1, behind
Hosting's `/oauth/**` and `/.well-known/oauth-*` rewrites): client metadata documents fetched through
an address check made at the socket (`auth/client_document_fetch.ts`), dynamic registration, PKCE S256
only, codes and opaque `npa_`/`npr_` tokens stored only as SHA-256 in deny-all root collections. Consent
writes only the code; **the grant is written when the code is redeemed**, so an abandoned sign-in leaves
no connection, and a redeemed code presented again ends that grant. A rotation seals the pair it issued
onto the spent refresh token under `ASSISTANTS_TOKEN_KEY` for 60 s: a retry in that minute gets the
same pair back, never a second chain; later, or once that pair has been rotated, it ends the grant.
Authorize and consent are counted per address — the hop left of the right-most `X-Forwarded-For`
one, because Hosting sends `client, proxy` from a rotating pool of Google proxies (measured
2026-10-29), and `req.ip` is the caller-written left-most hop under `trust proxy` — under overall
ceilings; the token endpoint per client and grant. The grant is
`households/{h}/assistantConnections/{grantId}`; deleting it disconnects. `assistantMcp`
(`mcp/assistant_mcp.ts`, behind `/mcp`) is `mcpHandler(authenticateBearer)` on the official
`@modelcontextprotocol/server` SDK: stateless Streamable HTTP, JSON answers only. `pruneAssistantConnections`
disconnects a member who leaves or stops being family; erasure, `endHousehold` and the export know the
collections. `test/emulator/assistants_end_to_end.test.ts` is the whole of Claude's flow — discovery,
consent, tokens, tools, refresh, the app's disconnect — through `firebase.json`'s rewrites, with the
official MCP client (`@modelcontextprotocol/client`, a devDependency).
Under the emulator a client document may be served from this machine over plain http only while
`assistantsEmulator/cimd.allowLoopback` is `true` (the emulator suite sets it) — a param cannot be set
by a committed test, because the emulator reads params only from git-ignored `.env` files.

Premium vouchers and codes (`src/premium_vouchers/`, subscriptions ADR-0003, ADR-0004, contract
C-0026) turn a frame bought on the store, or a Premium code typed on the web, into a `premiumGrants`
document of source `frame` or `code`, composed like a referral month. Emails, codes and one-time codes
are kept only as HMAC-SHA256 under `PREMIUM_EMAIL_PEPPER`; gift-link tokens only as SHA-256.
`issuePremiumVouchers` and `voidFrameVoucher` (africa-south1) are `invoker: 'private'`: Cloud Run IAM
decides who reaches them, and the handler also checks the bearer ID token's `email` against
`STORE_INVOKER_SERVICE_ACCOUNT`, audience the function's cloudfunctions.net URL. **The store's service
account needs `roles/run.invoker` on both services, granted by hand** — `firebase deploy` never touches
the invoker of a private function. Under the emulator no Google ID token exists, so both refuse 403; the
emulator tests drive their bodies directly. `premiumWeb` (europe-west1, behind Hosting's `/api/premium/**`)
is the public gift and redeem pages' endpoint: per address (`callerAddress`) first, then per email hash,
and only an accepted request counts against the overall budget; gift lookups have ceilings of their own.
A redeem answers `redeemed` for a first and a repeat redemption alike, and counts the email only on a
refusal. A gift link moves its voucher at most five times (`voucherReassignLimit`). A code-email
challenge is stored only after Resend accepted the email, under a daily cap per account and five sends
and ten tries an hour per address. Under the emulator `sendVoucherEmailCode` sends nothing and the code is always `123456`.
`seed:premium-codes` writes codes straight to Firestore; a unique batch's plain codes go only to the
CSV named by `--out` (mode 600, never overwritten); the real project needs the pepper in the
environment as `PREMIUM_EMAIL_PEPPER`.

**Deploy it in two steps**, because a Function built before `GRANT_SOURCES` gained `frame` and `code`
cannot read those grants and drops them from any restatement it makes:

1. `firebase deploy --only firestore:rules,firestore:indexes,functions --project nestprep-643b7` with
   `STORE_INVOKER_SERVICE_ACCOUNT` still empty in `.env.nestprep-643b7`, no IAM grant and no codes
   seeded. Every Function, the reconcile and the store notifications included, now reads every grant
   source. The new endpoints are deployed but inert: the store is refused 403, so no frame voucher can
   exist, and with no `premiumCodes` the redeem page creates none, so nothing can be claimed.
2. Only once step 1 is serving everywhere (`gcloud run revisions list --region africa-south1` shows
   no older revision taking traffic): set `STORE_INVOKER_SERVICE_ACCOUNT`, run
   `firebase deploy --only functions:issuePremiumVouchers,functions:voidFrameVoucher`, grant the store
   `roles/run.invoker` on `issuepremiumvouchers` and `voidframevoucher`, seed codes, deploy Hosting, then
   switch on the store's push.

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
  `features.productMatch` (Jev's grocery ranking, never counted),
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

**A decision goes to Jev, not Gemini** (foundation ADR-0022 in Godfather): choosing or scoring
among options NestPrep already holds. A feature builds a `DecisionRequest` (`label`, `state`,
`questions` of `noul`/`choice`) and calls `runDecisionCall` (charged like `runAiCall`) or
`askDecisions` (switched, uncharged), with `deps = await decisionRuntime(db())`; it reads answers
with `noulOf`/`choiceOf` and decides in its own code. Jev is TypeSafe `systemOne`, keyed by the
`TYPESAFE_API_KEY` secret — the same TypeSafe account as the 28 Days app (integration-map C-021);
a callable that asks Jev declares `secrets: DECISION_SECRETS`. It never receives a person, a name,
an allergy or a household id. Under the emulator `EmulatorDecisionModel` answers from
`aiEmulator/{label}.answers` and otherwise says a sure yes or the first choice. `functions/.env.nestprep-643b7`
must name `AI_DECISION_MODEL`, or a non-interactive deploy stops asking for it.

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
- **The catalogue** — `recipes/` and `lunchStarterBoxes/` (recipes ADR-0001, ADR-0003, lunch-box
  ADR-0018) — has one source: the lunch box's recipes and the starter boxes in `src/recipes/` and
  `src/lunch_starter_boxes/`, and the meal recipes as one JSON file each in the repo's
  `../catalogue/recipes/<id>.json` with their photos in `../catalogue/recipe-photos/<id>/{hero,card}.jpg`
  (outside `functions/`, so a deploy carries neither; the authoring guide is in Godfather). Published by
  `src/catalogue/publish_catalogue.ts`: photos first, to Storage at
  `recipes/<id>/<size>-<8 hex of SHA-256>.jpg`, skipped when already there; then fixed ids, `version`
  raised only when content changes, an entry removed from source retired, never deleted. A file
  that does not parse, is not named after its id, or misses a photo stops the seed. The emulator seed publishes it on every start;
  the cloud gets it from `seed:catalogue -- --confirm` after a change, never from
  `seed:cloud-demo`. A starter box copies names and allergen codes from its recipes and from
  `SEED_FOODS`, which `seed_foods.test.ts` holds to the app's `LunchSeedCatalogue`. Without
  application-default credentials, `GOOGLE_APPLICATION_CREDENTIALS` may point at gcloud's own
  `~/.config/gcloud/legacy_credentials/<account>/adc.json` for the run.
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
  `CHECKERS_SESSION_KEY=unset`, `PNP_SESSION_KEY=unset` and `ASSISTANTS_TOKEN_KEY=unset` (the emulator then seals with a fixed local key) in
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
