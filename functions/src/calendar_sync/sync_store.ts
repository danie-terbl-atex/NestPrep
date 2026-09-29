import type { ConnectionDocument, ConnectionStatus, SyncedEventDocument } from './sync_documents';

/**
 * What a sync reads and writes, as an interface so the engine's rules are
 * tested without Firestore (BE-01, BE-14). `FirestoreSyncStore` is the one
 * implementation that runs.
 */
export interface StoredConnection extends ConnectionDocument {
  readonly id: string;
  readonly householdId: string;
}

export interface SyncChanges {
  readonly upserts: readonly { readonly id: string; readonly document: SyncedEventDocument }[];
  readonly deletes: readonly string[];
}

export interface SyncStore {
  readConnection(householdId: string, connectionId: string): Promise<StoredConnection | null>;

  /** The household's IANA zone, or null when the household is gone. */
  readHouseholdZone(householdId: string): Promise<string | null>;

  /** The refresh token or link, or null when it has gone. */
  readCredential(connectionId: string): Promise<string | null>;

  saveCredential(connectionId: string, credential: string): Promise<void>;

  /** Each synced event of the connection, by id, with the fingerprint it was written with. */
  readFingerprints(householdId: string, connectionId: string): Promise<Map<string, string>>;

  applyChanges(householdId: string, changes: SyncChanges): Promise<void>;

  recordOutcome(
    householdId: string,
    connectionId: string,
    outcome: { readonly status: ConnectionStatus; readonly eventCount: number | null },
  ): Promise<void>;
}
