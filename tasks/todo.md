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
