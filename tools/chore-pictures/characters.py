import argparse
import json
import pathlib

from PIL import Image

from process import cut_out

HERE = pathlib.Path(__file__).resolve().parent


def box_of(image: Image.Image):
    return image.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", default=str(HERE / "work/characters/raw"))
    parser.add_argument("--out", default=str(HERE.parent.parent.parent / "NestPrep-Home/app/src/main/assets/celebration"))
    parser.add_argument("--size", type=int, default=512)
    args = parser.parse_args()
    entries = json.loads((HERE / "characters.json").read_text())
    raw, out = pathlib.Path(args.raw), pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    cuts = {entry["id"]: cut_out(raw / f"{entry['id']}.png", 18, None) for entry in entries}
    groups: dict[str, list[str]] = {}
    for entry in entries:
        groups.setdefault(entry.get("pose_of", entry["id"]), []).append(entry["id"])
    for ids in groups.values():
        boxes = [box_of(cuts[i]) for i in ids]
        box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
        side = max(box[2] - box[0], box[3] - box[1])
        for i in ids:
            subject = cuts[i].crop(box)
            canvas = Image.new("RGBA", (side, side), (255, 255, 255, 0))
            canvas.paste(subject, ((side - subject.width) // 2, (side - subject.height) // 2), subject)
            canvas.resize((args.size, args.size), Image.LANCZOS).save(out / f"{i}.webp", "WEBP", quality=82, method=6)
            print("ok", i, flush=True)


if __name__ == "__main__":
    main()
