# Kid routines — plan (2026-11-13), phase 1 built 2026-11-14

Status: Daniel took all five proposals on 2026-11-14 (kid-routines ADR-0001, accepted). Godfather: the `kid-routines` feature node.

## Progress

Everything ticked is built and tested in the tree. **Live since 2026-11-14** (rules, `awardRoutineStars`, `exportAccountData`, flag on; release build on Daniel's iPhone). **Not committed.**

### Phase 1 — model, rules, stars, parent setup
- [x] Godfather: feature node, ADR-0001, overview, work-index row
- [x] Rules partial `kid_routines.rules` + 25 allowed and denied cases; `firestore.rules` rebuilt
- [x] Flag `kidRoutines` in both lists
- [x] `awardRoutineStars` + ledger kinds `routine` / `routineUndone`; unit and 8 emulator tests
- [x] App: model, repository, controller, Routines screen, routine sheet, step sheet, ready-made starts, the way in from Chores; 35 tests; pictures in `app/design-review/kid-routines/`
- [x] A demo routine in the emulator seed (not run against a suite)
- [ ] Daniel looks at it on the emulator: To do → Chores → Routines
- [ ] Repository integration test against the emulator suite (needs a device)
- [x] Deployed rules, `awardRoutineStars` and `exportAccountData`; `kidRoutines: true` in `appConfig/flags` (2026-11-14)
- [x] Committed `70f8cd7` on master, not pushed

### Phase 2 — kid home card and the player
- [x] `watchRoutinesFor` a kid (`kidIds array-contains`), `watchTicks` and `saveTick`. No index: the ticks read is two equalities (`kidId`, `occurrenceDate`), which Firestore answers from the single-field indexes
- [x] `KidRoutineDayController`, following the home's today, grant and the flag
- [x] The routine card on the kid home, above the jobs; the one-step-at-a-time player with things to remember, the path, untick, a star burst per step and `NestCelebration` at the end
- [x] Tests: run model 9, card and player 11, kid home 2; pictures `kid-card-*` and `player-*`
- [ ] On a kid device against the cloud: a tick lands, `awardRoutineStars` gives the stars
- [ ] Parents see today's progress per child on the Chores lens (not built)

### Phase 3 — the frame
- [ ] photo-frames ADR, C-0023 rev 21, `getFrameDay` routines, `tickFrameItem` kind `kidRoutine`
- [ ] NestPrep-Home: the player, Home and Chores entry points, larger stickers

Changed from the proposal below: `finishBy` is minutes since midnight, not `HH:mm`; the ticks index waits for phase 2's query.

## What it is

A parent sets up a morning, afternoon and bedtime routine per child: an ordered run of picture steps
(get dressed, eat breakfast, brush teeth, pack bag, shoes on). The child works through it on the wall
frame, or on their kid profile in the app, one big picture at a time.

## What exists and why none of it is this

| | Todos "routine" | Helper room routine | Needed |
|---|---|---|---|
| Shape | a shared schedule; each task is its own document | one document with ordered `items[]` | one document, ordered steps |
| Step picture | per task (`picture`) | none | per step |
| Detail under a step | task note | none | a pack list ("what goes in the bag") |
| Time of day | none | none | morning / afternoon / bedtime |
| Tick | one doc per task per day | one doc per routine per day, `doneItemIds` | one doc per routine, per child, per day |
| Stars, Nestling | yes | no | yes |
| Area grant | `todos` (kid default `own`) | `homeCare` (kid default `none`) | `todos` |
| Frame | Chores screen, kind `task` | helper column, kind `routine` | its own player |

So: the helper routine's document and tick shape, on the todos grant, with the chore pictures, stars
and celebrations.

## Model (proposed)

`households/{h}/kidRoutines/{routineId}`

- `name` — "Morning", editable
- `slot` — `morning` | `afternoon` | `bedtime`; drives the icon, the colour of the header, the default
  window and which routine the frame offers now
- `kidIds` — 1..n kid profiles (see decision 1)
- `firstDate`, `recurrence` — the shared `RecurrenceRule` (foundation ADR-0005). The editor offers
  School days / Every day / Weekends / pick days
- `finishBy` — optional `HH:mm` on the household clock ("out the door by 07:15")
- `points` — stars for finishing the whole routine, 0..20 (see decision 2)
- `steps` — 1..12, ordered:
  - `id`, `title` (≤ 40), `picture` (sticker id, the task regex), `note` (optional, ≤ 120)
  - `parts` — optional pack list, 0..8 of `{id, text, picture?, weekdays?}`; `weekdays` lets
    "swimming kit" show on Wednesdays only
  - `minutes` — optional, for the timer ring (phase 3)
- `createdBy`, `createdAt`

`households/{h}/kidRoutineTicks/{routineId}_{kidId}_{date}`

- `routineId`, `kidId`, `occurrenceDate`, `doneStepIds`, `updatedBy`, `updatedAt`
- derived id, so a repeat tick is the same write; one windowed listener answers "what is done today"
  (todos ADR-0002's argument)

Stars: a Function trigger on the tick awards `points` once when every current step is done, through
the existing `stageLine` ledger (entry id `routine_<tickId>`), so the balance, the streak and the
Nestling's `look.stage` move exactly as they do for a chore. Unticking withdraws, as a chore does.
Same guards as `decideClaim`: a real occurrence, not in the future, at most 7 days back, a kid.

Rules: new partial `rules/firestore/household/kid_routines.rules`, on the `todos` area.

- routines: family with `todos` edit write; a kid with `own` reads only routines naming them
- ticks: id must match its fields; `kidId` must be in the routine's `kidIds`; `doneStepIds` no longer
  than the steps; a kid ticks only their own; family ticks for any child
- stars set by family only, as for chores
- every rule with a denied case; composite index `kidRoutineTicks (kidId ASC, occurrenceDate ASC)`
  declared and deployed before the Functions (the frame lesson)

Flag `kidRoutines`, in both lists. Free on every plan.

## Parent setup (app)

- Entry: the Chores lens, beside Stars and rewards; and each child's family profile
- Pick a child, see three slots. An empty slot offers a starter set the parent can take as is:
  - Morning: wake up, get dressed, eat breakfast, brush teeth, pack school bag, shoes on
  - Afternoon: empty lunchbox, healthy snack, homework, play outside, tidy toys
  - Bedtime: bath, pyjamas, brush teeth, story, lights off
  - every one of these already has a sticker in the 200-picture library
- Editing: the helper `StepsEditor`, plus a picture per step (`ChorePictureField`, suggestions from
  the title), drag to reorder, a pack list under a step
- "Copy to another child", and a preview that plays the routine as the child will see it

## The child's side

On the frame (the main stage):

- When a slot's window is open and a routine is not finished, Home leads with it: each child's
  avatar, a ring, "Mia's morning". The Chores screen shows it above that child's chores
- Tap it: the routine player, full screen. One step at a time: the sticker large, the word under it,
  one big Done button, a peek of what is next, the path of all the steps along the bottom
- A step with a pack list shows its things as picture chips to tap off
- Each Done: an instant small cheer (star pop, the step's sticker flies to the path). The last one:
  the full `CelebrationView` act with the child's Nestling and the stars
- Two children side by side in landscape, each on their own half
- `finishBy` shows a calm countdown ring, never red

In the app (kid profile): the same routine card at the top of the kid home for the current slot,
opening the same player in Flutter, with `NestCelebration` at the end.

Parents see today's progress per child on the Chores lens.

## Frame contract: C-0023 rev 21 (additive)

- `getFrameDay` gains a top-level `routines` (not inside `todos`, so a frame that predates it draws
  nothing instead of an odd chore): per routine and child — opaque id, name, slot, who (first name),
  date, stars, `finishBy`, steps with `picture`, `note`, `parts`, `done`
- `tickFrameItem` gains `kind: 'kidRoutine'`, with `by` and `step`, writing the app's own tick
  document; ticks only what the frame shows
- shown when the frame's chores are shown; no new switch unless Daniel wants one
- the player needs the stickers larger than the 192 px the frame bundles: either ship the 384 px set
  (about +5 MB on a 3.6 MB APK) or only the ~70 routine pictures

## Where it beats Skylight

| Skylight Calendar | NestPrep |
|---|---|
| a list of emoji rows | one big picture at a time, a path of steps |
| emoji only | 200 drawn stickers in one style |
| celebration only when the whole list is done | a cheer per step, a character act at the end |
| nothing under a task | a pack list per step, by weekday |
| no deadline | finish-by ring |
| stars and rewards behind Plus | free |
| one-step mode only on a separate device (Buddy) | on the wall and in the app |
| no character | the child's own Nestling grows with streaks |

## Phases

1. Model, rules, flag, Functions trigger, parent setup, starter sets — app only, on the emulator
2. Kid home card and the Flutter player
3. Frame: rev 21 on the server, the player in NestPrep-Home, Home and Chores entry points
4. Later, each its own call: step timers, read-aloud (needs a text-to-speech check on the Android 6
   frames), a first/then view for the under-fives, a step photo taken by the parent

## Decisions for Daniel

1. One routine shared by several children (`kidIds`, a tick per child), or strictly one child per
   routine with "copy to". Proposed: shared, because siblings mostly run the same morning
2. Stars for finishing the routine, not per step, and no parent check. Proposed: yes — a check at
   06:45 is friction, and per-step stars turn a habit into a price list
3. Free, like chores. Proposed: yes
4. Own photos on a step (the child's actual bag): todos ADR-0005 rejected uploads for chore
   pictures, and children's data is a named risk. Proposed: not in the first version
5. The word: this is the third thing called a routine (todos bundles, room routines). Proposed:
   these are "Routines" to the family; the todos bundle is renamed in the UI later

## Not checked

- Whether verdict 003 covers this; it reads as an addition at Daniel's request, like the frame
- Text-to-speech on the Android 6 frames
- Skylight on a real device: the teardown is from its help centre and reviews
