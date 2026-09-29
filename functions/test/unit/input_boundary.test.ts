import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { parseInput, requireUid, requireVerifiedUid } from '../../src/household/parse_input';
import {
  createHouseholdInput,
  createInviteInput,
  leaveHouseholdInput,
  redeemInviteInput,
  removeMemberInput,
  setMemberAccessInput,
  setMemberRoleInput,
} from '../../src/household/schemas';
import { ROLE_DEFAULTS } from '../../src/household/access';
import { deleteDocumentFolderInput, openVaultDocumentInput } from '../../src/documents/schemas';
import { endNannyShiftInput } from '../../src/nanny_hub/schemas';
import { deleteAccountInput } from '../../src/account_data/schemas';
import { endNannyShiftInput, setCarerShiftOnlyInput } from '../../src/nanny_hub/schemas';
import {
  createDocumentShareInput,
  revokeDocumentShareInput,
} from '../../src/documents/share/share_schemas';
import { readSchoolLetterInput } from '../../src/school_letter/schemas';
import {
  acceptCoParentInviteInput,
  answerCoParentChangeInput,
  confirmCoParentLinkInput,
  createCoParentInviteInput,
  endCoParentLinkInput,
  previewCoParentInviteInput,
  proposeCoParentChangeInput,
  saveCoParentHandoverInput,
} from '../../src/coparent/schemas';
import { ALTERNATING, DADS_HOME, MUMS_HOME } from '../coparent_fixtures';
import { planMyWeekInput } from '../../src/plan_week/schemas';
import { recordActivityInput } from '../../src/product_analytics/record_activity';
import { recordPaywallOpenedInput } from '../../src/product_analytics/record_paywall_opened';
import { ensureReferralCodeInput, redeemReferralCodeInput } from '../../src/referrals/schemas';
import {
  cancelKidPairingInput,
  createKidPairingInput,
  redeemKidPairingInput,
  resetKidSignInInput,
  revokeKidDeviceInput,
} from '../../src/accounts/kid_schemas';
import { reviewChoreInput, settleRewardInput } from '../../src/chore_points/schemas';
import {
  connectCalendarLinkInput,
  connectionInput,
  householdInput,
  startCalendarConnectionInput,
} from '../../src/calendar_sync/schemas';
import {
  setChildProfileInput,
  subscriptionOfferInput,
  verifyPurchaseInput,
} from '../../src/subscriptions/schemas';
import {
  MAX_TEXTS_PER_CALL,
  MAX_TEXT_LENGTH,
  translateHomeCareTextsInput,
} from '../../src/home_care/schemas';
import { sendTestNotificationInput } from '../../src/notifications/schemas';

/**
 * The edge where a callable's body becomes a typed value (`ENG-09`, `BE-03`).
 *
 * The emulator tests exercise the paths the callables take; they cannot say
 * what the boundary *refuses*, because a refused body never reaches a callable.
 * This says it — for every field of every callable that takes a body.
 * `syncDocumentAccess` takes none: its subject is the caller, re-derived from
 * the token and Firestore, so there is nothing at its edge to refuse.
 */

/** What a valid body looks like for each callable. */
const validBodies = {
  createHousehold: {
    schema: createHouseholdInput,
    body: {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      adminDisplayName: 'Sam',
      adminColor: 'violet',
    },
  },
  createInvite: {
    schema: createInviteInput,
    body: { householdId: 'h1', memberId: 'm-kid' },
  },
  redeemInvite: { schema: redeemInviteInput, body: { code: 'ABCD2345' } },
  leaveHousehold: { schema: leaveHouseholdInput, body: { householdId: 'h1' } },
  removeMember: {
    schema: removeMemberInput,
    body: { householdId: 'h1', memberId: 'm-kid' },
  },
  setMemberRole: {
    schema: setMemberRoleInput,
    body: { householdId: 'h1', memberId: 'm-kid', role: 'admin' },
  },
  setMemberAccess: {
    schema: setMemberAccessInput,
    body: { householdId: 'h1', memberId: 'm-thandi', access: ROLE_DEFAULTS.helper },
  },
  deleteDocumentFolder: {
    schema: deleteDocumentFolderInput,
    body: { householdId: 'h1', folderId: 'f-school' },
  },
  recordActivity: { schema: recordActivityInput, body: { householdId: 'h1' } },
  // Kid sign-in (accounts ADR-0003). `label` is optional, so it is not in the
  // body every field of which must be required; its own cases are below.
  createKidPairing: {
    schema: createKidPairingInput,
    body: { householdId: 'h1', memberId: 'm-kid' },
  },
  cancelKidPairing: { schema: cancelKidPairingInput, body: { householdId: 'h1', code: 'ABC234' } },
  redeemKidPairing: { schema: redeemKidPairingInput, body: { code: 'ABC234' } },
  revokeKidDevice: {
    schema: revokeKidDeviceInput,
    body: { householdId: 'h1', deviceUid: 'kid_abc' },
  },
  resetKidSignIn: { schema: resetKidSignInInput, body: { householdId: 'h1', memberId: 'm-kid' } },
  // Calendar sync (calendar ADR-0003): list, share and reset take the
  // household alone; sync and disconnect name a connection too.
  listCalendarProviders: { schema: householdInput, body: { householdId: 'h1' } },
  startCalendarConnection: {
    schema: startCalendarConnectionInput,
    body: { householdId: 'h1', provider: 'google' },
  },
  connectCalendarLink: {
    schema: connectCalendarLinkInput,
    body: { householdId: 'h1', url: 'webcal://p01-caldav.icloud.com/published/2/abc' },
  },
  syncCalendarConnection: {
    schema: connectionInput,
    body: { householdId: 'h1', connectionId: 'c1' },
  },
  // Documents phase 2: the one door to a vault document's bytes (documents
  // ADR-0003).
  openVaultDocument: {
    schema: openVaultDocumentInput,
    body: { householdId: 'h1', ownerMemberId: 'm-emma', documentId: 'doc-1' },
  },
  // Todos phase 2: a parent's review of a chore and of a reward request
  // (todos ADR-0003).
  reviewChore: {
    schema: reviewChoreInput,
    body: { householdId: 'h1', completionId: 't1_2026-09-29', decision: 'approve' },
  },
  settleReward: {
    schema: settleRewardInput,
    body: { householdId: 'h1', requestId: 'r1', decision: 'fulfil' },
  },
  // Nanny hub: the closing note is required-and-nullable, so the app always
  // says whether there is one (nanny-hub ADR-0002).
  endNannyShift: {
    schema: endNannyShiftInput,
    body: { householdId: 'h1', shiftId: 'shift-1', closingNote: null },
  },
  // Subscriptions (subscriptions ADR-0001). `trigger` is nullable rather than
  // optional — a restore says so — so it is in the body every field of which
  // must be present.
  getSubscriptionOffer: { schema: subscriptionOfferInput, body: { householdId: 'h1' } },
  verifyPurchase: {
    schema: verifyPurchaseInput,
    body: {
      householdId: 'h1',
      store: 'playStore',
      verificationData: 'purchase-token',
      trigger: 'additionalChild',
    },
  },
  // Account data (accounts ADR-0006). Previewing and exporting take no body.
  deleteAccount: {
    schema: deleteAccountInput,
    body: { confirmation: 'DELETE', endingHouseholdIds: ['h1'] },
  },
  setChildProfile: {
    schema: setChildProfileInput,
    // `guardianConsent` is optional — a child with consent on record needs
    // none — so it is not here; its shape is below (accounts ADR-0005).
    body: { householdId: 'h1', memberId: 'm-kid', isChild: true },
  },
  // Plan my week: every option is said, so nothing defaults on the server
  // (lunch-box ADR-0011).
  planMyWeek: {
    schema: planMyWeekInput,
    body: {
      householdId: 'h1',
      week: '2026-W40',
      childIds: ['m-kid'],
      includeDinners: true,
      useWhatsInTheHouse: false,
      budget: 'none',
    },
  },
  // Home care: a helper's words in her language (home-care ADR-0006).
  translateHomeCareTexts: {
    schema: translateHomeCareTextsInput,
    body: { householdId: 'h1', language: 'zu', texts: ['Open a window'] },
  },
  // Documents V2: a shared link (documents ADR-0006). The owner, the shift and
  // the PIN are required-and-nullable, so the app always says which it means.
  createDocumentShare: {
    schema: createDocumentShareInput,
    body: {
      householdId: 'h1',
      ownerMemberId: 'm-emma',
      documentId: 'doc-1',
      lifetimeHours: 24,
      shiftId: null,
      pin: '2468',
    },
  },
  revokeDocumentShare: {
    schema: revokeDocumentShareInput,
    body: { householdId: 'h1', shareId: 's1' },
  },
  // Snap a school letter: the letter travels in the call and is never stored
  // (calendar ADR-0005).
  readSchoolLetter: {
    schema: readSchoolLetterInput,
    body: { householdId: 'h1', mimeType: 'application/pdf', data: 'JVBERi0xLjc=' },
  },
  // Co-parenting (household ADR-0004): every optional text is
  // required-and-nullable, so the app always says whether there is one.
  createCoParentInvite: {
    schema: createCoParentInviteInput,
    body: { householdId: 'h1', childMemberId: 'm-sam', home: MUMS_HOME, schedule: ALTERNATING },
  },
  previewCoParentInvite: { schema: previewCoParentInviteInput, body: { code: 'ABCD2345' } },
  acceptCoParentInvite: {
    schema: acceptCoParentInviteInput,
    body: {
      householdId: 'h2',
      code: 'ABCD2345',
      childMemberId: 'm-sam',
      newChildName: null,
      home: DADS_HOME,
    },
  },
  confirmCoParentLink: {
    schema: confirmCoParentLinkInput,
    body: { householdId: 'h1', linkId: 'l1', accept: true },
  },
  endCoParentLink: { schema: endCoParentLinkInput, body: { householdId: 'h1', linkId: 'l1' } },
  proposeCoParentChange: {
    schema: proposeCoParentChangeInput,
    body: {
      householdId: 'h1',
      linkId: 'l1',
      change: { kind: 'swap', from: '2026-10-02', to: '2026-10-04', toSide: 'a' },
      note: null,
    },
  },
  answerCoParentChange: {
    schema: answerCoParentChangeInput,
    body: { householdId: 'h1', linkId: 'l1', requestId: 'r1', answer: 'accept', note: null },
  },
  saveCoParentHandover: {
    schema: saveCoParentHandoverInput,
    body: {
      householdId: 'h1',
      linkId: 'l1',
      date: '2026-10-05',
      items: [{ text: 'School bag', packed: true }],
      medicine: null,
      homework: null,
      clothes: null,
      note: null,
    },
  },
  // Nanny hub V2: marking a carer shift-only (nanny-hub ADR-0006).
  setCarerShiftOnly: {
    schema: setCarerShiftOnlyInput,
    body: { householdId: 'h1', memberId: 'm-nomsa', shiftOnly: true },
  },
  // Referrals and conversion by trigger (subscriptions ADR-0002,
  // product-analytics ADR-0002).
  ensureReferralCode: { schema: ensureReferralCodeInput, body: { householdId: 'h1' } },
  redeemReferralCode: {
    schema: redeemReferralCodeInput,
    body: { householdId: 'h1', code: 'ABCD2345' },
  },
  recordPaywallOpened: {
    schema: recordPaywallOpenedInput,
    body: { householdId: 'h1', trigger: 'prepList' },
  },
  sendTestNotification: { schema: sendTestNotificationInput, body: { householdId: 'h1' } },
} as const;

describe('translateHomeCareTexts refuses what is not a translation to make', () => {
  const body = validBodies.translateHomeCareTexts.body;
  it.each([
    ['English, which every text is already in', { ...body, language: 'en' }],
    ['a language the helper cannot choose', { ...body, language: 'fr' }],
    ['no texts at all', { ...body, texts: [] }],
    ['a blank text', { ...body, texts: ['   '] }],
    ['a text longer than any step', { ...body, texts: ['x'.repeat(MAX_TEXT_LENGTH + 1)] }],
    ['more texts than a job has', { ...body, texts: Array(MAX_TEXTS_PER_CALL + 1).fill('Mop') }],
  ])('%s', (_, candidate) => {
    expect(() => parseInput(translateHomeCareTextsInput, candidate)).toThrow(HttpsError);
  });

  it('asks for a repeated text once, trimmed', () => {
    const parsed = parseInput(translateHomeCareTextsInput, {
      ...body,
      texts: [' Mop the floor ', 'Mop the floor'],
    });
    expect(parsed.texts).toEqual(['Mop the floor']);
  });
});

describe('verifyPurchase refuses what is not a purchase to verify', () => {
  const body = validBodies.verifyPurchase.body;
  it.each([
    ['a store that is not one of the two', { ...body, store: 'webStore' }],
    ['a trigger the analytics do not know', { ...body, trigger: 'somethingElse' }],
    [
      'a receipt longer than any signed transaction',
      { ...body, verificationData: 'x'.repeat(60_001) },
    ],
    ['an empty receipt', { ...body, verificationData: '   ' }],
  ])('%s', (_, candidate) => {
    expect(() => parseInput(verifyPurchaseInput, candidate)).toThrow(HttpsError);
  });

  it('accepts a restore, which names no trigger', () => {
    expect(() => parseInput(verifyPurchaseInput, { ...body, trigger: null })).not.toThrow();
  });
});

describe('setChildProfile’s parental consent (accounts ADR-0005)', () => {
  const body = { householdId: 'h1', memberId: 'm-kid', isChild: true };

  it('is a policy version, given as the child is marked', () => {
    expect(() =>
      parseInput(setChildProfileInput, { ...body, guardianConsent: { version: 1 } }),
    ).not.toThrow();
  });

  it.each([
    ['a version below 1', { version: 0 }],
    ['a version that is not whole', { version: 1.5 }],
    ['a version as text', { version: '1' }],
    ['a member id of the caller’s choosing', { version: 1, byMemberId: 'm-other' }],
    ['a bare yes', true],
  ])('refuses %s', (_, guardianConsent) => {
    expect(() => parseInput(setChildProfileInput, { ...body, guardianConsent })).toThrow(
      HttpsError,
    );
  });
});

describe('a referral code as a person types it (subscriptions ADR-0002)', () => {
  const body = validBodies.redeemReferralCode.body;

  it('forgives spaces and lower case, and hands on the code as it is stored', () => {
    const parsed = parseInput(redeemReferralCodeInput, { ...body, code: ' abcd 2345 ' });
    expect(parsed.code).toBe('ABCD2345');
  });

  it.each([
    ['a letter people confuse with a digit', 'ABCD0123'],
    ['a code one short', 'ABCD234'],
    ['a code one long', 'ABCD23456'],
    ['something that is not a code at all', 'sam@example.com'],
  ])('refuses %s', (_, code) => {
    expect(() => parseInput(redeemReferralCodeInput, { ...body, code })).toThrow(HttpsError);
  });
});

describe('every callable accepts its own body', () => {
  for (const [name, { schema, body }] of Object.entries(validBodies)) {
    it(name, () => {
      expect(() => parseInput(schema, body)).not.toThrow();
    });
  }
});

describe('and refuses a body that is missing any field', () => {
  for (const [name, { schema, body }] of Object.entries(validBodies)) {
    for (const field of Object.keys(body)) {
      it(`${name} without ${field}`, () => {
        const without = Object.fromEntries(Object.entries(body).filter(([key]) => key !== field));
        expect(() => parseInput(schema, without)).toThrow(HttpsError);
      });
    }
  }
});

describe('and refuses a body that is not an object at all', () => {
  const notBodies: [label: string, value: unknown][] = [
    ['null', null],
    ['undefined', undefined],
    ['a string', 'a string'],
    ['a number', 42],
    ['an array', []],
    ['a boolean', true],
  ];
  for (const [label, value] of notBodies) {
    it(label, () => {
      expect(() => parseInput(createHouseholdInput, value)).toThrow(HttpsError);
    });
  }
});

describe('names', () => {
  const { schema, body } = validBodies.createHousehold;

  it('are trimmed, so " Sam " and "Sam" are one person', () => {
    const parsed = parseInput(schema, { ...body, adminDisplayName: '  Sam  ' });
    expect(parsed.adminDisplayName).toBe('Sam');
  });

  it('cannot be only whitespace', () => {
    expect(() => parseInput(schema, { ...body, name: '   ' })).toThrow(HttpsError);
  });

  it('cannot be longer than a household name reasonably is', () => {
    expect(() => parseInput(schema, { ...body, name: 'x'.repeat(61) })).toThrow(HttpsError);
    expect(() => parseInput(schema, { ...body, name: 'x'.repeat(60) })).not.toThrow();
  });
});

describe('the timezone', () => {
  const { schema, body } = validBodies.createHousehold;

  for (const zone of [
    'Africa/Johannesburg',
    'Etc/UTC',
    'UTC',
    'America/Argentina/Buenos_Aires',
    'Etc/GMT+2',
  ]) {
    it(`accepts ${zone}`, () => {
      expect(() => parseInput(schema, { ...body, timeZone: zone })).not.toThrow();
    });
  }

  for (const [zone, why] of [
    ['Africa Johannesburg', 'a space is not a separator'],
    ['../../etc/passwd', 'a dot is not part of a zone name'],
    ['Africa/Johannesburg; DROP', 'nor is a semicolon'],
    ['', 'nor is nothing'],
  ] as const) {
    it(`refuses "${zone}" — ${why}`, () => {
      expect(() => parseInput(schema, { ...body, timeZone: zone })).toThrow(HttpsError);
    });
  }

  it('does not judge whether the zone exists, only its shape', () => {
    // A zone added to tzdata after this Function was deployed must still work.
    expect(() => parseInput(schema, { ...body, timeZone: 'Mars/Olympus_Mons' })).not.toThrow();
  });
});

describe('an invite code', () => {
  const { schema } = validBodies.redeemInvite;

  it('is normalised to upper case, because nobody types it as printed', () => {
    expect(parseInput(schema, { code: 'abcd2345' }).code).toBe('ABCD2345');
    expect(parseInput(schema, { code: ' AbCd2345 ' }).code).toBe('ABCD2345');
  });

  it('is refused when it is too short to be one of ours', () => {
    expect(() => parseInput(schema, { code: 'abc' })).toThrow(HttpsError);
  });

  it('is refused when it is long enough to be something else', () => {
    expect(() => parseInput(schema, { code: 'x'.repeat(17) })).toThrow(HttpsError);
  });
});

describe('a role', () => {
  const { schema, body } = validBodies.setMemberRole;

  for (const role of ['admin', 'parent', 'kid', 'helper', 'carer']) {
    it(`accepts ${role}`, () => {
      expect(parseInput(schema, { ...body, role }).role).toBe(role);
    });
  }

  it('accepts `member` from an app installed before ADR-0003, and writes it as parent', () => {
    expect(parseInput(schema, { ...body, role: 'member' }).role).toBe('parent');
  });

  for (const role of ['owner', 'ADMIN', 'superuser', '', null]) {
    it(`refuses ${JSON.stringify(role)}`, () => {
      expect(() => parseInput(schema, { ...body, role })).toThrow(HttpsError);
    });
  }
});

describe('a grant', () => {
  const { schema, body } = validBodies.setMemberAccess;

  it('accepts every role default as it stands', () => {
    for (const grant of Object.values(ROLE_DEFAULTS)) {
      expect(() => parseInput(schema, { ...body, access: grant })).not.toThrow();
    }
  });

  it('refuses a grant that leaves an area out — "not said" is not "none"', () => {
    const partial: Partial<typeof ROLE_DEFAULTS.helper> = { ...ROLE_DEFAULTS.helper };
    delete partial.documents;
    expect(() => parseInput(schema, { ...body, access: partial })).toThrow(HttpsError);
  });

  it('refuses an area nobody has heard of', () => {
    const access = { ...ROLE_DEFAULTS.helper, garage: 'edit' };
    expect(() => parseInput(schema, { ...body, access })).toThrow(HttpsError);
  });

  it('refuses a level that is not one of the four', () => {
    const access = { ...ROLE_DEFAULTS.helper, calendar: 'admin' };
    expect(() => parseInput(schema, { ...body, access })).toThrow(HttpsError);
  });

  it('refuses `own` where the area has no meaning of "theirs"', () => {
    for (const area of ['calendar', 'groceries', 'meals', 'documents', 'nannyHub']) {
      const access = { ...ROLE_DEFAULTS.helper, [area]: 'own' };
      expect(() => parseInput(schema, { ...body, access }), area).toThrow(HttpsError);
    }
  });

  it('accepts `own` where it does', () => {
    for (const area of ['todos', 'lunch', 'familyProfiles', 'medical', 'homeCare']) {
      const access = { ...ROLE_DEFAULTS.helper, [area]: 'own' };
      expect(() => parseInput(schema, { ...body, access }), area).not.toThrow();
    }
  });
});

describe('a calendar provider', () => {
  const { schema, body } = validBodies.startCalendarConnection;

  it('is one NestPrep connects through OAuth, and a link is not one', () => {
    expect(() => parseInput(schema, { ...body, provider: 'microsoft' })).not.toThrow();
    expect(() => parseInput(schema, { ...body, provider: 'ics' })).toThrow(HttpsError);
    expect(() => parseInput(schema, { ...body, provider: 'apple' })).toThrow(HttpsError);
  });
});

describe('what a refusal tells the client', () => {
  it('carries a reason the client can map, and no field names', () => {
    try {
      parseInput(createHouseholdInput, { name: '' });
      expect.unreachable('that body should not have parsed');
    } catch (error) {
      const refusal = error as HttpsError;
      expect(refusal.code).toBe('invalid-argument');
      expect(refusal.details).toEqual({ reason: 'badRequest' });
      // The message is for us; the client maps the reason to copy (`BE-04`).
      expect(refusal.message).not.toContain('name');
      expect(refusal.message).not.toContain('zod');
    }
  });
});

describe('the caller', () => {
  it('is whoever the token says', () => {
    expect(requireUid({ uid: 'uid-sam' })).toBe('uid-sam');
  });

  it('is refused when there is no token at all', () => {
    try {
      requireUid(undefined);
      expect.unreachable('an unsigned call should not get a uid');
    } catch (error) {
      const refusal = error as HttpsError;
      expect(refusal.code).toBe('unauthenticated');
      expect(refusal.details).toEqual({ reason: 'notSignedIn' });
    }
  });
});

/**
 * The gate between an account and its first household (accounts ADR-0002).
 *
 * This is the enforcement, not the screen: the app has a verify screen that
 * explains it, and it would go on being enforced here if that screen were
 * deleted (`BE-01`). A Google credential arrives verified, so every case below
 * is about a password one.
 */
describe('a caller who must have proved their address', () => {
  it('is let through when the token says the address is verified', () => {
    expect(requireVerifiedUid({ uid: 'uid-sam', token: { email_verified: true } })).toBe('uid-sam');
  });

  it('is refused when the token says it is not', () => {
    try {
      requireVerifiedUid({ uid: 'uid-sam', token: { email_verified: false } });
      expect.unreachable('an unverified caller should not create membership');
    } catch (error) {
      const refusal = error as HttpsError;
      expect(refusal.code).toBe('failed-precondition');
      expect(refusal.details).toEqual({ reason: 'emailNotVerified' });
    }
  });

  it('is refused when the claim is missing entirely', () => {
    // Fails closed. A token shape we do not recognise is not a licence, and a
    // claim that is absent is not the same as a claim that is true.
    try {
      requireVerifiedUid({ uid: 'uid-sam', token: {} });
      expect.unreachable('an absent claim is not a verified address');
    } catch (error) {
      expect((error as HttpsError).details).toEqual({ reason: 'emailNotVerified' });
    }
  });

  it('refuses an unsigned call before it looks at the claim', () => {
    // The order matters: "verify your email" to somebody who is not signed in
    // at all is the wrong sentence and the wrong thing to fix.
    try {
      requireVerifiedUid(undefined);
      expect.unreachable('an unsigned call should not get a uid');
    } catch (error) {
      const refusal = error as HttpsError;
      expect(refusal.code).toBe('unauthenticated');
      expect(refusal.details).toEqual({ reason: 'notSignedIn' });
    }
  });
});

describe('a school letter', () => {
  const { schema, body } = validBodies.readSchoolLetter;

  it('is a photo or a PDF, and nothing else', () => {
    for (const mimeType of ['image/jpeg', 'image/png', 'application/pdf']) {
      expect(() => parseInput(schema, { ...body, mimeType })).not.toThrow();
    }
    for (const mimeType of ['image/gif', 'text/html', 'application/zip', '']) {
      expect(() => parseInput(schema, { ...body, mimeType }), mimeType).toThrow(HttpsError);
    }
  });

  it('is not empty, and not larger than a callable should carry', () => {
    expect(() => parseInput(schema, { ...body, data: '' })).toThrow(HttpsError);
    expect(() => parseInput(schema, { ...body, data: 'A'.repeat(12_000_000) })).toThrow(HttpsError);
  });
});

describe('co-parenting inputs (household ADR-0004)', () => {
  const accept = validBodies.acceptCoParentInvite;

  it('a child is an existing profile or a new name, never both and never neither', () => {
    expect(() =>
      parseInput(accept.schema, { ...accept.body, childMemberId: null, newChildName: 'Sam' }),
    ).not.toThrow();
    expect(() => parseInput(accept.schema, { ...accept.body, newChildName: 'Sam' })).toThrow(
      HttpsError,
    );
    expect(() => parseInput(accept.schema, { ...accept.body, childMemberId: null })).toThrow(
      HttpsError,
    );
  });

  it('a home is drawn in a palette colour, not any string', () => {
    expect(() =>
      parseInput(accept.schema, { ...accept.body, home: { name: 'Dad', color: '#ff0000' } }),
    ).toThrow(HttpsError);
  });

  it('a blank note is no note', () => {
    const { schema, body } = validBodies.answerCoParentChange;
    expect(parseInput(schema, { ...body, note: '   ' }).note).toBeNull();
  });

  it('a change is a swap or a schedule, and nothing else', () => {
    const { schema, body } = validBodies.proposeCoParentChange;
    expect(() =>
      parseInput(schema, { ...body, change: { kind: 'schedule', schedule: ALTERNATING } }),
    ).not.toThrow();
    expect(() => parseInput(schema, { ...body, change: { kind: 'forever' } })).toThrow(HttpsError);
  });

  it('an answer is accept, decline or withdraw', () => {
    const { schema, body } = validBodies.answerCoParentChange;
    expect(() => parseInput(schema, { ...body, answer: 'insist' })).toThrow(HttpsError);
  });

  it('a handover holds at most thirty bag items', () => {
    const { schema, body } = validBodies.saveCoParentHandover;
    const items = Array.from({ length: 31 }, () => ({ text: 'Sock', packed: false }));
    expect(() => parseInput(schema, { ...body, items })).toThrow(HttpsError);
  });
});
