# Avatars review — integration (server, app, frame, art)

Reviewed 2026-11-13 after reading all seven portion reports. Nothing was committed, pushed or
deployed, and Godfather was not written (another agent is doing that). The emulator suite I started
was stopped with SIGINT and exported.

**Verdict:** the three codebases agree on the contract, and the whole flow works end to end on the
emulator. I found no new bug in the earlier portions' work. I added the three things asked for (a
shared fixture, the stuck-creation sweep, the frame's initial typeface) and wrote the deploy runbook.

## What was added

### 1. One golden fixture, three readers

`functions/test/fixtures/frame_avatars.json` is what the real `assembleFrameDay` sends for twelve
members: a preset at each stage 0–3, an image base, an initial base with layers (rev 19), all four
slots worn, a birthday hat over a worn crown, an unknown and a wrong-slot accessory, a malformed
look, an unknown Nestling, an initial with nothing worn, and a member with no look.

| Reader | File | What it holds |
|---|---|---|
| Server | `functions/test/unit/frames/frame_avatars_fixture.test.ts` | The file equals what the assembly builds now, and the frame's copy is byte-identical. `UPDATE_FIXTURES=1` rewrites both. |
| Frame | `../NestPrep-Home/app/src/test/java/…/FrameAvatarFixtureTest.kt` | Parses its copy (`app/src/test/resources/frame_avatars.json`, beside `day.json`) through `FrameDay.from`; every avatar reads back exactly as sent; this APK bundles every asset the server names; no member id. |
| App | `app/test/features/avatars/model/frame_avatars_fixture_test.dart` | `ResolvedAvatar.of` gives the same base and layers for the same looks. |

Two cases are skipped on the app, on purpose: a look with `v: 2` and one naming an unknown Nestling.
The server sends no avatar for either; the phone reads them leniently. The server never writes such
a look, so this is not a drift that can reach a family.

The frame gets a copy rather than a relative path because it is a separate repository; the server
test fails when the copy differs.

### 2. `sweepAvatarCreations` — creations a dead run left behind

`functions/src/avatars/creation_sweep.ts` (body) and `sweep_avatar_creations.ts` (hourly schedule,
`europe-west1`, 120 s, one retry, like `sweepAccountExports`).

- Finds `avatarCreations` at `checking` or `drawing` with `requestedAt` over an hour old, 100 a run.
- Ends each in a transaction that re-reads the status: `failed` / `unavailable`, or **`ready` when
  `imageHash` and `keepsakeId` are already on it** (the run died after keeping the picture, so the
  family has it).
- Deletes the inbox reference, and the keepsake original when no keepsake document exists.
- Refunds through the ledger's own `settle`: every `avatarCheck`, `avatarCreate` or `avatarPortrait`
  line still `claimed` and over an hour old in that household's month. A run lasts five minutes, so
  such a claim is abandoned. Settling is idempotent, so a second sweep changes nothing.
- A household with a `ready` ending is not refunded: its claim is rightly charged, and a ledger
  line does not name its creation.
- New collection-group index on `avatarCreations` (`status`, `requestedAt`) in
  `firestore.indexes.json`. **It must be live before the function** (runbook step 1).

Registered in `index.ts`, `global_options.test.ts` (141 endpoints) and `writes_are_atomic.test.ts`;
described in `functions/CLAUDE.md`.

Not covered: a request whose trigger never ran at all (no status), and an inbox upload whose
request was never written. Neither can be queried for; both are small and go with the member.

### 3. The frame's composed initial

The report said pill, pin and schedule were DM Sans. The code says otherwise for the pin: the map pin
and every disc of 44 dp and up draw the initial in Fraunces; the *who did it* choice (40 dp), the task
tag (36 dp), the schedule head (28 dp) and the filter pill (26 dp) draw DM Sans semibold. So
`AvatarBitmaps.Size` now says which, and an initial base is composed once in each typeface; each
size is scaled from the one its site uses today. Presets and photos are unchanged. The celebration
keeps Fraunces. `AvatarLayout.INITIAL_SANS` is 0.44 of the disc, the middle of what those four sites
use (0.39 to 0.50).

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | Medium | `avatar_creation.ts` (no retry on a trigger) | A crashed run left the request spinning, its reference in Storage and its claim on the allowance for ever. Privacy v6 says a failed request's photo is deleted. | **Fixed** by the sweep above. |
| 2 | Low | server, frame, app | Nothing held the three sides to one answer; each had hand-written JSON in its own tests. | **Fixed** by the fixture. |
| 3 | Low | `AvatarBitmaps.kt` | Composed initial in Fraunces at four sites that draw DM Sans. | **Fixed.** |
| 4 | Low | my own first draft of the sweep | A `none`-charge line (`avatarCheck`) would have been refunded as a monthly call. | **Fixed before any test ran**: only `allowance` and `none` lines are settled, with their own charge. |
| 5 | Info | `avatar_keepsakes.ts` | In the end-to-end run, deleting a keepsake left the picture and the look. | **Not a bug.** The emulator's canned picture gave the buddy and the drawing the same hash, and the server keeps a picture while another keepsake shares it. Deleting the second one removed the file, emptied `owned.images` and took the look off. |
| 6 | Info | `avatarCreations` | A creation document stays after its keepsake is deleted (status, hash, buddy words; no picture). | **Left.** It goes with the member. Say if the policy's "deletes the creation" should cover the document too. |
| 7 | Info | `notifications_triggers.test.ts` | The quiet-hours failure the server-ai review described. | **Not run, not touched**: outside avatars. |

## End to end on the emulator

No suite was running (port 4400 checked). Started with `npm --prefix functions run emulators`, which
imported `emulator-data/` and seeded. A node script used the Admin SDK and plain HTTP.

| Step | Result |
|---|---|
| Seeded looks | **Pass.** Mia `preset:pip` stage 2 in a crown, Leo `preset:olive` stage 0, Sam `preset:sunny` stage 3 in glasses, Alex `preset:pebble` stage 3 in a cap. |
| Link a frame, `getFrameDay` | **Pass.** Paired and claimed as the seeded parent. Members came back as `nestling-pebble-3` + cap, `nestling-olive-0`, `nestling-pip-2` + crown, `nestling-sunny-3` + glasses; Thandi (no look) had no `avatar`. No member id in the answer. |
| Buddy creation | **Pass.** `ready`, keepsake written, `left: 11`. |
| Drawing creation | **Pass.** `ready`, `left: 10`, inbox empty afterwards. |
| Image base and `getFrameAvatar` | **Pass.** Mia's choice set to the drawing; the look mirrored; the day sent `{image: <hash>}` with the crown; `getFrameAvatar` answered 200 `image/jpeg`, `no-store`, 18 496 bytes whose hash is the id. An unknown hash answered 404. |
| A kid buys an accessory | **Pass.** Mia bought the rugby ball: `owned`, balance 10 → 5, ledger line `accessory`, −5. |
| Delete a keepsake | **Pass, see finding 5.** The keepsake and its request went at once; the shared picture went with the second keepsake. |
| Tidy up | Mia back to Pip and crown; the test frame unlinked. |

Both creations went from no status to `ready` faster than the script's half-second poll, so it did
not see `checking` or `drawing` in between.

**Left in your emulator data** (it was exported on stop): two `ready` creation documents for Mia,
her rugby ball and five fewer stars, and two creations counted in the demo household's November
usage. Delete `emulator-data/` to start clean.

## Checks run

| Check | Result |
|---|---|
| `npm --prefix functions run build` | clean |
| `npm --prefix functions run lint` | clean |
| Unit (`vitest run`) | 155 files, **2897 passed**, 0 failed (10 new: 3 fixture, 7 sweep) |
| `npm --prefix functions run test:rules` | 75 files, **1316 passed**, 0 failed |
| Emulator: `avatar_creations` (19, 3 new), `avatars` (13), `photo_frames` (62), `chore_points` (9) | **103 passed**, 0 failed |
| `flutter analyze --fatal-infos lib test tool` | no issues |
| Full `flutter test` | **6061 passed, 4 skipped, 19 failed.** The 19 are exactly the list in `avatars-app.md`; none is new and none is avatar code. Two of the four skips are the fixture's deliberate ones. |
| Frame `./gradlew :app:testDebugUnitTest` | **132 passed**, 0 failed, 0 skipped (was 128) |
| Frame `./gradlew :app:assembleDebug` | builds |

Not run: the whole emulator suite (only the four avatar-related files), `assembleRelease`, anything
on a phone or a frame, the cloud demo seed.

## The four legal promises

All four hold in the tree; the table with file references is in `tasks/avatars-deploy.md`, step 7.
Hosting can go out once the rules and triggers are live.

## Files

- **New:** `functions/src/avatars/creation_sweep.ts`, `sweep_avatar_creations.ts`;
  `functions/test/unit/avatars/creation_sweep.test.ts`;
  `functions/test/unit/frames/frame_avatars_fixture.test.ts`;
  `functions/test/fixtures/frame_avatars.json`;
  `app/test/features/avatars/model/frame_avatars_fixture_test.dart`;
  `tasks/avatars-deploy.md`.
  In `../NestPrep-Home`: `FrameAvatarFixtureTest.kt`, `app/src/test/resources/frame_avatars.json`.
- **Changed:** `functions/src/index.ts`, `firestore.indexes.json`, `functions/CLAUDE.md`,
  `functions/test/emulator/avatar_creations.test.ts`, `test/unit/global_options.test.ts`,
  `test/unit/writes_are_atomic.test.ts`, `tasks/todo.md`.
  In `../NestPrep-Home`: `AvatarBitmaps.kt`, `AvatarLayout.kt`, `MainActivity.kt` (one argument),
  `CLAUDE.md` (one clause).

## Left for Daniel

1. **Deploy** by `tasks/avatars-deploy.md`. Two things to settle first: the rules deploy ships other
   sessions' partials too, and the new index must be enabled before the sweep.
2. **Vertex image quota** for `gemini-3.1-flash-image` on `global`, before `avatarCreations` goes on.
3. **Godfather** needs, from this review: the sweep and its index (ADR-0003), the shared fixture and
   how to rewrite it (C-0023), and the per-site typeface of the composed initial (NestPrep-Home
   ADR-0022). The header comment in the fixture test says the same.
4. **Still open from the earlier reports:** a look at the art; the "all 12" copy for a household out
   of tries; a real phone and both frames; real children's drawings through the filter; whether a
   plain leave should take the avatar with it.
5. **The frame has not been seen with the new initials.** The typeface change is covered by the build
   and the existing tests only; `AvatarSheetTest` draws its sheet with Java fonts, not the frame's.
