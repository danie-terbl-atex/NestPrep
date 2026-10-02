// Imported first, and deliberately: it calls `setGlobalOptions`, and ES modules
// evaluate imports in declaration order, before any statement in this file's
// body. Every export below builds its `onCall` endpoint at import time, so the
// options have to be set by a module that is evaluated ahead of them — a call
// at the foot of this file sets nothing at all. See `shared/global_options.ts`.
import './shared/global_options';

export { createHousehold } from './household/create_household';
export { createInvite } from './household/create_invite';
export { redeemInvite } from './household/redeem_invite';
export { leaveHousehold } from './household/leave_household';
export { removeMember } from './household/remove_member';
export { setMemberRole } from './household/set_member_role';
// household phase 2 — what each role may see (household ADR-0003)
export { setMemberAccess } from './household/set_member_access';
export { syncDocumentAccess } from './documents/sync_document_access';
export { deleteDocumentFolder } from './documents/delete_document_folder';

// ---- product analytics: the three beta numbers (product-analytics ADR-0001) ----
export { recordActivity } from './product_analytics/record_activity';
export { countHouseholdCreated } from './product_analytics/count_household_created';
export { countInviteCreated } from './product_analytics/count_invite_created';
export { countLunchPlanCreated } from './product_analytics/count_lunch_plan_created';
export { rollupBetaNumbers } from './product_analytics/rollup_beta_numbers';
// Kid sign-in (accounts ADR-0003).
export { createKidPairing } from './accounts/create_kid_pairing';
export { cancelKidPairing } from './accounts/cancel_kid_pairing';
export { redeemKidPairing } from './accounts/redeem_kid_pairing';
export { revokeKidDevice } from './accounts/revoke_kid_device';
export { resetKidSignIn } from './accounts/reset_kid_sign_in';

// ---- calendar sync (calendar ADR-0003) ----
export { listCalendarProviders } from './calendar_sync/list_calendar_providers';
export { startCalendarConnection } from './calendar_sync/start_calendar_connection';
export { calendarOAuthCallback } from './calendar_sync/calendar_oauth_callback';
export { connectCalendarLink } from './calendar_sync/connect_calendar_link';
export { syncCalendarConnection } from './calendar_sync/sync_calendar_connection';
export { disconnectCalendar } from './calendar_sync/disconnect_calendar';
export { shareCalendarFeed } from './calendar_sync/share_calendar_feed';
export { resetCalendarFeed } from './calendar_sync/reset_calendar_feed';
export { calendarFeed } from './calendar_sync/calendar_feed';
export { syncCalendarsOnSchedule } from './calendar_sync/sync_calendars_on_schedule';

// documents phase 2 — personal vaults and expiry reminders (documents ADR-0003, ADR-0005)
export { openVaultDocument } from './documents/open_vault_document';
export { sweepExpiryReminders } from './documents/sweep_expiry_reminders';

// ---- todos phase 2: chores that earn kids stars (todos ADR-0003) ----
export { awardChorePoints } from './chore_points/award_chore_points';
export { reserveRewardPoints } from './chore_points/reserve_reward_points';
export { reviewChore } from './chore_points/review_chore';
export { settleReward } from './chore_points/settle_reward';
// ---- nanny hub: ending a shift writes the parents' summary (nanny-hub ADR-0002) ----
export { endNannyShift } from './nanny_hub/end_nanny_shift';
// ---- subscriptions: free and premium in both stores (subscriptions ADR-0001) ----
export { getSubscriptionOffer } from './subscriptions/get_subscription_offer';
export { verifyPurchase } from './subscriptions/verify_purchase';
export { appStoreNotifications } from './subscriptions/app_store_notifications';
export { playBillingNotifications } from './subscriptions/play_billing_notifications';
export { reconcileSubscriptions } from './subscriptions/reconcile_subscriptions';
export { setChildProfile } from './family_profiles/set_child_profile';
// ---- account data: delete my account, download my data, the web request (accounts ADR-0006) ----
export { previewAccountDeletion } from './account_data/preview_account_deletion';
export { deleteAccount } from './account_data/delete_account';
export { exportAccountData } from './account_data/export_account_data';
export { sweepAccountExports } from './account_data/sweep_account_exports';
export { requestAccountDeletion } from './account_data/request_account_deletion';

// ---- home care V2: stock to groceries, the helper's language (home-care ADR-0005, ADR-0006) ----
export { addLowStockToGroceries } from './home_care/add_low_stock_to_groceries';
export { translateHomeCareTexts } from './home_care/translate_home_care_texts';

// ---- documents V2: one document shared by an expiring link (documents ADR-0006) ----
export { createDocumentShare } from './documents/share/create_document_share';
export { revokeDocumentShare } from './documents/share/revoke_document_share';
export { documentShare } from './documents/share/document_share';
export { endSharesWithShift } from './documents/share/end_shares_with_shift';

// ---- calendar V2: snap a school letter, the first AI call (calendar ADR-0005, foundation ADR-0015) ----
export { readSchoolLetter } from './school_letter/read_school_letter';

// ---- co-parenting: a child in two homes (household ADR-0004) ----
export { createCoParentInvite } from './coparent/create_coparent_invite';
export { previewCoParentInvite } from './coparent/preview_coparent_invite';
export { acceptCoParentInvite } from './coparent/accept_coparent_invite';
export { confirmCoParentLink } from './coparent/confirm_coparent_link';
export { endCoParentLink } from './coparent/end_coparent_link';
export { proposeCoParentChange } from './coparent/propose_coparent_change';
export { answerCoParentChange } from './coparent/answer_coparent_change';
export { saveCoParentHandover } from './coparent/save_coparent_handover';
// nanny hub V2: a carer who sees the household only on a booked shift (nanny-hub ADR-0006)
export { setCarerShiftOnly } from './nanny_hub/set_carer_shift_only';
// ---- referrals and conversion by trigger (subscriptions ADR-0002, product-analytics ADR-0002) ----
export { ensureReferralCode } from './referrals/ensure_referral_code';
export { redeemReferralCode } from './referrals/redeem_referral_code';
export { recordPaywallOpened } from './product_analytics/record_paywall_opened';
// ---- notifications: the morning digest and the one push channel (notifications ADR-0001 to ADR-0003) ----
export { composeMorningDigests } from './notifications/compose_morning_digests';
export { deliverNotifications } from './notifications/deliver_notifications';
export { notifyShiftHandover } from './notifications/notify_shift_handover';
export { notifyChoreCheck } from './notifications/notify_chore_check';
export { notifyRewardRequest } from './notifications/notify_reward_request';
export { sendTestNotification } from './notifications/send_test_notification';
// the V2 producers on the same channel: a carer's photo (nanny-hub ADR-0004) and
// the other home's requests and handover notes (household ADR-0004)
export { notifyPhotoUpdate } from './notifications/notify_photo_update';
export { notifyCoParentRequest } from './notifications/notify_coparent';
export { notifyCoParentHandover } from './notifications/notify_coparent';
// ---- plan my week from the store, in guided steps: proposals, never a write (lunch-box ADR-0012, foundation ADR-0015) ----
export { draftLunchIdeas } from './plan_week/draft_lunch_ideas';
export { buildLunchWeek } from './plan_week/build_lunch_week';
// ---- a picture of the lunch box, made once per combination (lunch-box ADR-0015, foundation ADR-0015) ----
export { lunchPhoto } from './lunch_photos/lunch_photo';
// ---- add to Checkers: a member's own Sixty60 cart, linked by SMS code (the Checkers build contract) ----
export { checkersLinkStatus } from './checkers/checkers_link_status';
export { checkersRequestOtp } from './checkers/checkers_request_otp';
export { checkersVerifyOtp } from './checkers/checkers_verify_otp';
export { checkersPushToCart } from './checkers/checkers_push_to_cart';
export { checkersUnlink } from './checkers/checkers_unlink';
