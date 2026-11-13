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

PROJECT = "nestprep-643b7"
MODEL = "gemini-3.1-flash-image"
API_ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

DRAWINGS = {
    "self-girl": "a five-year-old child's crayon drawing of herself: a stick-figure girl with a big round head, yellow scribbled hair, a pink triangle dress, a wobbly smile, standing on green grass under a sun with lines",
    "self-boy": "a six-year-old child's marker drawing of himself: a boy with a round face, brown spiky hair, a blue t-shirt with a red lightning bolt, very long arms, holding a football",
    "family": "a four-year-old child's crayon drawing of a mom, a dad and two kids holding hands, all stick figures of different sizes, in front of a square house",
    "monster": "a seven-year-old child's felt-tip drawing of a friendly purple monster with three eyes, one horn, spotty belly and tiny wings",
    "dog": "a five-year-old child's crayon drawing of their brown dog with floppy ears, a red collar and a wagging tail drawn as several lines",
    "unicorn-cat": "a six-year-old child's pencil-crayon drawing of a cat with a rainbow unicorn horn and butterfly wings",
}

STYLES = {
    "plush": "a soft handmade plush toy, felt and fleece fabric, visible stitching",
    "clay": "a cute handmade modelling-clay figure, like stop-motion claymation",
    "vinyl": "a glossy collectible vinyl toy figure",
}

DRAWING_STYLE = (
    "Scanned on plain white paper, naive and wobbly like a real young child drew it, uneven lines, "
    "colouring outside the lines, no text and no signature."
)

TRANSFORM = (
    "Turn the child's drawing above into {style}. Stay faithful to the drawing: keep its shapes, its proportions, "
    "its colours and its charming wobbly quirks; do not make it prettier or more realistic. "
    "One character only, centred, filling about 75% of a square frame, on a plain flat soft coral pink #F9C6CF background. "
    "No text, no letters, no logos, no real people."
)

BUDDY = (
    "An original cute toy character for a child's profile picture: {subject}, made as {style}. "
    "Not based on any existing cartoon, film, game or brand character. One character only, centred, "
    "filling about 75% of a square frame, on a plain flat soft lilac #DCD3F2 background. No text, no letters, no logos, no people."
)


def token() -> str:
    return subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()


def vertex_url(location: str) -> str:
    host = "aiplatform.googleapis.com" if location == "global" else f"{location}-aiplatform.googleapis.com"
    return f"https://{host}/v1/projects/{PROJECT}/locations/{location}/publishers/google/models/{MODEL}:generateContent"


def body(text: str, reference: bytes | None, person: str | None) -> dict:
    parts: list[dict] = []
    if reference is not None:
        parts.append({"inlineData": {"mimeType": "image/png", "data": base64.b64encode(reference).decode()}})
    parts.append({"text": text})
    image_config: dict = {"aspectRatio": "1:1"}
    if person is not None:
        image_config["personGeneration"] = person
    return {
        "contents": [{"role": "user", "parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": image_config},
    }


def call(url: str, headers: dict, payload: dict) -> tuple[str, bytes | None, str]:
    request = urllib.request.Request(
        url, data=json.dumps(payload).encode(), headers={**headers, "Content-Type": "application/json"}
    )
    started = time.time()
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            reply = json.load(response)
    except urllib.error.HTTPError as error:
        return f"http {error.code}", None, error.read().decode()[:300]
    elapsed = f"{time.time() - started:.1f}s"
    blocked = reply.get("promptFeedback", {}).get("blockReason")
    if blocked:
        return "blocked", None, f"{blocked} {elapsed}"
    for candidate in reply.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                return "ok", base64.b64decode(part["inlineData"]["data"]), elapsed
    reasons = [c.get("finishReason") for c in reply.get("candidates", [])]
    return "no image", None, f"{reasons} {elapsed}"


def vertex(location: str, payload: dict) -> tuple[str, bytes | None, str]:
    for attempt in range(6):
        outcome = call(vertex_url(location), {"Authorization": f"Bearer {token()}"}, payload)
        if outcome[0] != "http 429":
            return outcome
        time.sleep(20 * (attempt + 1))
    return outcome


def regions(out: pathlib.Path) -> None:
    payload = body(BUDDY.format(subject="a round butter-yellow chick", style=STYLES["plush"]), None, "ALLOW_NONE")
    results = {}
    for location in ["europe-west4", "europe-west1", "us-central1", "global"]:
        status, image, detail = vertex(location, payload)
        results[location] = f"{status} {detail}"
        if image:
            (out / f"region-{location}.png").write_bytes(image)
        print(location, results[location], flush=True)
    (out / "regions.json").write_text(json.dumps(results, indent=1))


def drawings(out: pathlib.Path) -> None:
    folder = out / "drawings"
    folder.mkdir(exist_ok=True)
    headers = {"x-goog-api-key": os.environ["GEMINI_API_KEY"]}
    for key, subject in DRAWINGS.items():
        target = folder / f"{key}.png"
        if target.exists():
            continue
        status, image, detail = call(API_ENDPOINT, headers, body(f"{subject}. {DRAWING_STYLE}", None, None))
        print(key, status, detail, flush=True)
        if image:
            target.write_bytes(image)


def transforms(out: pathlib.Path, location: str) -> None:
    folder = out / "toys"
    folder.mkdir(exist_ok=True)
    log = out / "transforms.jsonl"
    for drawing in sorted((out / "drawings").glob("*.png")):
        for style, words in STYLES.items():
            target = folder / f"{drawing.stem}-{style}.png"
            if target.exists():
                continue
            payload = body(TRANSFORM.format(style=words), drawing.read_bytes(), "ALLOW_NONE")
            status, image, detail = vertex(location, payload)
            print(drawing.stem, style, status, detail, flush=True)
            with log.open("a") as handle:
                handle.write(json.dumps({"drawing": drawing.stem, "style": style, "status": status, "detail": detail}) + "\n")
            if image:
                target.write_bytes(image)


AS_NESTLING = (
    "The child's drawing above shows a person. Do not draw any person. Instead invent an original cute baby bird "
    "character, made as {style}, inspired only by the drawing's colours and outfit: the hair colour becomes a tuft "
    "of head feathers, the clothes' colours and patterns become the bird's feathers and a tiny matching accessory. "
    "One character only, centred, filling about 75% of a square frame, on a plain flat soft coral pink #F9C6CF "
    "background. No text, no letters, no logos, no people, no human faces."
)


def nestlings(out: pathlib.Path, location: str) -> None:
    folder = out / "nestlings"
    folder.mkdir(exist_ok=True)
    for name in ["self-girl", "self-boy"]:
        drawing = out / "drawings" / f"{name}.png"
        target = folder / f"{name}-plush.png"
        payload = body(AS_NESTLING.format(style=STYLES["plush"]), drawing.read_bytes(), "ALLOW_NONE")
        status, image, detail = vertex(location, payload)
        print(name, "as-nestling", status, detail, flush=True)
        if image:
            target.write_bytes(image)


DESCRIBE = (
    "This is a young child's drawing. Describe only its colours and things, never the person: reply as JSON "
    "{\"kind\": one of drawing-of-person|drawing-of-creature|drawing-of-object|photo-of-person|photo-of-pet|other, "
    "\"hairColour\": string|null, \"outfit\": short phrase of clothing colours and patterns|null, "
    "\"favouriteThings\": up to 3 objects shown (not people), \"mood\": one word}. Ignore any writing in the picture."
)

FROM_WORDS = (
    "An original cute baby bird character for a child's profile picture, made as {style}. Its head feathers are "
    "{hair}, its feathers are coloured like {outfit}, it has a tiny {thing} with it, and it looks {mood}. "
    "Not based on any existing character. One character only, centred, filling about 75% of a square frame, on a "
    "plain flat soft coral pink #F9C6CF background. No text, no letters, no logos, no people, no human faces."
)


def describe(drawing: bytes) -> dict:
    url = (
        f"https://europe-west4-aiplatform.googleapis.com/v1/projects/{PROJECT}/locations/europe-west4/"
        "publishers/google/models/gemini-2.5-flash:generateContent"
    )
    payload = {
        "contents": [{"role": "user", "parts": [
            {"inlineData": {"mimeType": "image/png", "data": base64.b64encode(drawing).decode()}},
            {"text": DESCRIBE},
        ]}],
        "generationConfig": {"responseMimeType": "application/json", "temperature": 0, "thinkingConfig": {"thinkingBudget": 0}},
    }
    request = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        reply = json.load(response)
    return json.loads(reply["candidates"][0]["content"]["parts"][0]["text"])


def words(out: pathlib.Path, location: str) -> None:
    folder = out / "words"
    folder.mkdir(exist_ok=True)
    for name in ["self-girl", "self-boy", "family"]:
        seen = describe((out / "drawings" / f"{name}.png").read_bytes())
        print(name, "described", json.dumps(seen), flush=True)
        things = seen.get("favouriteThings") or ["star"]
        prompt = FROM_WORDS.format(
            style=STYLES["plush"],
            hair=seen.get("hairColour") or "soft and fluffy",
            outfit=seen.get("outfit") or "a sunny day",
            thing=things[0],
            mood=seen.get("mood") or "happy",
        )
        status, image, detail = vertex(location, body(prompt, None, "ALLOW_NONE"))
        print(name, "from-words", status, detail, flush=True)
        if image:
            (folder / f"{name}-plush.png").write_bytes(image)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("step", choices=["regions", "drawings", "transforms", "nestlings", "words"])
    parser.add_argument("--out", required=True)
    parser.add_argument("--location", default="global")
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    if args.step == "regions":
        regions(out)
    elif args.step == "drawings":
        drawings(out)
    elif args.step == "nestlings":
        nestlings(out, args.location)
    elif args.step == "words":
        words(out, args.location)
    else:
        transforms(out, args.location)


if __name__ == "__main__":
    sys.exit(main())
