import {
  Timestamp,
  type CollectionReference,
  type DocumentReference,
} from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { GROCERY_ITEM_KEYS } from '../../src/assistants/mcp/grocery_documents';
import {
  addGroceryItems,
  getGroceryList,
  removeGroceryItems,
  tickGroceryItems,
  updateGroceryItem,
} from '../../src/assistants/mcp/tools/groceries';
import {
  HOUSEHOLD,
  NOW,
  PAT,
  SAM,
  givenTheOakStreetNest,
  principalFor,
} from './assistants_mcp_fixture';
import { adminDb, clearFirestore } from './emulator_harness';

/**
 * The grocery tools against a real Firestore (assistants ADR-0001,
 * ADR-0005): typed items in the app's shape, deduplicated by the app's
 * normalised name in one transaction, ticked and removed only as the rules
 * allow, an activity line per item.
 */

const household = (): DocumentReference => adminDb().collection('households').doc(HOUSEHOLD);
const items = (): CollectionReference => household().collection('groceryItems');
const sam = principalFor(SAM);
const pat = principalFor(PAT);

const PICK = {
  retailer: 'checkers',
  productId: '0123456789abcdef01234567',
  articleCode: '10001',
  unitOfMeasure: 'EA',
  name: 'Clover milk 2 L',
  brand: 'Clover',
  priceCents: 3499,
  currency: 'ZAR',
  imageId: null,
  pickedBy: PAT.member,
  pickedAt: Timestamp.now(),
};

/** An item a person added in the app, as the app writes one. */
async function givenItem(
  id: string,
  fields: { name: string; addedBy: string; bought?: boolean; quantity?: string; planned?: boolean },
): Promise<void> {
  await items()
    .doc(id)
    .set({
      name: fields.name,
      quantity: fields.quantity ?? null,
      addedBy: fields.addedBy,
      addedAt: Timestamp.fromDate(new Date('2026-10-28T08:00:00Z')),
      boughtAt: fields.bought === true ? Timestamp.now() : null,
      boughtBy: fields.bought === true ? fields.addedBy : null,
      sourceKey: fields.planned === true ? fields.name.toLowerCase() : null,
      sourceWeek: fields.planned === true ? '2026-W44' : null,
      sourceNote: fields.planned === true ? 'For 5 lunches' : null,
    });
}

async function item(id: string): Promise<Record<string, unknown>> {
  return (await items().doc(id).get()).data() ?? {};
}

beforeEach(async () => {
  await clearFirestore();
  await givenTheOakStreetNest();
});

describe('add_grocery_items', () => {
  it("writes a typed item in the app's exact shape, in the caller's name, with the assistant", async () => {
    const answer = await addGroceryItems.run(
      adminDb(),
      sam,
      { items: [{ name: 'Taco shells', quantity: '2 boxes' }] },
      NOW,
    );
    expect(answer.added).toHaveLength(1);
    const id = answer.added[0]?.id ?? '';
    const stored = await item(id);
    expect(Object.keys(stored).sort()).toEqual([...GROCERY_ITEM_KEYS, 'addedVia'].sort());
    expect(stored).toMatchObject({
      name: 'Taco shells',
      quantity: '2 boxes',
      addedBy: SAM.member,
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
      addedVia: 'claude',
    });
    expect(stored['addedAt']).toBeInstanceOf(Timestamp);
    expect(stored).not.toHaveProperty('productMatch');
    expect(answer.added[0]).toEqual({
      id,
      name: 'Taco shells',
      quantity: '2 boxes',
      bought: false,
      added_by: SAM.member,
      added_via: 'claude',
      from_plans: false,
    });
  });

  it('skips what is still to buy under the same normalised name, in the list and in the call', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: PAT.member });
    await givenItem('eggs', { name: 'Eggs', addedBy: PAT.member, bought: true });
    await givenItem('cheese', { name: 'Cheese', addedBy: PAT.member, planned: true });
    const answer = await addGroceryItems.run(
      adminDb(),
      sam,
      addGroceryItems.input.parse({
        items: [
          { name: '  MILK ' },
          { name: 'Eggs' },
          { name: 'cheese' },
          { name: 'Avocados' },
          { name: 'avocados' },
        ],
      }),
      NOW,
    );
    expect(answer.added.map((added) => added.name)).toEqual(['Eggs', 'Avocados']);
    expect(answer.already_on_list.map((entry) => [entry.requested, entry.item.id])).toEqual([
      ['MILK', 'milk'],
      ['cheese', 'cheese'],
      ['avocados', answer.added[1]?.id],
    ]);
    expect((await items().get()).size).toBe(5);
  });

  it('one activity line per item added, ids only, none for what was already there', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: PAT.member });
    const answer = await addGroceryItems.run(
      adminDb(),
      sam,
      { items: [{ name: 'Milk' }, { name: 'Bread' }, { name: 'Butter' }] },
      NOW,
    );
    const lines = (await household().collection('assistantActivity').get()).docs.map((doc) =>
      doc.data(),
    );
    expect(lines.map((line) => (line['target'] as { id: string }).id).sort()).toEqual(
      answer.added.map((added) => added.id).sort(),
    );
    for (const line of lines) {
      expect(line).toMatchObject({
        tool: 'add_grocery_items',
        memberId: SAM.member,
        via: 'claude',
      });
      expect((line['target'] as { kind: string }).kind).toBe('groceryItem');
    }
    expect(JSON.stringify(lines)).not.toMatch(/Bread|Butter/);
  });

  it('refuses more than 50, an empty list, a name past the limit, and any field it does not know', () => {
    const many = Array.from({ length: 51 }, (_, index) => ({ name: `Item ${String(index)}` }));
    for (const args of [
      { items: many },
      { items: [] },
      { items: [{ name: 'x'.repeat(81) }] },
      { items: [{ name: '   ' }] },
      { items: [{ name: 'Milk', addedBy: PAT.member }] },
      { items: [{ name: 'Milk', productMatch: PICK }] },
      { items: [{ name: 'Milk' }], sourceKey: 'milk' },
    ]) {
      expect(addGroceryItems.input.safeParse(args).success, JSON.stringify(args).slice(0, 80)).toBe(
        false,
      );
    }
    expect(
      addGroceryItems.input.safeParse({
        items: Array.from({ length: 50 }, (_, index) => ({ name: `Item ${String(index)}` })),
      }).success,
    ).toBe(true);
  });
});

describe('get_grocery_list', () => {
  it('is what is still to buy by default, everything with include_bought', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: PAT.member, quantity: '2 L' });
    await givenItem('eggs', { name: 'Eggs', addedBy: PAT.member, bought: true });
    const unbought = await getGroceryList.run(adminDb(), sam, { include_bought: false }, NOW);
    expect(unbought.items).toEqual([
      {
        id: 'milk',
        name: 'Milk',
        quantity: '2 L',
        bought: false,
        added_by: PAT.member,
        added_via: null,
        from_plans: false,
      },
    ]);
    const all = await getGroceryList.run(adminDb(), sam, { include_bought: true }, NOW);
    expect(all.items.map((listed) => listed.id).sort()).toEqual(['eggs', 'milk']);
  });
});

describe('update_grocery_item', () => {
  it('a rename by whoever added it clears the product picked for the old name', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: PAT.member });
    await items().doc('milk').update({ productMatch: PICK });
    await updateGroceryItem.run(adminDb(), pat, { item_id: 'milk', name: 'Oat milk' }, NOW);
    const stored = await item('milk');
    expect(stored['name']).toBe('Oat milk');
    expect(stored).not.toHaveProperty('productMatch');
  });

  it('a quantity change keeps the product', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: PAT.member });
    await items().doc('milk').update({ productMatch: PICK });
    await updateGroceryItem.run(adminDb(), pat, { item_id: 'milk', quantity: '3' }, NOW);
    const stored = await item('milk');
    expect(stored['quantity']).toBe('3');
    expect(stored['productMatch']).toMatchObject({ productId: PICK.productId });
  });

  it("a parent may not change somebody else's item; an admin may; a planned item anybody may, and adopts it", async () => {
    await givenItem('samsmilk', { name: 'Milk', addedBy: SAM.member });
    await expect(
      updateGroceryItem.run(adminDb(), pat, { item_id: 'samsmilk', name: 'Oat milk' }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'notTheAdder' });
    await givenItem('patsbread', { name: 'Bread', addedBy: PAT.member });
    await updateGroceryItem.run(adminDb(), sam, { item_id: 'patsbread', quantity: '2' }, NOW);
    await givenItem('planned', { name: 'Cheese', addedBy: SAM.member, planned: true });
    await updateGroceryItem.run(adminDb(), pat, { item_id: 'planned', quantity: '500 g' }, NOW);
    expect(await item('planned')).toMatchObject({
      quantity: '500 g',
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
      addedBy: SAM.member,
    });
  });

  it('refuses nothing to change, and an id that is not on the list', async () => {
    await expect(
      updateGroceryItem.run(adminDb(), sam, { item_id: 'x' }, NOW),
    ).rejects.toMatchObject({
      reason: 'nothingToChange',
    });
    await expect(
      updateGroceryItem.run(adminDb(), sam, { item_id: 'x', name: 'y' }, NOW),
    ).rejects.toMatchObject({ kind: 'notFound' });
  });
});

describe('tick_grocery_items', () => {
  it('marks bought as the app does, and back, saying what changed', async () => {
    await givenItem('milk', { name: 'Milk', addedBy: SAM.member });
    await givenItem('eggs', { name: 'Eggs', addedBy: SAM.member, bought: true });
    const ticked = await tickGroceryItems.run(
      adminDb(),
      pat,
      { item_ids: ['milk', 'eggs', 'nope'], bought: true },
      NOW,
    );
    expect(ticked).toEqual({ changed: ['milk'], unchanged: ['eggs'], not_found: ['nope'] });
    const stored = await item('milk');
    expect(stored['boughtBy']).toBe(PAT.member);
    expect(stored['boughtAt']).toBeInstanceOf(Timestamp);
    const unticked = await tickGroceryItems.run(
      adminDb(),
      pat,
      { item_ids: ['milk'], bought: false },
      NOW,
    );
    expect(unticked.changed).toEqual(['milk']);
    expect(await item('milk')).toMatchObject({ boughtAt: null, boughtBy: null });
  });
});

describe('remove_grocery_items', () => {
  it('removes only what the rules let this member remove', async () => {
    await givenItem('mine', { name: 'Gum', addedBy: PAT.member });
    await givenItem('sams', { name: 'Beer', addedBy: SAM.member });
    await givenItem('planned', { name: 'Cheese', addedBy: SAM.member, planned: true });
    await givenItem('boughtplanned', {
      name: 'Ham',
      addedBy: SAM.member,
      planned: true,
      bought: true,
    });
    const answer = await removeGroceryItems.run(
      adminDb(),
      pat,
      { item_ids: ['mine', 'sams', 'planned', 'boughtplanned', 'nope'] },
      NOW,
    );
    expect(answer).toEqual({
      removed: ['mine', 'planned'],
      not_allowed: ['sams', 'boughtplanned'],
      not_found: ['nope'],
    });
    expect((await items().get()).docs.map((doc) => doc.id).sort()).toEqual([
      'boughtplanned',
      'sams',
    ]);
  });

  it('an admin removes anything', async () => {
    await givenItem('pats', { name: 'Gum', addedBy: PAT.member, bought: true });
    const answer = await removeGroceryItems.run(adminDb(), sam, { item_ids: ['pats'] }, NOW);
    expect(answer.removed).toEqual(['pats']);
  });

  it('refuses more than 50 ids at once', () => {
    const ids = Array.from({ length: 51 }, (_, index) => `i${String(index)}`);
    expect(removeGroceryItems.input.safeParse({ item_ids: ids }).success).toBe(false);
    expect(tickGroceryItems.input.safeParse({ item_ids: ids }).success).toBe(false);
  });
});
