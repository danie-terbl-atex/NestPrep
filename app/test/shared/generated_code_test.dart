import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ENG-24`: generated files are committed and never hand-edited.
///
/// The check that really settles it is to run the generator and see whether
/// anything moves:
///
///     dart run build_runner build --delete-conflicting-outputs
///     git status --porcelain      # must be empty
///
/// That needs a build and does not belong in a unit test. What belongs here is
/// the cheap half — that every `part` directive has its file, and every
/// generated file still says it is one. A `part` with no file is a build that
/// works on the machine that last ran the generator and nowhere else.
void main() {
  final lib = Directory('lib');

  final sources = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  final generated = sources
      .where(
        (file) =>
            file.path.endsWith('.g.dart') ||
            file.path.endsWith('.freezed.dart'),
      )
      .toList();

  test('there is generated code to check', () {
    expect(generated.length, greaterThanOrEqualTo(20));
  });

  test('every part directive has the file it names', () {
    final missing = <String>[];

    for (final file in sources) {
      if (generated.contains(file)) continue;
      final directory = file.parent.path;
      for (final match in RegExp(
        r"^part '([^']+)';",
        multiLine: true,
      ).allMatches(file.readAsStringSync())) {
        final part = File('$directory/${match.group(1)}');
        if (!part.existsSync()) {
          missing.add('${file.path} names ${match.group(1)}');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'a part with no file builds only on the machine that last ran '
          'build_runner (`ENG-24`)',
    );
  });

  test('and every generated file still says it is generated', () {
    final unmarked = [
      for (final file in generated)
        if (!file.readAsStringSync().contains('GENERATED CODE - DO NOT MODIFY'))
          file.path,
    ];

    expect(
      unmarked,
      isEmpty,
      reason:
          'the header is what tells the next person not to edit it by '
          'hand, and its absence is the first sign somebody did',
    );
  });

  test('none of it is checked in empty', () {
    final empty = [
      for (final file in generated)
        if (file.readAsStringSync().trim().length < 80) file.path,
    ];

    expect(empty, isEmpty, reason: 'a truncated generated file');
  });
}
