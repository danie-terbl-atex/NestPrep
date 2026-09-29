import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { HOUSEHOLDS } from '../household/documents';

/**
 * Where calendar sync keeps what it keeps, and the shape of each document
 * (calendar ADR-0003).
 *
 * Three collections a household may read and nobody but a Function writes, and
 * three no client may touch at all. The second three are the credentials: a
 * refresh token or a calendar link, the OAuth state of a connection in flight,
 * and the map from a feed token's hash to its household.
 */
export const CALENDAR_CONNECTIONS = 'calendarConnections';
export const SYNCED_EVENTS = 'syncedEvents';
export const CALENDAR_FEED = 'calendarFeed';
export const CURRENT_FEED = 'current';
export const CONNECTION_SECRETS = 'calendarConnectionSecrets';
export const OAUTH_STATES = 'calendarOAuthStates';
export const FEED_TOKENS = 'calendarFeeds';

/** Where an imported calendar comes from. `ics` is a pasted calendar link. */
export const PROVIDERS = ['google', 'microsoft', 'ics'] as const;
export type Provider = (typeof PROVIDERS)[number];

export const OAUTH_PROVIDERS = ['google', 'microsoft'] as const;
export type OAuthProvider = (typeof OAUTH_PROVIDERS)[number];

/**
 * How a connection's last sync went. A **contract with the client**, which
 * turns each into a sentence (FE-09); `app/test/.../connection_status_contract_test.dart`
 * reads this list.
 */
export const CONNECTION_STATUSES = [
  'connected',
  'revoked',
  'unreachable',
  'notACalendar',
  'notConfigured',
] as const;
export type ConnectionStatus = (typeof CONNECTION_STATUSES)[number];

/** What a household may see about a connection. */
export interface ConnectionDocument {
  readonly provider: Provider;
  readonly memberId: string;
  readonly ownerUid: string;
  /** The account's address, or a calendar link's host. */
  readonly accountLabel: string;
  readonly status: ConnectionStatus;
  readonly eventCount: number;
}

/** What only a Function may see. */
export interface SecretDocument {
  readonly householdId: string;
  readonly provider: Provider;
  /** A refresh token for Google or Microsoft, or the https calendar link. */
  readonly credential: string;
}

/** One imported occurrence, on the household's wall clock (calendar ADR-0002). */
export interface SyncedEventDocument {
  readonly connectionId: string;
  readonly provider: Provider;
  readonly memberId: string;
  /** The connection's account label — the host of a calendar link. */
  readonly sourceLabel: string;
  readonly title: string;
  /** `YYYY-MM-DD` where the household lives. */
  readonly date: string;
  /** The last day it covers, inclusive; the same as `date` unless it spans days. */
  readonly endDate: string;
  /** Minutes since midnight; null on both means all day. */
  readonly startMinute: number | null;
  readonly endMinute: number | null;
  /** A hash of everything above, so a sync rewrites only what changed. */
  readonly fingerprint: string;
}

function household(store: Firestore, householdId: string): DocumentReference {
  return store.collection(HOUSEHOLDS).doc(householdId);
}

export function connectionRef(
  store: Firestore,
  householdId: string,
  connectionId: string,
): DocumentReference {
  return household(store, householdId).collection(CALENDAR_CONNECTIONS).doc(connectionId);
}

export function syncedEventRef(
  store: Firestore,
  householdId: string,
  syncedEventId: string,
): DocumentReference {
  return household(store, householdId).collection(SYNCED_EVENTS).doc(syncedEventId);
}

export function feedRef(store: Firestore, householdId: string): DocumentReference {
  return household(store, householdId).collection(CALENDAR_FEED).doc(CURRENT_FEED);
}

export function secretRef(store: Firestore, connectionId: string): DocumentReference {
  return store.collection(CONNECTION_SECRETS).doc(connectionId);
}

export function oauthStateRef(store: Firestore, state: string): DocumentReference {
  return store.collection(OAUTH_STATES).doc(state);
}

export function feedTokenRef(store: Firestore, tokenHash: string): DocumentReference {
  return store.collection(FEED_TOKENS).doc(tokenHash);
}
