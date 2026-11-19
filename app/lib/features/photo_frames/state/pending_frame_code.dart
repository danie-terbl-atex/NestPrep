import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../model/frame_code.dart';

/// The code of a frame whose QR was scanned with the phone's own camera,
/// held through sign-in until the household shell opens *Link a frame* on it
/// (household ADR-0012).
final class PendingFrameCode extends ChangeNotifier {
  PendingFrameCode({required Stream<Uri> links}) {
    _subscription = links.listen(
      _offer,
      onError: (Object error) =>
          AppLog.failure('frame link', code: 'stream', error: error),
    );
  }

  late final StreamSubscription<Uri> _subscription;
  String? _code;

  String? get code => _code;

  String? take() {
    final code = _code;
    if (code == null) return null;
    _code = null;
    notifyListeners();
    return code;
  }

  void _offer(Uri uri) {
    final code = FrameCode.fromLink(uri);
    if (code == null || code == _code) return;
    _code = code;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
