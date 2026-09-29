import { describe, expect, it } from 'vitest';

import { composeDigest } from '../../../src/notifications/digest_composer';
import { SECTION_ITEM_LIMIT } from '../../../src/notifications/digest_sections';
import { AN_EMPTY_DAY, aBusyDay, person } from './fixtures';

/**
 * The morning digest from fixed data (notifications ADR-0002): what each kind
 * of person is told, and — as much the point — what they are not.
 */

function kinds(memberId: string): string[] {
  return composeDigest(aBusyDay(), person(memberId))?.sections.map((section) => section.kind) ?? [];
}

function texts(memberId: string, kind: string): string[] {
  const section = composeDigest(aBusyDay(), person(memberId))?.sections.find(
    (candidate) => candidate.kind === kind,
  );
  return section?.items.map((item) => `${item.text} | ${item.detail ?? ''}`) ?? [];
}

describe('a parent', () => {
  it('gets every section, in the order a morning reads', () => {
    expect(kinds('m-sam')).toEqual(['events', 'pack', 'chores', 'documents', 'shift', 'approvals']);
  });

  it('sees the day’s events with their times and people, all-day first', () => {
    expect(texts('m-sam', 'events')).toEqual([
      'Doctor for Leo | All day · Leo',
      'School run | 07:15 · You, Mia',
      'Swimming lesson | 15:00 · Leo',
    ]);
  });

  it('packs each child’s lunch box and the kit today’s events call for', () => {
    expect(texts('m-sam', 'pack')).toEqual([
      'Mia’s lunch box | Cheese sandwich · Apple',
      'Leo’s lunch box | Wrap · Carrots',
      'Swimming kit | Leo · Swimming lesson at 15:00',
    ]);
  });

  it('lists their own chores first', () => {
    expect(texts('m-sam', 'chores')).toEqual([
      'Bins out | For you',
      'Make your bed | For Mia',
      'Water the plants | For anyone',
    ]);
  });

  it('names a household document, and never a vault one', () => {
    expect(texts('m-sam', 'documents')).toEqual([
      'Leo passport | Expires in 12 days',
      'A document in your vault | Expires in 2 days',
    ]);
  });

  it('hears who is on shift and that a handover is waiting', () => {
    expect(texts('m-sam', 'shift')).toEqual([
      'Nomsa is on shift | Since 07:10',
      'Handover from Nomsa | 6 moments logged',
    ]);
  });

  it('is told what waits on their check', () => {
    expect(texts('m-sam', 'approvals')).toEqual([
      '2 chores to check | Stars wait for your look',
      '1 reward asked for | Hand it over when it happens',
    ]);
  });
});

describe('the lock screen', () => {
  it('carries counts and kinds only — no names, titles, foods or documents', () => {
    const digest = composeDigest(aBusyDay(), person('m-sam'));
    expect(digest?.push.title).toBe('Your Tuesday at a glance');
    expect(digest?.push.body).toBe(
      '3 events · 3 things to pack · 3 chores · 2 documents to renew · 2 shift updates · 2 things to check',
    );
    const lockScreen = `${digest?.push.title ?? ''} ${digest?.push.body ?? ''}`;
    for (const secret of ['Leo', 'Mia', 'Nomsa', 'Cheese', 'passport', 'Doctor', 'Swimming']) {
      expect(lockScreen).not.toContain(secret);
    }
  });
});

describe('what a grant keeps out (household ADR-0003)', () => {
  it('a helper who only cleans gets no digest at all', () => {
    expect(composeDigest(aBusyDay(), person('m-thandi'))).toBeNull();
  });

  it('a carer sees the day and the lunches, their own shift, and none of the family’s business', () => {
    // `own` to-dos: only what is theirs, and nothing today is — so no
    // chores section, and no documents, handovers or approvals either.
    expect(kinds('m-nomsa')).toEqual(['events', 'pack', 'shift']);
    expect(texts('m-nomsa', 'shift')).toEqual(['You are on shift | Since 07:10']);
  });

  it('a kid tablet gets its own lunch and its own chores, and no documents', () => {
    expect(kinds('m-mia')).toEqual(['events', 'pack', 'chores']);
    expect(texts('m-mia', 'pack')).toEqual([
      'Your lunch box | Cheese sandwich · Apple',
      'Swimming kit | Leo · Swimming lesson at 15:00',
    ]);
    expect(texts('m-mia', 'chores')).toEqual(['Make your bed | For you']);
  });
});

describe('a day with nothing on it', () => {
  it('sends nothing — decided, not accidental (ADR-0002)', () => {
    expect(composeDigest(AN_EMPTY_DAY, person('m-sam'))).toBeNull();
  });

  it('a weekend with only a chore is still a digest', () => {
    const digest = composeDigest(
      { ...AN_EMPTY_DAY, chores: [{ title: 'Bins out', assigneeIds: ['m-pat'] }] },
      person('m-pat'),
    );
    expect(digest?.push.body).toBe('1 chore');
  });
});

describe('a long day', () => {
  it('shows a bounded section and says how many more', () => {
    const events = Array.from({ length: 12 }, (_, index) => ({
      title: `Event ${String(index)}`,
      startMinute: 8 * 60 + index,
      memberIds: [],
    }));
    const digest = composeDigest({ ...AN_EMPTY_DAY, events }, person('m-sam'));
    const section = digest?.sections[0];
    expect(section?.items).toHaveLength(SECTION_ITEM_LIMIT);
    expect(section?.items.at(-1)?.text).toBe('And 5 more');
    expect(section?.total).toBe(12);
    expect(digest?.push.body).toBe('12 events');
  });
});
