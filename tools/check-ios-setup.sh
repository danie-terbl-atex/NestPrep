#!/usr/bin/env bash
# What an iOS build still needs on this Mac, and what it already has.
#
# ADR-0001 commits NestPrep to both platforms. The code side is ready — the
# bundle id is registered and `GoogleService-Info.plist` is committed — and iOS
# has still never built here, because of three separate things on the machine
# rather than anything in the repo. This says which of them are done.
#
# All three need an Apple ID, the App Store, or admin. None of them is something
# a script can do, so this one only ever reports.
#
#   tools/check-ios-setup.sh
#
# Its companion is tools/check-cloud-setup.sh, which does the same for the
# Firebase project and can act on what has become possible.

set -uo pipefail

MIN_XCODE_MAJOR=16
FLUTTER="${FLUTTER:-$HOME/development/flutter/bin/flutter}"

blocked=0
ok()      { printf '  \033[32mok\033[0m       %s\n' "$1"; }
human()   { printf '  \033[33mYOU\033[0m      %s\n' "$1"; blocked=1; }
note()    { printf '           %s\n' "$1"; }

echo
echo "NestPrep iOS — this Mac"
echo

# ------------------------------------------------------------------- Xcode
if ! command -v xcodebuild >/dev/null; then
  human "Xcode is not installed"
  note "Install it from the Mac App Store, then: sudo xcodebuild -runFirstLaunch"
else
  version="$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')"
  major="${version%%.*}"
  if [ -n "$major" ] && [ "$major" -ge "$MIN_XCODE_MAJOR" ] 2>/dev/null; then
    ok "Xcode $version (Flutter wants $MIN_XCODE_MAJOR or newer)"
  else
    human "Xcode is $version — Flutter's minimum is $MIN_XCODE_MAJOR"
    note "Update it in the Mac App Store. This is a multi-gigabyte download and"
    note "needs an Apple ID, which is why nothing here can do it."
  fi
fi

# -------------------------------------------------------- simulator runtime
# A runtime is a separate download from Xcode itself, and without one there is
# no device to run on even when everything else is right.
if ! command -v xcrun >/dev/null; then
  note "no xcrun, so runtimes cannot be listed — fix Xcode first"
else
  runtimes="$(xcrun simctl list runtimes 2>/dev/null | grep -ci 'iOS' || true)"
  if [ "${runtimes:-0}" -gt 0 ]; then
    ok "$runtimes iOS simulator runtime(s) installed"
  else
    human "no iOS simulator runtime is installed, so there is nothing to run on"
    note "Xcode → Settings → Components, or: xcodebuild -downloadPlatform iOS"
  fi
fi

# --------------------------------------------------------------- CocoaPods
# Flutter plugins need Pods on iOS. The blocker here is Ruby, not CocoaPods:
# the system Ruby cannot build native extensions, which is also why
# `flutterfire configure` cannot edit the Xcode project.
if command -v pod >/dev/null; then
  ok "CocoaPods $(pod --version 2>/dev/null)"
else
  human "CocoaPods is not installed, so no Flutter plugin will build for iOS"
  ruby_version="$(ruby -e 'print RUBY_VERSION' 2>/dev/null || echo unknown)"
  note "The system Ruby is $ruby_version and cannot build native extensions:"
  note '  gem install --user-install cocoapods'
  note "fails compiling nkf: the MacOSX SDK in Xcode ${version:-15.4} carries no"
  note "Ruby headers for it, so make cannot find ruby/config.h. Install a current"
  note "Ruby (rbenv, asdf or Homebrew) and put CocoaPods in that instead."
  note "The same Ruby is why flutterfire cannot add GoogleService-Info.plist"
  note "to the Xcode target."
fi

# ------------------------------------------------------- what the repo has
echo
if [ -f app/ios/Runner/GoogleService-Info.plist ]; then
  ok "GoogleService-Info.plist is committed (client identifiers, not secrets)"
  note "It is still not added to the Xcode target — do that when iOS first"
  note "builds, either in Xcode or by re-running flutterfire configure."
else
  human "app/ios/Runner/GoogleService-Info.plist is missing"
  note "Regenerate with the flutterfire command in app/CLAUDE.md"
fi

# ------------------------------------------------------ the verification
echo
if [ "$blocked" = 0 ]; then
  echo "Nothing is blocking an iOS build. Verify it for the first time with:"
  note "cd app && flutter build ios --simulator --no-codesign"
  note "then: flutter run -d <simulator>  (NESTPREP_BACKEND defaults to emulator)"
  note "A device build or TestFlight additionally needs the paid Apple Developer"
  note "Program, which the verdict puts outside v1."
else
  echo "Lines marked YOU are the ones nothing here can do."
  note "Afterwards, confirm with: $FLUTTER doctor"
  note "then re-run this script, then build for the simulator."
fi
exit 0
