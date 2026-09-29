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

// ---- notifications: the morning digest and the one push channel (notifications ADR-0001 to ADR-0003) ----
export { composeMorningDigests } from './notifications/compose_morning_digests';
export { deliverNotifications } from './notifications/deliver_notifications';
export { notifyShiftHandover } from './notifications/notify_shift_handover';
export { notifyChoreCheck } from './notifications/notify_chore_check';
export { notifyRewardRequest } from './notifications/notify_reward_request';
export { sendTestNotification } from './notifications/send_test_notification';
