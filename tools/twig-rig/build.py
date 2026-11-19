import argparse
import json
import pathlib

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
MASTER = REPO.parent / "nullstate-vault/nestprep-project/design-system/brand/twig/twig-welcome.png"
OUT = REPO / "app/assets/brand/twig/rig"
WORK = HERE / "work"
RIG = HERE / "rig.json"

SIZE = 512
FULL = 1254
SCALE = SIZE / FULL

HEAD_CENTRE = (657.8, 510.4)
HEAD_OUTER = 265.9
LINE = 12.0

WING_SEED = (300, 700)
TAIL_TEAL_SEED = (950, 1060)
TAIL_YELLOW_SEED = (1000, 975)
CREST_SEED = (700, 120)
EYE_SEEDS = ((514, 434), (734, 484))

PIVOTS = {
    "wing": (482.0, 780.0),
    "crest": (695.0, 266.0),
    "tail": (862.0, 990.0),
}
RANGES = {"wing": 20.0, "crest": 8.0, "tail": 8.0}
ORDER = ["tail", "wing", "body", "crest", "eyes_closed"]


def load_master() -> np.ndarray:
    return np.array(Image.open(MASTER).convert("RGBA")).astype(np.float32)


def classify(master: np.ndarray):
    r, g, b, a = (master[..., i] for i in range(4))
    ink = (np.maximum(np.maximum(r, g), b) < 120) & (r >= b) & (a > 128)
    fill = (a > 128) & ~ink
    teal = fill & (b > r + 30) & (b > g - 25)
    return ink, fill, teal


def component_at(mask: np.ndarray, seed: tuple[int, int]) -> np.ndarray:
    labels, _ = ndi.label(mask)
    label = labels[seed[1], seed[0]]
    if label == 0:
        raise SystemExit(f"seed {seed} is not inside its region; the master changed")
    return labels == label


def grown(core: np.ndarray, fill: np.ndarray) -> np.ndarray:
    """A colour threshold misses the blended pixels between a fill and its outline; take them too."""
    return ndi.binary_dilation(core, iterations=4) & fill


def polar(shape):
    yy, xx = np.mgrid[0 : shape[0], 0 : shape[1]].astype(np.float32)
    dx, dy = xx - HEAD_CENTRE[0], yy - HEAD_CENTRE[1]
    return np.hypot(dx, dy), np.degrees(np.arctan2(dx, -dy)), xx, yy


def ink_colour(master: np.ndarray, ink: np.ndarray) -> np.ndarray:
    core = ndi.binary_erosion(ink, iterations=3)
    return np.median(master[core][:, :3], axis=0)


def extension(owned: np.ndarray, fill_of_part: np.ndarray, near_body: np.ndarray, room: np.ndarray, pivot: tuple[float, float], depth: float, master: np.ndarray, ink_rgb: np.ndarray) -> np.ndarray:
    """A limb drawn behind the body, with the part the body hides made up: the limb's own colour
    carried inwards and closed with an outline, so a rotation that uncovers it shows more limb, never
    a hole. The body's outline is left to the body. Most of the made-up part is a disc about the pivot
    inside the silhouette: a disc turns onto itself, so it only ever shows where the limb already was."""
    silhouette = ndi.distance_transform_edt(master[..., 3] > 128)
    radius = silhouette[int(pivot[1]), int(pivot[0])] - 2
    yy, xx = np.mgrid[0 : owned.shape[0], 0 : owned.shape[1]]
    disc = np.hypot(xx - pivot[0], yy - pivot[1]) <= radius
    reach = ndi.distance_transform_edt(~fill_of_part) <= depth
    body_outline = owned & ~fill_of_part & near_body
    kept = owned & ~body_outline
    made_up = ndi.binary_opening((disc | reach) & room & ~kept, iterations=4)
    region = (made_up | (body_outline & (master[..., 3] > 200))) & ~kept

    parts, count = ndi.label(fill_of_part)
    near_region = ndi.distance_transform_edt(~region) <= 30
    colours = np.zeros((count + 1, 3), np.float32)
    for index in range(1, count + 1):
        sample = (parts == index) & near_region
        colours[index] = np.median(master[sample if sample.any() else parts == index][:, :3], axis=0)
    _, (iy, ix) = ndi.distance_transform_edt(parts == 0, return_indices=True)

    layer = np.zeros_like(master)
    layer[kept] = master[kept]
    layer[region, :3] = colours[parts[iy, ix]][region]
    layer[region, 3] = 255
    stroke = region & (ndi.distance_transform_edt(region | kept) <= LINE)
    layer[stroke, :3] = ink_rgb
    return layer


def build_layers(master: np.ndarray) -> tuple[dict[str, np.ndarray], tuple[float, float]]:
    """The wing and tail sit behind the body in the drawing, so they are cut out and drawn behind it.
    The crest grows out of the head with no line between them, so it stays on top: the body gets the
    head's outline closed across the crest's base, and the crest carries a patch of the original head
    over that line, opaque where the body differs, so the rest pose is the master pixel for pixel."""
    ink, fill, teal = classify(master)
    alpha = master[..., 3]
    ink_rgb = ink_colour(master, ink)
    radius, angle, xx, yy = polar(alpha.shape)
    inner = HEAD_OUTER - LINE

    wing_fill = grown(component_at(teal, WING_SEED), fill)
    tail_fill = grown(component_at(teal, TAIL_TEAL_SEED) | component_at(fill, TAIL_YELLOW_SEED), fill)

    crest_core = (alpha > 128) & (radius > HEAD_OUTER) & (yy < 300)
    crest_core = component_at(crest_core, CREST_SEED)
    crest_mask = ndi.binary_dilation(crest_core, iterations=3) & (alpha > 0) & (radius > HEAD_OUTER)

    on_ring = (radius >= inner + 2) & (radius <= HEAD_OUTER - 2)
    ring_ink = {}
    for degrees in range(-60, 61):
        sector = on_ring & (np.abs(angle - degrees) < 0.5)
        if sector.any():
            ring_ink[degrees] = ink[sector].mean()
    gap = [d for d, share in ring_ink.items() if share < 0.6 and -30 < d < 40]
    gap_lo, gap_hi = min(gap) - 1.0, max(gap) + 1.0

    labels = np.zeros(alpha.shape, np.int8)
    labels[fill] = 3
    labels[wing_fill] = 1
    labels[tail_fill] = 2
    labels[crest_core] = 4
    _, (iy, ix) = ndi.distance_transform_edt(labels == 0, return_indices=True)
    owner = labels[iy, ix]
    owner[alpha == 0] = 0
    body_fill = labels == 3
    near_body = ndi.distance_transform_edt(~body_fill) <= LINE + 4

    body = master.copy()
    keep = (owner == 3) | ((owner > 0) & ~fill & near_body)
    keep &= ~crest_mask
    body[~keep] = 0

    in_gap = (angle >= gap_lo) & (angle <= gap_hi)
    hole = in_gap & (radius >= inner - 22) & (radius < inner + 1)
    crest_side = (angle >= gap_lo - 4) & (angle <= gap_hi + 4) & (radius >= inner - 22) & (radius <= HEAD_OUTER + 30)
    patched = cv2.inpaint(np.ascontiguousarray(master[..., :3].astype(np.uint8)), crest_side.astype(np.uint8) * 255, 9, cv2.INPAINT_TELEA)
    body[hole, :3] = patched[hole]
    body[hole, 3] = master[hole, 3]
    ring = in_gap & (radius >= inner - 1) & (radius <= HEAD_OUTER + 2)
    weight = np.clip(radius - inner + 0.5, 0, 1)[..., None]
    body[ring, :3] = (weight * ink_rgb + (1 - weight) * patched.astype(np.float32))[ring]
    body[ring, 3] = 253
    under_crest = crest_core & (radius <= HEAD_OUTER + 2)
    body[under_crest, :3] = ink_rgb
    body[under_crest, 3] = 253

    crest = np.zeros_like(master)
    crest[crest_mask] = master[crest_mask]
    span = np.clip(np.minimum(angle - (gap_lo - 3), (gap_hi + 3) - angle) / 3.0, 0, 1)
    radial = np.clip((radius - (inner - 34)) / 8.0, 0, 1)
    patch_alpha = (span * radial) * (radius <= HEAD_OUTER)
    patch = patch_alpha > 0
    crest[patch, :3] = master[patch, :3]
    crest[patch, 3] = master[patch, 3] * patch_alpha[patch]

    wing_owned = owner == 1
    tail_owned = owner == 2
    room = body[..., 3] > 200

    wing = extension(wing_owned, wing_fill, near_body, room, PIVOTS["wing"], 0, master, ink_rgb)

    tail_room = room & (xx > 760) & (yy > 880) & (yy < 1140)
    tail = extension(tail_owned, tail_fill, near_body, tail_room, PIVOTS["tail"], 40, master, ink_rgb)

    eyes = closed_eyes(master, ink, ink_rgb)
    return {"tail": tail, "wing": wing, "body": body, "crest": crest, "eyes_closed": eyes}, (gap_lo, gap_hi)


def closed_eyes(master: np.ndarray, ink: np.ndarray, ink_rgb: np.ndarray) -> np.ndarray:
    overlay = np.zeros_like(master)
    eyes = np.zeros(ink.shape, bool)
    boxes = []
    for seed in EYE_SEEDS:
        highlight = component_at(~ink & (master[..., 3] > 128), seed)
        around = ndi.binary_dilation(highlight, iterations=83)
        eye = ndi.binary_fill_holes(component_at(ink | highlight, seed) & around)
        ys, xs = np.nonzero(eye)
        boxes.append((xs.min(), ys.min(), xs.max(), ys.max()))
        eyes |= eye
    other_ink = ndi.binary_dilation(ink & ~eyes, iterations=2)
    cover = ndi.binary_dilation(eyes, iterations=12) & ~other_ink
    around_cover = ndi.binary_dilation(cover, iterations=10) & ~ndi.binary_dilation(cover, iterations=3) & ~other_ink
    sample = master[around_cover & (master[..., 0] > 230)][:, :3]
    face = np.median(sample, axis=0)
    grain = ndi.gaussian_filter(np.random.default_rng(7).normal(size=ink.shape), 0.8)
    grain *= np.median(np.abs(sample - face)) * 0.67 / grain.std()
    soft = ndi.gaussian_filter(ndi.binary_dilation(cover, iterations=4).astype(np.float32), 2.0)
    soft = np.maximum(soft, cover)
    soft[other_ink] = 0
    overlay[..., :3] = face + grain[..., None]
    overlay[..., 3] = 253 * soft

    scale = 4
    arcs = Image.new("L", (FULL * scale, FULL * scale), 0)
    draw = ImageDraw.Draw(arcs)
    width = int(round(LINE * 1.15 * scale))
    for x0, y0, x1, y1 in boxes:
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2 + (y1 - y0) * 0.08
        half_w, rise = (x1 - x0) * 0.56, (y1 - y0) * 0.24
        points = []
        for i in range(41):
            t = -1 + 2 * i / 40
            points.append(((cx + half_w * t) * scale, (cy - rise * (1 - t * t)) * scale))
        draw.line(points, fill=255, width=width, joint="curve")
        for px, py in (points[0], points[-1]):
            draw.ellipse((px - width / 2, py - width / 2, px + width / 2, py + width / 2), fill=255)
    stroke = np.array(arcs.resize((FULL, FULL), Image.LANCZOS)).astype(np.float32) / 255
    stroke = stroke[..., None]
    overlay[..., :3] = stroke * ink_rgb + (1 - stroke) * overlay[..., :3]
    overlay[..., 3] = np.maximum(overlay[..., 3], 253 * stroke[..., 0])
    return overlay


def to_canvas(layer: np.ndarray) -> Image.Image:
    image = Image.fromarray(np.clip(layer, 0, 255).astype(np.uint8), "RGBA")
    return image.convert("RGBa").resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")


def save_layers(layers: dict[str, np.ndarray], quality: int) -> dict[str, int]:
    OUT.mkdir(parents=True, exist_ok=True)
    (WORK / "layers").mkdir(parents=True, exist_ok=True)
    sizes = {}
    for name, layer in layers.items():
        image = to_canvas(layer)
        image.save(WORK / "layers" / f"{name}.png")
        target = OUT / f"{name}.webp"
        image.save(target, "WEBP", quality=quality, alpha_quality=100, method=6)
        sizes[name] = target.stat().st_size
    return sizes


def write_rig() -> None:
    def point(name):
        x, y = PIVOTS[name]
        return [round(x * SCALE, 1), round(y * SCALE, 1)]

    layers = []
    for index, name in enumerate(ORDER):
        entry = {"name": name, "file": f"assets/brand/twig/rig/{name}.webp", "order": index}
        if name in PIVOTS:
            entry["pivot"] = point(name)
            entry["rotationDegrees"] = [-RANGES[name], RANGES[name]]
        layers.append(entry)
    rig = {
        "canvas": [SIZE, SIZE],
        "source": "twig-welcome.png scaled 1254 to 512; every layer is drawn at the canvas origin",
        "rotation": "degrees, positive is clockwise on screen (Flutter Transform.rotate), about pivot in canvas px",
        "layers": layers,
    }
    RIG.write_text(json.dumps(rig, indent=2) + "\n")


def load_canvas(name: str) -> Image.Image:
    return Image.open(OUT / f"{name}.webp").convert("RGBA")


def rotated(image: Image.Image, name: str, degrees: float) -> Image.Image:
    if degrees == 0:
        return image
    x, y = PIVOTS[name]
    return image.convert("RGBa").rotate(-degrees, resample=Image.BICUBIC, center=(x * SCALE, y * SCALE)).convert("RGBA")


def compose(pose: dict[str, float], eyes: bool, background) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), background)
    for name in ORDER:
        if name == "eyes_closed" and not eyes:
            continue
        canvas.alpha_composite(rotated(load_canvas(name), name, pose.get(name, 0.0)))
    return canvas


def preview() -> dict[str, float]:
    folder = WORK / "preview"
    folder.mkdir(parents=True, exist_ok=True)
    background = (200, 60, 200, 255)
    reference = Image.new("RGBA", (SIZE, SIZE), background)
    reference.alpha_composite(to_canvas(load_master()))
    rest = compose({}, False, background)
    difference = np.abs(np.array(rest).astype(int) - np.array(reference).astype(int))[..., :3].max(axis=2)
    amplified = Image.fromarray(np.clip(difference * 4, 0, 255).astype(np.uint8), "L").convert("RGBA")
    side = Image.new("RGBA", (SIZE * 3, SIZE), background)
    side.paste(rest, (0, 0))
    side.paste(reference, (SIZE, 0))
    side.paste(amplified, (SIZE * 2, 0))
    side.convert("RGB").save(folder / "rest_vs_original.png")

    frames = [
        ("wing -20", {"wing": -20}, False),
        ("wing 0", {}, False),
        ("wing +20", {"wing": 20}, False),
        ("crest -8", {"crest": -8}, False),
        ("crest +8", {"crest": 8}, False),
        ("tail -8", {"tail": -8}, False),
        ("tail +8", {"tail": 8}, False),
        ("eyes closed", {}, True),
    ]
    sheet = Image.new("RGB", (SIZE * 4, (SIZE + 24) * 2), (240, 236, 228))
    draw = ImageDraw.Draw(sheet)
    for index, (label, pose, eyes) in enumerate(frames):
        frame = compose(pose, eyes, background)
        x, y = (index % 4) * SIZE, (index // 4) * (SIZE + 24)
        sheet.paste(frame.convert("RGB"), (x, y))
        draw.text((x + 8, y + SIZE + 6), label, fill=(40, 30, 20))
        frame.convert("RGB").save(folder / f"frame_{index}.png")
    sheet.save(folder / "contact_sheet.png")
    for name in ORDER:
        alone = Image.new("RGBA", (SIZE, SIZE), background)
        alone.alpha_composite(load_canvas(name))
        alone.convert("RGB").save(folder / f"layer_{name}.png")
    return {"max_diff": int(difference.max()), "mean_diff": round(float(difference.mean()), 3), "pixels_over_16": int((difference > 16).sum())}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("step", choices=["layers", "preview", "all"], nargs="?", default="all")
    parser.add_argument("--quality", type=int, default=90)
    args = parser.parse_args()
    report = {}
    if args.step in ("layers", "all"):
        layers, gap = build_layers(load_master())
        report["sizes"] = save_layers(layers, args.quality)
        report["total"] = sum(report["sizes"].values())
        report["crest_gap_degrees"] = [round(gap[0], 1), round(gap[1], 1)]
        write_rig()
    if args.step in ("preview", "all"):
        report["rest"] = preview()
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
