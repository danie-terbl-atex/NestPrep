#!/usr/bin/env node
/**
 * Seeds the emulator suite so a local run signs straight into a lived-in
 * household (accounts ADR-0001, foundation ADR-0018):
 *
 * - three users with **fixed uids** — parent, partner, helper — so the seeded
 *   sign-in buttons are the same account on every device and after every
 *   restart; created verified, the way a Google account arrives;
 * - the demo household they share (`demo-household.mjs`), with two children,
 *   premium and every V2 flag on;
 * - the canned answers the emulator's model gives (foundation ADR-0015);
 * - NestPrep's recipes, their photos and the starter boxes (recipes ADR-0001,
 *   ADR-0003, lunch-box ADR-0018), as `seed-catalogue.mjs` publishes them to
 *   the cloud.
 *
 * Safe to run again, and safe over data the suite imported: users are
 * refreshed in place, and a user an earlier seed made under a random uid is
 * replaced by the fixed one. They exist only in the emulator; nothing here is
 * a secret (ENG-18).
 *
 * The same list is in `app/lib/app/seeded_sign_in.dart` — keep them equal.
 *
 *     npm run build && npm run seed        (with the emulator suite already running)
 */
import { createRequire } from 'node:module';

import { cannedLunchIdeasReply, cannedLunchWeekReply } from './canned-plan-week.mjs';
import { earnStars, seedLooks } from './cloud-demo/avatars.mjs';
import { HOUSEHOLD_ID, PEOPLE, seedDemoHousehold, upsert } from './demo-household.mjs';

const PROJECT = process.env.NESTPREP_EMULATOR_PROJECT ?? 'nestprep-643b7';
const PASSWORD = 'nestprep';

// The Admin SDK finds the suite through these; set before it starts.
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= '127.0.0.1:9199';
process.env.GCLOUD_PROJECT ??= PROJECT;
process.env.GOOGLE_CLOUD_PROJECT ??= PROJECT;
// Nothing here needs Google credentials; without this the SDK first probes for
// a cloud metadata server that a laptop does not have, and warns after a timeout.
process.env.METADATA_SERVER_DETECTION ??= 'none';

const require = createRequire(import.meta.url);
const { db } = require('../lib/shared/firestore.js');
const { auth } = require('../lib/shared/auth.js');
const { publishCatalogue } = require('../lib/catalogue/publish_catalogue.js');
const { objectStore } = require('../lib/shared/storage.js');

/** Creates the user under its fixed uid, or brings an existing one back to the seed. */
async function seedUser({ uid, email, displayName }) {
  const fields = { email, password: PASSWORD, displayName, emailVerified: true };
  const byEmail = await auth()
    .getUserByEmail(email)
    .catch((error) => {
      if (error?.code === 'auth/user-not-found') return null;
      throw error;
    });
  if (byEmail !== null && byEmail.uid !== uid) {
    // An earlier seed's random uid: the address has to be freed for the fixed one.
    await auth().deleteUser(byEmail.uid);
  }
  if (byEmail?.uid === uid) {
    await auth().updateUser(uid, fields);
    return `refreshed ${email} (${uid})`;
  }
  await auth().createUser({ uid, ...fields });
  return `created ${email} (${uid})`;
}

/**
 * The household's looks (avatars ADR-0001, ADR-0004): Mia three days of
 * stars, so her Nestling has fledged, and the crown she bought with them;
 * Leo still an egg; Sam grown, in glasses.
 */
async function seedEmulatorLooks(store) {
  await earnStars(store, HOUSEHOLD_ID, 'mia', {
    dates: ['2026-11-01', '2026-11-02', '2026-11-03'],
    each: 10,
    title: 'Helped at home',
  });
  return seedLooks(store, HOUSEHOLD_ID, {
    chosenBy: 'sam',
    purchases: [{ id: 'demo-mia-crown', memberId: 'mia', accessoryId: 'acc-crown' }],
    looks: [
      { memberId: 'mia', choice: { base: 'preset:pip', wear: { top: 'acc-crown' } } },
      { memberId: 'leo', choice: { base: 'preset:olive', wear: {} } },
      {
        memberId: 'sam',
        choice: { base: 'preset:sunny', stage: 3, wear: { face: 'acc-round-glasses' } },
      },
      { memberId: 'alex', choice: { base: 'preset:pebble', stage: 3, wear: { top: 'acc-cap' } } },
    ],
  });
}

/**
 * What the emulator's model answers when a school letter is snapped (calendar
 * ADR-0005): two events a week and two weeks out, so a local run shows a
 * review list. There is no Vertex under the emulator; only Functions read it.
 */
async function seedCannedReplies(store) {
  const day = (offset) => new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10);
  const letter = {
    events: [
      {
        title: 'Spring market',
        date: day(7),
        allDay: false,
        startTime: '14:00',
        endTime: '16:00',
        repeat: 'none',
        children: [],
        note: 'Bring cash for the stalls',
      },
      { title: 'Civvies day', date: day(14), allDay: true, repeat: 'none', children: ['child-1'] },
    ],
  };
  const replies = store.collection('aiEmulator');
  await replies.doc('schoolLetter').set({ reply: JSON.stringify(letter) });
  // Plan my week's two steps (lunch-box ADR-0012), in the Functions' placeholders.
  await replies.doc('lunchIdeas').set({ reply: JSON.stringify(cannedLunchIdeasReply) });
  await replies.doc('lunchWeek').set({ reply: JSON.stringify(cannedLunchWeekReply) });
  // Snap a shopping list (list-scan ADR-0001): what any photo reads as locally.
  const shoppingList = {
    items: [
      { name: 'Full cream milk', quantity: '2 l' },
      { name: 'Brown bread', quantity: null },
      { name: 'Free range eggs', quantity: '1 dozen' },
      { name: 'Bananas', quantity: '1 kg' },
      { name: 'Cheddar cheese', quantity: null },
      { name: 'Rooibos tea', quantity: null },
    ],
  };
  await replies.doc('listScan').set({ reply: JSON.stringify(shoppingList) });
  // Import a recipe (recipes ADR-0008): what any page or photo reads as locally.
  // A start clears `live`, so the real model is only ever on by a person's choice that run.
  const recipe = {
    isRecipe: true,
    name: 'Bobotie',
    summary: 'Spiced mince baked under a golden egg custard.',
    placement: { dinner: 'main' },
    servings: 6,
    prepMinutes: 20,
    cookMinutes: 40,
    ingredients: [
      { name: 'Beef mince', quantity: 1, unit: 'kg', note: null, group: null },
      { name: 'Onions', quantity: 2, unit: null, note: 'chopped', group: null },
      { name: 'Medium curry powder', quantity: 2, unit: 'tbsp', note: null, group: null },
      { name: 'Eggs', quantity: 2, unit: null, note: null, group: 'For the custard' },
      { name: 'Milk', quantity: 250, unit: 'ml', note: null, group: 'For the custard' },
    ],
    steps: [
      'Fry the onions until soft, then brown the mince with the curry powder.',
      'Press the mince into a baking dish.',
      'Beat the eggs and milk together and pour over the mince.',
      'Bake at 180°C for 40 minutes, until the custard is set.',
    ],
    notes: 'Serve with yellow rice and chutney.',
  };
  await replies.doc('recipeImport').set({ reply: JSON.stringify(recipe) });
  // Avatar creations (avatars ADR-0003): drawings read as a creature, then as a
  // person drawn as a Nestling from words, in turn; any photo as a pet; any
  // buddy words and any made picture as fine.
  const creature = {
    kind: 'drawing-of-creature',
    hairColour: null,
    outfit: null,
    favouriteThings: ['a star'],
    mood: 'happy',
  };
  const person = {
    kind: 'drawing-of-person',
    hairColour: 'yellow scribbles',
    outfit: 'a pink dress with yellow dots',
    favouriteThings: ['a sun', 'a kite'],
    mood: 'happy',
  };
  await replies.doc('avatarDrawingCheck').set({
    cycle: [JSON.stringify(creature), JSON.stringify(person)],
  });
  await replies.doc('avatarPetCheck').set({
    reply: JSON.stringify({ ...creature, kind: 'photo-of-pet', favouriteThings: [] }),
  });
  await replies.doc('avatarExtraCheck').set({ reply: JSON.stringify({ allowed: true }) });
  await replies.doc('avatarResultCheck').set({
    reply: JSON.stringify({ realisticHumanFace: false, logo: false, text: false }),
  });
  return 'canned school-letter, plan-my-week, shopping-list, recipe-import and avatar replies for the emulator model';
}

/**
 * One school-morning routine for both children (kid-routines ADR-0001), worth
 * three stars, in the shape the client writes.
 */
async function seedMorningRoutine(store) {
  const step = (id, title, picture, parts = []) => ({ id, title, picture, parts });
  await upsert(store.doc(`households/${HOUSEHOLD_ID}/kidRoutines/demo-morning`), {
    name: 'Morning',
    slot: 'morning',
    kidIds: ['mia', 'leo'],
    firstDate: '2026-11-01',
    recurrence: { frequency: 'weekly', interval: 1, weekdays: [1, 2, 3, 4, 5], until: null },
    finishBy: 7 * 60 + 15,
    points: 3,
    steps: [
      step('s1', 'Get dressed', 'get-dressed'),
      step('s2', 'Eat breakfast', 'eat-breakfast'),
      step('s3', 'Brush teeth', 'brush-teeth'),
      step('s4', 'Pack school bag', 'pack-school-bag', [
        { id: 'p1', text: 'Lunchbox', picture: 'pack-lunchbox', weekdays: [] },
        { id: 'p2', text: 'Water bottle', picture: 'fill-water-bottle', weekdays: [] },
        { id: 'p3', text: 'Swimming kit', weekdays: [3] },
      ]),
      step('s5', 'Shoes on', 'put-on-shoes'),
    ],
    createdBy: 'sam',
  });
  return 'a morning routine for Mia and Leo';
}

const lines = [];
for (const person of PEOPLE) lines.push(await seedUser(person));
lines.push(await seedDemoHousehold(db()));
lines.push(await seedCannedReplies(db()));
lines.push(await seedEmulatorLooks(db()));
lines.push(await seedMorningRoutine(db()));
const catalogue = await publishCatalogue(db(), objectStore(), { write: true });
lines.push(
  `recipe photos: ${catalogue.photos.uploaded} uploaded, ${catalogue.photos.present} already there`,
);
for (const { collection, published, retired, unchanged } of catalogue.collections) {
  lines.push(`${collection}: ${published} published, ${retired} retired, ${unchanged} unchanged`);
}
for (const line of lines) console.log(line);
console.log(`\npassword for all of them: ${PASSWORD}`);
