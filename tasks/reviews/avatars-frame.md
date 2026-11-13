# Avatars review — frame (`../NestPrep-Home`)

Reviewed 2026-11-13. Only avatar work was touched; the other session's celebration, pairing and chores-grid edits in the same files were left alone. Nothing committed, nothing installed on a device.

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | **High** | `CelebrationView.kt` `drawStar` (was `val bitmap = star`) | The celebration composed the avatar payoff (`heroArt`) but `drawStar` still drew the `star` field. A kid with an avatar got the old star, or nothing at all on the first celebration after start, and the hero was never warmed. | **Fixed.** `play` keeps what `compose` returned in `prize`; `drawStar` draws it, so the warm pass uploads it before the motion. |
| 2 | High (must-do 1) | `AvatarBitmaps.kt` `box()` | Face accessories were drawn in one fixed box (0.25, 0.23, 0.5), ignoring the per-picture anchors. | **Fixed.** New `AvatarLayout.kt` (no Android in it): face is centred on the anchor inside the square the Nestling is drawn in, width `w × 1.6` of that square, not clipped to it. A Nestling with no anchor drops the face layer in `FrameAvatar.plan`. |
| 3 | High (must-do 2) | `FrameAvatar.kt` `from` / `plan`, `AvatarBitmaps.kt` | C-0023 rev 19 `base: {initial: true}` was not understood (it parsed to "no avatar", so the worn layers were lost). | **Fixed.** `Base.Initial`; composed as the colour disc, the initial in Fraunces (Oat on a dark colour, Ink on a light one, 0.47 of the disc like the TextView discs), layers on top. `initial` counts only when exactly `true`. An initial base with nothing drawable left returns no plan, so the site's own initial is drawn as today. Under a `top` the letter sits slightly lower and smaller so the hat is not on it. |
| 4 | Medium | `AvatarBitmaps.kt` ring box | The ring was centred on the low-set base (y 0.56) at 1.1 × its radius, so it was off-centre in the disc and clipped at the bottom. | **Fixed.** The ring runs round the edge of the disc, as on the phone. |
| 5 | Medium | `AvatarBitmaps.kt` image base | A photo was drawn in the inset, low-set circle: a colour crescent above it, nearly none below. | **Fixed.** A photo fills the disc (centre-cropped), as the phone's `NestAvatar` does; a hat sits over its top. |
| 6 | Low | `AvatarBitmaps.Look` | The look key had no initial, which the initial base now needs (a renamed member must recompose). | **Fixed.** `Look(avatar, color, initial)`; `Shell.showAvatars` passes it. |
| 7 | Low | `MainActivity.kt` | `AvatarBitmaps` now needs the display font and two colours. | **Fixed.** Built after `Fonts`; two lines moved, nothing else in the file touched. |
| 8 | Low | `CLAUDE.md` (frame) | Avatars were not described; `AvatarFaces.kt` being generated was written nowhere on the frame side. | **Fixed.** One paragraph under *What it does*. |
| 9 | Checked (must-do 3) | every site | The mockup's plain discs with no initial. | **No bug in the app.** Every site sets its text and colour dot first and `Ui.showAvatar` returns early when there is no bitmap; the Canvas sites (`PeopleMapView`, `PersonFilterView`, `ScheduleView`) draw the initial in the `else`. `PeopleScreen.Row` restores the dot and the letter when a look goes away. The blank discs were the mockup harness, which only drew the disc. |
| 10 | Checked (must-do 5) | draw paths | Allocation and decoding. | **Clean.** No allocation in any `onDraw` (paints and rects are fields). All decoding and composing is on `AvatarBitmaps`' single worker. `heroArt` allocates in `play`, not in `onDraw`, and after fix 1 it is warmed. About 115 KB a member. |
| 11 | Rejected | `top` box | The frame's hat sits about 0.06 lower on the Nestling than the phone's. | **Kept.** The phone lets a hat overhang the circle; a TextView background cannot, so everything stays inside one square. On the sheet the hats sit well on the final art. Recorded in ADR-0022. |
| 12 | Rejected | `Shell.showAvatars` | The first bind shows initials and rebinds once when the compose lands (tens of ms after start). | **Kept.** Blocking the first paint on a decode is worse; the rebind is the same path as a day refresh and the chores screen already defers it while a celebration plays. |
| 13 | Rejected | discs under 20 dp | Event discs and week chips keep the initial. | By design (ADR-0022 point 6). |

Spec conformance otherwise holds: asset id and hash regexes match the spec, unknown fields are tolerated, an unknown base is the initial, an unknown layer is skipped, `face` is dropped on a photo, no member id reaches the frame (avatars are keyed by first name like `members`), and old frames read a rev 19 `initial` base as "no avatar".

## Contact sheet (must-do 4)

`AvatarSheetTest.drawsTheContactSheet` composes with the real `assets/avatars/*.webp`, `AvatarFaces`, `FrameAvatar.plan` and the same `AvatarLayout` boxes the app uses, and writes `../NestPrep-Home/app/build/reports/avatars/sheet-1.png`, `sheet-2.png` and `sizes.png`. It converts the WebP with `dwebp` and is skipped where that is not installed.

I read all three. All 96 Nestlings (24 × 4 stages) wearing glasses, masks and monocles: every one lands on the eyes, eggs included. Hats, badges and rings sit well; initial and photo bases look right; everything is still readable at 26 px. It looks fun.

## Checks run

- `./gradlew :app:testDebugUnitTest`: **128 tests, 0 failed, 0 skipped** (was 120). New: `AvatarSheetTest` (4), three in `FrameAvatarTest`, one in `FrameDayTest`.
- `./gradlew :app:assembleDebug`: **builds**.
- `godfather lint` on the NestPrep-Home node: no errors (the orphan and size warnings were there before).
- Not run: `assembleRelease` (needs the release keystore), anything on a device.

## Godfather

NestPrep-Home ADR-0022 edited in place (still proposed): rev 19 initial base, face anchors, ring and photo placement, the `prize` fix, the re-check on the final art, the new verification numbers. I had no `append_session_log` tool in this session (CLI only), so no session log entry was written.

## Left for Daniel

- **Not seen on a real frame.** The celebration hero in particular: it is the 128 px master scaled up to about 216 px (290 px on the Frame Pro), so it will be slightly soft. If that bothers you, the fix is composing the hero from 384 px art, which the frame does not bundle.
- **Rev 19 was built against the launch message's shape** (`base: {initial: true}` plus `layers`), since the server side was not in the tree yet. If the server ships a different key, `FrameAvatar.from` is the one place to change.
- The composed initial is Fraunces everywhere. Today's pill, pin and schedule-head initials are DM Sans, so a member with an initial base plus accessories shows a slightly different letter in those three places.
- `versionCode` was already bumped to 13 by another session; I did not touch it.
