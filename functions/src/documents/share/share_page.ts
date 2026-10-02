import { SHARE_PAGE_COPY as COPY } from './share_page_copy';
import { sharePageStyles } from './share_page_theme';

/**
 * What the shared-link page shows (documents ADR-0006). Pure: a value in,
 * a string of HTML out, so every state is a unit test. No script, nothing
 * external — the mark and the document come from this same function.
 */
export type SharePage =
  | {
      readonly kind: 'document';
      readonly householdName: string;
      readonly documentName: string;
      readonly isImage: boolean;
      readonly endsLabel: string;
      /** The query that fetches the file, relative to this page. */
      readonly fileQuery: string;
    }
  | {
      readonly kind: 'pin';
      /** The query the form posts back to — the link's own. */
      readonly formQuery: string;
      /** Tries left after a wrong PIN; null on the first visit. */
      readonly attemptsLeft: number | null;
    }
  | { readonly kind: 'expired' }
  | { readonly kind: 'ended' }
  | { readonly kind: 'locked' }
  | { readonly kind: 'notFound' };

/** Relative to the page, so the same markup works on any host. */
export const MARK_QUERY = '?asset=mark';

/**
 * Only this origin's images, only inline styles, only posting back here, and
 * never inside somebody else's frame.
 */
export const SHARE_PAGE_CSP =
  "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; " +
  "form-action 'self'; base-uri 'none'; frame-ancestors 'none'";

export function sharePageStatus(page: SharePage): number {
  switch (page.kind) {
    case 'document':
    case 'pin':
      return 200;
    case 'notFound':
      return 404;
    case 'expired':
    case 'ended':
    case 'locked':
      return 410;
  }
}

export function renderSharePage(page: SharePage): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer">
<title>${escapeHtml(COPY.pageTitle)}</title>
<style>${sharePageStyles()}</style>
</head>
<body><main>
<header><img src="${MARK_QUERY}" alt="" width="40" height="40"><span>${escapeHtml(COPY.brand)}</span></header>
<section class="card">${bodyOf(page)}</section>
<footer>${escapeHtml(COPY.footer)}</footer>
</main></body>
</html>`;
}

function bodyOf(page: SharePage): string {
  switch (page.kind) {
    case 'document':
      return documentBody(page);
    case 'pin':
      return pinBody(page.formQuery, page.attemptsLeft);
    case 'expired':
      return message(COPY.expiredTitle, COPY.expiredBody);
    case 'ended':
      return message(COPY.endedTitle, COPY.endedBody);
    case 'locked':
      return message(COPY.lockedTitle, COPY.lockedBody);
    case 'notFound':
      return message(COPY.notFoundTitle, COPY.notFoundBody);
  }
}

function documentBody(page: Extract<SharePage, { kind: 'document' }>): string {
  const file = escapeHtml(page.fileQuery);
  const name = escapeHtml(page.documentName);
  const shown = page.isImage
    ? `<img class="document" src="${file}" alt="${name}">`
    : `<a class="button" href="${file}">${escapeHtml(COPY.openPdf)}</a><p class="note">${escapeHtml(COPY.pdfNote)}</p>`;
  return `<p>${escapeHtml(COPY.sharedBy(page.householdName))}</p>
<h1>${name}</h1>
<span class="tag">${escapeHtml(page.endsLabel)}</span>
${shown}`;
}

function pinBody(formQuery: string, attemptsLeft: number | null): string {
  const problem =
    attemptsLeft === null
      ? ''
      : `<p class="problem" role="alert">${escapeHtml(COPY.wrongPin(attemptsLeft))}</p>`;
  return `<h1>${escapeHtml(COPY.pinTitle)}</h1>
<p>${escapeHtml(COPY.pinBody)}</p>
${problem}
<form method="post" action="${escapeHtml(formQuery)}">
<label for="pin">${escapeHtml(COPY.pinLabel)}</label>
<input id="pin" name="pin" type="password" inputmode="numeric" pattern="[0-9]*" minlength="4" maxlength="8" autocomplete="one-time-code" required autofocus>
<button class="button" type="submit">${escapeHtml(COPY.pinSubmit)}</button>
</form>`;
}

function message(title: string, body: string): string {
  return `<h1>${escapeHtml(title)}</h1><p>${escapeHtml(body)}</p>`;
}

export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
