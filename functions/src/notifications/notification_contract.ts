/**
 * The words notifications and the app both spell (notifications ADR-0001).
 *
 * **This is a contract with the app.** `app/lib/features/notifications/model/
 * notification_vocabulary.dart` spells every list below the same way, and
 * `app/test/features/notifications/model/notification_contract_test.dart`
 * reads this file and fails if the two drift — a category renamed on one side
 * only is a switch in the settings screen that silently stops doing anything
 * (the vault lesson on contracts between two languages).
 */

/**
 * What a notification is about. `digest` is the morning summary; the others
 * are things other features ask this one to say — `photos` a carer's photo
 * mid-shift (nanny-hub ADR-0004), `coParenting` the other home asking for a
 * change or leaving a handover note (household ADR-0004). `test` is the push
 * a person sends themselves from the settings screen.
 */
export const NOTIFICATION_CATEGORIES = [
  'digest',
  'documents',
  'handover',
  'chores',
  'photos',
  'coParenting',
  'test',
] as const;
export type NotificationCategory = (typeof NOTIFICATION_CATEGORIES)[number];

/** The categories a person can switch off one by one (notifications ADR-0003). */
export const SWITCHABLE_CATEGORIES = [
  'documents',
  'handover',
  'chores',
  'photos',
  'coParenting',
] as const;
export type SwitchableCategory = (typeof SWITCHABLE_CATEGORIES)[number];

/** The sections a digest can hold, in the order it reads (notifications ADR-0002). */
export const DIGEST_SECTIONS = [
  'events',
  'pack',
  'chores',
  'documents',
  'shift',
  'approvals',
] as const;
export type DigestSectionKind = (typeof DIGEST_SECTIONS)[number];

/**
 * Where tapping a notification lands. The push carries the kind and an id,
 * never a path: the app owns its routes and turns a target into one, so a
 * route renamed in the app cannot strand a notification already sent.
 */
export const NOTIFICATION_TARGETS = [
  'inboxItem',
  'documents',
  'vault',
  'shiftSummary',
  'stars',
  'photoUpdates',
  'coParentLink',
] as const;
export type NotificationTarget = (typeof NOTIFICATION_TARGETS)[number];

/**
 * One Android channel per category a person may want to silence in the
 * phone's own settings. The app creates them; a push names one.
 */
export const ANDROID_CHANNELS: Record<NotificationCategory, string> = {
  digest: 'nestprep_digest',
  documents: 'nestprep_documents',
  handover: 'nestprep_handover',
  chores: 'nestprep_chores',
  photos: 'nestprep_photos',
  coParenting: 'nestprep_two_homes',
  test: 'nestprep_digest',
};

/**
 * The push data keys. Ids and kinds only — never a name, a title or a date
 * (notifications ADR-0001): the payload sits in the phone's notification
 * store, readable by anything that can read notifications.
 */
export const PUSH_DATA_KEYS = ['householdId', 'inboxId', 'target', 'targetId'] as const;

/** Where a push stands (notifications ADR-0001). */
export const PUSH_STATES = ['pending', 'sent', 'noDevice', 'failed'] as const;
export type PushState = (typeof PUSH_STATES)[number];

/** A digest time is a quarter hour; the job runs every fifteen minutes. */
export const DIGEST_STEP_MINUTES = 15;

/** What a member who has never chosen gets (notifications ADR-0003). */
export const DEFAULT_DIGEST_MINUTE = 6 * 60 + 30;
export const DEFAULT_QUIET_START = 21 * 60;
export const DEFAULT_QUIET_END = 6 * 60;

/** How long an inbox item is kept before Firestore's TTL removes it. */
export const INBOX_RETENTION_DAYS = 30;
