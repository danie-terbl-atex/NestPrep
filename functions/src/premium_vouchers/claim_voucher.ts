import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { billingCallerIn } from '../subscriptions/billing_caller';
import { refuseSubscription } from '../subscriptions/errors';
import {
  type HouseholdPremium,
  premiumGrantRef,
  readHouseholdPremium,
  stageHouseholdPremium,
  storeEntitlementOf,
} from '../subscriptions/household_premium';
import type { PremiumGrant } from '../subscriptions/premium_composition';
import { STORE_PURCHASES } from '../subscriptions/subscription_documents';
import { provenEmailHashes, verifiedEmailHashes } from './caller_emails';
import { claimWindowRefusalOf, isNewToPremium, isUsedUp, usedCodeWithinYear } from './code_policy';
import { includesHash } from './premium_hashes';
import type { ClaimPremiumVoucherInput } from './schemas';
import type { VoucherDeps } from './voucher_deps';
import {
  type StoredCode,
  type StoredVoucher,
  CODE_CLAIMS,
  PREMIUM_CODES,
  acquisitionRef,
  codeClaimRef,
  codeRef,
  storedCode,
  storedVoucher,
  voucherGrantId,
  voucherRef,
} from './voucher_documents';

export interface ClaimResult {
  readonly grantId: string;
  readonly days: number;
  readonly startsAt: string | null;
  readonly queued: boolean;
}

interface CodeContext {
  readonly codeId: string;
  readonly code: StoredCode;
}

export async function claimVoucher(
  deps: VoucherDeps,
  uid: string,
  input: ClaimPremiumVoucherInput,
): Promise<ClaimResult> {
  const { store, now } = deps;
  const proven = await provenEmailHashes(deps, uid);
  const result = await store.runTransaction(async (transaction) => {
    const voucher = await readVoucher(transaction, store, input.voucherId);
    const owned = [...proven, ...(await verifiedEmailHashes(store, uid, transaction))];
    if (!includesHash(owned, voucher.emailHash)) throw refuseSubscription('notYourVoucher');
    if (voucher.status === 'claimed') throw refuseSubscription('voucherClaimed');
    if (voucher.status === 'void') throw refuseSubscription('voucherVoid');

    const caller = await billingCallerIn(store, input.householdId, uid, transaction);
    if (!caller.isFamily) throw refuseSubscription('notAMember');
    if (voucher.isTest && !deps.testers.includes(uid)) throw refuseSubscription('testVoucher');

    const code = voucher.kind === 'code' ? await readCode(transaction, store, voucher, now) : null;
    const premium = await readHouseholdPremium(transaction, store, input.householdId);
    if (code !== null) {
      await checkCodeClaim(transaction, store, { ...code, uid, input, premium, now });
    }
    const acquisition = await transaction.get(acquisitionRef(store, input.householdId));

    const grant: PremiumGrant = {
      id: voucherGrantId(input.voucherId),
      source: voucher.kind,
      days: voucher.days,
      grantedAt: now,
      startsAt: null,
    };
    const restated = stageHouseholdPremium(
      transaction,
      store,
      {
        householdId: input.householdId,
        storeEntitlement: storeEntitlementOf(premium.purchases, now),
        premium,
        newGrant: grant,
      },
      now,
    );
    const startsAt = restated.started[grant.id] ?? null;
    const at = Timestamp.fromDate(now);
    transaction.create(premiumGrantRef(store, input.householdId, grant.id), {
      source: grant.source,
      days: grant.days,
      grantedAt: at,
      startsAt: startsAt === null ? null : Timestamp.fromDate(startsAt),
      voucherId: input.voucherId,
    });
    transaction.update(voucherRef(store, input.voucherId), {
      status: 'claimed',
      householdId: input.householdId,
      claimedByUid: uid,
      claimedAt: at,
      grantId: grant.id,
    });
    if (code !== null) {
      transaction.update(codeRef(store, code.codeId), { claimCount: code.code.claimCount + 1 });
      transaction.create(codeClaimRef(store, code.codeId, input.householdId), {
        uid,
        voucherId: input.voucherId,
        at,
      });
    }
    if (voucher.attribution !== null && !acquisition.exists) {
      transaction.create(acquisitionRef(store, input.householdId), {
        code: voucher.attribution.code,
        partnerId: voucher.attribution.partnerId,
        via: voucher.kind === 'frame' ? 'frame-order' : 'premium-code',
        at,
      });
    }
    return { grantId: grant.id, days: grant.days, startsAt, kind: voucher.kind };
  });
  logger.info('premium voucher claimed', {
    householdId: input.householdId,
    voucherId: input.voucherId,
    kind: result.kind,
    queued: result.startsAt === null,
  });
  return {
    grantId: result.grantId,
    days: result.days,
    startsAt: result.startsAt?.toISOString() ?? null,
    queued: result.startsAt === null,
  };
}

async function readVoucher(
  transaction: Transaction,
  store: Firestore,
  voucherId: string,
): Promise<StoredVoucher> {
  const snapshot = await transaction.get(voucherRef(store, voucherId));
  if (!snapshot.exists) throw refuseSubscription('voucherNotFound');
  const parsed = storedVoucher.safeParse(snapshot.data());
  if (!parsed.success) {
    logger.error('premium voucher unreadable', { voucherId });
    throw refuseSubscription('voucherNotFound');
  }
  return parsed.data;
}

async function readCode(
  transaction: Transaction,
  store: Firestore,
  voucher: StoredVoucher,
  now: Date,
): Promise<CodeContext> {
  const codeId = voucher.codeId;
  const snapshot = codeId === null ? null : await transaction.get(codeRef(store, codeId));
  const parsed = snapshot?.exists === true ? storedCode.safeParse(snapshot.data()) : null;
  if (parsed?.success === false) logger.error('premium code unreadable', { codeHash: codeId });
  const code = parsed?.success === true ? parsed.data : null;
  const refusal = claimWindowRefusalOf(code, voucher, now);
  if (refusal !== null || code === null || codeId === null) {
    throw refuseSubscription(refusal ?? 'codeExpired');
  }
  return { codeId, code };
}

interface CodeClaimCheck extends CodeContext {
  readonly uid: string;
  readonly input: ClaimPremiumVoucherInput;
  readonly premium: HouseholdPremium;
  readonly now: Date;
}

async function checkCodeClaim(
  transaction: Transaction,
  store: Firestore,
  check: CodeClaimCheck,
): Promise<void> {
  const { codeId, code, uid, input, premium, now } = check;
  const household = await transaction.get(codeClaimRef(store, codeId, input.householdId));
  if (household.exists) throw refuseSubscription('codeAlreadyUsed', { scope: 'household' });
  const byPerson = await transaction.get(
    store.collectionGroup(CODE_CLAIMS).where('uid', '==', uid),
  );
  const personClaimedThisCode = byPerson.docs.some((doc) => {
    const codeDoc = doc.ref.parent.parent;
    return codeDoc?.id === codeId && codeDoc.parent.id === PREMIUM_CODES;
  });
  if (personClaimedThisCode) throw refuseSubscription('codeAlreadyUsed', { scope: 'person' });
  if (usedCodeWithinYear(premium.grants, now)) throw refuseSubscription('codeYearlyLimit');
  if (code.eligibility === 'newToPremium') {
    const purchases = await transaction.get(
      store.collection(STORE_PURCHASES).where('householdId', '==', input.householdId).limit(1),
    );
    if (!isNewToPremium(premium.grants, !purchases.empty)) {
      throw refuseSubscription('codeNotEligible');
    }
  }
  if (isUsedUp(code)) throw refuseSubscription('codeUsedUp');
}
