import type { CalendarSource, FetchOutcome } from '../../../src/calendar_sync/calendar_source';
import {
  calendarSourcesFor,
  type CalendarSources,
} from '../../../src/calendar_sync/calendar_sources';
import type { ExternalOccurrence } from '../../../src/calendar_sync/external_occurrence';
import { IcsCalendar } from '../../../src/calendar_sync/ics_calendar';
import type {
  ConnectionStatus,
  SyncedEventDocument,
} from '../../../src/calendar_sync/sync_documents';
import type {
  StoredConnection,
  SyncChanges,
  SyncStore,
} from '../../../src/calendar_sync/sync_store';
import { ScriptedHttp, json } from './fakes';

/** The sync store in memory, counting what a sync wrote (BE-14: rules without Firestore). */
export class MemorySyncStore implements SyncStore {
  connection: StoredConnection | null = {
    id: 'c1',
    householdId: 'h1',
    provider: 'google',
    memberId: 'm-sam',
    ownerUid: 'uid-sam',
    accountLabel: 'sam@example.com',
    status: 'connected',
    eventCount: 0,
  };
  zone: string | null = 'Africa/Johannesburg';
  credential: string | null = 'refresh-1';
  readonly events: Record<string, SyncedEventDocument | undefined> = {};
  outcomes: { status: ConnectionStatus; eventCount: number | null }[] = [];
  writes = 0;
  deletes = 0;

  readConnection(): Promise<StoredConnection | null> {
    return Promise.resolve(this.connection);
  }

  readHouseholdZone(): Promise<string | null> {
    return Promise.resolve(this.zone);
  }

  readCredential(): Promise<string | null> {
    return Promise.resolve(this.credential);
  }

  saveCredential(_connectionId: string, credential: string): Promise<void> {
    this.credential = credential;
    return Promise.resolve();
  }

  readFingerprints(): Promise<Map<string, string>> {
    return Promise.resolve(
      new Map(
        Object.entries(this.events).flatMap(([id, event]) =>
          event === undefined ? [] : [[id, event.fingerprint] as const],
        ),
      ),
    );
  }

  applyChanges(_householdId: string, changes: SyncChanges): Promise<void> {
    for (const { id, document } of changes.upserts) {
      this.events[id] = document;
      this.writes++;
    }
    for (const id of changes.deletes) {
      this.events[id] = undefined;
      this.deletes++;
    }
    return Promise.resolve();
  }

  recordOutcome(
    _householdId: string,
    _connectionId: string,
    outcome: { status: ConnectionStatus; eventCount: number | null },
  ): Promise<void> {
    this.outcomes.push(outcome);
    return Promise.resolve();
  }

  get stored(): SyncedEventDocument[] {
    return Object.values(this.events).filter((event) => event !== undefined);
  }
}

/** A provider that answers with whatever the test last gave it. */
export class FakeSource implements CalendarSource {
  outcome: FetchOutcome = { kind: 'ok', occurrences: [], refreshedCredential: null };
  seenCredentials: string[] = [];
  revoked: string[] = [];

  fetchOccurrences(credential: string): Promise<FetchOutcome> {
    this.seenCredentials.push(credential);
    return Promise.resolve(this.outcome);
  }

  revoke(credential: string): Promise<void> {
    this.revoked.push(credential);
    return Promise.resolve();
  }
}

/** Every source is [source]; the OAuth side is unconfigured. */
export function sourcesOf(source: FakeSource | null): CalendarSources {
  const unused = new IcsCalendar(
    new ScriptedHttp(() => json(500, {})),
    () => Promise.resolve([]),
    false,
  );
  const base = calendarSourcesFor({}, new ScriptedHttp(() => json(500, {})), unused);
  return { ...base, source: () => source };
}

export function timed(
  id: string,
  start: string,
  end: string,
  title = 'Swimming',
): ExternalOccurrence {
  return {
    externalId: id,
    title,
    time: { kind: 'timed', start: new Date(start), end: new Date(end) },
  };
}
