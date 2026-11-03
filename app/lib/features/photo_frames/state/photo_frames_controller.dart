import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../data/photo_frame_repository.dart';
import '../model/frame_groceries.dart';
import '../model/frame_panels.dart';
import '../model/frame_screensaver.dart';
import '../model/photo_frame.dart';

final class PhotoFramesController extends ChangeNotifier
    with ActionFailureHolder {
  PhotoFramesController({
    required PhotoFrameRepository photoFrameRepository,
    required this.householdId,
    required List<Member> members,
  }) : _repository = photoFrameRepository,
       helpers = helpersAmong(members) {
    _subscribe();
  }

  final PhotoFrameRepository _repository;
  final String householdId;
  final List<Member> helpers;

  static const nameMaxLength = 40;

  static List<Member> helpersAmong(List<Member> members) => [
    for (final member in members)
      if (member.role == MemberRole.helper || member.role == MemberRole.carer)
        member,
  ];

  StreamSubscription<List<PhotoFrame>>? _subscription;
  AsyncState<List<PhotoFrame>> _frames = const AsyncLoading();
  bool _isInSheet = false;
  bool _isSaving = false;

  AsyncState<List<PhotoFrame>> get frames => _frames;

  bool get isInSheet => _isInSheet;

  bool get isSaving => _isSaving;

  Member? helperById(String? memberId) =>
      helpers.where((member) => member.id == memberId).firstOrNull;

  void openSheet() {
    _isInSheet = true;
    clearFailureQuietly();
    notifyListeners();
  }

  void closeSheet() {
    _isInSheet = false;
    clearFailureQuietly();
    notifyListeners();
  }

  static bool isValidName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= nameMaxLength;
  }

  Future<bool> save(
    PhotoFrame frame, {
    required String name,
    required FramePanels panels,
    required FrameScreensaver screensaver,
    required FrameGroceries? groceries,
  }) => _write(
    () => _repository.updateFrame(
      householdId: householdId,
      frameId: frame.id,
      name: name.trim(),
      panels: panels,
      screensaver: screensaver,
      groceries: groceries,
    ),
  );

  Future<bool> unlink(PhotoFrame frame) => _write(
    () => _repository.unlinkFrame(householdId: householdId, frameId: frame.id),
  );

  Future<bool> _write(Future<void> Function() write) async {
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();
    await runAction(write);
    _isSaving = false;
    notifyListeners();
    return actionFailure == null;
  }

  Future<void> retry() async {
    await _cancel();
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
    _frames = AsyncData(frames);
    notifyListeners();
  }

  void _onError(Object error) {
    _frames = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
