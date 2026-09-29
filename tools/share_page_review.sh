#!/bin/bash
# Pictures of the shared-link page (documents ADR-0006) for the design review:
# a picture inline, a PDF behind its button, the PIN form after a wrong try and
# an expired link, in light and dark, at 390 px, into app/design-review/.
#
# The page is HTML the `documentShare` Function serves, so the Flutter press
# cannot draw it; this renders it from the built Functions and shoots it with
# headless Chrome (macOS path below). Headless Chrome will not make a window
# narrower than about 500 px, so each page is framed at phone width in the
# middle of a wider window and `sips` keeps the middle.
#
#     npm --prefix functions run build && tools/share_page_review.sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
out="$root/app/design-review"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

(cd "$root/functions" && WORK="$work" node -e "
const {renderSharePage} = require('./lib/documents/share/share_page.js');
const {endsLabel} = require('./lib/documents/share/share_page_copy.js');
const fs = require('fs');
const mark = 'file://' + process.cwd() + '/assets/share/nest_mark.png';
const picture = 'file://' + process.cwd() + '/../app/assets/brand/launcher/app_icon.png';
const zone = 'Africa/Johannesburg';
const pages = {
  document: {kind: 'document', householdName: 'The Parkers', documentName: 'Emma medical aid card', isImage: true,
    endsLabel: endsLabel({expiresAt: new Date('2026-09-29T16:00:00Z'), untilShiftEnds: true, timeZone: zone}), fileQuery: picture},
  pdf: {kind: 'document', householdName: 'The Parkers', documentName: 'Car insurance policy', isImage: false,
    endsLabel: endsLabel({expiresAt: new Date('2026-09-30T16:00:00Z'), untilShiftEnds: false, timeZone: zone}), fileQuery: '#'},
  pin: {kind: 'pin', formQuery: '#', attemptsLeft: 3},
  expired: {kind: 'expired'},
};
for (const [name, page] of Object.entries(pages)) {
  fs.writeFileSync(process.env.WORK + '/' + name + '.html', renderSharePage(page).replace('?asset=mark', mark));
}
")

for name in document pdf pin expired; do
  for scheme in light dark; do
    printf '<!doctype html><body style="margin:0;background:#888;width:600px"><iframe src="%s.html" style="width:390px;height:844px;border:0;display:block;margin:0 auto"></iframe></body>' \
      "$name" > "$work/frame-$name.html"
    flag=""
    if [ "$scheme" = dark ]; then flag="--blink-settings=preferredColorScheme=0"; fi
    "$chrome" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
      --window-size=600,844 --force-device-scale-factor=2 $flag \
      --screenshot="$out/share-page-$name-$scheme.png" "file://$work/frame-$name.html" >/dev/null 2>&1 || true
    # Chrome's exit code says nothing reliable in headless mode; the file does.
    if [ ! -s "$out/share-page-$name-$scheme.png" ]; then
      echo "no picture of $name ($scheme)" >&2
      exit 1
    fi
    sips --cropToHeightWidth 1688 780 "$out/share-page-$name-$scheme.png" >/dev/null
  done
done
echo "wrote app/design-review/share-page-*.png"
