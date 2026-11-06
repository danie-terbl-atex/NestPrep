import { defineConfig } from 'vitest/config';

// `emulators:exec` exports every emulator's host but the Functions one, so on
// any ports but firebase.json's the harness would call whatever suite holds 5001.
async function functionsHostFromHub(): Promise<void> {
  const hub = process.env['FIREBASE_EMULATOR_HUB'];
  if (hub === undefined || process.env['FUNCTIONS_EMULATOR_HOST'] !== undefined) return;
  const running = (await (await fetch(`http://${hub}/emulators`)).json()) as {
    functions?: { host: string; port: number };
  };
  if (running.functions === undefined) throw new Error(`no Functions emulator behind hub ${hub}`);
  process.env['FUNCTIONS_EMULATOR_HOST'] =
    `${running.functions.host}:${String(running.functions.port)}`;
}

// End-to-end tests of the callables against the emulator suite: they sign a real
// user in and call over HTTP the way the app does (BE-14). `npm run test:emulator`
// starts the emulators around them.
export default defineConfig(async () => {
  await functionsHostFromHub();
  return {
    test: {
      include: ['test/emulator/**/*.test.ts'],
      fileParallelism: false,
      testTimeout: 30_000,
      // A hook's budget includes the first call's cold start of every Function
      // in the emulator, which a loaded machine takes past 30 s over.
      hookTimeout: 60_000,
    },
  };
});
