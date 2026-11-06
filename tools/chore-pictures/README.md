# chore-pictures

The library of stickers a task can wear (todos ADR-0005). Pictures are generated once, reviewed by
eye, and shipped inside the app and the frame. Nothing here runs in production.

## Interface

- `catalogue.json` is the source of truth: `id`, `label`, `category`, `keywords` and `subject` for
  each picture. **An id is stored on tasks, so it is never renamed or reused.**
- `anchors/` holds the three approved stickers every generation is given as its style reference.
- `generate.py` calls Vertex `gemini-3.1-flash-image` on `nestprep-643b7` as your gcloud account and
  writes `work/raw/<id>.png`. It skips files that already exist; pass `--force --ids …` to redo some.
- `process.py` cuts the white background out to alpha with a flood fill from the edges, trims, squares
  and writes `work/384/` (app) and `work/192/` (frame) WebPs.
- `sheet.py` makes a contact sheet to review a folder.
- `build.py` copies every picture that has both sizes into `app/assets/chore_pictures/` and
  `../NestPrep-Home/app/src/main/assets/chore-pictures/`, and writes
  `app/lib/features/todos/model/chore_picture_catalogue.dart`.

`work/` is gitignored. The shipped assets and the generated Dart are committed.

```sh
cd tools/chore-pictures
python3 -m venv .venv && .venv/bin/pip install pillow
.venv/bin/python generate.py --catalogue catalogue.json --out work/raw \
  --refs anchors/brush-teeth.png anchors/make-bed.png anchors/water-plants.png --ids <new ids>
.venv/bin/python process.py --raw work/raw --out work/384:384 work/192:192 --ids <new ids>
.venv/bin/python sheet.py work/384 review.png 8 220 "#FFF8ED"
python3 build.py
```

Smoke check: `python3 build.py` prints `{"shipped": N, "missing": []}`, and N matches the number of
entries in `catalogue.json`.

## Adding a picture

1. Add an entry to `catalogue.json` and describe the subject.
   - No people, hands or faces, and no text.
   - Draw the chore as its objects or its result.
2. Generate it, process it, and review it on Oat and on Night.
3. Run `build.py`, then ship an app build and a frame APK. An older build simply shows no picture for
   the new id.
