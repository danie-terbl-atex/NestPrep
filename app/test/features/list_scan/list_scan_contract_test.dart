import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/list_scan/data/list_scan_failure_mapper.dart';
import 'package:nestprep/features/list_scan/model/list_photo.dart';
import 'package:nestprep/features/list_scan/model/list_reading.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

/// What the app and `readShoppingList` both write down (list-scan ADR-0001):
/// a reason, a flag or a limit renamed on one side breaks silently, so a
/// test reads both.
void main() {
  final refusals = File('../functions/src/list_scan/errors.ts')
      .readAsStringSync();
  final schemas = File('../functions/src/list_scan/schemas.ts')
      .readAsStringSync();
  final caller = File('../functions/src/list_scan/read_shopping_list.ts')
      .readAsStringSync();

  test('every refusal the server sends has words in the app', () {
    final start = refusals.indexOf('LIST_SCAN_REFUSALS =');
    final block = refusals.substring(start, refusals.indexOf('} as const'));
    final server = {
      for (final match in RegExp(
        r'^\s+(\w+): \[',
        multiLine: true,
      ).allMatches(block))
        match.group(1)!,
    };
    final app = {for (final problem in ListScanProblem.values) problem.name};
    expect(server, isNotEmpty);
    expect(app.containsAll(server), isTrue, reason: '$server vs $app');
  });

  test('the photo kind, the size limit, the flag and the paywall agree', () {
    expect(schemas, contains("'${ListPhoto.mimeType}'"));
    expect(schemas, contains('MAX_LIST_PHOTO_BYTES = 4 * 1024 * 1024'));
    expect(ListPhoto.maxBytes, 4 * 1024 * 1024);
    expect(
      caller,
      contains("readFlag(store, '${FeatureFlag.snapShoppingList.field}')"),
    );
    expect(
      caller,
      contains("premiumRequired('${PremiumFeature.listScan.name}')"),
    );
  });

  group('a refusal from the callable', () {
    AppFailure mapped(String code, [String? reason]) =>
        failureFromListScanCallable(
          FirebaseFunctionsException(
            code: code,
            message: 'server words',
            details: reason == null ? null : {'reason': reason},
          ),
        );

    test('keeps its own reason, the AI’s, the household’s and premium', () {
      expect(
        mapped('invalid-argument', 'listPhotoTooLarge'),
        isA<ListScanFailure>().having(
          (failure) => failure.problem,
          'problem',
          ListScanProblem.listPhotoTooLarge,
        ),
      );
      expect(mapped('resource-exhausted', 'aiLimitReached'), isA<AiFailure>());
      expect(
        mapped('permission-denied', 'notAMember'),
        isA<HouseholdFailure>(),
      );
      expect(
        mapped('failed-precondition', 'premiumRequired'),
        isA<PremiumRequiredFailure>().having(
          (failure) => failure.feature,
          'feature',
          PremiumFeature.listScan,
        ),
      );
    });

    test('falls back on the code when there is no reason', () {
      expect(mapped('deadline-exceeded'), isA<AiFailure>());
      expect(mapped('unavailable'), isA<UnavailableFailure>());
      expect(mapped('internal'), isA<UnknownFailure>());
    });
  });

  group('the reply', () {
    test('becomes lines in order, each with its own key', () {
      final reading = ListReading.fromWire({
        'lines': [
          {'name': 'Milk', 'quantity': '2 l'},
          {'name': 'Bread', 'quantity': null},
        ],
        'callsLeft': 42,
      });
      expect(reading.callsLeft, 42);
      expect(
        [
          for (final line in reading.lines)
            (line.key, line.name, line.quantity),
        ],
        [(0, 'Milk', '2 l'), (1, 'Bread', null)],
      );
    });

    test('leaves out a line it cannot read, and refuses a shape it cannot', () {
      final reading = ListReading.fromWire({
        'lines': [
          {'name': '  '},
          {'quantity': '3'},
          {'name': 'Tea', 'quantity': '  '},
        ],
        'callsLeft': 1,
      });
      expect([for (final line in reading.lines) line.name], ['Tea']);
      expect(reading.lines.single.quantity, isNull);
      expect(
        () => ListReading.fromWire({'lines': 'nope'}),
        throwsA(isA<AiFailure>()),
      );
      expect(() => ListReading.fromWire(null), throwsA(isA<AiFailure>()));
    });
  });
}
