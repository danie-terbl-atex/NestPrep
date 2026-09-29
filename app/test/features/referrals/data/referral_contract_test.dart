import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/data/callable_paywall_open_recorder.dart';
import 'package:nestprep/features/referrals/data/callable_referral_directory.dart';
import 'package:nestprep/features/referrals/data/firestore_referral_repository.dart';
import 'package:nestprep/features/referrals/data/referral_failure_mapper.dart';
import 'package:nestprep/features/referrals/model/referral_reward.dart';
import 'package:nestprep/features/referrals/model/referral_side.dart';
import 'package:nestprep/features/referrals/model/referral_status.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

/// Give a month, get a month written down in both languages (subscriptions
/// ADR-0002, product-analytics ADR-0002): the refusals, the statuses, sides
/// and rewards, where the documents live, and the callables' names. Each test
/// reads the server's own source, so the two cannot drift without something
/// going red — the lesson on contracts between two languages.
void main() {
  String source(String path) =>
      File('../functions/src/$path').readAsStringSync();

  Set<String> stringsOf(String text, String constant) {
    final start = text.indexOf('$constant = [');
    expect(start, isNonNegative, reason: constant);
    final block = text.substring(start, text.indexOf('] as const', start));
    return RegExp("'(\\w+)'").allMatches(block).map((m) => m.group(1)!).toSet();
  }

  String constantOf(String text, String name) {
    final match = RegExp("export const $name = '(\\w+)'").firstMatch(text);
    expect(match, isNotNull, reason: name);
    return match!.group(1)!;
  }

  test('every refusal the server can send is one the app has words for', () {
    final text = source('referrals/errors.ts');
    final start = text.indexOf('REFERRAL_REFUSALS = {');
    final block = text.substring(start, text.indexOf('} as const', start));
    final reasons = RegExp(
      r'^\s{2}(\w+):',
      multiLine: true,
    ).allMatches(block).map((m) => m.group(1)!).toSet();
    final referral = ReferralProblem.values.map((p) => p.name).toSet();
    final household = HouseholdProblem.values.map((p) => p.name).toSet();
    expect(reasons, isNotEmpty);
    for (final reason in reasons) {
      expect(
        referral.contains(reason) || household.contains(reason),
        isTrue,
        reason: '$reason has no copy in the app',
      );
    }
    expect(referral, everyElement(isIn(reasons)));
  });

  test('a refusal becomes its own sentence, never the server’s words', () {
    for (final problem in ReferralProblem.values) {
      final failure = failureFromReferralCallable(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'for the log, not for a person',
          details: {'reason': problem.name},
        ),
      );
      expect(failure, ReferralFailure(problem));
      expect(AppCopy.failure(failure), isNot(contains('for the log')));
    }
    expect(
      failureFromReferralCallable(
        FirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'bad',
          details: {'reason': 'badRequest'},
        ),
      ),
      const ReferralFailure(ReferralProblem.referralCodeNotFound),
    );
  });

  test('the statuses, sides and rewards are the ledger’s', () {
    final documents = source('referrals/referral_documents.ts');
    expect(
      ReferralStatus.values.map((v) => v.name).toSet(),
      stringsOf(documents, 'REFERRAL_STATUSES'),
    );
    expect(
      ReferralSide.values.map((v) => v.name).toSet(),
      stringsOf(documents, 'REFERRAL_SIDES'),
    );
    expect(
      ReferralReward.values.map((v) => v.name).toSet(),
      stringsOf(documents, 'REFERRAL_REWARDS'),
    );
  });

  test('the documents live where the Functions write them', () {
    final documents = source('referrals/referral_documents.ts');
    expect(
      FirestoreReferralRepository.referralPath,
      constantOf(documents, 'REFERRAL'),
    );
    expect(
      FirestoreReferralRepository.currentReferral,
      constantOf(documents, 'CURRENT'),
    );
    expect(
      FirestoreReferralRepository.historyPath,
      constantOf(documents, 'REFERRAL_HISTORY'),
    );
    expect(
      FirestoreReferralRepository.grantsPath,
      constantOf(
        source('subscriptions/household_premium.ts'),
        'PREMIUM_GRANTS',
      ),
    );
  });

  test('the callables the app calls are the ones the server exports', () {
    final index = source('index.ts');
    for (final name in [
      CallableReferralDirectory.ensureCallable,
      CallableReferralDirectory.redeemCallable,
      CallablePaywallOpenRecorder.callableName,
    ]) {
      expect(index, contains('export { $name }'));
    }
  });

  test('the switch is the one the server reads', () {
    expect(
      stringsOf(source('shared/feature_flags.ts'), 'FEATURE_FLAGS'),
      contains(FeatureFlag.referralRewards.field),
    );
  });
}
