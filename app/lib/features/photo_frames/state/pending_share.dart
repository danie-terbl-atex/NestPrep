import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../model/shared_page.dart';

final class PendingShare extends ChangeNotifier {
  PendingShare({required Stream<Uri> links}) {
    _subscription = links.listen(
      _offer,
      onError: (Object error) =>
          AppLog.failure('share link', code: 'stream', error: error),
    );
  }

  late final StreamSubscription<Uri> _subscription;
  SharedPage? _page;

  SharedPage? get page => _page;

  SharedPage? take() {
    final page = _page;
    if (page == null) return null;
    _page = null;
    notifyListeners();
    return page;
  }

  void _offer(Uri uri) {
    final page = SharedPage.fromLink(uri);
    if (page == null) return;
    _page = page;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
