import type { Firestore, QuerySnapshot } from 'firebase-admin/firestore';

import { CALENDAR_CONNECTIONS } from '../calendar_sync/sync_documents';
import { GRANTS, VAULT_DOCUMENTS, VIEWS, vaultRef } from '../documents/vault_refs';
import { type HouseholdDocument, MEMBERS, householdRef, userRef } from '../household/documents';
import { STORE_PURCHASES } from '../subscriptions/subscription_documents';
import type { AuthRecord } from './account_auth';
import { AUTHORED_LIMIT, AUTHORED_RECORDS } from './authored_records';
import { HOUSEHOLD_LIMIT } from './deletion_plan';
import { type PlainValue, isPlainRecord, plainDocument, plainValue } from './plain_value';
import { personalRefs } from './personal_refs';

/** Vault rows, grants and view-log lines listed per vault, at most (`BE-08`). */
const VAULT_LIMIT = 500;

/**
 * The shape of an export. `formatVersion` changes when a field is renamed or
 * removed, so a person comparing two exports — or the Information Regulator
 * reading one — knows which shape they hold.
 */
export const EXPORT_FORMAT_VERSION = 1;

/** A file whose bytes are in the person's vault; the export lists it rather than copying it. */
export interface ExportedFile {
  readonly householdId: string;
  readonly documentId: string;
  readonly name: string;
  readonly contentType: string;
  readonly sizeBytes: number;
}

export interface PersonalDataExport {
  readonly body: Readonly<Record<string, PlainValue>>;
  readonly files: readonly ExportedFile[];
}

/**
 * Everything NestPrep holds about one account, as one JSON document
 * (accounts ADR-0006 — POPIA's right of access): the account and what Auth
 * knows, and for each household the person's role and grant, the profile they
 * claimed with its details, medication, last position and vault, the
 * calendars they connected, and what they put into the household. Store
 * subscriptions they linked are listed without the store's purchase token.
 *
 * Bounded everywhere (`BE-08`); a list cut short says so beside it.
 */
export async function assembleExport(
  store: Firestore,
  subject: { uid: string; auth: AuthRecord | null; now: Date },
): Promise<PersonalDataExport> {
  const { uid } = subject;
  const account = await userRef(store, uid).get();
  const listed: unknown = account.get('householdIds');
  const householdIds = Array.isArray(listed)
    ? listed.filter((id): id is string => typeof id === 'string').slice(0, HOUSEHOLD_LIMIT)
    : [];

  const files: ExportedFile[] = [];
  const households: PlainValue[] = [];
  for (const householdId of householdIds) {
    const household = await exportHousehold(store, uid, householdId, files);
    if (household !== null) households.push(household);
  }

  return {
    files,
    body: {
      formatVersion: EXPORT_FORMAT_VERSION,
      generatedAt: subject.now.toISOString(),
      account: plainDocument(uid, account.data()),
      signIn: subject.auth === null ? null : plainValue({ ...subject.auth }),
      households,
      storeSubscriptions: await exportPurchases(store, uid),
      vaultFiles: files.map((file) => plainValue({ ...file })),
    },
  };
}

async function exportHousehold(
  store: Firestore,
  uid: string,
  householdId: string,
  files: ExportedFile[],
): Promise<PlainValue | null> {
  const snapshot = await householdRef(store, householdId).get();
  const household = snapshot.data() as HouseholdDocument | undefined;
  if (household === undefined || household.members[uid] === undefined) return null;

  const claimed = await householdRef(store, householdId)
    .collection(MEMBERS)
    .where('claimedBy', '==', uid)
    .limit(1)
    .get();
  const member = claimed.docs[0];
  const connections = await householdRef(store, householdId)
    .collection(CALENDAR_CONNECTIONS)
    .where('ownerUid', '==', uid)
    .limit(VAULT_LIMIT)
    .get();

  return {
    householdId,
    name: household.name,
    timeZone: household.timeZone,
    yourRole: household.members[uid],
    yourAccess: plainValue(household.access?.[uid] ?? null),
    profile: member === undefined ? null : plainDocument(member.id, member.data()),
    aboutYou: member === undefined ? [] : await exportDetails(store, householdId, member.id),
    vault: member === undefined ? null : await exportVault(store, householdId, member.id, files),
    connectedCalendars: connections.docs.map((doc) => plainDocument(doc.id, doc.data())),
    whatYouAdded: member === undefined ? {} : await exportAuthored(store, householdId, member.id),
  };
}

async function exportDetails(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<PlainValue[]> {
  const refs = personalRefs(store, householdId, memberId);
  const snapshots = await store.getAll(...refs);
  return snapshots.flatMap((doc) =>
    doc.exists ? [{ kind: doc.ref.parent.id, ...asObject(plainDocument(doc.id, doc.data())) }] : [],
  );
}

async function exportVault(
  store: Firestore,
  householdId: string,
  memberId: string,
  files: ExportedFile[],
): Promise<PlainValue> {
  const vault = vaultRef(store, householdId, memberId);
  const page = (name: string): Promise<QuerySnapshot> =>
    vault.collection(name).limit(VAULT_LIMIT).get();
  const [documents, grants, views] = await Promise.all([
    page(VAULT_DOCUMENTS),
    page(GRANTS),
    page(VIEWS),
  ]);
  for (const doc of documents.docs) {
    files.push({
      householdId,
      documentId: doc.id,
      name: stringOr(doc.get('name'), doc.id),
      contentType: stringOr(doc.get('contentType'), 'application/octet-stream'),
      sizeBytes: numberOr(doc.get('sizeBytes'), 0),
    });
  }
  const rows = (found: typeof documents): PlainValue[] =>
    found.docs.map((doc) => plainDocument(doc.id, doc.data()));
  return { documents: rows(documents), accessGranted: rows(grants), viewLog: rows(views) };
}

async function exportAuthored(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<PlainValue> {
  const sections: Record<string, PlainValue> = {};
  for (const { collection, authorField } of AUTHORED_RECORDS) {
    const page = await householdRef(store, householdId)
      .collection(collection)
      .where(authorField, '==', memberId)
      .limit(AUTHORED_LIMIT + 1)
      .get();
    if (page.empty) continue;
    sections[collection] = {
      records: page.docs.slice(0, AUTHORED_LIMIT).map((doc) => plainDocument(doc.id, doc.data())),
      cutShort: page.size > AUTHORED_LIMIT,
    };
  }
  return sections;
}

/** Linked subscriptions, without `storeRef` — the store's own purchase credential. */
async function exportPurchases(store: Firestore, uid: string): Promise<PlainValue[]> {
  const linked = await store
    .collection(STORE_PURCHASES)
    .where('linkedByUid', '==', uid)
    .limit(HOUSEHOLD_LIMIT)
    .get();
  return linked.docs.map((doc) =>
    plainValue(
      Object.fromEntries(Object.entries(doc.data()).filter(([key]) => key !== 'storeRef')),
    ),
  );
}

function asObject(value: PlainValue | null): Record<string, PlainValue> {
  return isPlainRecord(value) ? { ...value } : {};
}

function stringOr(value: unknown, fallback: string): string {
  return typeof value === 'string' && value !== '' ? value : fallback;
}

function numberOr(value: unknown, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}
