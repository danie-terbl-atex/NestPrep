# avatar-pictures

The avatar library (avatars ADR-0002): 24 Nestlings, each an egg and three stages, the accessories a
member wears on four slots, and the moments the calendar puts on them. Pictures are generated once,
reviewed by eye, and shipped inside the app, the Functions bundle and the frame. Nothing here runs in
production.

## Interface

- `catalogue.json` is the source of truth.
  - `nestlings`: `name`, `label`, `creature`, and the words for each stage: `hatchling` (stage 1),
    `egg` (the pattern on stage 0), `young` (stage 2) and `grown` (stage 3). `faces` is the face
    anchor of each stage's picture, in stage order: `x`, `y` is the point midway between the eye
    centres and `w` is 1.4 times the distance between them, all as fractions of the square picture.
  - `accessories`: `id`, `label`, `slot` (`top`, `face`, `badge`, `ring`), `stars` (0 is free) and
    `subject`. A `face` accessory also has `eyes`: where its two eye holes are on its trimmed
    square (one point and a `scale` for a monocle). `one_piece` cuts stray sparkles away.
  - `moments`: `id`, `label`, `slot`, `rule` (`birthday`, `dates` with an optional `hemisphere`, or
    `easter` in days around Easter Sunday) and `subject`. A moment with `art` reuses another moment's
    picture, which is how one picture serves both hemispheres.
  - `buddy`: the Build-a-Buddy words, `creature`, `colour`, `loves`, `wears` and `power`.

  **Ids and names are stored on members, so they are never renamed or reused.** The asset ids are
  `nestling-<name>-<stage>`, `acc-<id>` and `moment-<id>`.
- `generate.py` calls `gemini-3.1-flash-image` and writes `work/raw/<asset id>.png`: on the Gemini
  API when `GEMINI_API_KEY` is set, otherwise on Vertex as your gcloud account (about a picture a
  minute, so fine for a retry and slow for the library). Every Nestling's stage 1 is drawn first from the two anchors (a chore
  celebration bird and the make-bed sticker); its egg and its stages 2 and 3 are then drawn with stage 1
  as the only reference, so the four match. Stages 2 and 3 are head-and-shoulders busts so the face
  reads in a 28 px circle. It skips files that exist; `--force --ids …` redoes some, `--note` adds a
  line to the prompt for a retry, and `--list` prints every id.
- `process.py` cuts the white background out to alpha with a flood fill from the edges (and, for
  `face` and `ring`, every enclosed white too, so lenses and the ring's middle are clear), trims,
  squares and writes `work/384/` and `work/128/` WebPs. A Nestling keeps only its one big piece, so
  the sparkles and shell chips the model scatters round it go. An accessory is trimmed and padded
  to a square with no placement baked in: the client places it by its slot. The exception is `face`:
  each is scaled and moved so its `eyes` land on the same two points of the square, 0.223 either
  side of the centre. A client draws it centred on the Nestling's anchor at `1.6 * w` of the
  base's size, and those points then fall on the Nestling's eyes.
- `sheet.py` makes a review sheet per kind on Oat or Night; Nestlings also show a 56 px circle chip.
  `faces` tries a face accessory (`--wear`, round glasses by default) on every Nestling at its
  anchor, and `--grid` rules tenths over each picture.
- `build.py` copies every picture into `app/assets/avatars/` and `functions/assets/avatars/` (384 px)
  and `../NestPrep-Home/app/src/main/assets/avatars/` (128 px), and writes
  `app/lib/features/avatars/model/avatar_catalogue.g.dart`,
  `functions/src/avatars/avatar_catalogue.ts` and, for the frame, the face anchors in
  `../NestPrep-Home/app/src/main/java/io/nullstate/nestprep/home/AvatarFaces.kt`. A missing picture is reported, not fatal: the
  catalogue is still generated.

`work/` and `.venv/` are gitignored. The shipped assets and the generated Dart and TS are committed.

```sh
cd tools/avatar-pictures
python3 -m venv .venv && .venv/bin/pip install pillow
python3 generate.py --ids <ids>          # or no --ids for everything missing
.venv/bin/python process.py --ids <ids>
.venv/bin/python sheet.py nestlings oat review.png
.venv/bin/python sheet.py faces oat faces.png --grid
python3 build.py
```

Generating everything takes about 15 minutes in three shards: split the ids from `--list` three ways,
keeping each Nestling's four stages in one shard, and run a `generate.py --ids …` per shard.

Smoke check: `python3 build.py` prints `{"shipped": N, "total": N, "missing": []}`.

## Adding a picture

1. Add an entry to `catalogue.json`. No people, hands or human faces, and no text.
2. Generate it, process it, and review it on Oat and on Night.
3. A Nestling picture, new or redrawn, needs its face anchor measured by hand: read the two eye
   centres off a `--grid` sheet, write `faces`, and check the `faces` sheet. Two vision models were
   tried for this on 2026-11-12 and both were wrong on about half the pictures. A profile with one
   eye showing takes its second point a little way towards the beak.
4. Run `build.py`, then ship an app build, a Functions deploy and a frame APK. An older build simply
   draws nothing for an id it does not know, and the initial for a base it does not know.
