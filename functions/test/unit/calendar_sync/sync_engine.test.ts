import { beforeEach, describe, expect, it } from 'vitest';

import {
  MAX_OCCURRENCES_PER_CONNECTION,
  syncConnection,
  type SyncDeps,
} from '../../../src/calendar_sync/sync_engine';
import { FakeSource, MemorySyncStore, sourcesOf, timed } from './memory_sync_store';

/**
 * One sync of one connection (calendar ADR-0003, BE-15): idempotent, writes
 * only what changed, and leaves every failure on the connection as a status.
 */
let store: MemorySyncStore;
let source: FakeSource;
let deps: SyncDeps;

beforeEach(() => {
  store = new MemorySyncStore();
  source = new FakeSource();
  deps = { store, sources: sourcesOf(source), now: (): Date => new Date('2026-09-29T10:00:00Z') };
  source.outcome = {
    kind: 'ok',
    occurrences: [
      timed('a', '2026-10-01T14:00:00Z', '2026-10-01T15:00:00Z'),
      timed('b', '2026-10-08T14:00:00Z', '2026-10-08T15:00:00Z'),
    ],
    refreshedCredential: null,
  };
});

describe('a sync', () => {
  it('writes every occurrence on the household clock, filed under the connection', async () => {
    const result = await syncConnection(deps, 'h1', 'c1');
    expect(result).toEqual({ status: 'connected', eventCount: 2, written: 2, deleted: 0 });
    expect(store.stored[0]).toMatchObject({
      connectionId: 'c1',
      provider: 'google',
      memberId: 'm-sam',
      title: 'Swimming',
      date: '2026-10-01',
      startMinute: 16 * 60,
      endMinute: 17 * 60,
    });
    expect(store.outcomes).toEqual([{ status: 'connected', eventCount: 2 }]);
  });

  it('run again with nothing changed writes nothing', async () => {
    await syncConnection(deps, 'h1', 'c1');
    const again = await syncConnection(deps, 'h1', 'c1');
    expect(again).toMatchObject({ written: 0, deleted: 0 });
    expect(store.writes).toBe(2);
  });

  it('rewrites a changed occurrence and deletes one that has gone', async () => {
    await syncConnection(deps, 'h1', 'c1');
    source.outcome = {
      kind: 'ok',
      occurrences: [timed('a', '2026-10-01T15:00:00Z', '2026-10-01T16:00:00Z', 'Swimming gala')],
      refreshedCredential: null,
    };
    const result = await syncConnection(deps, 'h1', 'c1');
    expect(result).toMatchObject({ eventCount: 1, written: 1, deleted: 1 });
    expect(store.stored.map((event) => event.title)).toEqual(['Swimming gala']);
  });

  it('keeps a refresh token the provider rotated', async () => {
    source.outcome = { kind: 'ok', occurrences: [], refreshedCredential: 'refresh-2' };
    await syncConnection(deps, 'h1', 'c1');
    expect(store.credential).toBe('refresh-2');
  });

  it('stores one document for an occurrence the provider sent twice', async () => {
    const twice = timed('a', '2026-10-01T14:00:00Z', '2026-10-01T15:00:00Z');
    source.outcome = { kind: 'ok', occurrences: [twice, twice], refreshedCredential: null };
    expect(await syncConnection(deps, 'h1', 'c1')).toMatchObject({ eventCount: 1 });
  });

  it('stops at the cap rather than filling the household with one calendar', async () => {
    source.outcome = {
      kind: 'ok',
      occurrences: Array.from({ length: MAX_OCCURRENCES_PER_CONNECTION + 5 }, (_, i) =>
        timed(`e${String(i)}`, '2026-10-01T14:00:00Z', '2026-10-01T15:00:00Z'),
      ),
      refreshedCredential: null,
    };
    expect(await syncConnection(deps, 'h1', 'c1')).toMatchObject({
      eventCount: MAX_OCCURRENCES_PER_CONNECTION,
    });
  });
});

describe('a sync that cannot happen', () => {
  for (const kind of ['revoked', 'unreachable', 'notACalendar', 'notConfigured'] as const) {
    it(`leaves the connection ${kind} and the imported events as they were`, async () => {
      await syncConnection(deps, 'h1', 'c1');
      source.outcome = { kind };
      const result = await syncConnection(deps, 'h1', 'c1');
      expect(result?.status).toBe(kind);
      expect(store.outcomes.at(-1)).toEqual({ status: kind, eventCount: null });
      expect(store.stored).toHaveLength(2);
    });
  }

  it('says not set up when the provider has no client configured', async () => {
    deps = { ...deps, sources: sourcesOf(null) };
    expect((await syncConnection(deps, 'h1', 'c1'))?.status).toBe('notConfigured');
  });

  it('says revoked when the credential has gone', async () => {
    store.credential = null;
    expect((await syncConnection(deps, 'h1', 'c1'))?.status).toBe('revoked');
    expect(source.seenCredentials).toEqual([]);
  });

  it('is nothing at all when the connection has been removed', async () => {
    store.connection = null;
    expect(await syncConnection(deps, 'h1', 'c1')).toBeNull();
    expect(store.outcomes).toEqual([]);
  });

  it('reads a household zone this runtime does not know as UTC, rather than failing', async () => {
    store.zone = 'Mars/Olympus_Mons';
    await syncConnection(deps, 'h1', 'c1');
    expect(store.stored[0]?.startMinute).toBe(14 * 60);
  });
});
