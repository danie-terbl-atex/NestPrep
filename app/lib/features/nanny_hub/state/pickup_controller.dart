import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/nanny_hub_repository.dart';
import '../data/pickup_repository.dart';
import '../model/nanny_limits.dart';
import '../model/nanny_pickups.dart';
import '../model/photo_change.dart';
import '../model/pickup_change.dart';
import '../model/pickup_drafts.dart';
import '../model/pickup_person.dart';
import '../model/pickup_tidy.dart';
import '../model/school_run.dart';
import 'photo_library.dart';
import 'photo_write.dart';

/// Who may collect the children and the school-run week (nanny-hub
/// ADR-0005), on the hub's shell so the pickups screen and the door check
/// share one set of listeners.
///
/// Everybody who reads the hub reads this; only family changes it — the rules
/// say so, and [canEdit] mirrors them so nobody is offered a refused button
/// (`FE-04`). Each change runs through the one action runner, so a refusal is
/// a banner and never an exception (`FE-09`).
final class PickupController extends ChangeNotifier with ActionFailureHolder {
  PickupController({
    required PickupRepository pickupRepository,
    required this.photos,
    required this.householdId,
    required this.memberId,
    required this.canEdit,
    required this.today,
  }) : _repository = pickupRepository {
    _start();
  }

  final PickupRepository _repository;
  final PhotoLibrary photos;
  final String householdId;

  /// The viewer's profile, stamped on what they write.
  final String memberId;

  /// Family alone decides who may take a child.
  final bool canEdit;

  /// The household's today when the hub opened — where "upcoming" starts.
  final CalendarDate today;

  final _subscriptions = <StreamSubscription<Object?>>[];
  List<PickupPerson>? _people;
  List<SchoolRun>? _runs;
  List<PickupChange>? _changes;
  AsyncState<NannyPickups> _pickups = const AsyncLoading();
  var _isSaving = false;

  AsyncState<NannyPickups> get pickups => _pickups;

  /// A change is on its way — the sheets' save waits (`FE-10`).
  bool get isSaving => _isSaving;

  AuthoredBy get _by => (householdId: householdId, memberId: memberId);

  Future<void> retry() async {
    await _stop();
    _pickups = const AsyncLoading();
    notifyListeners();
    _start();
  }

  /// Adds a person when [personId] is null, or changes that one — the photo
  /// stored before the record that points at it (nanny-hub ADR-0003).
  Future<void> savePerson(
    PickupPersonDraft draft, {
    String? personId,
    required PhotoChange photo,
    String? currentPhotoId,
  }) => _saving(
    () => writeWithPhoto(
      photos,
      photo,
      current: currentPhotoId,
      write: (photoId) => personId == null
          ? _repository.addPerson(_by, tidyPerson(draft), photoId: photoId)
          : _repository.updatePerson(
              householdId,
              personId,
              tidyPerson(draft),
              photoId: photoId,
            ),
    ),
  );

  /// The person, then their photo — a failure leaves at worst a photo nothing
  /// shows.
  Future<void> removePerson(PickupPerson person) => _saving(() async {
    await _repository.removePerson(householdId, person.id);
    final photoId = person.photoId;
    if (photoId != null) await photos.discard(photoId);
  });

  Future<void> saveRun(SchoolRunDraft draft) => _saving(
    () => _repository.saveRun(_by, (
      childId: draft.childId,
      weekday: draft.weekday,
      collector: draft.collector,
      atMinute: draft.atMinute,
      place: tidyText(draft.place, NannyLimits.schoolRunPlace),
    )),
  );

  Future<void> removeRun(String childId, int weekday) => _saving(
    () => _repository.removeRun(householdId, SchoolRun.idFor(childId, weekday)),
  );

  Future<void> saveChange(PickupChangeDraft draft) => _saving(
    () => _repository.saveChange(_by, (
      childId: draft.childId,
      date: draft.date,
      collector: draft.collector,
      atMinute: draft.atMinute,
      note: tidyText(draft.note, NannyLimits.pickupChangeNote),
    )),
  );

  Future<void> removeChange(PickupChange change) =>
      _saving(() => _repository.removeChange(householdId, change.id));

  Future<void> _saving(Future<void> Function() save) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    await runAction(save);
    _isSaving = false;
    notifyListeners();
  }

  void _start() {
    _listen(_repository.watchPeople(householdId), (value) {
      _people = value;
      photos.ensure([for (final person in value) person.photoId]);
    });
    _listen(_repository.watchRuns(householdId), (value) => _runs = value);
    _listen(
      _repository.watchChanges(householdId, from: today),
      (value) => _changes = value,
    );
  }

  void _listen<T>(Stream<T> stream, void Function(T value) keep) {
    _subscriptions.add(
      stream.listen((value) {
        keep(value);
        _publish();
      }, onError: _fail),
    );
  }

  void _publish() {
    final (people, runs, changes) = (_people, _runs, _changes);
    if (people == null || runs == null || changes == null) return;
    _pickups = AsyncData(
      NannyPickups(people: people, runs: runs, changes: changes),
    );
    notifyListeners();
  }

  void _fail(Object error) {
    _pickups = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  Future<void> _stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _people = null;
    _runs = null;
    _changes = null;
  }

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }
}
