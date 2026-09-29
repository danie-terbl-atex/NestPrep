import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/account_repository.dart';
import '../data/auth_gateway.dart';
import '../model/account.dart';
import '../model/auth_user.dart';
import '../model/session.dart';

/// Who is signed in, for the whole app. This is the one controller that is not
/// route-scoped: the router redirects on it, so it has to outlive every route
/// (foundation ADR-0006 — lifting a controller is a deliberate choice, and this
/// is the one place it is made).
final class SessionController extends ChangeNotifier {
  SessionController({
    required AuthGateway authGateway,
    required AccountRepository accountRepository,
  }) : _auth = authGateway,
       _accounts = accountRepository {
    _authSubscription = _auth.authStateChanges().listen(
      _onAuthUser,
      onError: _onAuthError,
    );
  }

  final AuthGateway _auth;
  final AccountRepository _accounts;

  StreamSubscription<AuthUser?>? _authSubscription;
  StreamSubscription<Account?>? _accountSubscription;

  AsyncState<Session> _session = const AsyncLoading();
  bool _isSigningIn = false;
  AppFailure? _signInFailure;

  AsyncState<Session> get session => _session;
  bool get isSigningIn => _isSigningIn;

  /// The last sign-in failure worth telling the person about. Backing out of
  /// the Google sheet is not one.
  AppFailure? get signInFailure => _signInFailure;

  /// The household every feature's route is scoped by, or null when this
  /// account belongs to none yet (household ADR-0002).
  String? get activeHouseholdId => switch (_session) {
    AsyncData(value: final SignedIn signedIn) =>
      signedIn.account.householdToShow,
    _ => null,
  };

  /// The uid every rule keys on, or the empty string when nobody is signed in —
  /// a value no rule matches, which is the right answer for a screen that is
  /// about to be redirected away.
  String get uidOrEmpty => switch (_session) {
    AsyncData(value: final SignedIn signedIn) => signedIn.uid,
    _ => '',
  };

  /// What to call this person before they have named their own profile.
  String get suggestedDisplayName => switch (_session) {
    AsyncData(value: final SignedIn signedIn) => signedIn.user.bestName,
    _ => '',
  };

  /// Whether Firebase says this person has proved their address. A Google
  /// credential always has; a password one has not until they open the link.
  /// The router reads this to decide whether there is any point showing the
  /// household gate — the callables refuse an unverified caller anyway
  /// (accounts ADR-0002), so this only saves them the round trip.
  bool get emailVerified => switch (_session) {
    AsyncData(value: final SignedIn signedIn) => signedIn.user.emailVerified,
    // Nobody signed in has nothing to verify, and saying "false" here would
    // route a signed-out person at the verify screen.
    _ => true,
  };

  /// The address a credential is waiting to be linked onto, so the sign-in
  /// screen can say whose account it is about to join up.
  String? get pendingLinkEmail => _auth.pendingLinkEmail;

  Future<void> signInWithGoogle() => _attemptSignIn(_auth.signInWithGoogle);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _attemptSignIn(
    () => _auth.signInWithEmail(email: email.trim(), password: password),
  );

  /// Asks Firebase again whether the address has been verified since, because
  /// nothing pushes that claim to the app — the person proves it on a web page
  /// this app never sees. Returns whether it has.
  Future<bool> refreshEmailVerified() async {
    try {
      final verified = await _auth.refreshEmailVerified();
      if (verified) {
        // The token the callables read has changed, so the session has to be
        // rebuilt from it or the gate stays shut for a person who is through it.
        await _onAuthUser(_currentUser?.copyWith(emailVerified: true));
      }
      return verified;
    } on AppFailure catch (failure) {
      _signInFailure = failure;
      notifyListeners();
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _auth.sendEmailVerification();
    } on AppFailure catch (failure) {
      _signInFailure = failure;
      notifyListeners();
    }
  }

  Future<void> signInWithSeededUser({
    required String email,
    required String password,
  }) => _attemptSignIn(
    () => _auth.signInWithSeededUser(email: email, password: password),
  );

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AppFailure catch (failure) {
      _signInFailure = failure;
      notifyListeners();
    }
  }

  /// Retries the read of the account document after a failure, without signing
  /// the person out to do it.
  Future<void> retry() async {
    _session = const AsyncLoading();
    notifyListeners();
    await _onAuthUser(_currentUser);
  }

  Future<void> switchHousehold(String householdId) async {
    final signedIn = switch (_session) {
      AsyncData(value: final SignedIn value) => value,
      _ => null,
    };
    if (signedIn == null || signedIn.account.activeHouseholdId == householdId) {
      return;
    }
    try {
      await _accounts.setActiveHousehold(
        uid: signedIn.uid,
        householdId: householdId,
      );
    } on AppFailure catch (failure) {
      _signInFailure = failure;
      notifyListeners();
    }
  }

  AuthUser? _currentUser;

  Future<void> _attemptSignIn(Future<AuthUser> Function() signIn) async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    _signInFailure = null;
    notifyListeners();
    try {
      await signIn();
      // The auth stream drives the rest; it has already fired by the time this
      // returns, or it will in a moment.
    } on AppFailure catch (failure) {
      _signInFailure = failure is SignInFailure && !failure.isWorthShowing
          ? null
          : failure;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> _onAuthUser(AuthUser? user) async {
    _currentUser = user;
    await _accountSubscription?.cancel();
    _accountSubscription = null;

    if (user == null) {
      _session = const AsyncData(SignedOut());
      notifyListeners();
      return;
    }

    try {
      await _accounts.ensureAccount(user);
    } on AppFailure catch (failure) {
      await _failSession(failure);
      return;
    }

    _accountSubscription = _accounts
        .watch(user.uid)
        .listen(
          (account) {
            // Null means the document is not there yet — the write we just made
            // has not come back through the listener. Stay on loading rather
            // than flashing a signed-out screen at someone who is signed in.
            if (account == null) return;
            _session = AsyncData(SignedIn(user: user, account: account));
            notifyListeners();
          },
          onError: (Object error) {
            unawaited(
              _failSession(error is AppFailure ? error : UnknownFailure(error)),
            );
          },
        );
  }

  /// A failed session read. A session the backend no longer accepts is not
  /// something retrying fixes, so the person is signed out and lands back on
  /// the sign-in screen with copy that says why.
  Future<void> _failSession(AppFailure failure) async {
    if (failure is SessionExpiredFailure) {
      _signInFailure = failure;
      await signOut();
      return;
    }
    _session = AsyncFailure(failure);
    notifyListeners();
  }

  void _onAuthError(Object error) {
    _session = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_accountSubscription?.cancel());
    super.dispose();
  }
}
