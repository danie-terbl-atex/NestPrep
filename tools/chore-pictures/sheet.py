import pathlib
import sys

from PIL import Image, ImageDraw

source, target = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
columns = int(sys.argv[3]) if len(sys.argv) > 3 else 6
cell = int(sys.argv[4]) if len(sys.argv) > 4 else 220
background = sys.argv[5] if len(sys.argv) > 5 else "#C9BCE8"
files = sorted(p for p in source.iterdir() if p.suffix in {".png", ".webp"})
rows = (len(files) + columns - 1) // columns
sheet = Image.new("RGB", (columns * cell, rows * (cell + 18)), background)
draw = ImageDraw.Draw(sheet)
for index, path in enumerate(files):
    image = Image.open(path).convert("RGBA")
    image.thumbnail((cell - 10, cell - 10))
    x, y = (index % columns) * cell, (index // columns) * (cell + 18)
    sheet.paste(image, (x + (cell - image.width) // 2, y + (cell - image.height) // 2), image)
    draw.text((x + 4, y + cell), path.stem[:30], fill="#35252E")
sheet.save(target)
print(target, len(files))
