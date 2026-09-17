import { defineConfig } from 'vitest/config';

// Rules tests need the Firestore emulator, so they are a separate run from the
// pure-function tests: `npm run test:rules` starts the emulator around them.
export default defineConfig({
  test: {
    include: ['test/rules/**/*.test.ts'],
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 20_000,
  },
});
