import {
  createHouseholdInput,
  createInviteInput,
  leaveHouseholdInput,
  previewInviteInput,
  redeemInviteInput,
  removeMemberInput,
  setMemberAccessInput,
  setMemberRoleInput,
} from '../../../src/household/schemas';
import { ROLE_DEFAULTS } from '../../../src/household/access';
import { deleteDocumentFolderInput, openVaultDocumentInput } from '../../../src/documents/schemas';
import { endNannyShiftInput } from '../../../src/nanny_hub/schemas';
import { recordActivityInput } from '../../../src/product_analytics/record_activity';
import {
  cancelKidPairingInput,
  createKidPairingInput,
  redeemKidPairingInput,
  resetKidSignInInput,
  revokeKidDeviceInput,
} from '../../../src/accounts/kid_schemas';
import { sendPasswordResetInput } from '../../../src/accounts/password_reset';
import { reviewChoreInput, settleRewardInput } from '../../../src/chore_points/schemas';
import {
  connectCalendarLinkInput,
  connectionInput,
  householdInput,
  pushAppleCalendarInput,
  startCalendarConnectionInput,
} from '../../../src/calendar_sync/schemas';

/** Accounts, households, documents, kids and calendars. */
export const coreBodies = {
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
  previewInvite: { schema: previewInviteInput, body: { code: 'ABCD2345' } },
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
  sendPasswordReset: { schema: sendPasswordResetInput, body: { email: 'sam@example.com' } },
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
  pushAppleCalendar: {
    schema: pushAppleCalendarInput,
    body: {
      householdId: 'h1',
      link: true,
      occurrences: [
        {
          id: 'e1',
          title: 'Swimming',
          allDay: false,
          start: 1_790_000_000_000,
          end: 1_790_003_600_000,
        },
      ],
    },
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
} as const;
