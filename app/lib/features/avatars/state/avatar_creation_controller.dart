import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/avatar_photo_store.dart';
import '../data/avatar_repository.dart';
import '../model/avatar_buddy.dart';
import '../model/avatar_creation.dart';
import 'creation_step.dart';

final class AvatarCreationController extends ChangeNotifier
    with ActionFailureHolder {
  AvatarCreationController({
    required AvatarRepository avatarRepository,
    required AvatarPhotoStore photoStore,
    required this.householdId,
    required this.memberId,
    required this.viewerMemberId,
    required this.viewerUid,
    this.wait = const Duration(seconds: 120),
  }) : _avatars = avatarRepository,
       _photos = photoStore {
    _recentSubscription = _avatars
        .watchRecentCreations(householdId)
        .listen(
          (creations) {
            _recent = creations;
            notifyListeners();
          },
          onError: (Object _) {
            _recent = null;
            notifyListeners();
          },
        );
  }

  static const extraLength = 60;

  final AvatarRepository _avatars;
  final AvatarPhotoStore _photos;
  final String householdId;
  final String memberId;
  final String viewerMemberId;
  final String viewerUid;
  final Duration wait;

  StreamSubscription<List<AvatarCreation>>? _recentSubscription;
  StreamSubscription<AvatarCreation?>? _subscription;
  Timer? _timer;
  List<AvatarCreation>? _recent;
  CreationStep _step = const CreationComposing();
  AvatarBuddy? _buddy;
  int _run = 0;

  CreationStep get step => _step;

  List<AvatarCreation> get recent => _recent ?? const [];

  bool get isBusy => _step is CreationSending || _step is CreationWaiting;

  Future<void> makeFromPicture({
    required CreationRecipe recipe,
    required Uint8List jpeg,
    CreationStyle? style,
  }) => _make(recipe: recipe, style: style, reference: jpeg);

  Future<void> makeBuddy(
    AvatarBuddy buddy, {
    String? extra,
    CreationStyle? style,
  }) {
    final trimmed = extra?.trim() ?? '';
    return _make(
      recipe: CreationRecipe.buddy,
      style: style,
      buddy: buddy,
      extra: trimmed.isEmpty
          ? null
          : trimmed.substring(0, trimmed.length.clamp(0, extraLength)),
    );
  }

  Future<void> makePortrait() => _make(recipe: CreationRecipe.portrait);

  Future<void> _make({
    required CreationRecipe recipe,
    CreationStyle? style,
    AvatarBuddy? buddy,
    String? extra,
    Uint8List? reference,
  }) async {
    if (isBusy) return;
    await _stop();
    final run = ++_run;
    _buddy = buddy;
    _step = CreationSending(recipe);
    notifyListeners();
    final creationId = _avatars.newCreationId(householdId);
    _startTimer(run, recipe);
    await runAction(() async {
      try {
        await _send(
          creationId: creationId,
          recipe: recipe,
          style: style,
          buddy: buddy,
          extra: extra,
          reference: reference,
        ).timeout(wait);
      } on TimeoutException {
        if (run != _run) return;
        _settle(CreationTooSlow(recipe));
        _follow(run, creationId, recipe);
        return;
      } on AppFailure {
        if (run == _run) {
          _timer?.cancel();
          _step = const CreationComposing();
          notifyListeners();
        }
        rethrow;
      }
      if (run != _run) return;
      if (_step is CreationSending) {
        _step = CreationWaiting(recipe);
        notifyListeners();
      }
      _follow(run, creationId, recipe);
    });
  }

  Future<void> _send({
    required String creationId,
    required CreationRecipe recipe,
    CreationStyle? style,
    AvatarBuddy? buddy,
    String? extra,
    Uint8List? reference,
  }) async {
    if (reference != null) {
      await _photos.uploadReference(
        householdId: householdId,
        memberId: memberId,
        inboxId: creationId,
        uploaderUid: viewerUid,
        bytes: reference,
      );
    }
    await _avatars.requestCreation(
      householdId: householdId,
      creationId: creationId,
      memberId: memberId,
      recipe: recipe,
      byMemberId: viewerMemberId,
      style: recipe == CreationRecipe.portrait ? null : style,
      buddy: buddy,
      extra: extra,
      inboxId: reference == null ? null : creationId,
    );
  }

  void _startTimer(int run, CreationRecipe recipe) {
    _timer?.cancel();
    _timer = Timer(wait, () {
      if (run != _run || !isBusy) return;
      _step = CreationTooSlow(recipe);
      notifyListeners();
    });
  }

  void _follow(int run, String creationId, CreationRecipe recipe) {
    _subscription = _avatars
        .watchCreation(householdId, creationId)
        .listen(
          (creation) {
            if (run != _run || creation == null) return;
            if (creation.isReady) {
              _settle(CreationReady(creation, buddy: _buddy));
            } else if (creation.isSettled) {
              _settle(
                CreationRefused(
                  recipe,
                  creation.reason ?? CreationRefusal.unavailable,
                  left: creation.left,
                ),
              );
            } else if (_step is CreationWaiting) {
              _step = CreationWaiting(recipe, status: creation.status);
              notifyListeners();
            }
          },
          onError: (Object error) {
            if (run != _run) return;
            _settle(CreationRefused(recipe, CreationRefusal.unavailable));
          },
        );
  }

  void _settle(CreationStep step) {
    if (step is! CreationTooSlow) unawaited(_stop());
    _step = step;
    notifyListeners();
  }

  Future<void> startOver() async {
    _run++;
    await _stop();
    _buddy = null;
    _step = const CreationComposing();
    notifyListeners();
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    final cancelling = _subscription?.cancel();
    _subscription = null;
    await cancelling;
  }

  Future<void> _cancel() async {
    final cancelling = _recentSubscription?.cancel();
    _recentSubscription = null;
    await _stop();
    await cancelling;
  }

  @override
  void dispose() {
    _run++;
    unawaited(_cancel());
    super.dispose();
  }
}
