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
