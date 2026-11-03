import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What a store build needs from the native projects, read from the files the
/// build reads (Stage C, the launch; foundation ADR-0016 for App Check).
///
/// None of these fail a debug build or a test run. Each fails at the worst
/// moment instead: a missing usage string crashes iOS the first time the
/// permission is asked for, a manifest that is not in the bundle is a rejected
/// upload, and a committed keystore is a leaked one (`ENG-18`).
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  /// The iOS usage strings each plugin needs before it may ask.
  const usageStringsByPlugin = {
    'image_picker': [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
    ],
    'cunning_document_scanner': ['NSCameraUsageDescription'],
    'mobile_scanner': ['NSCameraUsageDescription'],
    'geolocator': ['NSLocationWhenInUseUsageDescription'],
    'local_auth': ['NSFaceIDUsageDescription'],
  };

  for (final MapEntry(key: plugin, value: keys)
      in usageStringsByPlugin.entries) {
    test('$plugin has its iOS usage strings, and they say something', () {
      expect(pubspec, contains('  $plugin:'), reason: 'plugin moved or gone');
      for (final key in keys) {
        final match = RegExp('<key>$key</key>\\s*<string>([^<]*)</string>')
            .firstMatch(infoPlist);
        expect(match, isNotNull, reason: '$key is missing');
        expect(match!.group(1)!.trim().length, greaterThan(40), reason: key);
      }
    });
  }

  test(
    'background location is declared with the reasons the stores ask for',
    () {
      // Always-on sharing (live-location ADR-0003, ADR-0005): Play needs the
      // prominent-disclosure declaration before a release carries these.
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      for (final permission in [
        'ACCESS_BACKGROUND_LOCATION',
        'FOREGROUND_SERVICE_LOCATION',
        'ACTIVITY_RECOGNITION',
      ]) {
        expect(manifest, matches(RegExp('<uses-permission[^>]*$permission')));
      }
      expect(manifest, contains('android:foregroundServiceType="location"'));
      expect(
        infoPlist,
        contains('NSLocationAlwaysAndWhenInUseUsageDescription'),
      );
      expect(infoPlist, contains('NSMotionUsageDescription'));
      expect(infoPlist, matches(RegExp(r'<string>location</string>')));
    },
  );

  test('the privacy manifest exists, tracks nothing and ships in the app', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy')
        .readAsStringSync();
    expect(
      manifest,
      matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
    );
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    // A file in the folder but not in the Resources phase is not in the app.
    expect(project, contains('/* PrivacyInfo.xcprivacy in Resources */,'));
  });

  test('the release build is signed from key.properties, never the repo', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('signingConfigs.getByName("upload")'));
    final ignored = File('android/.gitignore').readAsStringSync();
    expect(ignored, contains('key.properties'));
    expect(ignored, contains('*.jks'));
    expect(ignored, contains('*.keystore'));
  });

  test('the version has a name and a build number the stores will take', () {
    final version = RegExp(
      r'^version: (\d+)\.(\d+)\.(\d+)\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(version, isNotNull);
    expect(int.parse(version!.group(4)!), greaterThan(1));
  });
}
