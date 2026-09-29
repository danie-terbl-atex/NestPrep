import { describe, expect, it } from 'vitest';

import {
  GOOGLE_EVENTS_URL,
  GOOGLE_TOKEN_URL,
  GoogleCalendar,
  occurrenceFromGoogle,
} from '../../../src/calendar_sync/google_calendar';
import { toSyncedEvent } from '../../../src/calendar_sync/external_occurrence';
import { HttpUnreachable } from '../../../src/calendar_sync/http_client';
import { CLIENT, ScriptedHttp, formFields, json, windowIn } from './fakes';

/**
 * Google's event shape, mapped (calendar ADR-0003) — and the DoD line that an
 * imported repeating event keeps its wall-clock time across a clocks change.
 */
const TOKENS = json(200, { access_token: 'access', expires_in: 3599 });

function googleWith(
  pages: unknown[],
  tokens = TOKENS,
): { calendar: GoogleCalendar; http: ScriptedHttp } {
  let page = 0;
  const http = new ScriptedHttp((url) => {
    if (url === GOOGLE_TOKEN_URL) return tokens;
    const next = pages[page];
    page++;
    return json(200, next);
  });
  return { calendar: new GoogleCalendar(CLIENT, http), http };
}

describe('connecting', () => {
  it('asks for read-only calendar access, offline, with PKCE', () => {
    const url = new URL(
      new GoogleCalendar(CLIENT, new ScriptedHttp(() => TOKENS)).authorizationUrl({
        state: 'state-1',
        codeChallenge: 'challenge',
        redirectUri: 'https://example.test/cb',
      }),
    );
    expect(url.searchParams.get('scope')).toContain('calendar.readonly');
    expect(url.searchParams.get('scope')).not.toMatch(/calendar(\s|$)/);
    expect(url.searchParams.get('access_type')).toBe('offline');
    expect(url.searchParams.get('code_challenge_method')).toBe('S256');
    expect(url.searchParams.get('state')).toBe('state-1');
    expect(url.searchParams.get('redirect_uri')).toBe('https://example.test/cb');
  });

  it('exchanges the code with the verifier and reads the address off the ID token', async () => {
    const idToken = `x.${Buffer.from(JSON.stringify({ email: 'sam@example.com' })).toString('base64url')}.y`;
    const http = new ScriptedHttp(() =>
      json(200, { access_token: 'a', refresh_token: 'refresh-1', id_token: idToken }),
    );
    const account = await new GoogleCalendar(CLIENT, http).exchangeCode({
      code: 'code-1',
      codeVerifier: 'verifier-1',
      redirectUri: 'https://example.test/cb',
    });
    expect(account).toEqual({ refreshToken: 'refresh-1', accountLabel: 'sam@example.com' });
    const sent = formFields(http.requests[0]?.request.body);
    expect(sent).toMatchObject({
      grant_type: 'authorization_code',
      code: 'code-1',
      code_verifier: 'verifier-1',
      client_secret: 'client-secret',
    });
  });

  it('gives nothing back when Google hands no refresh token', async () => {
    const http = new ScriptedHttp(() => json(200, { access_token: 'a' }));
    const account = await new GoogleCalendar(CLIENT, http).exchangeCode({
      code: 'c',
      codeVerifier: 'v',
      redirectUri: 'r',
    });
    expect(account).toBeNull();
  });
});

describe('reading the calendar', () => {
  it('reads the window, expanded by Google, and pages through', async () => {
    const { calendar, http } = googleWith([
      {
        items: [
          {
            id: 'a',
            summary: 'Swimming',
            start: { dateTime: '2026-10-01T16:00:00+02:00' },
            end: { dateTime: '2026-10-01T17:00:00+02:00' },
          },
        ],
        nextPageToken: 'p2',
      },
      {
        items: [
          {
            id: 'b',
            summary: 'Holiday',
            start: { date: '2026-10-05' },
            end: { date: '2026-10-08' },
          },
        ],
      },
    ]);
    const outcome = await calendar.fetchOccurrences('refresh-1', windowIn());
    expect(outcome.kind).toBe('ok');
    if (outcome.kind !== 'ok') return;
    expect(outcome.occurrences.map((o) => o.externalId)).toEqual(['a', 'b']);
    const firstList = new URL(http.requests[1]?.url ?? '');
    expect(`${firstList.origin}${firstList.pathname}`).toBe(GOOGLE_EVENTS_URL);
    expect(firstList.searchParams.get('singleEvents')).toBe('true');
    expect(new URL(http.requests[2]?.url ?? '').searchParams.get('pageToken')).toBe('p2');
    expect(http.requests[1]?.request.headers?.['Authorization']).toBe('Bearer access');
  });

  it('says revoked when Google refuses the refresh token', async () => {
    const { calendar } = googleWith([], json(400, { error: 'invalid_grant' }));
    expect(await calendar.fetchOccurrences('gone', windowIn())).toEqual({ kind: 'revoked' });
  });

  it('says revoked when a fresh token is refused by the calendar', async () => {
    const http = new ScriptedHttp((url) => (url === GOOGLE_TOKEN_URL ? TOKENS : json(403, {})));
    expect(await new GoogleCalendar(CLIENT, http).fetchOccurrences('r', windowIn())).toEqual({
      kind: 'revoked',
    });
  });

  it('says unreachable when Google is down or does not answer', async () => {
    const down = new ScriptedHttp((url) => (url === GOOGLE_TOKEN_URL ? TOKENS : json(503, {})));
    expect(await new GoogleCalendar(CLIENT, down).fetchOccurrences('r', windowIn())).toEqual({
      kind: 'unreachable',
    });
    const silent = new ScriptedHttp(() => {
      throw new HttpUnreachable('TimeoutError');
    });
    expect(await new GoogleCalendar(CLIENT, silent).fetchOccurrences('r', windowIn())).toEqual({
      kind: 'unreachable',
    });
  });
});

describe('an instance', () => {
  it('that is cancelled or declined is not the household’s to see', () => {
    const base = {
      id: 'x',
      start: { dateTime: '2026-10-01T10:00:00Z' },
      end: { dateTime: '2026-10-01T11:00:00Z' },
    };
    expect(occurrenceFromGoogle({ ...base, status: 'cancelled' })).toBeNull();
    expect(
      occurrenceFromGoogle({ ...base, attendees: [{ self: true, responseStatus: 'declined' }] }),
    ).toBeNull();
    expect(
      occurrenceFromGoogle({ ...base, attendees: [{ self: false, responseStatus: 'declined' }] }),
    ).not.toBeNull();
  });

  it('that repeats keeps its wall-clock time across the clocks going back', () => {
    // A weekly 07:30 school run in London, written by Google as instances in
    // the event's own zone: 06:30Z in BST, 07:30Z in GMT. The household is in
    // London too, and sees 07:30 both weeks (calendar ADR-0002).
    const before = occurrenceFromGoogle({
      id: 'run_20261023',
      summary: 'School run',
      start: { dateTime: '2026-10-23T07:30:00+01:00' },
      end: { dateTime: '2026-10-23T08:00:00+01:00' },
    });
    const after = occurrenceFromGoogle({
      id: 'run_20261030',
      summary: 'School run',
      start: { dateTime: '2026-10-30T07:30:00+00:00' },
      end: { dateTime: '2026-10-30T08:00:00+00:00' },
    });
    const identity = { connectionId: 'c1', provider: 'google' as const, memberId: 'm-sam' };
    for (const occurrence of [before, after]) {
      expect(occurrence).not.toBeNull();
      if (occurrence === null) return;
      const synced = toSyncedEvent(occurrence, identity, 'Europe/London').document;
      expect(synced.startMinute).toBe(7 * 60 + 30);
      expect(synced.endMinute).toBe(8 * 60);
    }
  });
});
