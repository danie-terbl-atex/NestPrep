import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/account_repository.dart';
import '../data/auth_gateway.dart';
import '../model/account.dart';
import '../model/auth_user.dart';
import '../model/kid_identity.dart';
import '../model/session.dart';
import '../model/session_check.dart';

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

  /// Bumped on every auth event and retry, so work an older one started — an
  /// account write that finally lands after the person tapped *Try again* —
  /// cannot overwrite what the newer one decided.
  int _generation = 0;

  /// How long a start waits on the session check before going on from the
  /// cache. Short, because offline this is pure delay.
  static const _checkBudget = Duration(seconds: 6);

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

  /// Which kid profile this device is signed in as, or null when it is not a
  /// kid device (accounts ADR-0003).
  KidIdentity? get kidIdentity => switch (_session) {
    AsyncData(value: KidSignedIn(:final kid)) => kid,
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

  /// Whether this account has still to agree to the documents this build
  /// ships — never agreed, or agreed to an older version (accounts ADR-0005).
  /// The router holds a person on the consent step until it is false.
  bool get needsLegalConsent => switch (_session) {
    AsyncData(value: final SignedIn signedIn) =>
      !signedIn.account.hasAcceptedCurrentLegal,
    _ => false,
  };

  /// Whether the consent being asked for replaces an earlier one, so the
  /// step says what changed rather than introducing itself.
  bool get hasAcceptedEarlierLegal => switch (_session) {
    AsyncData(value: final SignedIn signedIn) =>
      signedIn.account.hasAcceptedEarlierLegal,
    _ => false,
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
    _setSession(const AsyncLoading());
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
    final generation = ++_generation;
    bool isStale() => generation != _generation;
    _currentUser = user;
    await _accountSubscription?.cancel();
    _accountSubscription = null;
    if (isStale()) return;

    if (user == null) {
      _setSession(const AsyncData(SignedOut()));
      return;
    }

    // A session restored from disk is checked before anything trusts it: a
    // token the backend refuses makes every Firestore write wait for ever,
    // which is a gate that never opens. Offline keeps the cached session
    // (accounts ADR-0008).
    // The check has a budget, not the last word: the refresh behind it can be
    // slow (App Check being fetched first, a poor network), and the gate must
    // not wait on it. Past the budget the start goes on from the cache, and a
    // refusal that arrives later still signs the person out.
    final pending = _auth.checkSession();
    final check = await pending.timeout(
      _checkBudget,
      onTimeout: () {
        unawaited(
          pending.then((late) async {
            if (late == SessionCheck.rejected && !isStale()) {
              await _failSession(const SessionExpiredFailure());
            }
          }),
        );
        return SessionCheck.unverified;
      },
    );
    if (isStale()) return;
    if (check == SessionCheck.rejected) {
      await _failSession(const SessionExpiredFailure());
      return;
    }

    // A kid device has no account document to read or write: it is a profile
    // in one household, and that is the whole of its session (accounts
    // ADR-0003).
    final kid = user.kid;
    if (kid != null) {
      _setSession(AsyncData(KidSignedIn(uid: user.uid, kid: kid)));
      return;
    }

    try {
      await _accounts.ensureAccount(user);
    } on AppFailure catch (failure) {
      if (!isStale()) await _failSession(_ownAccountFailure(failure));
      return;
    }
    if (isStale()) return;

    _accountSubscription = _accounts
        .watch(user.uid)
        .listen(
          (account) {
            // Null means the document is not there yet — the write we just made
            // has not come back through the listener. Stay on loading rather
            // than flashing a signed-out screen at someone who is signed in.
            if (account == null) return;
            _setSession(AsyncData(SignedIn(user: user, account: account)));
          },
          onError: (Object error) {
            unawaited(
              _failSession(
                _ownAccountFailure(
                  error is AppFailure ? error : UnknownFailure(error),
                ),
              ),
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
    _setSession(AsyncFailure(failure));
  }

  void _onAuthError(Object error) {
    unawaited(
      _failSession(error is AppFailure ? error : UnknownFailure(error)),
    );
  }

  /// The rules let every signed-in person read their own account, always, so
  /// a refusal there means the request carried no identity the backend
  /// accepts — a dead session, not a permission (accounts ADR-0008).
  AppFailure _ownAccountFailure(AppFailure failure) =>
      failure is PermissionDeniedFailure
      ? const SessionExpiredFailure()
      : failure;

  void _setSession(AsyncState<Session> session) {
    _session = session;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_accountSubscription?.cancel());
    super.dispose();
  }
}
