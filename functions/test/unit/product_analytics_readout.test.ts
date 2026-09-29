import { describe, expect, it } from 'vitest';

import {
  inviteRateLabel,
  readoutTable,
  storedWeeklyTotals,
  type WeeklyTotalsRow,
} from '../../src/product_analytics/beta_numbers_readout';

/**
 * The table Daniel reads the beta by (`npm run beta-numbers`). Wrong here is a
 * wrong decision about the beta, so the formatting is tested like a rule.
 */

function row(overrides: Partial<WeeklyTotalsRow> = {}): WeeklyTotalsRow {
  return storedWeeklyTotals.parse({ week: '2026-W40', weekStart: '2026-09-28', ...overrides });
}

describe('the invite rate as printed', () => {
  it('is a whole percentage of the new families', () => {
    expect(inviteRateLabel(row({ newFamilies: 3, newFamiliesInvitingAnAdult: 2 }))).toBe('67%');
    expect(inviteRateLabel(row({ newFamilies: 4, newFamiliesInvitingAnAdult: 0 }))).toBe('0%');
  });

  it('is a dash when nobody new joined, not a 0% that reads as failure', () => {
    expect(inviteRateLabel(row())).toBe('—');
  });
});

describe('a weekly totals document', () => {
  it('reads a missing count as zero, so an older document still prints', () => {
    const parsed = row();
    expect(parsed.activeFamilies).toBe(0);
    expect(parsed.isInviteCohortComplete).toBe(false);
  });

  it('refuses a count that is not a whole number', () => {
    expect(
      storedWeeklyTotals.safeParse({
        week: '2026-W40',
        weekStart: '2026-09-28',
        activeFamilies: 1.5,
      }).success,
    ).toBe(false);
  });
});

describe('the table', () => {
  it('has a heading, a rule and one row per week, in the order given', () => {
    const table = readoutTable([
      row({ week: '2026-W41', weekStart: '2026-10-05', activeFamilies: 12, familiesSeen: 20 }),
      row({ activeFamilies: 9, isInviteCohortComplete: true }),
    ]);
    const lines = table.split('\n');
    expect(lines[0]).toMatch(/^Week\s+Starts\s+Active families/);
    expect(lines[1]).toMatch(/^-+ {2}-+/);
    expect(lines[2]).toMatch(/^2026-W41\s+2026-10-05\s+12\s+20/);
    expect(lines[3]).toMatch(/^2026-W40\s+2026-09-28\s+9\s+/);
  });

  it('keeps the columns aligned whatever the width of a number', () => {
    const lines = readoutTable([
      row({ activeFamilies: 1234, isInviteCohortComplete: true }),
      row({ activeFamilies: 5, isInviteCohortComplete: true }),
    ]).split('\n');
    const column = (line: string | undefined): number => (line ?? '').indexOf('Families seen');
    const heading = column(lines[0]);
    expect(heading).toBeGreaterThan(0);
    expect((lines[2] ?? '').slice(heading, heading + 1)).toMatch(/\d/);
    expect((lines[3] ?? '').slice(heading, heading + 1)).toMatch(/\d/);
  });

  it('marks a cohort that is still counting, and explains the mark once', () => {
    const table = readoutTable([row({ newFamilies: 2, newFamiliesInvitingAnAdult: 1 })]);
    expect(table).toContain('50% *');
    expect(table).toContain('* still counting');
    expect(readoutTable([row({ newFamilies: 2, isInviteCohortComplete: true })])).not.toContain(
      'still counting',
    );
  });

  it('marks nothing as still counting when nobody new joined — there is no rate to move', () => {
    const table = readoutTable([row()]);
    expect(table).not.toContain('*');
  });

  it('says there is nothing yet, and when there will be, rather than printing an empty grid', () => {
    expect(readoutTable([])).toContain('rollup runs nightly');
  });
});
