# Avatars review — app-ai (phases 4–5 client)

Reviewed the Create tab, Keepsakes tab, the AI-pictures switch, the portrait entry and the premium
mirror in `app/`, against the server as built (`avatar_creation.ts`, `avatar_keepsakes.ts`, both
avatars rules partials). Every finding is fixed unless it says otherwise. Nothing was committed,
pushed or deployed; no emulator was started.

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | High | `ui/create_tab.dart`, `ui/creation_refused_view.dart`, `model/creation_allowance.dart` | "You can make more from 1 December!" and "N left this month" were worked out from the **phone's** clock and zone. The server counts in the household's zone, so a parent abroad, or anyone near midnight on the last day, saw the wrong month. | Fixed. `AvatarStudio` carries the household's `timeZone` (from the household stream the Studio already watches, so kid devices have it too); the tab builds a `HouseholdClock` and both the date and the "this month" test use it. Tested across two zones and across December → January. |
| 2 | High | `model/creation_allowance.dart` | `limitReached` also means the month's *tries* are used (refused photos), and then the server still sends `left > 0`. The menu said "7 left this month" and kept the cards live, so every tap was refused again. | Fixed: a `limitReached` answer this month reads as nothing left; the note gives the date and the cards close. Tested. |
| 3 | Medium | `ui/studio_tab_picker.dart`, new `design/primitives/nest_chip_rail.dart` | Five tabs wrapped onto two rows of chips. | Fixed: one row that scrolls sideways (`NestChipRail`, a kit primitive, exported from `nest_kit.dart`), each tab with an icon, the chosen tab brought into view — so opening on Keepsakes never starts off-screen. Three tabs keep the segmented control, so the flag-off Studio is unchanged. Tested at 360 wide, dark, 200% text. |
| 4 | Medium | `app/avatar_routes.dart`, `ui/avatar_studio_screen.dart` | With the `avatarCreations` flag off, Keepsakes vanished with Create, so a family could not see or **delete** pictures already made. With the switch off, a child got an empty shelf saying "everything you make lands here" and no way to make anything. | Fixed: the shelf is always watched; the Keepsakes tab shows when Create shows, or when the shelf holds something. Flag off and nothing made is exactly as before. Tested for both. |
| 5 | Medium | `state/avatar_creation_controller.dart` | When the send itself timed out (offline: a Firestore write never completes), the controller showed "Still hatching" but stopped listening, so a request that landed later was never shown as ready. | Fixed: it follows the creation after a send timeout too. Tested. |
| 6 | Low | `ui/creation_refused_view.dart` | "Try again" was offered for `limitReached` and `creationsOff`, where trying again cannot work. | Fixed: those say "Back". |
| 7 | Low | `shared/copy/avatar_creation_copy.dart` | "3 buddies left this month" / "No more buddies this month" also counted toys, pet twins and the portrait. | Fixed: "pictures". |
| 8 | Low | `ui/buddy_composer.dart` | The plan gives every recipe the style choice; a buddy was always plush though the rules and the trigger take a style. | Fixed: the buddy builder has the same style picker. |
| 9 | Low | `state/avatar_creation_controller.dart` (`extra`) | Cutting at 60 UTF-16 units could split an emoji. | Rejected: the field already limits typing to 60, and the server would only drop one broken character. |
| 10 | Low | `state/avatar_keepsakes_controller.dart` | A second delete of a keepsake whose first request the trigger never settled is refused by the rules (the request doc exists) and shows a failure. | Rejected: it needs a failed trigger first, and the banner is honest. |

## Checked and held

- **Create keys per recipe:** drawing/pet send `memberId, recipe, style, inboxId, requestedBy, requestedAt`; buddy sends `buddy` (all five words, the button is off until complete), optional `extra` and `style`, no `inboxId`; portrait sends only the four required keys, and is offered only to family on their own Studio, so `memberId == requestedBy`.
- **Inbox:** `households/{h}/avatars/{memberId}/inbox/{creationId}.jpg`, `image/jpeg`, `uploadedByUid`, compressed to 1024 px under 2 MB; the id is a Firestore auto id, inside the rules' pattern.
- **Keepsake delete:** `avatarKeepsakeDeletes/{keepsakeId}` with exactly `requestedBy`, `requestedAt`.
- **Statuses and reasons:** all five statuses and six reasons are read; an unknown reason falls back by status.
- **`avatarCreationsOn`:** written through the household update the rules allow for family; absent reads as on.
- **Kid devices:** no privacy link (it needs a `HouseholdView` and a router), the disclosure text still shows; `premiumRequired` says "Ask a grown-up about Premium" with no paywall.
- **120 s:** one timer from the tap; "Still hatching" has Done and See the shelf, and turns into the ready view if the answer arrives while it is open.
- **Twig** appears only on the hatching and ready cards.
- **Reduce motion:** `NestMotion.wobble` is zero, the egg's controller stops and no transform is built (tested).
- **Photo-frame pictures** (`photo-frame-scan-*`, `photo-frame-settings-*`): other sessions changed `frame_link_sheet`, `frame_edit_sheet` and `photo_frame_copy`; the pictures follow those. Left alone.

## Checks run

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos lib test tool` | no issues |
| `dart format --set-exit-if-changed` on the touched avatar files (100) | 0 changed |
| `flutter test test/features/avatars` + egg wobble | 181 passed (7 new) |
| subscriptions + photo_frames + chore_points | 507 passed |
| full `flutter test` | 6050 passed, 2 skipped, 19 failed — **none new**; all 19 are on the list in `avatars-app.md`. `subscription_contract_test` now passes. |
| both avatar design-review tools, `--update-goldens` | 28 passed; looked at `avatar-create-menu-light`, `avatar-create-buddy-light`, `avatar-keepsakes-dark-200-percent-text`: one tab row, nothing clipped or overflowing |

## Left for Daniel

- **Godfather is not updated.** I had the CLI but not the MCP tools, and an export/import of the node beside other reviewers could overwrite their edits. To write, in place, on the proposed docs:
  - **avatars overview** — client as built: Studio tabs Create and Keepsakes on a scrolling chip row past three tabs; the shelf stays reachable with the flag or switch off while it holds something; the switch `avatarCreationsOn` on Stars and inline in Create; the portrait card on the frame album opens the viewer's own Studio on Create; `PremiumFeature.avatarCreate`/`avatarPortrait`.
  - **ADR-0003** — the client reads the allowance from the newest of the household's five latest `avatarCreations` carrying `left`, in the household's month (`HouseholdClock`); `limitReached` this month reads as none left; a free household's try is `left` 0/1; a kid device shows no count (it has no entitlement) and "ask a grown-up" on `premiumRequired`; 120 s then "Still hatching", never blocking.
  - **ADR-0005** — delete is a request doc `avatarKeepsakeDeletes/{keepsakeId}` `{requestedBy, requestedAt}`; originals are read by `originalPath` (2 MB cap); "Use again" is hidden on a portrait; the shelf query is `memberId ==`, limit 200, sorted on the phone.
- **A free household that burns its month's tries** on refused photos sees "Your free try is used" on the menu, though the try itself is still there next month. The refusal card gives the right date.
- **A kid device shows no "N left" note**, because it has no entitlement; it learns of the limit from the refusal.
- **No review picture of the frame album with the portrait card**, and nothing here was run on a device.
