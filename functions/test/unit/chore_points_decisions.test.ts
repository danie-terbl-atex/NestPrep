import { describe, expect, it } from 'vitest';

import { decideClaim, type ClaimFacts } from '../../src/chore_points/chore_eligibility';
import { applyLine, type LedgerLine } from '../../src/chore_points/point_ledger';
import type { StoredBalance, StoredTask } from '../../src/chore_points/point_documents';
import { decideReservation } from '../../src/chore_points/reward_reservation';
import { NO_STREAK, nextStreak } from '../../src/chore_points/streak';
import { reviewChoreInput, settleRewardInput } from '../../src/chore_points/schemas';
import { parseInput } from '../../src/household/parse_input';
import { HttpsError } from 'firebase-functions/v2/https';

/**
 * The decisions behind a child's stars (todos ADR-0003), each pure and each a
 * way a child's own device could otherwise mint them.
 */

const TODAY = '2026-09-29';

const task = (overrides: Partial<StoredTask> = {}): StoredTask => ({
  title: 'Make your bed',
  dueDate: '2026-09-01',
  recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: null },
  assigneeIds: ['m-mia'],
  routineId: null,
  points: 5,
  needsApproval: false,
  ...overrides,
});

const facts = (overrides: Partial<ClaimFacts> = {}): ClaimFacts => ({
  completion: {
    taskId: 't-bed',
    occurrenceDate: TODAY,
    completedBy: 'm-mia',
    completedFor: 'm-mia',
  },
  task: task(),
  routine: undefined,
  forRole: 'kid',
  byRole: 'kid',
  today: TODAY,
  ...overrides,
});

describe('whether a completion earns stars', () => {
  it('a kid ticking today’s starred chore earns them at once', () => {
    expect(decideClaim(facts())).toEqual({
      memberId: 'm-mia',
      taskId: 't-bed',
      occurrenceDate: TODAY,
      title: 'Make your bed',
      points: 5,
      completedBy: 'm-mia',
      awardsAtOnce: true,
    });
  });

  it('a chore that needs a check waits for a parent', () => {
    const decided = decideClaim(facts({ task: task({ needsApproval: true }) }));
    expect(decided).toMatchObject({ awardsAtOnce: false });
  });

  it('but not when a parent ticked it for the child', () => {
    const decided = decideClaim(
      facts({
        task: task({ needsApproval: true }),
        completion: { ...facts().completion, completedBy: 'm-sam' },
        byRole: 'admin',
      }),
    );
    expect(decided).toMatchObject({ memberId: 'm-mia', awardsAtOnce: true });
  });

  it('the legacy `member` role is family too', () => {
    const decided = decideClaim(facts({ task: task({ needsApproval: true }), byRole: 'member' }));
    expect(decided).toMatchObject({ awardsAtOnce: true });
  });

  it('earns nothing for a chore with no stars, or one that is gone', () => {
    expect(decideClaim(facts({ task: task({ points: 0 }) }))).toBe('noStars');
    expect(decideClaim(facts({ task: undefined }))).toBe('noTask');
  });

  it('only kids earn', () => {
    expect(decideClaim(facts({ forRole: 'parent' }))).toBe('notAKid');
    expect(decideClaim(facts({ forRole: 'helper' }))).toBe('notAKid');
    expect(decideClaim(facts({ forRole: undefined }))).toBe('notAKid');
  });

  it('refuses a day that is not one of the chore’s days', () => {
    const weekly = task({
      dueDate: '2026-09-26',
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [], until: null },
    });
    expect(decideClaim(facts({ task: weekly }))).toBe('notAnOccurrence');
  });

  it('refuses tomorrow, and anything more than a week back', () => {
    const at = (occurrenceDate: string): ReturnType<typeof decideClaim> =>
      decideClaim(facts({ completion: { ...facts().completion, occurrenceDate } }));
    expect(at('2026-09-30')).toBe('inTheFuture');
    expect(at('2026-09-21')).toBe('tooLongAgo');
    expect(at('2026-09-22')).toMatchObject({ occurrenceDate: '2026-09-22' });
  });

  it('a chore in a routine follows the routine’s schedule, not its own', () => {
    const inRoutine = task({ routineId: 'r-laundry', recurrence: null, dueDate: '2026-09-01' });
    const saturdays = {
      firstDate: '2026-09-26',
      recurrence: { frequency: 'weekly' as const, interval: 1, weekdays: [], until: null },
      defaultAssigneeIds: [],
    };
    const on = (occurrenceDate: string): ReturnType<typeof decideClaim> =>
      decideClaim(
        facts({
          task: inRoutine,
          routine: saturdays,
          completion: { ...facts().completion, occurrenceDate },
        }),
      );
    expect(on('2026-09-26')).toMatchObject({ points: 5 });
    expect(on('2026-09-29')).toBe('notAnOccurrence');
  });

  it('a routine that is gone leaves the chore its own schedule, as the app does', () => {
    const orphan = task({ routineId: 'r-gone' });
    expect(decideClaim(facts({ task: orphan, routine: undefined }))).toMatchObject({ points: 5 });
  });
});

describe('the streak', () => {
  it('starts at one, and the same day leaves it', () => {
    const first = nextStreak(NO_STREAK, TODAY);
    expect(first).toEqual({ streakDays: 1, bestStreak: 1, streakLastDay: TODAY });
    expect(nextStreak(first, TODAY)).toBe(first);
  });

  it('grows on the next day and starts again after a gap, keeping the best', () => {
    const three = { streakDays: 3, bestStreak: 3, streakLastDay: '2026-09-28' };
    expect(nextStreak(three, TODAY)).toEqual({
      streakDays: 4,
      bestStreak: 4,
      streakLastDay: TODAY,
    });
    expect(nextStreak(three, '2026-10-01')).toEqual({
      streakDays: 1,
      bestStreak: 3,
      streakLastDay: '2026-10-01',
    });
  });

  it('crosses a month end', () => {
    const lastOfMonth = { streakDays: 2, bestStreak: 2, streakLastDay: '2026-09-30' };
    expect(nextStreak(lastOfMonth, '2026-10-01').streakDays).toBe(3);
  });
});

describe('a ledger line and the balance it leads to', () => {
  const empty: StoredBalance = { balance: 0, earned: 0, spent: 0, ...NO_STREAK };
  const line = (overrides: Partial<LedgerLine>): LedgerLine => ({
    entryId: 'e',
    memberId: 'm-mia',
    delta: 5,
    kind: 'chore',
    sourceId: 's',
    title: 'Make your bed',
    ...overrides,
  });

  it('a chore adds to the balance and to what was earned, and moves the streak', () => {
    expect(applyLine(empty, line({ earnedOn: TODAY }))).toEqual({
      balance: 5,
      earned: 5,
      spent: 0,
      streakDays: 1,
      bestStreak: 1,
      streakLastDay: TODAY,
    });
  });

  it('an untick takes back exactly that, and leaves the streak', () => {
    const after = applyLine(
      applyLine(empty, line({ earnedOn: TODAY })),
      line({ delta: -5, kind: 'choreUndone' }),
    );
    expect(after).toMatchObject({ balance: 0, earned: 0, spent: 0, streakDays: 1 });
  });

  it('a reward spends, and a declined one comes back', () => {
    const rich = { ...empty, balance: 30, earned: 30 };
    const spent = applyLine(rich, line({ delta: -20, kind: 'reward' }));
    expect(spent).toMatchObject({ balance: 10, earned: 30, spent: 20 });
    expect(applyLine(spent, line({ delta: 20, kind: 'rewardReturned' }))).toMatchObject({
      balance: 30,
      spent: 0,
    });
  });

  it('the balance is always the sum of the lines', () => {
    const lines = [
      line({ delta: 5, earnedOn: TODAY }),
      line({ delta: 10, earnedOn: TODAY }),
      line({ delta: -5, kind: 'choreUndone' }),
      line({ delta: -8, kind: 'reward' }),
      line({ delta: 8, kind: 'rewardReturned' }),
      line({ delta: -3, kind: 'reward' }),
    ];
    const final = lines.reduce(applyLine, empty);
    expect(final.balance).toBe(lines.reduce((sum, each) => sum + each.delta, 0));
    expect(final.earned - final.spent).toBe(final.balance);
  });
});

describe('whether a reward can be had', () => {
  const reward = { title: 'Ice cream', cost: 20, icon: 'iceCream' };
  const balance = (stars: number): StoredBalance => ({
    balance: stars,
    earned: stars,
    spent: 0,
    ...NO_STREAK,
  });

  it('reserves when the child has enough, exactly or more', () => {
    expect(decideReservation({ reward, memberRole: 'kid', balance: balance(20) })).toBe('reserve');
    expect(decideReservation({ reward, memberRole: 'kid', balance: balance(99) })).toBe('reserve');
  });

  it('refuses one star short', () => {
    expect(decideReservation({ reward, memberRole: 'kid', balance: balance(19) })).toBe(
      'notEnoughPoints',
    );
  });

  it('refuses a reward that is gone, and anybody who is not a kid', () => {
    expect(decideReservation({ reward: undefined, memberRole: 'kid', balance: balance(99) })).toBe(
      'rewardGone',
    );
    expect(decideReservation({ reward, memberRole: 'parent', balance: balance(99) })).toBe(
      'notAKid',
    );
  });
});

describe('the callables’ edges', () => {
  it('refuse a decision they do not know', () => {
    expect(() =>
      parseInput(reviewChoreInput, { householdId: 'h1', completionId: 'c', decision: 'award' }),
    ).toThrow(HttpsError);
    expect(() =>
      parseInput(settleRewardInput, { householdId: 'h1', requestId: 'r', decision: 'refund' }),
    ).toThrow(HttpsError);
  });
});
