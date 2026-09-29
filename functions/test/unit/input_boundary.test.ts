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
import {
  createDocumentShareInput,
  revokeDocumentShareInput,
} from '../../src/documents/share/share_schemas';
import { readSchoolLetterInput } from '../../src/school_letter/schemas';
import { recordActivityInput } from '../../src/product_analytics/record_activity';
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
  setChildProfile: {
    schema: setChildProfileInput,
    body: { householdId: 'h1', memberId: 'm-kid', isChild: true },
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
} as const;

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
