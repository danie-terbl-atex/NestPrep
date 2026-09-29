import { daysBetween, wallClockOf } from '../calendar_sync/zoned_time';
import type { DigestSectionKind } from './notification_contract';
import type { ExpiringDocument, HouseholdDay } from './digest_facts';
import { kitFor } from './kit_vocabulary';
import { canSee, type Recipient } from './recipients';

/**
 * The sections of one person's digest, each built only from what that person
 * may see (notifications ADR-0002, household ADR-0003). A helper whose grant
 * stops at cleaning gets no calendar, no lunches and no documents here, for
 * the same reason the rules would refuse them the reads.
 *
 * These words are read **inside the app**, behind the rules, never on a lock
 * screen: the push itself carries counts only (`push_text.ts`).
 */

export interface DigestItem {
  readonly text: string;
  readonly detail: string | null;
}

export interface DigestSection {
  readonly kind: DigestSectionKind;
  readonly items: readonly DigestItem[];
  /** How many things the section is about, including any not shown. */
  readonly total: number;
}

/** As many lines as one section shows before "and N more" (BE-08). */
export const SECTION_ITEM_LIMIT = 8;

export function clockText(minute: number): string {
  const hours = Math.floor(minute / 60);
  return `${String(hours).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`;
}

function nameOf(day: HouseholdDay, memberId: string): string {
  return day.names[memberId] ?? 'Someone';
}

function whoText(
  day: HouseholdDay,
  memberIds: readonly string[],
  recipient: Recipient,
  you = 'You',
): string {
  if (memberIds.length === 0) return 'Everyone';
  return memberIds.map((id) => (id === recipient.memberId ? you : nameOf(day, id))).join(', ');
}

function bounded(kind: DigestSectionKind, items: readonly DigestItem[]): DigestSection | null {
  if (items.length === 0) return null;
  const total = items.length;
  if (total <= SECTION_ITEM_LIMIT) return { kind, items, total };
  const shown = items.slice(0, SECTION_ITEM_LIMIT - 1);
  const more = total - shown.length;
  return { kind, items: [...shown, { text: `And ${String(more)} more`, detail: null }], total };
}

export function eventsSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  if (!canSee(recipient, 'calendar')) return null;
  return bounded(
    'events',
    day.events.map((event) => ({
      text: event.title,
      detail: `${event.startMinute === null ? 'All day' : clockText(event.startMinute)} · ${whoText(day, event.memberIds, recipient)}`,
    })),
  );
}

/** Lunch boxes for today, and the kit today's events call for. */
export function packSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  const lunchLevel = recipient.levels.lunch;
  const boxes = day.lunchBoxes.filter(
    (box) =>
      lunchLevel === 'view' ||
      lunchLevel === 'edit' ||
      (lunchLevel === 'own' && box.childId === recipient.memberId),
  );
  const lunchItems = boxes.map((box) => ({
    text:
      box.childId === recipient.memberId
        ? 'Your lunch box'
        : `${nameOf(day, box.childId)}’s lunch box`,
    detail: box.items.join(' · '),
  }));
  const kitItems = canSee(recipient, 'calendar')
    ? day.events.flatMap((event) => {
        const kit = kitFor(event.title);
        if (kit === null) return [];
        const when = event.startMinute === null ? '' : ` at ${clockText(event.startMinute)}`;
        return [
          {
            text: kit,
            detail: `${whoText(day, event.memberIds, recipient)} · ${event.title}${when}`,
          },
        ];
      })
    : [];
  return bounded('pack', [...lunchItems, ...kitItems]);
}

export function choresSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  const level = recipient.levels.todos;
  if (level === 'none') return null;
  const isMine = (assigneeIds: readonly string[]): boolean =>
    assigneeIds.includes(recipient.memberId);
  const visible = day.chores.filter((chore) => level !== 'own' || isMine(chore.assigneeIds));
  const ordered = [
    ...visible.filter((chore) => isMine(chore.assigneeIds)),
    ...visible.filter((chore) => !isMine(chore.assigneeIds)),
  ];
  return bounded(
    'chores',
    ordered.map((chore) => ({
      text: chore.title,
      detail:
        chore.assigneeIds.length === 0
          ? 'For anyone'
          : `For ${whoText(day, chore.assigneeIds, recipient, 'you')}`,
    })),
  );
}

export function expiryText(today: string, expiresOn: string): string {
  const days = daysBetween(today, expiresOn);
  if (days === 0) return 'Expires today';
  if (days === 1) return 'Expires tomorrow';
  if (days > 1) return `Expires in ${String(days)} days`;
  return days === -1 ? 'Expired yesterday' : `Expired ${String(-days)} days ago`;
}

/**
 * A vault document is never named outside the vault: its list opens behind the
 * phone's own lock (documents ADR-0003), and a name in the inbox would walk
 * round it.
 */
function documentItem(today: string, document: ExpiringDocument, inVault: boolean): DigestItem {
  const when = expiryText(today, document.expiresOn);
  return inVault
    ? { text: 'A document in your vault', detail: when }
    : { text: document.name, detail: when };
}

export function documentsSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  const shared = canSee(recipient, 'documents')
    ? day.documents.map((document) => documentItem(day.today, document, false))
    : [];
  // Only a person's own vault, and only a person with their own login — a
  // vault is the owner's and the family's to manage (documents ADR-0002).
  const own = recipient.hasAccount
    ? (day.vaults[recipient.memberId] ?? []).map((document) =>
        documentItem(day.today, document, true),
      )
    : [];
  return bounded('documents', [...shared, ...own]);
}

export function shiftSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  if (!canSee(recipient, 'nannyHub')) return null;
  const shifts = day.openShifts
    .filter((shift) => recipient.isFamily || shift.carerMemberId === recipient.memberId)
    .map((shift) => ({
      text:
        shift.carerMemberId === recipient.memberId
          ? 'You are on shift'
          : `${nameOf(day, shift.carerMemberId)} is on shift`,
      detail: `Since ${clockText(wallClockOf(shift.startedAt, day.zone).minute)}`,
    }));
  // The handover is written for the parents (nanny-hub ADR-0002).
  const handovers = recipient.isFamily
    ? day.handovers.map((handover) => ({
        text: `Handover from ${nameOf(day, handover.carerMemberId)}`,
        detail:
          handover.entryCount === 1
            ? '1 moment logged'
            : `${String(handover.entryCount)} moments logged`,
      }))
    : [];
  return bounded('shift', [...shifts, ...handovers]);
}

export function approvalsSection(day: HouseholdDay, recipient: Recipient): DigestSection | null {
  // Checking a chore and handing over a reward are family's (todos ADR-0003).
  if (!recipient.isFamily) return null;
  const items: DigestItem[] = [];
  if (day.choresToCheck > 0) {
    items.push({
      text:
        day.choresToCheck === 1
          ? '1 chore to check'
          : `${String(day.choresToCheck)} chores to check`,
      detail: 'Stars wait for your look',
    });
  }
  if (day.rewardsAskedFor > 0) {
    items.push({
      text:
        day.rewardsAskedFor === 1
          ? '1 reward asked for'
          : `${String(day.rewardsAskedFor)} rewards asked for`,
      detail: 'Hand it over when it happens',
    });
  }
  return bounded('approvals', items);
}
