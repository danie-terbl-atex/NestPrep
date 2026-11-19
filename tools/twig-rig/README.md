# twig-rig

Cut-out "puppet rig" layers of Twig in his welcome pose, so the app can animate a wave, a crest and tail
sway, and a blink in code instead of shipping frames. Nothing here runs in production.

## Inputs and outputs

- Input: the master art `nullstate-vault/nestprep-project/design-system/brand/twig/twig-welcome.png`
  (1254×1254 RGBA). The vault is frozen; the script only reads it.
- Output: five lossy WebPs with alpha in `app/assets/brand/twig/rig/`, all on one shared 512×512 canvas
  (the master scaled 1254 → 512). Drawing every layer at the canvas origin rebuilds the bird.
- `rig.json`: each layer's file, draw order, pivot in canvas px and rotation range. Degrees are positive
  clockwise on screen, the `Transform.rotate` convention.

| Order | Layer | Moves | Pivot (512 px) | Range |
| ----- | ----- | ----- | -------------- | ----- |
| 0 | `tail.webp` | sway | 351.9, 404.2 (root, under the right wing) | ±8° |
| 1 | `wing.webp` | wave | 196.8, 318.5 (shoulder, just inside the body edge) | ±20° |
| 2 | `body.webp` | — | — | — |
| 3 | `crest.webp` | sway | 283.8, 108.6 (where the feathers meet the head) | ±8° |
| 4 | `eyes_closed.webp` | blink: show it | — | — |

The draw order comes from the drawing itself. In the master, the body outline runs unbroken over the
raised wing's root and over the tail, so both are behind the body: they go below it, and the body hides
their joints. The crest has no line between it and the head, so it stays on top. A positive wing angle
raises the wing towards the head and a negative one swings it out and down.

## How it is made

Every step runs locally and gives the same bytes each run (the one bit of noise is seeded). Nothing is paid for.

1. **Segmentation.** The art is flat colour inside a dark outline, so thresholds work: outline pixels
   are the dark brown ones, the wing and tail are the teal and yellow regions at fixed seed points,
   and every outline or edge pixel goes to the nearest fill. An outline shared by a limb and the body
   belongs to the body.
2. **Wing and tail.** Each limb keeps its own pixels and gets a made-up root behind the body: its
   own colour, closed with an outline. Most of that root is a disc about the pivot, fitted inside the
   silhouette. A disc rotated about its own centre stays in place, so the root can only show where the
   limb already was, never as a flap outside the bird.
3. **Crest.** A circle is fitted to the head's top outline (residuals under 1 px), and the gap where
   the feathers grow out is found along it. The body gets that outline closed across the gap and the
   green under it inpainted (OpenCV Telea, sampling from below only). The crest layer is the feathers
   plus a patch of the original head over the closed line, opaque where the body differs and fading out
   where it does not. At rest that gives back the master exactly.
4. **Eyes closed.** Each eye, with its light rim, is covered with the sampled face cream and the
   face's own fine grain. The beak outline stays clear. A happy arc in the outline colour, about the
   outline's weight, is drawn over each eye, oversampled 4× for smooth edges.
5. **Canvas.** Layers are built at 1254 px, downscaled to 512 px with premultiplied Lanczos, and saved as
   WebP at quality 90 with alpha quality 100.

## Running it

```sh
cd tools/twig-rig
python3 -m venv .venv && .venv/bin/pip install pillow numpy scipy opencv-python-headless
.venv/bin/python build.py            # layers + rig.json + previews
.venv/bin/python build.py layers     # layers + rig.json only
.venv/bin/python build.py preview    # previews of the shipped WebPs only
```

It prints the layer sizes and how far the rest pose is from the original. `work/` is gitignored:

- `work/layers/*.png`: lossless 512 px layers
- `work/preview/rest_vs_original.png`: the stacked rest pose, the downscaled master, and their difference ×4
- `work/preview/contact_sheet.png`: wing −20°/0°/+20°, crest ±8°, tail ±8°, eyes closed, on magenta so any hole shows
- `work/preview/layer_*.png`: each layer alone

Smoke check: the rest pose stacked from the lossless layers matches the master. Mean difference is
0.06/255; the 42 pixels over 16/255 are anti-aliasing where two outlines meet. With the WebPs, the mean
difference is 1.3/255, which is compression noise along edges.

The seed points, head circle and pivots are constants at the top of `build.py`. They belong to this
master: if the art changes, `component_at` stops with the seed that missed.

## Cost

US$0. The plan allowed up to US$4 of fal.ai for segmentation and inpainting. The art turned out to be
clean enough to cut by colour and outline, and the hidden fills are small enough to make up in code, so
no fal model was called.

## Using it in the app

`app/pubspec.yaml` lists `assets/brand/twig/` but not this subfolder, and Flutter does not recurse into
subfolders. Add `assets/brand/twig/rig/` to the pubspec before loading these.
