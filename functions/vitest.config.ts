import { defineConfig } from 'vitest/config';

// The pure-function tests, which need nothing running. Rules tests live under
// `test/rules/` and run against the emulator through `npm run test:rules`.
export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    exclude: ['test/rules/**'],
  },
});
