// Builds NestPrep's public site into `hosting/public/`, which Firebase Hosting
// serves (see "Hosting" in the root CLAUDE.md). The output is generated and
// committed, like `firestore.rules`: edit `hosting/src/` or the legal documents
// in `app/assets/legal/`, then build — never edit `hosting/public/` by hand.
//
//   node hosting/tools/build-site.mjs           write hosting/public/
//   node hosting/tools/build-site.mjs --check   exit 1 if it is out of date
//
// `firebase deploy --only hosting` runs the check first, so a stale site — a
// privacy policy that says something the app's copy does not — cannot ship.

import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildSite } from './site-pages.mjs';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const publicDir = join(repoRoot, 'hosting/public');

function filesUnder(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    throw error;
  }
  return entries.flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? filesUnder(path) : [relative(publicDir, path)];
  });
}

function sameContents(path, expected) {
  try {
    return readFileSync(path).equals(Buffer.from(expected));
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

/** Every file that differs, is missing, or should not be there. */
function staleFiles(site) {
  const stale = [...site]
    .filter(([path, contents]) => !sameContents(join(publicDir, path), contents))
    .map(([path]) => path);
  const extra = filesUnder(publicDir).filter((path) => !site.has(path));
  return [...stale, ...extra].sort();
}

const site = buildSite(repoRoot);

if (process.argv.includes('--check')) {
  const stale = staleFiles(site);
  if (stale.length > 0) {
    console.error(
      `hosting/public is out of date (${stale.join(', ')}). ` +
        'Run `npm --prefix functions run site:build` and commit the result.',
    );
    process.exit(1);
  }
  console.log(`hosting/public is up to date (${String(site.size)} files).`);
} else {
  rmSync(publicDir, { recursive: true, force: true });
  for (const [path, contents] of site) {
    const target = join(publicDir, path);
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, contents);
  }
  console.log(`hosting/public built (${String(site.size)} files).`);
}
