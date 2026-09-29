import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/log/best_effort.dart';
import '../data/push_gateway.dart';
import '../data/push_token_repository.dart';
import '../model/notification_vocabulary.dart';
import '../model/push_arrival.dart';
import '../model/push_token.dart';

/// This phone's part of the channel (notifications ADR-0001, ADR-0003): it
/// knows whether the phone lets the app notify, registers the phone's token
/// for whoever is signed in, follows the token when it rotates, and forgets it
/// on sign-out so a shared phone stops buzzing for the last person.
///
/// It never asks for permission by itself. [turnOn] is the only way the
/// phone's prompt appears, and only a person's tap calls it.
final class PushRegistrar extends ChangeNotifier {
  PushRegistrar({
    required this._gateway,
    required this._tokens,
    required this._session,
    required this._signedInUid,
  });

  final PushGateway _gateway;
  final PushTokenRepository _tokens;
  final Listenable _session;
  final String Function() _signedInUid;

  StreamSubscription<String>? _refreshes;
  PushPermission _permission = PushPermission.unknown;
  String _uid = '';
  String? _registered;
  bool _isAsking = false;
  bool _started = false;

  PushPermission get permission => _permission;

  /// Whether this phone can be reached: allowed, and its token is on file.
  bool get isReachable =>
      _permission == PushPermission.granted && _registered != null;

  /// Whether the phone's prompt is up, so its button cannot be pressed twice.
  bool get isAsking => _isAsking;

  /// Reads the phone's answer and registers quietly when it is already yes.
  /// Called once, after the first frame; it asks nobody anything.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await bestEffort(
      'push channels',
      code: 'prepare',
      run: () => _gateway.prepareChannels(_channelSpecs),
    );
    _session.addListener(_followSession);
    _refreshes = _gateway.tokenRefreshes.listen(_register);
    _permission = await _gateway.permission();
    notifyListeners();
    await _followSessionNow();
  }

  /// Shows the phone's prompt and, on a yes, registers this phone. Answers
  /// what the phone said.
  Future<PushPermission> turnOn() async {
    if (_isAsking) return _permission;
    _isAsking = true;
    notifyListeners();
    try {
      _permission = await _gateway.requestPermission();
      if (_permission == PushPermission.granted) await _registerCurrent();
      return _permission;
    } finally {
      _isAsking = false;
      notifyListeners();
    }
  }

  void _followSession() => unawaited(_followSessionNow());

  Future<void> _followSessionNow() async {
    final uid = _signedInUid();
    if (uid == _uid) return;
    final wasSignedIn = _uid.isNotEmpty;
    _uid = uid;
    if (uid.isEmpty) {
      _registered = null;
      notifyListeners();
      // Signed out: the token dies with the session, so the next send to it
      // is refused and the server forgets it (ADR-0001).
      if (wasSignedIn) {
        await bestEffort(
          'push token',
          code: 'forget',
          run: _gateway.forgetToken,
        );
      }
      return;
    }
    if (_permission == PushPermission.granted) await _registerCurrent();
  }

  Future<void> _registerCurrent() async {
    final token = await _gateway.token();
    if (token == null) {
      _registered = null;
      notifyListeners();
      return;
    }
    await _register(token);
  }

  Future<void> _register(String token) async {
    final platform = _gateway.platform;
    // Whoever is signed in now — a tap can come before [start] has run.
    final uid = _signedInUid();
    if (uid.isEmpty || platform == null) return;
    try {
      await _tokens.register(uid, PushToken.of(token, platform));
      _registered = token;
    } on AppFailure catch (failure) {
      // The inbox still fills; the phone simply is not reachable, and the
      // settings screen says so rather than claiming otherwise.
      _registered = null;
      AppLog.failure('push token', code: 'register', error: failure);
    }
    notifyListeners();
  }

  static final _channelSpecs = [
    for (final channel in AndroidChannel.values)
      PushChannelSpec(
        id: channel.id,
        name: NotificationsCopy.channelName(channel),
        description: NotificationsCopy.channelDescription(channel),
        isImportant: channel != AndroidChannel.digest,
      ),
  ];

  @override
  void dispose() {
    _session.removeListener(_followSession);
    unawaited(_refreshes?.cancel());
    super.dispose();
  }
}
