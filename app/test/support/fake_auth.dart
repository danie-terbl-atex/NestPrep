import 'dart:async';

import 'package:nestprep/features/accounts/data/account_repository.dart';
import 'package:nestprep/features/accounts/data/auth_gateway.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
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

  int signOutCount = 0;
  final googleSignIns = <int>[];

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
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  }) => _signIn(AuthUser(uid: 'uid-$email', email: email));

  @override
  Future<void> signOut() async {
    signOutCount += 1;
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

  void emit(Account? account) => _accounts.add(account);
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
}
