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
The nanny hub's eleven are `tool/nanny_design_review_test.dart`. Two homes' fourteen are
`tool/two_homes_design_review_test.dart` (household ADR-0004).

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
| `two-homes-light.png` / `two-homes-dark.png` | two homes: a link waiting for this home to confirm, and a live one — where the child is today, the coming week in each home's colour, the next handover — then the ways in and the privacy boundary (household ADR-0004) |
| `two-homes-link-light.png` / `two-homes-link-dark.png` | one link: the next two weeks, the coming handovers with how far the bag has got, and a swap the other home has asked for |
| `two-homes-handover-light.png` / `two-homes-handover-dark.png` | a handover: who goes where, the bag half packed, the usual things a tap away, and the notes both homes read |
| `two-homes-setup-light.png` / `two-homes-setup-dark.png` | making a code: the child, this home's name and colour, then the schedule chosen from four patterns |
| `two-homes-join-light.png` / `two-homes-join-dark.png` | accepting a code: what the other home offers, the fortnight it proposes, this home's profile for the child, and what will be shared |
| `two-homes-privacy-light.png` / `two-homes-privacy-dark.png` | what the other home can see, and what stays — the same two lists everywhere they appear |
| `week-two-homes-light.png` / `week-two-homes-dark.png` | the week with a linked child: a small bar under each day in the home's colour, and the day's all-day band — *goes to Mum's home, at 17:00* |
