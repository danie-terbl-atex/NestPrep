import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/app_version.dart';

/// The About screen's version is a constant, and the stores read
/// `pubspec.yaml` — so the two are checked against each other here, and a
/// release that raises one without the other fails the build.
void main() {
  test('the About screen says the version the stores see', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has a name+build version');
    expect(AppVersion.name, match!.group(1));
    expect(AppVersion.build, int.parse(match.group(2)!));
  });
}
