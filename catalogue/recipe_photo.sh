#!/bin/zsh
# Generate a recipe photo with NestPrep's image model and write hero.jpg + card.jpg.
#   recipe_photo.sh generate <id>...                 (each id's scene is its entry in recipe-photo-scenes.json)
#   recipe_photo.sh resize   <id> <source-image-path> (for an openly licensed photo you downloaded)
# Output: catalogue/recipe-photos/<id>/{hero,card}.jpg beside this script. Needs gcloud signed in with access to the project.
set -euo pipefail
export PATH="$HOME/google-cloud-sdk/bin:$PATH"
HERE="${0:A:h}"
PROJECT="${NESTPREP_PROJECT:-nestprep-643b7}"
MODEL="${NESTPREP_IMAGE_MODEL:-gemini-3-pro-image}"
MODE=$1; shift
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
finish() {
  local id=$1 src=$2 out="$HERE/recipe-photos/$1"
  mkdir -p "$out"
  # crop to 4:3 around the centre, then size
  local w h; w=$(sips -g pixelWidth "$src" | awk '/pixelWidth/{print $2}'); h=$(sips -g pixelHeight "$src" | awk '/pixelHeight/{print $2}')
  local tw=$w th=$(( w * 3 / 4 ))
  if (( th > h )); then th=$h; tw=$(( h * 4 / 3 )); fi
  sips -c $th $tw "$src" --out "$WORK/$id-crop.png" -s format png >/dev/null
  sips -Z 1200 -s format jpeg -s formatOptions 85 "$WORK/$id-crop.png" --out "$out/hero.jpg" >/dev/null
  sips -Z 640 -s format jpeg -s formatOptions 80 "$WORK/$id-crop.png" --out "$out/card.jpg" >/dev/null
  echo "$id: wrote hero.jpg ($(stat -f%z "$out/hero.jpg") bytes) and card.jpg ($(stat -f%z "$out/card.jpg") bytes)"
}
if [[ $MODE == resize ]]; then finish "$1" "$2"; exit 0; fi
STYLE="The same set for every dish: a bright, premium, modern home kitchen. The dish stands on a warm cream travertine countertop; behind it, in soft creamy bokeh, a warm oat-coloured plastered wall, pale honey-oak open shelving with cream stoneware, and a small sprig of fresh herbs in a sage-green ceramic vase. Soft diffused daylight from the left, gentle shadows, a warm palette of cream, sand, honey oak and sage green with a touch of blush pink. Styled like a high-end food magazine shoot: the food is the hero, generous, glistening and appetising, steaming when hot. Camera at a three-quarter angle of about 35 degrees, the dish filling most of the frame. Shot on a full-frame camera with an 85mm lens, true-to-life colour, real food textures with crumbs, drips and small imperfections, shallow depth of field. No text, no people, no hands, no logos, no branded packaging, no watermark."
TOKEN=$(gcloud auth print-access-token)
FAILED=()
for ID in "$@"; do
  /usr/bin/python3 - "$HERE/recipe-photo-scenes.json" "$ID" "$STYLE" > "$WORK/$ID-body.json" <<'PY'
import json,sys
scenes=json.load(open(sys.argv[1]))
if sys.argv[2] not in scenes: sys.exit(f"no scene for {sys.argv[2]} in recipe-photo-scenes.json")
print(json.dumps({"contents":[{"role":"user","parts":[{"text":f"Photograph of {scenes[sys.argv[2]]} {sys.argv[3]}"}]}],
 "generationConfig":{"responseModalities":["IMAGE"],"imageConfig":{"aspectRatio":"4:3","imageSize":"2K"}}}))
PY
  done_id=0
  for attempt in 1 2 3 4 5; do
    curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "x-goog-user-project: $PROJECT" \
      "https://aiplatform.googleapis.com/v1/projects/$PROJECT/locations/global/publishers/google/models/${MODEL}:generateContent" \
      -d @"$WORK/$ID-body.json" -o "$WORK/$ID-out.json"
    if /usr/bin/python3 - "$WORK/$ID-out.json" "$WORK/$ID-gen.png" <<'PY'
import json,base64,sys
d=json.load(open(sys.argv[1]))
try:
  for p in d['candidates'][0]['content']['parts']:
    if 'inlineData' in p:
      open(sys.argv[2],'wb').write(base64.b64decode(p['inlineData']['data'])); sys.exit(0)
except Exception: pass
print('no image in reply:', json.dumps(d)[:300], file=sys.stderr); sys.exit(1)
PY
    then finish "$ID" "$WORK/$ID-gen.png"; done_id=1; break; fi
    sleep $(( attempt * 20 ))
  done
  (( done_id )) || FAILED+=("$ID")
done
(( ${#FAILED} == 0 )) || { echo "FAILED to generate: ${FAILED[*]}" >&2; exit 1; }
