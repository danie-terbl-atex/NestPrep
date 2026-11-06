import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { claimVoucher } from '../../src/premium_vouchers/claim_voucher';
import { EMULATOR_PEPPER } from '../../src/premium_vouchers/premium_config';
import { voidVoucher } from '../../src/premium_vouchers/void_voucher';
import { issueVouchers } from '../../src/premium_vouchers/issue_vouchers';
import { tokenHashOf } from '../../src/premium_vouchers/premium_hashes';
import { firestoreChallenges } from '../../src/premium_vouchers/email_challenges';
import { sendEmailCode, verifyEmailCode } from '../../src/premium_vouchers/email_code';
import { EmailNotSent } from '../../src/shared/email_sender';
import { type RateLimitRule, consumeRateLimit, rateLimitId } from '../../src/shared/rate_limit';
import { REDEEM_MISSES_OVERALL } from '../../src/premium_vouchers/premium_web_limits';
import { EMULATOR_EMAIL_CODE } from '../../src/premium_vouchers/voucher_runtime';
import {
  CallFailed,
  adminDb,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
  signUp,
} from './emulator_harness';
import { createHousehold, expectRefusal } from './product_analytics_fixture';
import {
  aCode,
  aFrameVoucher,
  aGrantIn,
  aPaidSubscription,
  claim,
  codeVoucherOf,
  onTheWeb,
  redeemOnTheWeb,
  vouchersFor,
} from './premium_vouchers_fixture';
import { DAY_MS, aFamily, grantsOf, instant, isAbout, joins, read } from './referrals_fixture';

afterAll(closeAdmin);

describe('a frame voucher claimed into a household', () => {
  beforeEach(clearFirestore);

  it('starts at once for a free household, as a frame grant', async () => {
    const family = await aFamily();
    const { voucherId } = await aFrameVoucher(family.admin.email.toUpperCase(), { partner: true });

    const answer = await claim(family.admin, voucherId, family.householdId);

    expect(answer.queued).toBe(false);
    expect(answer.days).toBe(93);
    expect(answer.startsAt).not.toBeNull();
    const [grant] = await grantsOf(family.householdId);
    expect(grant).toMatchObject({ source: 'frame', days: 93, voucherId });
    const entitlement = await read(`households/${family.householdId}/entitlement/current`);
    expect(isAbout(entitlement['premiumUntil'], 93)).toBe(true);
    expect(instant(entitlement['grantUntil'])).toEqual(instant(entitlement['referralUntil']));
    expect(entitlement['grantDaysWaiting']).toEqual({ referral: 0, frame: 0, code: 0 });
    expect(entitlement['referralDaysWaiting']).toBe(0);
    const voucher = await read(`premiumVouchers/${voucherId}`);
    expect(voucher).toMatchObject({
      status: 'claimed',
      householdId: family.householdId,
      claimedByUid: family.admin.uid,
      grantId: answer.grantId,
    });
    expect(await read(`households/${family.householdId}/private/acquisition`)).toMatchObject({
      code: 'THANDI10',
      partnerId: 'p-thandi',
      via: 'frame-order',
    });
  });

  it('queues behind paid time, and says so', async () => {
    const family = await aFamily();
    const paidUntil = new Date(Date.now() + 20 * DAY_MS);
    await aPaidSubscription(family.admin, family.householdId, paidUntil);
    const { voucherId } = await aFrameVoucher(family.admin.email);

    const answer = await claim(family.admin, voucherId, family.householdId);

    expect(answer).toMatchObject({ queued: true, startsAt: null, days: 93 });
    const entitlement = await read(`households/${family.householdId}/entitlement/current`);
    expect(entitlement['grantDaysWaiting']).toEqual({ referral: 0, frame: 93, code: 0 });
    expect(entitlement['referralDaysWaiting']).toBe(93);
    expect(instant(entitlement['premiumUntil'])).toEqual(
      new Date(paidUntil.getTime() + 93 * DAY_MS),
    );
    expect(entitlement['status']).toBe('cancelled');
  });

  it('adds up when one household claims two', async () => {
    const family = await aFamily();
    const first = await aFrameVoucher(family.admin.email, { days: 62 });
    const second = await aFrameVoucher(family.admin.email);
    await claim(family.admin, first.voucherId, family.householdId);
    const answer = await claim(family.admin, second.voucherId, family.householdId);
    expect(answer.queued).toBe(true);
    const entitlement = await read(`households/${family.householdId}/entitlement/current`);
    expect(isAbout(entitlement['premiumUntil'], 155)).toBe(true);
    expect(entitlement['grantDaysWaiting']).toEqual({ referral: 0, frame: 93, code: 0 });
  });

  it('is refused to an account whose emails are not the voucher’s', async () => {
    const family = await aFamily();
    const { voucherId } = await aFrameVoucher('somebody-else@nestprep.test');
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'notYourVoucher');
    expect(await grantsOf(family.householdId)).toEqual([]);
  });

  it('is refused for a test order to anybody who is not a tester', async () => {
    const family = await aFamily();
    const { voucherId } = await aFrameVoucher(family.admin.email, { isTest: true });
    expect(await vouchersFor(family.admin)).toEqual([]);
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'testVoucher');
    expect((await read(`premiumVouchers/${voucherId}`))['status']).toBe('waiting');
  });

  it('is claimed once: again, or into another household, it is already claimed', async () => {
    const family = await aFamily();
    const { voucherId } = await aFrameVoucher(family.admin.email);
    await claim(family.admin, voucherId, family.householdId);
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'voucherClaimed');
    const second = await createHousehold(family.admin);
    await expectRefusal(claim(family.admin, voucherId, second.householdId), 'voucherClaimed');
    expect(await grantsOf(family.householdId)).toHaveLength(1);
  });

  it('is refused once the store voided it, and the store cannot void it once claimed', async () => {
    const family = await aFamily();
    const voided = await aFrameVoucher(family.admin.email);
    expect(
      await voidVoucher(adminDb(), { voucherId: voided.voucherId, reason: 'refund' }, new Date()),
    ).toBe('voided');
    await expectRefusal(claim(family.admin, voided.voucherId, family.householdId), 'voucherVoid');

    const claimed = await aFrameVoucher(family.admin.email);
    await claim(family.admin, claimed.voucherId, family.householdId);
    expect(
      await voidVoucher(adminDb(), { voucherId: claimed.voucherId, reason: 'refund' }, new Date()),
    ).toBe('alreadyClaimed');
    expect((await read(`premiumVouchers/${claimed.voucherId}`))['status']).toBe('claimed');
  });

  it('is refused to a helper, into a household that does not exist, and for a voucher that does not', async () => {
    const family = await aFamily();
    const helper = await joins(family, 'helper');
    const { voucherId } = await aFrameVoucher(helper.email);
    await expectRefusal(claim(helper, voucherId, family.householdId), 'notAMember');
    const other = await aFamily();
    await expectRefusal(claim(helper, voucherId, other.householdId), 'notAMember');
    await expectRefusal(claim(helper, voucherId, 'no-such-household'), 'householdNotFound');
    await expectRefusal(claim(helper, 'ord_none_1', family.householdId), 'voucherNotFound');
    expect((await read(`premiumVouchers/${voucherId}`))['status']).toBe('waiting');
  });

  it('may be claimed by a tester when it came from a test order', async () => {
    const family = await aFamily();
    const { voucherId } = await aFrameVoucher(family.admin.email, { isTest: true });
    const answer = await claimVoucher(
      {
        store: adminDb(),
        users: { provenEmails: async () => Promise.resolve([family.admin.email]) },
        pepper: EMULATOR_PEPPER,
        testers: [family.admin.uid],
        now: new Date(),
      },
      family.admin.uid,
      { voucherId, householdId: family.householdId },
    );
    expect(answer.queued).toBe(false);
  });
});

describe('the vouchers waiting for me', () => {
  beforeEach(clearFirestore);

  it('are the waiting ones sent to any email I have proved, with no code or partner in them', async () => {
    const family = await aFamily();
    const waiting = await aFrameVoucher(family.admin.email, { partner: true });
    const claimed = await aFrameVoucher(family.admin.email);
    await aFrameVoucher('other@nestprep.test');
    await claim(family.admin, claimed.voucherId, family.householdId);

    expect(await vouchersFor(family.admin)).toEqual([
      {
        voucherId: waiting.voucherId,
        kind: 'frame',
        days: 93,
        sku: 'frame-15',
        emailMasked: `t***@nestprep.test`,
        isTest: false,
      },
    ]);
  });

  it('leave out a code voucher past the day it had to be claimed by', async () => {
    const family = await aFamily();
    const codeHash = await aCode('LATE-CODE');
    await redeemOnTheWeb('late-code', family.admin.email);
    const voucherId = await codeVoucherOf(codeHash, family.admin.email);
    expect((await vouchersFor(family.admin)).map((voucher) => voucher.voucherId)).toEqual([
      voucherId,
    ]);
    await adminDb()
      .doc(`premiumVouchers/${voucherId}`)
      .update({ claimBy: Timestamp.fromMillis(Date.now() - DAY_MS) });
    expect(await vouchersFor(family.admin)).toEqual([]);
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'codeExpired');
  });
});

describe('a Premium code, redeemed on the web and claimed in the app', () => {
  beforeEach(clearFirestore);

  it('becomes a code voucher, then a code grant using one of its places', async () => {
    const family = await aFamily();
    const codeHash = await aCode('THANDI30', {
      maxClaims: 5,
      attribution: { partnerId: 'p-thandi' },
    });

    const first = await redeemOnTheWeb('thandi-30', family.admin.email);
    expect(first).toMatchObject({
      status: 200,
      body: { result: 'redeemed', days: 30, label: 'Launch readers' },
    });
    expect(first.cacheControl).toBe('no-store');
    const again = await redeemOnTheWeb(' THANDI30 ', family.admin.email.toUpperCase());
    expect(again.body).toEqual(first.body);
    expect((await read(`premiumCodes/${codeHash}`))['claimCount']).toBe(0);

    const voucherId = await codeVoucherOf(codeHash, family.admin.email);
    const answer = await claim(family.admin, voucherId, family.householdId);

    expect(answer).toMatchObject({ days: 30, queued: false });
    expect((await read(`premiumCodes/${codeHash}`))['claimCount']).toBe(1);
    expect(await read(`premiumCodes/${codeHash}/claims/${family.householdId}`)).toMatchObject({
      uid: family.admin.uid,
      voucherId,
    });
    const [grant] = await grantsOf(family.householdId);
    expect(grant).toMatchObject({ source: 'code', days: 30, voucherId });
    expect(await read(`households/${family.householdId}/private/acquisition`)).toMatchObject({
      code: 'THANDI30',
      partnerId: 'p-thandi',
      via: 'premium-code',
    });
  });

  it('gives exactly two of three racing households a two-place code', async () => {
    const codeHash = await aCode('RACE-TWO', { maxClaims: 2 });
    const families = await Promise.all([aFamily(), aFamily(), aFamily()]);
    const vouchers: string[] = [];
    for (const family of families) {
      await redeemOnTheWeb('RACE-TWO', family.admin.email);
      vouchers.push(await codeVoucherOf(codeHash, family.admin.email));
    }

    const outcomes = await Promise.allSettled(
      families.map((family, index) =>
        claim(family.admin, vouchers[index] ?? '', family.householdId),
      ),
    );

    expect(outcomes.filter((outcome) => outcome.status === 'fulfilled')).toHaveLength(2);
    const refused = outcomes.flatMap((outcome): unknown[] =>
      outcome.status === 'rejected' ? [outcome.reason] : [],
    );
    expect(refused).toHaveLength(1);
    expect(refused[0]).toBeInstanceOf(CallFailed);
    expect((refused[0] as CallFailed).reason).toBe('codeUsedUp');
    expect((await read(`premiumCodes/${codeHash}`))['claimCount']).toBe(2);
    const claims = await adminDb().collection(`premiumCodes/${codeHash}/claims`).get();
    expect(claims.size).toBe(2);
    expect((await redeemOnTheWeb('RACE-TWO', 'late@nestprep.test')).body).toEqual({
      error: 'codeUsedUp',
    });
  });

  it('is for households new to Premium unless the code says any', async () => {
    const strict = await aCode('NEW-ONLY', { eligibility: 'newToPremium' });
    const open = await aCode('ANYONE', { eligibility: 'any' });

    const framed = await aFamily();
    await aGrantIn(framed.householdId, 'old-frame', {
      source: 'frame',
      days: 93,
      grantedDaysAgo: 200,
      started: true,
    });
    await redeemOnTheWeb('NEW-ONLY', framed.admin.email);
    await expectRefusal(
      claim(framed.admin, await codeVoucherOf(strict, framed.admin.email), framed.householdId),
      'codeNotEligible',
    );

    const paying = await aFamily();
    await aPaidSubscription(paying.admin, paying.householdId, new Date(Date.now() - 5 * DAY_MS));
    await redeemOnTheWeb('NEW-ONLY', paying.admin.email);
    await expectRefusal(
      claim(paying.admin, await codeVoucherOf(strict, paying.admin.email), paying.householdId),
      'codeNotEligible',
    );

    await redeemOnTheWeb('ANYONE', framed.admin.email);
    const answer = await claim(
      framed.admin,
      await codeVoucherOf(open, framed.admin.email),
      framed.householdId,
    );
    expect(answer.days).toBe(30);

    const fresh = await aFamily();
    await redeemOnTheWeb('NEW-ONLY', fresh.admin.email);
    await claim(fresh.admin, await codeVoucherOf(strict, fresh.admin.email), fresh.householdId);
    expect((await read(`premiumCodes/${strict}`))['claimCount']).toBe(1);
  });

  it('is one per household in any 365 days, and frame or referral grants do not count (D16)', async () => {
    const codeHash = await aCode('YEARLY');
    const recent = await aFamily();
    await aGrantIn(recent.householdId, 'old-code', {
      source: 'code',
      days: 30,
      grantedDaysAgo: 100,
      started: true,
    });
    await redeemOnTheWeb('YEARLY', recent.admin.email);
    await expectRefusal(
      claim(recent.admin, await codeVoucherOf(codeHash, recent.admin.email), recent.householdId),
      'codeYearlyLimit',
    );

    const longAgo = await aFamily();
    await aGrantIn(longAgo.householdId, 'old-code', {
      source: 'code',
      days: 30,
      grantedDaysAgo: 366,
      started: true,
    });
    await aGrantIn(longAgo.householdId, 'frame', {
      source: 'frame',
      days: 93,
      grantedDaysAgo: 10,
      started: true,
    });
    await aGrantIn(longAgo.householdId, 'referral', {
      source: 'referral',
      days: 30,
      grantedDaysAgo: 10,
      started: false,
    });
    await redeemOnTheWeb('YEARLY', longAgo.admin.email);
    const answer = await claim(
      longAgo.admin,
      await codeVoucherOf(codeHash, longAgo.admin.email),
      longAgo.householdId,
    );
    expect(answer.queued).toBe(true);
  });

  it('is used once per household and once per person', async () => {
    const codeHash = await aCode('ONCE-EACH');
    const family = await aFamily();
    const partner = await joins(family, 'parent');
    await redeemOnTheWeb('ONCE-EACH', family.admin.email);
    await redeemOnTheWeb('ONCE-EACH', partner.email);
    await claim(
      family.admin,
      await codeVoucherOf(codeHash, family.admin.email),
      family.householdId,
    );
    await expect(
      claim(partner, await codeVoucherOf(codeHash, partner.email), family.householdId),
    ).rejects.toMatchObject({
      reason: 'codeAlreadyUsed',
    });

    const secondHome = await createHousehold(family.admin);
    const otherEmail = `other-${family.admin.uid}@nestprep.test`.toLowerCase();
    await redeemOnTheWeb('ONCE-EACH', otherEmail);
    await callAs(family.admin, 'sendVoucherEmailCode', { email: otherEmail });
    await callAs(family.admin, 'verifyVoucherEmailCode', {
      email: otherEmail,
      code: EMULATOR_EMAIL_CODE,
    });
    await expectRefusal(
      claim(family.admin, await codeVoucherOf(codeHash, otherEmail), secondHome.householdId),
      'codeAlreadyUsed',
    );
    expect((await read(`premiumCodes/${codeHash}`))['claimCount']).toBe(1);
  });

  it('is refused while paused, once archived, and long after it ended', async () => {
    const family = await aFamily();
    const codeHash = await aCode('STATES');
    await redeemOnTheWeb('STATES', family.admin.email);
    const voucherId = await codeVoucherOf(codeHash, family.admin.email);
    const code = adminDb().doc(`premiumCodes/${codeHash}`);

    await code.update({ status: 'paused' });
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'codePaused');
    await code.update({ status: 'archived' });
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'codeExpired');
    await code.update({
      status: 'active',
      validFrom: Timestamp.fromMillis(Date.now() - 90 * DAY_MS),
      validUntil: Timestamp.fromMillis(Date.now() - 31 * DAY_MS),
    });
    await expectRefusal(claim(family.admin, voucherId, family.householdId), 'codeExpired');
    expect(await grantsOf(family.householdId)).toEqual([]);
  });
});

describe('the web page’s answers', () => {
  beforeEach(clearFirestore);

  it('refuse a code that is unknown, paused, not started, ended or used up', async () => {
    await aCode('PAUSED', { status: 'paused' });
    await aCode('LATER', { validFrom: new Date('2099-03-01T00:00:00+02:00') });
    await aCode('ENDED', {
      validFrom: new Date('2020-01-01T00:00:00Z'),
      validUntil: new Date('2026-01-31T23:59:59+02:00'),
    });
    await aCode('FULL', { maxClaims: 1, claimCount: 1 });
    await aCode('GONE', { status: 'archived' });
    const email = 'web@nestprep.test';
    expect(await redeemOnTheWeb('NOPE-NOPE', email)).toMatchObject({
      status: 404,
      body: { error: 'codeUnknown' },
    });
    expect((await redeemOnTheWeb('GONE', email)).body).toEqual({ error: 'codeUnknown' });
    expect((await redeemOnTheWeb('PAUSED', email)).body).toEqual({ error: 'codePaused' });
    expect((await redeemOnTheWeb('LATER', email)).body).toEqual({
      error: 'codeNotStarted',
      startsOn: '2099-03-01',
    });
    expect((await redeemOnTheWeb('ENDED', email)).body).toEqual({
      error: 'codeExpired',
      endedOn: '2026-01-31',
    });
    expect((await redeemOnTheWeb('FULL', email)).body).toEqual({ error: 'codeUsedUp' });
    expect((await redeemOnTheWeb('ab', email)).body).toEqual({ error: 'badCode' });
    expect((await redeemOnTheWeb('PAUSED', 'nope')).body).toEqual({ error: 'badEmail' });
    expect((await adminDb().collection('premiumVouchers').get()).size).toBe(0);
  });

  it('show a gift by its link, move it to another email while it waits, and never say more', async () => {
    const family = await aFamily();
    const { voucherId, token } = await aFrameVoucher('typo@nestprep.test');

    const lookup = await onTheWeb('/gift/lookup', { token });
    expect(lookup).toMatchObject({
      status: 200,
      body: { status: 'waiting', days: 93, sku: 'frame-15', emailMasked: 't***@nestprep.test' },
      cacheControl: 'no-store',
    });
    expect(Object.keys(lookup.body).sort()).toEqual(['days', 'emailMasked', 'sku', 'status']);

    const moved = await onTheWeb('/gift/reassign', { token, email: family.admin.email });
    expect(moved.body).toEqual({ ok: true, emailMasked: 't***@nestprep.test' });
    expect((await vouchersFor(family.admin)).map((voucher) => voucher.voucherId)).toEqual([
      voucherId,
    ]);
    expect((await read(`premiumVouchers/${voucherId}`))['reassignedAt']).toBeInstanceOf(Timestamp);

    await claim(family.admin, voucherId, family.householdId);
    expect((await onTheWeb('/gift/lookup', { token })).body['status']).toBe('claimed');
    expect(await onTheWeb('/gift/reassign', { token, email: 'x@nestprep.test' })).toMatchObject({
      status: 409,
      body: { error: 'voucherClaimed' },
    });

    const voided = await aFrameVoucher('void@nestprep.test');
    await voidVoucher(adminDb(), { voucherId: voided.voucherId, reason: 'cancelled' }, new Date());
    expect(
      (await onTheWeb('/gift/reassign', { token: voided.token, email: 'x@nestprep.test' })).body,
    ).toEqual({
      error: 'voucherVoid',
    });
    const unknown = 'B'.repeat(43);
    expect(await onTheWeb('/gift/lookup', { token: unknown })).toMatchObject({
      status: 404,
      body: { error: 'voucherNotFound' },
    });
    expect(
      (await onTheWeb('/gift/reassign', { token: unknown, email: 'x@nestprep.test' })).body,
    ).toEqual({
      error: 'voucherNotFound',
    });
  });

  it('stop answering one address’s gift lookups after sixty in a quarter hour', async () => {
    const answers: number[] = [];
    for (let attempt = 0; attempt < 61; attempt += 1) {
      answers.push((await onTheWeb('/gift/lookup', { token: 'C'.repeat(43) })).status);
    }
    expect(answers.slice(0, 60).every((status) => status === 404)).toBe(true);
    expect(answers[60]).toBe(429);
    expect((await redeemOnTheWeb('NOPE-NOPE', 'x@nestprep.test')).status).toBe(404);
  });
});

describe('proving another email with a code (Hide My Email)', () => {
  beforeEach(clearFirestore);

  it('adds the email to the account, after which its vouchers are mine', async () => {
    const user = await signUp();
    const storeEmail = `shop-${user.uid}@nestprep.test`.toLowerCase();
    await aFrameVoucher(storeEmail);
    expect(await vouchersFor(user)).toEqual([]);

    expect(await callAs(user, 'sendVoucherEmailCode', { email: storeEmail })).toEqual({
      sent: true,
      emailMasked: 's***@nestprep.test',
    });
    const challenge = await read(`premiumEmailChallenges/${user.uid}`);
    expect(challenge['codeHash']).not.toBe(EMULATOR_EMAIL_CODE);
    expect(JSON.stringify(challenge)).not.toContain(storeEmail);
    await expectRefusal(
      callAs(user, 'verifyVoucherEmailCode', { email: storeEmail, code: '000000' }),
      'emailCodeWrong',
    );
    expect(
      await callAs(user, 'verifyVoucherEmailCode', {
        email: storeEmail,
        code: EMULATOR_EMAIL_CODE,
      }),
    ).toEqual({
      verified: true,
      emailMasked: 's***@nestprep.test',
    });

    expect(await vouchersFor(user)).toHaveLength(1);
    expect((await adminDb().doc(`premiumEmailChallenges/${user.uid}`).get()).exists).toBe(false);
    const verified = await read(`users/${user.uid}/private/verifiedEmails`);
    expect(JSON.stringify(verified)).not.toContain(storeEmail);
    await expectRefusal(
      callAs(user, 'sendVoucherEmailCode', { email: storeEmail.toUpperCase() }),
      'emailAlreadyVerified',
    );
    await expectRefusal(
      callAs(user, 'sendVoucherEmailCode', { email: user.email }),
      'emailAlreadyVerified',
    );
  });

  it('sends at most three codes an hour to one account', async () => {
    const user = await signUp();
    for (let sent = 0; sent < 3; sent += 1) {
      await callAs(user, 'sendVoucherEmailCode', { email: `a${String(sent)}@nestprep.test` });
    }
    await expectRefusal(
      callAs(user, 'sendVoucherEmailCode', { email: 'a9@nestprep.test' }),
      'tooManyCodes',
    );
  });

  it('allows five tries at a code, and refuses an expired one', async () => {
    const user = await signUp();
    const email = 'tries@nestprep.test';
    await callAs(user, 'sendVoucherEmailCode', { email });
    for (let tried = 0; tried < 5; tried += 1) {
      await expectRefusal(
        callAs(user, 'verifyVoucherEmailCode', { email, code: '999999' }),
        'emailCodeWrong',
      );
    }
    await expectRefusal(
      callAs(user, 'verifyVoucherEmailCode', { email, code: EMULATOR_EMAIL_CODE }),
      'emailCodeTooManyTries',
    );

    await callAs(user, 'sendVoucherEmailCode', { email });
    await adminDb()
      .doc(`premiumEmailChallenges/${user.uid}`)
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    await expectRefusal(
      callAs(user, 'verifyVoucherEmailCode', { email, code: EMULATOR_EMAIL_CODE }),
      'emailCodeExpired',
    );
    const stranger = await signUp();
    await expectRefusal(
      callAs(stranger, 'verifyVoucherEmailCode', { email, code: EMULATOR_EMAIL_CODE }),
      'emailCodeExpired',
    );
  });

  it('counts a try for the right code sent to a different email', async () => {
    const user = await signUp();
    await callAs(user, 'sendVoucherEmailCode', { email: 'one@nestprep.test' });
    await expectRefusal(
      callAs(user, 'verifyVoucherEmailCode', {
        email: 'two@nestprep.test',
        code: EMULATOR_EMAIL_CODE,
      }),
      'emailCodeWrong',
    );
    expect((await read(`premiumEmailChallenges/${user.uid}`))['tries']).toBe(1);
  });
});

describe('the store’s two endpoints', () => {
  beforeEach(clearFirestore);

  it('issue idempotently, never overwriting a voucher, and keep no email', async () => {
    const voucher = {
      voucherId: 'ord_idem_1',
      orderId: 'ord_idem',
      sku: 'frame-10',
      days: 62,
      email: 'Buyer@Example.com',
      claimTokenHash: tokenHashOf('t'.repeat(43)),
      isTest: false,
      attribution: null,
    };
    expect(
      await issueVouchers(adminDb(), EMULATOR_PEPPER, { vouchers: [voucher] }, new Date()),
    ).toEqual([{ voucherId: 'ord_idem_1', outcome: 'issued' }]);
    await adminDb().doc('premiumVouchers/ord_idem_1').update({ status: 'claimed' });
    const again = await issueVouchers(
      adminDb(),
      EMULATOR_PEPPER,
      {
        vouchers: [
          { ...voucher, days: 3650 },
          { ...voucher, voucherId: 'ord_idem_2' },
        ],
      },
      new Date(),
    );
    expect(again).toEqual([
      { voucherId: 'ord_idem_1', outcome: 'exists' },
      { voucherId: 'ord_idem_2', outcome: 'issued' },
    ]);
    const stored = await read('premiumVouchers/ord_idem_1');
    expect(stored).toMatchObject({ status: 'claimed', days: 62, emailMasked: 'b***@example.com' });
    expect(JSON.stringify(stored).toLowerCase()).not.toContain('buyer@example.com');
  });

  it('void a waiting voucher once and say what it found otherwise', async () => {
    const { voucherId } = await aFrameVoucher('void@nestprep.test');
    const now = new Date();
    expect(await voidVoucher(adminDb(), { voucherId, reason: 'refund' }, now)).toBe('voided');
    expect(await voidVoucher(adminDb(), { voucherId, reason: 'refund' }, now)).toBe('alreadyVoid');
    expect(await voidVoucher(adminDb(), { voucherId: 'ord_none_1', reason: 'refund' }, now)).toBe(
      'notFound',
    );
    expect(await read(`premiumVouchers/${voucherId}`)).toMatchObject({
      status: 'void',
      voidReason: 'refund',
    });
  });

  it('refuse anybody without the store’s ID token', async () => {
    for (const name of ['issuePremiumVouchers', 'voidFrameVoucher']) {
      const response = await fetch(httpFunctionUrl(name), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer not-a-google-id-token-at-all',
        },
        body: JSON.stringify({ voucherId: 'ord_x_1', reason: 'refund' }),
      });
      expect(response.status, name).toBe(403);
      expect(await response.json()).toEqual({ error: 'forbidden' });
    }
  });
});

describe('nobody can guess at a code that was never sent (R-01)', () => {
  beforeEach(clearFirestore);

  it('leaves no live challenge after tooManyCodes', async () => {
    const target = 'guarded@nestprep.test';
    for (let sender = 0; sender < 5; sender += 1) {
      await callAs(await signUp(), 'sendVoucherEmailCode', { email: target });
    }
    const attacker = await signUp();
    await expectRefusal(
      callAs(attacker, 'sendVoucherEmailCode', { email: target }),
      'tooManyCodes',
    );
    expect((await adminDb().doc(`premiumEmailChallenges/${attacker.uid}`).get()).exists).toBe(
      false,
    );
    await expectRefusal(
      callAs(attacker, 'verifyVoucherEmailCode', { email: target, code: '000000' }),
      'emailCodeExpired',
    );
    await expectRefusal(
      callAs(attacker, 'verifyVoucherEmailCode', { email: target, code: EMULATOR_EMAIL_CODE }),
      'emailCodeExpired',
    );
  });

  it('leaves no live challenge when the email is not accepted', async () => {
    const user = await signUp();
    const store = adminDb();
    const now = new Date();
    const deps = {
      challenges: firestoreChallenges(store),
      provenHashes: async (): Promise<string[]> => Promise.resolve([]),
      pepper: EMULATOR_PEPPER,
      sender: {
        send: async (): Promise<void> => {
          await Promise.resolve();
          throw new EmailNotSent('status 500');
        },
      },
      newCode: (): string => '424242',
      consume: (rule: RateLimitRule, subject: string): Promise<boolean> =>
        consumeRateLimit(store, rule, subject, now),
      now,
    };
    await expect(sendEmailCode(deps, user.uid, 'bounce@nestprep.test')).rejects.toMatchObject({
      code: 'unavailable',
    });
    expect((await store.doc(`premiumEmailChallenges/${user.uid}`).get()).exists).toBe(false);
    await expect(
      verifyEmailCode(deps, user.uid, { email: 'bounce@nestprep.test', code: '424242' }),
    ).rejects.toMatchObject({ details: { reason: 'emailCodeExpired' } });
  });

  it('holds one address to ten tries an hour across every account', async () => {
    const target = 'many-tries@nestprep.test';
    for (let round = 0; round < 2; round += 1) {
      const guesser = await signUp();
      await callAs(guesser, 'sendVoucherEmailCode', { email: target });
      for (let tried = 0; tried < 5; tried += 1) {
        await expectRefusal(
          callAs(guesser, 'verifyVoucherEmailCode', { email: target, code: '999999' }),
          'emailCodeWrong',
        );
      }
    }
    const owner = await signUp();
    await callAs(owner, 'sendVoucherEmailCode', { email: target });
    await expectRefusal(
      callAs(owner, 'verifyVoucherEmailCode', { email: target, code: EMULATOR_EMAIL_CODE }),
      'emailCodeTooManyTries',
    );
    expect((await adminDb().doc(`users/${owner.uid}/private/verifiedEmails`).get()).exists).toBe(
      false,
    );
  });

  it('lets nobody spend an address’s tries with a challenge sent somewhere else (N-02)', async () => {
    const victim = 'hide-my-email@nestprep.test';
    const attacker = await signUp();
    await callAs(attacker, 'sendVoucherEmailCode', {
      email: `own-${attacker.uid}@nestprep.test`.toLowerCase(),
    });
    const outcomes: string[] = [];
    for (let call = 0; call < 12; call += 1) {
      await callAs(attacker, 'verifyVoucherEmailCode', { email: victim, code: '000000' }).catch(
        (error: unknown) => {
          outcomes.push(error instanceof CallFailed ? (error.reason ?? '') : 'other');
        },
      );
    }
    expect(outcomes.slice(0, 5)).toEqual(Array(5).fill('emailCodeWrong'));
    expect(outcomes.slice(5)).toEqual(Array(7).fill('emailCodeTooManyTries'));
    const owner = await signUp();
    await callAs(owner, 'sendVoucherEmailCode', { email: victim });
    expect(
      await callAs(owner, 'verifyVoucherEmailCode', { email: victim, code: EMULATOR_EMAIL_CODE }),
    ).toEqual({ verified: true, emailMasked: 'h***@nestprep.test' });
  });

  it('lets nobody without a challenge spend an address’s tries', async () => {
    const target = 'owner-only@nestprep.test';
    const stranger = await signUp();
    for (let call = 0; call < 20; call += 1) {
      await expectRefusal(
        callAs(stranger, 'verifyVoucherEmailCode', { email: target, code: '000000' }),
        'emailCodeExpired',
      );
    }
    const owner = await signUp();
    await callAs(owner, 'sendVoucherEmailCode', { email: target });
    expect(
      await callAs(owner, 'verifyVoucherEmailCode', { email: target, code: EMULATOR_EMAIL_CODE }),
    ).toEqual({ verified: true, emailMasked: 'o***@nestprep.test' });
  });

  it('caps one account at ten codes a day, whatever the hour', async () => {
    const user = await signUp();
    for (let sent = 0; sent < 10; sent += 1) {
      await adminDb().doc(`premiumEmailChallenges/${user.uid}`).delete();
      await callAs(user, 'sendVoucherEmailCode', { email: `day${String(sent)}@nestprep.test` });
    }
    await adminDb().doc(`premiumEmailChallenges/${user.uid}`).delete();
    await expectRefusal(
      callAs(user, 'sendVoucherEmailCode', { email: 'day10@nestprep.test' }),
      'tooManyCodes',
    );
  });
});

describe('the redeem page answers the same for a first and a repeat redemption (R-11, N-04)', () => {
  beforeEach(clearFirestore);

  it('never lets garbage codes lock an email out, and counts a real code’s refusals per email', async () => {
    await aCode('GOOD-ONE');
    await aCode('ON-HOLD', { status: 'paused' });
    const email = 'repeat@nestprep.test';
    for (let attempt = 0; attempt < 5; attempt += 1) {
      expect((await redeemOnTheWeb('WRONG-CODE', email)).body).toEqual({ error: 'codeUnknown' });
    }
    for (let attempt = 0; attempt < 3; attempt += 1) {
      expect((await redeemOnTheWeb('GOOD-ONE', email)).body['result']).toBe('redeemed');
    }
    for (let attempt = 0; attempt < 10; attempt += 1) {
      expect((await redeemOnTheWeb('ON-HOLD', email)).body).toEqual({ error: 'codePaused' });
    }
    expect((await redeemOnTheWeb('ON-HOLD', email)).body).toEqual({ error: 'tooManyTries' });
    expect((await redeemOnTheWeb('GOOD-ONE', email)).body['result']).toBe('redeemed');
    expect((await adminDb().collection('premiumVouchers').get()).size).toBe(1);
  });

  it('still answers redeemed to an email that redeemed a code since paused', async () => {
    const codeHash = await aCode('THEN-PAUSED');
    const first = await redeemOnTheWeb('THEN-PAUSED', 'early@nestprep.test');
    await adminDb().doc(`premiumCodes/${codeHash}`).update({ status: 'paused' });
    expect((await redeemOnTheWeb('THEN-PAUSED', 'early@nestprep.test')).body).toEqual(first.body);
    expect((await redeemOnTheWeb('THEN-PAUSED', 'never@nestprep.test')).body).toEqual({
      error: 'codePaused',
    });
  });
});

describe('every redeem from an address is limited before anything is looked up (M-01)', () => {
  beforeEach(clearFirestore);

  const vouchers = async (): Promise<number> =>
    (await adminDb().collection('premiumVouchers').get()).size;

  it('refuses the thirty-first redeem in a quarter hour, a valid code and a new email included', async () => {
    await aCode('REAL-CODE');
    for (let call = 0; call < 30; call += 1) {
      expect((await redeemOnTheWeb('REAL-CODE', 'same@nestprep.test')).status).toBe(200);
    }
    expect(await vouchers()).toBe(1);
    expect(await redeemOnTheWeb('REAL-CODE', 'fresh@nestprep.test')).toMatchObject({
      status: 429,
      body: { error: 'tooManyTries' },
    });
    expect(await vouchers()).toBe(1);
  });

  it('refuses everything, a valid code included, once ten misses are spent', async () => {
    await aCode('REAL-CODE');
    for (let miss = 0; miss < 10; miss += 1) {
      expect((await redeemOnTheWeb(`MISS-${String(miss)}`, 'guess@nestprep.test')).status).toBe(
        404,
      );
    }
    expect((await redeemOnTheWeb('MISS-X', 'guess@nestprep.test')).status).toBe(429);
    expect((await redeemOnTheWeb('REAL-CODE', 'new@nestprep.test')).status).toBe(429);
    expect(await vouchers()).toBe(0);
  });

  it('creates at most ten vouchers an hour from one address', async () => {
    await aCode('SHARED-CODE');
    for (let email = 0; email < 10; email += 1) {
      expect(
        (await redeemOnTheWeb('SHARED-CODE', `farm-${String(email)}@nestprep.test`)).body['result'],
      ).toBe('redeemed');
    }
    expect((await redeemOnTheWeb('SHARED-CODE', 'farm-10@nestprep.test')).body).toEqual({
      error: 'tooManyTries',
    });
    expect((await redeemOnTheWeb('SHARED-CODE', 'farm-0@nestprep.test')).body['result']).toBe(
      'redeemed',
    );
    expect(await vouchers()).toBe(10);
  });

  it('lets a spent overall miss ceiling refuse misses only, never a found code', async () => {
    await aCode('REAL-CODE');
    await adminDb()
      .doc(`rateLimits/${rateLimitId(REDEEM_MISSES_OVERALL, 'all')}`)
      .set({
        rule: REDEEM_MISSES_OVERALL.name,
        windowStart: Timestamp.now(),
        count: REDEEM_MISSES_OVERALL.limit,
        expiresAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
      });
    expect((await redeemOnTheWeb('NOPE-NOPE', 'x@nestprep.test')).status).toBe(429);
    expect((await redeemOnTheWeb('REAL-CODE', 'x@nestprep.test')).body['result']).toBe('redeemed');
  });
});

describe('a gift link moves its Premium at most five times (R-10)', () => {
  beforeEach(clearFirestore);

  it('then refuses voucherReassignLimit and keeps the last email', async () => {
    const { voucherId, token } = await aFrameVoucher('first@nestprep.test');
    for (let move = 1; move <= 5; move += 1) {
      expect(
        (await onTheWeb('/gift/reassign', { token, email: `move${String(move)}@nestprep.test` }))
          .status,
      ).toBe(200);
    }
    expect(await onTheWeb('/gift/reassign', { token, email: 'sixth@nestprep.test' })).toMatchObject(
      { status: 409, body: { error: 'voucherReassignLimit' } },
    );
    const stored = await read(`premiumVouchers/${voucherId}`);
    expect(stored['reassignCount']).toBe(5);
    expect(stored['emailMasked']).toBe('m***@nestprep.test');
    expect(stored['reassignedAt']).toBeInstanceOf(Timestamp);
  });
});

describe('a household with hundreds of grants (R-13)', () => {
  beforeEach(clearFirestore);

  it('composes every one of them, the oldest included', async () => {
    const family = await aFamily();
    const grants = adminDb().collection(`households/${family.householdId}/premiumGrants`);
    const long = Timestamp.fromMillis(Date.now() - 400 * DAY_MS);
    await grants
      .doc('oldest')
      .set({ source: 'frame', days: 3650, grantedAt: long, startsAt: long });
    for (let start = 0; start < 220; start += 110) {
      const batch = adminDb().batch();
      for (let index = start; index < start + 110; index += 1) {
        const at = Timestamp.fromMillis(Date.now() - (300 - index) * DAY_MS);
        batch.set(grants.doc(`tiny-${String(index)}`), {
          source: 'referral',
          days: 1,
          grantedAt: at,
          startsAt: at,
        });
      }
      await batch.commit();
    }
    const { voucherId } = await aFrameVoucher(family.admin.email);

    const answer = await claim(family.admin, voucherId, family.householdId);

    expect(answer.queued).toBe(true);
    const entitlement = await read(`households/${family.householdId}/entitlement/current`);
    expect(isAbout(entitlement['grantUntil'], 3650 - 400 + 93)).toBe(true);
    expect(entitlement['grantDaysWaiting']).toEqual({ referral: 0, frame: 93, code: 0 });
  });
});
