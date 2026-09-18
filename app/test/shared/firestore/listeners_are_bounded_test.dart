import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `BE-08`: every listener is bounded to the active household and, where dates
/// apply, to a window.
///
/// An unbounded collection listener is the cheapest mistake in Firestore to
/// make and the most expensive to find. It works, it is fast, and it stays both
/// of those things until one household has more rows than anybody imagined —
/// at which point it is a bill and a slow screen at the same time, for the
/// household least able to afford either.
///
/// A document listener is bounded by being one document. A collection listener
/// needs a `limit`, or a date range that is its own bound.
void main() {
  final repositories = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.contains('/data/firestore_'))
      .toList();

  test('it can see the repositories', () {
    expect(repositories, isNotEmpty);
    expect(repositories.length, greaterThanOrEqualTo(5));
  });

  test('every collection listener has a bound', () {
    final unbounded = <String>[];

    for (final file in repositories) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'\.snapshots\(\)').allMatches(source)) {
        // The chain starts at the blank line before it: one method body.
        final start = source.lastIndexOf('\n\n', match.start);
        final chain = source.substring(start < 0 ? 0 : start, match.start);
        final line = '\n'.allMatches(source.substring(0, match.start)).length;

        // `.doc(…)` is one document, which is its own bound.
        final isOneDocument =
            RegExp(r'\.doc\(').hasMatch(chain) ||
            RegExp(r'_household\(householdId\)\s*\.snapshots').hasMatch(chain);
        final hasLimit = chain.contains('.limit(');
        final hasWindow = chain.contains('isGreaterThanOrEqualTo');

        if (!isOneDocument && !hasLimit && !hasWindow) {
          unbounded.add('${file.path.split('/').last}:${line + 1}');
        }
      }
    }

    expect(
      unbounded,
      isEmpty,
      reason:
          'a collection listener with no limit and no window reads a whole '
          'collection for ever — give it a limit on the repository interface, '
          'beside the others (`BE-08`)',
    );
  });

  test('and the limits are declared where the interface can be read', () {
    // The number belongs next to the method it bounds, not buried in the
    // Firestore implementation where nobody comparing features would see it.
    final interfaces = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('_repository.dart') &&
              !file.path.contains('/firestore_'),
        )
        .toList();

    final declared = [
      for (final file in interfaces)
        ...RegExp(r'static const (\w*[Ll]imit) =')
            .allMatches(file.readAsStringSync())
            .map((match) => match.group(1)!),
    ];

    expect(
      declared,
      containsAll(['eventLimit', 'itemLimit', 'taskLimit', 'mealLimit']),
      reason: 'the established pattern',
    );
    expect(
      declared,
      contains('memberLimit'),
      reason: 'the members listener was the one that had none',
    );
  });
}
