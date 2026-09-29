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

/** A scheduled job sets its own timeout; everything else is a callable. */
function isScheduled(endpoint: Endpoint): boolean {
  return endpoint.scheduleTrigger !== undefined;
}

describe('every exported function', () => {
  it('there are ten of them, so a new one cannot slip past these checks', () => {
    // Guards the loops below: they would all pass vacuously on an empty export.
    expect(endpoints()).toHaveLength(10);
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
      expect(endpoint.availableMemoryMb, name).toBe(256);
      if (isScheduled(endpoint)) continue;
      expect(endpoint.timeoutSeconds, name).toBe(30);
    }
  });

  it('a scheduled job carries a timeout of its own, and a bounded one', () => {
    // A sweep is longer work than one person's request, so it does not share
    // the callables' thirty seconds — but it is never the platform's default
    // either (documents ADR-0005, BE-15, BE-19).
    const scheduled = endpoints().filter(([, endpoint]) => isScheduled(endpoint));
    expect(scheduled.map(([name]) => name)).toContain('sweepExpiryReminders');
    for (const [name, endpoint] of scheduled) {
      expect(endpoint.timeoutSeconds, name).toBeGreaterThan(30);
      expect(endpoint.timeoutSeconds, name).toBeLessThanOrEqual(300);
    }
  });
});
