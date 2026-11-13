# Avatars review — art

Reviewed `tools/avatar-pictures/`, the 151 shipped assets and the three generated files. Every finding
below is fixed unless it says otherwise. Nothing was committed, pushed or deployed, and no emulator was
started.

Review sheets (all rebuilt after the fixes):
`/private/tmp/claude-501/-Users-danielterblanche-Documents-NullState-NestPrep/d794818a-974d-45a5-9ccf-d82740dea94d/scratchpad/avatar-library/`

- `faces-oat-0-8.png`, `faces-oat-8-16.png`, `faces-oat-16-24.png`: round glasses on all 96 Nestlings at their anchors
- `face-accessories-on-16-nestlings.png`: all five face accessories on 16 Nestlings
- `faces-monocle-night-0-8.png`: the monocle, on Night, with the grid
- `nestlings-night-128-*.png`, `accessories-night-128.png`, `moments-night-128.png`: the frame's 128 px assets on Night
- `nestlings-oat-*.png`, `accessories-oat.png`, `moments-oat.png`

## Findings

| # | Severity | Where | Finding | Outcome |
|---|---|---|---|---|
| 1 | High | `tools/avatar-pictures/catalogue.json` (`faces` on every Nestling), `build.py` | No face anchors: glasses, masks and the monocle sat at one fixed point while eye height varies from 0.13 to 0.65 of the picture. | Fixed. All 96 anchors measured and checked on the sheets. Generated as `NESTLING_FACES` (TS), `AvatarFace` and `avatarNestlingFaces` (Dart) and `AvatarFaces.kt` (frame). |
| 2 | High | `process.py` `seated`, `catalogue.json` `eyes` on the five face accessories | An anchor alone could not seat a face accessory: each picture had its eye holes a different distance apart (0.36 to 0.49 of its width), and the monocle's lens was in the middle, so it would land on the nose. | Fixed. Every face accessory is now scaled and moved so its eye holes sit on the same two points of its square; the monocle's lens sits on the right-hand one. The spec rule (centre on x, y; width `1.6 * w`) then puts a lens on each eye with no per-accessory code in any client. |
| 3 | Medium | `acc-hero-mask` | The mask's side ties made it too wide to seat with its holes on the eyes. | Fixed: redrawn without ties, with round holes. |
| 4 | Medium | `nestling-pebble-2` | Lilac, yellow and green; did not match stages 1 and 3. | Fixed: redrawn in grey-brown and cream. |
| 5 | Medium | `nestling-dotty-2` | Sat on a lilac base ring. | Fixed: redrawn without it. Its bottom edge is now a straight cut rather than a rounded bust; a circle crop hides it. |
| 6 | Medium | `acc-flower-crown` | Read as an oval wreath seen from above. | Fixed: redrawn as a front-on arc of flowers. |
| 7 | Low | `process.py` `drop_islands` | Stray sparkles and shell chips round `jewel-1/2/3`, `bao-1/3`, `squeak-0/1`, `cotton-0/1`, `rosie-1`, and round `acc-cat-ears` and `acc-dinosaur`. | Fixed without redrawing: a Nestling keeps only its one big piece; the two accessories are flagged `one_piece`. Sparkles that were asked for (halo, star crown, New Year crown, Book Day) stay. |
| 8 | Low | `generate.py` `door` | Only worked with `GEMINI_API_KEY`, which is not set on this machine. | Fixed: falls back to Vertex on the gcloud account, as `tools/chore-pictures` does. |
| 9 | Low | `functions/test/unit/avatars/avatar_catalogue.test.ts` (new) | Nothing checked that every catalogue id has a picture, or that every Nestling picture has an anchor. | Fixed: three tests. |
| 10 | Low | `README.md` | Did not cover anchors, seating, the sparkle clean-up or the Vertex route. | Fixed. |
| 11 | Low | `acc-monocle` | The chain links keep white centres: they are smaller than the shared cut-out's hole threshold. They read as beads at avatar sizes. | Rejected: the threshold lives in `tools/chore-pictures/process.py`, shared with the chore pictures, and is not worth changing for this. |
| 12 | Low | `acc-round-glasses` | The frames came out dark green, not the dark plum the prompt asks for, and are faint on Dotty's dark face. | Rejected: cosmetic, and a redraw risks a worse pair. Left for Daniel's eye. |

## How the anchors were measured

The brief said to measure with Gemini. I tried it and it was not good enough:

- `gemini-2.5-flash` in `europe-west4` was wrong on roughly half the pictures (eyes found on the body, widths off by 2x) and returned malformed boxes for five.
- `gemini-2.5-pro` on the ten worst was wrong on all ten.

So all 96 were read by hand off gridded sheets (both eye centres per picture), then verified by drawing round glasses on every Nestling and all five accessories on a sample of 16. No outliers remain on the sheets. The measuring script was deleted rather than kept as a tool that gives wrong answers; the README says to measure by hand and why.

Three things a consumer should know:

- **`w` is 1.4 times the distance between the eye centres**, which is about outer edge to outer edge of the eyes. It is tied to the centres, not the eye size, so the lenses always land on the eyes.
- **Profile Nestlings** with one eye showing (`jewel-1`, `jewel-2`) take their second point towards the beak, so glasses perch on the beak. Every Nestling asset has an anchor; none is left without a face layer.
- **A wide-eyed Nestling gets a wide accessory.** On `squeak-3`, `w` is 0.579, so a face accessory is drawn 0.93 of the base's size and overhangs the picture a little. Clients should not clip the face layer to the base's bounds.

## Deviations from the spec

- The catalogue stores `faces` as a list per Nestling in stage order, not `face` per asset. The generated maps are keyed by asset id exactly as the spec says.
- `AvatarFaces.Face` is a class nested in the `AvatarFaces` object (`AvatarFaces.of(id): AvatarFaces.Face?`), with `Float` fields.
- The existing generated API is unchanged; everything is additive.

## Checks run

| Check | Result |
|---|---|
| `python3 build.py` | `{"shipped": 151, "total": 151, "missing": []}`; app 3.1 MB, frame 1.2 MB |
| `npm --prefix functions run build` | clean |
| `vitest` on `test/unit/avatars` and `test/unit/frames/frame_avatar.test.ts` | 5 files, 179 tests passed (3 new) |
| `eslint` and `prettier --check` on the generated TS and the new test | clean |
| `flutter analyze --fatal-infos` on `avatar_catalogue.g.dart` | no issues |
| `flutter test test/features/avatars test/design/primitives/nest_avatar_test.dart` | 104 passed |
| `./gradlew :app:compileDebugKotlin` in NestPrep-Home | compiles with `AvatarFaces.kt` |
| White-halo score, every 128 px asset | 144 of 151 score 0; the other seven (max 12%) are cream busts with an unoutlined bottom edge, confirmed by eye on Night |
| People, hands, human faces, text | none; all 96 Nestlings, 40 accessories and 12 moment pictures looked at |

Not run: `test:rules`, the emulator suite, the full Flutter suite and `./gradlew test`. None of this portion touches rules, triggers or UI code.

## Left for Daniel

- **Nothing draws from the anchors yet.** `app/lib/design/primitives/nest_avatar.dart` still places the face layer at a fixed 0.42 height and 0.52 width, and the frame's `AvatarBitmaps.kt` has no reference to `AvatarFaces`. Until the app and frame portions switch to `centre (x, y), width 1.6 * w`, face accessories will look worse than before, because the pictures are now seated for that rule.
- **Godfather is not updated.** The face-anchor decision and the seating rule belong in the avatars ADR-0002 write-back; I had no Godfather tools in this session.
- **Look at the art.** The four redrawn pictures (`pebble-2`, `dotty-2`, flower crown, hero mask) and findings 11 and 12 are a matter of taste. The pictures they replaced are in `tools/avatar-pictures/work/before/` (gitignored).
- `tools/chore-pictures/__pycache__/process.cpython-313.pyc` is tracked and shows as modified, because Python recompiled it when the avatar tool imported the chore cut-out. It is harmless; the `__pycache__` probably should not be tracked.
- Three regenerations hit Vertex 429s and succeeded on retry; the quota note in the plan still stands.
