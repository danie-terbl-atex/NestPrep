import {
  type FrameShareDocument,
  type FrameShareKind,
  FRAME_PAGE_ONLY,
  frameDocument,
  parsed,
  shareKind,
} from './frame_documents';
import { FRAME_SHARE_FRESH_MS } from './frame_policy';
import type { FrameRecipe } from './frame_recipe';

export interface FrameSharedPage {
  readonly id: string;
  readonly kind: 'page';
  readonly url: string;
  readonly title: string | null;
  readonly by: string;
}

export interface FrameSharedRecipe {
  readonly id: string;
  readonly kind: 'recipe';
  readonly title: string | null;
  readonly by: string;
  readonly recipe: FrameRecipe;
}

export type FrameShared = FrameSharedPage | FrameSharedRecipe;

export interface FrameShareSnapshot {
  readonly exists: boolean;
  data(): unknown;
}

export interface FrameShareSource {
  onSnapshot(
    onNext: (snapshot: FrameShareSnapshot) => void,
    onError: (error: Error) => void,
  ): () => void;
}

export function shareQualifies(
  share: FrameShareDocument | null,
  after: string | null,
  now: Date,
  accepts: readonly FrameShareKind[] = FRAME_PAGE_ONLY,
): share is FrameShareDocument {
  return (
    share !== null &&
    share.id !== after &&
    accepts.includes(shareKind(share)) &&
    now.getTime() - share.at.toMillis() <= FRAME_SHARE_FRESH_MS
  );
}

export function shared(share: FrameShareDocument): FrameShared {
  const { id, title, by } = share;
  return share.kind === 'recipe'
    ? { id, kind: 'recipe', title, by, recipe: share.recipe }
    : { id, kind: 'page', url: share.url, title, by };
}

export async function awaitFrameShare(
  source: FrameShareSource,
  after: string | null,
  waitMs: number,
  accepts: readonly FrameShareKind[] = FRAME_PAGE_ONLY,
): Promise<FrameShared | null> {
  let deadline: NodeJS.Timeout | undefined;
  let unsubscribe = (): void => undefined;
  try {
    return await new Promise<FrameShared | null>((resolve, reject) => {
      deadline = setTimeout(() => {
        resolve(null);
      }, waitMs);
      unsubscribe = source.onSnapshot((snapshot) => {
        const frame = snapshot.exists ? parsed(frameDocument, snapshot.data()) : null;
        if (frame === null || !frame.panels.share) {
          resolve(null);
        } else if (shareQualifies(frame.share, after, new Date(), accepts)) {
          resolve(shared(frame.share));
        }
      }, reject);
    });
  } finally {
    clearTimeout(deadline);
    unsubscribe();
  }
}
