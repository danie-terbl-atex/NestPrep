#!/usr/bin/env node
/**
 * Creates the users the emulator's Auth is expected to have, so a local run can
 * sign in without Google (accounts ADR-0001, ADR-0002).
 *
 * They are created **already verified**, because createHousehold and redeemInvite
 * refuse a caller whose address is unproved (accounts ADR-0002) and a seeded user
 * has no inbox to prove one from. An unverified seeded user is a local run that
 * cannot make a household — which reads as a broken callable, not as the gate
 * working. The unverified path has tests of its own; it does not need the seed. They exist only in the emulator,
 * which is thrown away; nothing here is a secret (ENG-18).
 *
 * The same list is in `app/lib/app/emulator_accounts.dart` — keep them equal.
 *
 *     npm run seed        (with the emulator suite already running)
 */
const HOST = process.env.NESTPREP_AUTH_EMULATOR ?? 'http://127.0.0.1:9099';
const PROJECT = process.env.NESTPREP_EMULATOR_PROJECT ?? 'nestprep-643b7';
const PASSWORD = 'nestprep';

const ACCOUNTS = [
  { email: 'parent@nestprep.test', displayName: 'Sam Parent' },
  { email: 'partner@nestprep.test', displayName: 'Alex Parent' },
  { email: 'helper@nestprep.test', displayName: 'Thandi Helper' },
];

const signUpUrl = `${HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp` + `?key=fake-api-key`;

async function seed({ email, displayName }) {
  const response = await fetch(signUpUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer owner',
      'X-Firebase-Locale': 'en',
    },
    body: JSON.stringify({
      email,
      password: PASSWORD,
      displayName,
      emailVerified: true,
      returnSecureToken: false,
      targetProjectId: PROJECT,
    }),
  });
  const body = await response.json();
  if (response.ok) return `created ${email}`;
  if (body?.error?.message === 'EMAIL_EXISTS') return `already there: ${email}`;
  throw new Error(`${email}: ${body?.error?.message ?? response.status}`);
}

/**
 * What the emulator's model answers when a school letter is snapped (calendar
 * ADR-0005, foundation ADR-0015): there is no Vertex under the emulator, so
 * the canned reply is a Firestore document only Functions read. Two events a
 * week and two weeks out, so a local run shows a review list.
 */
const FIRESTORE = process.env.NESTPREP_FIRESTORE_EMULATOR ?? 'http://127.0.0.1:8080';

async function seedLetterReply() {
  const day = (offset) => new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10);
  const reply = {
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
  const url = `${FIRESTORE}/v1/projects/${PROJECT}/databases/(default)/documents/aiEmulator/schoolLetter`;
  const response = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ fields: { reply: { stringValue: JSON.stringify(reply) } } }),
  });
  if (!response.ok) throw new Error(`canned letter reply: ${response.status}`);
  return 'canned school-letter reply for the emulator model';
}

const results = await Promise.all([...ACCOUNTS.map(seed), seedLetterReply()]);
for (const line of results) console.log(line);
console.log(`\npassword for all of them: ${PASSWORD}`);
