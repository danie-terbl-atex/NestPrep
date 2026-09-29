import type { OAuthProvider } from './sync_documents';

/**
 * The page the browser lands on after Google or Microsoft — the one screen of
 * NestPrep that is not in the app. It says what happened in words and sends
 * the person back (FE-09); a code or a token never appears on it.
 */
export type CallbackOutcome =
  | { readonly kind: 'connected'; readonly provider: OAuthProvider }
  | { readonly kind: 'declined' }
  | { readonly kind: 'expired' }
  | { readonly kind: 'failed'; readonly provider: OAuthProvider }
  | { readonly kind: 'notConfigured' };

const PROVIDER_NAMES: Readonly<Record<OAuthProvider, string>> = {
  google: 'Google Calendar',
  microsoft: 'Outlook',
};

export function callbackCopy(outcome: CallbackOutcome): { title: string; body: string } {
  switch (outcome.kind) {
    case 'connected':
      return {
        title: `${PROVIDER_NAMES[outcome.provider]} is connected`,
        body: 'Go back to NestPrep. Your events are on their way to the family week.',
      };
    case 'declined':
      return {
        title: 'Nothing was connected',
        body: 'NestPrep was not given permission to read that calendar. Go back to NestPrep to try again.',
      };
    case 'expired':
      return {
        title: 'That link has expired',
        body: 'Go back to NestPrep and start connecting again. It only takes a moment.',
      };
    case 'failed':
      return {
        title: `${PROVIDER_NAMES[outcome.provider]} did not connect`,
        body: 'Something went wrong on the way back. Go back to NestPrep and try again.',
      };
    case 'notConfigured':
      return {
        title: 'Not set up yet',
        body: 'Calendar connections are not set up on NestPrep yet. Go back to NestPrep.',
      };
  }
}

/** A small, self-contained page: no scripts, no external assets. */
export function callbackPage(outcome: CallbackOutcome): string {
  const { title, body } = callbackCopy(outcome);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} · NestPrep</title>
<style>
  body { margin: 0; font-family: system-ui, sans-serif; background: #f6f3fb; color: #231d33; }
  main { max-width: 28rem; margin: 18vh auto 0; padding: 0 1.5rem; }
  h1 { font-size: 1.5rem; margin: 0 0 .75rem; }
  p { font-size: 1.05rem; line-height: 1.5; color: #4b4461; }
  @media (prefers-color-scheme: dark) {
    body { background: #17131f; color: #f1edf8; }
    p { color: #c9c1d9; }
  }
</style>
</head>
<body><main><h1>${escapeHtml(title)}</h1><p>${escapeHtml(body)}</p></main></body>
</html>`;
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
