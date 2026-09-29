import { defineConfig } from 'vitest/config';

// Rules tests need the Firestore emulator, so they are a separate run from the
// pure-function tests: `npm run test:rules` starts the emulator around them.
export default defineConfig({
  test: {
    include: ['test/rules/**/*.test.ts'],
    fileParallelism: false,
    testTimeout: 20_000,
    // A hook's budget includes the first file's cold load of both rulesets
    // into the emulator, which takes well past 20 s on a loaded machine. A
    // test's own budget stays 20 s: a single rule check that slow is a bug.
    hookTimeout: 60_000,
  },
});
