import { describe, expect, it } from 'vitest';

import {
  ATTRIBUTION_WINDOW_MS,
  attributeConversion,
} from '../../src/product_analytics/conversion_ledger';
import {
  byTriggerLabel,
  conversionRateLabel,
  premiumTable,
} from '../../src/product_analytics/premium_readout';
import { countReferrals } from '../../src/product_analytics/referral_counts';
import {
  storedWeeklyTotals,
  type WeeklyTotalsRow,
} from '../../src/product_analytics/beta_numbers_readout';

/**
 * Free-to-premium conversion by the feature that opened the paywall, and the
 * referral counts beside it (product-analytics ADR-0002).
 */
const BOUGHT = new Date('2026-10-08T10:00:00Z');
const HOUR_MS = 60 * 60 * 1000;

describe('a conversion is attributed', () => {
  it('to the household"s last paywall opening, when it was within seven days', () => {
    expect(
      attributeConversion(
        'direct',
        { trigger: 'prepList', openedAt: new Date(BOUGHT.getTime() - 3 * HOUR_MS) },
        BOUGHT,
      ),
    ).toEqual({ trigger: 'prepList', attribution: 'lastPaywall' });
    expect(
      attributeConversion(
        'direct',
        {
          trigger: 'additionalChild',
          openedAt: new Date(BOUGHT.getTime() - ATTRIBUTION_WINDOW_MS),
        },
        BOUGHT,
      ).trigger,
    ).toBe('additionalChild');
  });

  it('to what the purchase said, once the last opening is older than the window', () => {
    expect(
      attributeConversion(
        'lunchLearning',
        {
          trigger: 'prepList',
          openedAt: new Date(BOUGHT.getTime() - ATTRIBUTION_WINDOW_MS - 1),
        },
        BOUGHT,
      ),
    ).toEqual({ trigger: 'lunchLearning', attribution: 'purchase' });
  });

  it('to what the purchase said when nothing was recorded, or something unreadable was', () => {
    expect(attributeConversion('direct', { trigger: undefined, openedAt: null }, BOUGHT)).toEqual({
      trigger: 'direct',
      attribution: 'purchase',
    });
    expect(
      attributeConversion(
        'direct',
        { trigger: 'somethingNew', openedAt: new Date(BOUGHT.getTime() - HOUR_MS) },
        BOUGHT,
      ).trigger,
    ).toBe('direct');
  });

  it('never to an opening after the purchase', () => {
    expect(
      attributeConversion(
        'direct',
        { trigger: 'prepList', openedAt: new Date(BOUGHT.getTime() + HOUR_MS) },
        BOUGHT,
      ).trigger,
    ).toBe('direct');
  });
});

describe('a week"s referrals as counts', () => {
  it('counts what was redeemed, what qualified, and the months both sides got', () => {
    expect(
      countReferrals(
        [
          { referrerReward: null, referredReward: null },
          { referrerReward: null, referredReward: null },
        ],
        [
          { referrerReward: 'month', referredReward: 'month' },
          { referrerReward: 'capped', referredReward: 'month' },
          { referrerReward: null, referredReward: 'month' },
        ],
      ),
    ).toEqual({ redeemed: 2, qualified: 3, monthsGiven: 4 });
  });
});

function row(overrides: Record<string, unknown> = {}): WeeklyTotalsRow {
  return storedWeeklyTotals.parse({ week: '2026-W41', weekStart: '2026-10-05', ...overrides });
}

describe('the premium table', () => {
  it('prints a rate as bought over families shown, and a dash where nobody was shown', () => {
    expect(conversionRateLabel(1, 4)).toBe('1/4 25%');
    expect(conversionRateLabel(0, 3)).toBe('0/3 0%');
    expect(conversionRateLabel(0, 0)).toBe('—');
    expect(conversionRateLabel(2, 0)).toBe('2/0');
  });

  it('lists only the triggers somebody met or bought through', () => {
    const week = row({
      paywallFamiliesByTrigger: { additionalChild: 4, prepList: 1 },
      premiumConversionsByTrigger: { additionalChild: 1, direct: 1 },
    });
    expect(byTriggerLabel(week)).toBe('additionalChild 1/4 25%, prepList 0/1 0%, direct 1/0');
    expect(byTriggerLabel(row())).toBe('—');
  });

  it('reads an older week with none of these counts as zeros', () => {
    const week = row();
    expect(week.paywallFamilies).toBe(0);
    expect(week.referralMonthsGiven).toBe(0);
  });

  it('has a title, a heading and one row per week with its referrals', () => {
    const table = premiumTable([
      row({
        paywallFamilies: 5,
        premiumConversions: 2,
        referralsRedeemed: 3,
        referralsQualified: 1,
        referralMonthsGiven: 2,
      }),
    ]);
    const lines = table.split('\n');
    expect(lines[0]).toBe('Premium and referrals');
    expect(lines[2]).toMatch(/^Week\s+Met paywall\s+Bought\s+Rate/);
    expect(lines[4]).toMatch(/^2026-W41\s+5\s+2\s+2\/5 40%\s+—\s+3\s+1\s+2$/);
    expect(premiumTable([])).toBe('');
  });
});
