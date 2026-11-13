import argparse
import base64
import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
MODEL = "gemini-3.1-flash-image"
API_ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
VERTEX_ENDPOINT = f"https://aiplatform.googleapis.com/v1/projects/nestprep-643b7/locations/global/publishers/google/models/{MODEL}:generateContent"
ANCHORS = [
    HERE.parent / "chore-pictures/work/characters/raw/bird-up.png",
    HERE.parent / "chore-pictures/anchors/make-bed.png",
]

PALETTE = (
    "Warm limited palette: coral pink #F57B91, butter yellow #F3D886, lilac #C9BCE8, sage green #7FA07F, "
    "deep basil green #465C48, warm cream #FFF8ED, plus natural colours only where needed. "
    "Bold, even, rounded dark plum outlines (#35252E) about 3% of the image width, flat fills with at most one soft "
    "lighter highlight shape, no gradients, no texture, no photorealism, no 3D."
)

ISOLATED = (
    "Absolutely no text, letters or numbers. No people, no hands, no human faces. Isolated on a pure flat white "
    "#FFFFFF background with no ground shadow, no border and no scenery."
)

STYLES = {
    "nestling": (
        "A single cute original cartoon character for a children's app profile picture. Clean modern flat vector "
        "illustration, soft rounded chunky shapes, friendly and instantly lovable to a four-year-old. "
        f"{PALETTE} The character faces the viewer, its face in the upper middle of the picture, and the whole "
        "character is centred and fills about 78% of a square frame so it reads inside a circle crop. "
        f"Not based on any existing cartoon, film, game or brand character. {ISOLATED}"
    ),
    "portrait": (
        "A single cute original cartoon character for a children's app profile picture that is shown as small as "
        "a fingertip, so the face must be big. Clean modern flat vector illustration, soft rounded chunky shapes, "
        f"friendly and instantly lovable to a four-year-old. {PALETTE} Framed as a head-and-shoulders portrait "
        "bust: the head is very big, about two thirds of the picture height, facing the viewer, with the face "
        "centred in the upper middle; below it only the shoulders and top of the chest, which round off softly "
        "into a smooth curved bottom edge like a bust sticker. Wings, arms and tail stay tucked in close; nothing "
        "spreads out sideways. The bust is centred and fills about 85% of a square frame, with a margin of white all round: nothing touches the edges of the picture. Not based on any "
        f"existing cartoon, film, game or brand character. {ISOLATED}"
    ),
    "accessory": (
        "A single cheerful flat vector clipart sticker of an accessory for a children's app avatar. "
        f"{PALETTE} The object is centred and fills about 80% of a square frame. {ISOLATED}"
    ),
}


def jobs(catalogue: dict) -> list[dict]:
    entries = []
    for n in catalogue["nestlings"]:
        hatchling = f"nestling-{n['name']}-1"
        creature = n["creature"]
        entries += [
            {"id": hatchling, "style": "nestling", "anchored": True,
             "subject": f"{n['label']}, {n['hatchling']}, sitting inside the bottom half of a cracked cream eggshell"},
            {"id": f"nestling-{n['name']}-0", "style": "nestling", "ref": hatchling,
             "subject": f"a whole unhatched cream egg with {n['egg']} and a small zigzag crack near the top, with the "
                        f"big round happy eyes of the baby {creature} from the last reference image peeking out "
                        "through the crack. Only the egg"},
            {"id": f"nestling-{n['name']}-2", "style": "portrait", "ref": hatchling,
             "subject": f"a close-up head-and-shoulders portrait, cropped at the chest like a passport photo and not "
                        f"the full body, of the same baby {creature} from the last reference image now a little older, "
                        f"a young {creature}: same colours, same eyes and face, {n['young']}, no eggshell. Its head "
                        "fills most of the picture"},
            {"id": f"nestling-{n['name']}-3", "style": "portrait", "ref": hatchling,
             "subject": f"a close-up head-and-shoulders portrait, cropped at the chest like a passport photo and not "
                        f"the full body, of the same {creature} from the last reference image fully grown up into an "
                        f"adult: same colours, same eyes and face, {n['grown']}, looking proud and happy, no eggshell. "
                        "Clearly more grown-up than a chick: a less baby-round head, longer sleeker feathers or fur and "
                        "its signature features fully grown. "
                        "Its head fills most of the picture"},
        ]
    entries += [{"id": f"acc-{a['id']}", "style": "accessory", "anchored": True, "subject": a["subject"]}
                for a in catalogue["accessories"]]
    entries += [{"id": f"moment-{m['id']}", "style": "accessory", "anchored": True, "subject": m["subject"]}
                for m in catalogue["moments"] if "subject" in m]
    return entries


def body(entry: dict, references: list[bytes]) -> dict:
    parts = [{"inlineData": {"mimeType": "image/png", "data": base64.b64encode(r).decode()}} for r in references]
    lead = "Match the illustration style of the reference images: same outline weight, palette and flatness. " if references else ""
    note = f" {entry['note']}" if entry.get("note") else ""
    parts.append({"text": f"{STYLES[entry['style']]}\n\n{lead}Draw: {entry['subject']}.{note}"})
    return {
        "contents": [{"role": "user", "parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "1:1"}},
    }


def door() -> tuple[str, dict]:
    if os.environ.get("GEMINI_API_KEY"):
        return API_ENDPOINT, {"x-goog-api-key": os.environ["GEMINI_API_KEY"]}
    bearer = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()
    return VERTEX_ENDPOINT, {"Authorization": f"Bearer {bearer}"}


def generate(entry: dict, references: list[bytes]) -> bytes:
    url, headers = door()
    request = urllib.request.Request(
        url,
        data=json.dumps(body(entry, references)).encode(),
        headers={**headers, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        reply = json.load(response)
    for candidate in reply.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
    raise RuntimeError(f"no image: {json.dumps(reply)[:300]}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalogue", default=str(HERE / "catalogue.json"))
    parser.add_argument("--out", default=str(HERE / "work/raw"))
    parser.add_argument("--ids", nargs="*", default=[])
    parser.add_argument("--note", default="")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()

    entries = jobs(json.loads(pathlib.Path(args.catalogue).read_text()))
    if args.list:
        print("\n".join(e["id"] for e in entries))
        return
    if args.ids:
        entries = [e for e in entries if e["id"] in set(args.ids)]
    anchors = [a.read_bytes() for a in ANCHORS]
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    failed = []
    for entry in sorted(entries, key=lambda e: "ref" in e):
        entry["note"] = args.note
        target = out / f"{entry['id']}.png"
        if target.exists() and not args.force:
            continue
        references = anchors if entry.get("anchored") else []
        if "ref" in entry:
            if not (out / f"{entry['ref']}.png").exists():
                failed.append(entry["id"])
                continue
            references = [(out / f"{entry['ref']}.png").read_bytes()]
        for attempt in range(4):
            try:
                target.write_bytes(generate(entry, references))
                print(f"ok {entry['id']}", flush=True)
                break
            except (urllib.error.HTTPError, urllib.error.URLError, RuntimeError, TimeoutError, OSError) as error:
                detail = error.read().decode()[:200] if isinstance(error, urllib.error.HTTPError) else str(error)
                print(f"retry {entry['id']} {attempt}: {detail}", file=sys.stderr, flush=True)
                time.sleep(5 * (attempt + 1))
        else:
            failed.append(entry["id"])
    print(json.dumps({"failed": failed}), flush=True)


if __name__ == "__main__":
    main()
