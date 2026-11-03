import { describe, expect, it } from 'vitest';

import { provenEmailsOf } from '../../../src/premium_vouchers/caller_emails';
import { testerUidsFrom } from '../../../src/premium_vouchers/premium_config';

describe('the emails an account has proved', () => {
  it('are the Auth email once verified', () => {
    expect(
      provenEmailsOf({ email: 'Sam@Example.com', emailVerified: true, providerData: [] }),
    ).toEqual(['sam@example.com']);
    expect(
      provenEmailsOf({ email: 'sam@example.com', emailVerified: false, providerData: [] }),
    ).toEqual([]);
  });

  it('and every Google and Apple provider email, Hide My Email included', () => {
    const emails = provenEmailsOf({
      email: 'sam@example.com',
      emailVerified: true,
      providerData: [
        { providerId: 'google.com', email: 'SAM@example.com' },
        { providerId: 'apple.com', email: 'x7f2k@privaterelay.appleid.com' },
        { providerId: 'password', email: 'typed@example.com' },
        { providerId: 'phone' },
      ],
    });
    expect(emails).toEqual(['sam@example.com', 'x7f2k@privaterelay.appleid.com']);
  });

  it('skip a provider email that is not an address', () => {
    expect(
      provenEmailsOf({
        emailVerified: false,
        providerData: [{ providerId: 'google.com', email: 'not an email' }],
      }),
    ).toEqual([]);
  });
});

describe('the tester allow-list', () => {
  it('is a comma-separated list of uids, empty by default', () => {
    expect(testerUidsFrom('')).toEqual([]);
    expect(testerUidsFrom('unset')).toEqual([]);
    expect(testerUidsFrom(' uid-a, uid-b ,,')).toEqual(['uid-a', 'uid-b']);
  });
});
