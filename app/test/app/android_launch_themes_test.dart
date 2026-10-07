import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Android window theme stays on AppCompat (design-system ADR-0003).
///
/// `MainActivity` is a `FlutterFragmentActivity` because the vault's device
/// lock needs one (documents ADR-0003), and that activity refuses to start on
/// a non-AppCompat theme. `flutter_native_splash` writes its Android 12 styles
/// (`values-v31`, `values-night-v31`) on the platform's own
/// `Theme.Light.NoTitleBar` — so a plain regeneration of the splash would
/// crash the app at launch on every phone from Android 12 up, and nothing but
/// a device would say so. This reads the files the build reads.
void main() {
  final res = Directory('android/app/src/main/res');
  final styles = res
      .listSync()
      .whereType<Directory>()
      .where((dir) => dir.path.split('/').last.startsWith('values'))
      .map((dir) => File('${dir.path}/styles.xml'))
      .where((file) => file.existsSync())
      .toList();

  test('the launch and normal themes exist for every splash variant', () {
    final folders = styles.map((file) => file.parent.path.split('/').last);
    expect(
      folders,
      containsAll(['values', 'values-night', 'values-v31', 'values-night-v31']),
    );
  });

  for (final file in styles) {
    final folder = file.parent.path.split('/').last;
    test('$folder keeps every window theme on AppCompat', () {
      final parents = RegExp(
        r'<style name="(\w+)" parent="([^"]+)"',
      ).allMatches(file.readAsStringSync()).toList();
      expect(parents, isNotEmpty);
      for (final match in parents) {
        expect(
          match.group(2),
          startsWith('Theme.AppCompat'),
          reason: '${match.group(1)} in $folder',
        );
      }
    });
  }
}
