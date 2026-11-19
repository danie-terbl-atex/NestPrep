#!/usr/bin/env bash
# Store releases and Dart patches for the NestPrep app, through Shorebird.
#
#   tools/shorebird.sh release android|ios
#   tools/shorebird.sh patch android|ios <release-version> [staging|stable]
#
# Shorebird refuses a patch whose defines differ from its release, so a release
# built without NESTPREP_MAPS could never get the map back by patch: both go
# through here. A patch goes to staging unless stable is named.

set -euo pipefail

FLUTTER_VERSION=3.47.6
DEFINES=(--dart-define=NESTPREP_MAPS=on)

usage() { sed -n 4,5p "$0" >&2; exit 64; }

command -v shorebird >/dev/null || {
  echo 'shorebird is not installed: curl -fsSL https://shorebird.dev/install.sh | bash' >&2
  exit 69
}
cd "$(dirname "$0")/../app"

action=${1:-}
platform=${2:-}
[[ $platform == android || $platform == ios ]] || usage

case $action in
  release)
    shorebird release "$platform" --flutter-version="$FLUTTER_VERSION" "${DEFINES[@]}"
    ;;
  patch)
    version=${3:-}
    track=${4:-staging}
    [[ -n $version && ($track == staging || $track == stable) ]] || usage
    shorebird patch "$platform" --release-version="$version" --track="$track" "${DEFINES[@]}"
    ;;
  *) usage ;;
esac
