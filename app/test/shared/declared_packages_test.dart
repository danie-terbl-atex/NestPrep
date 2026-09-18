import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ENG-17`: a package not in the vault's stack note is not in the app.
///
/// The note says so itself — "A package not in this note is not in the app;
/// adding one is a new ADR, and this note gains its row in the same change."
/// Nothing checked it, and four packages had arrived without one:
/// `freezed_annotation`, `json_annotation`, `@types/node` and `prettier`.
///
/// None of those is a bad dependency. That is the point. A dependency arrives
/// because it was needed for five minutes, and the note is where somebody a
/// year later finds out whether anybody weighed it. This reads the note and
/// both manifests, so the answer cannot drift.
void main() {
  final repoRoot = Directory.current.parent;
  final note = File(
    '${repoRoot.parent.path}/nullstate-vault/nestprep-project/'
    'nestprep-technology-stack.md',
  );

  /// Keys in `pubspec.yaml` that are not packages.
  const notPackages = {
    'sdk',
    'flutter',
    'uses',
    'fonts',
    'assets',
    'flutter_test',
    'flutter_lints',
  };

  List<String> pubspecPackages() {
    final source = File('pubspec.yaml').readAsStringSync();
    final dependencies = source.substring(source.indexOf('dependencies:'));
    return [
      for (final match in RegExp(
        r'^  ([a-z_][a-z0-9_]*):',
        multiLine: true,
      ).allMatches(dependencies))
        if (!notPackages.contains(match.group(1))) match.group(1)!,
    ];
  }

  List<String> functionsPackages() {
    final manifest = jsonDecode(
      File('${repoRoot.path}/functions/package.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return [
      for (final section in ['dependencies', 'devDependencies'])
        ...(manifest[section] as Map<String, Object?>? ?? const {}).keys,
    ];
  }

  test('the note is where this expects it', () {
    expect(
      note.existsSync(),
      isTrue,
      reason:
          'if the stack note moved, point this at it rather than deleting '
          'it — the question it answers does not go away',
    );
  });

  test('every package the app depends on is named in the note', () {
    final text = note.readAsStringSync();
    final packages = pubspecPackages();
    expect(packages, isNotEmpty);

    final undeclared = [
      for (final package in packages)
        if (!text.contains('`$package`')) package,
    ];

    expect(
      undeclared,
      isEmpty,
      reason:
          'adding a package is an ADR and a row in the note, in the same '
          'change as the dependency (`ENG-17`)',
    );
  });

  test('and every package the Functions depend on', () {
    final text = note.readAsStringSync();
    final packages = functionsPackages();
    expect(packages, isNotEmpty);

    final undeclared = [
      for (final package in packages)
        if (!text.contains('`$package`')) package,
    ];

    expect(undeclared, isEmpty, reason: 'same rule, other half of the repo');
  });

  test('and the note has not kept a row for something that has gone', () {
    // The note also lists what was deliberately *not* used, which is half its
    // value — so this only checks the packages it claims are in use, by
    // looking for them in the two manifests.
    final text = note.readAsStringSync();
    final inUse = {...pubspecPackages(), ...functionsPackages()};
    // That section, and only that section — the Functions toolchain follows
    // it, and its packages are very much in use.
    final start = text.indexOf('Deliberately not used');
    final nextHeading = text.indexOf('\n## ', start);
    final rejected = text.substring(
      start,
      nextHeading == -1 ? text.length : nextHeading,
    );

    final ghosts = [
      for (final match in RegExp(
        r'^\| `([a-z@][a-z0-9_@/-]+)` \|',
        multiLine: true,
      ).allMatches(rejected))
        if (inUse.contains(match.group(1))) match.group(1)!,
    ];

    expect(
      ghosts,
      isEmpty,
      reason: 'a package listed as deliberately not used, that is used',
    );
  });
}
