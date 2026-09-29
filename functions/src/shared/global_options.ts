import { setGlobalOptions } from 'firebase-functions/v2';

import { FUNCTIONS_REGION } from './region';

/**
 * The options every callable runs under (`BE-19`), applied as a side effect of
 * importing this module.
 *
 * **It is a module rather than a call in `index.ts` for one reason, and the
 * reason is not style.** ES modules evaluate every import before the first
 * statement of the importing module's body, so a `setGlobalOptions(...)` written
 * *below* the `export { x } from './feature'` lines runs *after* those modules
 * have already built their `onCall` endpoints — and sets nothing. That is how
 * this project reached its first deploy with `maxInstances`, `timeoutSeconds`
 * and `memory` all silently `null`, discovered on 2026-09-18 when the region
 * would not take either.
 *
 * Importing this first, by declaration order, is what makes the options land.
 * `test/unit/global_options.test.ts` reads the built endpoints and fails if any
 * of them is unset again, because nothing else notices: an unset option is not
 * an error anywhere, it is just a different default.
 *
 * `maxInstances` is the one with teeth — an unbounded callable is the runaway
 * the R200 kill line in foundation ADR-0003 exists to survive.
 */
setGlobalOptions({
  region: FUNCTIONS_REGION,
  maxInstances: 10,
  timeoutSeconds: 30,
  memory: '256MiB',
});
