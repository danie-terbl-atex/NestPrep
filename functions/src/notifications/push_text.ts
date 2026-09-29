import { weekdayOf } from '../calendar_sync/zoned_time';
import type { DigestSection } from './digest_sections';
import type { DigestSectionKind } from './notification_contract';

/**
 * What a lock screen shows (notifications ADR-0001). **Counts and kinds only**:
 * never a child's name, an event's title, a food, a document's name, an
 * allergy or a medicine. A lock screen is read by whoever picks the phone up,
 * and a notification is kept by the operating system where other apps can
 * read it. The words that matter are one tap away, behind sign-in and the
 * rules, in the inbox.
 */

export interface PushText {
  readonly title: string;
  readonly body: string;
}

const WEEKDAYS = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

function counted(total: number, one: string, many: string): string {
  return total === 1 ? `1 ${one}` : `${String(total)} ${many}`;
}

const COUNT_WORDS: Record<DigestSectionKind, (total: number) => string> = {
  events: (total) => counted(total, 'event', 'events'),
  pack: (total) => counted(total, 'thing to pack', 'things to pack'),
  chores: (total) => counted(total, 'chore', 'chores'),
  documents: (total) => counted(total, 'document to renew', 'documents to renew'),
  shift: (total) => counted(total, 'shift update', 'shift updates'),
  approvals: (total) => counted(total, 'thing to check', 'things to check'),
};

export function digestPushText(today: string, sections: readonly DigestSection[]): PushText {
  return {
    title: `Your ${WEEKDAYS[weekdayOf(today)] ?? 'day'} at a glance`,
    body: sections.map((section) => COUNT_WORDS[section.kind](section.total)).join(' · '),
  };
}

export function expiryPushText(daysBefore: number, inVault: boolean): PushText {
  const whose = inVault ? 'A document in your vault' : 'One of the household’s documents';
  const when =
    daysBefore === 0 ? 'expires today, or already has' : `expires in ${String(daysBefore)} days`;
  return { title: 'A document needs renewing', body: `${whose} ${when}.` };
}

export const HANDOVER_TEXT: PushText = {
  title: 'The shift handover is ready',
  body: 'See how the shift went — every moment the carer logged.',
};

export const CHORE_CHECK_TEXT: PushText = {
  title: 'A chore is waiting for your check',
  body: 'Have a look, and the stars land.',
};

export const REWARD_ASKED_TEXT: PushText = {
  title: 'A reward was asked for',
  body: 'The stars are set aside until you hand it over.',
};

export const TEST_TEXT: PushText = {
  title: 'Notifications are on',
  body: 'This is how NestPrep will tap you on the shoulder.',
};

export const PHOTO_UPDATE_TEXT: PushText = {
  title: 'A photo from the shift',
  body: 'The carer sent a photo — open NestPrep to see it.',
};

export const COPARENT_SWAP_TEXT: PushText = {
  title: 'The other home asked to swap days',
  body: 'Nothing changes until you answer.',
};

export const COPARENT_SCHEDULE_TEXT: PushText = {
  title: 'The other home proposed a new schedule',
  body: 'Nothing changes until you answer.',
};

export const COPARENT_HANDOVER_TEXT: PushText = {
  title: 'A handover note from the other home',
  body: 'See what is coming across before the switch.',
};
