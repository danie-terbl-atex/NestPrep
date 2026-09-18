import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every query the app runs, checked against the indexes the project declares.
///
/// This is the gap the emulator cannot show you. The Firestore emulator serves
/// **any** query, inventing whatever index it needs; the real Firestore refuses
/// one it has no index for, with `FAILED_PRECONDITION: The query requires an
/// index`. So a query that needs a composite index passes every test, passes
/// the hand-driven run against the suite, and fails the first time a real
/// household opens that screen.
///
/// A single field — one `where` on it, or one `orderBy`, or a range with both
/// bounds on it — is indexed automatically and needs nothing declared. Two or
/// more distinct fields in one query is a composite index, and composite
/// indexes are only ever created by somebody writing them down.
void main() {
  final repositories = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.contains('/data/firestore_'))
      .toList();

  final indexesFile = File('../firestore.indexes.json');

  /// The fields each query touches, per repository method.
  ///
  /// A query is one chain ending at `.snapshots()` or `.get()`, so the source
  /// is split there and the `where`/`orderBy` fields since the previous chain
  /// belong to this one.
  List<({String where, Set<String> fields})> queriesIn(File file) {
    final source = file.readAsStringSync();
    final field = RegExp(r"\.(?:where|orderBy)\(\s*'([A-Za-z0-9_.]+)'");
    final endOfChain = RegExp(r'\.(?:snapshots|get)\(\)');

    final found = <({String where, Set<String> fields})>[];
    var cursor = 0;
    for (final chainEnd in endOfChain.allMatches(source)) {
      final chain = source.substring(cursor, chainEnd.start);
      cursor = chainEnd.end;
      final fields = field
          .allMatches(chain)
          .map((match) => match.group(1)!)
          .toSet();
      if (fields.isEmpty) continue;
      final line = '\n'.allMatches(source.substring(0, chainEnd.start)).length;
      found.add((
        where: '${file.path.split('/').last}:${line + 1}',
        fields: fields,
      ));
    }
    return found;
  }

  /// The composite indexes `firestore.indexes.json` declares, as field sets.
  List<Set<String>> declaredComposites() {
    final json =
        jsonDecode(indexesFile.readAsStringSync()) as Map<String, Object?>;
    final indexes = (json['indexes'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    return [
      for (final index in indexes)
        {
          for (final entry
              in (index['fields'] as List<Object?>? ?? const [])
                  .cast<Map<String, Object?>>())
            entry['fieldPath']! as String,
        },
    ];
  }

  test('the repositories and the indexes file are where this expects', () {
    expect(repositories, isNotEmpty, reason: 'no repositories found to check');
    expect(indexesFile.existsSync(), isTrue);
  });

  test('every query is one Firestore will serve without being told', () {
    final composites = declaredComposites();
    final undeclared = <String>[];

    for (final file in repositories) {
      for (final query in queriesIn(file)) {
        if (query.fields.length < 2) continue;
        final isDeclared = composites.any(
          (declared) => declared.containsAll(query.fields),
        );
        if (!isDeclared) {
          undeclared.add('${query.where} needs an index on ${query.fields}');
        }
      }
    }

    expect(
      undeclared,
      isEmpty,
      reason:
          'these pass against the emulator, which invents an index for any '
          'query, and fail against the real Firestore with FAILED_PRECONDITION '
          'the first time a household opens the screen. Declare them in '
          'firestore.indexes.json and deploy it.',
    );
  });

  test('and no index is declared that nothing asks for', () {
    final asked = [
      for (final file in repositories)
        for (final query in queriesIn(file))
          if (query.fields.length >= 2) query.fields,
    ];

    for (final declared in declaredComposites()) {
      expect(
        asked.any((fields) => declared.containsAll(fields)),
        isTrue,
        reason:
            'an index nothing queries still costs a write on every document '
            'it covers — delete it, or write the query it was for',
      );
    }
  });

  test('the parser can actually see the queries it is checking', () {
    // If a refactor changes how a chain is written, this test would silently
    // check nothing at all. Prove it still finds the queries we know exist.
    final everyField = {
      for (final file in repositories)
        for (final query in queriesIn(file)) ...query.fields,
    };

    expect(
      everyField,
      containsAll(['occurrenceDate', 'addedAt', 'displayName', 'name']),
      reason:
          'the parser stopped recognising query chains, so it is no '
          'longer checking anything',
    );
  });
}
