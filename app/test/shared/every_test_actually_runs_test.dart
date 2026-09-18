import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A test that never runs is worse than no test, because it is counted.
///
/// `flutter test` runs `test/**/*_test.dart`. A file full of perfectly good
/// assertions named anything else is silently skipped, the suite stays green,
/// and the count goes up by nothing — which is exactly how a check written
/// this session sat there doing nothing until the total gave it away.
///
/// So: a file that contains tests must be named so the runner finds it, and a
/// file that is not a test must not pretend to be one.
void main() {
  final dartFiles = Directory('test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  /// Anything that declares a case the runner would execute.
  final declaresTests = RegExp(
    r'^\s*(testWidgets|test|group)\(',
    multiLine: true,
  );

  test('there are test files to check', () {
    expect(dartFiles.length, greaterThan(40));
  });

  test('every file with tests in it is named so the runner picks it up', () {
    final skipped = [
      for (final file in dartFiles)
        if (!file.path.endsWith('_test.dart') &&
            declaresTests.hasMatch(file.readAsStringSync()))
          file.path,
    ];

    expect(
      skipped,
      isEmpty,
      reason:
          'these declare tests and `flutter test` will not run them — '
          'rename to _test.dart',
    );
  });

  test('and every file named as a test has some', () {
    final empty = [
      for (final file in dartFiles)
        if (file.path.endsWith('_test.dart') &&
            !declaresTests.hasMatch(file.readAsStringSync()))
          file.path,
    ];

    expect(
      empty,
      isEmpty,
      reason: 'a _test.dart with no cases passes for ever and proves nothing',
    );
  });

  test('helpers live where helpers live', () {
    // Not a style rule: a fake in the same folder as the tests is a fake that
    // will be named `..._test.dart` by somebody one day, and then run.
    final strays = [
      for (final file in dartFiles)
        if (!file.path.endsWith('_test.dart') &&
            !file.path.startsWith('test/support/'))
          file.path,
    ];

    expect(strays, isEmpty, reason: 'move it to test/support/');
  });
}
