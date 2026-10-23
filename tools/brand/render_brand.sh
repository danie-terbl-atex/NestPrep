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

# Android's adaptive icon: the strokes alone over a Guava background set in
# flutter_launcher_icons.yaml. A launcher shows the middle 72 of the 108 dp
# layer, so a 144-unit view frames the 96-unit tile in exactly that 72 dp and
# the mark fills the icon as it does on iOS (64% of its height). The furthest
# stroke is then 24.5 dp from the centre, inside the 33 dp safe zone. The
# yaml's adaptive_icon_foreground_inset is 0 because the padding is here
# (design-system ADR-0011).
render "-24 -24 144 144" "$strokes" 1024 "$launcher/app_icon_foreground.png"

# Launch screens: the tile, and for Android 12 the tile inside its icon
# circle (two thirds of the 1152 image).
render "0 0 96 96" "$tile$strokes" 432 "$launcher/splash_mark.png"
render "-60 -60 216 216" "$tile$strokes" 1152 "$launcher/splash_android12.png"

echo "rendered the mark into app/assets/brand, its launcher folder and functions/assets/share"

# The iOS app icon is its own SVG, not the tile above: pure black strokes on a
# full-bleed Guava square, one 1024 image per home-screen appearance. Shipping
# the dark appearance as the same picture stops iOS dimming it in Dark mode,
# which faded Ink-on-Guava into a soft blur (design-system ADR-0013). Xcode
# draws every smaller size from the 1024; flutter_launcher_icons no longer
# writes the iOS set (`ios: false`).
appicon="$here/app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
opaque() {
  sips -s format png "$1" --out "$work/raw.png" >/dev/null
  xcrun swift "$here/tools/brand/opaque_png.swift" "$work/raw.png" "$2"
}
rm -f "$appicon"/*.png
opaque "$brand/app_icon_ios.svg" "$appicon/AppIcon-1024.png"
cp "$appicon/AppIcon-1024.png" "$appicon/AppIcon-1024-dark.png"
opaque "$brand/app_icon_ios_tinted.svg" "$appicon/AppIcon-1024-tinted.png"
cat > "$appicon/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "filename" : "AppIcon-1024-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ],
      "filename" : "AppIcon-1024-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "rendered the iOS app icon set (light, dark, tinted)"
