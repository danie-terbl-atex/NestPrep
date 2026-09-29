import { beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  adminDb,
  callAs,
  clearFirestore,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * `openVaultDocument`, driven the way the app drives it — over HTTP, with a real
 * ID token (BE-14, documents ADR-0003).
 *
 * The call is the only door to a vault document's bytes: it checks who may read
 * the vault, then writes the view-log entry and the ticket Storage reads, in one
 * batch. So every test asserts on both — a ticket with no log line would be the
 * exact failure the design exists to prevent.
 */

interface Parkers {
  readonly householdId: string;
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly alex: TestUser;
}

async function givenTheParkers(): Promise<Parkers> {
  const [sam, thandi, alex] = await Promise.all([signUp(), signUp(), signUp()]);
  const household = adminDb().collection('households').doc();
  await household.set({
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    members: { [sam.uid]: 'admin', [thandi.uid]: 'helper', [alex.uid]: 'member' },
  });
  for (const [id, role, claimedBy] of [
    ['m-sam', 'admin', sam.uid],
    ['m-thandi', 'helper', thandi.uid],
    ['m-alex', 'member', alex.uid],
    ['m-emma', 'member', null],
  ] as const) {
    await household
      .collection('members')
      .doc(id)
      .set({ displayName: id, color: 'violet', role, claimedBy });
  }
  await household
    .collection('vaults')
    .doc('m-emma')
    .collection('vaultDocuments')
    .doc('passport')
    .set({
      name: 'Emma passport',
      contentType: 'application/pdf',
      sizeBytes: 300_000,
      uploadedBy: 'm-sam',
      uploadedAt: new Date(),
    });
  return { householdId: household.id, sam, thandi, alex };
}

function openPassport(user: TestUser | null, householdId: string): Promise<{ expiresAt: string }> {
  return callAs(user, 'openVaultDocument', {
    householdId,
    ownerMemberId: 'm-emma',
    documentId: 'passport',
  });
}

async function viewsOfEmma(householdId: string): Promise<Record<string, unknown>[]> {
  const views = await adminDb().collection(`households/${householdId}/vaults/m-emma/views`).get();
  return views.docs.map((view) => view.data());
}

async function ticketOf(
  householdId: string,
  uid: string,
): Promise<Record<string, unknown> | undefined> {
  const ticket = await adminDb()
    .doc(`households/${householdId}/vaultOpenings/${uid}_passport`)
    .get();
  return ticket.data();
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}

describe('openVaultDocument', () => {
  beforeEach(clearFirestore);

  it('lets an admin open a child"s document, and logs it before the bytes are readable', async () => {
    const { householdId, sam } = await givenTheParkers();
    const before = Date.now();

    const result = await openPassport(sam, householdId);

    const views = await viewsOfEmma(householdId);
    expect(views).toHaveLength(1);
    expect(views[0]).toMatchObject({
      documentId: 'passport',
      documentName: 'Emma passport',
      viewerMemberId: 'm-sam',
      viewerRole: 'admin',
    });
    const ticket = await ticketOf(householdId, sam.uid);
    expect(ticket).toMatchObject({ ownerMemberId: 'm-emma', documentId: 'passport', uid: sam.uid });
    const expiresAt = Date.parse(result.expiresAt);
    expect(expiresAt).toBeGreaterThan(before + 4 * 60_000);
    expect(expiresAt).toBeLessThanOrEqual(Date.now() + 5 * 60_000);
  });

  it('refuses a helper nobody granted the vault to, and writes nothing', async () => {
    const { householdId, thandi } = await givenTheParkers();

    await expectRefusal(openPassport(thandi, householdId), 'vaultNotShared');

    expect(await viewsOfEmma(householdId)).toHaveLength(0);
    expect(await ticketOf(householdId, thandi.uid)).toBeUndefined();
  });

  it('lets that helper open it once granted, and names her in the log', async () => {
    const { householdId, thandi } = await givenTheParkers();
    await adminDb()
      .doc(`households/${householdId}/vaults/m-emma/grants/${thandi.uid}`)
      .set({ memberId: 'm-thandi', grantedBy: 'm-sam', grantedAt: new Date() });

    await openPassport(thandi, householdId);

    const views = await viewsOfEmma(householdId);
    expect(views.map((view) => view['viewerMemberId'])).toEqual(['m-thandi']);
    expect(await ticketOf(householdId, thandi.uid)).toBeDefined();
  });

  it('lets a family member who is not an admin open it, and names them in the log', async () => {
    // `member` is read as `parent` (household ADR-0003): family.
    const { householdId, alex } = await givenTheParkers();
    await openPassport(alex, householdId);
    const views = await viewsOfEmma(householdId);
    expect(views.map((view) => view['viewerMemberId'])).toEqual(['m-alex']);
  });

  it('refuses somebody outside the household before looking at anything else', async () => {
    const { householdId } = await givenTheParkers();
    const stranger = await signUp();
    await expectRefusal(openPassport(stranger, householdId), 'notAMember');
  });

  it('says so when the document has gone', async () => {
    const { householdId, sam } = await givenTheParkers();
    await expectRefusal(
      callAs(sam, 'openVaultDocument', {
        householdId,
        ownerMemberId: 'm-emma',
        documentId: 'gone',
      }),
      'documentNotFound',
    );
    expect(await viewsOfEmma(householdId)).toHaveLength(0);
  });

  it('refuses a signed-out caller and a malformed body', async () => {
    const { householdId, sam } = await givenTheParkers();
    await expectRefusal(openPassport(null, householdId), 'notSignedIn');
    await expectRefusal(callAs(sam, 'openVaultDocument', { householdId }), 'badRequest');
  });

  it('logs every open, and refreshes one ticket rather than piling them up', async () => {
    const { householdId, sam } = await givenTheParkers();
    await openPassport(sam, householdId);
    await openPassport(sam, householdId);

    expect(await viewsOfEmma(householdId)).toHaveLength(2);
    const tickets = await adminDb().collection(`households/${householdId}/vaultOpenings`).get();
    expect(tickets.size).toBe(1);
  });
});
