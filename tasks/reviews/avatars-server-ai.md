# Avatars — server-ai review (phases 4–5 and review follow-ups)

Reviewed 2026-11-13 against `tasks/avatars-spec.md`, avatars ADR-0003, the `ALLOW_NONE` lesson, `tools/avatar-spike/spike.py` and the root and `functions/` `CLAUDE.md`.

**Verdict:** the build is sound. One real robustness bug was fixed (item a), plus three smaller hardenings. The failing notifications test is not avatars. Nothing was committed, pushed or deployed.

## Findings

### Fixed

| # | Severity | Where | Finding | Fix |
|---|---|---|---|---|
| 1 | **High** | `functions/src/ai/usage_rules.ts` (`decideCharge`), `firestore_usage_ledger.ts`, `ai_settings.ts` | Every `avatarCheck` and every creation counted in the household's shared `attempts`, and was refused at the shared ceiling (30 free, 300 premium). A child sending refused photos could close school letters, list scans and the week plan for the month. | Creations and their checks now count in `aiUsage/{month}.allowanceAttempts.avatarCreate`, never in `attempts`, and are bounded only by their own ceiling: nine calls for each creation the tier may make (9 a month free, 108 premium). The separation works both ways: other features' failures no longer close creations. |
| 2 | Medium | `functions/src/avatars/avatar_creation.ts` (`gateCreation`) | With a ceiling per call, a picture could be drawn and then lost at its last check. | A request is refused `limitReached` before anything is spent once fewer than three attempts are left. `left` still reports what the allowance holds. |
| 3 | Medium | `avatar_creation.ts` (`settleAvatarCreation`) | The inbox reference was deleted inside `finish`, after its transaction. If that transaction threw, the reference stayed in Storage. | The delete is now in a `finally` around `finish`. |
| 4 | Low | `avatar_creation.ts` (`keep`) | A member removed while their creation was being drawn got a keepsake, a new `memberAvatars` document and files written after `removeMember` had cleaned up. | The keep transaction reads the member and throws when they are gone; the files are taken back and the allowance refunded. |
| 5 | Low | `functions/src/avatars/avatar_prompts.ts` (`fromBuddy`, `fromWords`) | The measured spike prompts carried "Not based on any existing cartoon, film, game or brand character" in the prompt. The build moved it to the system instruction only, which the spike never measured. | The sentence is back inline in both prompts; the system instruction stays as well. |
| 6 | Low | `avatar_creation.ts` (`referencePicture`, new) | No test showed the production path sends no image for a person drawing; only `fromWords` was tested alone. | The decision is one exported pure function that `plan` calls. Tests assert a drawing of a person yields a request with no parts and none of the reference's bytes, and that a photo of a person yields nothing for either recipe. |
| 7 | Low | Godfather | C-0023's summary still said rev 18; ADR-0003 said checks count against the shared ceiling. | C-0023 summary now names rev 19 (body unchanged, verified by read-back). ADR-0003 is rev 4 with the new ceiling. `functions/CLAUDE.md` says the same. |

### Checked and found right

- **Privacy:**
  - A photo of a person is refused for both recipes, and the inbox is deleted on refused, failed and ready (emulator tests assert the member's prefix is empty).
  - Photo avatars are deleted once not worn, and creations kept as keepsakes.
  - Keepsakes, creation requests and the Storage prefix go with a removed member and with a deleted account, and both collections are in the export.
  - The portrait sends a Nestling of the member's colour for anyone wearing a photo, the initial or nothing; only a base that matches the member's own keepsake is read from Storage.
- **Idempotency and charging:**
  - Only the run that moves a request out of no status works.
  - The allowance is claimed around the draw, the result check and the keep together, and refunded on blocked, failed, an unclean result and a keep that throws.
  - `left` comes from the claim, so it is never stale.
- **Prompts:** the drawing prompt is the measured `TRANSFORM` wording with the member's light fill; every request is `ALLOW_NONE`; the reference check asks for "the colours used for hair" and clothes, as the lesson requires; a buddy's extra words are checked and stripped to plain characters; reading fields are stripped the same way before they reach a prompt.
- **Rules:** exact create shapes per recipe, the portrait for family only and in their own name, kid devices for their own child only, both household switches family-only and boolean. Each has denied tests.
- **Frame rev 19** (`frame_avatar.ts`): `{initial: true}` only when the look exists with a null base; never a `face` layer on it.

### Not avatars: the failing `notifications_triggers` test

"a shift summary written pending reaches the family" fails at line 40 because the pushes stay `pending`. The delivery runs on the real clock, and default quiet hours are 21:00 to 06:00 household time; I ran it at 00:35 SAST. It will pass in daytime. Avatars added two constants to `push_text.ts` and a new file (`avatar_delivery.ts`); neither touches dispatch. I left the test alone because it is outside avatar work. The fix is one line: give Sam and Pat `givenSettings(…, { quiet: null })` in that test.

### Rejected

- **A per-member daily limit instead of a monthly ceiling.** The monthly ceiling fits the ledger as it is and needs no new document. The cost is that one child can use up the household's tries for the month.
- **Guarding the rollback in `keep` against deleting an identical earlier picture.** It needs two creations with byte-identical JPEGs, which only the emulator's canned picture produces.

## Checks run

| Check | Result |
|---|---|
| `npm run build` | clean |
| `npm run lint` | clean |
| Unit (`vitest run`) | 153 files, **2889 passed**, 0 failed |
| `npm run test:rules` | 75 files, **1316 passed**, 0 failed; `rules:check` up to date |
| Emulator: `avatar_creations` (16), `avatars` (13), `photo_frames` (62), `notifications` (13), `notifications_triggers` (5), plus the AI-ledger suites `list_scan`, `school_letter`, `lunch_photo`, `jev_decisions`, `own_recipes` | 10 files, **183 passed, 1 failed** (the quiet-hours test above). No other suite was running. |
| Live smoke, one call | The Function's own request body for a creature drawing (system instruction, JPEG output, `ALLOW_NONE`, pink fill) against `gemini-3.1-flash-image` on `global`: 200 in 10.6 s, a faithful plush of a synthetic three-eyed monster on the pink fill, 117 KB JPEG. This confirms the image model accepts `systemInstruction`, which the spike had not measured. |
| Godfather lint (avatars node) | 0 errors, 3 warnings |

New tests: the attempt ceiling in `ai_settings_and_usage.test.ts`, the gate and `referencePicture` in `avatar_creation.test.ts`, and an emulator test where seven refused photos close creations with `limitReached` while `attempts` and `calls` stay untouched.

## Left for Daniel

1. **Copy for the new `limitReached` case.** The app says "That's all 12 for this month" for `limitReached`. A household that ran out of tries rather than creations sees the same line, and a free household sees it too. "Make more from next month" is true; "all 12" is not. A separate line is app work.
2. **A crashed run leaves its request at `checking` or `drawing` and its inbox file in Storage.** Triggers do not retry here. The app should time out, and an hourly sweep of `avatars/*/inbox/` older than an hour would close the gap; an upload whose request was never written has the same gap. I did not build the sweep: the object store has no way to list across households yet.
3. **The quiet-hours test** above, if you want it fixed.
4. **Godfather:** my session log landed as a new "Session log" document on the avatars node (there was no active session), which lint flags as an orphan. The other two warnings (overview not verified, not indexed) were there before.
5. **Real drawings.** The lesson's open item stands: the describe-then-draw path is measured on generated drawings only.
