import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../data/invite_links.dart';

/// The invite code a tapped link brought in, held until the person joins or
/// says not now (household ADR-0005). It outlives sign-in, so somebody who
/// taps the link before they have an account still lands on the invite.
final class PendingInvite extends ChangeNotifier {
  PendingInvite({required Stream<Uri> links}) {
    _subscription = links.listen(
      _offer,
      onError: (Object error) =>
          AppLog.failure('invite link', code: 'stream', error: error),
    );
  }

  late final StreamSubscription<Uri> _subscription;
  String? _code;

  String? get code => _code;

  void clear() {
    if (_code == null) return;
    _code = null;
    notifyListeners();
  }

  /// A code typed on the sign-in screen, held exactly as a tapped link's
  /// would be. False when it is not the shape of an invite code.
  bool offerCode(String typed) {
    final code = InviteLinks.codeFrom(
      Uri(scheme: InviteLinks.scheme, host: 'invite', path: '/${typed.trim()}'),
    );
    if (code == null) return false;
    _hold(code);
    return true;
  }

  void _offer(Uri uri) {
    final code = InviteLinks.codeFrom(uri);
    if (code != null) _hold(code);
  }

  void _hold(String code) {
    if (code == _code) return;
    _code = code;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
