import { coreBodies } from './core_bodies';
import { featureBodies } from './feature_bodies';

/** What a valid body looks like for each callable that takes one. */
export const validBodies = { ...coreBodies, ...featureBodies } as const;
