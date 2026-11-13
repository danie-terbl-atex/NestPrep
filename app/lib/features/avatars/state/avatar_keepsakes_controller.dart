import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/avatar_repository.dart';
import '../model/avatar_keepsake.dart';

final class AvatarKeepsakesController extends ChangeNotifier
    with ActionFailureHolder {
  AvatarKeepsakesController({
    required AvatarRepository avatarRepository,
    required this.householdId,
    required this.memberId,
    required this.viewerMemberId,
  }) : _avatars = avatarRepository {
    _listen();
  }

  final AvatarRepository _avatars;
  final String householdId;
  final String memberId;
  final String viewerMemberId;

  StreamSubscription<List<AvatarKeepsake>>? _subscription;
  AsyncState<List<AvatarKeepsake>> _keepsakes = const AsyncLoading();
  List<AvatarKeepsake> _shelf = const [];
  final _deleting = <String>{};

  AsyncState<List<AvatarKeepsake>> get keepsakes => _keepsakes;

  bool get hasAny => _shelf.isNotEmpty;
  bool isDeleting(String keepsakeId) => _deleting.contains(keepsakeId);

  void _listen() {
    _subscription = _avatars
        .watchKeepsakes(householdId, memberId)
        .listen(
          (keepsakes) {
            _shelf = keepsakes;
            _deleting.removeWhere(
              (id) => !keepsakes.any((keepsake) => keepsake.id == id),
            );
            _publish();
          },
          onError: (Object error) {
            _keepsakes = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  void _publish() {
    _keepsakes = AsyncData(_shelf);
    notifyListeners();
  }

  Future<void> delete(AvatarKeepsake keepsake) async {
    if (_deleting.contains(keepsake.id)) return;
    _deleting.add(keepsake.id);
    _publish();
    await runAction(() async {
      try {
        await _avatars.deleteKeepsake(
          householdId: householdId,
          keepsakeId: keepsake.id,
          byMemberId: viewerMemberId,
        );
      } on AppFailure {
        _deleting.remove(keepsake.id);
        _publish();
        rethrow;
      }
    });
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _keepsakes = const AsyncLoading();
    notifyListeners();
    _listen();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
