import { alignedTable, type WeeklyTotalsRow } from './beta_numbers_readout';
import { CONVERSION_TRIGGERS } from './conversion_ledger';

/**
 * The second table `npm run beta-numbers` prints: premium and referrals, one
 * row per week (product-analytics ADR-0002). A rate is conversions over the
 * families that met the paywall — per trigger, and overall — and a trigger
 * nobody met is left out rather than printed as a 0% that never happened.
 */

/** A conversion rate as a person reads it: "1/4 25%", or a dash when nobody met it. */
export function conversionRateLabel(conversions: number, families: number): string {
  if (families === 0) return conversions === 0 ? '—' : `${String(conversions)}/0`;
  const percent = Math.round((conversions / families) * 100);
  return `${String(conversions)}/${String(families)} ${String(percent)}%`;
}

/** Every trigger somebody met or bought through that week, with its rate. */
export function byTriggerLabel(row: WeeklyTotalsRow): string {
  const parts = CONVERSION_TRIGGERS.flatMap((trigger) => {
    const families = row.paywallFamiliesByTrigger[trigger] ?? 0;
    const conversions = row.premiumConversionsByTrigger[trigger] ?? 0;
    if (families === 0 && conversions === 0) return [];
    return [`${trigger} ${conversionRateLabel(conversions, families)}`];
  });
  return parts.length === 0 ? '—' : parts.join(', ');
}

const HEADINGS = [
  'Week',
  'Met paywall',
  'Bought',
  'Rate',
  'By trigger',
  'Referred',
  'Qualified',
  'Months given',
] as const;

function cells(row: WeeklyTotalsRow): string[] {
  return [
    row.week,
    String(row.paywallFamilies),
    String(row.premiumConversions),
    conversionRateLabel(row.premiumConversions, row.paywallFamilies),
    byTriggerLabel(row),
    String(row.referralsRedeemed),
    String(row.referralsQualified),
    String(row.referralMonthsGiven),
  ];
}

export function premiumTable(rows: readonly WeeklyTotalsRow[]): string {
  if (rows.length === 0) return '';
  return ['Premium and referrals', '', ...alignedTable(HEADINGS, rows.map(cells))].join('\n');
}
