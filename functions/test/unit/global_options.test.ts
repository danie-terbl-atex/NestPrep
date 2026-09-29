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

/** The one HTTPS function allowed past thirty seconds, and by how much. */
const LONGER_TIMEOUTS: Readonly<Record<string, number>> = { documentShare: 120 };

/** The callables allowed more than the global limits, and exactly how much. */
const LARGER: Record<string, { memoryMb: number; timeoutSeconds: number }> = {
  readSchoolLetter: { memoryMb: 512, timeoutSeconds: 60 },
};

/** A scheduled job sets its own timeout; everything else is a callable. */
function isScheduled(endpoint: Endpoint): boolean {
  return endpoint.scheduleTrigger !== undefined;
}

describe('every function — callable, trigger or schedule', () => {
  it('there are sixty-eight of them, so a new one cannot slip past these checks', () => {
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
    // (subscriptions ADR-0001). Documents V2: two callables, the HTTPS
    // function a shared link opens and the trigger that ends a shift's links
    // (documents ADR-0006). Snap a school letter: readSchoolLetter, the first
    // AI call (calendar ADR-0005). Co-parenting: eight callables that write
    // both homes' copies of a link at once (household ADR-0004). Nanny hub
    // V2: setCarerShiftOnly (nanny-hub ADR-0006). Referrals: two callables
    // (subscriptions ADR-0002); conversion by trigger: recordPaywallOpened
    // (product-analytics ADR-0002). Notifications: six — two schedules (the
    // digest and delivery), three Firestore triggers (a handover, a chore to
    // check, a reward asked for) and the test callable (notifications
    // ADR-0001 to ADR-0003), and three more triggers on the same channel: a
    // carer's photo (nanny-hub ADR-0004) and the other home's requests and
    // handover notes (household ADR-0004). A feature adds its count and its
    // line.
    expect(endpoints()).toHaveLength(68);
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
      if (name in LARGER) continue;
      expect(endpoint.availableMemoryMb, name).toBe(256);
      if (isScheduled(endpoint) || name in LONGER_TIMEOUTS) continue;
      expect(endpoint.timeoutSeconds, name).toBe(30);
    }
  });

  it('only a function that streams a file runs longer, and says how long', () => {
    // A shared link streams up to 20 MiB to a phone that may be on a slow
    // connection, which thirty seconds cannot promise (documents ADR-0006).
    for (const [name, seconds] of Object.entries(LONGER_TIMEOUTS)) {
      const endpoint = endpoints().find(([candidate]) => candidate === name)?.[1];
      expect(endpoint?.timeoutSeconds, name).toBe(seconds);
    }
  });

  it('a callable that waits on a model says so, and is still bounded', () => {
    // Reading a letter holds it in memory twice and waits seconds on Vertex,
    // so it has its own limits — named here, never the platform's default
    // (foundation ADR-0015, BE-19).
    for (const [name, limits] of Object.entries(LARGER)) {
      const endpoint = endpoints().find(([candidate]) => candidate === name)?.[1];
      expect(endpoint?.availableMemoryMb, name).toBe(limits.memoryMb);
      expect(endpoint?.timeoutSeconds, name).toBe(limits.timeoutSeconds);
    }
  });

  it('a scheduled job carries a timeout of its own, and a bounded one', () => {
    // A sweep is longer work than one person's request, so it does not share
    // the callables' thirty seconds — but it is never the platform's default
    // either (documents ADR-0005, BE-15, BE-19).
    const scheduled = endpoints().filter(([, endpoint]) => isScheduled(endpoint));
    expect(scheduled.map(([name]) => name)).toContain('sweepExpiryReminders');
    expect(scheduled.map(([name]) => name)).toContain('reconcileSubscriptions');
    expect(scheduled.map(([name]) => name)).toContain('composeMorningDigests');
    expect(scheduled.map(([name]) => name)).toContain('deliverNotifications');
    for (const [name, endpoint] of scheduled) {
      expect(endpoint.timeoutSeconds, name).toBeGreaterThanOrEqual(30);
      expect(endpoint.timeoutSeconds, name).toBeLessThanOrEqual(300);
    }
  });
});
