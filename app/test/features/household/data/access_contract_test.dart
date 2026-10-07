import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/member_role.dart';

/// The area keys, the levels and the role defaults are written twice: in
/// `functions/src/household/access.ts`, which the Functions write grants from,
/// and here, which the app hides things by (household ADR-0003). Other features
/// gate on the keys. A key spelled one way here and another there is not an
/// error anywhere — a helper just silently loses an area, or keeps one — so
/// this reads the TypeScript itself, like the refusal contract does.
///
/// The functions side holds `firestore.rules` and `storage.rules` to the same
/// file (`functions/test/unit/access_contract.test.ts`), so the three agree
/// through it.
void main() {
  final accessFile = File('../functions/src/household/access.ts');

  String source() => accessFile.readAsStringSync();

  /// The quoted words inside the first `[...]` after [marker].
  List<String> listAfter(String marker) {
    final text = source();
    final start = text.indexOf('[', text.indexOf(marker));
    final end = text.indexOf(']', start);
    return RegExp(
      r"'(\w+)'",
    ).allMatches(text.substring(start, end)).map((m) => m.group(1)!).toList();
  }

  /// `area: 'level'` pairs inside the `{...}` after [marker].
  Map<String, String> pairsAfter(String text, String marker) {
    final start = text.indexOf('{', text.indexOf(marker));
    final end = text.indexOf('}', start);
    return {
      for (final match in RegExp(
        r"(\w+):\s*'(\w+)'",
      ).allMatches(text.substring(start, end)))
        match.group(1)!: match.group(2)!,
    };
  }

  test('the server source is where this test thinks it is', () {
    expect(accessFile.existsSync(), isTrue, reason: 'point it at the new home');
    expect(listAfter('export const AREAS'), isNotEmpty);
  });

  test('the areas are the same, in the same order', () {
    expect(listAfter('export const AREAS'), [
      for (final area in HouseholdArea.values) area.key,
    ]);
  });

  test('the levels are the same, in the same order', () {
    expect(listAfter('export const LEVELS'), [
      for (final level in AccessLevel.values) level.name,
    ]);
  });

  test('each area accepts the same levels on both sides', () {
    final text = source();
    final block = text.substring(
      text.indexOf('AREA_LEVELS'),
      text.indexOf('};', text.indexOf('AREA_LEVELS')),
    );
    for (final area in HouseholdArea.values) {
      final line = RegExp(
        '${area.key}: \\[([^\\]]*)\\]',
      ).firstMatch(block)?.group(1);
      expect(line, isNotNull, reason: '${area.key} is missing on the server');
      final levels = RegExp(
        r"'(\w+)'",
      ).allMatches(line!).map((m) => m.group(1)).toList();
      expect(levels, [
        for (final level in area.levels) level.name,
      ], reason: area.key);
    }
  });

  test('family is the same roles on both sides', () {
    final server = listAfter('export const FAMILY_ROLES');
    // `member` is stored, never assignable; both read it as a parent.
    expect(server, ['admin', 'parent', 'member']);
    for (final name in server) {
      expect(MemberRole.fromName(name).isFamily, isTrue, reason: name);
    }
  });

  group('the role defaults match, area by area', () {
    final text = source();
    final block = text.substring(text.indexOf('ROLE_DEFAULTS'));
    for (final role in [MemberRole.kid, MemberRole.helper, MemberRole.carer]) {
      test(role.name, () {
        final server = pairsAfter(block, '${role.name}: {');
        final client = AccessDefaults.forRole(role)!.toJson();
        expect(server, client);
      });
    }
  });
}
