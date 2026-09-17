# What I would flag, so the verdict is a yes or a no

The verdict on the design direction is yours and I cannot form it. What I can do is go first, so you
are reacting to something concrete instead of starting from a blank page. Disagree freely — this is
one reading of eleven pictures, and you have the one that counts.

## The direction, in one line

It reads as **domestic and calm rather than productive and efficient** — soft lavender, generous
radii, a lot of air, one friendly type family. For an app whose whole job is a family's week, I think
that is the right instinct, and I would keep it. A household app that looked like Jira would be
correct and unpleasant.

**My recommendation: keep the direction, change four small things.** All four are token-level, so
each is one file.

## The four things

**1. Two strong purples compete on the week screen.** The *today* pill in the date strip and the
*Add an event* button are the same saturated accent, roughly the same size, in the same visual
weight. The eye does not know which is the subject. The date pill is state, the button is an action —
they should not look alike. Softening the pill to the tonal fill would fix it in
`nest_colors.dart`.

**2. Dark mode is nearly black, and the cards are barely there.** In `todos-mine-dark.png` the card
outlines are a hair above the background. It reads well on a bright screen and I suspect it
disappears on a dim one. Worth looking at in bed, which is when a family app actually gets used.

**3. At 200% text the weekday names run together** — *MonTueWed* with no gap (`week-dark-200-percent-text.png`).
Nothing clips and nothing overflows, so the rule holds; it just stops reading as seven separate days.
A minimum gap, or dropping to single letters at large scales, would do it.

**4. Day labels mix absolute and relative.** The meal week shows *Mon 14 Sep*, *Tue 15 Sep*, then
*Yesterday*. Each is friendly on its own; together in one column they read as two systems. Pick one
per surface — relative for the day you are on, absolute for a list you are scanning.

## What I would not change

The type. Plus Jakarta Sans at these sizes is doing a lot of quiet work, and the hierarchy holds at
every size I rendered. The pill-shaped kit is consistent enough that the app already looks like one
thing rather than seven screens. The member colours stay distinguishable in both themes and never
carry meaning alone.

## The honest caveat

These are renders, not a phone in your hand. Colour on an OLED at low brightness, how the motion
feels, and whether the touch targets land under a thumb are all things a picture cannot tell you. If
your verdict is "I need to hold it", that is a fair answer and the app is installable — the device
run on 2026-09-18 worked end to end.
