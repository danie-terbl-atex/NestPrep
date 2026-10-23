import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import {
  assertFails,
  assertSucceeds,
  clearData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  storageAsStranger,
} from './rules_harness';

/**
 * A catalogue recipe's photos (recipes ADR-0003 §4): NestPrep's own pictures,
 * loaded by anybody signed in, written only by the catalogue seed as the
 * Admin SDK, and never listed — the recipe document names each file.
 */

const HERO = 'recipes/bobotie/hero-0123abcd.jpg';
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);

beforeEach(async () => {
  await clearData();
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), HERO), JPEG, { contentType: 'image/jpeg' });
  });
});

describe('recipes/{recipeId}/{file} in Storage', () => {
  it('is loaded by anybody signed in, in a household or none', async () => {
    await assertSucceeds(getBytes(ref(await storageAsStranger('uid-new'), HERO)));
    await assertSucceeds(getBytes(ref(await storageAs('uid-sam', { h1: 'admin' }, {}), HERO)));
  });

  it('is refused to anybody signed out', async () => {
    await assertFails(getBytes(ref(await storageAsSignedOut(), HERO)));
  });

  it('is never listed, written, replaced or removed by a client', async () => {
    for (const storage of [
      await storageAs('uid-sam', { h1: 'admin' }, {}),
      await storageAsSignedOut(),
    ]) {
      await assertFails(listAll(ref(storage, 'recipes/bobotie')));
      await assertFails(
        uploadBytes(ref(storage, 'recipes/bobotie/card-0123abcd.jpg'), JPEG, {
          contentType: 'image/jpeg',
        }),
      );
      await assertFails(uploadBytes(ref(storage, HERO), JPEG, { contentType: 'image/jpeg' }));
      await assertFails(deleteObject(ref(storage, HERO)));
    }
  });
});
