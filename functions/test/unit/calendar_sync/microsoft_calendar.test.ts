import { describe, expect, it } from 'vitest';

import { toSyncedEvent } from '../../../src/calendar_sync/external_occurrence';
import {
  MICROSOFT_TOKEN_URL,
  MicrosoftCalendar,
  occurrenceFromGraph,
} from '../../../src/calendar_sync/microsoft_calendar';
import { CLIENT, ScriptedHttp, formFields, json, windowIn } from './fakes';

/** Microsoft Graph's `calendarView` shape, mapped (calendar ADR-0003). */
const identity = { connectionId: 'c1', provider: 'microsoft' as const, memberId: 'm-thandi' };

describe('connecting', () => {
  it('asks for offline, read-only calendar access with PKCE', () => {
    const url = new URL(
      new MicrosoftCalendar(CLIENT, new ScriptedHttp(() => json(200, {}))).authorizationUrl({
        state: 's',
        codeChallenge: 'c',
        redirectUri: 'https://example.test/cb',
      }),
    );
    const scope = url.searchParams.get('scope') ?? '';
    expect(scope).toContain('Calendars.Read');
    expect(scope).toContain('offline_access');
    expect(scope).not.toContain('ReadWrite');
    expect(url.searchParams.get('code_challenge_method')).toBe('S256');
  });

  it('sends the scopes again with every token request, as Microsoft requires', async () => {
    const http = new ScriptedHttp(() => json(200, { access_token: 'a', refresh_token: 'r2' }));
    await new MicrosoftCalendar(CLIENT, http).exchangeCode({
      code: 'code',
      codeVerifier: 'v',
      redirectUri: 'https://example.test/cb',
    });
    expect(formFields(http.requests[0]?.request.body)['scope']).toContain('Calendars.Read');
  });
});

describe('reading the calendar', () => {
  it('asks for UTC, follows Graph paging, and keeps the rotated refresh token', async () => {
    let page = 0;
    const http = new ScriptedHttp((url) => {
      if (url === MICROSOFT_TOKEN_URL) return json(200, { access_token: 'a', refresh_token: 'r2' });
      page++;
      return page === 1
        ? json(200, {
            value: [
              {
                id: 'e1',
                subject: 'Standup',
                start: { dateTime: '2026-10-01T07:00:00.0000000' },
                end: { dateTime: '2026-10-01T07:15:00.0000000' },
              },
            ],
            '@odata.nextLink': 'https://graph.microsoft.com/v1.0/me/calendarView?$skip=1',
          })
        : json(200, { value: [] });
    });
    const outcome = await new MicrosoftCalendar(CLIENT, http).fetchOccurrences('r1', windowIn());
    expect(outcome).toMatchObject({ kind: 'ok', refreshedCredential: 'r2' });
    expect(http.requests[1]?.request.headers?.['Prefer']).toBe('outlook.timezone="UTC"');
    expect(http.requests[2]?.url).toContain('$skip=1');
  });

  it('never follows a next link off Graph, where the token would go with it', async () => {
    let lists = 0;
    const http = new ScriptedHttp((url) => {
      if (url === MICROSOFT_TOKEN_URL) return json(200, { access_token: 'a' });
      lists++;
      return json(200, { value: [], '@odata.nextLink': 'https://evil.example/steal' });
    });
    await new MicrosoftCalendar(CLIENT, http).fetchOccurrences('r1', windowIn());
    expect(lists).toBe(1);
    expect(http.requests.some((r) => r.url.includes('evil.example'))).toBe(false);
  });

  it('says revoked when the refresh token is refused', async () => {
    const http = new ScriptedHttp(() => json(400, { error: 'invalid_grant' }));
    expect(await new MicrosoftCalendar(CLIENT, http).fetchOccurrences('r', windowIn())).toEqual({
      kind: 'revoked',
    });
  });
});

describe('an instance', () => {
  it('in UTC lands on the household clock', () => {
    const occurrence = occurrenceFromGraph({
      id: 'e1',
      subject: 'Standup',
      start: { dateTime: '2026-10-01T07:00:00.0000000' },
      end: { dateTime: '2026-10-01T07:15:00.0000000' },
    });
    expect(occurrence).not.toBeNull();
    if (occurrence === null) return;
    const synced = toSyncedEvent(occurrence, identity, 'Africa/Johannesburg').document;
    expect(synced).toMatchObject({
      date: '2026-10-01',
      startMinute: 9 * 60,
      endMinute: 9 * 60 + 15,
    });
  });

  it('all day keeps its own dates, ending the day before the exclusive end', () => {
    const occurrence = occurrenceFromGraph({
      id: 'e2',
      subject: 'Half term',
      isAllDay: true,
      start: { dateTime: '2026-10-19T00:00:00.0000000' },
      end: { dateTime: '2026-10-24T00:00:00.0000000' },
    });
    if (occurrence === null) throw new Error('expected an occurrence');
    const synced = toSyncedEvent(occurrence, identity, 'Africa/Johannesburg').document;
    expect(synced).toMatchObject({
      date: '2026-10-19',
      endDate: '2026-10-23',
      startMinute: null,
      endMinute: null,
    });
  });

  it('cancelled, or declined by its owner, stays out; one with no subject comes in untitled', () => {
    const base = {
      id: 'e3',
      start: { dateTime: '2026-10-01T07:00:00.0000000' },
      end: { dateTime: '2026-10-01T08:00:00.0000000' },
    };
    expect(occurrenceFromGraph({ ...base, isCancelled: true })).toBeNull();
    expect(occurrenceFromGraph({ ...base, responseStatus: { response: 'declined' } })).toBeNull();
    expect(occurrenceFromGraph({ ...base, subject: null })?.title).toBe('');
  });
});
