import { setGlobalOptions } from 'firebase-functions/v2';

export { createHousehold } from './household/create_household';
export { createInvite } from './household/create_invite';
export { redeemInvite } from './household/redeem_invite';
export { leaveHousehold } from './household/leave_household';
export { removeMember } from './household/remove_member';
export { setMemberRole } from './household/set_member_role';

// One region for every function, chosen when the cloud project exists
// (foundation ADR-0003). Explicit limits are BE-19.
setGlobalOptions({ maxInstances: 10, timeoutSeconds: 30, memory: '256MiB' });
