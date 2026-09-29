import { logger } from 'firebase-functions/v2';

import type { CalendarSources } from './calendar_sources';
import { syncWindow, toSyncedEvent, type SyncedEventDraft } from './external_occurrence';
import type { ConnectionStatus } from './sync_documents';
import type { SyncStore } from './sync_store';
import { knownZoneOr } from './zoned_time';

/**
 * One sync of one connection: read the provider's window, put every
 * occurrence on the household's clock, and write only what changed
 * (calendar ADR-0003, BE-15).
 *
 * It is safe to run twice and safe to run late — a second run finds every
 * fingerprint the same and writes nothing but the outcome. Every way it can
 * fail becomes the connection's status, which the screen turns into words; it
 * throws only for what nobody could have expected.
 */
export const MAX_OCCURRENCES_PER_CONNECTION = 1_000;

export interface SyncDeps {
  readonly store: SyncStore;
  readonly sources: CalendarSources;
  readonly now: () => Date;
}

export interface SyncResult {
  readonly status: ConnectionStatus;
  readonly eventCount: number;
  readonly written: number;
  readonly deleted: number;
}

export async function syncConnection(
  deps: SyncDeps,
  householdId: string,
  connectionId: string,
): Promise<SyncResult | null> {
  const { store } = deps;
  const connection = await store.readConnection(householdId, connectionId);
  if (connection === null) return null;

  const fail = async (status: ConnectionStatus): Promise<SyncResult> => {
    await store.recordOutcome(householdId, connectionId, { status, eventCount: null });
    logger.info('calendar sync did not complete', { connectionId, status });
    return { status, eventCount: connection.eventCount, written: 0, deleted: 0 };
  };

  const source = deps.sources.source(connection.provider);
  if (source === null) return fail('notConfigured');
  const credential = await store.readCredential(connectionId);
  if (credential === null) return fail('revoked');

  const zone = knownZoneOr((await store.readHouseholdZone(householdId)) ?? undefined);
  const outcome = await source.fetchOccurrences(credential, syncWindow(zone, deps.now()));
  if (outcome.kind !== 'ok') return fail(outcome.kind);
  if (outcome.refreshedCredential !== null && outcome.refreshedCredential !== credential) {
    await store.saveCredential(connectionId, outcome.refreshedCredential);
  }

  const drafts = uniqueDrafts(
    outcome.occurrences.slice(0, MAX_OCCURRENCES_PER_CONNECTION).map((occurrence) =>
      toSyncedEvent(
        occurrence,
        {
          connectionId,
          provider: connection.provider,
          memberId: connection.memberId,
          sourceLabel: connection.accountLabel,
        },
        zone,
      ),
    ),
  );
  if (outcome.occurrences.length > MAX_OCCURRENCES_PER_CONNECTION) {
    logger.warn('calendar sync capped', { connectionId, found: outcome.occurrences.length });
  }

  const existing = await store.readFingerprints(householdId, connectionId);
  const upserts = drafts.filter((draft) => existing.get(draft.id) !== draft.document.fingerprint);
  const keep = new Set(drafts.map((draft) => draft.id));
  const deletes = [...existing.keys()].filter((id) => !keep.has(id));
  await store.applyChanges(householdId, { upserts, deletes });
  await store.recordOutcome(householdId, connectionId, {
    status: 'connected',
    eventCount: drafts.length,
  });

  logger.info('calendar synced', {
    connectionId,
    provider: connection.provider,
    events: drafts.length,
    written: upserts.length,
    deleted: deletes.length,
  });
  return {
    status: 'connected',
    eventCount: drafts.length,
    written: upserts.length,
    deleted: deletes.length,
  };
}

/** Two occurrences a provider sent twice are one document. */
function uniqueDrafts(drafts: readonly SyncedEventDraft[]): SyncedEventDraft[] {
  const seen = new Set<string>();
  return drafts.filter((draft) => {
    if (seen.has(draft.id)) return false;
    seen.add(draft.id);
    return true;
  });
}
