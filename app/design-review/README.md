# Design review — every screen, both themes

Forty pictures of NestPrep, taken from the real widgets with the real theme, the real fonts and the
real logo. **All of them were retaken on 2026-09-29, when the app moved onto Daniel's logo**
(design-system ADR-0003: forest green acts, teal selects, cream pages, Nunito headings, the nest as
the mark).
They exist so the one thing v1 still needs — **an opinion on whether this direction is right** — does
not have to wait for a working Android emulator.

Take them at 390×844, the size of an ordinary phone, at 2× so the type is sharp. The kids' eight
are a press of their own — `flutter test tool/kid_design_review_test.dart --update-goldens` — sharing
the same shutter (`tool/design_review_press.dart`). The parent's stars and rewards are another —
`flutter test tool/chore_points_design_review_test.dart --update-goldens` (todos ADR-0003).
The nanny hub's eleven are `tool/nanny_design_review_test.dart`.

Five presses share one shutter: `design_review_test.dart` (the tabs and the way in),
`kid_design_review_test.dart`, `family_design_review_test.dart`, `household_access_review_test.dart`
and `brand_design_review_test.dart` (the launch screen and a first-run empty state). The shutter
decodes every image for real before it fires; without that the nest is a blank box.

| File | What it shows |
|---|---|
| `week-light.png` / `week-dark.png` | the family week: the seven-day strip, today, and the day's agenda in member colours |
| `todos-mine-light.png` / `todos-mine-dark.png` | what one person is being asked to do, overdue first |
| `todos-everyone-light.png` / `todos-everyone-dark.png` | the whole household's list, the member filter and the routines |
| `groceries-light.png` / `groceries-dark.png` | the one list, with something already ticked |
| `meals-light.png` / `meals-dark.png` | the week's twenty-one slots, some filled |
| `launch-light.png` / `launch-dark.png` | what the native splash hands over to while the session is read: the nest at the splash's size, the words, one pulsing bar |
| `sign-in-light.png` / `sign-in-dark.png` | the first screen anybody sees: the logo's nest with the household's five member marks circling it, the wordmark, the tagline, and the way in |
| `household-gate-light.png` / `household-gate-dark.png` | the screen after it: the nest and wordmark, the question, then making or joining a household |
| `groceries-empty-light.png` / `groceries-empty-dark.png` | a new household's first list — a first-run empty state drawn with the nest |
| `week-dark-200-percent-text.png` | the same week at the largest text a phone offers |
| `beta-numbers-light.png` / `beta-numbers-dark.png` | Daniel's readout during the beta: this week's three numbers, then earlier weeks side by side (product-analytics ADR-0001) |
| `kid-code-light.png` / `kid-code-dark.png` | a child's way in: a hello, six big letter tiles half typed, and one button (accounts ADR-0003) |
| `kid-home-light.png` / `kid-home-dark.png` | the only screen a kid device has: their colour and name, how far through today's jobs they are, their stars (with the line a celebration leaves and a streak), the jobs as big tiles each saying what it is worth, then — below the fold — the treat shelf and today's food (todos ADR-0003) |
| `stars-and-rewards-light.png` / `stars-and-rewards-dark.png` | a parent's stars and rewards: a chore waiting for a look, a treat to hand over, a child's stars and streak, and the shelf's header (todos ADR-0003) |
| `kids-sign-in-light.png` / `kids-sign-in-dark.png` | the parent's side: each child, the devices they are signed in on, add one or sign them all out |
| `kids-pairing-light.png` / `kids-pairing-dark.png` | the code a parent reads out, counting down its ten minutes |
| `family-light.png` / `family-dark.png` | family profiles: children first, each with their allergies in their severity's tone and the nut-free rule, then everyone else and the household's schools |
| `family-profile-light.png` / `family-profile-dark.png` | one child's profile: the severe-allergy banner, the nut-free rule with its reasons, then allergies, food and the rest below the fold |
| `family-profile-dark-200-percent-text.png` | the same profile at the largest text a phone offers |
| `nanny-hub-light.png` / `nanny-hub-dark.png` | the nanny hub as a carer finds it: start the shift, the latest handover, each child with a severe allergy named before the card is opened, and the places a shift needs (nanny-hub ADR-0003) |
| `nanny-shift-light.png` / `nanny-shift-dark.png` | shift mode: who is on since when, seven big tiles for what happened, this part of the evening's checklist half ticked, and the log so far (nanny-hub ADR-0002) |
| `nanny-shift-dark-200-percent-text.png` | shift mode at the largest text a phone offers — one tile to a row, so no word breaks |
| `nanny-child-card-light.png` / `nanny-child-card-dark.png` | a child's card: allergies in their severity's tone first, then medication with its times, then the routine |
| `nanny-emergency-light.png` / `nanny-emergency-dark.png` | the emergency sheet: 10111, 10177 and 112 as big buttons, the address to read out, the medical aid, and a call button on every contact |
| `nanny-handover-light.png` / `nanny-handover-dark.png` | a finished shift's summary for the parents: the incident called out first, the counts, the carer's last word, the checklist, then the evening moment by moment |

## What to look at

The design system is tokens, not screens: colours in `lib/design/tokens/nest_colors.dart`, the type
family in `nest_typography.dart`, the shape of a button in `primitives/nest_button.dart`. A verdict
of "too purple" or "too round" changes one file, not fifteen screens. That is the question worth
answering here — the direction, not any single screen.

**The two way-in screens move, and a still cannot show it.** They are choreographed: the mark, then
the rings, then each thing in orbit, then the name, then the tagline typing itself out, then the
button — once, in about a second and a half, and then the screen is still. These are pictures of the
end of that. The deliberate choice behind them is in design-system ADR-0002: the app this was drawn
from drifts forever and ours stops, and the honest question to bring back is whether stopping leaves
it too quiet.

## A starting point for the verdict

[ASSESSMENT.md](ASSESSMENT.md) is my reading of the first eleven pictures: keep the direction. Of the
four things it first flagged, the two that were defects are fixed; two are judgement calls left for
you, with measurements rather than adjectives. React to it, do not defer to it. It predates the four
way-in pictures and does not cover them.

## What the pictures already caught

The first render of `week-dark-200-percent-text.png` showed the weekday names running together —
*MonTueWed*, no gap. Nothing clipped and nothing overflowed, so every existing test passed; a
`FittedBox` will shrink type forever rather than admit it has run out of room. It is fixed, and the
fix has a test that measures the gap. These images are regenerated from the current code, so that
one now shows seven separate days.

The first render of `family-profile-dark-200-percent-text.png` caught the nut-free rule as a tag cut
to *Nut-free · nut allergy,…* — the reasons, which are the point, were the part that went. It is a
wrapping banner now.

The first render of `sign-in-light.png` did the same job for the welcome: two of the member marks
had landed on the same bearing as the tiles inside them and overlapped, which no test could have
had an opinion about. The bearings are picked by eye now, and the reason is written where the
numbers are.

## Regenerating them

```sh
flutter test tool/ --update-goldens
```

`tool/design_review_test.dart` is deliberately outside `test/`, so `flutter test` never runs it.
These are pictures to look at, not assertions to defend: if the design changes, the images change,
and that is the point. Read a diff here as "the design moved", never as a failing test.
