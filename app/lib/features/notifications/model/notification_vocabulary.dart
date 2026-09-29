/// The words notifications and the Functions both spell (notifications
/// ADR-0001).
///
/// **A contract with the server.** `functions/src/notifications/
/// notification_contract.ts` holds the same lists, and
/// `test/features/notifications/model/notification_contract_test.dart` reads
/// that file and fails if the two drift — a category renamed on one side only
/// is a switch in the settings screen that silently stops doing anything.
library;

/// What a notification is about. A value a newer server wrote reads as
/// `digest` — shown plainly, never a crash (`BE-10`).
enum NotificationCategory {
  digest,
  documents,
  handover,
  chores,

  /// A carer's photo mid-shift (nanny-hub ADR-0004).
  photos,

  /// The other home asking for a change, or leaving a handover note
  /// (household ADR-0004).
  coParenting,
  test;

  static NotificationCategory fromName(String name) =>
      values.where((value) => value.name == name).firstOrNull ?? digest;
}

/// The categories a person switches off one by one (notifications ADR-0003).
enum SwitchableCategory { documents, handover, chores, photos, coParenting }

/// The sections a digest can hold, in the order it reads (ADR-0002).
enum DigestSectionKind {
  events,
  pack,
  chores,
  documents,
  shift,
  approvals;

  /// Null for a section a newer server wrote that this build cannot title.
  static DigestSectionKind? fromName(String name) =>
      values.where((value) => value.name == name).firstOrNull;
}

/// Where tapping a notification lands. The push carries this and an id, never
/// a path — the app owns its routes (ADR-0001).
enum NotificationTarget {
  inboxItem,
  documents,
  vault,
  shiftSummary,
  stars,

  /// A shift's photo feed; the id is the shift (nanny-hub ADR-0004).
  photoUpdates,

  /// One co-parent link; the id is the link (household ADR-0004).
  coParentLink;

  /// Unknown targets open the inbox, which always holds the notification.
  static NotificationTarget fromName(String name) =>
      values.where((value) => value.name == name).firstOrNull ?? inboxItem;
}

/// One Android channel per category a person may want to silence in the
/// phone's own settings. `MainActivity.kt` creates them; a push names one.
enum AndroidChannel {
  digest('nestprep_digest'),
  documents('nestprep_documents'),
  handover('nestprep_handover'),
  chores('nestprep_chores'),
  photos('nestprep_photos'),
  twoHomes('nestprep_two_homes');

  const AndroidChannel(this.id);

  final String id;
}

/// The keys a push's data carries — ids and kinds, never a name.
abstract final class PushDataKeys {
  static const householdId = 'householdId';
  static const inboxId = 'inboxId';
  static const target = 'target';
  static const targetId = 'targetId';

  static const all = [householdId, inboxId, target, targetId];
}

/// A digest time is a quarter hour; the job runs every fifteen minutes.
abstract final class DigestTimes {
  static const stepMinutes = 15;
  static const defaultMinute = 6 * 60 + 30;
  static const quietStart = 21 * 60;
  static const quietEnd = 6 * 60;
}
