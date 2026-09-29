import {
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { KID, MIA, NOMSA, SAM, STRANGER } from './family_fixture';
import {
  APPLE,
  MONDAY,
  PEANUT_BUTTER,
  TRAIL_MIX,
  WEEK,
  WRAP,
  YOGHURT,
  ZOLA,
  givenTheLunchHousehold,
  kidsTablet,
  pick,
  planOf,
  planPath,
} from './lunch_box_fixture';
import { CHOICES } from './lunch_planning_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * Kid picks (lunch-box ADR-0008). A parent approves two or three options per
 * compartment — and the rules refuse an option that is not safe for the
 * child. The child (`m-kid`, on the kid tablet with lunch at `own`) writes
 * their choice into their own plan, **and only one of the approved options**:
 * nothing else, nothing cleared, nobody else's plan. The allergy check still
 * holds on that write.
 */

const BANANA = pick('banana', 'Banana');
const GRAPES = pick('grapes', 'Grapes');
const CHEESE = pick('cheese', 'Cheese sandwich', ['milk', 'wheat']);

const choicesPath = (childId: string): string => `${CHOICES}/${childId}_${WEEK}`;

/** A parent's write of one day's options — `editedDay` names the day. */
const choicesOf = (childId: string, editedDay: string, options: object): object => ({
  childId,
  week: WEEK,
  options,
  chosen: {},
  editedDay,
  updatedBy: 'm-sam',
  updatedAt: serverTimestamp(),
});

/** What a day's option change sends as an update. */
const dayUpdate = (editedDay: string, changes: object): object => ({
  ...changes,
  editedDay,
  updatedBy: 'm-sam',
  updatedAt: serverTimestamp(),
});

async function givenOptions(childId: string, options: object): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, choicesPath(childId)), {
      childId,
      week: WEEK,
      options,
      chosen: {},
      editedDay: '1',
      updatedBy: 'm-sam',
      updatedAt: new Date(),
    });
  });
}

/** The chooser's batch: the plan's slot, and the choice recorded as theirs. */
async function choose(
  db: Awaited<ReturnType<typeof kidsTablet>>,
  childId: string,
  key: string,
  option: object,
): Promise<void> {
  const batch = writeBatch(db);
  batch.set(
    doc(db, planPath(childId)),
    { childId, week: WEEK, weekStart: MONDAY, slots: { [key]: option } },
    { mergeFields: ['childId', 'week', 'weekStart', `slots.${key}`] },
  );
  batch.update(doc(db, choicesPath(childId)), {
    [`chosen.${key}`]: (option as { itemId: string }).itemId,
    chosenKey: key,
  });
  await batch.commit();
}

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
});

describe('lunchChoices/{childId}_{week}: a parent approves the options', () => {
  it('two or three safe things per compartment, in their own name', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), choicesPath(KID)),
        choicesOf(KID, '2', { '2_fruit': [APPLE, BANANA], '2_main': [WRAP, BANANA, GRAPES] }),
      ),
    );
    await assertSucceeds(
      setDoc(doc(await asUser(MIA), choicesPath(ZOLA)), {
        ...choicesOf(ZOLA, '1', { '1_main': [PEANUT_BUTTER, WRAP] }),
        updatedBy: 'm-mia',
      }),
    );
  });

  it('a whole day of options, three to a compartment, fits the rules’ budget', async () => {
    // Suggest options writes a day at a time: five compartments of three
    // for the child with the most rules to check is the heaviest write.
    const three = [APPLE, BANANA, GRAPES];
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), choicesPath(KID)),
        choicesOf(KID, '4', {
          '4_main': [WRAP, BANANA, GRAPES],
          '4_fruit': three,
          '4_veg': three,
          '4_snack': three,
          '4_treat': three,
        }),
      ),
    );
  });

  it('refuses an option the child must avoid — their allergy, their school’s nuts', async () => {
    const db = await asUser(SAM);
    for (const unsafe of [PEANUT_BUTTER, TRAIL_MIX, YOGHURT]) {
      await assertFails(
        setDoc(doc(db, choicesPath(KID)), choicesOf(KID, '3', { '3_main': [WRAP, unsafe] })),
      );
    }
  });

  it('refuses an unsafe option added to a slot later, and one or four options', async () => {
    await givenOptions(KID, { '1_fruit': [APPLE, BANANA] });
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(
        doc(db, choicesPath(KID)),
        dayUpdate('4', { 'options.4_snack': [APPLE, TRAIL_MIX] }),
      ),
    );
    for (const count of [[APPLE], [APPLE, BANANA, GRAPES, WRAP]]) {
      await assertFails(
        updateDoc(doc(db, choicesPath(KID)), dayUpdate('4', { 'options.4_snack': count })),
      );
    }
    await assertSucceeds(
      updateDoc(doc(db, choicesPath(KID)), dayUpdate('4', { 'options.4_snack': [APPLE, GRAPES] })),
    );
    await assertSucceeds(
      updateDoc(
        doc(db, choicesPath(KID)),
        dayUpdate('1', { 'options.1_fruit': deleteField(), 'chosen.1_fruit': deleteField() }),
      ),
    );
  });

  it('holds a write to the one day it names — never a sweep of the week', async () => {
    await givenOptions(KID, { '1_fruit': [APPLE, BANANA] });
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(
        doc(db, choicesPath(KID)),
        dayUpdate('4', { 'options.4_snack': [APPLE, GRAPES], 'options.1_fruit': deleteField() }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, choicesPath(ZOLA)),
        choicesOf(ZOLA, '1', { '1_main': [WRAP, BANANA], '2_main': [WRAP, BANANA] }),
      ),
    );
    await assertFails(
      setDoc(doc(db, choicesPath(ZOLA)), choicesOf(ZOLA, '6', { '1_main': [WRAP, BANANA] })),
    );
  });

  it('refuses a carer, the tablet, a stranger, and a week for somebody who is not a child', async () => {
    const options = { '1_fruit': [APPLE, BANANA] };
    for (const db of [await asUser(NOMSA), await kidsTablet(), await asUser(STRANGER)]) {
      await assertFails(setDoc(doc(db, choicesPath(KID)), choicesOf(KID, '1', options)));
    }
    await assertFails(
      setDoc(doc(await asUser(SAM), `${CHOICES}/m-sam_${WEEK}`), choicesOf('m-sam', '1', options)),
    );
  });

  it('the tablet reads its own options and nobody else’s', async () => {
    await givenOptions(KID, { '1_fruit': [APPLE, BANANA] });
    await givenOptions(ZOLA, { '1_fruit': [APPLE, BANANA] });
    const tablet = await kidsTablet();
    await assertSucceeds(getDoc(doc(tablet, choicesPath(KID))));
    await assertFails(getDoc(doc(tablet, choicesPath(ZOLA))));
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), choicesPath(ZOLA))));
  });
});

describe('the child chooses', () => {
  beforeEach(async () => {
    await givenOptions(KID, {
      '2_main': [WRAP, CHEESE],
      '2_fruit': [APPLE, BANANA, GRAPES],
    });
    await givenOptions(ZOLA, { '2_main': [WRAP, PEANUT_BUTTER] });
  });

  it('picks one of the approved options into their own plan — even one nobody planned yet', async () => {
    const tablet = await kidsTablet();
    await assertSucceeds(choose(tablet, KID, '2_fruit', BANANA));
    await assertSucceeds(choose(tablet, KID, '2_fruit', APPLE));
  });

  it('cannot pick anything that is not one of the options', async () => {
    const tablet = await kidsTablet();
    await assertFails(choose(tablet, KID, '2_fruit', pick('chips', 'Chips')));
    await assertFails(choose(tablet, KID, '3_fruit', APPLE));
    // An option's name changed on the way is not the option.
    await assertFails(choose(tablet, KID, '2_fruit', { ...APPLE, name: 'Apple pie' }));
  });

  it('still cannot pick an allergen, even one a parent approved before the allergy was known', async () => {
    // Cheese was approved; the child has since been recorded as allergic to milk.
    await assertFails(choose(await kidsTablet(), KID, '2_main', CHEESE));
    await assertSucceeds(choose(await kidsTablet(), KID, '2_main', WRAP));
  });

  it('cannot clear a slot, touch another child’s plan, or mark what came home', async () => {
    const tablet = await kidsTablet();
    await assertSucceeds(choose(tablet, KID, '2_fruit', APPLE));
    await assertFails(updateDoc(doc(tablet, planPath(KID)), { 'slots.2_fruit': deleteField() }));
    await assertFails(choose(tablet, ZOLA, '2_main', WRAP));
    await assertFails(
      updateDoc(doc(tablet, planPath(KID)), {
        'feedback.2': { verdict: 'ate', by: KID, at: serverTimestamp() },
      }),
    );
  });

  it('cannot change its options, or pick without any', async () => {
    const tablet = await kidsTablet();
    await assertFails(
      updateDoc(doc(tablet, choicesPath(KID)), { 'options.2_fruit': [APPLE, BANANA] }),
    );
    await assertFails(
      updateDoc(doc(tablet, choicesPath(KID)), {
        'chosen.2_fruit': 'apple',
        'chosen.2_main': 'wrap',
        chosenKey: '2_fruit',
      }),
    );
    await givenData(async (db) => {
      await setDoc(doc(db, planPath(KID)), planOf(KID));
    });
    await assertFails(
      setDoc(doc(tablet, planPath(KID)), { slots: { '4_fruit': APPLE } }, { merge: true }),
    );
  });

  it('a parent still packs anything safe over the child’s pick', async () => {
    await assertSucceeds(choose(await kidsTablet(), KID, '2_fruit', GRAPES));
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), planPath(KID)), { 'slots.2_fruit': APPLE }),
    );
  });
});
