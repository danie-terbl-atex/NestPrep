# Avatars — server review (phases 1, 2 server half, 3)

Reviewed 2026-11-12 against `tasks/avatars-spec.md`, the plan, avatars ADR-0001 and ADR-0004 and the overview (read through the Godfather MCP server), and the app and frame counterparts where the sides must agree.

**Verdict:** the server work is sound. Three things were fixed, one of them a real bug on the app side of the contract. Nothing was committed, pushed, deployed or seeded to the cloud.

## Findings

### Fixed

| # | Severity | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | **High** | `app/lib/features/avatars/data/firestore_avatar_repository.dart:61` (`offerPhoto`) | The app offered a photo with a whole-document `set`. On any `memberAvatars` document that already has `owned` (after a first photo or a first purchase), that drops `owned`, and the rule rightly denies it. So a member's second photo, or a first photo after buying an accessory, was refused. `choose` beside it already merged. | `SetOptions(mergeFields: ['choice', 'pendingPhoto', 'updatedBy', 'updatedAt'])`. This is one line in the app portion; I made it because it is where the rules and the app disagreed. New rules test at `functions/test/rules/avatars.rules.test.ts:250` shows the whole-document write denied and the merged one allowed. |
| 2 | Medium | `functions/src/avatars/member_avatar.ts:77` | Race between two photo offers. The trigger checks the photo in Storage before its transaction. If a second `pendingPhoto` landed in between, the transaction saw a hash it had not checked, called it refused and deleted it, so the second photo was lost with no run left to take it. | The transaction settles a pending photo only when it is the one it looked at; a later one is left for its own event. New emulator test "takes the later of two photos offered one straight after the other". |
| 3 | Medium | `functions/test/unit/avatars/avatar_moments_fixture.test.ts` (new) | The plan requires a contract test holding Dart and TS to the same moment dates. `app/test/fixtures/avatar_moments.json` says it is shared with the Functions' tests, but only the Dart test read it. | New test runs the fixture's 34 cases, its Easter dates, hemispheres and stage rows through `layersOn`, `easterSunday`, `hemisphereOf` and `starStage`. All 106 pass, so the two sides agree today. |

### The build agent's deviations

| Deviation | Ruling | Why |
|---|---|---|
| Extra member-doc read in `readBalance` (ADR-0004 says "no extra read") | **Accepted** | Without it `stageLine` cannot know whether the member has a look, and an unconditional `'look.stage'` update would create a malformed `look: {stage}` on every kid with none. The read also lets the stage be compared with the stored one, which is what makes "never goes down" hold. It rides the same `getAll` as the balance. Cost: a star transaction now retries if the member document changes under it. ADR-0001 and ADR-0004 should say this. |
| `avatarShop` on the household document | **Accepted** | The spec allows it when no settings document exists. The rule is its own branch (`isSwitchingTheAvatarShop`): family only, that key only, boolean only, with denied tests for kid, kid device, helper, stranger and a non-boolean. |
| Buying a free accessory is refused `alreadyOwned` | **Accepted** | A free one is everybody's already; no other reason in the spec fits better, and no stars move. |
| Kid stage 1 when `earned >= 1` **or** any streak | **Accepted** | Unticking can take `earned` back to 0 while `bestStreak` stays. Every chore line carries `earnedOn`, so `earned >= 1` implies `bestStreak >= 1` and the stage recomputed by the mirror never drops. Dart's `AvatarStage.forStars` is the same, and the shared fixture now checks both. |
| Members whose look is the initial get no frame avatar, so no birthday hat | **Accepted as built; a product call for Daniel** | See below. |
| Seeded stars lines (`earnStars`) | **Accepted** | Emulator only: the demo household has no chores, and the lines go through `readBalance` and `stageLine`, so balances and stages read as real ones. The cloud seed does not call it. |

**The birthday hat on an initial.** I did not change the contract, for three reasons:
- **The phone does the same for a member with no look.** `ResolvedAvatar.of` returns the plain initial when `look` is null, with no moments. Sending hats for look-less members would make the frame differ from the phone.
- **It would break "flag off behaves exactly as today".** `getFrameDay` does not read the `avatars` flag, so every household's frame would start showing hats on birthdays.
- **The frame cannot draw it yet.** `FrameAvatar.from` returns null without a `base` object, so `base: null` with layers is safe on every frame, old and new, but nothing would be drawn. Drawing layers over a hand-drawn initial is frame work on about 15 surfaces.

One gap remains: a member who chose the initial *and* wears something has `look.base: null`. The phone draws the hat on the initial; the frame draws the plain initial. If Daniel wants hats on initials, it is a three-line server change (`base: null` plus layers when the look exists), a C-0023 revision, and frame work to compose an initial disc.

### Checked and found right

- **Rules, clients never write what is the Functions':** `owned` (create key list, `changedKeys` on update), `look` (absent from the member create list and from `onlyChanged` on update, admin included), the purchase outcome (exactly four keys, no update or delete), ledger lines, keepsakes. Each has a denied test.
- **Who may write a choice:** family for anyone, a member for themselves, a kid device for its own child only. A helper or kid on someone else, a stranger, a non-member id, a forged `updatedBy` and a client timestamp are each denied and tested.
- **Storage:** JPEG only, 512 KB for a photo and 2 MB for the inbox, hash-named, stamped, create-only, never listed. The `member` role in `avatarsActsFor` is the legacy family role, the same as Firestore's `isFamily`.
- **No member id reaches the frame:** `avatar` carries a bundled asset id or a content hash and layer ids. `getFrameAvatar` serves a hash only while it is a current member's `look.base`, at 60 an hour per credential, through `frameJpegEndpoint` (`no-store`, same status words).
- **Trigger loops:** `settleMemberAvatar` re-reads everything and writes nothing when the look is already mirrored, so its own write wakes it once and stops (emulator test asserts the document's `updateTime` does not move). The purchase's `owned` write wakes the mirror, which finds nothing to do.
- **Transactions read before they write:** purchase (purchase, household, member, avatar, balance, then writes) and the mirror (`getAll`, then writes). A retried purchase finds `status` and writes nothing; the ledger id is `accessory_<purchaseId>`.
- **Leaving:** `removeMember` deletes `memberAvatars` in its transaction and the Storage prefix after; erasing an account clears `look`, the document and the prefix; ending a household covers the prefix. Emulator tests cover the first two.
- **Face rule:** the server allows a `face` accessory only on a Nestling base and drops it from the frame's layers on an image. Whether a particular Nestling picture has an anchor is the drawer's business (`NESTLING_FACES` and `AvatarFaces`), so the server needs nothing more. A face worn on an egg stays in `look.wear` and appears when the egg hatches.
- **Hemisphere lists** in TS and Dart are identical; 29 February birthdays fall on the 28th on both sides.

### Rejected

- **Gate the triggers on the `avatars` flag.** No trigger in this codebase reads a flag; the client hides the feature. Rules still shape every write.
- **Rate-limit purchases and uploads.** A client can create purchase documents or hash-named photos without limit, as with reward requests and other uploads here. Each is rules-shaped and small. Noted below.
- **Header doc comments in the new files.** They match every other file in `functions/src`; I followed the codebase rather than strip them.

## Checks run

| Check | Result |
|---|---|
| `npm --prefix functions run build` | clean |
| `npm --prefix functions run lint` (eslint and prettier) | clean |
| Unit (`vitest run test/unit`) | 151 files, **2838 passed**, 0 failed. An earlier run had one failure, `site_is_generated` (privacy page out of date, not avatar work); it passed on the final run after another session rebuilt the site. |
| `npm --prefix functions run test:rules` | 75 files, **1306 passed**, 0 failed |
| `rules:check` | both generated rules files up to date |
| Emulator: `avatars`, `photo_frames`, `chore_points` | 3 files, **82 passed** (11, 62, 9), 0 failed. No other suite was running (checked port 4400 before each start). |
| `flutter analyze --fatal-infos lib/features/avatars/data` | no issues (only the one file I touched; the full app run is the app reviewer's) |

The cloud demo seed was not run.

## Left for Daniel

1. **Hats on initials** (above): keep as built, or ask for the frame work.
2. **Godfather is behind the code.** The avatars overview still says "Nothing built" and phases 1–3 "not started"; ADR-0001 and ADR-0004 still say "no extra read" and list no `notAKid` reason. I did not write to Godfather from this review. The write-back should record: the member read in `readBalance`, `avatarShop` on the household document, `notAKid`, the stage rule with `bestStreak >= 1`, and that a base-null look sends no frame avatar.
3. **The birthday hat shows a birthday on the wall.** The frame's day never used birthdays before; now a member with a picture wears a hat on theirs. Probably wanted, but it is new.
4. **Old photos are never deleted** while the member stays. `owned.images` and the Storage folder only grow, 512 KB at most each. A cap or a sweep is worth a thought before wide release, together with the unlimited uploads noted above.
5. **A purchase whose trigger fails stays without a status.** Triggers do not retry here, so the app should time out rather than wait for ever. Worth confirming with the app review.
6. **Deploy order** from the plan stands: rules, then `onMemberAvatarWritten` and `onAvatarPurchase`, then `getFrameDay` and `getFrameAvatar`, then the app, then the frame.
