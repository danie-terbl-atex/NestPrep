import 'dart:async';

import 'package:nestprep/features/accounts/data/account_repository.dart';
import 'package:nestprep/features/accounts/data/auth_gateway.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/legal_consent.dart';
import 'package:nestprep/features/legal/model/legal_versions.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Firebase Auth, without a platform channel. A test drives who is signed in by
/// hand (foundation ADR-0006).
final class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({AuthUser? signedInAs}) {
    if (signedInAs != null) _users.add(signedInAs);
  }

  final _users = StreamController<AuthUser?>.broadcast();

  /// Set to make the next sign-in fail the way Google or Firebase would.
  AppFailure? failSignInWith;

  /// Set to make a reset send fail.
  AppFailure? failSendWith;

  int signOutCount = 0;
  final googleSignIns = <int>[];
  final registrations = <String>[];
  final emailSignIns = <String>[];
  final passwordResetsSentTo = <String>[];

  @override
  String? pendingLinkEmail;

  void emit(AuthUser? user) => _users.add(user);
  void failStreamWith(Object error) => _users.addError(error);
  Future<void> close() => _users.close();

  @override
  Stream<AuthUser?> authStateChanges() => _users.stream;

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleSignIns.add(googleSignIns.length);
    return _signIn(
      const AuthUser(
        uid: 'uid-sam',
        email: 'sam@nestprep.test',
        displayName: 'Sam Parent',
      ),
    );
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    emailSignIns.add(email);
    return _signIn(AuthUser(uid: 'uid-$email', email: email));
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    registrations.add(email);
    return _signIn(
      AuthUser(uid: 'uid-$email', email: email, displayName: displayName),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final failure = failSendWith;
    if (failure != null) throw failure;
    passwordResetsSentTo.add(email);
  }

  @override
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  }) => _signIn(AuthUser(uid: 'uid-$email', email: email));

  /// The tokens a kid device signed in with, and who each one signs in as —
  /// set [kidTokenSignsInAs] to play out `redeemKidPairing`'s token.
  final kidTokens = <String>[];
  AuthUser? kidTokenSignsInAs;

  @override
  Future<AuthUser> signInWithKidToken(String token) {
    kidTokens.add(token);
    return _signIn(kidTokenSignsInAs ?? AuthUser(uid: 'kid_$token', email: ''));
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    pendingLinkEmail = null;
    _users.add(null);
  }

  Future<AuthUser> _signIn(AuthUser user) async {
    final failure = failSignInWith;
    if (failure != null) throw failure;
    _users.add(user);
    return user;
  }
}

/// `users/{uid}`, in memory.
final class FakeAccountRepository implements AccountRepository {
  final _accounts = StreamController<Account?>.broadcast();

  AppFailure? failWritesWith;
  final ensured = <String>[];
  final activeHouseholds = <String>[];
  final acceptedLegal = <LegalConsent>[];

  /// What this build asks people to agree to, as an account that has.
  static const currentConsent = LegalConsent(
    termsVersion: LegalVersions.terms,
    privacyVersion: LegalVersions.privacy,
  );

  /// Emits [account] as the account document. An account with no consent is
  /// emitted as one that has agreed to the current documents, so the tests
  /// written before the consent step keep testing what they were written for
  /// (accounts ADR-0005); pass [consented] false to meet the consent step.
  void emit(Account? account, {bool consented = true}) => _accounts.add(
    consented && account != null && account.legalConsent == null
        ? account.copyWith(legalConsent: currentConsent)
        : account,
  );
  void failStreamWith(Object error) => _accounts.addError(error);
  Future<void> close() => _accounts.close();

  @override
  Stream<Account?> watch(String uid) => _accounts.stream;

  @override
  Future<void> ensureAccount(AuthUser user) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    ensured.add(user.uid);
  }

  @override
  Future<void> setActiveHousehold({
    required String uid,
    required String householdId,
  }) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    activeHouseholds.add(householdId);
  }

  @override
  Future<void> acceptLegal({
    required String uid,
    required int termsVersion,
    required int privacyVersion,
  }) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    acceptedLegal.add(
      LegalConsent(termsVersion: termsVersion, privacyVersion: privacyVersion),
    );
  }
}
