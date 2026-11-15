#!/usr/bin/env node
/**
 * Seeds the live demo family into the real project (foundation ADR-0019):
 * five accounts under fixed `demo-` uids, and *The Oak Street Nest* they
 * share, filled with a lived-in fortnight around the week it runs in —
 * calendar, to-dos and stars, meals, lunch boxes, groceries, documents,
 * home care, the nanny hub and the inbox. It also turns every V2 flag on in
 * `appConfig/flags`, which Daniel accepted for release builds.
 *
 * Every write is to the demo household, the demo users or `appConfig/flags`;
 * Daniel's real household is in the same project and nothing here reads or
 * touches it. Safe to run again: ids are fixed and writes overwrite. For a
 * clean slate, `npm run teardown:cloud-demo -- --confirm` first.
 *
 * The shapes are the Functions' own (`lib/`: grants, claims, the free child,
 * the stars ledger, shift summaries, digests), so build first:
 *
 *     npm run build && npm run seed:cloud-demo
 *
 * Needs application-default credentials for the project, and
 * `app/demo_logins.json` (gitignored) for the one password. After changing
 * that password, run with `-- --reset-password` (it signs the demo accounts
 * out everywhere). Prints counts and addresses only, never the password
 * (ENG-18).
 */
import { CLOUD_CAST } from './cloud-demo/cast.mjs';
import { seedAccount } from './cloud-demo/accounts.mjs';
import { connect, demoPassword } from './cloud-demo/admin.mjs';
import { createContext } from './cloud-demo/context.mjs';
import { seedAvatars } from './cloud-demo/avatars.mjs';
import { seedCalendar } from './cloud-demo/calendar.mjs';
import { seedDocuments } from './cloud-demo/documents.mjs';
import { seedGroceries } from './cloud-demo/groceries.mjs';
import { seedHealth } from './cloud-demo/health.mjs';
import { seedHomeCare } from './cloud-demo/home-care.mjs';
import { seedLunch } from './cloud-demo/lunch.mjs';
import { seedLocation } from './cloud-demo/location.mjs';
import { seedLunchStock } from './cloud-demo/lunch-stock.mjs';
import { seedMeals } from './cloud-demo/meals.mjs';
import { seedNanny } from './cloud-demo/nanny.mjs';
import { seedNannyPickups } from './cloud-demo/nanny-pickups.mjs';
import { seedNannyShifts } from './cloud-demo/nanny-shifts.mjs';
import { seedNotifications } from './cloud-demo/notifications.mjs';
import { seedStars } from './cloud-demo/stars.mjs';
import { seedTodos } from './cloud-demo/todos.mjs';
import { seedDemoHousehold } from './demo-household.mjs';

const password = demoPassword();
const { target, store, auth, bucket } = connect();
console.log(`seeding the demo family into ${target}\n`);

const resetPassword = process.argv.includes('--reset-password');

for (const person of CLOUD_CAST.people) {
  console.log(await seedAccount(auth, person, { password, resetPassword }));
}
console.log(await seedDemoHousehold(store, CLOUD_CAST));

const ctx = createContext({ store, bucket, cast: CLOUD_CAST });
console.log(`the week of ${ctx.monday}, today ${ctx.today}`);
for (const part of [
  seedHealth,
  seedCalendar,
  seedTodos,
  seedStars,
  seedAvatars,
  seedMeals,
  seedLunch,
  seedLunchStock,
  seedGroceries,
  seedDocuments,
  seedHomeCare,
  seedNanny,
  seedNannyShifts,
  seedNannyPickups,
  seedLocation,
  // Last: the digest reads everything above.
  seedNotifications,
]) {
  console.log(await part(ctx));
}
console.log('\ndone — the password is in app/demo_logins.json');
