import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/font_licences.dart';

/// The bundled fonts' OFL travels with them into the Licences screen.
void main() {
  tearDown(LicenseRegistry.reset);

  test('each bundled family is listed with its licence text', () async {
    LicenseRegistry.reset();
    registerFontLicences(bundle: _DiskBundle());
    final entries = await LicenseRegistry.licenses.toList();
    final families = entries.expand((entry) => entry.packages).toSet();
    expect(families, containsAll(['Nunito', 'Plus Jakarta Sans']));
    final text = entries
        .expand((entry) => entry.paragraphs)
        .map((paragraph) => paragraph.text)
        .join(' ');
    expect(text, contains('SIL OPEN FONT LICENSE'));
  });

  test('the licence files exist and are bundled with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final (_, path) in fontLicenceFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(
        pubspec,
        contains('- $path'),
        reason: 'declare $path under `assets:` or the Licences screen fails',
      );
    }
  });
}

final class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(utf8.encode(File(key).readAsStringSync())),
  );
}
