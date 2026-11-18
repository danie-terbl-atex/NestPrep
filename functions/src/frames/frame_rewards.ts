import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { POINT_BALANCES, REWARDS } from '../chore_points/point_refs';
import { parsed } from './frame_documents';

/**
 * The reward shelf and each child's stars on a frame (C-0023 rev 22), read
 * only: a child sees what stars buy, and asks for it on a phone.
 */

export const FRAME_REWARD_LIMIT = 100;

export const frameRewardShape = z.object({
  title: z.string().trim().min(1).max(60),
  cost: z.number().int().min(1).max(10000),
  icon: z.string().catch('gift').default('gift'),
});

const balanceShape = z.object({ balance: z.number() });

export interface FrameReward {
  readonly id: string;
  readonly title: string;
  readonly cost: number;
  readonly icon: string;
}

export interface RewardSources {
  readonly items: readonly FrameReward[];
  /** kidId → stars to spend, with waiting requests already taken off. */
  readonly stars: Readonly<Record<string, number>>;
}

export interface FrameRewards {
  readonly items: FrameReward[];
  readonly balances: { readonly who: string; readonly stars: number }[];
}

export function frameRewardsOf(docs: readonly { id: string; data: unknown }[]): FrameReward[] {
  return docs.flatMap(({ id, data }) => {
    const reward = parsed(frameRewardShape, data);
    return reward === null ? [] : [{ id, ...reward }];
  });
}

export function starsOf(data: unknown): number {
  const stored = parsed(balanceShape, data);
  return stored === null ? 0 : Math.max(0, Math.floor(stored.balance));
}

export function rewardsPanel(
  sources: RewardSources,
  kids: readonly { readonly id: string; readonly name: string }[],
): FrameRewards {
  return {
    items: [...sources.items]
      .sort((a, b) => a.cost - b.cost || a.title.localeCompare(b.title))
      .slice(0, FRAME_REWARD_LIMIT),
    balances: kids.map(({ id, name }) => ({ who: name, stars: sources.stars[id] ?? 0 })),
  };
}

export async function readFrameRewards(
  store: Firestore,
  home: DocumentReference,
  kidIds: readonly string[],
): Promise<RewardSources | undefined> {
  if (kidIds.length === 0) return undefined;
  const [rewardDocs, balanceDocs] = await Promise.all([
    home.collection(REWARDS).orderBy('cost').limit(FRAME_REWARD_LIMIT).get(),
    store.getAll(...kidIds.map((id) => home.collection(POINT_BALANCES).doc(id))),
  ]);
  return {
    items: frameRewardsOf(rewardDocs.docs.map((doc) => ({ id: doc.id, data: doc.data() }))),
    stars: Object.fromEntries(balanceDocs.map((doc) => [doc.id, starsOf(doc.data())] as const)),
  };
}
