import { defineConfig } from 'vitest/config';

// The pure tests: the parts of a Function that need nothing running. Rules tests
// live under `test/rules/` and callable tests under `test/emulator/`; both need
// the emulator suite and have their own runs.
export default defineConfig({
  test: {
    include: ['test/unit/**/*.test.ts'],
  },
});
