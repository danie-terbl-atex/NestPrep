import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

/**
 * Where chores' stars live under a household (todos ADR-0003). Every one of
 * these but `rewards` and a request's first four fields is written by
 * Functions and nothing else; the rules refuse every client write to them.
 */
export const TASKS = 'tasks';
export const ROUTINES = 'routines';
export const TASK_COMPLETIONS = 'taskCompletions';
export const POINT_CLAIMS = 'pointClaims';
export const POINT_ENTRIES = 'pointEntries';
export const POINT_BALANCES = 'pointBalances';
export const REWARDS = 'rewards';
export const REWARD_REQUESTS = 'rewardRequests';

function inHousehold(
  store: Firestore,
  householdId: string,
  collection: string,
  id: string,
): DocumentReference {
  return householdRef(store, householdId).collection(collection).doc(id);
}

export function taskRef(store: Firestore, householdId: string, taskId: string): DocumentReference {
  return inHousehold(store, householdId, TASKS, taskId);
}

export function routineRef(
  store: Firestore,
  householdId: string,
  routineId: string,
): DocumentReference {
  return inHousehold(store, householdId, ROUTINES, routineId);
}

export function completionRef(
  store: Firestore,
  householdId: string,
  completionId: string,
): DocumentReference {
  return inHousehold(store, householdId, TASK_COMPLETIONS, completionId);
}

/** Keyed like the completion it is about, so there is one per occurrence. */
export function claimRef(
  store: Firestore,
  householdId: string,
  completionId: string,
): DocumentReference {
  return inHousehold(store, householdId, POINT_CLAIMS, completionId);
}

export function entryRef(
  store: Firestore,
  householdId: string,
  entryId: string,
): DocumentReference {
  return inHousehold(store, householdId, POINT_ENTRIES, entryId);
}

export function balanceRef(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference {
  return inHousehold(store, householdId, POINT_BALANCES, memberId);
}

export function rewardRef(
  store: Firestore,
  householdId: string,
  rewardId: string,
): DocumentReference {
  return inHousehold(store, householdId, REWARDS, rewardId);
}

export function requestRef(
  store: Firestore,
  householdId: string,
  requestId: string,
): DocumentReference {
  return inHousehold(store, householdId, REWARD_REQUESTS, requestId);
}
