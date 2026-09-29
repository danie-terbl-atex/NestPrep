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

describe('every function — callable, trigger or schedule', () => {
  it('there are eighteen of them, so a new one cannot slip past these checks', () => {
    // Guards the loops below: they would all pass vacuously on an empty export.
    // Fourteen callables (eight household and documents, recordActivity, and
    // five kid sign-in calls — accounts ADR-0003), three Firestore triggers and
    // one schedule; the triggers must run in the database's region or they
    // never fire (product-analytics ADR-0001).
    expect(endpoints()).toHaveLength(18);
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
      expect(endpoint.timeoutSeconds, name).toBe(30);
      expect(endpoint.availableMemoryMb, name).toBe(256);
    }
  });
});
