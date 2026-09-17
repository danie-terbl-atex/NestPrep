import { defineConfig } from 'vitest/config';

// End-to-end tests of the callables against the emulator suite: they sign a real
// user in and call over HTTP the way the app does (BE-14). `npm run test:emulator`
// starts the emulators around them.
export default defineConfig({
  test: {
    include: ['test/emulator/**/*.test.ts'],
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});
