import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ENG-03`/`ENG-08` and `FE-16`, the halves of them a machine can judge.
///
/// **What this checks.** No dumping-ground filenames, and no private widget
/// builder methods. Both are on the never-skipped list, and both are the shape
/// a second responsibility takes when it first arrives: a `utils.dart` nobody
/// owns, or a `Widget _buildHeader()` that should have been a kit widget.
///
/// **What it does not.** "Named after what it exports" is real and holds, and
/// it resisted being mechanised honestly. The convention here is a function,
/// not a class — `event_sheet.dart` exports `showEventSheet`,
/// `firebase_failure_mapper.dart` exports `failureFromFirebase`,
/// `typed_collection.dart` exports `typedCollection<T>`. A check expecting the
/// PascalCase of the filename flagged 28 files, every one of them correct. A
/// rule with more exceptions than content is a rule people learn to ignore, so
/// that half stays a human judgement and this says so rather than pretending.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .toList();

  test('it can see the codebase', () {
    expect(dartFiles.length, greaterThan(80));
  });

  test('nothing is called utils, helpers, manager or misc', () {
    // A file named after a category rather than a thing is a place for the
    // next unrelated function to go, and then the one after that.
    const dumpingGrounds = [
      'util',
      'utils',
      'helper',
      'helpers',
      'manager',
      'misc',
      'common',
      'shared_code',
      'constants',
      'extensions',
    ];

    final offences = [
      for (final file in dartFiles)
        if (dumpingGrounds.contains(
          file.uri.pathSegments.last.split('.').first,
        ))
          file.path,
    ];

    expect(
      offences,
      isEmpty,
      reason: 'name a file after the one thing it is for (`ENG-08`)',
    );
  });

  test('no screen builds a widget in a private method', () {
    // A new visual becomes a kit widget, never a private builder — otherwise
    // the second screen that wants it copies it instead (`FE-16`, `ENG-01`).
    final builder = RegExp(r'^\s+Widget\s+_\w+\(', multiLine: true);
    final offences = <String>[];

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final match in builder.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, match.start)).length;
        offences.add('${file.path}:${line + 1}  ${match.group(0)!.trim()}…)');
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'a private builder is a widget that has not been named yet, and '
          'the next screen that wants it will copy it (`FE-16`)',
    );
  });
}
