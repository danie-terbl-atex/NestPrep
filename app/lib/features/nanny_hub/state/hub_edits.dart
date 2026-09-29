import '../data/nanny_hub_repository.dart';
import '../model/care_routine.dart';
import '../model/checklist_item.dart';
import '../model/contact_draft.dart';
import '../model/home_sheet.dart';
import '../model/nanny_limits.dart';
import '../model/photo_change.dart';
import '../model/shift_moment.dart';
import 'photo_library.dart';
import 'photo_write.dart';

/// Every change a parent — or a carer whose hub is `edit` — makes to what the
/// hub holds, each run through the controller's one action runner so a
/// refusal becomes a banner rather than an exception (`FE-09`).
///
/// Text is tidied here, visibly: what a sheet shows is what is saved, and the
/// sheet already trimmed as the person typed (`FE-10`). This is the second
/// line, for a caller that did not.
final class HubEdits {
  HubEdits({
    required NannyHubRepository nannyHubRepository,
    required this._photos,
    required this.householdId,
    required this.memberId,
    required Future<void> Function(Future<void> Function() action) runAction,
  }) : _repository = nannyHubRepository,
       _run = runAction;

  final NannyHubRepository _repository;
  final PhotoLibrary _photos;
  final String householdId;

  /// The viewer's profile, stamped on everything they write.
  final String memberId;
  final Future<void> Function(Future<void> Function() action) _run;

  AuthoredBy get _by => (householdId: householdId, memberId: memberId);

  CardWrite _card(String childId) =>
      (householdId: householdId, childId: childId, memberId: memberId);

  /// Blank is nothing, and surrounding space is not part of what was said.
  static String? tidy(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static List<String> tidyList(List<String> items, int limit) =>
      {for (final item in items) ?tidy(item)}.take(limit).toList();

  Future<void> saveRoutines(String childId, List<CareRoutine> routines) => _run(
    () => _repository.saveRoutines(
      _card(childId),
      [
        for (final routine in routines)
          if (tidy(routine.label) case final label?)
            CareRoutine(
              label: label,
              minuteOfDay: routine.minuteOfDay,
              note: tidy(routine.note),
            ),
      ].take(NannyLimits.routines).toList(),
    ),
  );

  Future<void> saveComfortItems(String childId, List<String> items) => _run(
    () => _repository.saveComfortItems(
      _card(childId),
      tidyList(items, NannyLimits.comfortItems),
    ),
  );

  Future<void> saveCareNotes(
    String childId, {
    required String? settling,
    required String? goodToKnow,
  }) => _run(
    () => _repository.saveCareNotes(
      _card(childId),
      settling: tidy(settling),
      goodToKnow: tidy(goodToKnow),
    ),
  );

  Future<void> changeCardPhoto(
    String childId,
    PhotoChange change, {
    String? current,
  }) => _run(
    () => _withPhoto(
      change,
      current: current,
      write: (photoId) => _repository.saveCardPhoto(_card(childId), photoId),
    ),
  );

  Future<void> addContact(ContactDraft draft) => _run(
    () => _repository.addContact(
      _by,
      name: draft.name.trim(),
      kind: draft.kind,
      phone: draft.phone.trim(),
      note: tidy(draft.note),
    ),
  );

  Future<void> updateContact(String contactId, ContactDraft draft) => _run(
    () => _repository.updateContact(
      householdId,
      contactId,
      name: draft.name.trim(),
      kind: draft.kind,
      phone: draft.phone.trim(),
      note: tidy(draft.note),
    ),
  );

  Future<void> removeContact(String contactId) =>
      _run(() => _repository.removeContact(householdId, contactId));

  Future<void> saveSheet(HomeSheet sheet) => _run(
    () => _repository.saveSheet(
      _by,
      HomeSheet(
        address: tidy(sheet.address),
        medicalAidScheme: tidy(sheet.medicalAidScheme),
        medicalAidPlan: tidy(sheet.medicalAidPlan),
        medicalAidNumber: tidy(sheet.medicalAidNumber),
      ),
    ),
  );

  /// Adds a place when [spotId] is null, or changes that one.
  Future<void> saveGuideSpot({
    String? spotId,
    required String title,
    String? note,
    required PhotoChange photo,
    String? currentPhotoId,
  }) => _run(
    () => _withPhoto(
      photo,
      current: currentPhotoId,
      write: (photoId) => spotId == null
          ? _repository.addGuideSpot(
              _by,
              title: title.trim(),
              note: tidy(note),
              photoId: photoId,
            )
          : _repository.updateGuideSpot(
              householdId,
              spotId,
              title: title.trim(),
              note: tidy(note),
              photoId: photoId,
            ),
    ),
  );

  /// The place, then its photo — so a failure leaves at worst a photo nothing
  /// shows, never a place showing a photo that is gone.
  Future<void> removeGuideSpot(String spotId, {String? photoId}) =>
      _run(() async {
        await _repository.removeGuideSpot(householdId, spotId);
        if (photoId != null) await _photos.discard(photoId);
      });

  Future<void> addRule(String text) =>
      _run(() => _repository.addRule(_by, text.trim()));

  Future<void> updateRule(String ruleId, String text) =>
      _run(() => _repository.updateRule(householdId, ruleId, text.trim()));

  Future<void> removeRule(String ruleId) =>
      _run(() => _repository.removeRule(householdId, ruleId));

  /// Saves a moment's list. An item typed in the sheet has no id yet and gets
  /// one here; an item that kept its id keeps its tick on an open shift.
  Future<void> saveChecklist(ShiftMoment moment, List<ChecklistItem> items) =>
      _run(
        () => _repository.saveChecklist(
          _by,
          moment,
          [
            for (final item in items)
              if (tidy(item.text) case final text?)
                ChecklistItem(
                  id: item.id.isEmpty
                      ? _repository.newItemId(householdId)
                      : item.id,
                  text: text,
                ),
          ].take(NannyLimits.checklistItems).toList(),
        ),
      );

  Future<void> _withPhoto(
    PhotoChange change, {
    required String? current,
    required Future<void> Function(String? photoId) write,
  }) => writeWithPhoto(_photos, change, current: current, write: write);
}
