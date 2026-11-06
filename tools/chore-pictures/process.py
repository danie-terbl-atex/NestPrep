import argparse
import json
import pathlib
from collections import deque

from PIL import Image, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent


def is_white(pixel: tuple[int, int, int], tolerance: int) -> bool:
    return min(pixel) >= 255 - tolerance


def background_mask(image: Image.Image, tolerance: int) -> Image.Image:
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    mask = Image.new("L", rgb.size, 0)
    marked = mask.load()
    queue = deque()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if marked[x, y] or not is_white(pixels[x, y], tolerance):
            continue
        marked[x, y] = 255
        if x > 0:
            queue.append((x - 1, y))
        if x < width - 1:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y < height - 1:
            queue.append((x, y + 1))
    return mask


def clear_enclosed(image: Image.Image, mask: Image.Image, tolerance: int, holes) -> None:
    """White enclosed by the drawing (a basket handle, cage bars) is background only where
    holes.json says so: colour alone cannot tell it from a white object such as milk or an egg."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    marked = mask.load()
    seen = bytearray(width * height)
    for y in range(height):
        for x in range(width):
            if seen[y * width + x] or marked[x, y] or not is_white(pixels[x, y], tolerance):
                continue
            queue, region = deque([(x, y)]), []
            seen[y * width + x] = 1
            while queue:
                a, b = queue.popleft()
                region.append((a, b))
                for c, d in ((a - 1, b), (a + 1, b), (a, b - 1), (a, b + 1)):
                    if 0 <= c < width and 0 <= d < height and not seen[d * width + c] and not marked[c, d] and is_white(pixels[c, d], tolerance):
                        seen[d * width + c] = 1
                        queue.append((c, d))
            if len(region) < 0.0015 * width * height:
                continue
            cx = sum(p[0] for p in region) / len(region)
            cy = sum(p[1] for p in region) / len(region)
            if holes == "all" or any(abs(cx - hx) < 30 and abs(cy - hy) < 30 for hx, hy in holes):
                for a, b in region:
                    marked[a, b] = 255


def cut_out(path: pathlib.Path, tolerance: int, holes) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    mask = background_mask(image, tolerance)
    if holes:
        clear_enclosed(image, mask, tolerance, holes)
    background = mask.filter(ImageFilter.MaxFilter(3))
    image.putalpha(Image.eval(background.filter(ImageFilter.GaussianBlur(1.2)), lambda v: 255 - v))
    return image


def square(image: Image.Image, margin: float) -> Image.Image:
    box = image.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    if box is None:
        raise ValueError("empty picture")
    subject = image.crop(box)
    side = int(max(subject.size) * (1 + 2 * margin))
    canvas = Image.new("RGBA", (side, side), (255, 255, 255, 0))
    canvas.paste(subject, ((side - subject.width) // 2, (side - subject.height) // 2), subject)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", required=True)
    parser.add_argument("--out", required=True, nargs="+", help="dir:size pairs")
    parser.add_argument("--holes", default=str(HERE / "holes.json"))
    parser.add_argument("--tolerance", type=int, default=18)
    parser.add_argument("--margin", type=float, default=0.04)
    parser.add_argument("--ids", nargs="*", default=[])
    args = parser.parse_args()
    holes = json.loads(pathlib.Path(args.holes).read_text())
    targets = [(pathlib.Path(spec.split(":")[0]), int(spec.split(":")[1])) for spec in args.out]
    for directory, _ in targets:
        directory.mkdir(parents=True, exist_ok=True)
    sources = sorted(pathlib.Path(args.raw).glob("*.png"))
    if args.ids:
        sources = [s for s in sources if s.stem in set(args.ids)]
    for source in sources:
        picture = square(cut_out(source, args.tolerance, holes.get(source.stem)), args.margin)
        for directory, size in targets:
            picture.resize((size, size), Image.LANCZOS).save(
                directory / f"{source.stem}.webp", "WEBP", quality=82, method=6
            )
        print("ok", source.stem, flush=True)


if __name__ == "__main__":
    main()
