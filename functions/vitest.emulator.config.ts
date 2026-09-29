import { defineConfig } from 'vitest/config';

// End-to-end tests of the callables against the emulator suite: they sign a real
// user in and call over HTTP the way the app does (BE-14). `npm run test:emulator`
// starts the emulators around them.
export default defineConfig({
  test: {
    include: ['test/emulator/**/*.test.ts'],
    fileParallelism: false,
    testTimeout: 30_000,
    // A hook's budget includes the first call's cold start of every Function
    // in the emulator, which a loaded machine takes past 30 s over.
    hookTimeout: 60_000,
  },
});
