#!/bin/sh
# Every raster of the arch mark, rendered from app/assets/brand/nest_mark.svg
# (design-system ADR-0008): the site's and the shared-link page's marks, the
# app icon, the Android adaptive foreground and the launch-screen marks.
# Then, from app/: `dart run flutter_launcher_icons` and
# `dart run flutter_native_splash:create` (read the warning in
# flutter_native_splash.yaml before you do). Uses macOS `sips`.
set -eu
here=$(cd "$(dirname "$0")/../.." && pwd)
brand="$here/app/assets/brand"
launcher="$brand/launcher"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

strokes='<path d="M25 54V44c0-13 9-22 23-22s23 9 23 22v10" fill="none" stroke="#35252E" stroke-width="8" stroke-linecap="round"/><path d="M23 63c6 9 14 13 25 13s19-4 25-13M34 55c4 5 8 7 14 7s10-2 14-7" fill="none" stroke="#35252E" stroke-width="7" stroke-linecap="round"/>'

tile='<rect width="96" height="96" rx="28" fill="#F57B91"/>'

# sips draws an SVG at its own width before resampling, so each is written
# at the size it is wanted.
render() {
  printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s">%s</svg>' \
    "$3" "$3" "$1" "$2" > "$work/mark.svg"
  sips -s format png "$work/mark.svg" --out "$4" >/dev/null
}

# The site and the shared-link page use the tile as drawn.
render "0 0 96 96" "$tile$strokes" 720 "$brand/nest_mark.png"
render "0 0 96 96" "$tile$strokes" 192 "$here/functions/assets/share/nest_mark.png"

# iOS masks its own corners: the tile is square and full-bleed.
render "0 0 96 96" "<rect width=\"96\" height=\"96\" fill=\"#F57B91\"/>$strokes" 1024 "$launcher/app_icon.png"

# Android's adaptive icon: the strokes alone inside the 66/108 safe zone,
# over a Guava background set in flutter_launcher_icons.yaml.
render "-30 -30 156 156" "$strokes" 1024 "$launcher/app_icon_foreground.png"

# Launch screens: the tile, and for Android 12 the tile inside its icon
# circle (two thirds of the 1152 image).
render "0 0 96 96" "$tile$strokes" 432 "$launcher/splash_mark.png"
render "-60 -60 216 216" "$tile$strokes" 1152 "$launcher/splash_android12.png"

echo "rendered the mark into app/assets/brand, its launcher folder and functions/assets/share"
