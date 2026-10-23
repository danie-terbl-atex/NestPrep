#!/bin/zsh
# Generate a recipe photo with NestPrep's image model and write hero.jpg + card.jpg.
#   recipe_photo.sh generate <id> "<dish description, as served, with sides, on surface>"
#   recipe_photo.sh resize   <id> <source-image-path>    (for an openly licensed photo you downloaded)
# Output: catalogue/recipe-photos/<id>/{hero,card}.jpg beside this script. Needs gcloud signed in with access to the project (recipe-authoring-guide in the vault).
set -euo pipefail
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
MODE=$1; ID=$2; ARG=$3
OUT="${0:A:h}/recipe-photos/$ID"
WORK=$(mktemp -d)
mkdir -p "$OUT"
finish() {
  local src=$1
  # crop to 4:3 around the centre, then size
  local w h; w=$(sips -g pixelWidth "$src" | awk '/pixelWidth/{print $2}'); h=$(sips -g pixelHeight "$src" | awk '/pixelHeight/{print $2}')
  local tw=$w th=$(( w * 3 / 4 ))
  if (( th > h )); then th=$h; tw=$(( h * 4 / 3 )); fi
  sips -c $th $tw "$src" --out "$WORK/crop.png" -s format png >/dev/null
  sips -Z 1200 -s format jpeg -s formatOptions 70 "$WORK/crop.png" --out "$OUT/hero.jpg" >/dev/null
  sips -Z 640 -s format jpeg -s formatOptions 62 "$WORK/crop.png" --out "$OUT/card.jpg" >/dev/null
  echo "wrote $OUT/hero.jpg ($(stat -f%z "$OUT/hero.jpg") bytes) and card.jpg ($(stat -f%z "$OUT/card.jpg") bytes)"
}
if [[ $MODE == resize ]]; then finish "$ARG"; exit 0; fi
PROMPT="Editorial food photograph of $ARG. Natural window light, shallow depth of field, three-quarter overhead angle, warm and homely South African family kitchen styling. Photorealistic. No text, no people, no hands, no logos, no watermark."
/usr/bin/python3 - "$PROMPT" > "$WORK/body.json" <<'PY'
import json,sys
print(json.dumps({"contents":[{"role":"user","parts":[{"text":sys.argv[1]}]}],
 "generationConfig":{"responseModalities":["IMAGE"],"imageConfig":{"aspectRatio":"4:3"}}}))
PY
TOKEN=$(gcloud auth print-access-token)
for attempt in 1 2 3; do
  curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "x-goog-user-project: ${NESTPREP_PROJECT:-nestprep-643b7}" \
    "https://aiplatform.googleapis.com/v1/projects/${NESTPREP_PROJECT:-nestprep-643b7}/locations/global/publishers/google/models/${NESTPREP_IMAGE_MODEL:-gemini-3.1-flash-image}:generateContent" \
    -d @"$WORK/body.json" -o "$WORK/out.json"
  if /usr/bin/python3 - "$WORK" <<'PY'
import json,base64,sys
d=json.load(open(sys.argv[1]+'/out.json'))
try:
  for p in d['candidates'][0]['content']['parts']:
    if 'inlineData' in p:
      open(sys.argv[1]+'/gen.png','wb').write(base64.b64decode(p['inlineData']['data'])); sys.exit(0)
except Exception: pass
print('no image in reply:', json.dumps(d)[:300], file=sys.stderr); sys.exit(1)
PY
  then finish "$WORK/gen.png"; exit 0; fi
  sleep $(( attempt * 10 ))
done
echo "FAILED to generate $ID" >&2; exit 1
