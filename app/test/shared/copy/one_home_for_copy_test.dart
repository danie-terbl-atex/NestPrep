import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

/// `FE-19`: every user-facing string lives in one file.
///
/// The cost of breaking it is not obvious until somebody changes a word. This
/// was already broken once, in the quietest possible place: `NestSkeleton`
/// announced `'Loading'` to a screen reader as a literal while
/// `AppCopy.loading` sat in the copy file holding the same word and used by
/// nothing. Change one and the other keeps saying the old thing, and the only
/// person who notices is the one who cannot see the screen.
void main() {
  /// Named arguments that reach a person — on screen or through a screen
  /// reader.
  const copyArguments = [
    'label',
    'title',
    'subtitle',
    'message',
    'hint',
    'actionLabel',
    'confirmLabel',
    'cancelLabel',
    'retryLabel',
    'anyoneLabel',
    'semanticsLabel',
    'tooltip',
  ];

  /// Where copy is allowed to be a literal, and why.
  const allowed = {
    // Emulator-only scaffolding that must match functions/tools/seed-emulator.mjs
    // exactly. These are fixture identifiers, not product copy, and they exist
    // in no build a household will ever run.
    'lib/app/emulator_accounts.dart',
    // The gallery is a debug route naming the primitives it is showing; its
    // labels are the widget names, not words anybody is meant to read.
  };

  bool isAllowed(String path) =>
      allowed.contains(path) || path.contains('/design/gallery/');

  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .toList();

  test('there are files to check, and the copy file has copy in it', () {
    expect(dartFiles.length, greaterThan(40));
    expect(AppCopy.loading, isNotEmpty);
  });

  test('no widget is handed copy as a literal', () {
    // `'$x $y'` assembles words that live elsewhere; only a bare literal is
    // copy with no home.
    final pattern = RegExp(
      '(${copyArguments.join('|')}):\\s*\'([^\'\$]{2,})\'',
    );
    final offences = <String>[];

    for (final file in dartFiles) {
      if (isAllowed(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = pattern.firstMatch(lines[i]);
        if (match == null) continue;
        offences.add(
          '${file.path}:${i + 1}  ${match.group(1)}: "${match.group(2)}"',
        );
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'these reach a person but do not live in AppCopy, so changing the '
          'word in one place leaves the other saying the old one (`FE-19`)',
    );
  });

  test('and Text() is never handed one either', () {
    final offences = <String>[];
    for (final file in dartFiles) {
      if (isAllowed(file.path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r"\bText\(\s*'[^'$]{2,}").hasMatch(lines[i])) {
          offences.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(offences, isEmpty, reason: 'a sentence on a screen (`FE-19`)');
  });

  test('the copy file is not carrying words nothing says', () {
    // `AppCopy.loading` existed for a while used by nothing, while a widget
    // said the same word as a literal. An unused constant is the first half of
    // that mistake, so it is worth knowing about.
    // Every file in the copy folder, each read under the class its name
    // spells — `kid_copy.dart` is `KidCopy`, `access_copy.dart` is
    // `AccessCopy` — so a feature that adds its own copy file beside
    // `AppCopy` (accounts ADR-0003, household ADR-0003) is held to this rule
    // without editing this test.
    final copyFiles = {
      for (final file in Directory('lib/shared/copy').listSync())
        if (file is File && file.path.endsWith('_copy.dart'))
          file.path: _classNameOf(file.path),
    };
    final names = <String>{};
    final owner = <String, String>{};
    for (final MapEntry(key: path, value: className) in copyFiles.entries) {
      final copySource = File(path).readAsStringSync();
      for (final match in RegExp(
        r'static const (\w+) =',
      ).allMatches(copySource)) {
        final name = '$className.${match.group(1)!}';
        names.add(name);
        owner[name] = path;
      }
    }

    final usedAnywhere = <String>{};
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final name in names) {
        final bare = name.split('.').last;
        // Inside its own copy file a constant is referenced by its bare name:
        // `weekdayName()` indexes `weekdayNames`, `mealSlotName()` returns
        // `mealsBreakfast`. More than the declaration itself is a use.
        final used = file.path == owner[name]
            ? RegExp('\\b$bare\\b').allMatches(source).length > 1
            : source.contains(name);
        if (used) usedAnywhere.add(name);
      }
    }

    // This list is empty, and that is the interesting part.
    //
    // It began at ten names. Every one turned out to be a capability finished
    // in the model, the repository, the controller and the rules, with the
    // words already written, and no control anywhere that opened it: the
    // recurrence end date, completing a task for somebody else, switching
    // households, renaming a household or its zone, renaming a meal, the
    // calendar's member filter, and its way back to this week. Two more were
    // copy superseded by a better decision and were deleted. One was a screen
    // that said nothing while it worked.
    //
    // A name appearing here again is a capability somebody stopped one layer
    // short of. Either wire it up, or do not write the words yet.
    const noScreenYet = <String>{};

    expect(
      names.difference(usedAnywhere),
      equals(noScreenYet),
      reason:
          'copy nothing uses is copy nobody maintains, and the next widget '
          'that needs those words will write them out by hand instead. If a '
          'name has gone, delete it from noScreenYet; if one has appeared, '
          'either wire it up or do not add the words yet',
    );
  });
}

/// `lib/shared/copy/product_analytics_copy.dart` → `ProductAnalyticsCopy`.
String _classNameOf(String path) => path
    .split('/')
    .last
    .replaceAll('.dart', '')
    .split('_')
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join();
