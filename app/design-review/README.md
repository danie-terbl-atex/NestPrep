# Design review — every screen, both themes

Eleven pictures of NestPrep v1, taken from the real widgets with the real theme and the real font.
They exist so the one thing v1 still needs — **an opinion on whether this direction is right** — does
not have to wait for a working Android emulator.

Take them at 390×844, the size of an ordinary phone, at 2× so the type is sharp.

| File | What it shows |
|---|---|
| `week-light.png` / `week-dark.png` | the family week: the seven-day strip, today, and the day's agenda in member colours |
| `todos-mine-light.png` / `todos-mine-dark.png` | what one person is being asked to do, overdue first |
| `todos-everyone-light.png` / `todos-everyone-dark.png` | the whole household's list, the member filter and the routines |
| `groceries-light.png` / `groceries-dark.png` | the one list, with something already ticked |
| `meals-light.png` / `meals-dark.png` | the week's twenty-one slots, some filled |
| `week-dark-200-percent-text.png` | the same week at the largest text a phone offers |

## What to look at

The design system is tokens, not screens: colours in `lib/design/tokens/nest_colors.dart`, the type
family in `nest_typography.dart`, the shape of a button in `primitives/nest_button.dart`. A verdict
of "too purple" or "too round" changes one file, not eleven screens. That is the question worth
answering here — the direction, not any single screen.

## One thing to look at twice

In `week-dark-200-percent-text.png` the weekday names run together — *MonTueWed* with no gap. Nothing
is clipped and nothing overflows, so `FE-14` holds, but at the largest text size the strip reads as
one word. It is a spacing decision, not a bug, and it is the kind of thing that is easier to judge
from a picture than from a rule.

## Regenerating them

```sh
flutter test tool/design_review_test.dart --update-goldens
```

`tool/design_review_test.dart` is deliberately outside `test/`, so `flutter test` never runs it.
These are pictures to look at, not assertions to defend: if the design changes, the images change,
and that is the point. Read a diff here as "the design moved", never as a failing test.
