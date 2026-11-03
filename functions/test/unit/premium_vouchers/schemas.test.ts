import { describe, expect, it } from 'vitest';

import {
  claimPremiumVoucherInput,
  issueVouchersInput,
  premiumVouchersForMeInput,
  sendVoucherEmailCodeInput,
  verifyVoucherEmailCodeInput,
  voidVoucherInput,
} from '../../../src/premium_vouchers/schemas';

const voucher = {
  voucherId: 'ord_8Kd2_1',
  orderId: 'ord_8Kd2',
  sku: 'frame-15',
  days: 93,
  email: 'Sam@Example.com',
  claimTokenHash: 'a'.repeat(64),
  isTest: false,
  attribution: { code: 'THANDI10', partnerId: 'p-thandi' },
};

describe('issuePremiumVouchers takes what the store sends (C-0026)', () => {
  it('accepts one to twenty vouchers', () => {
    expect(issueVouchersInput.safeParse({ vouchers: [voucher] }).success).toBe(true);
    const twenty = Array.from({ length: 20 }, (_, index) => ({
      ...voucher,
      voucherId: `ord_8Kd2_${String(index + 1)}`,
    }));
    expect(issueVouchersInput.safeParse({ vouchers: twenty }).success).toBe(true);
    expect(issueVouchersInput.safeParse({ vouchers: [] }).success).toBe(false);
    const many = [...twenty, { ...voucher, voucherId: 'ord_8Kd2_21' }];
    expect(issueVouchersInput.safeParse({ vouchers: many }).success).toBe(false);
  });

  it('accepts a voucher with no partner code and ignores a field it does not know', () => {
    const plain = { ...voucher, attribution: null, addedLater: 'fine' };
    expect(issueVouchersInput.safeParse({ vouchers: [plain] }).success).toBe(true);
  });

  it.each([
    ['an id that is not the order’s', { voucherId: 'other_1' }],
    ['an id with no unit number', { voucherId: 'ord_8Kd2_' }],
    ['an id numbered from zero', { voucherId: 'ord_8Kd2_0' }],
    ['an id with a slash', { voucherId: 'ord/8Kd2_1', orderId: 'ord/8Kd2' }],
    ['days that are not whole', { days: 93.5 }],
    ['no days', { days: 0 }],
    ['a token hash that is not hex SHA-256', { claimTokenHash: 'xyz' }],
    ['a token hash in capitals', { claimTokenHash: 'A'.repeat(64) }],
    ['a very long email', { email: `${'a'.repeat(400)}@b.co` }],
    ['a test flag that is not a boolean', { isTest: 'no' }],
    ['a partner with no id', { attribution: { code: 'THANDI10', partnerId: '' } }],
  ])('refuses %s', (_, change) => {
    expect(issueVouchersInput.safeParse({ vouchers: [{ ...voucher, ...change }] }).success).toBe(
      false,
    );
  });

  it('refuses the same voucher twice in one call', () => {
    expect(issueVouchersInput.safeParse({ vouchers: [voucher, voucher] }).success).toBe(false);
  });
});

describe('voidFrameVoucher', () => {
  it('takes a voucher and one of the two reasons', () => {
    for (const reason of ['refund', 'cancelled']) {
      expect(voidVoucherInput.safeParse({ voucherId: 'ord_1_1', reason }).success).toBe(true);
    }
    expect(voidVoucherInput.safeParse({ voucherId: 'ord_1_1', reason: 'whim' }).success).toBe(
      false,
    );
    expect(voidVoucherInput.safeParse({ reason: 'refund' }).success).toBe(false);
  });
});

describe('the callables’ edges', () => {
  it('premiumVouchersForMe takes nothing', () => {
    expect(premiumVouchersForMeInput.safeParse({}).success).toBe(true);
    expect(premiumVouchersForMeInput.safeParse(null).success).toBe(true);
  });

  it('claimPremiumVoucher refuses an id no voucher could have', () => {
    expect(
      claimPremiumVoucherInput.safeParse({ voucherId: '../x', householdId: 'h1' }).success,
    ).toBe(false);
    expect(
      claimPremiumVoucherInput.safeParse({ voucherId: 'v'.repeat(161), householdId: 'h1' }).success,
    ).toBe(false);
  });

  it('the email flow normalises the address and refuses one that is not', () => {
    expect(sendVoucherEmailCodeInput.parse({ email: ' Sam@Example.COM ' }).email).toBe(
      'sam@example.com',
    );
    expect(sendVoucherEmailCodeInput.safeParse({ email: 'nope' }).success).toBe(false);
    expect(sendVoucherEmailCodeInput.safeParse({ email: `${'a'.repeat(250)}@b.co` }).success).toBe(
      false,
    );
  });

  it('a one-time code is exactly six digits', () => {
    const email = 'sam@example.com';
    expect(verifyVoucherEmailCodeInput.safeParse({ email, code: '012345' }).success).toBe(true);
    for (const code of ['12345', '1234567', '12a456', ' 123456']) {
      expect(verifyVoucherEmailCodeInput.safeParse({ email, code }).success, code).toBe(false);
    }
  });
});
