import { describe, expect, it } from 'vitest';

import * as functions from '../../src/index';
import { FUNCTIONS_REGION } from '../../src/shared/region';

/**
 * That the global options actually reached every endpoint (`BE-19`).
 *
 * This exists because they did not, for the whole life of the project until
 * 2026-09-18. `setGlobalOptions` was called at the foot of `src/index.ts`, below
 * the `export { x } from './feature'` lines — and ES modules evaluate imports
 * before any body statement, so every `onCall` had already been built by the
 * time it ran. The result was `maxInstances`, `timeoutSeconds` and `memory` all
 * `null`, which is not an error anywhere: it is simply a different default, and
 * nothing in a build, a lint or an emulator run says a word about it.
 *
 * So the assertion is on the built endpoint rather than on the source. Moving
 * the call back into `index.ts` leaves this file compiling and failing, which is
 * the point.
 */
interface Endpoint {
  region?: string[];
  scheduleTrigger?: unknown;
  maxInstances?: number | null;
  timeoutSeconds?: number | null;
  availableMemoryMb?: number | null;
}

function endpoints(): [string, Endpoint][] {
  return Object.entries(functions).map(([name, value]) => [
    name,
    (value as { __endpoint: Endpoint }).__endpoint,
  ]);
}

/** The callables allowed past thirty seconds and 256 MiB, and exactly how far. */
const LONGER_WORK: Record<string, { timeoutSeconds: number; memoryMb: number }> = {
  deleteAccount: { timeoutSeconds: 300, memoryMb: 512 },
  exportAccountData: { timeoutSeconds: 120, memoryMb: 512 },
};

/** A scheduled job sets its own timeout; everything else is a callable. */
function isScheduled(endpoint: Endpoint): boolean {
  return endpoint.scheduleTrigger !== undefined;
}

describe('every function — callable, trigger or schedule', () => {
  it('there are forty-nine of them, so a new one cannot slip past these checks', () => {
    // Guards the loops below: they would all pass vacuously on an empty export.
    // Household and documents: nine callables (`setMemberAccess` is household
    // ADR-0003's). Product analytics: recordActivity, three Firestore triggers
    // that must run in the database's region or never fire, and one schedule
    // (product-analytics ADR-0001). Kid sign-in: five callables (accounts
    // ADR-0003). Calendar sync: ten — seven callables, two HTTP and one
    // schedule (calendar ADR-0003). Documents phase 2: openVaultDocument and
    // the daily expiry sweep (documents ADR-0003, ADR-0005). Todos phase 2:
    // two Firestore triggers that write a child's stars and two callables a
    // parent settles them with (todos ADR-0003). Nanny hub: endNannyShift
    // (nanny-hub ADR-0002). Subscriptions: six — three callables, the App
    // Store's HTTP endpoint, the Play Pub/Sub trigger and the daily reconcile
    // (subscriptions ADR-0001). Account data: five — preview and delete an
    // account, export its data, the hourly export sweep and the web deletion
    // request (accounts ADR-0006). Home care V2: a Firestore trigger that puts
    // a low product on the grocery list and a callable that translates for the
    // helper (home-care ADR-0005, ADR-0006). A feature adds its count and its
    // line.
    expect(endpoints()).toHaveLength(49);
  });

  it('runs in the one region, which is the database region', () => {
    for (const [name, endpoint] of endpoints()) {
      expect(endpoint.region, name).toEqual([FUNCTIONS_REGION]);
    }
  });

  it('has a bounded instance count, which is the cost ceiling', () => {
    // The one with teeth: unset means an unbounded callable, and the kill line
    // in foundation ADR-0003 is R200 a month.
    for (const [name, endpoint] of endpoints()) {
      expect(endpoint.maxInstances, name).toBe(10);
    }
  });

  it('has an explicit timeout and memory rather than the platform default', () => {
    for (const [name, endpoint] of endpoints()) {
      if (name in LONGER_WORK) continue;
      expect(endpoint.availableMemoryMb, name).toBe(256);
      if (isScheduled(endpoint)) continue;
      expect(endpoint.timeoutSeconds, name).toBe(30);
    }
  });

  it('the two that do more than one request’s work say how much more, and it is bounded', () => {
    // Erasing an account walks every household it is in and may end one with
    // all its bytes; an export reads all of it (accounts ADR-0006, BE-19).
    for (const [name, limits] of Object.entries(LONGER_WORK)) {
      const endpoint = endpoints().find(([candidate]) => candidate === name)?.[1];
      expect(endpoint?.timeoutSeconds, name).toBe(limits.timeoutSeconds);
      expect(endpoint?.availableMemoryMb, name).toBe(limits.memoryMb);
      expect(limits.timeoutSeconds, name).toBeLessThanOrEqual(300);
    }
  });

  it('a scheduled job carries a timeout of its own, and a bounded one', () => {
    // A sweep is longer work than one person's request, so it does not share
    // the callables' thirty seconds — but it is never the platform's default
    // either (documents ADR-0005, BE-15, BE-19).
    const scheduled = endpoints().filter(([, endpoint]) => isScheduled(endpoint));
    expect(scheduled.map(([name]) => name)).toContain('sweepExpiryReminders');
    expect(scheduled.map(([name]) => name)).toContain('reconcileSubscriptions');
    for (const [name, endpoint] of scheduled) {
      expect(endpoint.timeoutSeconds, name).toBeGreaterThanOrEqual(30);
      expect(endpoint.timeoutSeconds, name).toBeLessThanOrEqual(300);
    }
  });
});
