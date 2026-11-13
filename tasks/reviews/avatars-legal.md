# Avatars review — legal

Reviewed the avatar text only in `app/assets/legal/privacy-policy.md` (v6) and `terms-of-service.md` (v4), against `functions/src/avatars/*`, the rules partials, `tasks/avatars-spec.md` and avatars ADR-0001/3/4/5/6. The other session's v5/v3 text (recipes, PDFs, TypeSafe, calendar Limited Use) is untouched. Versions stay 6 and 4: nothing has shipped at those numbers.

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | High | privacy-policy.md:66, :248 | Photo retention said earlier photos stay "so they can be chosen again" until the member leaves. Daniel's decision is that a replaced or removed photo is deleted by the server. | **Fixed.** "We keep the photo until it is changed or removed, and then delete it", and section 9 says the same. |
| 2 | High | privacy-policy.md:248 | "When a member leaves a household … their avatar photos, creations and keepsakes are deleted" is untrue for a plain leave: `functions/src/household/leave_household.ts` keeps the profile, its `look` and its pictures. Only `removeMember` and account erasure (`leave_erasing.ts:72,83`) delete them. | **Fixed in the text**, to match the code: deleted when a member is removed or deletes their account; on a plain leave the profile keeps its avatar until the family removes it. Not changed in code: it is a product choice (see Daniel, 1). |
| 3 | Medium | privacy-policy.md:163, :169 | Nothing said what happens to a reference that is refused or whose creation fails, so a refused photo of a person had no stated end. | **Fixed.** A refused photo "is deleted", and a refused or failed request's drawing or photo is deleted. This is a commitment on Phase 4 (see Daniel, 2). |
| 4 | Medium | privacy-policy.md:164, :229 | "Drawings of creatures, objects and toys" misread ADR-0003: a toy is a *photo* (`photo-of-toy`). | **Fixed** in both places: drawings of creatures and objects, photos of toys and pets. |
| 5 | Medium | terms-of-service.md:60 | "never a picture of another person" and "refuse … when the picture shows a person" contradict the policy: a *drawing* of a person is accepted and turned into words; any *photo* of a person is refused, your own included. | **Fixed.** "never a photo of a person"; "when a photo shows a person". |
| 6 | Low | privacy-policy.md:164 | "Google offers it in no single region" claims more than was measured (three regions answer 404 for this project). | **Fixed.** "Google does not offer it to us in a single region". |
| 7 | Low | privacy-policy.md:170, terms :60 | "A free household can make one creation" reads as one a month; the allowance is one ever. The terms said only "monthly limits". | **Fixed.** "one creation in all" in the policy, and the same sentence added to the terms. |
| 8 | Low | privacy-policy.md:208 | "Everybody in the household, children included" left out helpers and carers, who read avatars and keepsakes too (`isInHousehold`), while the next sentence says they see only granted areas. | **Fixed.** Helpers and carers named. |
| 9 | Low | privacy-policy.md:203 | A kid device can upload a photo of itself with no parent step (storage `avatarsActsFor`, `kids` map); the children's section did not say so. | **Fixed.** "can change their own avatar, a photo included". |
| 10 | Low | privacy-policy.md:232 | "each creation is one you chose to make": a child may have asked for it. | **Fixed.** "one your household chose to make". |
| 11 | Low | privacy-policy.md:248 | "A deleted avatar keepsake removes both…" was clumsy. | **Fixed.** "Deleting an avatar keepsake deletes both the creation and its original." |
| 12 | — | privacy-policy.md:66 | EXIF claim checked: `JpegCompressor` clears EXIF (`jpeg_compressor.dart:93`), 512 px, picker asks for no full metadata. | Accurate, no change. |
| 13 | — | AI section | EU check first, person drawing reduced to words, photo of a person refused, photo avatars never sent, portrait from characters and creations, keepsakes until deleted, album copy, counts without content: all match ADR-0003/5/6. | Accurate, no change. |
| 14 | — | "until the family deletes them" | A kid can also delete their own keepsake (ADR-0005). | **Rejected:** "the family" reads naturally as the household here and is not narrower in effect. |
| 15 | — | Godfather note on accounts | Its "Deviation to know" described the old photo retention. | **Fixed:** replaced with what the text commits the server to (imported, 1 updated, 0 conflicts). |

## Checks run

- `npm --prefix functions run site:build`: `hosting/public` built, 28 files.
- `npx vitest run test/unit/site_is_generated.test.ts`: 86 passed of 86.
- `flutter test test/features/legal` (development SDK): 50 passed of 50.

Nothing committed or deployed.

## Left for Daniel

The policy now promises four things the code does not yet do. Hosting must not go out with v6 until they hold:

1. **Plain leave keeps the avatar.** The text says so because `leaveHousehold` does. If you would rather a leaving member's photo went with them, add the prefix delete and `look` clear to `leaveHousehold` and change the last sentence of the avatar part of section 9.
2. **Refused and failed references are deleted.** Phase 4's trigger must delete the inbox file on `refused` and `failed`.
3. **Photo avatars are deleted when changed or removed.** The server delete you decided on, being built next. The Photo tab still lists earlier photos from `owned.images`.
4. **Keepsake and creation documents go with the member.** `removeMember` and `leaveErasing` delete the Storage prefix and `memberAvatars` today; `avatarKeepsakes` and `avatarCreations` documents by `memberId` are Phase 4's to add.

Two judgement calls:

- **No off switch for children's AI creations.** Section 4 says consent is withdrawn "by turning the feature off". The star shop has a household switch; creations have none, and a kid device can start one without a parent. A parent's consent on the child profile covers it as written, but a household switch would make that sentence true for this feature.
- **Storage `avatarsActsFor` admits a role `member`** alongside admin and parent (`rules/storage/paths/avatars.rules`), while the policy says family is an admin or a parent. It is the rules reviewer's to judge; noted in case that role is real.
