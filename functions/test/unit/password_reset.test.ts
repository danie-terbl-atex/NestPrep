import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  PASSWORD_RESETS_OVERALL,
  PASSWORD_RESETS_PER_ADDRESS,
  PASSWORD_RESETS_PER_EMAIL,
  type PasswordResetDeps,
  sendPasswordResetInput,
  sendPasswordResetLink,
} from '../../src/accounts/password_reset';
import {
  escapeHtml,
  passwordResetMessage,
  resetPageLink,
} from '../../src/accounts/password_reset_email';
import { parseInput } from '../../src/household/parse_input';
import { EmailNotSent, type EmailMessage } from '../../src/shared/email_sender';
import type { RateLimitRule } from '../../src/shared/rate_limit';

const FIREBASE_LINK =
  'https://nestprep-643b7.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=Abc-123_x&apiKey=k&lang=en';

function aWorld(
  options: {
    refuse?: RateLimitRule;
    link?: string | null;
    sendFails?: boolean;
  } = {},
): { deps: PasswordResetDeps; sent: EmailMessage[]; consumed: [string, string][] } {
  const sent: EmailMessage[] = [];
  const consumed: [string, string][] = [];
  return {
    sent,
    consumed,
    deps: {
      consume: async (rule, subject): Promise<boolean> => {
        consumed.push([rule.name, subject]);
        return Promise.resolve(rule !== options.refuse);
      },
      resetLink: async () =>
        Promise.resolve(options.link === undefined ? FIREBASE_LINK : options.link),
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

describe('sending a password reset', () => {
  it('emails the reset link on our own site to an address with an account', async () => {
    const { deps, sent } = aWorld();
    await expect(sendPasswordResetLink(deps, 'sam@example.com', '1.2.3.4')).resolves.toEqual({
      sent: true,
    });
    expect(sent).toHaveLength(1);
    expect(sent[0]?.to).toBe('sam@example.com');
    expect(sent[0]?.html).toContain('https://app.nestprep.io/reset-password?oobCode=Abc-123_x');
    expect(sent[0]?.text).toContain('https://app.nestprep.io/reset-password?oobCode=Abc-123_x');
  });

  it('answers sent and emails nothing for an address with no account', async () => {
    const { deps, sent } = aWorld({ link: null });
    await expect(sendPasswordResetLink(deps, 'nobody@example.com', '1.2.3.4')).resolves.toEqual({
      sent: true,
    });
    expect(sent).toHaveLength(0);
  });

  it('counts the caller, the address and the total, in that order', async () => {
    const { deps, consumed } = aWorld();
    await sendPasswordResetLink(deps, 'sam@example.com', '1.2.3.4');
    expect(consumed).toEqual([
      [PASSWORD_RESETS_PER_ADDRESS.name, '1.2.3.4'],
      [PASSWORD_RESETS_PER_EMAIL.name, 'sam@example.com'],
      [PASSWORD_RESETS_OVERALL.name, 'all'],
    ]);
  });

  for (const rule of [
    PASSWORD_RESETS_PER_ADDRESS,
    PASSWORD_RESETS_PER_EMAIL,
    PASSWORD_RESETS_OVERALL,
  ]) {
    it(`refuses tooManyAttempts and sends nothing past ${rule.name}`, async () => {
      const { deps, sent } = aWorld({ refuse: rule });
      expect(await reasonOf(sendPasswordResetLink(deps, 'sam@example.com', '1.2.3.4'))).toBe(
        'tooManyAttempts',
      );
      expect(sent).toHaveLength(0);
    });
  }

  it('refuses unavailable when Resend does not take the email', async () => {
    const { deps } = aWorld({ sendFails: true });
    expect(await reasonOf(sendPasswordResetLink(deps, 'sam@example.com', '1.2.3.4'))).toBe(
      'unavailable',
    );
  });

  it('refuses unavailable when Firebase hands back a link with no code', async () => {
    const { deps, sent } = aWorld({
      link: 'https://nestprep-643b7.firebaseapp.com/__/auth/action',
    });
    expect(await reasonOf(sendPasswordResetLink(deps, 'sam@example.com', '1.2.3.4'))).toBe(
      'unavailable',
    );
    expect(sent).toHaveLength(0);
  });
});

describe('the reset request body', () => {
  it('trims and lower-cases the address, so one person is one counter', () => {
    expect(parseInput(sendPasswordResetInput, { email: '  Sam@Example.COM ' }).email).toBe(
      'sam@example.com',
    );
  });

  it('refuses something that is not an address', () => {
    expect(() => parseInput(sendPasswordResetInput, { email: 'sam' })).toThrow(HttpsError);
  });
});

describe('the reset page link', () => {
  it('carries only the code, on app.nestprep.io', () => {
    const link = new URL(resetPageLink(FIREBASE_LINK) ?? '');
    expect(link.origin).toBe('https://app.nestprep.io');
    expect(link.pathname).toBe('/reset-password');
    expect([...link.searchParams.keys()]).toEqual(['oobCode']);
    expect(link.searchParams.get('oobCode')).toBe('Abc-123_x');
  });

  it('is null when the Firebase link has no code', () => {
    expect(resetPageLink('https://example.com/__/auth/action?mode=resetPassword')).toBeNull();
  });
});

describe('the reset email', () => {
  const link = 'https://app.nestprep.io/reset-password?oobCode=abc&x=1';
  const message = passwordResetMessage('sam@example.com', link);

  it('has a subject that names NestPrep and what it is for', () => {
    expect(message.subject).toBe('Reset your NestPrep password');
  });

  it('carries the link as a button and as text in the html, and in the plain text', () => {
    const escaped = escapeHtml(link);
    expect(message.html).toContain(`href="${escaped}"`);
    expect(message.html?.split(escaped).length).toBeGreaterThanOrEqual(4);
    expect(message.text).toContain(link);
  });

  it('says how long the link lasts and that ignoring it is safe', () => {
    for (const body of [message.text, message.html ?? '']) {
      expect(body).toContain('one hour');
      expect(body).toContain('Your password has not changed');
    }
  });

  it('leaves no Firebase template placeholder behind', () => {
    expect(`${message.text}${message.html ?? ''}`).not.toMatch(/%[A-Z_]+%/);
  });

  it('escapes the address it shows', () => {
    const hostile = passwordResetMessage('<script>x</script>@example.com', link);
    expect(hostile.html).not.toContain('<script>');
    expect(hostile.html).toContain('&lt;script&gt;');
  });

  it('loads its only picture from our own site', () => {
    const sources = [...(message.html ?? '').matchAll(/src="([^"]+)"/g)].map((match) => match[1]);
    expect(sources).toEqual(['https://app.nestprep.io/assets/nest_mark.png']);
  });
});
