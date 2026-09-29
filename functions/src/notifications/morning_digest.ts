import type { Firestore, QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { composeDigest } from './digest_composer';
import { loadHouseholdDay } from './digest_loader';
import { candidateSlots, dueDigestDay, knownZones } from './digest_schedule';
import { loadRoster, recipientIn, type HouseholdRoster } from './household_roster';
import { deliverDrafts } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import { NOTIFICATION_SETTINGS, inboxRef } from './notification_refs';
import { readSettings } from './notification_settings';
import type { PushSender } from './push_sender';
import type { Recipient } from './recipients';

/**
 * The morning digest's run, apart from its schedule so the emulator suite can
 * drive it with a fixed clock (notifications ADR-0002, BE-15).
 *
 * 1. Asks for the people whose digest slot is "now" in *some* zone — one
 *    collection-group query per thirty slots, each capped.
 * 2. Keeps those for whom it is now in *their household's* zone.
 * 3. Drops anybody whose digest for that local day already exists — the id is
 *    the person and the day, so a second run, a late run or a repeated hour
 *    at a clock change sends nothing twice.
 * 4. Reads each household's day once, composes one digest per person from
 *    what they may see, and delivers it through the inbox.
 */
export const SLOTS_PER_QUERY = 30;
export const SETTINGS_PER_QUERY = 300;

export interface DigestRunReport {
  candidates: number;
  due: number;
  composed: number;
  quiet: number;
  created: number;
  capped: boolean;
}

export interface DigestRun {
  readonly store: Firestore;
  readonly sender: PushSender;
  readonly now: Date;
  /** The zones whose "now" is considered; every zone the runtime knows by default. */
  readonly zones?: readonly string[];
}

function chunks<T>(values: readonly T[], size: number): T[][] {
  const out: T[][] = [];
  for (let start = 0; start < values.length; start += size)
    out.push(values.slice(start, start + size));
  return out;
}

async function candidatesFor(
  run: DigestRun,
  report: DigestRunReport,
): Promise<QueryDocumentSnapshot[]> {
  const slots = candidateSlots(run.now, run.zones ?? knownZones());
  const pages = await Promise.all(
    chunks(slots, SLOTS_PER_QUERY).map((group) =>
      run.store
        .collectionGroup(NOTIFICATION_SETTINGS)
        .where('digestSlot', 'in', group)
        .limit(SETTINGS_PER_QUERY)
        .get(),
    ),
  );
  report.capped = pages.some((page) => page.size >= SETTINGS_PER_QUERY);
  return pages.flatMap((page) => page.docs);
}

function byHousehold(
  documents: readonly QueryDocumentSnapshot[],
): Record<string, QueryDocumentSnapshot[]> {
  const grouped: Record<string, QueryDocumentSnapshot[]> = {};
  for (const document of documents) {
    const segments = document.ref.path.split('/');
    const householdId = segments[1];
    if (segments.length !== 4 || segments[0] !== 'households' || householdId === undefined)
      continue;
    (grouped[householdId] ??= []).push(document);
  }
  return grouped;
}

export function digestId(memberId: string, localDate: string): string {
  return `digest_${memberId}_${localDate}`;
}

export async function runMorningDigest(run: DigestRun): Promise<DigestRunReport> {
  const report: DigestRunReport = {
    candidates: 0,
    due: 0,
    composed: 0,
    quiet: 0,
    created: 0,
    capped: false,
  };
  const candidates = await candidatesFor(run, report);
  report.candidates = candidates.length;
  for (const [householdId, settings] of Object.entries(byHousehold(candidates))) {
    const roster = await loadRoster(run.store, householdId);
    if (roster !== null) await digestHousehold(run, roster, settings, report);
  }
  logger.info('morning digests run', { ...report });
  if (report.capped)
    logger.warn('morning digest stopped at its query cap', { cap: SETTINGS_PER_QUERY });
  return report;
}

async function digestHousehold(
  run: DigestRun,
  roster: HouseholdRoster,
  settings: readonly QueryDocumentSnapshot[],
  report: DigestRunReport,
): Promise<void> {
  const due: { recipient: Recipient; today: string }[] = settings.flatMap((document) => {
    const today = dueDigestDay(readSettings(document.data()), roster.zone, run.now);
    const recipient = recipientIn(roster, document.id);
    return today === undefined || recipient === undefined ? [] : [{ recipient, today }];
  });
  const existing = await Promise.all(
    due.map(({ recipient, today }) =>
      inboxRef(run.store, roster.householdId, digestId(recipient.memberId, today)).get(),
    ),
  );
  const fresh = due.filter((_, index) => existing[index]?.exists !== true);
  report.due += fresh.length;

  // Everybody in one household shares one clock, so one day; grouped all the
  // same, because a run straddling midnight is not impossible.
  const days = [...new Set(fresh.map(({ today }) => today))];
  for (const today of days) {
    const people = fresh.filter((entry) => entry.today === today).map(({ recipient }) => recipient);
    const day = await loadHouseholdDay({
      store: run.store,
      roster,
      today,
      now: run.now,
      due: people,
    });
    const drafts: InboxDraft[] = people.flatMap((recipient) => {
      const digest = composeDigest(day, recipient);
      if (digest === null) {
        report.quiet += 1;
        return [];
      }
      const id = digestId(recipient.memberId, today);
      return [
        {
          id,
          memberId: recipient.memberId,
          category: 'digest',
          text: digest.push,
          detail: null,
          sections: digest.sections,
          target: { kind: 'inboxItem', id },
          source: { kind: 'digest', id: today },
          localDate: today,
        },
      ];
    });
    report.composed += drafts.length;
    const delivered = await deliverDrafts(
      {
        store: run.store,
        sender: run.sender,
        householdId: roster.householdId,
        zone: roster.zone,
        now: run.now,
      },
      drafts,
    );
    report.created += delivered.created;
  }
}
