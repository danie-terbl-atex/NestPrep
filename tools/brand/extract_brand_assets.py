"""Cut NestPrep's app assets out of the official logo (design-system ADR-0003).

The logo is one JPEG in the vault (`nestprep-project/brand/NestPrep logo.jpeg`):
a white rounded card on a pale page, the nest illustration on a flat beige
shadow, and the wordmark "Nest Prep" in one forest green underneath. Run this
again whenever Daniel replaces it; everything it writes is derived.

    python3 -m venv .venv && .venv/bin/pip install Pillow numpy scipy
    .venv/bin/python tools/brand/extract_brand_assets.py "<path to the logo>"
    cd app && dart run flutter_launcher_icons && dart run flutter_native_splash:create

What it writes, under `app/assets/brand/`:

- `nest_mark.png` — the nest without the words, on transparent. The page and
  the shadow ellipse are flooded inward from the crop's edge, so white that is
  *inside* the drawing (the calendar page, the tick's inner stroke) survives
  because an outline encloses it. The 1-3 px fringe is un-mixed against the
  colour it was blended with, so the edge is soft on any background, not haloed.
- `nest_wordmark.png` — the words alone, as an alpha mask painted in the brand
  forest. The app tints it with a token, so the same file works in dark.
- `launcher/app_icon.png` — the iOS and legacy Android icon: the mark on cream,
  opaque (the App Store refuses alpha).
- `launcher/app_icon_foreground.png` — the Android adaptive foreground: the mark
  fitted inside the 66 dp safe circle of a 108 dp layer, so no launcher mask
  ever clips the tick or the heart.
- `launcher/splash_mark.png` / `splash_android12.png` — the native splash at
  the session gate's size, and Android 12's, whose icon is masked to a circle
  two thirds of its box.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# Colours sampled from the logo. The cream is the app's light canvas
# (`NestColors.light.canvas`), so the splash hands over to the first screen
# without a flash; keep the two in step.
CREAM = (0xF4, 0xED, 0xDF)
WHITE = np.array([255.0, 255.0, 255.0])
SHADOW = np.array([231.0, 218.0, 201.0])
FOREST = np.array([0x32, 0x53, 0x3C], dtype=float)

# The logo's own layout, in source pixels: the mark, then the words.
MARK_BOX = (205, 205, 825, 668)
WORDMARK_BOX = (205, 680, 825, 825)
UPSCALE = 2

ICON = 1024
RUNTIME_WIDTH = 720
# Adaptive icons: a 108 dp layer whose 66 dp centre circle is never masked.
SAFE_RADIUS = ICON * 66 / 108 / 2


def load(path):
    src = Image.open(path).convert('RGB')
    big = src.resize((src.width * UPSCALE, src.height * UPSCALE), Image.LANCZOS)
    return np.asarray(big).astype(float)


def crop(pixels, box):
    x0, y0, x1, y1 = (v * UPSCALE for v in box)
    return pixels[y0:y1, x0:x1].copy()


def trim(rgba, pad):
    ys, xs = np.where(rgba[..., 3] > 8)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    out = np.zeros((y1 - y0 + 2 * pad, x1 - x0 + 2 * pad, 4), dtype=np.uint8)
    out[pad:pad + y1 - y0, pad:pad + x1 - x0] = rgba[y0:y1, x0:x1]
    return out


def cut_mark(pixels):
    px = crop(pixels, MARK_BOX)
    spread = px.max(axis=2) - px.min(axis=2)
    page = (px.min(axis=2) >= 236) & (spread <= 16)
    shadow = np.linalg.norm(px - SHADOW, axis=2) <= 20
    labels, _ = ndimage.label(page | shadow)
    edge = np.unique(
        np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])
    )
    background = np.isin(labels, edge[edge != 0])
    keep = ndimage.binary_opening(~background, iterations=1)

    core = ndimage.binary_erosion(keep, iterations=3)
    fringe = keep & ~core
    # Each pixel's "true" colour is its nearest core pixel's; what it was
    # blended with is its nearest background pixel's.
    _, core_at = ndimage.distance_transform_edt(~core, return_indices=True)
    _, bg_at = ndimage.distance_transform_edt(keep, return_indices=True)
    fg = px[core_at[0], core_at[1]]
    bg = px[bg_at[0], bg_at[1]]
    num = np.linalg.norm(px - bg, axis=2)
    den = np.maximum(np.linalg.norm(fg - bg, axis=2), 1.0)
    alpha = np.where(core, 1.0, np.where(fringe, np.clip(num / den, 0, 1), 0.0))
    safe = np.maximum(alpha, 1e-3)[..., None]
    colour = np.where(fringe[..., None], (px - (1 - safe) * bg) / safe, px)
    alpha = np.where(keep, ndimage.gaussian_filter(alpha, 0.6), 0.0)
    rgba = np.dstack([np.clip(colour, 0, 255), np.clip(alpha, 0, 1) * 255])
    return trim(rgba.astype(np.uint8), pad=8)


def cut_wordmark(pixels):
    px = crop(pixels, WORDMARK_BOX)
    darkness = (255.0 - px.mean(axis=2)) / (255.0 - FOREST.mean())
    alpha = np.clip((darkness - 0.04) / 0.92, 0, 1)
    rgba = np.zeros(px.shape[:2] + (4,), dtype=np.uint8)
    rgba[..., :3] = FOREST.astype(np.uint8)
    rgba[..., 3] = (alpha * 255).astype(np.uint8)
    return trim(rgba, pad=4)


def reach(mark):
    """The furthest opaque pixel from the mark's centre, in its own pixels."""
    ys, xs = np.where(np.asarray(mark)[..., 3] > 24)
    cy, cx = mark.height / 2, mark.width / 2
    return float(np.sqrt((ys - cy) ** 2 + (xs - cx) ** 2).max())


def placed(mark, size, radius, background):
    """The mark centred on a square, scaled so its furthest pixel is `radius`."""
    scale = radius / reach(mark)
    fitted = mark.resize(
        (round(mark.width * scale), round(mark.height * scale)), Image.LANCZOS
    )
    canvas = Image.new('RGBA', (size, size), background)
    canvas.alpha_composite(
        fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2)
    )
    return canvas


def runtime(image):
    """The bundled copy: wide enough for the largest place it is drawn (the
    welcome, about 240 dp) at 3x, and no wider, so the binary stays small."""
    if image.width <= RUNTIME_WIDTH:
        return image
    height = round(image.height * RUNTIME_WIDTH / image.width)
    return image.resize((RUNTIME_WIDTH, height), Image.LANCZOS)


def main(logo, app_dir):
    out = Path(app_dir) / 'assets' / 'brand'
    launcher = out / 'launcher'
    launcher.mkdir(parents=True, exist_ok=True)
    pixels = load(logo)

    mark = Image.fromarray(cut_mark(pixels))
    for name, image in (
        ('nest_mark.png', mark),
        ('nest_wordmark.png', Image.fromarray(cut_wordmark(pixels))),
    ):
        runtime(image).save(out / name, optimize=True)

    # The icon's mark fills more of the square than the adaptive one may:
    # iOS masks to a rounded square, not a circle.
    placed(mark, ICON, ICON * 0.46, CREAM + (255,)).convert('RGB').save(
        launcher / 'app_icon.png', optimize=True
    )
    placed(mark, ICON, SAFE_RADIUS - 6, (0, 0, 0, 0)).save(
        launcher / 'app_icon_foreground.png', optimize=True
    )
    # The pre-12 and iOS splash draw this at 4x density. The nest is 736 px
    # wide — 184 dp, `NestSize.brandMarkLarge` — the size the session gate
    # opens on, so the hand-over does not change the nest's size.
    mark.resize(
        (736, round(mark.height * 736 / mark.width)), Image.LANCZOS
    ).save(launcher / 'splash_mark.png', optimize=True)
    # Android 12: 1152 px box, icon masked to a circle of 768 px.
    placed(mark, 1152, 384 - 12, (0, 0, 0, 0)).save(
        launcher / 'splash_android12.png', optimize=True
    )
    print('wrote', ', '.join(sorted(p.name for p in out.rglob('*.png'))))


if __name__ == '__main__':
    here = Path(__file__).resolve().parents[2] / 'app'
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else here)
