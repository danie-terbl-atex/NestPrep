import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/photo_update_repository.dart';
import '../data/shift_repository.dart';
import '../model/photo_feed.dart';
import '../model/photo_update.dart';
import '../model/shift.dart';
import 'photo_library.dart';

/// One shift's photo updates: the parents' live feed, and the carer's way of
/// sending one (nanny-hub ADR-0004). The shift and its photos are two live
/// reads joined into one `PhotoFeed`, so a screen has one loading state.
///
/// Sending stores the photo first — compressed and stripped by the hub's one
/// `PhotoCompressor` — then writes the update that points at it, and takes the
/// photo back out if that write is refused, as every hub photo is handled
/// (nanny-hub ADR-0003). A second tap while one is on its way is not a second
/// photo (`FE-10`).
final class PhotoFeedController extends ChangeNotifier
    with ActionFailureHolder {
  PhotoFeedController({
    required PhotoUpdateRepository photoUpdateRepository,
    required ShiftRepository shiftRepository,
    required this.photos,
    required this.householdId,
    required this.shiftId,
    required this.memberId,
    required this.isFamily,
  }) : _updates = photoUpdateRepository,
       _shifts = shiftRepository {
    _start();
  }

  final PhotoUpdateRepository _updates;
  final ShiftRepository _shifts;
  final PhotoLibrary photos;
  final String householdId;
  final String shiftId;

  /// The viewer's profile: what a photo they send is stamped with.
  final String memberId;

  /// Family takes any photo back; everybody else only their own.
  final bool isFamily;

  StreamSubscription<Shift?>? _shiftSubscription;
  StreamSubscription<List<PhotoUpdate>>? _updateSubscription;
  (Shift?,)? _shift;
  List<PhotoUpdate>? _list;
  AsyncState<PhotoFeed> _feed = const AsyncLoading();
  var _isSending = false;

  AsyncState<PhotoFeed> get feed => _feed;

  /// A photo is on its way: compressing, storing, then the update.
  bool get isSending => _isSending;

  /// The sender takes a photo back while their shift is open; family, any
  /// time — the rules say the same.
  bool mayRemove(PhotoUpdate update, {required bool isShiftOpen}) =>
      isFamily || (isShiftOpen && update.byMemberId == memberId);

  /// Sends [picked] to the parents. True when it was sent; the banner says
  /// why when it was not.
  Future<bool> send(
    Uint8List picked, {
    String? caption,
    List<String> childIds = const [],
  }) async {
    if (_isSending) return false;
    _isSending = true;
    notifyListeners();
    var sent = false;
    await runAction(() async {
      final photoId = await photos.store(picked);
      try {
        await _updates.send((
          householdId: householdId,
          shiftId: shiftId,
          byMemberId: memberId,
          photoId: photoId,
          caption: _tidy(caption),
          childIds: childIds,
        ));
      } on AppFailure {
        await photos.discard(photoId);
        rethrow;
      }
      sent = true;
    });
    _isSending = false;
    notifyListeners();
    return sent;
  }

  Future<void> remove(PhotoUpdate update) => runAction(() async {
    await _updates.remove(
      householdId: householdId,
      shiftId: shiftId,
      updateId: update.id,
    );
    await photos.discard(update.photoId);
  });

  Future<void> retry() async {
    await _cancel();
    _shift = null;
    _list = null;
    _feed = const AsyncLoading();
    notifyListeners();
    _start();
  }

  static String? _tidy(String? caption) {
    final text = caption?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _start() {
    _shiftSubscription = _shifts
        .watchShift(householdId: householdId, shiftId: shiftId)
        .listen((shift) {
          _shift = (shift,);
          _publish();
        }, onError: _onError);
    _updateSubscription = _updates
        .watchUpdates(householdId: householdId, shiftId: shiftId)
        .listen((updates) {
          _list = updates;
          photos.ensure([for (final update in updates) update.photoId]);
          _publish();
        }, onError: _onError);
  }

  void _publish() {
    final shift = _shift;
    final list = _list;
    if (shift == null || list == null) return;
    _feed = AsyncData(PhotoFeed(shift: shift.$1, updates: list));
    notifyListeners();
  }

  void _onError(Object error) {
    _feed = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _shiftSubscription?.cancel();
    await _updateSubscription?.cancel();
    _shiftSubscription = null;
    _updateSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
