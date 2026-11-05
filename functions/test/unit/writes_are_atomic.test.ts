import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

/**
 * `BE-06`/`BE-07`: anything touching more than one document is a transaction,
 * and every write a callable makes is staged on it.
 *
 * These functions exist precisely because Security Rules cannot move several
 * documents at once. Redeeming an invite claims a member, adds a uid to the
 * household's role map, adds the household to the account and closes the
 * invite — four documents. A direct write among them is a household left half
 * joined, with no error anywhere: the call returns, and the person is a member
 * of a household that does not list them.
 *
 * And `BE-19`: a callable declares its timeout and its memory, so an infinite
 * loop is a bill for thirty seconds rather than for nine minutes.
 */

const srcDir = resolve(import.meta.dirname, '../../src');

function sourcesIn(dir: string): { name: string; source: string }[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = resolve(dir, entry.name);
    if (entry.isDirectory()) return sourcesIn(path);
    if (!entry.name.endsWith('.ts')) return [];
    return [{ name: path.slice(srcDir.length + 1), source: readFileSync(path, 'utf8') }];
  });
}

const sources = sourcesIn(srcDir);

describe('every write a callable makes is atomic', () => {
  it('finds the source it is checking', () => {
    expect(sources.length).toBeGreaterThanOrEqual(10);
  });

  it('no document is written outside a transaction or a batch', () => {
    // Match the *call*, then look at what it is called on. Requiring a bare
    // word before the dot misses `householdRef(store, id).update(…)`, which is
    // the shape a direct write actually takes — that hole let a deliberately
    // broken version of this pass.
    const write = /\.(set|update|delete|create)\(/g;
    // `FieldValue.delete()` is a sentinel value handed to an update, not an
    // operation of its own.
    const allowed = ['transaction', 'batch', 'FieldValue', 'Timestamp'];
    const offences: string[] = [];

    for (const { name, source } of sources) {
      for (const match of source.matchAll(write)) {
        const before = source.slice(0, match.index);
        const receiver = /([\w$]+)$/.exec(before)?.[1] ?? '(an expression)';
        if (allowed.includes(receiver)) continue;
        const line = before.split('\n').length;
        offences.push(`${name}:${String(line)}  ${receiver}${match[0]}`);
      }
    }

    expect(
      offences,
      'a write outside the transaction leaves a household half changed, and ' +
        'nothing reports it — the call succeeds (BE-06, BE-07)',
    ).toEqual([]);
  });

  it('and the ones that move several documents say so in a comment', () => {
    // Not enforceable, but worth asserting the transaction is reached for the
    // file that moves the most: redeeming an invite touches four documents.
    const redeem = sources.find((file) => file.name.endsWith('redeem_invite.ts'));
    expect(redeem).toBeDefined();
    const source = redeem?.source ?? '';
    expect(source).toContain('runTransaction');
    // `recordClaim(transaction, …)` stages the household's side of the claim —
    // role, profile and grant (household ADR-0003) — on the same transaction.
    expect(
      (source.match(/transaction\.(set|update|delete)\(|recordClaim\(transaction/g) ?? []).length,
    ).toBeGreaterThanOrEqual(4);
  });
});

describe('every callable declares what it may cost', () => {
  const index = sources.find((file) => file.name === 'index.ts');

  // The limits themselves are asserted in `global_options.test.ts`, against the
  // endpoints the build actually produces.
  //
  // They used to be asserted *here*, by matching `setGlobalOptions({...})` in
  // this file's text — and that assertion passed for the life of the project
  // while every limit was `null` at runtime, because the call sat below the
  // `export ... from` lines and ES modules evaluate imports first. A test that
  // reads the source can only ever prove somebody typed the words. This one is
  // gone rather than moved, so there is one home for the fact (`ENG-01`).

  it('imports the module that sets the global options before anything else', () => {
    // What this file *can* still check is the ordering the runtime depends on:
    // the side-effect import has to come before the first callable export, or
    // the options are built too late again.
    const source = index?.source ?? '';
    const optionsAt = source.indexOf("import './shared/global_options'");
    const firstExportAt = source.indexOf('export {');
    expect(optionsAt, 'index.ts imports ./shared/global_options').toBeGreaterThanOrEqual(0);
    expect(
      optionsAt,
      'the options import must precede every callable export, or it sets nothing',
    ).toBeLessThan(firstExportAt);
  });

  it('and every exported callable is one we meant to ship', () => {
    // The list is the point: a Function is what rules cannot express, so a new
    // name here should have cost somebody an ADR to justify. Six were the
    // household's; the two documents ones are the household claim Storage rules
    // need and the folder-is-empty check no rule can perform (documents
    // ADR-0001). The five product-analytics ones count the beta numbers, which
    // no rule can do because a rule cannot write a second document
    // (product-analytics ADR-0001). `setMemberAccess` is the grant a parent
    // chooses, which lives on the profile and on the household document at
    // once (household ADR-0003).
    const exported = [...(index?.source ?? '').matchAll(/export \{ (\w+) \}/g)].flatMap((match) =>
      match[1] === undefined ? [] : [match[1]],
    );
    expect([...exported].sort()).toEqual(
      [
        // Household and documents (household ADR-0001–0003, documents ADR-0001).
        'createHousehold',
        'createInvite',
        'deleteDocumentFolder',
        'leaveHousehold',
        'previewInvite',
        'redeemInvite',
        'removeMember',
        'setMemberAccess',
        'setMemberRole',
        'syncDocumentAccess',
        // Documents phase 2: the one door to a vault document's bytes, which
        // writes the view log a client could skip, and the daily expiry sweep,
        // which no rule can schedule (documents ADR-0003, ADR-0005).
        'openVaultDocument',
        'sweepExpiryReminders',
        // Product analytics: counting the beta numbers, which no rule can do
        // because a rule cannot write a second document (product-analytics
        // ADR-0001).
        'countHouseholdCreated',
        'countInviteCreated',
        'countLunchPlanCreated',
        'recordActivity',
        'rollupBetaNumbers',
        // Kid sign-in: mint and revoke custom tokens and move a code, a device
        // and a household map entry together (accounts ADR-0003).
        'cancelKidPairing',
        'createKidPairing',
        'redeemKidPairing',
        'resetKidSignIn',
        'revokeKidDevice',
        // Calendar sync (calendar ADR-0003): a provider's token exchange and
        // refresh, a link fetched with an address check, a feed served by
        // token, and a schedule — none of which a rule can do.
        'calendarFeed',
        'calendarOAuthCallback',
        'connectCalendarLink',
        'disconnectCalendar',
        'listCalendarProviders',
        'resetCalendarFeed',
        'shareCalendarFeed',
        'startCalendarConnection',
        'syncCalendarConnection',
        'syncCalendarsOnSchedule',
        // Todos phase 2: a child's stars, which only Functions write — a
        // ledger line and its balance together, a date checked against the
        // chore's schedule, and a parent's review in the same transaction as
        // the stars (todos ADR-0003).
        'awardChorePoints',
        'reserveRewardPoints',
        'reviewChore',
        'settleReward',
        // Nanny hub: ending a shift writes a summary derived from every entry
        // the carer logged, which no rule can read or count (nanny-hub
        // ADR-0002).
        'endNannyShift',
        // Subscriptions (subscriptions ADR-0001): a store receipt verified
        // with the store's own server before the entitlement is written, the
        // two stores' notifications and a daily reconcile — and marking a
        // child, which the free tier counts and no rule can count.
        'appStoreNotifications',
        'getSubscriptionOffer',
        'playBillingNotifications',
        'reconcileSubscriptions',
        'setChildProfile',
        'verifyPurchase',
        // Account data (accounts ADR-0006): erasing an account moves every
        // household it is in and deletes Auth users and Storage bytes; an
        // export reads across all of it; the web request is rate-limited and
        // written where no client can read — none of which a rule can do.
        'deleteAccount',
        'exportAccountData',
        'previewAccountDeletion',
        'requestAccountDeletion',
        'sweepAccountExports',
        // Closing a household ends it the way erasure does, Auth users and
        // Storage bytes included (household ADR-0007).
        'closeHousehold',
        // Home care V2: a low product's grocery line written on the
        // household's behalf, whatever the marker's groceries grant, once
        // (home-care ADR-0005); and a translation paid for from a monthly cap
        // only a server can hold, as the Functions' own service account
        // (home-care ADR-0006).
        'addLowStockToGroceries',
        'translateHomeCareTexts',
        // Documents V2: a link to one document, which a rule cannot mint,
        // hash, count, serve to somebody with no account or end with a shift
        // (documents ADR-0006).
        'createDocumentShare',
        'documentShare',
        'endSharesWithShift',
        'revokeDocumentShare',
        // Snap a school letter: the model is called only from a Function, as
        // its service account, behind a monthly cap claimed in a transaction
        // (calendar ADR-0005, foundation ADR-0015).
        'readSchoolLetter',
        // Snap a shopping list: the same model door, behind premium; it
        // writes nothing but the cap's ledger — the app adds the lines
        // (list-scan ADR-0001).
        'readShoppingList',
        // Co-parenting: a child in two homes. Every write goes to both
        // households' mirrors of the link in one transaction, which no client
        // may do because no client is in both (household ADR-0004).
        'acceptCoParentInvite',
        'answerCoParentChange',
        'confirmCoParentLink',
        'createCoParentInvite',
        'endCoParentLink',
        'previewCoParentInvite',
        'proposeCoParentChange',
        'saveCoParentHandover',
        // Nanny hub V2: the shift-only mark lives in the household document,
        // which only Functions write (nanny-hub ADR-0006).
        'setCarerShiftOnly',
        // Referrals and conversion by trigger (subscriptions ADR-0002,
        // product-analytics ADR-0002): a code no phone may pick, a redemption
        // checked against two households at once, and a paywall opening that
        // is counted where no client can move the number.
        'ensureReferralCode',
        'recordPaywallOpened',
        'redeemReferralCode',
        // Notifications (notifications ADR-0001 to ADR-0003): a push is sent
        // from a server, never a rule; a digest reads every area a person may
        // see and composes one message from them; a producer's record is
        // fanned out to each person it concerns, at their time.
        'composeMorningDigests',
        'deliverNotifications',
        'notifyChoreCheck',
        'notifyRewardRequest',
        'notifyShiftHandover',
        'sendTestNotification',
        // The V2 producers on the same channel (nanny-hub ADR-0004, household
        // ADR-0004): each fans a record out to the people it concerns.
        'notifyCoParentHandover',
        'notifyCoParentRequest',
        'notifyPhotoUpdate',
        'notifyPlaceEvent',
        // Plan my week: two proposals from the model — ideas, then the week
        // from the store's products — behind premium and the same monthly
        // cap; they write nothing but the cap's own ledger (lunch-box
        // ADR-0012, foundation ADR-0015).
        'buildLunchWeek',
        'draftLunchIdeas',
        // A picture of a lunch box: an image model reached only from a
        // Function, behind premium and the same monthly cap, cached by
        // combination where no client may write (lunch-box ADR-0015).
        'lunchPhoto',
        // Add to Checkers: a member's Checkers session is held by the server,
        // sealed, and used to fill their own Sixty60 cart — nothing a rule or
        // a phone may hold (the Checkers build contract).
        'checkersLinkStatus',
        'checkersPushToCart',
        'checkersRequestOtp',
        'checkersUnlink',
        'checkersVerifyOtp',
        // Add to Pick n Pay: the member's PnP tokens are sealed and held by
        // the server, and fill their own PnP cart (add-to-pnp ADR-0003).
        'pnpCompleteLink',
        'pnpLinkStatus',
        'pnpPushToCart',
        'pnpStartLink',
        'pnpUnlink',
        // Jev's ranking of a grocery line's matches: the TypeSafe key is a
        // server secret (foundation ADR-0021).
        'rankProductMatches',
        // A household recipe's allergen codes come from word lists no rule
        // can run, so only a Function writes one (recipes ADR-0002).
        'saveLunchRecipes',
        // Photo frames: a device with no Auth user pairs by a code a parent
        // claims, and reads a day assembled across areas no grant opens to it
        // (photo-frames ADR-0001), and unlinks itself with its own secret
        // (photo-frames ADR-0004). It reads a month (photo-frames ADR-0005)
        // and its household's screensaver album (photo-frames ADR-0006) the
        // same way, ticks what its panels show (photo-frames ADR-0007),
        // adds an event in the name of whoever says they are adding it
        // (photo-frames ADR-0008), fetches today's lunch-box pictures
        // (photo-frames ADR-0009), opens a page family shares from a phone,
        // which only family may put on the wall (C-0023 rev 9), streams a
        // shared recipe's photo (photo-frames ADR-0013), and searches the
        // family's shop and adds to the grocery list in the name of whoever
        // says they are adding it (photo-frames ADR-0012).
        'addFrameEvent',
        'addFrameGroceryItem',
        'claimFramePairing',
        'getFrameDay',
        'getFrameLunchPhoto',
        'getFrameMonth',
        'getFrameRecipePhoto',
        'getFramePhoto',
        'getFramePhotos',
        'pollFramePairing',
        'searchFrameProducts',
        'shareToFrame',
        'startFramePairing',
        'tickFrameItem',
        'unlinkFrame',
        'waitFrameShare',
        // Assistants: an OAuth authorization server — codes, tokens and a
        // fetched client document no rule can issue, hash or check — the MCP
        // endpoint, which acts for a bearer token no rule can read, and the
        // trigger that disconnects a member who leaves or stops being family
        // (assistants ADR-0001 to ADR-0003).
        'assistantAuth',
        'assistantMcp',
        'pruneAssistantConnections',
        // Premium vouchers and codes: an HMAC no rule can compute, a claim
        // checked against a code, a household and a person at once, and an
        // email proved by a code a server sends (subscriptions ADR-0003,
        // ADR-0004).
        'claimPremiumVoucher',
        'issuePremiumVouchers',
        'premiumVouchersForMe',
        'premiumWeb',
        'sendVoucherEmailCode',
        'verifyVoucherEmailCode',
        'voidFrameVoucher',
      ].sort(),
    );
  });
});
