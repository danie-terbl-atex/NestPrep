import 'dart:async';

import 'package:nestprep/features/referrals/data/referral_directory.dart';
import 'package:nestprep/features/referrals/data/referral_repository.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/premium_grant.dart';
import 'package:nestprep/features/referrals/model/referral_line.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The referral screen's three listeners, driven by hand (subscriptions
/// ADR-0002). Each starts with whatever a test hands the constructor, the way
/// a Firestore listener answers at once from its cache.
final class FakeReferralRepository implements ReferralRepository {
  FakeReferralRepository({
    HouseholdReferral? referral,
    List<ReferralLine>? lines,
    List<PremiumGrant>? grants,
  }) : _initialReferral = referral,
       _initialLines = lines,
       _initialGrants = grants;

  final HouseholdReferral? _initialReferral;
  final List<ReferralLine>? _initialLines;
  final List<PremiumGrant>? _initialGrants;

  final _referral = StreamController<HouseholdReferral>.broadcast();
  final _lines = StreamController<List<ReferralLine>>.broadcast();
  final _grants = StreamController<List<PremiumGrant>>.broadcast();

  void emitReferral(HouseholdReferral referral) => _referral.add(referral);
  void emitLines(List<ReferralLine> lines) => _lines.add(lines);
  void emitGrants(List<PremiumGrant> grants) => _grants.add(grants);
  void failHistory(Object error) => _lines.addError(error);

  Future<void> close() async {
    await _referral.close();
    await _lines.close();
    await _grants.close();
  }

  Stream<T> _starting<T>(T? initial, Stream<T> rest) =>
      initial == null ? rest : _after(initial, rest);

  Stream<T> _after<T>(T initial, Stream<T> rest) async* {
    yield initial;
    yield* rest;
  }

  @override
  Stream<HouseholdReferral> watchReferral(String householdId) =>
      _starting(_initialReferral, _referral.stream);

  @override
  Stream<List<ReferralLine>> watchHistory(String householdId) =>
      _starting(_initialLines, _lines.stream);

  @override
  Stream<List<PremiumGrant>> watchGrants(String householdId) =>
      _starting(_initialGrants, _grants.stream);
}

/// The referral callables: records what was asked, and answers or refuses as
/// a test says.
final class FakeReferralDirectory implements ReferralDirectory {
  final ensured = <String>[];
  final redeemed = <({String householdId, String code})>[];

  /// What `ensureCode` answers with; the repository has to be told separately,
  /// as the server writes the code into the document the screen listens to.
  String code = 'ABCD2345';
  AppFailure? failEnsureWith;
  AppFailure? failRedeemWith;
  DateTime qualifyBy = DateTime.utc(2026, 10, 20);

  @override
  Future<String> ensureCode(String householdId) async {
    ensured.add(householdId);
    final failure = failEnsureWith;
    if (failure != null) throw failure;
    return code;
  }

  @override
  Future<DateTime> redeem({
    required String householdId,
    required String code,
  }) async {
    final failure = failRedeemWith;
    if (failure != null) throw failure;
    redeemed.add((householdId: householdId, code: code));
    return qualifyBy;
  }
}
