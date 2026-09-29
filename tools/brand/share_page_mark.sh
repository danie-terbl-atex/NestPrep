#!/bin/sh
# The nest mark the shared-link page shows (documents ADR-0006), cut from the
# app's own copy so the two cannot drift in anything but size. The page is read
# on a phone over a mobile connection, and the app's 720 px mark is 570 KB; this
# one is 192 px wide. Rerun after `extract_brand_assets.py` changes the mark.
#
# Uses macOS `sips`; on another system any resize to 192 px wide that keeps the
# alpha channel is the same thing. `share_page_assets.test.ts` checks the size
# and that the source still exists.
set -eu
here=$(cd "$(dirname "$0")/../.." && pwd)
sips --resampleWidth 192 "$here/app/assets/brand/nest_mark.png" \
  --out "$here/functions/assets/share/nest_mark.png" >/dev/null
echo "wrote functions/assets/share/nest_mark.png"
