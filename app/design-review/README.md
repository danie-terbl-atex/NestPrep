# Design review — every screen, both themes

Twenty pictures of NestPrep, taken from the real widgets with the real theme and the real font.
They exist so the one thing v1 still needs — **an opinion on whether this direction is right** — does
not have to wait for a working Android emulator.

Take them at 390×844, the size of an ordinary phone, at 2× so the type is sharp. The kids' eight
are a press of their own — `flutter test tool/kid_design_review_test.dart --update-goldens` — sharing
the same shutter (`tool/design_review_press.dart`).

`sign-in-*` was retaken on 2026-09-29 when the kids' way in joined it. `household-gate-*` is
**stale**: it no longer matches the screen (a 5% pixel difference, from before kid sign-in), and it
was left alone rather than retaken on a branch that did not change that screen.

| File | What it shows |
|---|---|
| `week-light.png` / `week-dark.png` | the family week: the seven-day strip, today, and the day's agenda in member colours |
| `todos-mine-light.png` / `todos-mine-dark.png` | what one person is being asked to do, overdue first |
| `todos-everyone-light.png` / `todos-everyone-dark.png` | the whole household's list, the member filter and the routines |
| `groceries-light.png` / `groceries-dark.png` | the one list, with something already ticked |
| `meals-light.png` / `meals-dark.png` | the week's twenty-one slots, some filled |
| `sign-in-light.png` / `sign-in-dark.png` | the first screen anybody sees: the nest mark in a two-ring orbit of the four tabs and five member marks, the name, the tagline, and the way in |
| `household-gate-light.png` / `household-gate-dark.png` | the screen after it, where a household is made or joined |
| `week-dark-200-percent-text.png` | the same week at the largest text a phone offers |
| `beta-numbers-light.png` / `beta-numbers-dark.png` | Daniel's readout during the beta: this week's three numbers, then earlier weeks side by side (product-analytics ADR-0001) |
| `kid-code-light.png` / `kid-code-dark.png` | a child's way in: a hello, six big letter tiles half typed, and one button (accounts ADR-0003) |
| `kid-home-light.png` / `kid-home-dark.png` | the only screen a kid device has: their colour and name, how far through today's jobs they are, the jobs as big tiles, and today's food |
| `kids-sign-in-light.png` / `kids-sign-in-dark.png` | the parent's side: each child, the devices they are signed in on, add one or sign them all out |
| `kids-pairing-light.png` / `kids-pairing-dark.png` | the code a parent reads out, counting down its ten minutes |
| `family-light.png` / `family-dark.png` | family profiles: children first, each with their allergies in their severity's tone and the nut-free rule, then everyone else and the household's schools |
| `family-profile-light.png` / `family-profile-dark.png` | one child's profile: the severe-allergy banner, the nut-free rule with its reasons, then allergies, food and the rest below the fold |
| `family-profile-dark-200-percent-text.png` | the same profile at the largest text a phone offers |
| `paywall-light.png` / `paywall-dark.png` | premium's paywall, opened on a second child: the mark, what premium adds, both plans at the store's own prices with the yearly saving (regenerate with `flutter test tool/subscriptions_design_review_test.dart --update-goldens`) |
| `plan-free-light.png` / `plan-free-dark.png` | Plan & billing on the free plan: what the family has and the way to premium |
| `plan-premium-light.png` / `plan-premium-dark.png` | Plan & billing on premium: when it renews, who bought it, and the buyer's way to their store |

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
flutter test tool/design_review_test.dart --update-goldens
```

`tool/design_review_test.dart` is deliberately outside `test/`, so `flutter test` never runs it.
These are pictures to look at, not assertions to defend: if the design changes, the images change,
and that is the point. Read a diff here as "the design moved", never as a failing test.
