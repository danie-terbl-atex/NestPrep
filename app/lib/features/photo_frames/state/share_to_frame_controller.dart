import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/photo_frame_directory.dart';
import '../data/photo_frame_repository.dart';
import '../model/frame_share_item.dart';
import '../model/photo_frame.dart';
import '../model/shared_page.dart';

final class ShareToFrameController extends ChangeNotifier {
  ShareToFrameController({
    required PhotoFrameRepository photoFrameRepository,
    required PhotoFrameDirectory photoFrameDirectory,
    required this.householdId,
    required this.item,
    required this.isFamily,
  }) : _repository = photoFrameRepository,
       _directory = photoFrameDirectory {
    if (canSend) _subscribe();
  }

  final PhotoFrameRepository _repository;
  final PhotoFrameDirectory _directory;
  final String householdId;
  final FrameShareItem item;
  final bool isFamily;

  StreamSubscription<List<PhotoFrame>>? _subscription;
  AsyncState<List<PhotoFrame>> _frames = const AsyncLoading();
  String? _sendingTo;
  PhotoFrame? _sentTo;
  AppFailure? _failure;
  bool _isDisposed = false;

  bool get canSend => isFamily && item.isSendable;

  bool canOpen(PhotoFrame frame) => switch (item) {
    FrameSharePage() => true,
    FrameShareRecipe() => frame.opensRecipes,
  };

  AsyncState<List<PhotoFrame>> get frames => _frames;

  String? get sendingTo => _sendingTo;

  PhotoFrame? get sentTo => _sentTo;

  AppFailure? get failure => _failure;

  Future<void> send(PhotoFrame frame) async {
    if (!item.isSendable ||
        !canOpen(frame) ||
        _sendingTo != null ||
        _sentTo != null) {
      return;
    }
    _sendingTo = frame.id;
    _failure = null;
    notifyListeners();
    try {
      if (item case FrameSharePage(page: SharedPage(:final url?))
          when url.length > SharedPage.urlMaxLength) {
        throw const PhotoFrameFailure(PhotoFrameProblem.badLink);
      }
      await _directory.shareToFrame(
        householdId: householdId,
        frameId: frame.id,
        item: item,
      );
      _sentTo = frame;
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _sendingTo = null;
      if (!_isDisposed) notifyListeners();
    }
  }

  void retry() {
    unawaited(_subscription?.cancel());
    _frames = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchFrames(householdId)
        .listen(_onFrames, onError: _onError);
  }

  void _onFrames(List<PhotoFrame> frames) {
    _frames = AsyncData([
      for (final frame in frames)
        if (frame.panels.share) frame,
    ]);
    notifyListeners();
  }

  void _onError(Object error) {
    _frames = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
