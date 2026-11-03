import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { ASSISTANT_TOOLS } from '../../src/assistants/mcp/tools';
import { getHousehold } from '../../src/assistants/mcp/tools/get_household';
import { addGroceryItems } from '../../src/assistants/mcp/tools/groceries';
import { listEvents } from '../../src/assistants/mcp/tools/list_events';
import {
  HOUSEHOLD,
  LEE,
  NOMSA,
  NOW,
  PAT,
  SAM,
  THANDI,
  acceptingOnly,
  bearer,
  exchange,
  givenNomsaOnShift,
  givenTheOakStreetNest,
  modern,
  principalFor,
  rpc,
} from './assistants_mcp_fixture';
import { adminDb, clearFirestore } from './emulator_harness';

/**
 * `requireAccess` for real, through each tool (assistants ADR-0003): a
 * connection does no more than its member could in the app at that moment —
 * admins and parents only in v1, a claimed profile, both switches on, the
 * household's own switch on, and still a member on the second call.
 */

const household = (): DocumentReference => adminDb().collection('households').doc(HOUSEHOLD);

/** Arguments every tool accepts, so the refusal is the access check's and not the schema's. */
const VALID_ARGS: Record<string, unknown> = {
  get_household: {},
  list_events: { from: '2026-10-29', to: '2026-11-04' },
  create_event: { title: 'Dentist', date: '2026-11-02' },
  update_event: { event_id: 'missing', title: 'x' },
  delete_event: { event_id: 'missing' },
  get_grocery_list: {},
  add_grocery_items: { items: [{ name: 'Milk' }] },
  update_grocery_item: { item_id: 'missing', name: 'x' },
  tick_grocery_items: { item_ids: ['missing'] },
  remove_grocery_items: { item_ids: ['missing'] },
};

beforeEach(async () => {
  await clearFirestore();
  await givenTheOakStreetNest();
});

describe('who may use an assistant in v1', () => {
  it('an admin and a parent who claimed their profiles', async () => {
    await expect(getHousehold.run(adminDb(), principalFor(SAM), {}, NOW)).resolves.toMatchObject({
      you: { member_id: SAM.member },
    });
    await expect(getHousehold.run(adminDb(), principalFor(PAT), {}, NOW)).resolves.toMatchObject({
      you: { member_id: PAT.member },
    });
  });

  for (const tool of ASSISTANT_TOOLS) {
    it(`${tool.name}: a helper is refused, whatever her grant`, async () => {
      await expect(
        tool.call(adminDb(), principalFor(THANDI), VALID_ARGS[tool.name], NOW),
      ).rejects.toMatchObject({ kind: 'forbidden', reason: 'familyOnly' });
    });
  }

  it('a shift-only carer off shift is refused', async () => {
    await expect(
      addGroceryItems.run(adminDb(), principalFor(NOMSA), { items: [{ name: 'Milk' }] }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'familyOnly' });
  });

  it('and so is the same carer on shift: carers come later, behind their own switch', async () => {
    await givenNomsaOnShift(NOW);
    await expect(
      addGroceryItems.run(adminDb(), principalFor(NOMSA), { items: [{ name: 'Milk' }] }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'familyOnly' });
  });

  it('a parent who never claimed a profile is told to claim one, and nothing is written', async () => {
    await expect(
      addGroceryItems.run(adminDb(), principalFor(LEE), { items: [{ name: 'Milk' }] }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'noProfile' });
    expect((await household().collection('groceryItems').get()).size).toBe(0);
  });

  it('somebody who is not a member at all', async () => {
    await expect(
      getHousehold.run(adminDb(), principalFor({ uid: 'uid-stranger' }), {}, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'notAMember' });
  });

  it('a household that no longer exists', async () => {
    await household().delete();
    await expect(getHousehold.run(adminDb(), principalFor(SAM), {}, NOW)).rejects.toMatchObject({
      kind: 'forbidden',
      reason: 'householdNotFound',
    });
  });
});

describe('checked live on every call', () => {
  it('a member removed between two calls is refused on the second', async () => {
    const principal = principalFor(PAT);
    await listEvents.run(adminDb(), principal, { from: '2026-10-29', to: '2026-10-30' }, NOW);
    await household().update({ [`members.${PAT.uid}`]: FieldValue.delete() });
    await expect(
      listEvents.run(adminDb(), principal, { from: '2026-10-29', to: '2026-10-30' }, NOW),
    ).rejects.toMatchObject({ kind: 'forbidden', reason: 'notAMember' });
  });

  it('a parent made a helper between two calls is refused on the second', async () => {
    const principal = principalFor(PAT);
    await getHousehold.run(adminDb(), principal, {}, NOW);
    await household().update({ [`members.${PAT.uid}`]: 'helper' });
    await expect(getHousehold.run(adminDb(), principal, {}, NOW)).rejects.toMatchObject({
      reason: 'familyOnly',
    });
  });

  it("the household's own switch off refuses every tool", async () => {
    await household().collection('assistantSettings').doc('current').set({
      allowed: false,
      updatedBy: SAM.member,
      updatedAt: FieldValue.serverTimestamp(),
    });
    for (const tool of ASSISTANT_TOOLS) {
      await expect(
        tool.call(adminDb(), principalFor(SAM), VALID_ARGS[tool.name], NOW),
      ).rejects.toMatchObject({ kind: 'forbidden', reason: 'householdSwitchedOff' });
    }
  });

  it('the switch back on lets them through again', async () => {
    await household().collection('assistantSettings').doc('current').set({ allowed: true });
    await expect(getHousehold.run(adminDb(), principalFor(SAM), {}, NOW)).resolves.toBeDefined();
  });

  it('the flag off refuses inside the tool too', async () => {
    await adminDb().collection('appConfig').doc('flags').set({ assistants: false });
    await expect(getHousehold.run(adminDb(), principalFor(SAM), {}, NOW)).rejects.toMatchObject({
      kind: 'switchedOff',
    });
  });

  it('the kill switch refuses inside the tool too', async () => {
    await adminDb().collection('appConfig').doc('assistants').set({ enabled: false });
    await expect(getHousehold.run(adminDb(), principalFor(SAM), {}, NOW)).rejects.toMatchObject({
      kind: 'switchedOff',
    });
  });

  for (const tool of ASSISTANT_TOOLS) {
    it(`${tool.name} checks its own scope even when called without HTTP in front`, async () => {
      await expect(
        tool.call(adminDb(), principalFor(SAM, []), VALID_ARGS[tool.name], NOW),
      ).rejects.toMatchObject({ kind: 'insufficientScope', scope: tool.scope });
    });
  }
});

describe('a refusal reaches the assistant as a tool error in plain words', () => {
  const TOKEN = 'npa_thandi';

  it('a helper gets isError with the reason, and no internals', async () => {
    const reply = await exchange(acceptingOnly(TOKEN, principalFor(THANDI)), {
      ...modern('tools/call', { name: 'get_household', arguments: {} }),
      headers: {
        ...modern('tools/call', { name: 'get_household', arguments: {} }).headers,
        ...bearer(TOKEN),
      },
    });
    expect(reply.status).toBe(200);
    const result = rpc(reply).result as { isError: boolean; content: { text: string }[] };
    expect(result.isError).toBe(true);
    expect(result.content[0]?.text).toBe(
      'Only admins and parents can use an assistant with NestPrep for now.',
    );
  });

  it('the household switch off reads the same way', async () => {
    await household().collection('assistantSettings').doc('current').set({ allowed: false });
    const call = modern('tools/call', { name: 'get_grocery_list', arguments: {} });
    const reply = await exchange(acceptingOnly(TOKEN, principalFor(SAM)), {
      body: call.body,
      headers: { ...call.headers, ...bearer(TOKEN) },
    });
    const result = rpc(reply).result as { isError: boolean; content: { text: string }[] };
    expect(result.isError).toBe(true);
    expect(result.content[0]?.text).toMatch(/switched assistants off/);
  });
});
