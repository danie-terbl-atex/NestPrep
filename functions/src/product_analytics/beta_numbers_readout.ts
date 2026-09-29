import { z } from 'zod';

/**
 * The table `npm run beta-numbers` prints: one row per week, newest first
 * (product-analytics ADR-0001). It is here, in the typed program, so the
 * formatting is tested; `tools/beta-numbers.mjs` only reads Firestore and
 * hands the documents to this.
 */

const count = z.number().int().nonnegative();

/** A weekly totals document as the readout reads it; missing counts read as zero (`BE-10`). */
export const storedWeeklyTotals = z.object({
  week: z.string(),
  weekStart: z.string(),
  activeFamilies: count.default(0),
  familiesSeen: count.default(0),
  lunchPlansCreated: count.default(0),
  familiesPlanningLunches: count.default(0),
  newFamilies: count.default(0),
  newFamiliesInvitingAnAdult: count.default(0),
  isInviteCohortComplete: z.boolean().default(false),
  // Premium and referrals (product-analytics ADR-0002); absent before it.
  paywallFamilies: count.default(0),
  paywallFamiliesByTrigger: z.record(z.string(), count).default({}),
  premiumConversions: count.default(0),
  premiumConversionsByTrigger: z.record(z.string(), count).default({}),
  referralsRedeemed: count.default(0),
  referralsQualified: count.default(0),
  referralMonthsGiven: count.default(0),
});
export type WeeklyTotalsRow = z.infer<typeof storedWeeklyTotals>;

/** The invite rate as a person reads it: a whole percentage, or a dash when nobody new joined. */
export function inviteRateLabel(row: WeeklyTotalsRow): string {
  if (row.newFamilies === 0) return '—';
  const percent = Math.round((row.newFamiliesInvitingAnAdult / row.newFamilies) * 100);
  return `${String(percent)}%`;
}

/** A rate that can still move: a cohort with families in it, not all through their first week. */
function isStillCounting(row: WeeklyTotalsRow): boolean {
  return row.newFamilies > 0 && !row.isInviteCohortComplete;
}

const HEADINGS = [
  'Week',
  'Starts',
  'Active families',
  'Families seen',
  'Lunch plans',
  'Families planning',
  'New families',
  'Invited an adult',
  'Invite rate',
] as const;

function cells(row: WeeklyTotalsRow): string[] {
  return [
    row.week,
    row.weekStart,
    String(row.activeFamilies),
    String(row.familiesSeen),
    String(row.lunchPlansCreated),
    String(row.familiesPlanningLunches),
    String(row.newFamilies),
    String(row.newFamiliesInvitingAnAdult),
    `${inviteRateLabel(row)}${isStillCounting(row) ? ' *' : ''}`,
  ];
}

/** The whole table, aligned, with the footnote when any cohort is still counting. */
export function readoutTable(rows: readonly WeeklyTotalsRow[]): string {
  if (rows.length === 0) {
    return 'No weekly totals yet. The rollup runs nightly at 03:00 Johannesburg time.';
  }
  const lines = alignedTable(HEADINGS, rows.map(cells));
  if (rows.some(isStillCounting)) {
    lines.push('', '* still counting: some families in that cohort are inside their first week.');
  }
  return lines.join('\n');
}

/** Columns padded to their widest cell, with a rule under the headings. */
export function alignedTable(headings: readonly string[], rows: readonly string[][]): string[] {
  const table = [[...headings], ...rows];
  const widths = headings.map((_, column) =>
    Math.max(...table.map((line) => (line[column] ?? '').length)),
  );
  const lines = table.map((line) =>
    line
      .map((cell, column) => cell.padEnd(widths[column] ?? 0))
      .join('  ')
      .trimEnd(),
  );
  lines.splice(1, 0, widths.map((width) => '-'.repeat(width)).join('  '));
  return lines;
}
