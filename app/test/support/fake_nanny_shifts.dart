import 'dart:async';

import 'package:nestprep/features/nanny_hub/data/shift_directory.dart';
import 'package:nestprep/features/nanny_hub/data/shift_repository.dart';
import 'package:nestprep/features/nanny_hub/model/handover_draft.dart';
import 'package:nestprep/features/nanny_hub/model/handover_entry.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Shifts, their log and their summaries, driven by hand.
final class FakeShiftRepository implements ShiftRepository {
  final openShifts = StreamController<List<Shift>>.broadcast();
  final summaries = StreamController<List<ShiftSummary>>.broadcast();
  final shift = StreamController<Shift?>.broadcast();
  final entries = StreamController<List<HandoverEntry>>.broadcast();

  AppFailure? failWritesWith;
  final writes = <(String, Map<String, Object?>)>[];

  /// The id `startShift` answers with.
  String startedId = 'shift-new';

  Future<void> close() async {
    await openShifts.close();
    await summaries.close();
    await shift.close();
    await entries.close();
  }

  Future<void> _record(String method, Map<String, Object?> arguments) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add((method, arguments));
  }

  @override
  Stream<List<Shift>> watchOpenShifts(String householdId) => openShifts.stream;
  @override
  Stream<List<ShiftSummary>> watchSummaries(String householdId) =>
      summaries.stream;
  @override
  Stream<Shift?> watchShift({
    required String householdId,
    required String shiftId,
  }) => shift.stream;
  @override
  Stream<List<HandoverEntry>> watchEntries({
    required String householdId,
    required String shiftId,
  }) => entries.stream;

  @override
  Future<String> startShift({
    required String householdId,
    required String carerMemberId,
    required String startedBy,
  }) async {
    await _record('startShift', {
      'carerMemberId': carerMemberId,
      'startedBy': startedBy,
    });
    return startedId;
  }

  @override
  Future<void> setTick({
    required String householdId,
    required String shiftId,
    required String tickKey,
    required bool isTicked,
  }) => _record('setTick', {'tickKey': tickKey, 'isTicked': isTicked});

  @override
  Future<void> addEntry({
    required String householdId,
    required String shiftId,
    required String byMemberId,
    required HandoverDraft draft,
  }) => _record('addEntry', {'byMemberId': byMemberId, 'draft': draft});

  @override
  Future<void> updateEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
    required HandoverDraft draft,
  }) => _record('updateEntry', {'entryId': entryId, 'draft': draft});

  @override
  Future<void> removeEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
  }) => _record('removeEntry', {'entryId': entryId});
}

/// `endNannyShift`, answered by the test.
final class FakeShiftDirectory implements ShiftDirectory {
  AppFailure? failWith;
  final ended = <({String shiftId, String? closingNote})>[];

  /// Held open until the test completes it, to catch a second tap.
  Completer<void>? gate;

  @override
  Future<void> endShift({
    required String householdId,
    required String shiftId,
    String? closingNote,
  }) async {
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    ended.add((shiftId: shiftId, closingNote: closingNote));
  }

  /// Every shift-only choice asked for, as `memberId → isShiftOnly`.
  final shiftOnly = <String, bool>{};

  @override
  Future<void> setCarerShiftOnly({
    required String householdId,
    required String memberId,
    required bool isShiftOnly,
  }) async {
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    shiftOnly[memberId] = isShiftOnly;
  }
}
