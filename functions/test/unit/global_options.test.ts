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
  it('there are twenty-nine of them, so a new one cannot slip past these checks', () => {
    // Guards the loops below: they would all pass vacuously on an empty export.
    // Household and documents: nine callables (`setMemberAccess` is household
    // ADR-0003's). Product analytics: recordActivity, three Firestore triggers
    // that must run in the database's region or never fire, and one schedule
    // (product-analytics ADR-0001). Kid sign-in: five callables (accounts
    // ADR-0003). Calendar sync: ten — seven callables, two HTTP and one
    // schedule (calendar ADR-0003). A feature adds its count and its line.
    expect(endpoints()).toHaveLength(29);
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
