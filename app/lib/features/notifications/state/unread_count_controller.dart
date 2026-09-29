import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../data/notification_repository.dart';

/// How many notifications a person has not read — the bell's dot. A bell that
/// cannot read its count shows no dot and says so in the log: the inbox it
/// opens has the real error and the retry (`FE-08`, `ENG-10`).
final class UnreadCountController extends ChangeNotifier {
  UnreadCountController({
    required NotificationRepository repository,
    required String householdId,
    required String memberId,
  }) {
    _subscription = repository
        .watchUnreadCount(householdId, memberId)
        .listen(
          (count) {
            _count = count;
            notifyListeners();
          },
          onError: (Object error) {
            AppLog.failure('unread count', code: 'listen', error: error);
            _count = 0;
            notifyListeners();
          },
        );
  }

  StreamSubscription<int>? _subscription;
  int _count = 0;

  int get count => _count;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
