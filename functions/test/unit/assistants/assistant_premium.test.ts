import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { requireAccess } from '../../../src/assistants/assistant_access';
import type { AssistantPrincipal } from '../../../src/assistants/principal';
import { storeOf } from '../document_store_fake';

/**
 * Assistants are Premium (subscriptions ADR-0008): `requireAccess` refuses a
 * household without it as a tool error the assistant can pass on, after the
 * household's own switch and before anything is read or written.
 */

const NOW = new Date('2026-11-15T08:00:00Z');
const DAY = 24 * 60 * 60 * 1000;

const principal: AssistantPrincipal = {
  grantId: 'g1',
  uid: 'uid-sam',
  householdId: 'h1',
  via: 'claude',
  scopes: ['household:read'],
};

function household(extra: Record<string, Record<string, unknown>>): ReturnType<typeof storeOf> {
  return storeOf({
    'appConfig/flags': { assistants: true },
    'households/h1': {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { 'uid-sam': 'admin' },
      profiles: { 'uid-sam': 'm-sam' },
    },
    'households/h1/members/m-sam': { claimedBy: 'uid-sam' },
    ...extra,
  });
}

const premium = {
  'households/h1/entitlement/current': {
    premiumUntil: Timestamp.fromMillis(NOW.getTime() + DAY),
  },
};

function access(store: ReturnType<typeof storeOf>): Promise<unknown> {
  return requireAccess(store, principal, 'household:read', NOW);
}

describe('an assistant in a household', () => {
  it('with Premium is let through as its member', async () => {
    await expect(access(household(premium))).resolves.toMatchObject({
      memberId: 'm-sam',
      role: 'admin',
    });
  });

  it('that never had Premium is refused, in words the assistant can pass on', async () => {
    await expect(access(household({}))).rejects.toMatchObject({
      kind: 'forbidden',
      reason: 'premiumRequired',
      message: expect.stringContaining('nestprep Premium') as unknown,
    });
  });

  it('whose Premium has lapsed is refused from that moment', async () => {
    const lapsed = {
      'households/h1/entitlement/current': { premiumUntil: Timestamp.fromDate(NOW) },
    };
    await expect(access(household(lapsed))).rejects.toMatchObject({
      kind: 'forbidden',
      reason: 'premiumRequired',
    });
  });

  it('that switched assistants off hears that first', async () => {
    const off = { 'households/h1/assistantSettings/current': { allowed: false } };
    await expect(access(household(off))).rejects.toMatchObject({ reason: 'householdSwitchedOff' });
  });
});
