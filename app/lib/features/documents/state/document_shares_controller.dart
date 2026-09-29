import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/document_share_directory.dart';
import '../data/document_share_repository.dart';
import '../model/document_share.dart';

/// The Shared links screen (documents ADR-0006): every live link this person
/// may see — all of the household's for the family, their own otherwise —
/// soonest to end first, and the way to stop each one.
///
/// "Live" is asked of the server as of when the screen opened; a link that
/// runs out while somebody watches is dropped by the clock here, because the
/// status the server holds does not change when a time passes.
final class DocumentSharesController extends ChangeNotifier
    with ActionFailureHolder {
  DocumentSharesController({
    required this._repository,
    required this._directory,
    required this.householdId,
    required this.viewerUid,
    required this.isFamily,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _start();
  }

  final DocumentShareRepository _repository;
  final DocumentShareDirectory _directory;
  final String householdId;
  final String viewerUid;
  final bool isFamily;
  final DateTime Function() _now;

  StreamSubscription<List<DocumentShare>>? _subscription;
  AsyncState<List<DocumentShare>> _shares = const AsyncLoading();
  final _stopping = <String>{};

  AsyncState<List<DocumentShare>> get shares => switch (_shares) {
    AsyncData(:final value) => AsyncData([
      for (final share in value)
        if (share.isLiveAt(_now())) share,
    ]),
    final other => other,
  };

  bool isStopping(String shareId) => _stopping.contains(shareId);

  void _start() {
    _subscription = _repository
        .watchLiveShares(
          householdId: householdId,
          viewerUid: viewerUid,
          isFamily: isFamily,
          now: _now(),
        )
        .listen(
          (shares) {
            _shares = AsyncData(shares);
            notifyListeners();
          },
          onError: (Object error) {
            _shares = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _shares = const AsyncLoading();
    notifyListeners();
    _start();
  }

  /// Stops one link. It leaves the list when the server says so.
  Future<void> stop(DocumentShare share) async {
    if (_stopping.contains(share.id)) return;
    _stopping.add(share.id);
    notifyListeners();
    await runAction(
      () => _directory.revoke(householdId: householdId, shareId: share.id),
    );
    _stopping.remove(share.id);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
