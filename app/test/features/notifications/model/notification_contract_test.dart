import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/data/notification_directory.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';

/// The words notifications spells on both sides of the wire (notifications
/// ADR-0001), read from the Functions' own file — a category, a section, a
/// target, a channel or a push key renamed on one side only is a switch that
/// silently does nothing, or a tap that lands nowhere (the vault lesson on
/// contracts between two languages).
void main() {
  final contract = File(
    '../functions/src/notifications/notification_contract.ts',
  ).readAsStringSync();
  final testCallable = File(
    '../functions/src/notifications/send_test_notification.ts',
  ).readAsStringSync();

  /// The quoted words of `export const <name> = [ ... ]`.
  List<String> listNamed(String source, String name) {
    final match = RegExp(
      'export const $name = \\[([^\\]]*)\\]',
      multiLine: true,
    ).firstMatch(source);
    expect(match, isNotNull, reason: '$name is gone from the contract');
    return RegExp("'([^']+)'")
        .allMatches(match!.group(1)!)
        .map((word) => word.group(1)!)
        .toList();
  }

  test('the categories', () {
    expect(
      NotificationCategory.values.map((value) => value.name),
      listNamed(contract, 'NOTIFICATION_CATEGORIES'),
    );
  });

  test('the categories a person switches off', () {
    expect(
      SwitchableCategory.values.map((value) => value.name),
      listNamed(contract, 'SWITCHABLE_CATEGORIES'),
    );
  });

  test('the digest sections, in the order they read', () {
    expect(
      DigestSectionKind.values.map((value) => value.name),
      listNamed(contract, 'DIGEST_SECTIONS'),
    );
  });

  test('where a tap lands', () {
    expect(
      NotificationTarget.values.map((value) => value.name),
      listNamed(contract, 'NOTIFICATION_TARGETS'),
    );
  });

  test('the push data keys', () {
    expect(PushDataKeys.all, listNamed(contract, 'PUSH_DATA_KEYS'));
  });

  test('every Android channel the server names is one the app creates', () {
    final named = RegExp("'(nestprep_\\w+)'")
        .allMatches(contract)
        .map((match) => match.group(1)!)
        .toSet();
    expect(named, AndroidChannel.values.map((channel) => channel.id).toSet());
  });

  test('the times: the step, the default digest, the quiet night', () {
    int constant(String name) => int.parse(
      RegExp(
        'export const $name = ([0-9 *+]+);',
      ).firstMatch(contract)!.group(1)!.split('+').fold<int>(0, (sum, term) {
        final factors = term.trim().split('*').map((f) => int.parse(f.trim()));
        return sum + factors.reduce((a, b) => a * b);
      }).toString(),
    );
    expect(constant('DIGEST_STEP_MINUTES'), DigestTimes.stepMinutes);
    expect(constant('DEFAULT_DIGEST_MINUTE'), DigestTimes.defaultMinute);
    expect(constant('DEFAULT_QUIET_START'), DigestTimes.quietStart);
    expect(constant('DEFAULT_QUIET_END'), DigestTimes.quietEnd);
  });

  test('the answers a test push can give', () {
    final match = RegExp('export type TestOutcome = ([^;]+);')
        .firstMatch(testCallable);
    expect(match, isNotNull);
    final words = RegExp("'(\\w+)'")
        .allMatches(match!.group(1)!)
        .map((word) => word.group(1)!)
        .toSet();
    expect(TestPushOutcome.values.map((value) => value.name).toSet(), words);
  });
}
