// Assembles every file of the public site in memory: the hand-written pages
// under `hosting/src/`, the two legal documents rendered from the app's own
// `app/assets/legal/`, and the brand images and fonts copied from the app's
// assets. `build-site.mjs` writes the result to `hosting/public/` or checks it.
// Nothing here touches the disk except to read.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import {
  escapeHtml,
  headingsOf,
  parseDocument,
  renderBlocks,
  renderInline,
} from './site-markdown.mjs';

/** Copied byte for byte from the app, never edited on the site. */
export const COPIED_ASSETS = [
  ['app/assets/brand/nest_mark.png', 'assets/nest_mark.png'],
  ['app/assets/fonts/DMSans-Regular.ttf', 'assets/fonts/DMSans-Regular.ttf'],
  ['app/assets/fonts/DMSans-Medium.ttf', 'assets/fonts/DMSans-Medium.ttf'],
  ['app/assets/fonts/DMSans-SemiBold.ttf', 'assets/fonts/DMSans-SemiBold.ttf'],
  ['app/assets/fonts/DMSans-Bold.ttf', 'assets/fonts/DMSans-Bold.ttf'],
  ['app/assets/fonts/DMSans-OFL.txt', 'assets/fonts/DMSans-OFL.txt'],
  ['app/assets/fonts/Fraunces-SemiBold.ttf', 'assets/fonts/Fraunces-SemiBold.ttf'],
  ['app/assets/fonts/Fraunces-OFL.txt', 'assets/fonts/Fraunces-OFL.txt'],
  ['hosting/src/site.css', 'assets/site.css'],
  ['hosting/src/delete-account.js', 'assets/delete-account.js'],
  ['hosting/src/invite.js', 'assets/invite.js'],
  ['hosting/src/well-known/assetlinks.json', 'well-known/assetlinks.json'],
];

/** The two documents the app bundles and the site publishes. */
export const LEGAL_DOCUMENTS = [
  {
    source: 'app/assets/legal/privacy-policy.md',
    output: 'privacy/index.html',
    nav: 'privacy',
    description:
      'What NestPrep holds about your household, why, where it is kept, and your rights.',
  },
  {
    source: 'app/assets/legal/terms-of-service.md',
    output: 'terms/index.html',
    nav: 'terms',
    description: 'The agreement between you and NestPrep.',
  },
];

const PAGES = [
  {
    source: 'hosting/src/pages/index.html',
    output: 'index.html',
    title: 'NestPrep — school lunches, sorted before Sunday night',
    description:
      'NestPrep plans a week of school lunches per child, respecting allergies, and runs the rest of the family week.',
    nav: '',
  },
  {
    source: 'hosting/src/pages/delete-account.html',
    output: 'delete-account/index.html',
    title: 'Delete your account — NestPrep',
    description: 'How to delete your NestPrep account and what happens to your information.',
    nav: 'delete-account',
    head: '    <script src="/assets/delete-account.js" defer></script>',
  },
  {
    source: 'hosting/src/pages/invite.html',
    output: 'invite/index.html',
    title: 'Your invite — NestPrep',
    description: 'Join your household on NestPrep.',
    nav: '',
    robots: 'noindex',
    head: '    <script src="/assets/invite.js" defer></script>',
  },
  {
    source: 'hosting/src/pages/404.html',
    output: '404.html',
    title: 'Page not found — NestPrep',
    description: 'That page is not here.',
    nav: '',
    robots: 'noindex',
  },
];

const NAV_KEYS = ['privacy', 'terms', 'delete-account'];

/** Fills the shared layout. Unknown or leftover `{{…}}` markers are a bug, not output. */
export function renderLayout(layout, page) {
  let html = layout
    .replace('{{title}}', escapeHtml(page.title))
    .replace('{{description}}', escapeHtml(page.description))
    .replace('{{robots}}', page.robots ?? 'index, follow')
    .replace('{{head}}\n', page.head === undefined ? '' : `${page.head}\n`)
    .replace('{{body}}', page.body);
  for (const key of NAV_KEYS) {
    html = html.replace(`{{current:${key}}}`, key === page.nav ? ' aria-current="page"' : '');
  }
  const leftover = /\{\{[^}]*\}\}/.exec(html);
  if (leftover !== null) throw new Error(`layout marker left unfilled: ${leftover[0]}`);
  return html;
}

/** "29 September 2026" from "2026-09-29"; anything else is shown as written. */
export function readableDate(isoDate) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDate);
  if (match === null) return isoDate;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return `${Number(match[3])} ${months[Number(match[2]) - 1]} ${match[1]}`;
}

/** A legal document's page body: its title, version, contents and text. */
export function renderLegalBody(document) {
  const contents = headingsOf(document.blocks)
    .map(
      (heading) =>
        `            <li><a href="#${heading.id}">${renderInline(heading.text)}</a></li>`,
    )
    .join('\n');
  return [
    '      <div class="wrap wrap--prose">',
    '        <article class="prose">',
    `          <h1>${escapeHtml(document.title)}</h1>`,
    `          <p class="doc-meta">Version ${document.version} · Updated ${escapeHtml(readableDate(document.updated))}</p>`,
    '          <nav class="toc panel" aria-labelledby="toc-title">',
    '            <h2 id="toc-title">Contents</h2>',
    '            <ul>',
    contents,
    '            </ul>',
    '          </nav>',
    renderBlocks(document.blocks),
    '        </article>',
    '      </div>',
  ].join('\n');
}

/**
 * Every file of the site: a map from its path under `hosting/public/` to its
 * contents, a string for what is written here and a Buffer for what is copied.
 */
export function buildSite(repoRoot) {
  const read = (path) => readFileSync(join(repoRoot, path), 'utf8');
  const layout = read('hosting/src/layout.html');
  const files = new Map();

  for (const page of PAGES) {
    files.set(page.output, renderLayout(layout, { ...page, body: read(page.source).trimEnd() }));
  }
  for (const legal of LEGAL_DOCUMENTS) {
    const document = parseDocument(read(legal.source));
    files.set(
      legal.output,
      renderLayout(layout, {
        title: `${document.title} — NestPrep`,
        description: legal.description,
        nav: legal.nav,
        body: renderLegalBody(document),
      }),
    );
  }
  for (const [from, to] of COPIED_ASSETS) {
    files.set(to, readFileSync(join(repoRoot, from)));
  }
  return files;
}
