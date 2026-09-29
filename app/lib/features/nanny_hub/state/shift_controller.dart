import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/shift_directory.dart';
import '../data/shift_repository.dart';
import '../model/handover_draft.dart';
import '../model/handover_entry.dart';
import '../model/photo_change.dart';
import '../model/shift.dart';
import '../model/shift_checklist.dart';
import '../model/shift_log.dart';
import '../model/shift_moment.dart';
import 'photo_library.dart';

/// Shift mode: one shift, its checklists ticked and its log kept, and its end
/// (nanny-hub ADR-0002). The shift and its log are two live reads joined into
/// one `ShiftLog`, so the screen has one loading state (foundation ADR-0006).
///
/// Saving and ending each refuse a second tap while the first is in flight
/// (`FE-10`): a carer with a child on one hip taps twice.
final class ShiftController extends ChangeNotifier with ActionFailureHolder {
  ShiftController({
    required ShiftRepository shiftRepository,
    required ShiftDirectory shiftDirectory,
    required this.photos,
    required this.householdId,
    required this.shiftId,
    required this.memberId,
  }) : _repository = shiftRepository,
       _directory = shiftDirectory {
    _start();
  }

  final ShiftRepository _repository;
  final ShiftDirectory _directory;
  final PhotoLibrary photos;
  final String householdId;
  final String shiftId;

  /// The viewer's profile: whose entries are theirs to change.
  final String memberId;

  StreamSubscription<Shift?>? _shiftSubscription;
  StreamSubscription<List<HandoverEntry>>? _entrySubscription;
  (Shift?,)? _shift;
  List<HandoverEntry>? _entries;
  AsyncState<ShiftLog> _log = const AsyncLoading();
  var _isSaving = false;
  var _isEnding = false;

  AsyncState<ShiftLog> get log => _log;

  /// A log entry is being stored — its photo first, then the words.
  bool get isSaving => _isSaving;

  bool get isEnding => _isEnding;

  bool isMine(HandoverEntry entry) => entry.byMemberId == memberId;

  Future<void> retry() async {
    await _cancel();
    _shift = null;
    _entries = null;
    _log = const AsyncLoading();
    notifyListeners();
    _start();
  }

  Future<void> setTick(
    ShiftMoment moment,
    String itemId, {
    required bool isTicked,
  }) => runAction(
    () => _repository.setTick(
      householdId: householdId,
      shiftId: shiftId,
      tickKey: ShiftChecklist.tickKey(moment, itemId),
      isTicked: isTicked,
    ),
  );

  /// Logs an entry, storing its photo first so the entry never points at a
  /// photo that is not there. True when it was logged.
  Future<bool> addEntry(HandoverDraft draft, {Uint8List? photo}) =>
      _saving(() async {
        final photoId = photo == null ? null : await photos.store(photo);
        try {
          await _repository.addEntry(
            householdId: householdId,
            shiftId: shiftId,
            byMemberId: memberId,
            draft: draft.withPhoto(photoId),
          );
        } on AppFailure {
          if (photoId != null) await photos.discard(photoId);
          rethrow;
        }
      });

  Future<bool> updateEntry(
    HandoverEntry entry,
    HandoverDraft draft, {
    required PhotoChange photo,
  }) => _saving(() async {
    final photoId = switch (photo) {
      PhotoKept() => entry.photoId,
      PhotoRemoved() => null,
      PhotoPicked(:final bytes) => await photos.store(bytes),
    };
    try {
      await _repository.updateEntry(
        householdId: householdId,
        shiftId: shiftId,
        entryId: entry.id,
        draft: draft.withPhoto(photoId),
      );
    } on AppFailure {
      if (photo is PhotoPicked && photoId != null) {
        await photos.discard(photoId);
      }
      rethrow;
    }
    final replaced = entry.photoId;
    if (replaced != null && replaced != photoId) await photos.discard(replaced);
  });

  Future<void> removeEntry(HandoverEntry entry) => runAction(() async {
    await _repository.removeEntry(
      householdId: householdId,
      shiftId: shiftId,
      entryId: entry.id,
    );
    final photoId = entry.photoId;
    if (photoId != null) await photos.discard(photoId);
  });

  /// Ends the shift and has the summary written. True when it ended; the
  /// banner says why when it did not.
  Future<bool> end({String? closingNote}) async {
    if (_isEnding) return false;
    _isEnding = true;
    notifyListeners();
    var ended = false;
    await runAction(() async {
      await _directory.endShift(
        householdId: householdId,
        shiftId: shiftId,
        closingNote: closingNote?.trim().isEmpty ?? true
            ? null
            : closingNote?.trim(),
      );
      ended = true;
    });
    _isEnding = false;
    notifyListeners();
    return ended;
  }

  Future<bool> _saving(Future<void> Function() save) async {
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();
    var saved = false;
    await runAction(() async {
      await save();
      saved = true;
    });
    _isSaving = false;
    notifyListeners();
    return saved;
  }

  void _start() {
    _shiftSubscription = _repository
        .watchShift(householdId: householdId, shiftId: shiftId)
        .listen((shift) {
          _shift = (shift,);
          _publish();
        }, onError: _onError);
    _entrySubscription = _repository
        .watchEntries(householdId: householdId, shiftId: shiftId)
        .listen((entries) {
          _entries = entries;
          photos.ensure([for (final entry in entries) entry.photoId]);
          _publish();
        }, onError: _onError);
  }

  void _publish() {
    final shift = _shift;
    final entries = _entries;
    if (shift == null || entries == null) return;
    _log = AsyncData(ShiftLog(shift: shift.$1, entries: entries));
    notifyListeners();
  }

  void _onError(Object error) {
    _log = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _shiftSubscription?.cancel();
    await _entrySubscription?.cancel();
    _shiftSubscription = null;
    _entrySubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
