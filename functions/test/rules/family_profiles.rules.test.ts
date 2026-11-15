import {
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  type DocumentReference,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';
import {
  HEALTH,
  HOUSEHOLD,
  KID,
  MIA,
  OLIVIA,
  PROFILES,
  SAM,
  SCHOOLS,
  STRANGER,
  THANDI,
  THANDI_MEMBER,
  aFullProfile,
  givenFamilyPremium,
  givenTheKidsDetails,
  givenTheParkers,
  merge,
} from './family_fixture';

/**
 * `familyProfiles`, `memberHealth` and `schools` — family-profiles ADR-0001,
 * with reading by the household's grant (ADR-0002).
 *
 * The denied cases are the point. A child's allergies are read by whoever the
 * `familyProfiles` grant lets see profiles — family always, here a helper a
 * parent let see them; their **medication** by the `medical` grant and the
 * person themselves, and **not by that helper**. Nobody outside the household
 * reads any of it. Every other grant and the kid device are in
 * `family_profiles_access.rules.test.ts`.
 *
 * Writes are merges, as the app makes them, so every rule here is judging the
 * document as it will be after the write.
 */

describe('familyProfiles/{memberId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenFamilyPremium();
  });

  describe('who may read', () => {
    it('lets the admin, a member and a helper read a child"s allergies', async () => {
      await givenTheKidsDetails();
      for (const uid of [SAM, MIA, THANDI]) {
        await assertSucceeds(getDoc(doc(await asUser(uid), `${PROFILES}/${KID}`)));
      }
    });

    it('denies somebody in no household', async () => {
      await givenTheKidsDetails();
      await assertFails(getDoc(doc(await asUser(STRANGER), `${PROFILES}/${KID}`)));
    });

    it('denies the admin of another household', async () => {
      await givenTheKidsDetails();
      await assertFails(getDoc(doc(await asUser(OLIVIA), `${PROFILES}/${KID}`)));
    });

    it('denies somebody who is not signed in', async () => {
      await givenTheKidsDetails();
      await assertFails(getDoc(doc(await asSignedOut(), `${PROFILES}/${KID}`)));
    });
  });

  describe('who may create', () => {
    it('lets an admin create a child"s profile with every field', async () => {
      // Every field but `isChild`, which only `setChildProfile` writes
      // (subscriptions ADR-0001); `subscriptions.rules.test.ts` has that denial.
      await assertSucceeds(
        setDoc(
          doc(await asUser(SAM), `${PROFILES}/${KID}`),
          { ...aFullProfile(), isChild: false },
          merge,
        ),
      );
    });

    it('lets a first edit be one field, which is how the app creates it', async () => {
      await assertSucceeds(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { likes: ['Pasta'] }, merge),
      );
    });

    it('lets a helper fill in their own profile', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(THANDI), `${PROFILES}/${THANDI_MEMBER}`),
          { likes: ['Tea'] },
          merge,
        ),
      );
    });

    it('denies a helper writing a child"s profile', async () => {
      await assertFails(
        setDoc(doc(await asUser(THANDI), `${PROFILES}/${KID}`), { likes: ['Sweets'] }, merge),
      );
    });

    it('denies a member who is not an admin writing a child"s profile', async () => {
      await assertFails(
        setDoc(doc(await asUser(MIA), `${PROFILES}/${KID}`), { likes: ['Sweets'] }, merge),
      );
    });

    it('denies a profile for a member that does not exist', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `${PROFILES}/m-nobody`), { likes: ['Tea'] }, merge),
      );
    });

    it('denies the admin of another household', async () => {
      await assertFails(
        setDoc(doc(await asUser(OLIVIA), `${PROFILES}/${KID}`), { likes: ['Sweets'] }, merge),
      );
    });

    it('denies a field the profile does not have', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { bloodType: 'O+' }, merge),
      );
    });

    it('denies medication on the profile, where a helper could read it', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { medications: {} }, merge),
      );
    });
  });

  describe('what an allergy may be', () => {
    async function allergies(value: unknown): Promise<void> {
      await setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { allergies: value }, merge);
    }

    it('accepts every one of the nine at every severity', async () => {
      await assertSucceeds(
        allergies({
          peanut: { severity: 'severe', note: null },
          treeNut: { severity: 'moderate', note: null },
          milk: { severity: 'mild', note: null },
          egg: { severity: 'mild', note: null },
          wheat: { severity: 'mild', note: null },
          soy: { severity: 'mild', note: null },
          fish: { severity: 'mild', note: null },
          shellfish: { severity: 'mild', note: null },
          sesame: { severity: 'mild', note: 'A rash' },
        }),
      );
    });

    it('denies an allergen outside the vocabulary, which lunch-box could not match', async () => {
      await assertFails(allergies({ kiwi: { severity: 'severe', note: null } }));
    });

    it('denies a severity that is not one of the three', async () => {
      await assertFails(allergies({ peanut: { severity: 'deadly', note: null } }));
    });

    it('denies an allergy with no severity', async () => {
      await assertFails(allergies({ peanut: { note: 'ask Sam' } }));
    });

    it('denies an allergy carrying a field it does not have', async () => {
      await assertFails(allergies({ peanut: { severity: 'mild', note: null, dose: '1' } }));
    });

    it('denies an allergy that is not a map at all', async () => {
      await assertFails(allergies({ peanut: 'severe' }));
    });

    it('lets one allergy be removed by a merge without touching the others', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(
        setDoc(
          doc(await asUser(SAM), `${PROFILES}/${KID}`),
          { allergies: { milk: deleteField() } },
          merge,
        ),
      );
    });
  });

  describe('the rest of the shape', () => {
    async function write(fields: Record<string, unknown>): Promise<void> {
      await setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), fields, merge);
    }

    it('denies a diet outside the vocabulary', async () => {
      await assertFails(write({ diet: ['paleo'] }));
    });

    it('denies thirty-one likes', async () => {
      await assertFails(
        write({ likes: Array.from({ length: 31 }, (_, i) => `like ${String(i)}`) }),
      );
    });

    it('allows thirty', async () => {
      await assertSucceeds(
        write({ likes: Array.from({ length: 30 }, (_, i) => `like ${String(i)}`) }),
      );
    });

    it('denies eleven free-text allergies', async () => {
      const others = Object.fromEntries(
        Array.from({ length: 11 }, (_, i) => [`o${String(i)}`, { name: 'x', severity: 'mild' }]),
      );
      await assertFails(write({ otherAllergies: others }));
    });

    it('denies an empty grade, which is no grade written as something', async () => {
      await assertFails(write({ grade: '' }));
    });

    it('denies isChild that is not a yes or a no', async () => {
      await assertFails(write({ isChild: 'yes' }));
    });
  });

  describe('the school it points at', () => {
    it('denies a school that does not exist', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { schoolId: 'nowhere' }, merge),
      );
    });

    it('does not lock a child"s profile when their school is deleted', async () => {
      await givenTheKidsDetails();
      await givenData(async (db: Firestore) => {
        await deleteDoc(doc(db, `${SCHOOLS}/oakwood`));
      });
      await assertSucceeds(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { shoeSize: 'UK 1' }, merge),
      );
    });

    it('but denies moving to a school that does not exist', async () => {
      await givenTheKidsDetails();
      await assertFails(
        setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { schoolId: 'nowhere' }, merge),
      );
    });
  });

  describe('who may delete', () => {
    it('denies even an admin — a profile goes with its member, in removeMember', async () => {
      await givenTheKidsDetails();
      await assertFails(deleteDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`)));
    });
  });
});

describe('memberHealth/{memberId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenFamilyPremium();
  });

  describe('who may read', () => {
    it('lets the admin read a child"s medication', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(getDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`)));
    });

    it('lets a member who is not an admin read it', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(getDoc(doc(await asUser(MIA), `${HEALTH}/${KID}`)));
    });

    it('DENIES A HELPER the household did not give the medical area', async () => {
      await givenTheKidsDetails();
      await assertFails(getDoc(doc(await asUser(THANDI), `${HEALTH}/${KID}`)));
    });

    it('lets a helper read their own', async () => {
      await assertSucceeds(getDoc(doc(await asUser(THANDI), `${HEALTH}/${THANDI_MEMBER}`)));
    });

    it('denies somebody in no household, and another household"s admin', async () => {
      await givenTheKidsDetails();
      await assertFails(getDoc(doc(await asUser(STRANGER), `${HEALTH}/${KID}`)));
      await assertFails(getDoc(doc(await asUser(OLIVIA), `${HEALTH}/${KID}`)));
    });
  });

  describe('who may write', () => {
    function aMedicine(): Record<string, unknown> {
      return { name: 'Antihistamine', dose: '5 ml', times: [480, 1200], note: null };
    }

    it('lets the admin add a medicine', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine() } },
          merge,
        ),
      );
    });

    it('lets a helper keep their own', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(THANDI), `${HEALTH}/${THANDI_MEMBER}`),
          { medications: { a1: aMedicine() } },
          merge,
        ),
      );
    });

    it('denies a member who is not an admin, although they may read it', async () => {
      await assertFails(
        setDoc(
          doc(await asUser(MIA), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine() } },
          merge,
        ),
      );
    });

    it('denies a helper writing a child"s', async () => {
      await assertFails(
        setDoc(
          doc(await asUser(THANDI), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine() } },
          merge,
        ),
      );
    });

    it('denies a member that does not exist', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `households/${HOUSEHOLD}/memberHealth/m-nobody`), {
          medications: {},
        }),
      );
    });

    it('denies a thirteenth medicine', async () => {
      const medications = Object.fromEntries(
        Array.from({ length: 13 }, (_, i) => [`m${String(i)}`, aMedicine()]),
      );
      await assertFails(setDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`), { medications }));
    });

    it('denies anything but medication in the document', async () => {
      await assertFails(
        setDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`), { medications: {}, diagnosis: 'x' }),
      );
    });

    it('denies deleting it, even to an admin', async () => {
      await givenTheKidsDetails();
      await assertFails(deleteDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`)));
    });
  });
});

describe('schools/{schoolId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  function aSchool(): Record<string, unknown> {
    return { name: 'Greenfields', nutFree: false, createdAt: serverTimestamp() };
  }

  it('lets a helper who may see profiles read the household"s schools', async () => {
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${SCHOOLS}/oakwood`)));
  });

  it('denies somebody in no household', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `${SCHOOLS}/oakwood`)));
  });

  it('lets an admin add a school', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${SCHOOLS}/greenfields`), aSchool()));
  });

  it('denies a member who is not an admin adding one', async () => {
    await assertFails(setDoc(doc(await asUser(MIA), `${SCHOOLS}/greenfields`), aSchool()));
  });

  it('denies a creation time the client chose', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${SCHOOLS}/greenfields`), {
        ...aSchool(),
        createdAt: new Date(),
      }),
    );
  });

  it('denies a nut-free rule that is not a yes or a no', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${SCHOOLS}/greenfields`), { ...aSchool(), nutFree: 'yes' }),
    );
  });

  it('lets an admin mark a school nut-free', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${SCHOOLS}/oakwood`), { name: 'Oakwood', nutFree: false }),
    );
  });

  it('denies a helper changing a school"s rule', async () => {
    await assertFails(
      updateDoc(doc(await asUser(THANDI), `${SCHOOLS}/oakwood`), { nutFree: false }),
    );
  });

  it('denies moving its creation time', async () => {
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${SCHOOLS}/oakwood`), { createdAt: new Date(2020, 0, 1) }),
    );
  });

  it('lets an admin delete a school', async () => {
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${SCHOOLS}/oakwood`)));
  });

  it('denies a member who is not an admin deleting one', async () => {
    await assertFails(deleteDoc(doc(await asUser(MIA), `${SCHOOLS}/oakwood`)));
  });
});

describe('allergies and medication are Premium (subscriptions ADR-0008)', () => {
  const aMedicine = { name: 'Antihistamine', dose: '5 ml', times: [480], note: null };
  const kidAs = async (uid: string): Promise<DocumentReference> =>
    doc(await asUser(uid), `${PROFILES}/${KID}`);

  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  describe('a free household', () => {
    it('creates a profile with everything but an allergy', async () => {
      await assertSucceeds(
        setDoc(
          await kidAs(SAM),
          {
            likes: ['Pasta'],
            dislikes: ['Mushrooms'],
            diet: ['nutFree', 'halal'],
            schoolId: 'oakwood',
            grade: 'Grade 3',
            clothingSize: '7-8',
            shoeSize: 'UK 13',
          },
          merge,
        ),
      );
    });

    it('creates one that says, in so many words, that there are no allergies', async () => {
      await assertSucceeds(
        setDoc(await kidAs(SAM), { likes: ['Pasta'], allergies: {}, otherAllergies: {} }),
      );
    });

    it('is denied a first profile that records an allergy, of either kind', async () => {
      await assertFails(
        setDoc(
          await kidAs(SAM),
          { allergies: { peanut: { severity: 'severe', note: null } } },
          merge,
        ),
      );
      await assertFails(
        setDoc(
          await kidAs(SAM),
          { otherAllergies: { k1: { name: 'Kiwi', severity: 'mild', note: null } } },
          merge,
        ),
      );
    });

    it('edits every other field of a profile that already holds allergies', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(
        setDoc(
          await kidAs(SAM),
          {
            likes: ['Pears'],
            dislikes: [],
            diet: ['vegetarian'],
            grade: 'Grade 4',
            shoeSize: 'UK 1',
          },
          merge,
        ),
      );
      await assertSucceeds(updateDoc(await kidAs(SAM), { clothingSize: deleteField() }));
    });

    it('rewrites the whole document when the allergies are carried over as stored', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(setDoc(await kidAs(SAM), { ...aFullProfile(), grade: 'Grade 4' }));
    });

    it('is denied adding, changing or removing an allergy', async () => {
      await givenTheKidsDetails();
      await assertFails(
        setDoc(await kidAs(SAM), { allergies: { egg: { severity: 'mild', note: null } } }, merge),
      );
      await assertFails(
        setDoc(await kidAs(SAM), { allergies: { peanut: { severity: 'mild' } } }, merge),
      );
      await assertFails(setDoc(await kidAs(SAM), { allergies: { milk: deleteField() } }, merge));
      await assertFails(updateDoc(await kidAs(SAM), { otherAllergies: {} }));
      await assertFails(
        setDoc(
          await kidAs(SAM),
          { otherAllergies: { k2: { name: 'Latex', severity: 'mild', note: null } } },
          merge,
        ),
      );
    });

    it('is denied a rewrite that drops the allergies along the way', async () => {
      await givenTheKidsDetails();
      await assertFails(setDoc(await kidAs(SAM), { isChild: true, likes: ['Pears'] }));
    });

    it('is denied medication: a first one, a change, and an empty document', async () => {
      await assertFails(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine } },
          merge,
        ),
      );
      await assertFails(
        setDoc(doc(await asUser(THANDI), `${HEALTH}/${THANDI_MEMBER}`), { medications: {} }, merge),
      );
      await givenTheKidsDetails();
      await assertFails(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine } },
          merge,
        ),
      );
      await assertFails(
        updateDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`), {
          'medications.ritalin': deleteField(),
        }),
      );
    });

    it('still reads what it recorded', async () => {
      await givenTheKidsDetails();
      await assertSucceeds(getDoc(await kidAs(SAM)));
      await assertSucceeds(getDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`)));
    });
  });

  describe('a household whose Premium has lapsed', () => {
    beforeEach(async () => {
      await givenFamilyPremium('lapsed');
      await givenTheKidsDetails();
    });

    it('keeps and reads its allergies and medication, and edits the rest', async () => {
      await assertSucceeds(getDoc(await kidAs(SAM)));
      await assertSucceeds(getDoc(doc(await asUser(SAM), `${HEALTH}/${KID}`)));
      await assertSucceeds(setDoc(await kidAs(SAM), { grade: 'Grade 4' }, merge));
    });

    it('is denied changing either', async () => {
      await assertFails(
        setDoc(await kidAs(SAM), { allergies: { egg: { severity: 'mild', note: null } } }, merge),
      );
      await assertFails(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine } },
          merge,
        ),
      );
    });
  });

  describe('a Premium household', () => {
    beforeEach(async () => {
      await givenFamilyPremium();
    });

    it('records allergies on a new profile and changes them on an old one', async () => {
      await assertSucceeds(
        setDoc(
          await kidAs(SAM),
          { allergies: { peanut: { severity: 'severe', note: null } } },
          merge,
        ),
      );
      await assertSucceeds(
        setDoc(
          await kidAs(SAM),
          {
            allergies: { peanut: deleteField(), egg: { severity: 'mild', note: null } },
            otherAllergies: { k1: { name: 'Kiwi', severity: 'mild', note: null } },
          },
          merge,
        ),
      );
    });

    it('records and changes medication', async () => {
      await assertSucceeds(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: aMedicine } },
          merge,
        ),
      );
      await assertSucceeds(
        setDoc(
          doc(await asUser(SAM), `${HEALTH}/${KID}`),
          { medications: { a1: { ...aMedicine, dose: '10 ml' } } },
          merge,
        ),
      );
    });

    it('is still held to who may edit a profile', async () => {
      await assertFails(
        setDoc(await kidAs(MIA), { allergies: { egg: { severity: 'mild', note: null } } }, merge),
      );
      await assertFails(
        setDoc(doc(await asUser(THANDI), `${HEALTH}/${KID}`), { medications: {} }, merge),
      );
    });
  });
});
