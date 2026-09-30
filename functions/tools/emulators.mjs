#!/usr/bin/env node
/**
 * Starts the emulator suite with its data kept between runs, and seeds it
 * once it is listening (foundation ADR-0018):
 *
 *     npm run emulators          this Mac only (127.0.0.1)
 *     npm run emulators:lan      reachable from a phone on the same network
 *
 * Data lives in `emulator-data/` at the repo root (gitignored): imported on
 * start when a previous run exported it, exported again when the suite stops
 * with Ctrl+C. The seed runs after every start and is idempotent, so the demo
 * household and its three fixed accounts are there on the first run and put
 * back on every later one, beside whatever was added by hand.
 *
 * `--lan` writes `firebase.lan.json` beside `firebase.json` (gitignored — it is
 * generated, never edited) with every emulator host set to 0.0.0.0, because
 * the Firebase CLI takes hosts only from a config file. Point a phone at it
 * with `--dart-define=NESTPREP_EMULATOR_HOST=<this Mac's LAN address>`.
 */
import { spawn } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { connect } from 'node:net';
import { resolve } from 'node:path';

const PROJECT = 'nestprep-643b7';
const repoRoot = resolve(import.meta.dirname, '../..');
const functionsDir = resolve(repoRoot, 'functions');
const dataDir = resolve(repoRoot, 'emulator-data');
const lan = process.argv.includes('--lan');

function run(command, args, options = {}) {
  return new Promise((done, fail) => {
    const child = spawn(command, args, { stdio: 'inherit', ...options });
    child.on('error', fail);
    child.on('exit', (code) =>
      code === 0 ? done() : fail(new Error(`${command} exited ${String(code)}`)),
    );
  });
}

/** The config to start from: `firebase.json`, or a LAN copy of it. */
function configFile() {
  const base = resolve(repoRoot, 'firebase.json');
  if (!lan) return base;
  const config = JSON.parse(readFileSync(base, 'utf8'));
  for (const emulator of Object.values(config.emulators ?? {})) {
    if (typeof emulator === 'object' && emulator !== null && 'port' in emulator) {
      emulator.host = '0.0.0.0';
    }
  }
  const lanFile = resolve(repoRoot, 'firebase.lan.json');
  writeFileSync(lanFile, `${JSON.stringify(config, null, 2)}\n`);
  return lanFile;
}

function portIsOpen(port) {
  return new Promise((done) => {
    const socket = connect({ host: '127.0.0.1', port });
    socket.once('connect', () => {
      socket.end();
      done(true);
    });
    socket.once('error', () => done(false));
  });
}

/** Waits until Auth, Firestore and Functions all answer, or gives up after five minutes. */
async function waitForSuite(ports) {
  const deadline = Date.now() + 5 * 60_000;
  while (Date.now() < deadline) {
    const open = await Promise.all(ports.map(portIsOpen));
    if (open.every(Boolean)) return;
    await new Promise((wait) => setTimeout(wait, 2_000));
  }
  throw new Error(`the suite did not open ports ${ports.join(', ')} within five minutes`);
}

const config = configFile();
const { emulators } = JSON.parse(readFileSync(config, 'utf8'));

// The Functions emulator runs lib/, and the seed reads it too.
await run('npm', ['run', 'build'], { cwd: functionsDir });

const args = [
  'emulators:start',
  '--project',
  PROJECT,
  '--config',
  config,
  `--export-on-exit=${dataDir}`,
];
// --import refuses a folder no export has written yet, so the first run starts empty.
if (existsSync(resolve(dataDir, 'firebase-export-metadata.json'))) args.push(`--import=${dataDir}`);

const suite = spawn('firebase', args, { cwd: repoRoot, stdio: 'inherit' });
// Ctrl+C reaches the suite too; this process only waits for it to finish
// exporting, so it must not die first.
process.on('SIGINT', () => {});
process.on('SIGTERM', () => suite.kill('SIGTERM'));
suite.on('exit', (code) => process.exit(code ?? 0));

try {
  await waitForSuite([emulators.auth.port, emulators.firestore.port, emulators.functions.port]);
  await run('node', ['tools/seed-emulator.mjs'], { cwd: functionsDir });
  console.log(
    lan
      ? '\nSeeded. Run the app with --dart-define=NESTPREP_BACKEND=emulator --dart-define=NESTPREP_EMULATOR_HOST=<this Mac’s LAN address>.'
      : '\nSeeded. Run the app with --dart-define=NESTPREP_BACKEND=emulator.',
  );
} catch (error) {
  console.error(`\nThe suite is running but the seed did not finish: ${error.message}`);
  console.error('Run `npm --prefix functions run seed` once it is up.');
}
