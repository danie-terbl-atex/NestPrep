import { randomBytes } from 'node:crypto';

import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { monthKeyIn } from '../../src/ai/usage_rules';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import {
  adminAuth,
  adminBucket,
  adminDb,
  callAs,
  clearFirestore,
  signInWithCustomToken,
  signUp,
  type TestUser,
} from './emulator_harness';

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const JPEG_BASE64 = JPEG.toString('base64');
const MONTH = monthKeyIn('Africa/Johannesburg', new Date());

interface Home {
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly householdId: string;
}

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

const newRecipeId = (): string => `own-${randomBytes(10).toString('hex')}`;

async function premium(householdId: string): Promise<void> {
  await home(householdId)
    .collection('entitlement')
    .doc('current')
    .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
}

async function aPremiumHousehold(thandiRole = 'parent'): Promise<Home> {
  const household = await householdOfTwo(thandiRole);
  await premium(household.householdId);
  return household;
}

function recipeBody(
  householdId: string,
  recipeId: string,
  more: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    householdId,
    recipeId,
    name: 'Bobotie',
    summary: 'Spiced mince.',
    contexts: ['dinner'],
    placement: { dinner: 'main' },
    ingredients: [
      { name: 'Beef mince', quantity: 1, unit: 'kg', note: 'lean', group: null },
      { name: 'Salt', quantity: null, unit: null, note: 'to taste', group: null },
    ],
    steps: ['Brown the mince.', 'Brush with egg and bake.'],
    servings: 6,
    prepMinutes: 20,
    cookMinutes: 40,
    notes: 'Lovely with cream.',
    origin: 'typed',
    sourceUrl: null,
    sourceName: null,
    alsoContains: ['sesame'],
    photo: null,
    gallery: [],
    ...more,
  };
}

const save = (
  user: TestUser,
  householdId: string,
  recipeId: string,
  more: Record<string, unknown> = {},
): Promise<{ id: string; allergens: string[]; created: boolean }> =>
  callAs(user, 'saveHouseholdRecipe', recipeBody(householdId, recipeId, more));

const remove = (
  user: TestUser,
  householdId: string,
  recipeId: string,
): Promise<{ deleted: boolean }> =>
  callAs(user, 'deleteHouseholdRecipe', { householdId, recipeId });

const photoPath = (
  householdId: string,
  recipeId: string,
  photoId: string,
  size: 'card' | 'hero',
): string => `households/${householdId}/recipePhotos/${recipeId}/${photoId}-${size}.jpg`;

async function stored(path: string): Promise<void> {
  await adminBucket().file(path).save(JPEG, { contentType: 'image/jpeg', resumable: false });
}

async function isStored(path: string): Promise<boolean> {
  const [found] = await adminBucket().file(path).exists();
  return found;
}

async function givenPhoto(householdId: string, recipeId: string, photoId: string): Promise<void> {
  await stored(photoPath(householdId, recipeId, photoId, 'card'));
  await stored(photoPath(householdId, recipeId, photoId, 'hero'));
}

const photoInput = (photoId: string, more: Record<string, unknown> = {}): unknown => ({
  photoId,
  credit: null,
  sourceUrl: null,
  ...more,
});

async function aKidDevice(householdId: string): Promise<TestUser> {
  const token = await adminAuth().createCustomToken('kid_tablet', {
    kidProfile: { householdId, memberId: 'm-kid' },
  });
  return signInWithCustomToken(token);
}

beforeEach(async () => {
  await clearFirestore();
});

describe('saving a household’s own recipe', () => {
  it('stores the whole shape, deriving the codes and who added it', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await givenPhoto(householdId, recipeId, 'coverphoto');

    const answer = await save(sam, householdId, recipeId, {
      origin: 'link',
      sourceUrl: 'HTTPS://Drizzleanddip.com/bobotie',
      sourceName: 'drizzleanddip.com',
      photo: photoInput('coverphoto', {
        credit: 'drizzleanddip.com',
        sourceUrl: 'https://drizzleanddip.com/bobotie',
      }),
    });

    expect(answer).toEqual({ id: recipeId, allergens: ['milk', 'egg', 'sesame'], created: true });
    const doc = await home(householdId).collection('recipes').doc(recipeId).get();
    const household = await home(householdId).get();
    const profiles = household.get('profiles') as Record<string, string>;
    expect(doc.data()).toMatchObject({
      name: 'Bobotie',
      summary: 'Spiced mince.',
      source: 'own',
      contexts: ['dinner'],
      placement: { dinner: 'main' },
      allergens: ['milk', 'egg', 'sesame'],
      alsoContains: ['sesame'],
      dietTags: [],
      kcalPerServing: null,
      ingredients: [
        { name: 'Beef mince', quantity: 1, unit: 'kg', note: 'lean', group: null },
        { name: 'Salt', quantity: null, unit: null, note: 'to taste', group: null },
      ],
      steps: ['Brown the mince.', 'Brush with egg and bake.'],
      servings: 6,
      prepMinutes: 20,
      cookMinutes: 40,
      notes: 'Lovely with cream.',
      origin: 'link',
      sourceUrl: 'https://drizzleanddip.com/bobotie',
      sourceName: 'drizzleanddip.com',
      addedBy: profiles[sam.uid],
      photo: {
        card: photoPath(householdId, recipeId, 'coverphoto', 'card'),
        hero: photoPath(householdId, recipeId, 'coverphoto', 'hero'),
        credit: 'drizzleanddip.com',
        sourceUrl: 'https://drizzleanddip.com/bobotie',
      },
      gallery: [],
    });
    expect(doc.get('createdAt')).toBeDefined();
    expect(doc.get('updatedAt')).toBeDefined();
    expect(doc.get('version')).toBeUndefined();
    expect(doc.get('updatedBy')).toBeUndefined();
  });

  it('an edit by someone else keeps who added it and when, and recomputes the codes', async () => {
    const { sam, thandi, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await save(sam, householdId, recipeId);
    const ref = home(householdId).collection('recipes').doc(recipeId);
    const before = await ref.get();

    const answer = await save(thandi, householdId, recipeId, {
      steps: ['Bake it.'],
      notes: null,
      alsoContains: ['sesame'],
    });

    expect(answer).toEqual({ id: recipeId, allergens: ['sesame'], created: false });
    const after = await ref.get();
    expect(after.get('addedBy')).toBe(before.get('addedBy'));
    expect(after.get('createdAt')).toEqual(before.get('createdAt'));
    expect(after.get('alsoContains')).toEqual(['sesame']);
    expect(after.get('notes')).toBeNull();
  });

  it('saving twice is one recipe', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await save(sam, householdId, recipeId);
    expect((await save(sam, householdId, recipeId)).created).toBe(false);
    const all = await home(householdId).collection('recipes').count().get();
    expect(all.data().count).toBe(1);
  });

  it('an edit renames its linked meal, and leaves anything else on it alone', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await save(sam, householdId, recipeId);
    const meal = home(householdId).collection('meals').doc(`recipe-${recipeId}`);
    const lines = [{ name: 'Mince', amount: 1, unit: 'kg' }];
    await meal.set({
      name: 'Bobotie',
      nameKey: 'bobotie',
      householdRecipeId: recipeId,
      ingredients: lines,
    });

    await save(sam, householdId, recipeId, { name: ' Gran’s   Bobotie ' });

    const after = await meal.get();
    expect(after.get('name')).toBe('Gran’s   Bobotie');
    expect(after.get('nameKey')).toBe('gran’s bobotie');
    expect(after.get('ingredients')).toEqual(lines);
    expect(after.get('householdRecipeId')).toBe(recipeId);
  });

  it('refuses to overwrite a document that is not own', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await home(householdId)
      .collection('recipes')
      .doc(recipeId)
      .set({ name: 'A wrap', source: 'ai', allergens: [] });
    await expectRefusal(save(sam, householdId, recipeId), 'notOwnRecipe');
    const doc = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(doc.get('source')).toBe('ai');
  });

  it('refuses an id that is not own at the edge', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(save(sam, householdId, 'ai-0123456789abcdef0123'), 'badRequest');
  });

  it('refuses the 301st, counting only own recipes, and still lets one be edited', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipes = home(householdId).collection('recipes');
    const held = Array.from({ length: 300 }, () => newRecipeId());
    const batches = [held.slice(0, 150), held.slice(150)];
    for (const ids of batches) {
      const batch = adminDb().batch();
      for (const id of ids) batch.set(recipes.doc(id), { name: 'A dish', source: 'own' });
      await batch.commit();
    }
    await recipes.doc('ai-0123456789abcdef0123').set({ name: 'A wrap', source: 'ai' });

    await expectRefusal(save(sam, householdId, newRecipeId()), 'recipeLimitReached');
    expect((await save(sam, householdId, held[0] ?? '')).created).toBe(false);

    await recipes.doc(held[1] ?? '').delete();
    expect((await save(sam, householdId, newRecipeId())).created).toBe(true);
  });

  it('refuses a photo that is not there, or only there in another home', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await expectRefusal(
      save(sam, householdId, recipeId, { photo: photoInput('missingphoto') }),
      'recipePhotoMissing',
    );
    await stored(photoPath(householdId, recipeId, 'halfphoto', 'card'));
    await expectRefusal(
      save(sam, householdId, recipeId, { photo: photoInput('halfphoto') }),
      'recipePhotoMissing',
    );
    await givenPhoto('another-household', recipeId, 'foreignphoto');
    await expectRefusal(
      save(sam, householdId, recipeId, { photo: photoInput('foreignphoto') }),
      'recipePhotoMissing',
    );
    const doc = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(doc.exists).toBe(false);
  });

  it('refuses a photo id shaped like a path', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      save(sam, householdId, newRecipeId(), {
        photo: photoInput('../../../another-household/x'),
      }),
      'badRequest',
    );
  });

  it('refuses a source link that is not public', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      save(sam, householdId, newRecipeId(), { sourceUrl: 'http://192.168.1.1/recipe' }),
      'sourceLinkNotPublic',
    );
    const recipeId = newRecipeId();
    await givenPhoto(householdId, recipeId, 'coverphoto');
    await expectRefusal(
      save(sam, householdId, recipeId, {
        photo: photoInput('coverphoto', { sourceUrl: 'file:///etc/passwd' }),
      }),
      'sourceLinkNotPublic',
    );
  });

  it('tidies what the save no longer names, and keeps what it does', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await givenPhoto(householdId, recipeId, 'firstphoto');
    await givenPhoto(householdId, recipeId, 'secondphoto');
    await givenPhoto(householdId, recipeId, 'abandoned');
    await save(sam, householdId, recipeId, {
      photo: photoInput('firstphoto'),
      gallery: [photoInput('secondphoto')],
    });
    expect(await isStored(photoPath(householdId, recipeId, 'firstphoto', 'hero'))).toBe(true);
    expect(await isStored(photoPath(householdId, recipeId, 'secondphoto', 'card'))).toBe(true);
    expect(await isStored(photoPath(householdId, recipeId, 'abandoned', 'hero'))).toBe(false);

    await save(sam, householdId, recipeId, { photo: photoInput('secondphoto') });
    expect(await isStored(photoPath(householdId, recipeId, 'firstphoto', 'card'))).toBe(false);
    expect(await isStored(photoPath(householdId, recipeId, 'secondphoto', 'hero'))).toBe(true);
    const doc = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(doc.get('gallery')).toEqual([]);
  });

  it('is refused with the flag off, and off premium with the feature named', async () => {
    const { sam, householdId } = await householdOfTwo();
    await expectRefusal(save(sam, householdId, newRecipeId()), 'premiumRequired');
    await premium(householdId);
    await adminDb().collection('appConfig').doc('flags').set({ householdRecipes: false });
    await expectRefusal(save(sam, householdId, newRecipeId()), 'householdRecipesOff');
  });

  it('is refused without meals at edit, and to a stranger', async () => {
    const { thandi, householdId } = await aPremiumHousehold('helper');
    await expectRefusal(save(thandi, householdId, newRecipeId()), 'mealsNotShared');
    await expectRefusal(save(await signUp(), householdId, newRecipeId()), 'notAMember');
  });

  it('is refused to a shift-only carer off shift, whatever their grant', async () => {
    const { thandi, householdId } = await aPremiumHousehold('carer');
    const memberId = await memberOf(householdId, thandi.uid);
    await home(householdId).update({
      [`access.${thandi.uid}.meals`]: 'edit',
      [`shiftOnly.${memberId}`]: true,
    });
    await expectRefusal(save(thandi, householdId, newRecipeId()), 'mealsNotShared');
  });

  it('finds the profile of an account claimed before the profiles map existed', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const memberId = await memberOf(householdId, sam.uid);
    await home(householdId).update({ [`profiles.${sam.uid}`]: FieldValue.delete() });
    const recipeId = newRecipeId();
    await save(sam, householdId, recipeId);
    const saved = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(saved.get('addedBy')).toBe(memberId);
  });

  it('is refused to an account with no profile to say who added it', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const memberId = await memberOf(householdId, sam.uid);
    await home(householdId).update({ [`profiles.${sam.uid}`]: FieldValue.delete() });
    await home(householdId).collection('members').doc(memberId).update({ claimedBy: null });
    await expectRefusal(save(sam, householdId, newRecipeId()), 'notAMember');
  });

  it('is refused to a kid device', async () => {
    const { householdId } = await aPremiumHousehold();
    await expectRefusal(
      save(await aKidDevice(householdId), householdId, newRecipeId()),
      'kidAccount',
    );
  });
});

async function memberOf(householdId: string, uid: string): Promise<string> {
  const household = await home(householdId).get();
  return (household.get('profiles') as Record<string, string>)[uid] ?? '';
}

describe('deleting a household’s own recipe', () => {
  it('removes it and its photos, leaving its meal plain, and is safe to repeat', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await givenPhoto(householdId, recipeId, 'coverphoto');
    await save(sam, householdId, recipeId, { photo: photoInput('coverphoto') });
    const meal = home(householdId).collection('meals').doc(`recipe-${recipeId}`);
    await meal.set({ name: 'Bobotie', nameKey: 'bobotie', householdRecipeId: recipeId });

    expect(await remove(sam, householdId, recipeId)).toEqual({ deleted: true });

    const doc = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(doc.exists).toBe(false);
    const after = await meal.get();
    expect(after.get('name')).toBe('Bobotie');
    expect(after.get('householdRecipeId')).toBeUndefined();
    expect(await isStored(photoPath(householdId, recipeId, 'coverphoto', 'hero'))).toBe(false);
    expect(await remove(sam, householdId, recipeId)).toEqual({ deleted: true });
  });

  it('leaves another recipe’s photos and meal alone', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const kept = newRecipeId();
    await givenPhoto(householdId, kept, 'coverphoto');
    await save(sam, householdId, kept, { photo: photoInput('coverphoto') });
    const meal = home(householdId).collection('meals').doc(`recipe-${kept}`);
    await meal.set({ name: 'Bobotie', nameKey: 'bobotie', householdRecipeId: kept });

    await remove(sam, householdId, newRecipeId());

    expect(await isStored(photoPath(householdId, kept, 'coverphoto', 'card'))).toBe(true);
    expect((await meal.get()).get('householdRecipeId')).toBe(kept);
  });

  it('still works once premium lapses and with the flag off', async () => {
    const { sam, householdId } = await householdOfTwo();
    const recipeId = newRecipeId();
    await home(householdId)
      .collection('recipes')
      .doc(recipeId)
      .set({ name: 'Bobotie', source: 'own' });
    await adminDb().collection('appConfig').doc('flags').set({ householdRecipes: false });
    expect(await remove(sam, householdId, recipeId)).toEqual({ deleted: true });
  });

  it('refuses a recipe that is not own, leaving it and its photos', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    const ref = home(householdId).collection('recipes').doc(recipeId);
    await ref.set({ name: 'A wrap', source: 'ai' });
    await givenPhoto(householdId, recipeId, 'coverphoto');
    await expectRefusal(remove(sam, householdId, recipeId), 'notOwnRecipe');
    expect((await ref.get()).exists).toBe(true);
    expect(await isStored(photoPath(householdId, recipeId, 'coverphoto', 'card'))).toBe(true);
    await expectRefusal(remove(sam, householdId, 'ai-0123456789abcdef0123'), 'badRequest');
  });

  it('is refused without meals at edit, to a stranger and to a kid device', async () => {
    const { thandi, householdId } = await aPremiumHousehold('helper');
    await expectRefusal(remove(thandi, householdId, newRecipeId()), 'mealsNotShared');
    await expectRefusal(remove(await signUp(), householdId, newRecipeId()), 'notAMember');
    await expectRefusal(
      remove(await aKidDevice(householdId), householdId, newRecipeId()),
      'kidAccount',
    );
  });
});

describe('drafting a recipe', () => {
  interface Proposal {
    isRecipe: boolean;
    recipe: Record<string, unknown> | null;
    imageUrls: string[];
    callsLeft: number;
  }

  const CANNED = {
    isRecipe: true,
    name: 'Bobotie',
    summary: 'Spiced mince.',
    placement: { dinner: 'main' },
    servings: 6,
    prepMinutes: 20,
    cookMinutes: null,
    ingredients: [{ name: 'Mince', quantity: 1, unit: 'kg', note: null, group: null }],
    steps: ['Bake it.'],
    notes: null,
    allergens: ['milk'],
    imageUrls: ['https://model.example.com/made-up.jpg'],
  };

  const modelAnswers = async (reply: unknown): Promise<void> => {
    await adminDb()
      .collection('aiEmulator')
      .doc('recipeImport')
      .set({ reply: JSON.stringify(reply) });
  };

  const aPage = (more: Record<string, unknown> = {}): Record<string, unknown> => ({
    url: 'https://www.drizzleanddip.com/bobotie?print=1',
    title: 'Bobotie',
    jsonLd: ['{"@type":"Recipe"}'],
    text: '',
    imageUrls: [],
    ...more,
  });

  const draft = (user: TestUser, householdId: string, page = aPage()): Promise<Proposal> =>
    callAs(user, 'draftRecipe', { householdId, page });

  const anyCallSpent = async (householdId: string): Promise<boolean> =>
    (await home(householdId).collection('aiUsage').doc(MONTH).get()).exists;

  it('answers a proposal from a page, charges one call and stores no recipe', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers(CANNED);

    const answer = await draft(sam, householdId);

    expect(answer).toEqual({
      isRecipe: true,
      recipe: {
        name: 'Bobotie',
        summary: 'Spiced mince.',
        contexts: ['dinner'],
        placement: { dinner: 'main' },
        ingredients: [{ name: 'Mince', quantity: 1, unit: 'kg', note: null, group: null }],
        steps: ['Bake it.'],
        servings: 6,
        prepMinutes: 20,
        cookMinutes: null,
        cutShort: false,
        notes: null,
        origin: 'link',
        sourceUrl: 'https://www.drizzleanddip.com/bobotie?print=1',
        sourceName: 'drizzleanddip.com',
      },
      imageUrls: [],
      callsLeft: 99,
    });
    const recipes = await home(householdId).collection('recipes').count().get();
    expect(recipes.data().count).toBe(0);
  });

  it('hands back only the phone’s public image links, never the model’s', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers(CANNED);
    const first = 'https://cdn.example.com/1.jpg';
    const answer = await draft(
      sam,
      householdId,
      aPage({ imageUrls: [first, 'http://192.168.1.1/2.jpg', first, 'not a link'] }),
    );
    expect(answer.imageUrls).toEqual([first]);
  });

  it('says so when there is no recipe, keeping the call spent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers({ isRecipe: false });
    const answer = await draft(sam, householdId);
    expect(answer).toEqual({ isRecipe: false, recipe: null, imageUrls: [], callsLeft: 99 });
  });

  it('reads a photo, with no source and no images', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers(CANNED);
    const answer = await callAs<Proposal>(sam, 'draftRecipe', {
      householdId,
      photo: { mimeType: 'image/jpeg', data: JPEG_BASE64 },
    });
    expect(answer.recipe).toMatchObject({ origin: 'photo', sourceUrl: null, sourceName: null });
    expect(answer.imageUrls).toEqual([]);
  });

  it('reads several photos, cut into parts, as one call', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers(CANNED);
    const answer = await callAs<Proposal>(sam, 'draftRecipe', {
      householdId,
      photos: [{ parts: [JPEG_BASE64, JPEG_BASE64, JPEG_BASE64] }, { parts: [JPEG_BASE64] }],
    });
    expect(answer.recipe).toMatchObject({ origin: 'photo', sourceUrl: null, sourceName: null });
    expect(answer.imageUrls).toEqual([]);
    expect(answer.callsLeft).toBe(99);
  });

  it('refuses a part that is not a JPEG, or too many photos, before a call is spent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      callAs(sam, 'draftRecipe', {
        householdId,
        photos: [{ parts: [JPEG_BASE64, 'iVBORw0KGgo='] }],
      }),
      'listPhotoNotSupported',
    );
    await expectRefusal(
      callAs(sam, 'draftRecipe', {
        householdId,
        photos: Array.from({ length: 9 }, () => ({ parts: [JPEG_BASE64] })),
      }),
      'badRequest',
    );
    expect(await anyCallSpent(householdId)).toBe(false);
  });

  it('refuses what is not a photo before a call is spent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      callAs(sam, 'draftRecipe', {
        householdId,
        photo: { mimeType: 'image/png', data: JPEG_BASE64 },
      }),
      'listPhotoNotSupported',
    );
    expect(await anyCallSpent(householdId)).toBe(false);
  });

  it('refuses a page that isn’t public, or is too long, before a call is spent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      draft(sam, householdId, aPage({ url: 'http://192.168.1.1/recipe' })),
      'sourceLinkNotPublic',
    );
    await expectRefusal(draft(sam, householdId, aPage({ text: 'x'.repeat(60_001) })), 'badRequest');
    expect(await anyCallSpent(householdId)).toBe(false);
  });

  it('passes on the model’s refusal and gives the call back', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb().collection('aiEmulator').doc('recipeImport').set({ failWith: 'blocked' });
    await expectRefusal(draft(sam, householdId), 'aiDeclined');
    await modelAnswers(CANNED);
    expect((await draft(sam, householdId)).callsLeft).toBe(99);
  });

  it('stops at the feature’s own switch', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb()
      .collection('appConfig')
      .doc('ai')
      .set({ features: { recipeImport: false } });
    await expectRefusal(draft(sam, householdId), 'aiSwitchedOff');
  });

  it('is refused with the flag off, off premium, without meals at edit and to a kid device', async () => {
    const free = await householdOfTwo();
    await expectRefusal(draft(free.sam, free.householdId), 'premiumRequired');
    const { thandi, householdId } = await aPremiumHousehold('helper');
    await expectRefusal(draft(thandi, householdId), 'mealsNotShared');
    await expectRefusal(draft(await aKidDevice(householdId), householdId), 'kidAccount');
    await adminDb().collection('appConfig').doc('flags').set({ householdRecipes: false });
    await expectRefusal(draft(free.sam, free.householdId), 'householdRecipesOff');
  });
});

describe('the emulator’s live switch (recipes ADR-0008 §11)', () => {
  it('stays canned for another feature with live: true: no Vertex is reached', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb()
      .collection('aiEmulator')
      .doc('listScan')
      .set({ live: true, reply: JSON.stringify({ items: [{ name: 'Milk', quantity: null }] }) });
    const answer = await callAs<{ lines: { name: string }[] }>(sam, 'readShoppingList', {
      householdId,
      mimeType: 'image/jpeg',
      data: JPEG_BASE64,
    });
    expect(answer.lines.map(({ name }) => name)).toEqual(['Milk']);
  });

  it('stays canned for recipe import when the field is absent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb()
      .collection('aiEmulator')
      .doc('recipeImport')
      .set({ reply: JSON.stringify({ isRecipe: false }) });
    const answer = await callAs<{ isRecipe: boolean }>(sam, 'draftRecipe', {
      householdId,
      photo: { mimeType: 'image/jpeg', data: JPEG_BASE64 },
    });
    expect(answer.isRecipe).toBe(false);
  });
});

describe('reading a PDF’s recipes (recipes ADR-0009)', () => {
  const page = (number: number): { number: number; data: string } => ({
    number,
    data: JPEG_BASE64,
  });

  const readPage = (number: number, whole: boolean): Record<string, unknown> => ({
    number,
    top: JPEG_BASE64,
    bottom: JPEG_BASE64,
    whole: whole ? JPEG_BASE64 : null,
  });

  const modelAnswers = async (feature: string, reply: unknown): Promise<void> => {
    await adminDb()
      .collection('aiEmulator')
      .doc(feature)
      .set({ reply: JSON.stringify(reply) });
  };

  const callsSpent = async (householdId: string): Promise<number> => {
    const usage = await home(householdId).collection('aiUsage').doc(MONTH).get();
    return (usage.get('calls') as number | undefined) ?? 0;
  };

  interface Scanned {
    readonly recipes: unknown[];
    readonly callsLeft: number;
  }

  interface Drafted {
    readonly isRecipe: boolean;
    readonly recipe: Record<string, unknown>;
    readonly photo: unknown;
    readonly callsLeft: number;
  }

  const scan = (
    user: TestUser,
    householdId: string,
    pages = [page(1), page(2), page(3)],
  ): Promise<Scanned> =>
    callAs<Scanned>(user, 'scanRecipeDocument', {
      householdId,
      documentName: 'Dough it easy',
      pages,
    });

  const draftFromPages = (user: TestUser, householdId: string): Promise<Drafted> =>
    callAs<Drafted>(user, 'draftDocumentRecipe', {
      householdId,
      documentName: 'Dough it easy',
      recipeName: 'Focaccia',
      pages: [readPage(1, false), readPage(3, true)],
    });

  it('lists the recipes on the pages it was sent, for one call, storing nothing', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers('recipeDocument', {
      recipes: [
        { name: 'Focaccia', summary: 'Bread.', pages: [3, 9], usesPages: [1] },
        { name: 'Ghost', pages: [40] },
      ],
    });
    const answer = await scan(sam, householdId);
    expect(answer).toEqual({
      recipes: [{ name: 'Focaccia', summary: 'Bread.', pages: [3], usesPages: [1] }],
      callsLeft: 99,
    });
    expect((await home(householdId).collection('recipes').count().get()).data().count).toBe(0);
  });

  it('drafts one recipe for one call, though it asks the model twice', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers('recipeImport', {
      isRecipe: true,
      name: 'Focaccia',
      placement: { dinner: 'side' },
      servings: null,
      ingredients: [{ name: 'Flour', quantity: 400, unit: 'g', group: 'Base dough' }],
      steps: ['Mix it.', 'Bake it.'],
      photo: { page: 3, box: [560, 50, 888, 491] },
    });
    const answer = await draftFromPages(sam, householdId);
    expect(answer.recipe).toMatchObject({
      name: 'Focaccia',
      origin: 'document',
      sourceUrl: null,
      sourceName: 'Dough it easy',
    });
    expect(answer.photo).toEqual({ page: 3, box: [560, 50, 888, 491] });
    expect(answer.callsLeft).toBe(99);
    expect(await callsSpent(householdId)).toBe(1);
  });

  it('refuses a page that is not a JPEG before a call is spent', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      scan(sam, householdId, [{ number: 1, data: Buffer.from('%PDF-1.4').toString('base64') }]),
      'documentPageUnreadable',
    );
    expect(await callsSpent(householdId)).toBe(0);
  });

  it('stops at its own switch, off premium, and without meals at edit', async () => {
    const free = await householdOfTwo();
    await expectRefusal(scan(free.sam, free.householdId), 'premiumRequired');
    const { sam, thandi, householdId } = await aPremiumHousehold('helper');
    await expectRefusal(scan(thandi, householdId), 'mealsNotShared');
    await expectRefusal(draftFromPages(thandi, householdId), 'mealsNotShared');
    await adminDb()
      .collection('appConfig')
      .doc('ai')
      .set({ features: { recipeDocument: false } });
    await expectRefusal(scan(sam, householdId), 'aiSwitchedOff');
  });

  it('saves a recipe that came from a PDF', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const recipeId = newRecipeId();
    await callAs(
      sam,
      'saveHouseholdRecipe',
      recipeBody(householdId, recipeId, {
        origin: 'document',
        sourceUrl: null,
        sourceName: 'Dough it easy',
      }),
    );
    const saved = await home(householdId).collection('recipes').doc(recipeId).get();
    expect(saved.get('origin')).toBe('document');
    expect(saved.get('sourceName')).toBe('Dough it easy');
  });
});
