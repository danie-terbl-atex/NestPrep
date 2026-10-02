import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The three typefaces the app bundles are under the SIL Open Font Licence,
/// which asks that the licence travel with the fonts. Flutter lists the
/// licences of Dart packages by itself; fonts copied into `assets/` it cannot
/// know about, so they are added here and the Licences screen shows them with
/// the rest.
///
/// Lazy: the text is read only when something lists the licences.
void registerFontLicences({AssetBundle? bundle}) {
  final assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in fontLicenceFiles) {
      yield LicenseEntryWithLineBreaks([family], await assets.loadString(path));
    }
  });
}

/// Each bundled family and its licence text, as declared in `pubspec.yaml`.
const fontLicenceFiles = [
  ('Grand Hotel', 'assets/fonts/GrandHotel-OFL.txt'),
  ('Nunito', 'assets/fonts/Nunito-OFL.txt'),
  ('Plus Jakarta Sans', 'assets/fonts/PlusJakartaSans-OFL.txt'),
];
