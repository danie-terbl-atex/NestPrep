import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { monthKeyIn } from '../../src/ai/usage_rules';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * `readSchoolLetter` end to end, over HTTP with a real token (calendar
 * ADR-0005, foundation ADR-0015, BE-14). The emulator's model answers from
 * `aiEmulator/schoolLetter`, so nothing leaves the machine; everything else —
 * the flag, the grant, the file check, the cap claimed in a transaction, the
 * ledger, the refund — is the real code path.
 */

const PDF = Buffer.from('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n').toString('base64');
const JPEG_BYTES_AS_PDF = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString('base64');
const MONTH = monthKeyIn('Africa/Johannesburg', new Date());

interface Home {
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly householdId: string;
  readonly kidMemberId: string;
}

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

/** Sam the admin, Thandi a helper on the defaults, and Mia in Grade 3 at Parkview. */
async function aHousehold(): Promise<Home> {
  const { sam, thandi, householdId } = await householdOfTwo('helper');
  const kid = home(householdId).collection('members').doc();
  await kid.set({ displayName: 'Mia', color: 'mint', role: 'kid', claimedBy: null });
  await home(householdId).collection('schools').doc('s1').set({ name: 'Parkview Primary' });
  await home(householdId)
    .collection('familyProfiles')
    .doc(kid.id)
    .set({ schoolId: 's1', grade: 'Grade 3' });
  return { sam, thandi, householdId, kidMemberId: kid.id };
}

async function modelAnswers(reply: unknown): Promise<void> {
  await adminDb()
    .collection('aiEmulator')
    .doc('schoolLetter')
    .set({ reply: JSON.stringify(reply) });
}

const letterFor = (
  householdId: string,
  data = PDF,
  mimeType = 'application/pdf',
): Record<string, string> => ({
  householdId,
  mimeType,
  data,
});

interface Proposal {
  title: string;
  date: string;
  startMinute: number | null;
  memberIds: string[];
}

const nextWeek = new Date(Date.now() + 7 * 86_400_000).toISOString().slice(0, 10);

beforeEach(async () => {
  await clearFirestore();
});

describe('a parent snapping a letter', () => {
  it('gets proposals back, with the child mapped from the placeholder, and nothing saved', async () => {
    const { sam, householdId, kidMemberId } = await aHousehold();
    await modelAnswers({
      events: [
        {
          title: 'Grade 3 zoo outing',
          date: nextWeek,
          allDay: false,
          startTime: '08:30',
          endTime: null,
          repeat: 'none',
          children: ['child-1'],
          note: 'Bring a hat',
        },
      ],
    });
    const result = await callAs<{ proposals: Proposal[]; callsLeft: number }>(
      sam,
      'readSchoolLetter',
      letterFor(householdId),
    );
    expect(result.callsLeft).toBe(9);
    expect(result.proposals).toEqual([
      expect.objectContaining({
        title: 'Grade 3 zoo outing',
        date: nextWeek,
        startMinute: 8 * 60 + 30,
        memberIds: [kidMemberId],
      }),
    ]);
    // Proposals only: the parent confirms before anything is on the calendar.
    expect((await home(householdId).collection('events').get()).size).toBe(0);
  });

  it('is counted in the household’s month, with a line that names no child', async () => {
    const { sam, householdId } = await aHousehold();
    await modelAnswers({ events: [] });
    await callAs(sam, 'readSchoolLetter', letterFor(householdId));
    const month = await home(householdId).collection('aiUsage').doc(MONTH).get();
    expect(month.data()).toMatchObject({ calls: 1, attempts: 1, byFeature: { schoolLetter: 1 } });
    const lines = await month.ref.collection('calls').get();
    expect(lines.docs.map((line) => line.data())).toEqual([
      expect.objectContaining({
        feature: 'schoolLetter',
        tier: 'free',
        uid: sam.uid,
        status: 'succeeded',
        inputTokens: 10,
      }),
    ]);
    expect(JSON.stringify(lines.docs[0]?.data())).not.toContain('Mia');
  });

  it('counts against the premium cap while the household has premium', async () => {
    const { sam, householdId } = await aHousehold();
    await modelAnswers({ events: [] });
    await home(householdId)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
    const result = await callAs<{ callsLeft: number }>(
      sam,
      'readSchoolLetter',
      letterFor(householdId),
    );
    expect(result.callsLeft).toBe(99);
  });
});

describe('the monthly cap', () => {
  it('refuses once the month is spent, without asking the model', async () => {
    const { sam, householdId } = await aHousehold();
    await home(householdId).collection('aiUsage').doc(MONTH).set({ calls: 10, attempts: 10 });
    await modelAnswers({ events: [] });
    await expectRefusal(callAs(sam, 'readSchoolLetter', letterFor(householdId)), 'aiLimitReached');
    const month = await home(householdId).collection('aiUsage').doc(MONTH).get();
    expect(month.data()).toMatchObject({ calls: 10, attempts: 10 });
  });

  it('follows a lower cap set in the console at once', async () => {
    const { sam, householdId } = await aHousehold();
    await adminDb()
      .collection('appConfig')
      .doc('ai')
      .set({ monthlyCalls: { free: 1 } });
    await modelAnswers({ events: [] });
    await callAs(sam, 'readSchoolLetter', letterFor(householdId));
    await expectRefusal(callAs(sam, 'readSchoolLetter', letterFor(householdId)), 'aiLimitReached');
  });

  it('refunds a call the model failed, and still counts the attempt', async () => {
    const { sam, householdId } = await aHousehold();
    await adminDb().collection('aiEmulator').doc('schoolLetter').set({ failWith: 'permanent' });
    await expectRefusal(callAs(sam, 'readSchoolLetter', letterFor(householdId)), 'aiUnavailable');
    const month = await home(householdId).collection('aiUsage').doc(MONTH).get();
    expect(month.data()).toMatchObject({ calls: 0, attempts: 1 });
    const [line] = (await month.ref.collection('calls').get()).docs;
    expect(line?.data()).toMatchObject({ status: 'failed', failure: 'unavailable' });
  });

  it('says a reply it cannot read is unreadable', async () => {
    const { sam, householdId } = await aHousehold();
    await adminDb().collection('aiEmulator').doc('schoolLetter').set({ reply: '{"nope":true}' });
    await expectRefusal(callAs(sam, 'readSchoolLetter', letterFor(householdId)), 'aiUnreadable');
  });
});

describe('the switches', () => {
  it('the AI kill switch refuses before anything is counted', async () => {
    const { sam, householdId } = await aHousehold();
    await adminDb().collection('appConfig').doc('ai').set({ enabled: false });
    await expectRefusal(callAs(sam, 'readSchoolLetter', letterFor(householdId)), 'aiSwitchedOff');
    expect((await home(householdId).collection('aiUsage').doc(MONTH).get()).exists).toBe(false);
  });

  it('the V2 flag refuses when it is set off', async () => {
    const { sam, householdId } = await aHousehold();
    await adminDb().collection('appConfig').doc('flags').set({ snapSchoolLetter: false });
    await expectRefusal(
      callAs(sam, 'readSchoolLetter', letterFor(householdId)),
      'letterFeatureOff',
    );
  });
});

describe('who may, and what', () => {
  it('a helper whose calendar grant is view is refused', async () => {
    const { thandi, householdId } = await aHousehold();
    await expectRefusal(
      callAs(thandi, 'readSchoolLetter', letterFor(householdId)),
      'calendarNotShared',
    );
  });

  it('somebody from another household is refused', async () => {
    const { householdId } = await aHousehold();
    const stranger = await signUp();
    await expectRefusal(callAs(stranger, 'readSchoolLetter', letterFor(householdId)), 'notAMember');
  });

  it('nobody signed in is refused', async () => {
    const { householdId } = await aHousehold();
    await expectRefusal(callAs(null, 'readSchoolLetter', letterFor(householdId)), 'notSignedIn');
  });

  it('a file that is not what it claims is refused before a call is counted', async () => {
    const { sam, householdId } = await aHousehold();
    await expectRefusal(
      callAs(sam, 'readSchoolLetter', letterFor(householdId, JPEG_BYTES_AS_PDF)),
      'letterNotSupported',
    );
    expect((await home(householdId).collection('aiUsage').doc(MONTH).get()).exists).toBe(false);
  });
});
