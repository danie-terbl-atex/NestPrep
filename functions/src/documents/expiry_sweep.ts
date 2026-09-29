import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  type Query,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { householdRef } from '../household/documents';
import { DOCUMENTS } from './document_refs';
import { EXPIRY_REMINDERS, type ExpiryReminderDocument } from './expiry_reminder';
import {
  EXPIRED_GRACE_DAYS,
  addDays,
  reminderId,
  reminderStage,
  todayIn,
  type ReminderScope,
} from './expiry_schedule';
import { VAULT_DOCUMENTS } from './vault_refs';

/**
 * The daily job's body, apart from its trigger so the emulator suite can run
 * it (documents ADR-0005, BE-15): idempotent — every reminder has a fixed id
 * and is only ever created; safe to run late — it raises the current stage
 * only; bounded — pages of 200, at most 25 pages per collection group; and
 * observable — it logs what it did, and warns when it hit the cap.
 */
export const PAGE_SIZE = 200;
export const MAX_PAGES = 25;

export interface SweepResult {
  examined: number;
  created: number;
  capped: boolean;
}

/** Each household's IANA zone, read once per run. */
type Zones = Record<string, string | undefined>;

interface Group {
  readonly collection: string;
  readonly scope: ReminderScope;
  /** Path segments of a document in this group: households/h/…/id. */
  readonly depth: number;
}

const GROUPS: readonly Group[] = [
  { collection: VAULT_DOCUMENTS, scope: 'vault', depth: 6 },
  { collection: DOCUMENTS, scope: 'household', depth: 4 },
];

export async function runExpirySweep(store: Firestore, now: Date): Promise<SweepResult> {
  const result: SweepResult = { examined: 0, created: 0, capped: false };
  const zones: Zones = {};
  // UTC bounds, padded a day each side: the stage itself is decided in each
  // household's own zone, only the query window is UTC.
  const utcToday = todayIn('UTC', now);
  const low = addDays(utcToday, -(EXPIRED_GRACE_DAYS + 1));
  const high = addDays(utcToday, 91);

  for (const group of GROUPS) {
    const base = store
      .collectionGroup(group.collection)
      .where('expiresOn', '>=', low)
      .where('expiresOn', '<=', high)
      .orderBy('expiresOn')
      .limit(PAGE_SIZE);
    const capped = await sweepGroup({ store, base, group, now, zones, result });
    result.capped ||= capped;
  }

  logger.info('expiry reminders swept', { ...result });
  if (result.capped) logger.warn('expiry sweep stopped at its page cap', { maxPages: MAX_PAGES });
  return result;
}

interface GroupRun {
  readonly store: Firestore;
  readonly base: Query;
  readonly group: Group;
  readonly now: Date;
  readonly zones: Zones;
  readonly result: SweepResult;
}

/** Pages through one collection group. True when it stopped at the cap. */
async function sweepGroup(run: GroupRun): Promise<boolean> {
  let last: QueryDocumentSnapshot | undefined;
  for (let page = 0; page < MAX_PAGES; page += 1) {
    const snapshot = await (last === undefined ? run.base : run.base.startAfter(last)).get();
    if (snapshot.empty) return false;
    run.result.examined += snapshot.size;
    await rememberZones(run.store, snapshot.docs, run.zones);
    run.result.created += await raiseDue(run, snapshot.docs);
    if (snapshot.size < PAGE_SIZE) return false;
    last = snapshot.docs[snapshot.docs.length - 1];
  }
  return true;
}

function householdIdOf(document: QueryDocumentSnapshot): string | undefined {
  return document.ref.path.split('/')[1];
}

async function rememberZones(
  store: Firestore,
  documents: readonly QueryDocumentSnapshot[],
  zones: Zones,
): Promise<void> {
  const missing = [
    ...new Set(documents.map(householdIdOf).filter((id): id is string => id !== undefined)),
  ].filter((id) => zones[id] === undefined);
  if (missing.length === 0) return;
  const households = await store.getAll(...missing.map((id) => householdRef(store, id)));
  for (const household of households) {
    const zone: unknown = household.get('timeZone');
    zones[household.id] = typeof zone === 'string' ? zone : 'UTC';
  }
}

interface Due {
  readonly ref: DocumentReference;
  readonly data: ExpiryReminderDocument;
}

/** Works out what one page owes, then creates only what is not there yet. */
async function raiseDue(
  run: GroupRun,
  documents: readonly QueryDocumentSnapshot[],
): Promise<number> {
  const due = documents.flatMap((document) => dueFor(run, document));
  if (due.length === 0) return 0;
  return run.store.runTransaction(async (transaction) => {
    const existing = await transaction.getAll(...due.map((reminder) => reminder.ref));
    let created = 0;
    due.forEach((reminder, index) => {
      if (existing[index]?.exists === true) return;
      transaction.create(reminder.ref, reminder.data);
      created += 1;
    });
    return created;
  });
}

function dueFor(run: GroupRun, document: QueryDocumentSnapshot): Due[] {
  const segments = document.ref.path.split('/');
  const householdId = segments[1];
  if (
    segments.length !== run.group.depth ||
    segments[0] !== 'households' ||
    householdId === undefined
  ) {
    return [];
  }
  const expiresOn: unknown = document.get('expiresOn');
  const name: unknown = document.get('name');
  if (typeof expiresOn !== 'string') return [];

  const today = todayIn(run.zones[householdId] ?? 'UTC', run.now);
  const daysBefore = reminderStage(expiresOn, today);
  if (daysBefore === undefined) return [];

  const ownerMemberId = run.group.scope === 'vault' ? (segments[3] ?? null) : null;
  const key = {
    scope: run.group.scope,
    ownerMemberId,
    documentId: document.id,
    expiresOn,
    daysBefore,
  };
  return [
    {
      ref: householdRef(run.store, householdId).collection(EXPIRY_REMINDERS).doc(reminderId(key)),
      data: {
        ...key,
        documentName: typeof name === 'string' ? name : '',
        dueOn: today,
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
      },
    },
  ];
}
