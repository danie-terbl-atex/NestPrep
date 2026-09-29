import { beforeEach, describe, expect, it } from 'vitest';

import { runExpirySweep } from '../../src/documents/expiry_sweep';
import { adminDb, clearFirestore } from './emulator_harness';

/**
 * The daily expiry sweep against a real Firestore (documents ADR-0005, BE-15).
 *
 * A schedule cannot be triggered in the emulator, so this runs the job's body —
 * the same function the schedule calls — with a fixed "now". What it proves is
 * the part a unit test cannot: the two collection-group queries find what they
 * should and nothing else, the household's own zone decides the day, and the
 * reminders it writes are the contract notifications will read.
 */

const NOW = new Date(Date.UTC(2027, 5, 1, 3, 0)); // 05:00 in Johannesburg, 1 June 2027

async function givenAHousehold(timeZone = 'Africa/Johannesburg'): Promise<string> {
  const household = adminDb().collection('households').doc();
  await household.set({ name: 'The Parkers', timeZone, members: {} });
  return household.id;
}

async function givenAVaultDocument(
  householdId: string,
  documentId: string,
  expiresOn: string | null,
): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/vaults/m-emma/vaultDocuments/${documentId}`)
    .set({ name: `Emma ${documentId}`, contentType: 'application/pdf', sizeBytes: 1, expiresOn });
}

async function givenAHouseholdDocument(
  householdId: string,
  documentId: string,
  expiresOn: string,
): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/documents/${documentId}`)
    .set({ folderId: 'f', name: 'Car insurance', contentType: 'application/pdf', expiresOn });
}

async function remindersOf(householdId: string): Promise<Record<string, unknown>[]> {
  const found = await adminDb().collection(`households/${householdId}/expiryReminders`).get();
  return found.docs.map((reminder) => ({ id: reminder.id, ...reminder.data() }));
}

describe('the expiry sweep', () => {
  beforeEach(clearFirestore);

  it('raises the reminder each document has come due for, and no others', async () => {
    const householdId = await givenAHousehold();
    await givenAVaultDocument(householdId, 'passport', '2027-06-20'); // 19 days: the 30-day one
    await givenAVaultDocument(householdId, 'licence', '2027-12-31'); // too far off
    await givenAVaultDocument(householdId, 'no-date', null);
    await givenAHouseholdDocument(householdId, 'policy', '2027-08-30'); // 90 days: the 90-day one

    await runExpirySweep(adminDb(), NOW);

    const reminders = await remindersOf(householdId);
    expect(reminders).toHaveLength(2);
    expect(reminders).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: 'vault_m-emma_passport_2027-06-20_30',
          scope: 'vault',
          ownerMemberId: 'm-emma',
          documentId: 'passport',
          documentName: 'Emma passport',
          expiresOn: '2027-06-20',
          daysBefore: 30,
          dueOn: '2027-06-01',
          status: 'pending',
        }),
        expect.objectContaining({
          scope: 'household',
          ownerMemberId: null,
          documentId: 'policy',
          daysBefore: 90,
        }),
      ]),
    );
  });

  it('writes nothing new when it runs twice, or runs late', async () => {
    const householdId = await givenAHousehold();
    await givenAVaultDocument(householdId, 'passport', '2027-06-20');

    const first = await runExpirySweep(adminDb(), NOW);
    const second = await runExpirySweep(adminDb(), NOW);

    expect(first.created).toBe(1);
    expect(second.created).toBe(0);
    expect(await remindersOf(householdId)).toHaveLength(1);
  });

  it('moves to the next stage as the day comes closer, keeping the first', async () => {
    const householdId = await givenAHousehold();
    await givenAVaultDocument(householdId, 'passport', '2027-06-20');

    await runExpirySweep(adminDb(), NOW);
    await runExpirySweep(adminDb(), new Date(Date.UTC(2027, 5, 14, 3)));

    const stages = (await remindersOf(householdId)).map((reminder) => reminder['daysBefore']);
    expect(stages.sort()).toEqual([30, 7]);
  });

  it('decides "today" in the household"s own zone, not the server"s', async () => {
    // 23:30 UTC on 31 May is already 1 June in Johannesburg, but not in Los
    // Angeles — so a document expiring on 8 June is 7 days out in one and 8 in
    // the other.
    const lateEvening = new Date(Date.UTC(2027, 4, 31, 23, 30));
    const joburg = await givenAHousehold('Africa/Johannesburg');
    const la = await givenAHousehold('America/Los_Angeles');
    await givenAVaultDocument(joburg, 'passport', '2027-06-08');
    await givenAVaultDocument(la, 'passport', '2027-06-08');

    await runExpirySweep(adminDb(), lateEvening);

    expect((await remindersOf(joburg)).map((reminder) => reminder['daysBefore'])).toEqual([7]);
    expect((await remindersOf(la)).map((reminder) => reminder['daysBefore'])).toEqual([30]);
  });

  it('raises "expired" for a week after the day, then stops', async () => {
    const householdId = await givenAHousehold();
    await givenAVaultDocument(householdId, 'recent', '2027-05-28');
    await givenAVaultDocument(householdId, 'long-gone', '2027-04-01');

    const result = await runExpirySweep(adminDb(), NOW);

    expect(result.capped).toBe(false);
    const reminders = await remindersOf(householdId);
    expect(reminders.map((reminder) => reminder['documentId'])).toEqual(['recent']);
    expect(reminders[0]?.['daysBefore']).toBe(0);
  });
});
