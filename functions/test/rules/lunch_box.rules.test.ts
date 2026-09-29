import {
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, KID, MIA, NOMSA, OLIVIA, SAM, STRANGER, THANDI } from './family_fixture';
import {
  APPLE,
  DIET_ONLY,
  PEANUT_BUTTER,
  PLANS,
  SCHOOL_ONLY,
  TRAIL_MIX,
  WEEK,
  WRAP,
  YOGHURT,
  ZOLA,
  givenLunchPremium,
  givenTheLunchHousehold,
  givenThandiHasLunch,
  kidsTablet,
  planOf,
  planPath,
} from './lunch_box_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * A week's lunches per child (lunch-box ADR-0001): planned by whoever holds
 * `lunch` at edit, read by `view`, and by a kid's tablet only for its own
 * week. **The allergy rule is enforced here**, on every slot a write changes:
 * an allergen the child reacts to, or a nut when nuts are ruled out for them
 * by an allergy, their diet or their school, is refused by the server — not
 * only hidden by the picker (the phase's definition of done).
 */

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
});

const merge = { merge: true } as const;

describe('planning a week', () => {
  it('a parent plans a week for each child, and the two differ', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_main': PEANUT_BUTTER })),
    );
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_main': WRAP })));
  });

  it('a second parent plans too, and a helper a parent gave lunch at edit', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(MIA), planPath(ZOLA)), planOf(ZOLA, { '2_fruit': APPLE })),
    );
    await givenThandiHasLunch('edit');
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), planPath(ZOLA)), planOf(ZOLA, { '3_fruit': APPLE })),
    );
  });

  it('nobody plans at view, at own, with none, or from outside', async () => {
    const plan = planOf(ZOLA, { '1_fruit': APPLE });
    for (const db of [
      await asUser(NOMSA),
      await kidsTablet(),
      await asUser(CLEO),
      await asUser(STRANGER),
      await asUser(OLIVIA),
    ]) {
      await assertFails(setDoc(doc(db, planPath(ZOLA)), plan));
    }
  });
});

describe('the allergy rule, on the server', () => {
  it('refuses a box with an allergen the child reacts to', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_main': PEANUT_BUTTER })));
    // A mild allergy is still an allergy.
    await assertFails(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_snack': YOGHURT })));
  });

  it('refuses it in any of the twenty-five slots', async () => {
    const db = await asUser(SAM);
    for (const key of ['1_main', '3_veg', '5_treat']) {
      await assertFails(setDoc(doc(db, planPath(KID)), planOf(KID, { [key]: PEANUT_BUTTER })));
    }
  });

  it('refuses tree nuts for a peanut-allergic child — nuts are out', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), planPath(KID)), planOf(KID, { '2_snack': TRAIL_MIX })),
    );
  });

  it('refuses nuts for a child whose school is nut-free, and nothing else', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, planPath(SCHOOL_ONLY)), planOf(SCHOOL_ONLY, { '1_snack': TRAIL_MIX })),
    );
    await assertSucceeds(
      setDoc(doc(db, planPath(SCHOOL_ONLY)), planOf(SCHOOL_ONLY, { '1_snack': YOGHURT })),
    );
  });

  it('refuses nuts for a child on a nut-free diet', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(SAM), planPath(DIET_ONLY)),
        planOf(DIET_ONLY, { '1_main': PEANUT_BUTTER }),
      ),
    );
  });

  it('refuses an unsafe slot added to an existing week', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_main': WRAP })));
    await assertFails(
      setDoc(doc(db, planPath(KID)), { slots: { '2_main': PEANUT_BUTTER } }, merge),
    );
    await assertSucceeds(setDoc(doc(db, planPath(KID)), { slots: { '2_main': WRAP } }, merge));
  });

  it('refuses a pick that hides what it contains in a shape it cannot have', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(
        doc(db, planPath(ZOLA)),
        planOf(ZOLA, { '1_main': { itemId: 'x', name: 'X', allergens: ['lupin'] } }),
      ),
    );
    await assertFails(
      setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_main': { itemId: 'x', name: '' } })),
    );
    await assertFails(
      setDoc(
        doc(db, planPath(ZOLA)),
        planOf(ZOLA, { '1_main': { ...WRAP, allergensHidden: ['peanut'] } }),
      ),
    );
  });

  it('judges only the slots a write changes', async () => {
    // Packed before the allergy was recorded: it stays until somebody swaps
    // it, and it does not stop the rest of the week being planned.
    await givenData(async (db) => {
      await setDoc(doc(db, planPath(KID)), planOf(KID, { '1_main': PEANUT_BUTTER }));
    });
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(KID)), { slots: { '2_main': WRAP } }, merge));
    await assertSucceeds(updateDoc(doc(db, planPath(KID)), { 'slots.1_main': deleteField() }));
  });
});

describe('what a plan is', () => {
  it('is filed under its own child and week', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, planPath(ZOLA)), planOf(KID, { '1_fruit': APPLE })));
    await assertFails(setDoc(doc(db, `${PLANS}/${ZOLA}_next-week`), planOf(ZOLA)));
    await assertFails(
      setDoc(doc(db, `${PLANS}/${ZOLA}_2026-40`), { ...planOf(ZOLA), week: '2026-40' }),
    );
  });

  it('holds Monday to Friday and the five slots, nothing else', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '6_main': APPLE })));
    await assertFails(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_dessert': APPLE })));
    await assertFails(setDoc(doc(db, planPath(ZOLA)), { ...planOf(ZOLA), note: 'hi' }));
  });

  it('is for a child — not an adult, not somebody with no profile', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, planPath('m-sam')), planOf('m-sam')));
    await assertFails(setDoc(doc(db, planPath('m-nobody')), planOf('m-nobody')));
  });

  it('never changes whose or which week it is, and is never deleted', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_fruit': APPLE })));
    await assertFails(updateDoc(doc(db, planPath(ZOLA)), { childId: KID }));
    await assertFails(updateDoc(doc(db, planPath(ZOLA)), { weekStart: '2026-10-05' }));
    await assertFails(deleteDoc(doc(db, planPath(ZOLA))));
  });
});

describe('reading a week', () => {
  beforeEach(async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, planPath(KID)), planOf(KID, { '2_main': WRAP }));
      await setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '2_main': WRAP }));
    });
  });

  it('family and a carer at view read every child’s week', async () => {
    for (const uid of [SAM, MIA, NOMSA]) {
      await assertSucceeds(getDoc(doc(await asUser(uid), planPath(ZOLA))));
    }
  });

  it('a kid’s tablet reads its own week — even one nobody has planned yet', async () => {
    const tablet = await kidsTablet();
    await assertSucceeds(getDoc(doc(tablet, planPath(KID))));
    await assertSucceeds(getDoc(doc(tablet, `${PLANS}/${KID}_2026-W41`)));
  });

  it('and nobody else’s', async () => {
    await assertFails(getDoc(doc(await kidsTablet(), planPath(ZOLA))));
  });

  it('a cleaner, a stranger and another household read none', async () => {
    for (const uid of [CLEO, STRANGER, OLIVIA]) {
      await assertFails(getDoc(doc(await asUser(uid), planPath(KID))));
    }
  });
});

describe('what came home', () => {
  beforeEach(async () => {
    // Learning from what came home is premium (lunch-box ADR-0009);
    // `lunch_premium.rules.test.ts` holds the free side of it.
    await givenLunchPremium();
    await givenData(async (db) => {
      await setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '2_main': WRAP }));
    });
  });

  const mark = (by: string, extra: object = {}): object => ({
    'feedback.2': { verdict: 'ate', items: { main: 'left' }, by, at: serverTimestamp(), ...extra },
  });

  it('a parent marks a box, in their own name at the server’s time', async () => {
    await assertSucceeds(updateDoc(doc(await asUser(SAM), planPath(ZOLA)), mark('m-sam')));
  });

  it('and can take it back', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, planPath(ZOLA)), mark('m-sam')));
    await assertSucceeds(updateDoc(doc(db, planPath(ZOLA)), { 'feedback.2': deleteField() }));
  });

  it('not in somebody else’s name, at a time of their choosing, or in words it does not know', async () => {
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, planPath(ZOLA)), mark('m-mia')));
    await assertFails(
      updateDoc(doc(db, planPath(ZOLA)), mark('m-sam', { at: new Date('2026-09-29') })),
    );
    await assertFails(updateDoc(doc(db, planPath(ZOLA)), mark('m-sam', { verdict: 'most' })));
    await assertFails(
      updateDoc(doc(db, planPath(ZOLA)), mark('m-sam', { items: { dessert: 'ate' } })),
    );
    await assertFails(
      updateDoc(doc(db, planPath(ZOLA)), {
        'feedback.6': { verdict: 'ate', items: {}, by: 'm-sam', at: serverTimestamp() },
      }),
    );
  });

  it('nobody marks at view or from a kid’s tablet', async () => {
    await assertFails(updateDoc(doc(await asUser(NOMSA), planPath(ZOLA)), mark('m-nomsa')));
    await assertFails(updateDoc(doc(await kidsTablet(), planPath(ZOLA)), mark(KID)));
  });
});

describe('the week is counted', () => {
  it('under the path product-analytics listens on', async () => {
    // `countLunchPlanCreated` fires on households/{h}/lunchPlans/{planId};
    // the id is the child and the week, so a re-made plan is the same one.
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${PLANS}/${ZOLA}_${WEEK}`), planOf(ZOLA)));
  });
});
