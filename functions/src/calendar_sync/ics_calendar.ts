import type { CalendarSource, FetchOutcome } from './calendar_source';
import type { SyncWindow } from './external_occurrence';
import { type HttpClient, HttpUnreachable } from '../shared/http_client';
import { icsOccurrences } from './ics_occurrences';
import { parseIcs } from './ics_parser';
import { type HostResolver, isPublicHost, normaliseCalendarLink } from './link_guard';

/**
 * A calendar link: an iCloud calendar shared publicly, a school's or a club's
 * published calendar, anything that serves ICS (calendar ADR-0003). It is
 * Apple's way in, because Apple has no calendar API.
 */
export type Download =
  | { readonly kind: 'ok'; readonly text: string }
  | { readonly kind: 'unreachable' }
  | { readonly kind: 'notACalendar' };

const MAX_REDIRECTS = 3;

export class IcsCalendar implements CalendarSource {
  constructor(
    private readonly http: HttpClient,
    private readonly resolve: HostResolver,
    /** Only the emulator, whose tests serve a calendar from this machine. */
    private readonly isEmulator: boolean,
  ) {}

  async fetchOccurrences(credential: string, window: SyncWindow): Promise<FetchOutcome> {
    const download = await this.download(credential);
    if (download.kind !== 'ok') return download;
    const events = parseIcs(download.text);
    if (events === null) return { kind: 'notACalendar' };
    return { kind: 'ok', occurrences: icsOccurrences(events, window), refreshedCredential: null };
  }

  /** A link holds no token to give back; forgetting it is the whole of it. */
  revoke(): Promise<void> {
    return Promise.resolve();
  }

  /** The link, checked and fetched, following at most three redirects. */
  async download(link: string): Promise<Download> {
    let url = normaliseCalendarLink(link, this.isEmulator);
    for (let hop = 0; hop <= MAX_REDIRECTS && url !== null; hop++) {
      if (!(await isPublicHost(url.hostname, this.resolve, this.isEmulator))) {
        return { kind: 'notACalendar' };
      }
      let response;
      try {
        response = await this.http.send(url.toString(), {
          method: 'GET',
          headers: { Accept: 'text/calendar, */*' },
        });
      } catch (error) {
        if (error instanceof HttpUnreachable) return { kind: 'unreachable' };
        throw error;
      }
      if (response.status >= 300 && response.status < 400 && response.location !== null) {
        url = normaliseCalendarLink(new URL(response.location, url).toString(), this.isEmulator);
        continue;
      }
      if (response.status === 404 || response.status === 410) return { kind: 'notACalendar' };
      if (response.status !== 200) return { kind: 'unreachable' };
      if (!/BEGIN:VCALENDAR/i.test(response.body.slice(0, 2048))) return { kind: 'notACalendar' };
      return { kind: 'ok', text: response.body };
    }
    return { kind: 'notACalendar' };
  }
}

/** What a household sees for a link: its host, without the secret path. */
export function labelForLink(link: string): string {
  return normaliseCalendarLink(link, true)?.hostname ?? '';
}
