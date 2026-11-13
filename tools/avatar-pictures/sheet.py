import argparse
import json
import pathlib

from PIL import Image, ImageDraw

HERE = pathlib.Path(__file__).resolve().parent
BACKGROUNDS = {"oat": ("#FFF8ED", "#35252E"), "night": ("#211A20", "#FFF8ED")}
CHIP = "#F9D7DE"


def rows(catalogue: dict, kind: str) -> list[list[str]]:
    if kind in ("nestlings", "faces"):
        return [[f"nestling-{n['name']}-{s}" for s in range(4)] for n in catalogue["nestlings"]]
    if kind == "accessories":
        ids = [f"acc-{a['id']}" for a in catalogue["accessories"]]
    else:
        ids = [f"moment-{m.get('art', m['id'])}" for m in catalogue["moments"] if "subject" in m]
    return [ids[i : i + 6] for i in range(0, len(ids), 6)]


def tiny(picture: Image.Image, size: int) -> Image.Image:
    chip = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    fill = Image.new("RGBA", (size, size), CHIP)
    chip.paste(fill, (0, 0), mask)
    small = picture.resize((size, size), Image.LANCZOS)
    inside = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inside.paste(small, (0, 0), small)
    chip.paste(inside, (0, 0), Image.composite(inside.getchannel("A"), Image.new("L", (size, size), 0), mask))
    return chip


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=["nestlings", "faces", "accessories", "moments"])
    parser.add_argument("background", choices=list(BACKGROUNDS))
    parser.add_argument("out")
    parser.add_argument("--work", default=str(HERE / "work/384"))
    parser.add_argument("--cell", type=int, default=200)
    parser.add_argument("--rows", default="", help="first:last row, for a part of a long sheet")
    parser.add_argument("--wear", default="acc-round-glasses", help="the face accessory a faces sheet tries on")
    parser.add_argument("--grid", action="store_true", help="tenths over every picture, to read a face anchor off")
    args = parser.parse_args()
    catalogue = json.loads((HERE / "catalogue.json").read_text())
    background, ink = BACKGROUNDS[args.background]
    grid = rows(catalogue, args.kind)
    faces = {
        f"nestling-{n['name']}-{stage}": face
        for n in catalogue["nestlings"]
        for stage, face in enumerate(n.get("faces", []))
        if face
    }
    if args.rows:
        first, last = (int(v) for v in args.rows.split(":"))
        grid = grid[first:last]
    cell, label = args.cell, 18
    width = max(len(r) for r in grid) * cell
    sheet = Image.new("RGB", (width, len(grid) * (cell + label)), background)
    draw = ImageDraw.Draw(sheet)
    for y, row in enumerate(grid):
        for x, asset_id in enumerate(row):
            left, top = x * cell, y * (cell + label)
            path = pathlib.Path(args.work) / f"{asset_id}.webp"
            if path.exists():
                picture = Image.open(path).convert("RGBA")
                big = picture.resize((cell - 16, cell - 16), Image.LANCZOS)
                sheet.paste(big, (left + 8, top + 8), big)
                if args.grid:
                    for tenth in range(1, 10):
                        at = 8 + tenth * (cell - 16) // 10
                        draw.line((left + at, top + 8, left + at, top + cell - 8), fill="#3B82C4")
                        draw.line((left + 8, top + at, left + cell - 8, top + at), fill="#3B82C4")
                if args.kind == "faces" and asset_id in faces:
                    face = faces[asset_id]
                    side = round(face["w"] * 1.6 * (cell - 16))
                    worn = Image.open(pathlib.Path(args.work) / f"{args.wear}.webp").convert("RGBA").resize((side, side), Image.LANCZOS)
                    centre = (left + 8 + face["x"] * (cell - 16), top + 8 + face["y"] * (cell - 16))
                    sheet.paste(worn, (round(centre[0] - side / 2), round(centre[1] - side / 2)), worn)
                if args.kind == "nestlings":
                    chip = tiny(picture, 56)
                    sheet.paste(chip, (left + cell - 60, top + cell - 60), chip)
            else:
                draw.text((left + 20, top + cell // 2), "missing", fill="#F57B91")
            draw.text((left + 4, top + cell), asset_id[:32], fill=ink)
    sheet.save(args.out)
    print(args.out)


if __name__ == "__main__":
    main()
