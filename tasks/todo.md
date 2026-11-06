# People — household and family profiles on one screen (design-system ADR, proposed)

Daniel 2026-11-06: family profiles and household should merge into the same screen, maybe split by tab.

Contradicts design-system ADR-0005 §3 (Family profiles is its own tile on More) and §5 / household
overview constraint ("the people screen holds people only"). Superseded by a new design-system ADR,
not silently. In v1 (both V1 core). App only: no rules, Functions, contracts or area keys change.

## Shape
- One **People** screen, a `NestSegmentedControl` under the title: *Household* | *Profiles*.
  Route-owned like Meals: `/household` is the Household tab, `/family` the Profiles tab; switching
  `go`es (replaces), so back leaves for More.
- The control shows only when `FamilyAccess.isVisible`; without the grant it is the people screen as
  today. A deep link to `/family` stays gated by the redirect.
- The household route moves into family's ShellRoute so both tabs share the one lazy
  `FamilyController` (created only when Profiles is first read, kept across switches).
- More: the Family profiles tile goes; the People card is the one way in. The welcome tour's
  `moreFamily` stop folds into `morePeople`.
- Lunch, Today and the share screen still push `/family`, and land on Profiles.

## Checklist
- [x] ADR (proposed): design-system ADR-0022; household, family-profiles and design-system overviews
- [x] `PeopleView` + `PeopleViewSwitch`; HouseholdScreen and FamilyScreen use it (title *People*)
- [x] Route: kept as two routes; the switch `replace`s, so no shell move was needed
- [x] More: tile dropped; tour `moreFamily` stop gone, People stop's admin text names Profiles
- [x] Tests: real-router tab test, family navigation (4), family screen, More, household, tour plan
- [x] analyze --fatal-infos + format on changed files only; people/family design-review pictures retaken
- [ ] Drive it on a device
- [x] Godfather lint (no new errors), session log

## Review
- Tab tests fail when the switch uses `go` (back loses More) and pass with `replace`: mutation-checked.
- Still failing, from other sessions' in-flight work and not this change: app_router groceries/meals/recipe pick
  (meals/recipes WIP), app_version, declared_packages, errors_are_never_swallowed, feature_flags (documents flags),
  one_home_for_copy (`HomeCareRoutineCopy.itemForReader`).
- Lint's one error is meal-planning's dangling `lunch-box:ADR-0035`, from another session.

# Password reset — branded email through Resend (accounts ADR-0012)

Daniel 2026-11-06: the reset flow is either not working or not hooked up; any email that goes out should be properly formatted, ideally Resend HTML.

Finding: it was hooked up, to Firebase's stock sender (`method: DEFAULT`, from `noreply@nestprep-643b7.firebaseapp.com`, raw-link template, bare handler on firebaseapp.com), which lands in spam or never arrives.

## Checklist
- [x] Resend sender moved to `functions/src/shared/email_sender.ts`, gains `html`; premium vouchers re-pointed
- [x] `sendPasswordReset` callable: zod body, limits per caller / email / overall, Admin SDK link, `sent` for unknown addresses, branded HTML + text email
- [x] `app.nestprep.io/reset-password` page + script + CSP header block; site rebuilt
- [x] App gateway calls the callable; `invalidEmail` / `resetUnavailable` problems + copy; success copy names admin@nestprep.io
- [x] `ACCOUNT_EMAIL_FROM` in `.env.nestprep-643b7` / `.env.local` and the functions CLAUDE.md table
- [x] Tests: unit 2510 green; emulator `password_reset.test.ts` 4/4 (isolated ports, no Storage); app accounts + failure copy 215 green; analyze clean on changed files
- [x] Godfather: ADR-0012 (proposed), accounts overview rev 8, lint 0 errors
- [ ] Deploy `functions:sendPasswordReset` + Hosting (Daniel's go) and one real reset seen in Gmail
- [ ] Drive it in the emulator app end to end

## Review
- Not verified: a real email in an inbox (needs deploy); the emulator app by hand.
- `premium_vouchers` emulator test: 23 failures on my isolated-port suite (`notYourVoucher`, premium web 404). The only change there is an import path, so this looks like the isolated setup or other in-flight work. Re-run `npm run test:emulator` once Daniel's suite is stopped.
- `test/app` and `errors_are_never_swallowed_test` failures come from other sessions' in-flight files (HomeCare provider, recipes, notification host), not from this change.

# Lunch board — one "Plan the week" button (lunch-box ADR-0022/ADR-0024 amended)

Daniel 2026-11-05: two ways to plan the week stacked in one card is confusing. One button, *Plan the week*, opens a chooser: *Let Twig plan it* at the shop (first when Premium, second when free, Premium-tagged), *Pick the boxes yourself* (Fill the week), and *Fill from the pantry* while the pantry switch is on.

## Checklist
- [x] `LunchPlanWay` model: which ways, in which order (premium Twig first; free Twig second; full week offers only Twig)
- [x] `PlanWeekEntry.shopFor/open` + `PlanWeekEntryCard` becomes the sheet's Twig option (logo, Premium tag)
- [x] `showLunchPlanWeekSheet`: titled with the week's name; one way skips the sheet
- [x] `LunchWeekPlanner`: title, one button, one caption, pantry switch (its fill button moves to the sheet), budget strip
- [x] Copy + tour (lunchPlanMyWeek anchors the button)
- [x] Tests: planner, entry card, fill-week way in, free tier, board-by-scope, tour; analyze; format changed files only
- [x] Godfather: ADR (proposed), overview, session log, lint

## Review
- Built: one *Plan the week* button; sheet *How should we plan this week?* with Twig (tinted, shop logo; first for Premium, second + Premium tag for free), *Pick the boxes yourself*, *Fill from the pantry* (switch on). One way skips the sheet. Card title dropped (section header names the week).
- Verified: analyze clean; lunch_box/plan_week/welcome_tour 670 pass, 1 fail (`lunch_pantry_screen_test` grocery add — not this change). Pictures: `app/design-review/plan-week-entry-*`, `plan-week-chooser-*`.
- Not done: device run; commit (shared tree, Daniel's call).

# Woolworths everywhere — every shop equal, like-for-like (add-to-woolworths phase 2)

Daniel 2026-11-05: Woolworths in the lunch builder and everywhere else Checkers and Pick n Pay are; people choose which shop they use. Discovery: three agents (lunch builder map, every shop surface, Woolworths lunchbox shelves — scratchpad `woolies-lunch/`).

## Decisions taken (mine, from the discovery)
- Plan my week is N-shop: no `isPnpOn`; the shops on offer are `planWeekShops` ∩ the switched-on shops, Checkers included (it follows `addToCheckers` like the others).
- Every shop gets the done-step and brief cart (`ShopCarts`, one shop-generic push shared with recipes). Checkers' push learns pack quantities (it was 1 per item, which is why ADR-0026 §6 left it out): add only what each product is short of, never lower — the same rule as PnP and Woolworths.
- Woolworths' default lunchbox shelves: 10 verified groups from its Kids School Lunches / Kids Snacks sections (no weighed top sellers), overridable as `appConfig/lunchAisle.woolworthsShelves`.
- Photo frames take Woolworths: the phone resolves the store and price zone (Cloudflare keeps `/server/*` off Functions) and saves them with the frame; the Function searches Constructor with them. Frame client (NestPrep-Home) learns the shop's name and logo.
- A shop whose switch is off is hidden, never "coming soon".
- *Your shops* in the account centre: each shop, linked or not, link/unlink, and the shop the family shops at by default.
- Download my data includes each shop link's non-secret fields (never the sealed session).

## Checklist
- [x] Daniel: Woolworths products with unknown contents are offered to allergic children with a caution ("Woolworths doesn't publish what's in this. Check the label."), the name still checked; Checkers/PnP unchanged — amends lunch-box ADR-0012 for Woolworths. Privacy policy v3: not now (outside ask)
- [x] App: lunch builder N-shop + Woolworths shelves + carts for every shop (agent)
- [x] Functions + app: Checkers pack quantities; data export shop links; hide switched-off shops; copy fixes (agent)
- [x] Frames: app, rules, Functions, NestPrep-Home (agent) — NestPrep-Home not built
- [x] App: *Your shops* in the account centre (agent)
- [x] Verify: analyze clean; Functions unit 2365/2365; app — every failure left (18) is another session's; agents' rules + emulator runs green. Not done: emulator drive, design-review pictures, account-export emulator test (needs Storage)
- [x] Deployed rules from the main tree (live == firestore.rules) + checkersPushToCart, exportAccountData, searchFrameProducts, addFrameGroceryItem, getFrameDay; iPhone build ready — [ ] install (phone was unavailable)
- [ ] Godfather: new ADRs amending add-to-woolworths ADR-0004 §3, lunch-box ADR-0026/0027, photo-frames ADR-0012, C-0023 revision; overviews; lint; session log

# People who have not joined yet are whole members; removing someone shows it happening (household)

Daniel 2026-11-05: a child invited through *Invite someone* is not in lunches until they join, and is not tagged a child; removing an invited person gives no sign it is happening, the row just vanishes.

## Root causes (from the code)

- **Lunches, Plan my week, the free-tier count, school letters and the assistants' household read go by `familyProfiles/{id}.isChild`**, not by the member's role. Inviting (or adding) a kid writes `role: kid` and the parent's consent, and never calls `setChildProfile`, so the child exists but is nobody's lunch. Nothing in the app or Functions sets `isChild` on joining either — the only way it gets set is the *Child* toggle on the family profile. Nanny hub and the to-dos already read `role == kid`, which is why the two disagree.
- **Removing** is one callable (`removeMember`, africa-south1, cold start seconds); the controller's `_isBusy` is set but the row shows nothing, and on success the listener just drops the row — no confirmation.

## Plan

- [x] Making a kid profile marks it a child in the same action (`NewChildMarking`, used by `InviteStepController.invite`, `HouseholdController.addMember`, a role change to kid in `updateMember`)
- [x] Free tier: a second child keeps the profile and invite; the paywall opens (`offerPremiumForNewChild`), marks them on upgrade
- [x] Removing: `removingMemberId`, *Removing…* row with spinner, other actions disabled, snackbar on success, banner on refusal
- [x] `removeMember` revokes the profile's unredeemed invites in its transaction
- [x] Tests: household controller +9, invite step controller +4, invite step screen +2, household screen +2, emulator membership +2
- [x] Verify: analyze clean (one info in another session's `notifications_providers.dart`); app 5199 pass / 19 fail (none household, same 19 on the tree before); functions unit 2330/2330; emulator 43/43; iOS Simulator against the emulator through the real callables; pictures `people-removing-*`, `people-removed-*` looked at, spinner and disabled buttons fixed after
- [x] Godfather: household ADR-0009 (accepted), overview (constraints, ledger, delivery, restamped e5e4ccd), phase 2 next action + session log, lint 0 errors
- [ ] Deploy `removeMember` — Daniel's call
- [ ] Seen on a phone (none attached; Android AVD offline)
- [ ] Commit — not asked for yet

## Review

Root cause was a second "who is a child" signal (`familyProfiles.isChild`) that only the family profile's toggle set; inviting wrote the role and never the flag. Fixed at creation rather than by reading the role, so the free-tier count stays honest. Mistakes: ran `dart format` over all of `lib test tool` in a tree shared with other sessions (whitespace only, but touched their files); first remove test asserted the wrong row; paywall test tapped the referral link under the fold. Lesson added.

# Snap a shopping list, premium (list-scan)

Daniel 2026-11-05: photo of a shopping list → items on the grocery list, or looked up at the chosen grocer and added so they are one tap from the cart. Plan approved: reuse the school-letter AI path and *Add to grocer*'s shop sheet; branch `feature/list-scan` in its own worktree.

- [x] ADR: list-scan ADR-0001 (proposed); feature node, overview, work-index row 58
- [x] Functions: `readShoppingList` (flag `snapShoppingList`, groceries edit, premium, photo check, `runAiCall` feature `listScan`); trigger `listScan`; emulator canned reply
- [x] App: scan button beside the grocery add field → `ensurePremium` → `…/groceries/scan`; review, edit, add by name, *Find at my shop* via `showRecipeShopSheet`
- [x] Tests: Functions unit 2267/2267, emulator list-scan 10/10 + school letter 13/13; app list-scan 31/31; full suite 5051 pass / 19 fail (same 19 on master)
- [x] Pictures `app/design-review/list-scan-*.png` looked at; 200% wrap and labels fixed
- [x] Committed `6b5645f`
- [ ] Merge, deploy `readShoppingList` + `recordPaywallOpened`/`verifyPurchase`/`rollupBetaNumbers`, set `snapShoppingList` — Daniel's call
- [ ] First real Gemini read; device run (needs the default emulator ports free, or the cloud)

## Review

Mostly glue over two proven seams, so little new surface: one callable, one screen. Mistake: a separate-port emulator suite that included Storage deleted the running LAN suite's blobs folder on exit; folder recreated, lesson updated.

# Add to Woolworths Dash — third shop, like-for-like with Checkers and Pick n Pay

Daniel 2026-11-05: Woolies Dash product search and add-to-cart, the same as Checkers. Discovery done (three agents); evidence in the session scratchpad `woolies-search/` (`verify.sh` replays every working call) and `woolies-auth/`. Nothing built yet.

## What discovery proved

- **Search, on the phone, no login (VERIFIED):** Constructor.io, the same index the site and the Dash app use — `wpkmgeuco-zone.cnstrc.com/v1/search/<q>?key=<public site key>&filters[stocked_at]=<store>`; shelves are `/browse/group_id/<cat>?sort_by=salerank` (best sellers). No headers, CORS `*`, ~200-call bucket refilling ~1 per 3 s per IP. The old `/server/searchCategory` (Endeca) is dead.
- **Place → store + price zone (VERIFIED):** `www.woolworths.co.za/server/validatePlace?latitude&longitude` → `<store>-<plist>`; plist picks the price field (`p10`/`p30`/`p60`, `_wp` = was-price). `/server/*` needs only a woolworths.co.za `Referer`; it sits behind Cloudflare + F5, so it stays on the phone.
- **Product id:** for food `data.id` = SKU = the cart's `catalogRefId`. Contents for the lunch-box allergen gate from `/server/getProductInfo` (ingredients, allergens, nutrition). Pack size only in the name; variable-weight ids start `25…`.
- **Account (REPORTED — a MITM-verified open-source Dash v10.11 client):** AWS Cognito `eu-west-1`, public app client, `USER_PASSWORD_AUTH` (email + password) → IdToken (24 h) + RefreshToken (months), refreshed with `REFRESH_TOKEN_AUTH`. No hosted login page, so the PnP web-view pattern does not apply.
- **Cart (REPORTED):** Dash app server `wfs-appserver.wigroup.co/wfs/app/v4` (AWS ALB, no WAF seen): `GET /cartV2`, `POST /cart/OnDemand/itemV2` `[{catalogRefId, productId, quantity, substitutionSelection}]` — additive. Needs the IdToken as `Sessiontoken` plus app headers (`Apiid`, an APK-wide `Sha1password`, …) — the same class as Checkers' app keys, so Function config only, never the repo or the app.
- **Checkers' cart is not on the phone today.** Only search is; link, session and cart run in Functions (add-to-checkers ADR-0001/0003/0005). PnP is the same.

## Proposed shape (pending Daniel's two calls below)

1. Search + shelves + contents on the phone: `HttpWoolworthsCatalogue` (Constructor + `validatePlace` + `getProductInfo`) behind `RetailerCatalogue`; `ProductRetailer.woolworths` becomes connected.
2. Link: the phone signs in to Cognito itself, so the password goes phone → AWS and never to NestPrep; it relays only the refresh token to `woolworthsCompleteLink`, sealed under `WOOLWORTHS_SESSION_KEY` in deny-all `woolworthsLinks/{uid}`. A Cognito challenge (SMS/email code) is relayed like Checkers' OTP.
3. Cart push in Functions: `woolworthsPushToCart` re-reads the items, re-prices server-side, reads `/cartV2`, adds only what is missing (add or raise, never lower), cart only — never `confirmLocation`, slots, checkout or payment.
4. Make the two-shop code N-shop: `RetailerCatalogues`/`ShopCarts` as maps; the PnP-else-Checkers switches in `list_cart_push`/`recipe_cart_push`; `isSoldByWeight` per shop; failure types; `rankProductMatches` flags and the Jev prompt that names Checkers for every shop; frame `FRAME_GROCERY_SHOPS`/`SHOP_FLAGS`/`frameProductPick`; rules `groceriesIsProductMatch` + frame shop list; `erase_account`. Plan my week stays Checkers/PnP in v1.

## Checklist

- [x] Daniel: the phone signs in to Cognito; the cart push runs in Functions (2026-11-05)
- [ ] Daniel (outside ask): capture one sign-in and one add-to-cart from his own Dash app (HTTP Toolkit) to confirm current `Apiid`/app version, the `Sha1password`, whether sign-in raises a code challenge, and the cart reply shape
- [ ] Godfather: `add-to-woolworths` feature node, ADR-0001 (cart-only bridge, Cognito link, refresh held server-side), ADR-0002 (catalogue on the phone via Constructor), contract C-0xx, integration-map row, work-index row
- [x] Generalise two-shop code (list above) with the existing tests kept green
- [x] App: catalogue client + parser + fakes; link screen (email, password, code) talking to Cognito directly; providers, routes, copy, `WoolworthsFailure`
- [x] Functions: link status/complete/unlink, push, session with refresh + compare-and-swap, emulator stand-in, `addToWoolworths` flag (app + server parity), erasure, callable allow-list and timeouts
- [x] Rules: `root/woolworths_links.rules` deny-all, `groceriesIsWoolworthsPick`, frame shop list; denied-case tests; `rules:build`
- [ ] Verify: analyze, app + Functions + rules suites, emulator drive light + dark, one real push to Daniel's own Dash cart
- [ ] Godfather: overviews (add-to-checkers, add-to-pnp, groceries, photo-frames), next action, lint, session log

## Review

Built in both halves against one fixed contract (scratchpad `woolies_contract.md`); not committed, not on a phone. Functions: build clean, unit 2,330 green, rules 1,227 green (isolated ports), `woolworths.test.ts` emulator 9 green; 82 emulator failures in six unrelated files on isolated ports (calendar feed port, Hosting-routed tests, in-flight frames work). App: 1,018 shop tests green, 83 new; analyze clean of this change (the remaining infos are another session's child-profile edits). Reconciled after the agents: the emulator Cognito client id now passes the app's check, and the app sends `retailer` to `rankProductMatches`. Guessed and unverified until a real capture: where `/cartV2` keeps the delivery store (`deliveryStoreOf`), the cart line and session-expiry shapes.


# Chore pictures for children who can't read (todos ADR-0005)

Daniel 2026-11-05: a picture beside each chore, picked from ~200 generated, on-brand clipart stickers; app and frame.

- [x] Style test on Vertex `gemini-3.1-flash-image`; three anchors chosen; cut-out pipeline (`tools/chore-pictures/`)
- [x] ADR-0005 on todos (proposed)
- [x] Catalogue of 200 chores (agent)
- [x] Generate 200 + review + regenerate the weak ones (agent; 211 generations, 15 redone incl. rugby; 32 enclosed-white fixes in `holes.json`)
- [x] Rules: `picture` on tasks + denied cases; Functions: pass `picture` to the frame day (C-0023 rev 13); cloud demo seed pictures (agent)
- [x] App: picker sheet (suggestions + search + categories), task sheet field, picture on rows, kid tile (ticks now one trailing column), celebration, Today (agent)
- [x] Frame: assets, chore card, task card, celebration, To do rows (agent)
- [x] Verify (partial): app analyze 0, chore tests green vs the full library; Functions unit 2254; rules picture cases as a standalone check; frame 93 unit tests, release + debug build
- [ ] Full `test:rules` (Daniel's dev suite was up), emulator drive in light + dark, frame on a real device
- [ ] Deploy in order (Daniel's call): Firestore rules → `getFrameDay` → app build → frame APK sideload
- [x] Godfather: todos overview, photo-frames overview, C-0023 rev 13, NestPrep-Home overview, work-index row + lesson, lint 0 errors

## Review

Built end to end and green wherever it could be tested here; nothing has been on a device. Full-suite app failures are the pre-existing ones (copy ratchet `HomeCareRoutineCopy.itemForReader`, declared_packages, errors_are_never_swallowed, feature_flags, router, …) plus `nothing_identifies_anybody` from another session's Woolworths work. Not committed.

# Life360-style family location, premium (live-location phase 2)

Daniel 2026-11-02: full location tracking like Life360, premium only, cheap to store and fast to read. Plan approved: windows stay free; our own native engine (not Transistor); kid phones share; a `location` area grant.

- [x] ADRs: live-location 0003–0008 (0008 restates 0003 with fixed links), household 0008, accounts 0010
- [x] Rules: location grant, isOwnMember (kid devices), 24 h premium lease, 10 s pace; trails (day docs, 120/write, 30 s, 3,000, 30-day expiry); places; events; `places` notification category
- [x] Functions: `notifyPlaceEvent` (dedupe, alerts toggles, canSee location), trail erasure/export/removeMember, `familyLocation` trigger, TTL overrides
- [x] Android engine (agent): `:location` process, state machine, geofences, boot, heartbeat; 28 JVM tests
- [x] iOS engine (agent): significant-change/visits/regions, BG refresh, secondary FirebaseApp; XCTests
- [x] Dart: channel client, AlwaysSharing + guard, map (behind NESTPREP_MAPS) / list, disclosure, history + timeline, places + editor, kid sheet, LocationCopy
- [x] Tests: rules 1,195; Functions unit + 4; emulator location/membership/account; Flutter 101 location + kid
- [x] Cloud demo seed (`tools/cloud-demo/location.mjs`)
- [x] Godfather: overview rev 7, phase 2, work-index row, tech-stack row, outside asks; lint clean
- [ ] Commit, deploy (rules, indexes/TTL, `notifyPlaceEvent`) — Daniel's call
- [ ] Real Android phone, then iPhone; battery and write counts
- [ ] Maps key; Play background-location declaration; privacy policy; data-safety form

## Review

Built end to end and green everywhere it can be tested here; nothing has been on a phone. Rules suite 1,195 green on isolated emulator ports (Daniel's dev suite untouched). App: 101 location tests green, analyze clean; the full app suite's 20 failures are the pre-existing ones (router/home-care provider, version, flags count, notifications swallow list, …) plus `declared_packages`, which reads the frozen vault and was already failing. Not committed.

# Send feedback — what works, what doesn't (feedback ADR-0001)

Daniel 2026-11-02: a way in the app for people to say what works and what doesn't, kept in the database for admin tools to read later.

- [x] Godfather: feedback feature node, ADR-0001 (proposed), contract C-0002, overview, work-index row (via `godfather export`/`import`, one row)
- [x] Rules: `rules/firestore/root/feedback.rules` — create-only by the account itself, shape-checked, kid devices refused, no client reads; 14 rules tests, 3 mutants killed
- [x] Functions: erasure deletes the person's feedback; Download my data lists it; emulator deletion + export 18 green, erasure mutant killed
- [x] App: `features/feedback` — repository (8 s bounded wait → queued), controller, screen at `/account/feedback`; account sheet + account centre; copy; export/delete copy lines
- [x] Tests: 16 widget/controller (canSend mutant killed); analyze clean on every touched file; Functions unit 2,106 green
- [x] Device: iOS Simulator integration test against the emulator suite, light and dark — 3 green, both entries read back in the contract's shape
- [ ] Design-review pictures (`tool/account_data_design_review_test.dart` gained send-feedback; blocked while live-location's freezed files are stale in the shared tree)
- [x] Godfather write-back, lint (0 errors), session log

## Review

Feedback is one root `feedback` collection the app creates directly: rules check the whole shape, kid devices are refused, no client reads it, erasure deletes it and the export lists it. Rules 14, Functions emulator 18, unit 2,106, app 16 + 2 entry, Simulator 3 — all green, with mutants killed in rules, erasure and `canSend`. Waiting on Daniel: the privacy-policy line (raises its version), commit, and deploying the rules and Functions. Design pictures are waiting for the shared tree to compile.

# Healthy weeknight recipes, diet tags and calories (recipes ADR-0006)

Daniel 2026-10-29: put focus on Food → Meals. 50 new healthy family meals researched on the web (sub-agents), photos to the catalogue standard on the best image model; room in the recipe model for diet/eating-plan tags (vegetarian, banting, keto…); every recipe gets an estimated kcal per serving, deep-dived by sub-agents.

- [x] Schema: `dietTags` vocabulary (vegetarian vegan pescatarian glutenFree dairyFree banting keto) with consistency rules; `healthy` catalogue tag; `kcalPerServing` on every catalogue recipe; nutrition worksheets in `catalogue/nutrition/` checked by a test
- [x] App: `kcalPerServing` read and shown in the recipe facts; `healthy` tag; Healthy and diet facets; a healthy weeknights shelf
- [x] Research the 50 (sub-agent, evidence of popularity, varied)
- [x] Author the 50 (5 sub-agents × 10, several sources each, own words) + scenes
- [x] Photos: `gemini-3-pro-image` (still the top Vertex image tier — probed 2026-10-29), the shared set; contact sheets looked at
- [x] Independent review of the 50
- [x] Nutrition worksheets for all 158 (sub-agents) + diet/healthy audit applied; independent cross-check of a sample
- [x] Tests, analyze, goldens; Godfather (ADR, guide, overview, phase, work index), lint, session log
- [ ] Seed to the cloud — only when Daniel says so


## Review

158 recipes (100 SA + 50 new + 8 lunch-box), every one with `kcalPerServing` from a per-ingredient worksheet in `catalogue/nutrition/` (`recipe_nutrition.test.ts`, mutation-checked) and audited diet tags; `healthy` on 50 + 5 + 1. The 50: researcher → 5 authors → 2 reviewers (33 changed, 2 near-duplicates rewritten) → nutrition; 2 healthy mains trimmed under ~650 kcal. Photos: `gemini-3-pro-image` (still the best Vertex model — compared against `gemini-nano-banana-2.1`), all 50 looked at, 4 redone. App: `~kcal` (DM Sans has no `≈`), *Suits*, Healthy/diet chips, *Healthy weeknights* shelf. Functions unit 1,898 green; app analyze clean, recipes + meal planning 193 green; the full suite's 21 failures are other sessions' work (home-care provider for the grocery plan, version screen, home-care copy). Seed dry run: 100 photos, 158 recipes at a new version, boxes unchanged — **not seeded, Daniel's call**. Not committed. Godfather: ADR-0006 (proposed), guide rev 4, overview rev 10, phase 4; the work index row was not rewritten (no row-level edit on a 65k doc).

# Calendar in the foreground — the bar becomes Today · Calendar · Food · Lists · More

Daniel 2026-10-27: Today is far too lunch-focused; the family calendar is one of the most important things and needs its own main tab, with a month view.

- [x] Godfather: design-system ADR (supersedes ADR-0015 §1/§3, lunch-box ADR-0014's tab and Today's first block)
- [x] `HouseholdTab`: `food` groups Lunch and Meals (like Lists); Week is in the bar as *Calendar*; More loses its Week tile
- [x] Food switch on the lunch and meals screens (like `ListsSwitch`)
- [x] Calendar: Month | Week, opening on Month; month grid with member-coloured dots and the day's agenda; controller windows a month
- [x] Today: the day's calendar and what is coming up first, to-dos, compact lunches, groceries
- [x] Welcome tour: a Calendar stop; places follow the bar
- [x] Tests updated; analyze, format, tests green
- [x] Build to Daniel's iPhone (release + demo logins, devicectl install), light and dark
- [x] Godfather: calendar, design-system, lunch-box overviews; work index; lint; session log

## Review

The bar is Today · Calendar · Food · Lists · More (design-system ADR-0017, proposed). Calendar opens on a month grid (member dots, spoken count, Month | Week); Food is a bar name for Lunch and Meals like Lists; Today leads with the calendar and *Coming up this week*, lunches a compact row each. Found on the way: `MemberStripe` had never painted (childless `ColoredBox`, zero wide) — fixed. Analyze clean; 4,595 app tests pass; the 19 failures that remain also fail on a clean HEAD worktree (plus `declared_packages`, from another session's pubspec). Design-review pictures retaken (+ `calendar-month-*`), looked at in light, dark and 200%. Release + demo logins installed and launched on Daniel's iPhone. Not committed. Open: Daniel to confirm folding Lunch and Meals into Food; the bar's "Calendar" label shrinks at 200% text.


# Recipe photos from gemini-3-pro-image (recipes ADR-0003 §4)

Daniel 2026-10-23: the generated recipe photos looked poor — flash model, one dated kitchen, JPEG 70/62. Then: one uniform premium kitchen set in the app palette, for every recipe.

- [x] `catalogue/recipe_photo.sh`: `gemini-3-pro-image` at 2K, JPEG 85/80, owns the shared set; dish-only scene per id from `catalogue/recipe-photo-scenes.json`; several ids per call, 5 retries for 429s, failures listed at the end
- [x] Batch 1 (10) reviewed by Daniel, redone in the uniform set, approved
- [x] The other 90 (86 generated + the 4 Commons ones, so all match); 9 rate-limited ones rerun
- [x] The 4 former Commons recipes' `photo` set to generated, attribution null
- [x] All cards looked at on contact sheets; macaroni-cheese (hand), mogodu, souskluitjies, slap-chips rewritten and redone
- [x] Recipe + catalogue unit tests 57 green; cloud dry run: 200 photos, 100 recipes at a new version, lunch and boxes unchanged
- [x] Cloud: `npm --prefix functions run seed:catalogue -- --confirm` — run 2026-10-27 at Daniel's ask: 200 photos uploaded, 100 recipes at a new version; rerun all unchanged
- [x] Godfather: authoring guide rev 3, recipes overview rev 6, session log, lint clean

## Review

Every catalogue photo is `gemini-3-pro-image` at 2K in one cream/oak/sage kitchen set the script owns; scenes describe only the dish. The Pro model 429s above two calls at once — the script retries and lists failures instead of stopping.

# Basket comparison — Compare shops (basket-compare ADR-0001)

Daniel 2026-10-23: price the list at every shop switched on, cheapest like-for-like cart, and make plain what each shop lacks.

- [x] Godfather: feature node `basket-compare`, ADR-0001 (proposed)
- [x] Model `basket_compare/model/basket_comparison.dart` (the contract both halves code against)
- [x] Controller + route + router registration + redirect gate + model/controller tests
- [x] Screen, copy, grocery-list entry + widget tests incl. 360/200%/dark
- [x] `flutter analyze --fatal-infos` clean; format clean; 314 pass in basket-compare/add-to-checkers/groceries/redirect
- [x] Device: iOS Simulator, emulator backend, live Checkers + PnP catalogues, light and dark
- [x] Godfather: overview, work-index row, add-to-pnp open question repaired, lint clean on the feature, session log

## Review

- Full app suite: 20 failures, none in basket-compare (home-care, mental load, subscriptions, notifications, recipes, copy, packages — other work in flight).
- Not seen: Android; the cloud's real Jev deciding "not at <shop>" (emulator Jev says yes to all; the miss path was shown by canning low scores).
- Found on the way, not fixed: `_WelcomeTourLayerState._measure` calls `findRenderObject` on a defunct element when the route changes under the tour.

# Use up a pack before opening another (lunch-box ADR-0028, foundation ADR-0023)

Daniel 2026-10-23: a week with main + fruit bought a kg each of apples, naartjies and bananas.
All three fillers forced variety and none asked whether a pack being bought had room.

- [x] ADRs: foundation ADR-0023 (supersedes ADR-0022's three-day cap only), lunch-box ADR-0028 — both proposed
- [x] Server: `sameAllWeek` input with default; `assembleWeek` sticks / at most 3 kinds / pack-room bonus; merge swaps; packs for every kept product
- [x] Functions tests: week_assembly, part_filled_week, packing_choices; lint + unit + emulator jev_decisions
- [x] App: `LunchVariety` model, store, `LunchVarietyChoice` at the lunch shell
- [x] App: fallback follows variety; `LunchPackBoxes` weight estimate; packs for every kept product
- [x] App: `LunchAutoFill` follows variety; *Fill the week* and the pantry fill pass it
- [x] App UI: variety row in the brief and Fill the week review; basket *Covers N lunches · M planned*; swap *Every day this week* + per-lunch price
- [x] App tests; `flutter analyze --fatal-infos`, format, `flutter test`
- [ ] Device: AVD on the emulator suite, light and dark — **not done**, the only AVD was in use by another app's session
- [x] Godfather: overview, phase 13, work index row 53, foundation ledger, lint, session log

## Review

- **Root cause:** every filler forced variety and none asked whether a pack being bought had room — server `REPEAT_COST` 0.15 + `MAX_DAYS_PER_PRODUCT` 3; phone fallback `ideas[(day - 1) % n]` with a "1kg" bag counted as one box; *Fill the week* −3 a box.
- **Functions:** lint clean; unit 1603 pass, 4 fail (the same 4 as a clean HEAD: notification settings ×2, account-data inventory, premium cap); `plan_week` 115/115; emulator `jev_decisions` + `lunch_recipes` 11/11, run on ports 15001/18080/19099/19199 from a temporary copy of `firebase.json` because another dev suite held the default ports.
- **App:** `flutter analyze --fatal-infos` clean for this change (another session's `basket_compare` is mid-build and has errors of its own); lunch-box + plan-week 540 pass, 1 fails — `lunch_pantry_screen_test` "what is missing goes to the grocery list", which fails on a clean HEAD too. Full suite: 20 failures, none in a file of this change; 18 fail identically on HEAD, the rest are `basket_compare`'s and the `@typesafe-ai/sdk` package check.
- **Not done:** device run; deploy of `buildLunchWeek` (Daniel/orchestrator); commit (not asked).

# Jev decides, Gemini writes

Jev (TypeSafe `systemOne`, `jev-latest`) answers questions with a probability or a label. It cannot
write text or read pictures. So Jev takes every *decision* in NestPrep, and Gemini keeps only the
*generation*: lunch ideas, the school-letter reading, and the lunch photo.

## Where NestPrep decides today

| Decision | Today | After |
|---|---|---|
| Which store product goes in each compartment, and how many boxes a pack does (`buildLunchWeek`) | Gemini writes the whole week as JSON | Jev scores each product; NestPrep's own code builds the week |
| Which Checkers product a grocery line is (grocery list matches) | the shop's search order, and a member picks | Jev scores each match, the best one is marked, and a member picks |
| Lunch ideas, school letter, lunch photo | Gemini | Gemini (unchanged) |

## Plan

- [x] ADR (foundation, Godfather): decisions go to Jev and generation stays with Gemini. This
      amends foundation ADR-0015 (AI was Gemini only, Vertex in Europe). Jev gets product names,
      prices and packing lines, and nothing about a person.
- [x] functions: `@typesafe-ai/sdk` 0.6.0; `TYPESAFE_API_KEY` secret (the 28 Days key);
      `src/ai/decision_model.ts` + Jev and emulator implementations; `runDecisionCall` through the same
      switch, cap and ledger as `runAiCall`
- [x] `buildLunchWeek`: Jev asks whether each product fits its compartment under the packing lines,
      and how many boxes a pack does when the shop does not say. `week_assembly.ts` then builds the
      week: it shares boxes across children, uses a product at most three days, and swaps the
      priciest products for cheaper ones while over budget. The reply contract is unchanged, so this
      needs no app change.
- [x] `rankProductMatches` callable (grocery `canView`, at most 8 products): Jev's fit score for each
      product. The phone puts the best first and badges it *Best match*. If Jev fails, the shop's
      order stays as it is.
- [x] Tests: unit tests (questions, assembly, budget), emulator tests (both callables, canned
      decisions), app tests (ranker, panel), `flutter analyze`
- [x] Live check: one real Jev call per question shape, using the key
- [x] Deploy `buildLunchWeek` + `rankProductMatches` (functions only) and set the secret
- [x] AVD run against the cloud: grocery matches ranked (light and dark). *Plan my week* was built through the deployed callable over HTTPS, not yet on a device
- [x] Vault/Godfather: foundation, lunch-box and add-to-checkers ledgers; integration-map C-0xx
      TypeSafe; session log

## Review

- **ADR:** foundation ADR-0022 (Godfather) supersedes ADR-0021. The first wording was written before the build; the server refuses edits to an accepted ADR.
- **Functions unit tests:** 1361 pass. 4 fail, and the same 4 fail on a clean HEAD worktree: notification settings ×2, the account-data inventory, and the premium-cap callsLeft test.
- **Functions emulator tests:** 5/5 for Jev (`jev_decisions.test.ts`). The checkers 7/7 and school letter 13/13 suites still pass.
- **App:** `flutter analyze --fatal-infos` is clean. Add-to-checkers, groceries and copy tests: 224 pass, 1 fails (`HomeCareRoutineCopy.itemForReader`), which is not this change.
- **Live Jev (real key):**
  - Milk → full cream 0.92, chocolate 0.03.
  - With *ready-made*: raw chicken 0.01. With *no fridge*: yoghurt 0.28.
  - A week takes about 450 ms.
  - The fit floor was lowered from 0.5 to 0.4 because apples scored 0.51 and then 0.46 on identical calls.
  - The three-day cap was made soft after a week came back with empty Thursday and Friday mains.
- **Cloud:**
  - `rankProductMatches`: Sasko Brown 0.91, rolls 0.70, white 0.10.
  - `buildLunchWeek` in the demo household spent a call (72 left) and filled the only open compartment with Provita, not popcorn kernels.
- **Device:** on the AVD, *Brown bread* showed Albany Everyday Brown Bread first with *Best match*, in light and dark.
- **Not done:**
  - Nothing is committed (Daniel did not ask). The plan_week files also hold lunch-box ADR-0017's uncommitted work, which was deployed with this at Daniel's OK.
  - *Plan my week* has not been driven on a device with Jev.
  - A *Brown bread* line was added to the demo household's list during the device run.

# Today's digest on the first open of the day (notifications ADR-0005)

Daniel 2026-11-05: on the first open of the day, a morning digest button on top that opens what the notification opens; only the first open; apps live in memory for days; per device, not across devices.

- [x] ADR-0005 (proposed): an open is the shell's first frame or `onShow`; offered only while today's digest exists and is unread; the day is marked in secure storage per household and member; a day with nothing to offer is not used up
- [x] `DigestIds.of` spelled in Dart, checked against `morning_digest.ts` by the contract test
- [x] `DigestPromptStore` + secure-storage implementation, `DigestPromptController`, `DigestPromptBanner`, `DigestPromptHost` in the household shell
- [x] Tests: controller (8), host widget incl. dark 200% 360-wide (4), contract (1); shell tests given the new providers
- [x] On a device: iPhone 17 Simulator against the emulator, light and dark — first open, tap-through, same-day return, empty day not used up, onShow
- [x] Godfather: ADR, overview, phase, lint, session log

## Review

Pre-existing failures in the working tree (not this change, confirmed by running without the host): app_router groceries/meals/recipe pick, and 16 others from in-flight work.
