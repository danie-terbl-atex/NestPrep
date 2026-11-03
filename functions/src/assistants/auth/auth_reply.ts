/**
 * What an authorization-server endpoint answers, decided apart from the
 * transport so each endpoint is tested without HTTP (assistants ADR-0002).
 * `assistant_auth.ts` is the only place one becomes a response.
 */
export type AuthReply =
  | { readonly kind: 'json'; readonly status: number; readonly body: object }
  | { readonly kind: 'page'; readonly status: number; readonly html: string }
  | { readonly kind: 'redirect'; readonly location: string; readonly session?: string };

export function json(status: number, body: object): AuthReply {
  return { kind: 'json', status, body };
}

/** An RFC 6749 §5.2 error, the shape the token, register and revoke endpoints share. */
export function oauthError(status: number, error: string, description?: string): AuthReply {
  return json(
    status,
    description === undefined ? { error } : { error, error_description: description },
  );
}

/**
 * The browser's tie to the authorize it started. Firebase Hosting forwards
 * only a cookie named `__session` to a Function, which is why it is called
 * that and cannot carry the `__Host-` prefix; `Path=/oauth` keeps it off
 * every other page of the site.
 */
export const SESSION_COOKIE = '__session';

export function sessionCookie(value: string, maxAgeSeconds: number): string {
  return `${SESSION_COOKIE}=${value}; Path=/oauth; Max-Age=${String(maxAgeSeconds)}; Secure; HttpOnly; SameSite=Lax`;
}

const SESSION_VALUE = /^[A-Za-z0-9_-]{43}$/;

/** The `__session` value a request carries, when it is one this server could have set. */
export function sessionFrom(cookieHeader: string | undefined): string | null {
  for (const part of (cookieHeader ?? '').split(';')) {
    const [name, ...rest] = part.trim().split('=');
    const value = rest.join('=');
    if (name === SESSION_COOKIE && SESSION_VALUE.test(value)) return value;
  }
  return null;
}

/**
 * The page `/oauth/authorize` shows when it cannot trust the redirect it was
 * given, so it must not send the browser there (RFC 6749 §4.1.2.1). Styled by
 * the site's own stylesheet, because Hosting's CSP refuses inline style.
 */
export type AuthorizePageReason = 'unknownClient' | 'badRedirect' | 'tooMany' | 'unavailable';

const PAGE_COPY: Readonly<Record<AuthorizePageReason, { title: string; body: string }>> = {
  unknownClient: {
    title: 'That assistant can’t connect to nestprep',
    body: 'nestprep doesn’t recognise the app that sent you here. Go back to it and try adding nestprep again.',
  },
  badRedirect: {
    title: 'That assistant can’t connect to nestprep',
    body: 'The link you followed doesn’t go back to an assistant nestprep works with. Go back and try again from Claude or ChatGPT.',
  },
  tooMany: {
    title: 'Give it a moment',
    body: 'There have been a lot of sign-ins from here just now. Wait a few minutes, then try again.',
  },
  unavailable: {
    title: 'Something went wrong',
    body: 'nestprep couldn’t start connecting just now. Go back to your assistant and try again in a few minutes.',
  },
};

export const AUTHORIZE_PAGE_STATUS: Readonly<Record<AuthorizePageReason, number>> = {
  unknownClient: 400,
  badRedirect: 400,
  tooMany: 429,
  unavailable: 503,
};

export function authorizeErrorPage(reason: AuthorizePageReason): AuthReply {
  const copy = PAGE_COPY[reason];
  return {
    kind: 'page',
    status: AUTHORIZE_PAGE_STATUS[reason],
    html: `<!doctype html>
<html lang="en-ZA">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="robots" content="noindex" />
    <title>${copy.title} — nestprep</title>
    <link rel="stylesheet" href="/assets/site.css" />
  </head>
  <body>
    <main id="main">
      <div class="wrap wrap--prose">
        <h1>${copy.title}</h1>
        <p class="lead">${copy.body}</p>
      </div>
    </main>
  </body>
</html>
`,
  };
}
