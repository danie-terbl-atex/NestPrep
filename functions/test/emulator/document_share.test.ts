import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { CallFailed, adminDb, callAs, clearFirestore, signUp } from './emulator_harness';
import {
  CARD_BYTES,
  POLICY_BYTES,
  expire,
  fileQueryIn,
  givenSharingParkers,
  open,
  share,
  shareDoc,
  tokenOf,
  type SharingParkers,
} from './document_share_fixture';

/**
 * One document shared by an expiring link, end to end (documents ADR-0006):
 * made by the callable over HTTP with a real ID token, opened by a browser
 * with no account at all, and stopped by expiry, by a parent, by a shift
 * ending and by a PIN guessed wrong too often. Every open that sends bytes is
 * counted, and a vault's is in that vault's log.
 */

let parkers: SharingParkers;

beforeEach(async () => {
  await clearFirestore();
  parkers = await givenSharingParkers();
});

async function refusal(call: Promise<unknown>): Promise<string | undefined> {
  try {
    await call;
  } catch (error) {
    if (error instanceof CallFailed) return error.reason;
    throw error;
  }
  return 'no refusal';
}

async function vaultViews(ownerMemberId: string): Promise<Record<string, unknown>[]> {
  const views = await adminDb()
    .collection(`households/${parkers.householdId}/vaults/${ownerMemberId}/views`)
    .get();
  return views.docs.map((view) => view.data());
}

describe('making a link', () => {
  it('a parent shares a vault document and gets a link to it, once', async () => {
    const made = await share(parkers.alex, parkers.householdId);
    expect(made.url).toMatch(/documentShare\?t=[A-Za-z0-9_-]{43}$/);
    const stored = await shareDoc(parkers.householdId, made.shareId);
    expect(stored).toMatchObject({
      scope: 'vault',
      ownerMemberId: 'm-emma',
      documentName: 'Emma medical aid card',
      createdBy: 'm-alex',
      status: 'active',
      hasPin: false,
      openCount: 0,
    });
    // The token itself is stored nowhere, not even hashed on the share.
    expect(JSON.stringify(stored)).not.toContain(tokenOf(made.url));
  });

  it('a helper shares her own vault document', async () => {
    const made = await share(parkers.thandi, parkers.householdId, {
      ownerMemberId: 'm-thandi',
      documentId: 'permit',
    });
    expect(made.shareId).not.toBe('');
  });

  it("a helper granted Emma's vault may read it but not send it out", async () => {
    expect(await refusal(share(parkers.thandi, parkers.householdId))).toBe('notAllowedToShare');
  });

  it("a helper cannot send the household's papers out", async () => {
    const call = share(parkers.thandi, parkers.householdId, {
      ownerMemberId: null,
      documentId: 'policy',
    });
    expect(await refusal(call)).toBe('notAllowedToShare');
  });

  it('somebody outside the household is refused', async () => {
    expect(await refusal(share(await signUp(), parkers.householdId))).toBe('notAMember');
  });

  it('a document that is not there is refused', async () => {
    const call = share(parkers.sam, parkers.householdId, { documentId: 'nothing' });
    expect(await refusal(call)).toBe('documentNotFound');
  });

  it('a household has at most 25 live links', async () => {
    const shares = adminDb().collection(`households/${parkers.householdId}/documentShares`);
    for (let index = 0; index < 25; index += 1) {
      await shares.add({
        status: 'active',
        expiresAt: Timestamp.fromMillis(Date.now() + 3_600_000),
      });
    }
    expect(await refusal(share(parkers.sam, parkers.householdId))).toBe('tooManyShares');
  });

  it('is refused when the switch is off', async () => {
    await adminDb().doc('appConfig/flags').set({ documentShareLinks: false });
    try {
      expect(await refusal(share(parkers.sam, parkers.householdId))).toBe('featureOff');
    } finally {
      await adminDb().doc('appConfig/flags').delete();
    }
  });
});

describe('opening a link', () => {
  it('shows a branded page naming the document, then its bytes — logged in the vault', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    const page = await open(tokenOf(made.url));
    expect(page.status).toBe(200);
    expect(page.headers.get('cache-control')).toBe('no-store');
    expect(page.headers.get('content-security-policy')).toContain("default-src 'none'");
    const html = await page.text();
    expect(html).toContain('Emma medical aid card');
    expect(html).toContain('The Parkers shared this with you');
    // The page alone opens nothing: no bytes, no log line.
    expect(await vaultViews('m-emma')).toHaveLength(0);

    const file = await open(tokenOf(made.url), fileQueryIn(html));
    expect(file.status).toBe(200);
    expect(file.headers.get('content-type')).toBe('application/pdf');
    expect(file.headers.get('content-disposition')).toMatch(/^inline; filename="/);
    expect(Buffer.from(await file.arrayBuffer())).toEqual(CARD_BYTES);

    const views = await vaultViews('m-emma');
    expect(views).toHaveLength(1);
    expect(views[0]).toMatchObject({
      documentId: 'card',
      viewerRole: 'shareLink',
      viewerMemberId: null,
      shareId: made.shareId,
    });
    expect(await shareDoc(parkers.householdId, made.shareId)).toMatchObject({ openCount: 1 });
  });

  it('serves a household document too, and counts it on the link', async () => {
    const made = await share(parkers.sam, parkers.householdId, {
      ownerMemberId: null,
      documentId: 'policy',
    });
    const file = await open(tokenOf(made.url), '&file=1');
    expect(file.headers.get('content-type')).toBe('image/jpeg');
    expect(Buffer.from(await file.arrayBuffer())).toEqual(POLICY_BYTES);
    expect(await shareDoc(parkers.householdId, made.shareId)).toMatchObject({ openCount: 1 });
  });

  it('a token that matches nothing, or is not a token, is a plain 404', async () => {
    for (const token of ['x'.repeat(43), 'short', '']) {
      const response = await open(token);
      expect(response.status, token).toBe(404);
      expect(await response.text()).toContain('This link does not work');
    }
  });

  it('serves the mark, and nothing but GET and POST', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    const mark = await open('', '&asset=mark');
    expect(mark.headers.get('content-type')).toBe('image/png');
    const put = await fetch(made.url, { method: 'PUT' });
    expect(put.status).toBe(405);
  });
});

describe('a link stops working', () => {
  it('when it expires — page and file alike, and nothing is logged', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    await expire(parkers.householdId, made.shareId);
    const page = await open(tokenOf(made.url));
    expect(page.status).toBe(410);
    expect(await page.text()).toContain('This link has expired');
    const file = await open(tokenOf(made.url), '&file=1');
    expect(file.status).toBe(410);
    expect(await vaultViews('m-emma')).toHaveLength(0);
  });

  it('when a parent stops it — and anybody else cannot', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    const byHelper = callAs(parkers.thandi, 'revokeDocumentShare', {
      householdId: parkers.householdId,
      shareId: made.shareId,
    });
    expect(await refusal(byHelper)).toBe('notAllowedToShare');
    expect((await open(tokenOf(made.url))).status).toBe(200);

    await callAs(parkers.alex, 'revokeDocumentShare', {
      householdId: parkers.householdId,
      shareId: made.shareId,
    });
    const page = await open(tokenOf(made.url));
    expect(page.status).toBe(410);
    expect(await page.text()).toContain('This link no longer works');
    expect(await shareDoc(parkers.householdId, made.shareId)).toMatchObject({ status: 'revoked' });
  });

  it('when whoever made it is no longer in the household', async () => {
    const made = await share(parkers.alex, parkers.householdId);
    await adminDb()
      .doc(`households/${parkers.householdId}`)
      .update({ members: { [parkers.sam.uid]: 'admin', [parkers.thandi.uid]: 'helper' } });
    expect((await open(tokenOf(made.url))).status).toBe(410);
  });

  it('when the document is deleted', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    await adminDb()
      .doc(`households/${parkers.householdId}/vaults/m-emma/vaultDocuments/card`)
      .delete();
    expect((await open(tokenOf(made.url), '&file=1')).status).toBe(410);
  });

  it('when the switch is turned off, for links already sent', async () => {
    const made = await share(parkers.sam, parkers.householdId);
    await adminDb().doc('appConfig/flags').set({ documentShareLinks: false });
    try {
      expect((await open(tokenOf(made.url))).status).toBe(410);
    } finally {
      await adminDb().doc('appConfig/flags').delete();
    }
  });
});

describe('until the shift ends', () => {
  async function openShift(status: string): Promise<string> {
    const shift = adminDb().collection(`households/${parkers.householdId}/nannyShifts`).doc();
    await shift.set({ carerMemberId: 'm-thandi', startedBy: 'm-sam', status, ticks: {} });
    return shift.id;
  }

  it('is refused for a shift that has already ended', async () => {
    const shiftId = await openShift('ended');
    const call = share(parkers.sam, parkers.householdId, { lifetimeHours: null, shiftId });
    expect(await refusal(call)).toBe('shiftNotOpen');
  });

  it('works during the shift, stops the moment it ends, and the list says ended', async () => {
    const shiftId = await openShift('open');
    const made = await share(parkers.sam, parkers.householdId, { lifetimeHours: null, shiftId });
    const html = await (await open(tokenOf(made.url))).text();
    expect(html).toContain('until the shift ends');

    await adminDb()
      .doc(`households/${parkers.householdId}/nannyShifts/${shiftId}`)
      .update({ status: 'ended' });
    expect((await open(tokenOf(made.url))).status).toBe(410);

    let status: unknown;
    for (let tries = 0; tries < 40 && status !== 'ended'; tries += 1) {
      await new Promise((done) => setTimeout(done, 250));
      status = (await shareDoc(parkers.householdId, made.shareId))['status'];
    }
    expect(status).toBe('ended');
  });
});
