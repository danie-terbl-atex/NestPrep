import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  WELCOMES_OVERALL,
  WELCOMES_PER_ACCOUNT,
  type WelcomeAccount,
  type WelcomeDeps,
  sendWelcome,
} from '../../src/accounts/welcome';
import { firstNameOf, verifyPageLink, welcomeMessage } from '../../src/accounts/welcome_email';
import { EmailNotSent, type EmailMessage } from '../../src/shared/email_sender';
import type { RateLimitRule } from '../../src/shared/rate_limit';

const FIREBASE_LINK =
  'https://nestprep-643b7.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=Abc-123_x&apiKey=k&lang=en';
const CONFIRM_LINK = 'https://app.nestprep.io/verify-email?oobCode=Abc-123_x';

const PASSWORD_ACCOUNT: WelcomeAccount = {
  email: 'sam@example.com',
  displayName: 'Sam Dlamini',
  disabled: false,
  needsConfirming: true,
};

function aWorld(
  options: {
    account?: Partial<WelcomeAccount>;
    refuse?: RateLimitRule;
    link?: string | null;
    sendFails?: boolean;
  } = {},
): { deps: WelcomeDeps; sent: EmailMessage[]; consumed: [string, string][]; linksAsked: string[] } {
  const sent: EmailMessage[] = [];
  const consumed: [string, string][] = [];
  const linksAsked: string[] = [];
  return {
    sent,
    consumed,
    linksAsked,
    deps: {
      consume: async (rule, subject): Promise<boolean> => {
        consumed.push([rule.name, subject]);
        return Promise.resolve(rule !== options.refuse);
      },
      account: async (): Promise<WelcomeAccount> =>
        Promise.resolve({ ...PASSWORD_ACCOUNT, ...options.account }),
      verifyLink: async (email): Promise<string | null> => {
        linksAsked.push(email);
        return Promise.resolve(options.link === undefined ? FIREBASE_LINK : options.link);
      },
      sender: {
        send: async (message): Promise<void> => {
          if (options.sendFails === true) throw new EmailNotSent('status 422');
          sent.push(message);
          return Promise.resolve();
        },
      },
    },
  };
}

async function reasonOf(promise: Promise<unknown>): Promise<unknown> {
  try {
    await promise;
  } catch (error) {
    return error instanceof HttpsError ? (error.details as { reason?: unknown }).reason : error;
  }
  return 'resolved';
}

describe('sending a welcome', () => {
  it('welcomes a password account by first name with a confirm link on our own site', async () => {
    const { deps, sent } = aWorld();
    await expect(sendWelcome(deps, 'uid-sam')).resolves.toEqual({ sent: true });
    expect(sent).toHaveLength(1);
    expect(sent[0]?.to).toBe('sam@example.com');
    expect(sent[0]?.subject).toBe('Welcome to NestPrep, Sam');
    expect(sent[0]?.html).toContain(CONFIRM_LINK);
    expect(sent[0]?.text).toContain(CONFIRM_LINK);
    expect(sent[0]?.html).toContain('Confirm my email');
  });

  it('welcomes a Google or Apple account without a confirm link and asks for none', async () => {
    const { deps, sent, linksAsked } = aWorld({ account: { needsConfirming: false } });
    await expect(sendWelcome(deps, 'uid-sam')).resolves.toEqual({ sent: true });
    expect(linksAsked).toHaveLength(0);
    expect(sent[0]?.html).not.toContain('Confirm my email');
    expect(sent[0]?.text).not.toContain('verify-email');
  });

  it('still welcomes when the confirm link could not be made', async () => {
    const { deps, sent } = aWorld({ link: null });
    await expect(sendWelcome(deps, 'uid-sam')).resolves.toEqual({ sent: true });
    expect(sent[0]?.html).not.toContain('Confirm my email');
  });

  it('sends once per account, and a second ask answers not sent', async () => {
    const { deps, sent } = aWorld({ refuse: WELCOMES_PER_ACCOUNT });
    await expect(sendWelcome(deps, 'uid-sam')).resolves.toEqual({ sent: false });
    expect(sent).toHaveLength(0);
  });

  it('counts the account before the shared budget, so a looping account cannot spend it', async () => {
    const { deps, consumed } = aWorld({ refuse: WELCOMES_PER_ACCOUNT });
    await sendWelcome(deps, 'uid-sam');
    expect(consumed).toEqual([[WELCOMES_PER_ACCOUNT.name, 'uid-sam']]);
  });

  it('refuses tooManyAttempts once the overall budget is spent', async () => {
    const { deps, sent } = aWorld({ refuse: WELCOMES_OVERALL });
    expect(await reasonOf(sendWelcome(deps, 'uid-sam'))).toBe('tooManyAttempts');
    expect(sent).toHaveLength(0);
  });

  it.each([
    ['no address', { email: undefined }],
    ['an empty address', { email: '' }],
    ['a disabled account', { disabled: true }],
  ])('sends nothing and spends nothing for %s', async (_, account) => {
    const { deps, sent, consumed } = aWorld({ account });
    await expect(sendWelcome(deps, 'uid-kid')).resolves.toEqual({ sent: false });
    expect(sent).toHaveLength(0);
    expect(consumed).toHaveLength(0);
  });

  it('refuses unavailable when Resend does not take the email', async () => {
    const { deps } = aWorld({ sendFails: true });
    expect(await reasonOf(sendWelcome(deps, 'uid-sam'))).toBe('unavailable');
  });
});

describe('the welcome email', () => {
  it('links the verify page with only the one-time code', () => {
    expect(verifyPageLink(FIREBASE_LINK)).toBe(CONFIRM_LINK);
    expect(verifyPageLink('https://nestprep-643b7.firebaseapp.com/__/auth/action')).toBeNull();
  });

  it.each([
    ['Sam Dlamini', 'Sam'],
    ['  Thandi  ', 'Thandi'],
    ['', null],
    ['   ', null],
    [undefined, null],
  ])('greets %j as %j', (displayName, expected) => {
    expect(firstNameOf(displayName)).toBe(expected);
  });

  it('says hello without a name when there is none', () => {
    expect(welcomeMessage('sam@example.com', null, null).subject).toBe('Welcome to NestPrep');
  });

  it('escapes the name and the address in the HTML', () => {
    const { html } = welcomeMessage('<b>@example.com', '<script>', CONFIRM_LINK);
    expect(html).not.toContain('<script>');
    expect(html).not.toContain('<b>@');
    expect(html).toContain('&lt;script&gt;');
  });

  it('is HTML with the nest mark and a plain-text alternative', () => {
    const message = welcomeMessage('sam@example.com', 'Sam', CONFIRM_LINK);
    expect(message.html).toContain('https://app.nestprep.io/assets/nest_mark.png');
    expect(message.text).toContain('Welcome to NestPrep, Sam!');
    expect(message.text).not.toContain('<');
  });
});
