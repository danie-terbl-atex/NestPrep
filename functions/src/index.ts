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
export { syncDocumentAccess } from './documents/sync_document_access';
export { deleteDocumentFolder } from './documents/delete_document_folder';

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
