import { createServer, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';

import { expect } from 'vitest';

import { CallFailed, adminDb, callAs, signUp, type TestUser } from './emulator_harness';

/**
 * What the calendar sync callables need around them: a household with two
 * accounts in it, and a calendar served from this machine — the emulator lets
 * a Function fetch from loopback, the cloud never does (calendar ADR-0003).
 */
export interface HouseholdOfTwo {
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly householdId: string;
}

export async function householdOfTwo(): Promise<HouseholdOfTwo> {
  const sam = await signUp();
  const thandi = await signUp();
  const { householdId } = await callAs<{ householdId: string }>(sam, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam Parent',
    adminColor: 'violet',
  });
  const ref = adminDb().collection('households').doc(householdId).collection('members').doc();
  await ref.set({
    displayName: 'Thandi',
    color: 'mint',
    role: 'helper',
    claimedBy: null,
    createdAt: new Date(),
  });
  const invite = await callAs<{ code: string }>(sam, 'createInvite', {
    householdId,
    memberId: ref.id,
  });
  await callAs(thandi, 'redeemInvite', { code: invite.code });
  return { sam, thandi, householdId };
}

export async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}

/** A calendar on this machine whose body a test can change between syncs. */
export class CalendarServer {
  body = '';
  status = 200;
  private server: Server | undefined;

  async start(): Promise<string> {
    this.server = createServer((_request, response) => {
      response.writeHead(this.status, { 'Content-Type': 'text/calendar' });
      response.end(this.body);
    });
    await new Promise<void>((resolve) => this.server?.listen(0, '127.0.0.1', resolve));
    const { port } = this.server.address() as AddressInfo;
    return `http://127.0.0.1:${String(port)}/family.ics`;
  }

  async stop(): Promise<void> {
    const server = this.server;
    if (server === undefined) return;
    await new Promise<void>((resolve) => {
      server.close(() => {
        resolve();
      });
    });
  }
}

/** A calendar of all-day events, one per day given, two weeks from now. */
export function calendarOf(
  ...events: { uid: string; title: string; offsetDays: number }[]
): string {
  const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0'];
  for (const event of events) {
    const date = new Date(Date.now() + event.offsetDays * 86_400_000)
      .toISOString()
      .slice(0, 10)
      .replace(/-/g, '');
    lines.push(
      'BEGIN:VEVENT',
      `UID:${event.uid}`,
      `SUMMARY:${event.title}`,
      `DTSTART;VALUE=DATE:${date}`,
      'END:VEVENT',
    );
  }
  lines.push('END:VCALENDAR');
  return lines.join('\r\n');
}

export async function syncedTitles(householdId: string): Promise<string[]> {
  const snapshot = await adminDb()
    .collection('households')
    .doc(householdId)
    .collection('syncedEvents')
    .get();
  return snapshot.docs.map((doc) => String(doc.get('title'))).sort();
}
