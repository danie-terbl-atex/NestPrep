# Premium map — shared brief for every build agent (2026-11-15)

Decisions: Godfather subscriptions ADR-0008 (the map) and ADR-0009 (how it is enforced). The app is
not launched; existing households are Premium influencers, testers and demos.

## The map

**Free:** calendars (sync included), to-dos and chores (stars and rewards included), the plain
grocery list, the week's meals with manual meals, Nestling and photo avatars, the nestprep Home
frame, kid routines, kid devices, the morning digest, birthdays, the mental load view, the shared
calendar feed. A free household holds at most **four people**, everybody counted.

**Premium:** lunch boxes (every part), recipes (the page is locked), the shop integrations
(Checkers, Pick n Pay, Woolworths, compare shops, add to grocer), avatar wardrobe, avatar Create
and keepsakes, Where we are (all of it), two homes, the nanny hub, home care, shared documents and
the personal vault, AI assistants (Claude/ChatGPT) and every in-app AI helper, recording allergies
and medication. **No free AI allowance of any kind.**

**Rule of thumb (Daniel):** never hide a Premium feature from a free household. Show it, locked.
A lapsed household keeps its data; the place is locked.

## How to enforce it — the same way everywhere

### App (Flutter, `app/`)
- A Premium **place** (a route): wrap the screen in its route builder with
  `PremiumArea(feature: PremiumFeature.x, title: <the screen's title copy>, child: <screen>)`
  from `lib/features/subscriptions/ui/premium_area.dart`. Wrap **every** route of the area,
  sub-routes and deep-link targets included. Keep any `ChangeNotifierProvider` *inside* the
  `PremiumArea` child so a locked place starts no controller, listener, upload or callable.
- A Premium **tab or section inside a free screen**: show `PremiumLockedView(feature: …)` in its
  place, or keep the control visible and call `ensurePremium(context, feature: …)`
  (`lib/features/subscriptions/ui/premium_gate.dart`) before it does anything. Mark it with a
  lock (`LucideIcons.lock`, `SubscriptionCopy.lockedHint` as the semantic label). Never remove it.
- Ask `context.watch<HouseholdEntitlement>().isPremium` (`hasPremiumIn(context)` when the place
  may sit outside the household shell, e.g. `/kid/...` routes — it answers false there, so read
  how `live_location/ui/kid_location_sheet.dart` gets the entitlement before relying on it).
- Paywall headline and pitch per feature already exist in `SubscriptionCopy`. Any other new
  sentence goes in your feature's own copy file under `lib/shared/copy/`, never inline.
- Tests pump with a **free** household by default (`test/support/pump_screen.dart`); add
  `premiumEntitlementProvider()` from `test/support/premium_entitlement.dart` to `providers` for
  a Premium one. Existing screen tests of a place you wrap at the route keep passing untouched;
  tests of a screen you lock *inside* need the Premium provider, plus new tests for the locked
  state (shown, not hidden; the button opens the paywall on your feature; dark at 200% text on a
  360-wide surface does not overflow — copy the pattern from a sibling test).

### Rules (`rules/firestore/household/<feature>.rules`)
- Add `&& hasPremium(householdId)` to the **create** and **update** rules of your area's
  collections, beside the existing grant check. Leave **delete** and every **read** exactly as
  they are. Never edit `firestore.rules` or `storage.rules` (generated). Do not change Storage
  partials.
- Add or extend the rules test in `functions/test/rules/` with a denied case (free household)
  and an allowed case (Premium) for each rule you changed. Read
  `functions/test/rules/premium_gate.rules.test.ts` and `lunch_premium.rules.test.ts` for how a
  test gives a household Premium. Existing rules tests of your area will now need their
  household to be Premium: fix them through the shared fixture they use, in the smallest way.

### Functions (`functions/src/`)
- A callable of a Premium area calls
  `await requirePremium(store, householdId, '<feature>')`
  (`functions/src/subscriptions/premium_gate.ts`) **after** its sign-in, membership, grant and
  flag checks and **before** any work or spend. Inside a transaction use the existing
  `householdHasPremium(transaction, …)` + `premiumRequired('<feature>')` instead.
- **No callable's input or output shape changes. No callable, export, collection, field or
  refusal name is renamed or removed.** Builds already on phones must keep working.
- Background triggers need no gate when the write that fires them is already refused by rules.
- Unit tests (vitest) beside the existing ones; emulator tests in `functions/test/emulator/`
  extended where the area already has one.

### Feature names (already added to `PremiumFeature` and `CONVERSION_TRIGGERS` — do not edit those files)
`lunchBox`, `recipes`, `shops`, `avatarWardrobe`, `avatarKeepsakes`, `twoHomes`, `nannyHub`,
`homeCare`, `documents`, `assistants`, `schoolLetter`, `healthProfile`, `householdSize`;
`familyLocation` now covers all of Where we are. Older names (`lunchLearning`, `prepList`,
`budgetMode`, `lunchPhoto`, `aiPlanning`, `recipeShopping`, `listScan`, `ownRecipes`,
`avatarCreate`, `avatarPortrait`, `additionalChild`) stay valid; keep using a finer one where it
already gates something finer.

## Working rules — several agents share this working tree at the same time

- **Touch only the files your brief gives you.** These are owned by the coordinator and are
  read-only for you: `premium_feature.dart`, `subscription_copy.dart`,
  `product_analytics_copy.dart`, `premium_area.dart`, `premium_gate.dart` (app) and
  `premium_gate.ts`, `conversion_ledger.ts`, `errors.ts` (functions), `household_place.dart`,
  `household_place_tile.dart`, `nest_place_tile.dart`, `app_router.dart`, `household_shell.dart`,
  `test/support/pump_screen.dart`, `test/support/premium_entitlement.dart`, `functions/src/index.ts`,
  `firestore.rules`, `storage.rules`, `firestore.indexes.json`. If you need a change in one, say
  so in your report instead of making it.
- The tree holds other people's uncommitted work. **Never** `git stash`, `git checkout -- …`,
  `git reset`, `git clean`, commit, push or deploy. Format only files you changed
  (`~/development/flutter/bin/dart format <paths>`), never a whole folder.
- Use `~/development/flutter/bin/flutter` and `…/dart` (the `flutter` on PATH is too old).
- **Do not start, stop or talk to the Firebase emulator suite**, and do not run
  `npm run test:rules`, `npm run rules:build`, `npm run build`, `build_runner`, or the emulator
  test folders. Write the rules and emulator tests; the coordinator runs those suites once at
  the end. You may run: `flutter analyze <your paths>`, `flutter test <your test paths>`,
  `npx tsc --noEmit -p functions/tsconfig.build.json`, `npx vitest run <your unit test files>`
  (from `functions/`), `npx eslint <your files>`.
- Other agents are editing other features at the same moment. An analyzer or compiler error in a
  file outside your brief is theirs: ignore it, do not fix it. If a `flutter test` run dies on a
  build or lock error rather than a test failure, wait a few seconds and run it again.
- Code style: match the file you are in. **No new comments** unless the line guards a genuine
  edge case nobody could infer; no banner comments, no restating what the code does.
- Do not write to Godfather memory, `CLAUDE.md` files or `tasks/`.

## Report back (under 350 words)

Files changed and added; per rule / callable / screen, what is now gated on which feature; tests
added and the exact commands you ran with their pass/fail counts; rules and emulator tests you
wrote but could not run; anything in your area you deliberately left free or ungated and why;
anything you needed from a coordinator-owned file; anything you are unsure of.
