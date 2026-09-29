import 'dart:async';

import 'package:nestprep/features/home_care/data/helper_profile_repository.dart';
import 'package:nestprep/features/home_care/data/read_aloud.dart';
import 'package:nestprep/features/home_care/data/routine_repository.dart';
import 'package:nestprep/features/home_care/data/translation_repository.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_tick.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'fake_home_care.dart';

/// The room routines and their ticks, driven by hand (home-care ADR-0004).
final class FakeRoutineRepository
    with RecordsWrites
    implements RoutineRepository {
  final _routines = StreamController<List<RoomRoutine>>.broadcast();
  final _ticks = StreamController<List<RoutineTick>>.broadcast();

  /// Each read's scope: null for everybody's, else the helper asked for.
  final routinesAskedFor = <String?>[];
  final ticksAskedFor =
      <({CalendarDate from, CalendarDate to, String? helperId})>[];

  void emitRoutines(List<RoomRoutine> routines) => _routines.add(routines);
  void emitTicks(List<RoutineTick> ticks) => _ticks.add(ticks);
  void failRoutinesWith(Object error) => _routines.addError(error);

  Future<void> close() async {
    await _routines.close();
    await _ticks.close();
  }

  @override
  Stream<List<RoomRoutine>> watchRoutines(
    String householdId, {
    String? helperId,
  }) {
    routinesAskedFor.add(helperId);
    return _routines.stream;
  }

  @override
  Stream<List<RoutineTick>> watchTicks(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? helperId,
  }) {
    ticksAskedFor.add((from: from, to: to, helperId: helperId));
    return _ticks.stream;
  }

  @override
  Future<void> saveRoutine({
    required String householdId,
    required RoomRoutine routine,
  }) => record('saveRoutine', {'routine': routine});

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) => record('deleteRoutine', {'routineId': routineId});

  @override
  Future<void> setDoneItems({
    required String householdId,
    required RoomRoutine routine,
    required CalendarDate day,
    required List<String> doneItemIds,
    required String by,
  }) => record('setDoneItems', {
    'routineId': routine.id,
    'day': day,
    'doneItemIds': doneItemIds,
    'by': by,
  });
}

/// Everybody's language, driven by hand (home-care ADR-0006).
final class FakeHelperProfileRepository
    with RecordsWrites
    implements HelperProfileRepository {
  final _profiles = StreamController<List<HelperProfile>>.broadcast();

  /// Whose one profile was asked for, when a helper asks for her own.
  final profileAskedFor = <String>[];
  var allAskedFor = 0;

  void emitProfiles(List<HelperProfile> profiles) => _profiles.add(profiles);
  void failProfilesWith(Object error) => _profiles.addError(error);

  Future<void> close() => _profiles.close();

  @override
  Stream<List<HelperProfile>> watchProfiles(String householdId) {
    allAskedFor++;
    return _profiles.stream;
  }

  @override
  Stream<HelperProfile?> watchProfile(String householdId, String memberId) {
    profileAskedFor.add(memberId);
    return _profiles.stream.map(
      (profiles) =>
          profiles.where((profile) => profile.id == memberId).firstOrNull,
    );
  }

  @override
  Future<void> setLanguage({
    required String householdId,
    required String memberId,
    required HelperLanguage language,
    required String by,
  }) => record('setLanguage', {
    'memberId': memberId,
    'language': language,
    'by': by,
  });
}

/// The cache and the Function: the cache holds [cache]; the Function
/// answers `[code] text` unless told to fail, and counts what it was asked.
final class FakeTranslationRepository implements TranslationRepository {
  final cache = <String, String>{};
  final asked = <List<String>>[];
  AppFailure? failTranslateWith;

  @override
  Future<Map<String, String>> cached({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async => {
    for (final text in texts)
      if (cache[text] case final String translated) text: translated,
  };

  @override
  Future<Map<String, String>> translate({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async {
    asked.add(texts);
    final failure = failTranslateWith;
    if (failure != null) throw failure;
    return {for (final text in texts) text: '[${language.code}] $text'};
  }
}

/// The phone's voice: says what it can do, and remembers what it spoke.
final class FakeReadAloud implements ReadAloud {
  VoiceSupport support = VoiceSupport.available;
  var refuses = false;
  final spoken = <(String, HelperLanguage)>[];
  var stops = 0;

  @override
  Future<VoiceSupport> supportFor(HelperLanguage language) async => support;

  @override
  Future<bool> speak(String text, HelperLanguage voice) async {
    spoken.add((text, voice));
    return !refuses;
  }

  @override
  Future<void> stop() async => stops++;
}
