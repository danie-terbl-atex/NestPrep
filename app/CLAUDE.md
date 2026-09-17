# app — NullState app `nestprep` (Flutter client)

This is the Flutter client of the NullState app **nestprep**. Its memory lives in the vault:

    ../../nullstate-vault/   (also $NULLSTATE_VAULT)

Before any task run the **nullstate-memory** skill; after any change update the vault in the same
change and run `python3 ../../nullstate-vault/tools/vault-lint.py`. The root `CLAUDE.md` one level
up has the full contract and the emulator command.

## Running this app

Flutter 3.47 / Dart 3.13 (the SDK at `~/development/flutter`, shared with Groomzy — do not upgrade
it as part of NestPrep work). Android and iOS; v1 is verified on Android.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed + json_serializable
flutter analyze --fatal-infos                               # zero diagnostics is the bar
dart format --set-exit-if-changed lib test
flutter test
flutter run                                                 # emulator backend by default
flutter build apk --debug
```

Defines (`--dart-define`), all optional:

| Name | Values | Default |
|---|---|---|
| `NESTPREP_BACKEND` | `emulator`, `cloud` | `emulator` |
| `NESTPREP_EMULATOR_HOST` | an IP the device can reach | `10.0.2.2` on the Android emulator, else `localhost` |

Both targets read `lib/app/firebase_options.dart` and `android/app/google-services.json`, generated
by `flutterfire configure` against project `nestprep-643b7`; they are client identifiers, not
secrets (foundation ADR-0008). Regenerate with:

```sh
flutterfire configure --project=nestprep-643b7 --platforms=android \
  --out=lib/app/firebase_options.dart
```

Emulator ports are fixed in the root `firebase.json` and mirrored in `lib/app/emulator_endpoint.dart`.

## Shape

- `lib/app/` — bootstrap: backend target, Firebase init, the Provider graph, the router.
- `lib/features/<feature>/{model,data,state,ui}/` — one folder per feature (`ENG-04`).
  `model/` is freezed types; `data/` a repository interface plus its Firestore implementation,
  the only place a raw map exists; `state/` a `ChangeNotifier` controller per screen holding an
  `AsyncState`; `ui/` screens that read the controller through `provider` and render all four
  async states.
- `lib/shared/` — `AppFailure`, `AsyncState`, `AppCopy` (every user-facing string), the typed
  Firestore collection helper and the server-timestamp converter.
- `lib/design/` — the design system. `tokens/` (colours, member palette, type, spacing, shadows,
  motion, `NestTheme`, `nestThemeData`), `primitives/` (the kit), `gallery/` (the debug `/design`
  route), and `nest_kit.dart`, the only import a screen uses. To retheme: colours in
  `tokens/nest_colors.dart`, the font in `tokens/nest_typography.dart`, how a button looks in
  `primitives/nest_button.dart`. Hex literals exist nowhere else. `test/design/tokens/nest_contrast_test.dart`
  fails the build if a pair drops below WCAG AA.
- State management is `provider` (foundation ADR-0006): repositories via `Provider` at the root,
  a `ChangeNotifierProvider` per route, `context.watch` in screens. No Riverpod, no get_it.
- Tests substitute a fake repository behind the controller; nothing pumps the Firestore SDK.

## Things that bite on this codebase

- Generated `*.g.dart` and `*.freezed.dart` are committed and never hand-edited; if the analyzer
  complains about a missing part, run `build_runner`.
- `build_runner` rewrites `analysis_options.yaml` to add `build/`, `android/` and `ios/` to the
  analyzer excludes the first time it runs; that edit is expected and harmless.
- **Debug builds need `src/debug/res/xml/network_security_config.xml`.** Android refuses cleartext
  HTTP, which the emulator's Auth and Functions speak; Firestore's gRPC does not care, so removing
  it breaks sign-in only, with an unmapped error. Release builds never merge it.
- **A Firebase failure on Android is only legible in `adb logcat`.** Neither the emulator UI nor
  `flutter run` shows the SDK's real message, and for Auth and Functions the request may never
  reach the emulator at all. See the vault lesson on what Auth and Functions need that Firestore
  does not.
- `app/firebase.json` is flutterfire's own record of what it generated — not the emulator config,
  which is the `firebase.json` at the repo root.
- iOS is registered in the Firebase project and `ios/Runner/GoogleService-Info.plist` is committed,
  but it is not yet added to the Xcode target: `flutterfire configure` cannot edit this Xcode
  project with the system Ruby's `xcodeproj`. Do that when iOS is first verified.
- Fonts are bundled under `assets/fonts/` (Plus Jakarta Sans, OFL). `flutter pub get` after
  changing the `fonts:` block or the family is silently absent.
