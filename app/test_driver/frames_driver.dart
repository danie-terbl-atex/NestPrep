import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Writes each frame summary an integration test reports to
/// `build/frames/<name>.json` and prints it, for
/// `flutter drive --profile --driver=test_driver/frames_driver.dart`.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final out = Directory('build/frames')..createSync(recursive: true);
    for (final MapEntry(:key, :value) in data.entries) {
      final text = const JsonEncoder.withIndent('  ').convert(value);
      File('${out.path}/$key.json').writeAsStringSync(text);
      stdout.writeln('$key: $text');
    }
  },
);
