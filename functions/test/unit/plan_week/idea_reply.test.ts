import { describe, expect, it } from 'vitest';

import { ideaBriefFrom, type IdeaBrief } from '../../../src/plan_week/idea_brief';
import { ideasFrom } from '../../../src/plan_week/idea_reply';
import { rulesOf } from './fixtures';

const MONDAY = '2026-10-05';

function briefFor(
  mia = rulesOf({ allergyCodes: ['peanut'], dislikes: ['tomato'], otherAllergies: ['kiwi'] }),
  leo = rulesOf({ schoolIsNutFree: true }),
): IdeaBrief {
  return ideaBriefFrom(
    [
      { memberId: 'mia', rules: mia },
      { memberId: 'leo', rules: leo },
    ],
    [],
    MONDAY,
    40000,
  );
}

function idea(
  slot: string,
  words: string,
  children: string[] = ['child-1', 'child-2'],
): Record<string, unknown> {
  return { slot, idea: words, searchTerm: words, children, why: '' };
}

describe('the ideas the model drafts, checked per child (lunch-box ADR-0012)', () => {
  it('strikes an idea out for a child whose allergen its words name, and says which', () => {
    const [peanut] = ideasFrom({ ideas: [idea('main', 'Peanut butter sandwiches')] }, briefFor());
    expect(peanut?.excluded).toContainEqual({
      childId: 'mia',
      reason: 'allergy',
      allergen: 'peanut',
    });
  });

  it('holds a nut-free school to both nuts', () => {
    const [cashews] = ideasFrom({ ideas: [idea('snack', 'Cashews')] }, briefFor());
    expect(cashews?.childIds).toEqual([]);
    expect(cashews?.excluded).toContainEqual({
      childId: 'leo',
      reason: 'allergy',
      allergen: 'treeNut',
    });
  });

  it('strikes out a free-text allergy and a dislike without naming a code', () => {
    const [kiwi, tomato] = ideasFrom(
      { ideas: [idea('fruit', 'Kiwi fruit'), idea('veg', 'Cherry tomatoes')] },
      briefFor(),
    );
    expect(kiwi?.excluded).toEqual([{ childId: 'mia', reason: 'allergy', allergen: null }]);
    expect(kiwi?.childIds).toEqual(['leo']);
    expect(tomato?.excluded).toEqual([{ childId: 'mia', reason: 'dislike', allergen: null }]);
  });

  it('keeps an idea struck out for everybody, so the phone can show why', () => {
    const ideas = ideasFrom({ ideas: [idea('main', 'Peanut butter')] }, briefFor());
    expect(ideas).toHaveLength(1);
    expect(ideas[0]?.childIds).toEqual([]);
  });

  it('drops an unknown compartment, a repeat, and gives an idea naming nobody to everybody', () => {
    const ideas = ideasFrom(
      {
        ideas: [
          idea('dessert', 'Jelly'),
          idea('fruit', 'Apples', []),
          idea('fruit', 'apples', ['child-1']),
          { nonsense: true },
        ],
      },
      briefFor(),
    );
    expect(ideas.map((entry) => entry.idea)).toEqual(['Apples']);
    expect(ideas[0]?.childIds).toEqual(['mia', 'leo']);
    expect(ideas[0]?.id).toBe('idea-1');
  });
});

describe('what the model is told about a child', () => {
  it('counts open compartments per kind, a treat on Friday only', () => {
    const brief = briefFor();
    expect(brief.children[0]?.open).toEqual({ main: 5, fruit: 5, veg: 5, snack: 5, treat: 1 });
    expect(brief.children[0]?.ref).toBe('child-1');
  });
});
