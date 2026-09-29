import type { Firestore } from 'firebase-admin/firestore';

import { isKeptContentType } from './shared_file';
import { endsLabel } from './share_page_copy';
import type { SharePage } from './share_page';
import { checkPin } from './share_pin_check';
import { lookUpShare, type LiveShare } from './share_lookup';
import { recordShareOpen } from './share_open_log';
import { sharedObjectPath } from './share_refs';
import { passFor, passIsValid, type PinHash } from './share_secrets';

/** What somebody holding a link asked for. Parsed at the edge; never trusted. */
export interface ShareRequest {
  readonly token: string;
  /** The file itself, rather than the page around it. */
  readonly wantsFile: boolean;
  /** The pass a right PIN earned, carried by the file request. */
  readonly pass: string | null;
  /** A PIN typed into the page's form. */
  readonly pin: string | null;
}

export interface SharedFile {
  readonly objectPath: string;
  readonly contentType: string;
  readonly documentName: string;
}

export type ShareOutcome =
  | { readonly kind: 'page'; readonly page: SharePage }
  | { readonly kind: 'file'; readonly file: SharedFile };

/**
 * The service behind `documentShare` (documents ADR-0006, `BE-01`): a link's
 * request in, what to send back out, with no HTTP in sight. The transport
 * streams the file; this decides whether there is one, and records the open
 * before saying yes.
 *
 * [objectExists] is how it asks Storage, so a document whose bytes are gone
 * is refused rather than logged as opened.
 */
export async function answerShareRequest(
  store: Firestore,
  request: ShareRequest,
  objectExists: (path: string) => Promise<boolean>,
  now: Date = new Date(),
): Promise<ShareOutcome> {
  const found = await lookUpShare(store, request.token, now);
  if (found.kind === 'notFound') return page({ kind: 'notFound' });
  if (found.kind === 'refused') return page({ kind: found.verdict });
  const live = found.live;

  let pin: PinHash | null = null;
  if (live.share.hasPin) {
    const unlocked = await unlockWithPin(store, live, request, now);
    if (unlocked.kind === 'page') return unlocked;
    pin = unlocked.pin;
  }

  if (!request.wantsFile) return page(documentPage(request.token, live, pin, now));
  if (!isKeptContentType(live.contentType)) return page({ kind: 'ended' });
  const file = sharedFileOf(live);
  if (!(await objectExists(file.objectPath))) return page({ kind: 'ended' });
  await recordShareOpen(store, live);
  return { kind: 'file', file };
}

/**
 * A PIN link opens for a right PIN typed now, or for a file request carrying
 * a pass a right PIN earned in the last fifteen minutes. Anything else is the
 * PIN form.
 */
async function unlockWithPin(
  store: Firestore,
  live: LiveShare,
  request: ShareRequest,
  now: Date,
): Promise<{ kind: 'unlocked'; pin: PinHash } | { kind: 'page'; page: SharePage }> {
  const formQuery = `?t=${request.token}`;
  if (request.pin !== null) {
    const checked = await checkPin(store, live, request.pin);
    if (checked.kind === 'locked') return page({ kind: 'locked' });
    if (checked.kind === 'wrong') {
      return page({ kind: 'pin', formQuery, attemptsLeft: checked.attemptsLeft });
    }
    return { kind: 'unlocked', pin: checked.pin };
  }
  const stored = pinOf(live);
  if (request.wantsFile && stored !== null && request.pass !== null) {
    if (passIsValid(request.pass, stored, live.shareId, now)) {
      return { kind: 'unlocked', pin: stored };
    }
  }
  return page({ kind: 'pin', formQuery, attemptsLeft: null });
}

function pinOf(live: LiveShare): PinHash | null {
  const { pinHash, pinSalt } = live.token;
  return pinHash === null || pinSalt === null ? null : { pinHash, pinSalt };
}

function documentPage(token: string, live: LiveShare, pin: PinHash | null, now: Date): SharePage {
  const pass = pin === null ? '' : `&p=${passFor(pin, live.shareId, now)}`;
  return {
    kind: 'document',
    householdName: live.householdName,
    documentName: live.documentName,
    isImage: live.contentType.startsWith('image/'),
    endsLabel: endsLabel({
      expiresAt: live.share.expiresAt.toDate(),
      untilShiftEnds: live.share.shiftId !== null,
      timeZone: live.timeZone,
    }),
    fileQuery: `?t=${token}&file=1${pass}`,
  };
}

function sharedFileOf(live: LiveShare): SharedFile {
  return {
    objectPath: sharedObjectPath(live.address),
    contentType: live.contentType,
    documentName: live.documentName,
  };
}

function page(value: SharePage): { kind: 'page'; page: SharePage } {
  return { kind: 'page', page: value };
}
