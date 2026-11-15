Verdict: no blocker and no breaking change found for shipped Premium builds or the frame contract, but six should-fix defects remain — one server bypass through the frame and five ways a lapsed or over-limit household is left without a way out or wrongly refused.

Read-only review of the uncommitted Premium work, 2026-11-15. Nothing was run: no emulator, no test suite, no build. Each finding below was confirmed by reading the code path named.

## Findings

### 1. A free household's frame still does home-care work — should-fix
- **Where:** `functions/src/frames/tick_frame_item.ts:118` (`handInJob`), `functions/src/frames/tick_frame_item.ts:152` (`tickRoutine`); the read side is `readHomeCare` in `functions/src/frames/frame_reads.ts:138`.
- **What is wrong:** both write `homeCareJobs` (plus a job event) and `homeCareRoutineTicks` with the Admin SDK and check no entitlement. These are exactly the writes `home_care.rules` and `home_care_routines.rules` now refuse a free household. The rest of the frame is gated (`set_frame_shift.ts:56`, `get_frame_job_photo.ts:19`, `search_frame_products.ts:59`), so the helper panel is half on.
- **Scenario:** a household lapses and its wall keeps the helper panel. The helper hands in jobs and ticks routine items all day from the frame. On the same panel clock-in answers `shiftsOff` and job photos answer 404.
- **Smallest fix:** in `handInJob` and `tickRoutine`, throw `refuseFrame('itemNotFound')` when `readFramePremium(store, home)` is false. It is an existing code, so the frame app sees nothing new. Whether `getFrameDay` should also stop sending the helper's jobs to a free household is a product call.

### 2. A lapsed household cannot end an open home-care or nanny shift from the app — should-fix
- **Where:** `app/lib/app/home_care_route.dart:11` (`homeCareArea`) and `app/lib/app/nanny_hub_route.dart:10` (`nannyHubArea`) wrap every route of both areas in a plain `PremiumArea`. The only end controls are `app/lib/features/home_care/ui/shift_clock_card.dart:114`, `app/lib/features/home_care/ui/shifts_screen.dart:186` and `app/lib/features/nanny_hub/ui/shift_body.dart:100`, all inside those areas.
- **What is wrong:** the server deliberately keeps ending free (`rules/firestore/household/home_care_shifts.rules:30`, and `endNannyShift` has no gate), but no screen a lapsed household can reach offers it.
- **Scenario:** a helper clocks in, Premium ends that afternoon, and she and the parent both see only the locked view. The shift stays open in the record hours and leave are worked out from. The only way to close it is a wall frame.
- **Smallest fix:** give these two areas a locked screen that still shows an open shift with its End button, the way `LockedAssistantsScreen` (`app/lib/features/assistants/ui/locked_assistants_screen.dart:34`) still lists connections with Disconnect.

### 3. A lapsed household cannot end a co-parent link — should-fix
- **Where:** every two-homes route is wrapped in `app/lib/features/two_homes/ui/two_homes_premium_area.dart:6` (`app/lib/app/two_homes_routes.dart:43` to `:126`); "End the link" exists only at `app/lib/features/two_homes/ui/link_overview.dart:139` and `app/lib/features/two_homes/ui/two_homes_screen.dart:124`.
- **What is wrong:** `endCoParentLink` is ungated on the server, but the control is behind the lock.
- **Scenario:** a separated parent's Premium lapses. The link to the other home stays active and they have no way to end it short of buying Premium again.
- **Smallest fix:** the same locked-screen-with-exit pattern, listing links with End.

### 4. The over-limit lock removes the exits a lapsed household of five or more needs — should-fix
- **Where:** `app/lib/app/household_place_redirect.dart:60` (`isOpenOverTheFreePlan`), `app/lib/app/household_shell.dart:154-164`, `app/lib/features/household/ui/household_size_lock.dart:78-99`.
- **What is wrong, three parts:**
  - Only household, setup, plan and referrals stay open. The shops screen (where Unlink is kept for lapsed households) and the assistants screen (Disconnect) are not on the list.
  - `AlwaysSharingGuard` is a child of `HouseholdSizeLock` (`household_shell.dart:164`), so while the over-limit screen shows it is not built and `stopForLapse` never runs.
  - A member who is not family gets only the "ask a parent" text and the account menu. Leave household lives on the household screen, which is open to them but which nothing on the lock screen links to.
- **Scenario:** Premium lapses on a six-person household. A parent cannot unlink their Checkers account or disconnect Claude until they have removed two people. A phone that was always-sharing is not told to stop by the app. The nanny can only sign out or delete her whole account.
- **Smallest fix:** mount `AlwaysSharingGuard` above `HouseholdSizeLock`; add the shops and assistants paths to `isOpenOverTheFreePlan`; show the manage-household button to non-family too.
- **Not confirmed:** whether the native location engine removes the pin when its writes are refused. The reviewer saw it stop after two denials but did not read its `stop()`; if it does not delete, the last position stays until the lease ends (up to 25 hours).

### 5. A dropped recount can stop a free household of three from adding a fourth — should-fix
- **Where:** `functions/src/household/keep_household_size.ts:15`.
- **What is wrong:** the trigger sets no `retry`, and no global option does, so a failed invocation is not run again. Nothing else recounts on a removal.
- **Scenario:** a free household of four removes a member and the recount fails (contention, timeout, crash). `entitlement/size.count` stays 4 with three members, so `hasRoomForAnotherMember` (`rules/firestore/household/household.rules:71`) refuses every new profile. No create can happen to trigger a fresh count; only removing another person or the backfill clears it.
- **Smallest fix:** `onDocumentWritten({ document: …, retry: true }, …)` — the recount is idempotent — or call `recountHouseholdSize` at the end of `removeMember`.

### 6. `PremiumArea` shows the paywall to a paying household when the entitlement read fails — should-fix
- **Where:** `app/lib/features/subscriptions/ui/premium_area.dart:33-35`; `isPremium` is false for anything but data (`app/lib/features/subscriptions/state/household_entitlement.dart:40-43`).
- **What is wrong:** only `AsyncLoading` gets the neutral view. A failure falls through to `PremiumLockedView` with no retry.
- **Scenario:** a Premium household opens the app offline with no cache, or the listener errors once. Every Premium place says "See Premium". `HouseholdSizeLock` already avoids this with `isKnown`.
- **Smallest fix:** on a failed entitlement show the error view with `onRetry: entitlement.retry`; lock only when `entitlement.isKnown`.

### 7. `ensurePremium` and the lock badges treat "still loading" as "not Premium" — minor
- **Where:** `app/lib/features/subscriptions/ui/premium_gate.dart:21`; badges at `app/lib/features/household/ui/household_place_tile.dart:113-116`.
- **Scenario:** a Premium parent opens the app and taps a shop control or "add a person" (fifth) before the first entitlement snapshot: the paywall opens. Lock badges flash on More for the same moment.
- **Smallest fix:** in `ensurePremium`, return true (the rules still decide) or wait while `!isKnown`; badge only when known.

### 8. Every refused add-a-person is reported as "the free plan is full" — minor
- **Where:** `app/lib/features/household/state/room_for_another.dart:11`, `app/lib/features/household/ui/household_room.dart:38`.
- **What is wrong:** any `PermissionDeniedFailure` on add becomes `PremiumRequiredFailure(householdSize)`. For a Premium household `offerRoomIfRefused` returns early without dismissing it, so the failure stays as free-plan wording. The test that covered a plain refusal was changed to `UnavailableFailure` (`app/test/features/household/ui/invite_step_screen_test.dart:220`), so nothing exercises this.
- **Scenario:** an admin whose role was changed mid-session, in a Premium household, adds a person and is refused; the message is about the free plan's four people.
- **Smallest fix:** convert only when the household is known to be free and at four or more; add a Premium + permission-denied test on both screens.

### 9. The snap-a-list route has no lock of its own — minor
- **Where:** `app/lib/app/list_scan_route.dart:39-63`.
- **What is wrong:** `/households/:id/groceries/scan` builds `ListScanController` and the screen with no `PremiumArea`; the only gate is the button that leads there. The server refuses the read (`readShoppingList` is gated), so nothing is spent.
- **Scenario:** a free household reaches the path directly, picks a photo, and only then meets the refusal.
- **Smallest fix:** wrap in `PremiumArea(feature: PremiumFeature.listScan, …)` with the provider inside.

### 10. Locked places that still listen — minor
- `app/lib/app/kid_routes.dart:145-162`: a free household's kid tablet still creates `LunchChooseController` and shows the "lunch to choose" card (the tap lands on the lock).
- `app/lib/app/meals_routes.dart:60`: the recipe catalogue controller is kept after a lapse.
- `app/lib/features/nanny_hub/ui/carer_scope.dart:70-91`: `ShiftPassController` and the offline keeper run whatever the plan.
- **Smallest fix:** gate each on the entitlement.

### 11. Tests that would not catch a regression — minor
- `functions/test/rules/lunch_premium.rules.test.ts:191-215`: the kid's plan write is denied only as part of a batch whose other write is gated separately, so removing `hasPremium` from the kid `lunchPlans` rules (`rules/firestore/household/lunch_kid_picks.rules:79`, `:86`) leaves it green. Seed the choices doc and assert a lone plan write free and Premium.
- `app/test/support/family_editor_harness.dart:55`: every family editor test now runs Premium; no free test saves a profile and checks the write carries no allergy keys.
- `functions/test/rules/avatars_premium.rules.test.ts:134-152`: the "no avatar document, wear on `members.look`" create path (`rules/firestore/household/avatars.rules:47-52`) is not the case tested — the test seeds the document, so it takes the update path.
- `functions/test/rules/avatars_premium.rules.test.ts:182-191`: the admin purchase and portrait denials have no Premium twin with the same payload.
- `app/test/support/avatar_studio_rig.dart:60-62`: the rig default flipped to Premium; no free photo-pick test.

### 12. Smaller things to decide or tidy — minor
- `functions/src/documents/open_vault_document.ts:50`: after a lapse someone granted another member's vault cannot open a document (refused `premiumRequired`), and live share links answer `ended` (`functions/src/documents/share/share_policy.ts:93`). That fits "the place is locked" but not "reads stay"; a lapsed household also cannot delete documents or revoke links from the app (`app/lib/app/documents_shell.dart:48`).
- `functions/src/nanny_hub/set_carer_shift_only.ts:67`: a shift-only carer in a lapsed household sees nothing at all, free places included, until an admin lifts the mark, and nothing prompts the admin.
- `functions/src/frames/search_frame_products.ts:59`: a free household's frame is still told its shop, and every search answers `shopUnavailable`, which reads as a passing outage.
- `functions/src/account_data/end_household.ts:65` with `keep_household_size.ts:35-41`: closing a large household may leave an orphan `entitlement/size` (inferred from delete order, not reproduced).
- `functions/tools/demo-household.mjs:246` still passes a fourth argument to `markChild`; it is ignored.
- `rules/firestore/household/avatars.rules:57-63`: a lapsed member wearing a face accessory on a Nestling cannot move to the initial — carrying the wear over passes the rule but the Function reverts the choice, and dropping it is refused.

## Checked and found correct
- Rules: every create and update in lunch box, kid picks, pantry, budget, documents, vaults, home care (rooms, products, jobs, events, routines, ticks, language, clock-in), nanny hub (cards, contacts, home, guide, rules, checklists, shifts, entries, photos, pickups, bookings, secrets), live location, trails, places, avatar purchases and creations carries `hasPremium`; reads and deletes are unchanged.
- Rules: collections with no client write (co-parent, document shares, household recipes, lunch photos, shop links, assistant tokens, AI usage, `entitlement/*`) need no gate; a client cannot write `entitlement/size`.
- Rules: plain grocery add, tick, rename with an unchanged pick, clearing a pick and delete stay free; only setting a pick needs Premium.
- Rules: family profile allergy fields are maps in both the rule and the app, so `== {}` holds; free saves merge only the edited fields; medication is never batched with a profile.
- Rules: member avatars — Nestling, initial, stage and photo (through `pendingPhoto` and the Function) pass for a free household; the fallback to `members.look` matches the shape the Function writes.
- Rules: members create allows the fourth and refuses the fifth; a missing size document passes; `createHousehold` writes `count: 1`; the recount is a transactional count, so it cannot drift.
- Rules: `assistantSettings.allowed = false`, home-care clock-out and the shift pass stay free.
- Generated file: `firestore.rules` and the partials carry the same 84 occurrences of the gate functions and none of the removed `lunchPlansFor`.
- Functions: every Premium callable in lunch, recipes, list scan, school letter, shops, two homes, documents, translation and assistants is gated after sign-in, membership, grant and flag checks and before any SMS, shop call, model call or ledger claim.
- Functions: `shops_premium.ts` is not exploitable — linking needs any Premium household of the caller, but push and rank are gated on the household named; status and unlink are free.
- Functions: the AI ledger gives a free household zero, reads the tier inside the claiming transaction, and treats a missing or malformed entitlement as free; the avatar creation trigger refuses before any model call.
- Functions: the MCP assistant checks Premium on every tool call and at consent; revoke and disconnect are free.
- Functions: no server path adds a fifth person — invites and kid pairing claim existing profiles, and the co-parent accept is behind Premium; remove, leave, close and account deletion have no gate.
- Breaking changes: `index.ts` only gains `keepHouseholdSize`; no callable input or output changed; no refusal name was removed; `setChildProfile` keeps its shape; a Premium household's frame responses are unchanged and a free one gets only existing codes and an absent `lunch` key.
- Breaking changes: `entitlement/freeChild` is no longer written but stays readable; shipped builds read an absent one as null and Premium households never consult it.
- App: every route of every Premium area is wrapped, notification taps land on wrapped routes, kid routes read their own entitlement, and no free place is locked.
- App: the over-limit lock waits for a known entitlement, never shows for Premium, and locks at five, not four.
- Tests: `family_fixture.ts` stays free by default, so groceries, household, calendar, to-do and kid rules tests still prove the free path; the guard-test allow-lists were only added to.

## Not reviewed
- `npm run rules:check` was not permitted in this session, so "the generated file matches the partials" rests on the occurrence counts above, not on the builder.
- The 1000-expression and document-access limits on rules that gained a gate (the `homeCareJobs` update is the one that was already near the limit) — only the emulator can answer that.
- Storage rules: uploads for Premium areas are ungated there, as the spec leaves them.
- The frame app itself (not in this repo): whether it tolerates the absent `lunch` key and a permanent `shopUnavailable`.
- The native location engines' behaviour on a refused write (Kotlin `stop()`, the iOS path).
- Emulator test diffs (shops, vault, shares, co-parent, home care, avatars, frames, school letter, assistants) and most new app `*_locked_test.dart` files.
- Route files with no `PremiumArea` that were grepped but not read: account, calendar, photo frame, notifications, subscription, referral, grocery, chore points, kid routines.
- The bodies of leave, close, erase and export beyond a search for entitlement use; push-to-cart bodies past the gate; the `tools/cloud-demo/*` modules other than `free-cast.mjs`.
- Whether a pushed route under the household shell builds a second entitlement scope (which would make findings 6 and 7 recur per place rather than once per session).

REVIEW COMPLETE
