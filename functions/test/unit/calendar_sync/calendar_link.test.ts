import { describe, expect, it } from 'vitest';

import { IcsCalendar, labelForLink } from '../../../src/calendar_sync/ics_calendar';
import {
  isPrivateAddress,
  isPublicHost,
  normaliseCalendarLink,
} from '../../../src/calendar_sync/link_guard';
import { ScriptedHttp, text, windowIn } from './fakes';

/**
 * A pasted calendar link is fetched from inside Google's network, so where it
 * leads is checked every hop (calendar ADR-0003).
 */
const publicDns = (): Promise<string[]> => Promise.resolve(['17.253.144.10']);
const ICS =
  'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:1\r\nSUMMARY:Fete\r\nDTSTART;VALUE=DATE:20261003\r\nEND:VEVENT\r\nEND:VCALENDAR';

describe('a calendar link', () => {
  it('webcal becomes https; http, ftp and a password are refused', () => {
    expect(normaliseCalendarLink('webcal://p01-caldav.icloud.com/published/2/x', false)?.href).toBe(
      'https://p01-caldav.icloud.com/published/2/x',
    );
    expect(normaliseCalendarLink('WEBCALS://example.com/c.ics', false)?.protocol).toBe('https:');
    expect(normaliseCalendarLink('http://example.com/c.ics', false)).toBeNull();
    expect(normaliseCalendarLink('ftp://example.com/c.ics', false)).toBeNull();
    expect(normaliseCalendarLink('https://sam:secret@example.com/c.ics', false)).toBeNull();
    expect(normaliseCalendarLink('not a link', false)).toBeNull();
  });

  it('is labelled by its host alone, never its secret path', () => {
    expect(labelForLink('webcal://p01-caldav.icloud.com/published/2/secret')).toBe(
      'p01-caldav.icloud.com',
    );
  });
});

describe('where a link may lead', () => {
  for (const address of [
    '127.0.0.1',
    '10.1.2.3',
    '172.16.0.1',
    '192.168.1.1',
    '169.254.169.254',
    '100.64.0.1',
    '0.0.0.0',
    '::1',
    'fd00::1',
    'fe80::1',
    '::ffff:10.0.0.1',
  ]) {
    it(`never to ${address}`, () => {
      expect(isPrivateAddress(address)).toBe(true);
    });
  }

  it('to a public address', () => {
    expect(isPrivateAddress('17.253.144.10')).toBe(false);
    expect(isPrivateAddress('2606:4700::1111')).toBe(false);
  });

  it('never to a name that resolves anywhere private, even once', async () => {
    const split = (): Promise<string[]> => Promise.resolve(['17.253.144.10', '10.0.0.5']);
    expect(await isPublicHost('mixed.example', split, false)).toBe(false);
    expect(await isPublicHost('fine.example', publicDns, false)).toBe(true);
  });

  it('to loopback only in the emulator', async () => {
    expect(await isPublicHost('127.0.0.1', publicDns, false)).toBe(false);
    expect(await isPublicHost('127.0.0.1', publicDns, true)).toBe(true);
    expect(await isPublicHost('10.0.0.1', publicDns, true)).toBe(false);
  });
});

describe('reading a link', () => {
  it('follows a redirect, checking where it goes', async () => {
    const http = new ScriptedHttp((url) =>
      url.includes('old') ? text(301, '', 'https://calendars.example/new.ics') : text(200, ICS),
    );
    const calendar = new IcsCalendar(http, publicDns, false);
    const outcome = await calendar.fetchOccurrences(
      'https://calendars.example/old.ics',
      windowIn(),
    );
    expect(outcome.kind).toBe('ok');
    expect(http.requests.map((r) => r.url)).toEqual([
      'https://calendars.example/old.ics',
      'https://calendars.example/new.ics',
    ]);
  });

  it('refuses a redirect into a private network', async () => {
    const http = new ScriptedHttp(() => text(302, '', 'http://169.254.169.254/computeMetadata/'));
    const calendar = new IcsCalendar(http, publicDns, false);
    expect(await calendar.download('https://calendars.example/c.ics')).toEqual({
      kind: 'notACalendar',
    });
    expect(http.requests).toHaveLength(1);
  });

  it('says a web page or a missing file is not a calendar, and a 500 is unreachable', async () => {
    const page = new IcsCalendar(new ScriptedHttp(() => text(200, '<html>')), publicDns, false);
    expect(await page.download('https://x.example/c')).toEqual({ kind: 'notACalendar' });
    const gone = new IcsCalendar(new ScriptedHttp(() => text(404, '')), publicDns, false);
    expect(await gone.download('https://x.example/c')).toEqual({ kind: 'notACalendar' });
    const down = new IcsCalendar(new ScriptedHttp(() => text(500, '')), publicDns, false);
    expect(await down.download('https://x.example/c')).toEqual({ kind: 'unreachable' });
  });
});
