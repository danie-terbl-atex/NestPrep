# What I would flag, so the verdict is a yes or a no

The verdict on the design direction is yours and I cannot form it. What I can do is go first, so you
are reacting to something concrete. Since writing the first version of this note I have fixed the two
findings that were defects rather than taste; the two left are genuinely yours.

## The direction, in one line

It reads as **domestic and calm rather than productive and efficient** — soft lavender, generous
radii, a lot of air, one friendly type family. For an app whose whole job is a family's week, I think
that is the right instinct, and I would keep it. A household app that looked like Jira would be
correct and unpleasant.

**My recommendation: keep the direction.** Two things below are now fixed. Two are your call.

## Fixed, because they were defects

**The weekday names ran together.** *MonTueWed*, with no gap. Seven `Expanded` columns sat edge to
edge, and the `FittedBox` shrank each name until it fitted whatever space it was given — so nothing
ever clipped and nothing ever overflowed, which is why no existing test could see it. The strip has a
gutter now. Writing the test turned up something the pictures had not: it was **already illegible at
1.5× text**, not only at 200%. `week_strip_legibility_test.dart` measures the gap between all seven
names at 1×, 1.5× and 2×.

**Day labels mixed two systems.** The meal week showed *Mon 14 Sep*, *Tue 15 Sep*, then *Yesterday*.
Each is friendly alone; in one column they are two labelling systems and the eye stops being able to
scan. There are now two named formatters — `relative` for a date on its own, `dayInARun` for a column
of consecutive days — so the choice is made once rather than remembered at each call site. Which day
is today is still carried by the card's own tint, so nothing was lost.

## Yours to decide

**1. Two strong purples compete on the week screen.** The *today* pill in the date strip and the
*Add an event* button are the same saturated accent, roughly the same size and weight. One is state,
the other is an action, and the eye does not know which is the subject. Softening the pill to the
tonal fill would fix it in `nest_colors.dart` — but which of the two should recede is a judgement
about what the screen is *for*, so I have left it.

**2. The cards barely separate from the background — in both themes.** I said "check it in bed" the
first time; here are the numbers instead, so you can decide with data rather than a feeling:

| | card vs background | its border vs the card |
|---|---|---|
| dark | **1.11 : 1** | 1.24 : 1 |
| light | **1.08 : 1** | 1.25 : 1 |

WCAG 2.1 asks 3:1 for a boundary that is *needed* to identify a control. These boundaries are not
needed — every card's contents are legible on their own and the contrast test already holds every
text pair at AA — so this is not a failure. It is a deliberate softness, and raising it would change
the whole feel of the app. That is exactly the decision I should not take for you. If you want more
separation, it is `outline` and `surface` in `nest_colors.dart` and nothing else.

## What I would not change

The type. Plus Jakarta Sans at these sizes is doing a lot of quiet work, and the hierarchy holds at
every size I rendered. The pill-shaped kit is consistent enough that the app already looks like one
thing rather than seven screens. The member colours stay distinguishable in both themes and never
carry meaning alone.

## The honest caveat

These are renders, not a phone in your hand. Colour on an OLED at low brightness, how the motion
feels, and whether the touch targets land under a thumb are things a picture cannot tell you. If your
verdict is "I need to hold it", that is a fair answer and the app is installable — the device run on
2026-09-18 worked end to end.
