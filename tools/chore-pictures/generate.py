import argparse
import base64
import json
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.request
import os

PROJECT = "nestprep-643b7"
MODEL = "gemini-3.1-flash-image"
ENDPOINT = f"https://aiplatform.googleapis.com/v1/projects/{PROJECT}/locations/global/publishers/google/models/{MODEL}:generateContent"

API_ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

STYLE = (
    "A single cheerful flat vector clipart sticker for a young children's chore chart. "
    "Clean modern flat illustration with bold, even, rounded dark plum outlines (#35252E) about 3% of the image width, "
    "soft rounded chunky shapes, very simple and instantly recognisable to a four-year-old who cannot read. "
    "Warm limited palette: coral pink #F57B91, butter yellow #F3D886, lilac #C9BCE8, sage green #7FA07F, deep basil green #465C48, "
    "warm cream #FFF8ED, plus natural colours only where the object needs them (sky blue water, light brown wood). "
    "Flat fills with at most one soft lighter highlight shape, no gradients, no texture, no photorealism, no 3D. "
    "Friendly and playful; objects may have a tiny happy sparkle but no faces on objects unless it is an animal. "
    "Absolutely no text, letters, numbers or words anywhere. No people, no hands, no human faces. "
    "The subject is centred and fills about 80% of a square frame, isolated on a pure flat white #FFFFFF background, "
    "with no ground shadow, no border, no frame and no background scenery."
)


def token() -> str:
    return subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()


def body(subject: str, references: list[bytes]) -> dict:
    parts: list[dict] = []
    for ref in references:
        parts.append({"inlineData": {"mimeType": "image/png", "data": base64.b64encode(ref).decode()}})
    lead = (
        "Match the exact illustration style of the reference stickers above: same outline weight, palette, "
        "flatness, simplicity and white background. Draw a new sticker of: "
        if references
        else "Draw: "
    )
    parts.append({"text": f"{STYLE}\n\n{lead}{subject}."})
    return {
        "contents": [{"role": "user", "parts": parts}],
        "generationConfig": {
            "responseModalities": ["IMAGE"],
            "imageConfig": {"aspectRatio": "1:1", "personGeneration": "ALLOW_NONE"},
        },
    }


def generate(subject: str, references: list[bytes], bearer: str | None) -> bytes:
    payload = body(subject, references)
    if bearer is None:
        del payload["generationConfig"]["imageConfig"]["personGeneration"]
        url, headers = API_ENDPOINT, {"x-goog-api-key": os.environ["GEMINI_API_KEY"]}
    else:
        url, headers = ENDPOINT, {"Authorization": f"Bearer {bearer}"}
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={**headers, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        reply = json.load(response)
    for candidate in reply.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
    raise RuntimeError(f"no image: {json.dumps(reply)[:300]}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalogue", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--ids", nargs="*", default=[])
    parser.add_argument("--refs", nargs="*", default=[])
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--suffix", default="")
    parser.add_argument("--gemini-api", action="store_true", help="use GEMINI_API_KEY instead of Vertex")
    args = parser.parse_args()

    entries = json.loads(pathlib.Path(args.catalogue).read_text())
    if args.ids:
        wanted = set(args.ids)
        entries = [e for e in entries if e["id"] in wanted]
    references = [pathlib.Path(r).read_bytes() for r in args.refs]
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    bearer, minted = (None if args.gemini_api else token()), time.time()
    failed = []
    for entry in entries:
        target = out / f"{entry['id']}{args.suffix}.png"
        if target.exists() and not args.force:
            continue
        if bearer is not None and time.time() - minted > 1800:
            bearer, minted = (None if args.gemini_api else token()), time.time()
        for attempt in range(4):
            try:
                target.write_bytes(generate(entry["subject"], references, bearer))
                print(f"ok {entry['id']}", flush=True)
                break
            except (urllib.error.HTTPError, urllib.error.URLError, RuntimeError, TimeoutError) as error:
                detail = error.read().decode()[:200] if isinstance(error, urllib.error.HTTPError) else str(error)
                print(f"retry {entry['id']} {attempt}: {detail}", file=sys.stderr, flush=True)
                time.sleep(5 * (attempt + 1))
        else:
            failed.append(entry["id"])
    print(json.dumps({"failed": failed}))


if __name__ == "__main__":
    main()
