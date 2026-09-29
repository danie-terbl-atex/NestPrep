/**
 * How a household's premium is composed from what a store sold it and what
 * it was given (subscriptions ADR-0002). Pure: the transaction that restates
 * the entitlement reads the inputs and writes what this answers.
 *
 * A grant — thirty days for a referral — **starts** at the first moment after
 * it was granted that the household was not otherwise covered, and then runs
 * its days whatever happens. Until then it waits. So a free household's month
 * starts at once, and a paying household's is queued after its paid time and
 * runs only if the subscription stops. Because the waiting days are already
 * in `premiumUntil`, premium runs on without a gap at a lapse that nobody
 * noticed; the next restatement writes down when the waiting month began.
 */
export interface PremiumGrant {
  readonly id: string;
  readonly days: number;
  readonly grantedAt: Date;
  /** When it began running, or null while it waits. Written once, never moved. */
  readonly startsAt: Date | null;
}

export interface PremiumSources {
  /** Premium from the stores alone (subscriptions ADR-0001), or null. */
  readonly storeUntil: Date | null;
  readonly grants: readonly PremiumGrant[];
  /**
   * What the last restatement wrote: from when waiting days began, and the
   * premium it granted. Null on a household never restated with grants in
   * mind — its old `premiumUntil` then stands in for both.
   */
  readonly previous: { readonly referralFrom: Date | null; readonly premiumUntil: Date | null };
}

export interface ComposedPremium {
  readonly premiumUntil: Date | null;
  readonly storeUntil: Date | null;
  /** The end of what grants cover, or null when they cover nothing from now. */
  readonly referralUntil: Date | null;
  /** Days granted that have not begun, queued after everything else. */
  readonly referralDaysWaiting: number;
  /** The instant those waiting days begin: now, or when current cover ends. */
  readonly referralFrom: Date;
  /** Grants that have begun since the last restatement, and when. */
  readonly started: Readonly<Record<string, Date>>;
}

export const DAY_MS = 24 * 60 * 60 * 1000;

export function composePremium(sources: PremiumSources, now: Date): ComposedPremium {
  const started = startedSince(sources, now);
  const runningEnds = sources.grants.flatMap((grant) => {
    const start = grant.startsAt ?? started[grant.id];
    return start === undefined ? [] : [endOf(start, grant.days)];
  });
  const waiting = sources.grants.filter(
    (grant) => grant.startsAt === null && started[grant.id] === undefined,
  );
  const grantsEnd = latest(runningEnds);
  const covered = latest([sources.storeUntil, grantsEnd]);
  const referralFrom = latest([covered, now]) ?? now;
  const referralDaysWaiting = waiting.reduce((total, grant) => total + grant.days, 0);

  if (referralDaysWaiting > 0) {
    const until = endOf(referralFrom, referralDaysWaiting);
    return {
      premiumUntil: until,
      storeUntil: sources.storeUntil,
      referralUntil: until,
      referralDaysWaiting,
      referralFrom,
      started,
    };
  }
  return {
    premiumUntil: isAfter(covered, now) ? covered : null,
    storeUntil: sources.storeUntil,
    referralUntil: isAfter(grantsEnd, now) ? grantsEnd : null,
    referralDaysWaiting: 0,
    referralFrom,
    started,
  };
}

/**
 * The waiting grants that the *previous* restatement's cover says have begun
 * by [now], each starting where the one before it ended — measured against
 * what was true then, not against a store answer that has just arrived, so a
 * renewal cannot slide a month that was already running.
 */
function startedSince(sources: PremiumSources, now: Date): Record<string, Date> {
  const { previous } = sources;
  let cursor = previous.referralFrom ?? latest([previous.premiumUntil, now]) ?? now;
  const runningEnd = latest(
    sources.grants.flatMap((grant) =>
      grant.startsAt === null ? [] : [endOf(grant.startsAt, grant.days)],
    ),
  );
  cursor = latest([cursor, runningEnd]) ?? cursor;

  const started: Record<string, Date> = {};
  const waiting = sources.grants
    .filter((grant) => grant.startsAt === null)
    .sort((a, b) => a.grantedAt.getTime() - b.grantedAt.getTime() || a.id.localeCompare(b.id));
  for (const grant of waiting) {
    const start = latest([cursor, grant.grantedAt]) ?? cursor;
    if (start.getTime() > now.getTime()) break;
    started[grant.id] = start;
    cursor = endOf(start, grant.days);
  }
  return started;
}

function endOf(start: Date, days: number): Date {
  return new Date(start.getTime() + days * DAY_MS);
}

function latest(dates: readonly (Date | null | undefined)[]): Date | null {
  let best: Date | null = null;
  for (const date of dates) {
    if (date !== null && date !== undefined && (best === null || date > best)) best = date;
  }
  return best;
}

function isAfter(date: Date | null, now: Date): date is Date {
  return date !== null && date.getTime() > now.getTime();
}
