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
 * - the canned answers the emulator's model gives (foundation ADR-0015).
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
import { PEOPLE, seedDemoHousehold } from './demo-household.mjs';

const PROJECT = process.env.NESTPREP_EMULATOR_PROJECT ?? 'nestprep-643b7';
const PASSWORD = 'nestprep';

// The Admin SDK finds the suite through these; set before it starts.
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.GCLOUD_PROJECT ??= PROJECT;
process.env.GOOGLE_CLOUD_PROJECT ??= PROJECT;
// Nothing here needs Google credentials; without this the SDK first probes for
// a cloud metadata server that a laptop does not have, and warns after a timeout.
process.env.METADATA_SERVER_DETECTION ??= 'none';

const require = createRequire(import.meta.url);
const { db } = require('../lib/shared/firestore.js');
const { auth } = require('../lib/shared/auth.js');

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
  return 'canned school-letter and plan-my-week replies for the emulator model';
}

const lines = [];
for (const person of PEOPLE) lines.push(await seedUser(person));
lines.push(await seedDemoHousehold(db()));
lines.push(await seedCannedReplies(db()));
for (const line of lines) console.log(line);
console.log(`\npassword for all of them: ${PASSWORD}`);
