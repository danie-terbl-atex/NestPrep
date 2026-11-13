import argparse
import importlib.util
import json
import pathlib
from collections import deque

from PIL import Image, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("chore_process", HERE.parent / "chore-pictures/process.py")
chore_process = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(chore_process)

SIZES = (384, 128)
EYE_SEATS = ((0.5 - 0.3125 / 1.4, 0.5), (0.5 + 0.3125 / 1.4, 0.5))


def see_through(catalogue: dict) -> set[str]:
    return {
        f"{prefix}-{e['id']}"
        for prefix, kind in (("acc", "accessories"), ("moment", "moments"))
        for e in catalogue[kind]
        if e["slot"] in ("face", "ring") or e.get("see_through")
    }


def seated(picture: Image.Image, eyes: list[list[float]], scale: float | None) -> Image.Image:
    """A face accessory is drawn 1.6 x a Nestling's face width, centred between its eyes, and that width is
    1.4 x the distance between the eye centres: so the eye holes of every face accessory sit on EYE_SEATS.
    One eye point (a monocle) sits on the right seat at the given scale."""
    side = picture.width
    if len(eyes) == 2:
        scale = (EYE_SEATS[1][0] - EYE_SEATS[0][0]) / (eyes[1][0] - eyes[0][0])
        from_x, from_y = (eyes[0][0] + eyes[1][0]) / 2, (eyes[0][1] + eyes[1][1]) / 2
        to_x, to_y = 0.5, 0.5
    else:
        (from_x, from_y), (to_x, to_y) = eyes[0], EYE_SEATS[1]
    size = round(side * scale)
    canvas = Image.new("RGBA", (side, side), (255, 255, 255, 0))
    canvas.paste(picture.resize((size, size), Image.LANCZOS), (round(to_x * side - from_x * size), round(to_y * side - from_y * size)))
    return canvas


def drop_islands(image: Image.Image, share: float = 0.02) -> list[int]:
    """A character is one piece: sparkles and shell chips the model scatters round it are cut away."""
    width, height = image.size
    alpha = image.getchannel("A")
    solid = alpha.point(lambda v: 255 if v > 24 else 0).tobytes()
    label = [0] * (width * height)
    sizes = [0]
    for start in range(width * height):
        if not solid[start] or label[start]:
            continue
        sizes.append(0)
        mark = len(sizes) - 1
        label[start] = mark
        queue = deque([start])
        while queue:
            at = queue.popleft()
            sizes[mark] += 1
            x = at % width
            for near in (at - width, at + width, at - 1 if x else -1, at + 1 if x < width - 1 else -1):
                if 0 <= near < width * height and solid[near] and not label[near]:
                    label[near] = mark
                    queue.append(near)
    keep = max(sizes) * share
    dropped = [size for size in sizes[1:] if size < keep]
    if dropped:
        near_kept = Image.frombytes("L", image.size, bytes(255 if sizes[m] >= keep else 0 for m in label))
        image.putalpha(Image.composite(alpha, Image.new("L", image.size, 0), near_kept.filter(ImageFilter.MaxFilter(9))))
    return dropped


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", default=str(HERE / "work/raw"))
    parser.add_argument("--work", default=str(HERE / "work"))
    parser.add_argument("--tolerance", type=int, default=18)
    parser.add_argument("--margin", type=float, default=0.03)
    parser.add_argument("--ids", nargs="*", default=[])
    args = parser.parse_args()
    catalogue = json.loads((HERE / "catalogue.json").read_text())
    holes = see_through(catalogue)
    tidy = {f"acc-{a['id']}" for a in catalogue["accessories"] if a.get("one_piece")}
    eyes = {f"acc-{a['id']}": a for a in catalogue["accessories"] if "eyes" in a}
    work = pathlib.Path(args.work)
    for size in SIZES:
        (work / str(size)).mkdir(parents=True, exist_ok=True)
    sources = sorted(pathlib.Path(args.raw).glob("*.png"))
    if args.ids:
        sources = [s for s in sources if s.stem in set(args.ids)]
    for source in sources:
        cut = chore_process.cut_out(source, args.tolerance, "all" if source.stem in holes else None)
        dropped = drop_islands(cut) if source.stem.startswith("nestling-") or source.stem in tidy else []
        picture = chore_process.square(cut, args.margin)
        if source.stem in eyes:
            picture = seated(picture, eyes[source.stem]["eyes"], eyes[source.stem].get("scale"))
        for size in SIZES:
            picture.resize((size, size), Image.LANCZOS).save(
                work / str(size) / f"{source.stem}.webp", "WEBP", quality=82, method=6
            )
        print("ok", source.stem, f"dropped {dropped}" if dropped else "", flush=True)


if __name__ == "__main__":
    main()
