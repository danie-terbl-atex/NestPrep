import type { HouseholdDay } from './digest_facts';
import {
  approvalsSection,
  choresSection,
  documentsSection,
  eventsSection,
  packSection,
  shiftSection,
  type DigestSection,
} from './digest_sections';
import { digestPushText, type PushText } from './push_text';
import type { Recipient } from './recipients';

/**
 * One person's morning digest (notifications ADR-0002). Pure: the same day and
 * the same person always give the same digest, so what it says is tested from
 * fixed data rather than from a schedule.
 */
export interface ComposedDigest {
  readonly push: PushText;
  readonly sections: readonly DigestSection[];
}

const BUILDERS = [
  eventsSection,
  packSection,
  choresSection,
  documentsSection,
  shiftSection,
  approvalsSection,
] as const;

/**
 * The digest, or null when there is nothing this person may see today. A day
 * with nothing on it sends nothing — decided, not accidental (ADR-0002): a
 * summary of nothing is the kind of ping that teaches people to switch the
 * whole channel off.
 */
export function composeDigest(day: HouseholdDay, recipient: Recipient): ComposedDigest | null {
  const sections = BUILDERS.flatMap((build) => {
    const section = build(day, recipient);
    return section === null ? [] : [section];
  });
  if (sections.length === 0) return null;
  return { push: digestPushText(day.today, sections), sections };
}
