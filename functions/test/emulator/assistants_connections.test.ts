import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { bearerAuthenticator } from '../../src/assistants/auth/bearer';
import { AssistantRefusal } from '../../src/assistants/principal';
import { addProfile, household, joinAs, samsHousehold } from './account_data_fixture';
import {
  type ClientDocumentServer,
  allowLocalClientDocuments,
  claudeDocument,
  connectAs,
  eventually,
  grantsIn,
  serveClientDocument,
  tokensFor,
} from './assistants_fixture';
import { adminBucket, adminDb, callAs, clearFirestore, closeAdmin } from './emulator_harness';

/**
 * What ends a connection besides the member pressing Disconnect (assistants
 * ADR-0003, ADR-0005): leaving or being removed from the household, no longer
 * being family, deleting the account, the household ending — and what Download
 * my data says about connections. Each is checked on the grant, its tokens,
 * and on whether the token still authenticates.
 */

let claude: ClientDocumentServer;

beforeAll(async () => {
  claude = await serveClientDocument(claudeDocument());
});

afterAll(async () => {
  await claude.close();
  await closeAdmin();
});

beforeEach(async () => {
  await clearFirestore();
  await allowLocalClientDocuments(true);
});

async function stillWorks(access: string): Promise<boolean> {
  try {
    await bearerAuthenticator(adminDb())(`Bearer ${access}`, new Date());
    return true;
  } catch (error) {
    if (error instanceof AssistantRefusal) return false;
    throw error;
  }
}

async function grantOf(householdId: string, uid: string): Promise<string | null> {
  const grants = await grantsIn(householdId);
  return grants.docs.find((doc) => doc.get('uid') === uid)?.id ?? null;
}

async function familyOfTwo(): Promise<{
  h: Awaited<ReturnType<typeof samsHousehold>>;
  pat: Awaited<ReturnType<typeof joinAs>>;
  patMemberId: string;
}> {
  const h = await samsHousehold();
  const patMemberId = await addProfile(h.householdId, 'Pat', 'parent');
  const pat = await joinAs(h.sam, h.householdId, patMemberId);
  return { h, pat, patMemberId };
}

describe('the households trigger disconnects a member who stops being one', () => {
  it('when an admin removes them', async () => {
    const { h, pat, patMemberId } = await familyOfTwo();
    const sams = await connectAs(claude.clientId, h.sam, h.householdId);
    const pats = await connectAs(claude.clientId, pat, h.householdId);
    const patGrant = await grantOf(h.householdId, pat.uid);

    await callAs(h.sam, 'removeMember', { householdId: h.householdId, memberId: patMemberId });

    await eventually(async () => (await grantOf(h.householdId, pat.uid)) === null, 'the prune');
    expect(await tokensFor(patGrant ?? '')).toBe(0);
    expect(await stillWorks(pats.access)).toBe(false);
    expect(await stillWorks(sams.access)).toBe(true);
  });

  it('when they leave', async () => {
    const { h, pat } = await familyOfTwo();
    await connectAs(claude.clientId, pat, h.householdId);
    await callAs(pat, 'leaveHousehold', { householdId: h.householdId });
    await eventually(async () => (await grantOf(h.householdId, pat.uid)) === null, 'the prune');
  });

  it('when they are made a helper', async () => {
    const { h, pat, patMemberId } = await familyOfTwo();
    const pats = await connectAs(claude.clientId, pat, h.householdId);
    await callAs(h.sam, 'setMemberRole', {
      householdId: h.householdId,
      memberId: patMemberId,
      role: 'helper',
    });
    await eventually(async () => (await grantOf(h.householdId, pat.uid)) === null, 'the prune');
    expect(await stillWorks(pats.access)).toBe(false);
  });

  it('and leaves a household change that touches no family role alone', async () => {
    const { h, pat } = await familyOfTwo();
    await connectAs(claude.clientId, pat, h.householdId);
    await household(h.householdId).update({ name: 'The Parker-Smiths' });
    await new Promise((resolve) => setTimeout(resolve, 1500));
    expect(await grantOf(h.householdId, pat.uid)).not.toBeNull();
  });
});

describe('erasing an account takes its connections with it', () => {
  it('in a household that goes on, the person’s grants and tokens go and the others stay', async () => {
    const { h, pat } = await familyOfTwo();
    const sams = await connectAs(claude.clientId, h.sam, h.householdId);
    const pats = await connectAs(claude.clientId, pat, h.householdId);
    const patGrant = await grantOf(h.householdId, pat.uid);

    await callAs(pat, 'deleteAccount', { confirmation: 'DELETE', endingHouseholdIds: [] });

    expect(await grantOf(h.householdId, pat.uid)).toBeNull();
    expect(await tokensFor(patGrant ?? '')).toBe(0);
    expect(await stillWorks(pats.access)).toBe(false);
    expect(await stillWorks(sams.access)).toBe(true);
  });

  it('and what assistants did as that person goes too, while the others’ lines stay', async () => {
    const { h, pat, patMemberId } = await familyOfTwo();
    const activity = household(h.householdId).collection('assistantActivity');
    for (const [id, memberId] of [
      ['pat-1', patMemberId],
      ['pat-2', patMemberId],
      ['sam-1', h.samMemberId],
    ] as const) {
      await activity.doc(id).set({
        grantId: `g-${id}`,
        memberId,
        via: 'claude',
        tool: 'add_grocery_items',
        target: { kind: 'groceryItem', id: `i-${id}` },
        at: Timestamp.now(),
        expiresAt: Timestamp.now(),
      });
    }

    await callAs(pat, 'deleteAccount', { confirmation: 'DELETE', endingHouseholdIds: [] });

    expect((await activity.get()).docs.map((doc) => doc.id)).toEqual(['sam-1']);
  });
});

describe('a household that ends takes every connection, activity line, switch and token', () => {
  async function expectAllGone(householdId: string, access: string): Promise<void> {
    for (const name of ['assistantConnections', 'assistantActivity', 'assistantSettings']) {
      expect((await household(householdId).collection(name).get()).size, name).toBe(0);
    }
    for (const name of ['assistantTokens', 'assistantCodes']) {
      const left = await adminDb().collection(name).where('householdId', '==', householdId).get();
      expect(left.size, name).toBe(0);
    }
    expect(await stillWorks(access)).toBe(false);
  }

  async function givenAConnectedHousehold(): Promise<{
    h: Awaited<ReturnType<typeof samsHousehold>>;
    access: string;
  }> {
    const h = await samsHousehold();
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    await household(h.householdId)
      .collection('assistantSettings')
      .doc('current')
      .set({ allowed: true, updatedBy: h.samMemberId, updatedAt: Timestamp.now() });
    await household(h.householdId)
      .collection('assistantActivity')
      .doc('a1')
      .set({
        grantId: 'g',
        memberId: h.samMemberId,
        via: 'claude',
        tool: 'add_grocery_items',
        target: { kind: 'groceryItem', id: 'i1' },
        at: Timestamp.now(),
        expiresAt: Timestamp.now(),
      });
    return { h, access: tokens.access };
  }

  it('when its last adult closes it', async () => {
    const { h, access } = await givenAConnectedHousehold();
    await callAs(h.sam, 'closeHousehold', { householdId: h.householdId, confirmation: 'CLOSE' });
    await expectAllGone(h.householdId, access);
  });

  it('when its last adult deletes their account', async () => {
    const { h, access } = await givenAConnectedHousehold();
    await callAs(h.sam, 'deleteAccount', {
      confirmation: 'DELETE',
      endingHouseholdIds: [h.householdId],
    });
    await expectAllGone(h.householdId, access);
  });
});

describe('Download my data lists the assistants a person connected', () => {
  it('with the assistant, what it may do, when, and what it did — and no token', async () => {
    const { h, pat } = await familyOfTwo();
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId, {
      scope: 'calendar:read calendar:write',
    });
    await connectAs(claude.clientId, pat, h.householdId);
    const grantId = (await grantOf(h.householdId, h.sam.uid)) ?? '';
    await bearerAuthenticator(adminDb())(`Bearer ${tokens.access}`, new Date());
    const activity = household(h.householdId).collection('assistantActivity');
    for (const [id, minutesAgo] of [
      ['older', 30],
      ['newer', 5],
    ] as const) {
      await activity.doc(id).set({
        grantId,
        memberId: h.samMemberId,
        via: 'claude',
        tool: id === 'newer' ? 'create_event' : 'list_events',
        target: { kind: 'event', id: `e-${id}` },
        at: Timestamp.fromMillis(Date.now() - minutesAgo * 60_000),
        expiresAt: Timestamp.now(),
      });
    }

    const result = await callAs<{ path: string }>(h.sam, 'exportAccountData', null);
    const [bytes] = await adminBucket().file(result.path).download();
    const text = bytes.toString('utf8');
    const body = JSON.parse(text) as {
      households: { connectedAssistants: Record<string, unknown>[] }[];
    };
    const connected = body.households[0]?.connectedAssistants ?? [];
    expect(connected).toHaveLength(1);
    expect(connected[0]).toMatchObject({
      assistant: 'Claude',
      via: 'claude',
      scopes: ['calendar:read', 'calendar:write'],
      consentVersion: 1,
    });
    expect(typeof connected[0]?.['connectedAt']).toBe('string');
    expect(typeof connected[0]?.['lastUsedAt']).toBe('string');
    const lines = connected[0]?.['recentActivity'] as { tool: string }[];
    expect(lines.map((line) => line.tool)).toEqual(['create_event', 'list_events']);
    expect(text).not.toContain('npa_');
    expect(text).not.toContain('npr_');
  });
});
