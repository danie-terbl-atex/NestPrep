# Avatars review — app

Reviewed the Flutter client for avatars phases 1 and 3 in `app/`. Every finding below is fixed unless
it says otherwise. Nothing was committed, pushed or deployed, and no emulator was started.

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | High | `lib/features/avatars/model/avatar_face_anchor.dart`, `model/resolved_avatar.dart:26` | Face anchors were a stub that answered null, so no Nestling could wear glasses and the wardrobe never showed the section. | Fixed. `avatarFaceAnchorOf` reads `avatarNestlingFaces`; the layer is centred on (x, y) at `w * 1.6` of the base's drawn size, outside the circle's clip. The map pin uses the same anchor. The wardrobe now shows *Glasses and masks* on a Nestling, and the star shop offers the priced ones. |
| 2 | Medium | `lib/design/primitives/nest_avatar.dart` (`_LayerAt`) | Every layer was drawn 2 px right and 2 px down of where `layerBox` put it. On a 28 px avatar that is 7% of its width, and it would have pushed glasses off the eyes. | Fixed: the shift is removed. |
| 3 | Medium | `tools/avatar-pictures/build.py`, `avatar_catalogue.g.dart` | `test/shared/generated_code_test.dart` failed: the generated Dart file lacked the `GENERATED CODE - DO NOT MODIFY` header. | Fixed in `build.py` for the Dart output only; the TS and Kotlin files have no such convention and are byte-identical after the rebuild. |
| 4 | Medium | `lib/features/avatars/state/avatar_studio_controller.dart` (`buy`) | The 20 s timeout started only after the purchase write was acknowledged. Offline, a Firestore write never completes, so the tile would spin for ever. | Fixed: the write is under the same wait and ends in the same "taking longer than usual" message. |
| 5 | Medium | `lib/app/avatar_routes.dart` (`kidAvatarStudioRoute`) | The kid route did not check the `avatars` flag. The entry points were hidden, but a kid device already on `/kid/avatar` kept a working Studio with the flag off. | Fixed: both routes show the same closed screen (`AvatarStudioClosed`), now with a back button. |
| 6 | Medium | `lib/features/household/ui/member_row.dart`, `household_body.dart` | A helper or carer could only reach their own Studio through their family profile, which their grant may hide; the member sheet is admin-only. | Fixed: on the People list, somebody who cannot manage the household gets the edit pip on the rows they may change (their own; all of them for a non-admin parent). Nothing changes for an admin or with the flag off. |
| 7 | Low | `lib/shared/copy/avatar_copy.dart`, `star_shop_section.dart`, `purchase_outcome_listener.dart` | A parent buying on a child's Studio read "You have 22 stars" and "The crown is yours!". "It's on your Nestling now" was also wrong for a child wearing a photo or their initial. | Fixed: "Mia has 22 stars to spend…", "The crown is Mia's!", "Mia is wearing it now."; for the child, "You're wearing it now." |
| 8 | Low | `test/` | No test covered a real face anchor, the initial-with-layers case or the no-look case. | Fixed: tests added (see below). |
| 9 | Low | `tool/avatars_design_review_test.dart` | No review picture showed a face accessory. | Fixed: the grown-up's Olive wears round glasses, and the child's wardrobe now shows the glasses section. |
| 10 | Low | `avatar_studio_controller.dart` (`_offeredPhoto`) | If the server ever refused an uploaded photo, the preview would keep showing it until the next choice. | Rejected: the server refuses only an object that is missing or over the size the client already enforces, and clearing it earlier races the trigger. |
| 11 | Low | `avatar_studio_controller.dart` (timeout) | After a timeout the purchase can still settle; the child is not told when it does. | Rejected: the accessory appears in the wardrobe through the record stream, and a retry is refused `alreadyOwned` server-side, so no stars are lost twice. |

## What was checked and held

- **Parity with the frame (C-0023 rev 19):** a look whose base is the initial shows the initial with worn layers and today's moments, including the birthday hat; a member with no look shows today's initial and nothing else, birthday or not. Both are now tested. The map pin follows the same rule.
- **Who edits whom:** the kid route takes no member id and always uses the device's own; `redirectForKid` admits only `/kid/avatar`. `AvatarRoute.canOpen` is family or self, checked by the opener and again by the route.
- **Flag off:** `MemberAvatar` falls back to the plain `NestAvatar`; no opener, pip, kid shelf, shop switch, hatch watcher or map art. `Member.look` and `Household.avatarShop` are never written by the client.
- **Purchases:** refused reasons each have copy; the celebration fires once per outcome; reduce motion shows the hatched picture with no animation and ignores the longer celebration length.
- **Other sessions' files:** no changed Dart file is whitespace-only. The regenerated `calendar_sync`, `meal` and `recipe` files match their sources' in-flight edits (for example `CalendarProvider.apple`). Nothing was reverted.
- **Rules agreement:** the choice, photo offer and purchase writes carry exactly the keys the Firestore partial allows; the upload path, content type and uploader stamp match the Storage partial.

## Checks run

| Check | Result |
|---|---|
| `python3 tools/avatar-pictures/build.py` | `{"shipped": 151, "total": 151, "missing": []}`; only the Dart catalogue changed |
| `flutter analyze --fatal-infos lib test tool` | no issues |
| `dart format --set-exit-if-changed` on the 91 touched files | 0 changed |
| `flutter test test/features/avatars` | 100 passed (7 new) |
| avatars, household, kid_accounts, chore_points, live_location, family_profiles, design, app, generated-code and one-thing-per-file tests together | 1208 passed, 4 failed (all four in the list below) |
| full `flutter test` | 5967 passed, 2 skipped, 21 failed |
| `flutter test tool/avatars_design_review_test.dart --update-goldens` | 12 passed; pictures retaken and looked at (`avatar-studio-nestlings-light`, `avatar-studio-kid-wardrobe-dark`): glasses sit on the eyes |

The full run was taken before finding 5's closed screen became a named widget; at that point
`one_thing_per_file_test` failed on it. It passes now, so the count today is 20.

**One failure is new and caused by avatars:**
`test/features/subscriptions/data/subscription_contract_test.dart` — the server's
`CONVERSION_TRIGGERS` gained `avatarCreate` and `avatarPortrait`, and the Dart `PremiumFeature` has
neither. Not fixed here: the mirror is phase 4 client work, and adding the values means paywall and
analytics copy for features this portion does not build.

The other 19 are not avatar work: `app_router_test` (3, a missing `GroceryPlanController`),
`store_readiness_test`, `lunch_pantry_screen_test`, `mental_load_screen_test` (2),
`nanny_v2_contract_test`, `beta_numbers_screen_test`, `referral_contract_test`,
`handover_screen_test`, `one_home_for_copy_test` (`HomeCareRoutineCopy`), `declared_packages_test` (2),
`errors_are_never_swallowed_test` (4, notifications and accounts), `feature_flags_test` (its list
still names two flags).

## Left for Daniel

- **`PremiumFeature` needs `avatarCreate` and `avatarPortrait`** before phase 4 ships, or the contract test above stays red.
- **No route-level test for the kid Studio with the flag off.** No test rig builds a kid session through `kidRoutes`; the guard is four lines and shares the family route's widget.
- **Not run on a device.** Everything here is widget tests and review pictures. The photo crop, the camera picker and the hatch animation want a look on a phone.
- **Godfather is not updated.** I had no Godfather tools in this session: the face-anchor wiring, the People-list entry point and the timeout covering the write belong in the avatars overview.
- **A parent can spend a child's stars** from the child's Studio on the parent's phone. The rules allow it and the wording now fits; say if the shop should be the child's device only.
- **Adults can only wear free accessories**, because only a child has stars. Round glasses are the one free face accessory.
- The People-list pip is 22 px on a 40 px avatar; I did not retake the household review pictures because an admin's view is unchanged.
