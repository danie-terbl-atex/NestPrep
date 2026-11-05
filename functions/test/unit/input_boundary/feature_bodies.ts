import { deleteAccountInput } from '../../../src/account_data/schemas';
import { setCarerShiftOnlyInput } from '../../../src/nanny_hub/schemas';
import {
  createDocumentShareInput,
  revokeDocumentShareInput,
} from '../../../src/documents/share/share_schemas';
import { readShoppingListInput } from '../../../src/list_scan/schemas';
import { readSchoolLetterInput } from '../../../src/school_letter/schemas';
import {
  acceptCoParentInviteInput,
  answerCoParentChangeInput,
  confirmCoParentLinkInput,
  createCoParentInviteInput,
  endCoParentLinkInput,
  previewCoParentInviteInput,
  proposeCoParentChangeInput,
  saveCoParentHandoverInput,
} from '../../../src/coparent/schemas';
import { ALTERNATING, DADS_HOME, MUMS_HOME } from '../../coparent_fixtures';
import { buildLunchWeekInput, draftLunchIdeasInput } from '../../../src/plan_week/schemas';
import { lunchPhotoInput } from '../../../src/lunch_photos/schemas';
import { recordPaywallOpenedInput } from '../../../src/product_analytics/record_paywall_opened';
import { ensureReferralCodeInput, redeemReferralCodeInput } from '../../../src/referrals/schemas';
import {
  claimPremiumVoucherInput,
  premiumVouchersForMeInput,
  sendVoucherEmailCodeInput,
  verifyVoucherEmailCodeInput,
} from '../../../src/premium_vouchers/schemas';
import {
  setChildProfileInput,
  subscriptionOfferInput,
  verifyPurchaseInput,
} from '../../../src/subscriptions/schemas';
import { translateHomeCareTextsInput } from '../../../src/home_care/schemas';
import {
  addFrameEventInput,
  claimFramePairingInput,
  getFrameDayInput,
  getFramePhotosInput,
  pollFramePairingInput,
  startFramePairingInput,
  tickFrameItemInput,
  unlinkFrameInput,
} from '../../../src/frames/frame_schemas';
import { sendTestNotificationInput } from '../../../src/notifications/schemas';
import {
  checkersPushToCartInput,
  checkersRequestOtpInput,
  checkersVerifyOtpInput,
} from '../../../src/checkers/schemas';
import { pnpCompleteLinkInput, pnpPushToCartInput } from '../../../src/pnp/pnp_schemas';

/** Subscriptions, home care, co-parenting, nanny hub and the shops. */
const FRAME_SECRET = 'q'.repeat(43);

export const featureBodies = {
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
  // Plan my week: the week and whose lunches, then what the store had for
  // each idea — every product field said, so nothing defaults on the server
  // (lunch-box ADR-0012).
  // `aisle` is optional — a phone that read no shelf sends none — so it is
  // not here; its shape is in plan_week/aisle.test.ts (lunch-box ADR-0013).
  draftLunchIdeas: {
    schema: draftLunchIdeasInput,
    body: { householdId: 'h1', week: '2026-W40', childIds: ['m-kid'] },
  },
  buildLunchWeek: {
    schema: buildLunchWeekInput,
    body: {
      householdId: 'h1',
      week: '2026-W40',
      childIds: ['m-kid'],
      ideas: [
        {
          id: 'idea-1',
          slot: 'fruit',
          childIds: ['m-kid'],
          fromAisle: false,
          products: [
            {
              productId: 'p1',
              name: 'Apples 1.5kg',
              brand: null,
              priceCents: 3499,
              isOnPromotion: false,
              allergens: [],
              allergensKnown: true,
              packQuantity: null,
            },
          ],
        },
      ],
    },
  },
  // A lunch box's picture: whose box, which day (lunch-box ADR-0015).
  lunchPhoto: {
    schema: lunchPhotoInput,
    body: { householdId: 'h1', childId: 'm-kid', date: '2026-10-05' },
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
  // Snap a shopping list: the photo travels in the call and is never stored
  // (list-scan ADR-0001).
  readShoppingList: {
    schema: readShoppingListInput,
    body: { householdId: 'h1', mimeType: 'image/jpeg', data: '/9j/4AAQ' },
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
  premiumVouchersForMe: { schema: premiumVouchersForMeInput, body: {} },
  claimPremiumVoucher: {
    schema: claimPremiumVoucherInput,
    body: { voucherId: 'order-1_1', householdId: 'h1' },
  },
  sendVoucherEmailCode: { schema: sendVoucherEmailCodeInput, body: { email: 'sam@example.com' } },
  verifyVoucherEmailCode: {
    schema: verifyVoucherEmailCodeInput,
    body: { email: 'sam@example.com', code: '123456' },
  },
  recordPaywallOpened: {
    schema: recordPaywallOpenedInput,
    body: { householdId: 'h1', trigger: 'prepList' },
  },
  sendTestNotification: { schema: sendTestNotificationInput, body: { householdId: 'h1' } },
  // Add to Checkers (the Checkers build contract). Link status and unlink take no body.
  checkersRequestOtp: { schema: checkersRequestOtpInput, body: { mobile: '082 123 4567' } },
  checkersVerifyOtp: { schema: checkersVerifyOtpInput, body: { code: '123456' } },
  checkersPushToCart: {
    schema: checkersPushToCartInput,
    body: { householdId: 'h1', itemIds: ['milk', 'bread'] },
  },
  // Add to Pick n Pay (add-to-pnp ADR-0003). Status, start and unlink take no body.
  pnpCompleteLink: { schema: pnpCompleteLinkInput, body: { code: 'abc', state: 'xyz' } },
  pnpPushToCart: {
    schema: pnpPushToCartInput,
    body: { householdId: 'h1', itemIds: ['milk'] },
  },
  // Photo frames (photo-frames ADR-0001). `model` is optional, so it is not
  // in the body; its own cases are in `frames/frame_day.test.ts`.
  startFramePairing: { schema: startFramePairingInput, body: { secret: FRAME_SECRET } },
  pollFramePairing: {
    schema: pollFramePairingInput,
    body: { code: 'ABC234', secret: FRAME_SECRET },
  },
  claimFramePairing: {
    schema: claimFramePairingInput,
    body: {
      householdId: 'h1',
      code: 'ABC234',
      name: 'Kitchen',
      panels: { calendar: true, todos: true, meals: true, helperMemberId: null },
    },
  },
  getFrameDay: { schema: getFrameDayInput, body: { secret: FRAME_SECRET } },
  getFramePhotos: { schema: getFramePhotosInput, body: { secret: FRAME_SECRET } },
  unlinkFrame: { schema: unlinkFrameInput, body: { secret: FRAME_SECRET } },
  tickFrameItem: {
    schema: tickFrameItemInput,
    body: { secret: FRAME_SECRET, kind: 'task', id: 'task-1', date: '2026-10-25', done: true },
  },
  // The times, note and repeat are optional; their cases are in `frames/frame_events.test.ts`.
  addFrameEvent: {
    schema: addFrameEventInput,
    body: { secret: FRAME_SECRET, title: 'Dentist', date: '2026-11-03', who: [], by: 'Sam' },
  },
} as const;
