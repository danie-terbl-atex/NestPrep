#!/usr/bin/env node
/**
 * How the recipe import reads real pages (recipes ADR-0008). Fetches each link
 * as the phone will, extracts the same parts, asks the real prompt and schema
 * through Vertex on your own gcloud sign-in, and prints one block per link.
 * Writes nothing. Costs one model call per link, unless `--dry`.
 *
 *     npm run build
 *     node tools/recipe-import-eval.mjs [--dry] <url> [<url> ...]
 */
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { pageLink } = require('../lib/shared/page_link.js');
const { MAX_PAGE_CHARS, MAX_PAGE_IMAGES } = require('../lib/recipes/draft_recipe_schemas.js');

const USER_AGENT = 'NestPrep/1.0 (+https://nestprep.io)';
const TIMEOUT_MS = 8_000;
const MAX_BYTES = 3 * 1024 * 1024;
const MAX_REDIRECTS = 5;
const NOISE = /<(script|style|noscript|svg|nav|header|footer|aside|form)\b[\s\S]*?<\/\1\s*>/gi;
const ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', '#39': "'" };

function unescaped(text) {
  return text
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&([a-z]+|#39);/gi, (entity, name) => ENTITIES[name.toLowerCase()] ?? entity);
}

function isRecipeNode(node) {
  const type = node?.['@type'];
  return type === 'Recipe' || (Array.isArray(type) && type.includes('Recipe'));
}

function recipeNodesIn(value) {
  if (Array.isArray(value)) return value.flatMap(recipeNodesIn);
  if (value === null || typeof value !== 'object') return [];
  if (isRecipeNode(value)) return [value];
  return recipeNodesIn(value['@graph'] ?? []);
}

function jsonLdRecipes(html) {
  const blocks = html.matchAll(
    /<script\b[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script\s*>/gi,
  );
  return [...blocks].flatMap(([, body]) => {
    try {
      return recipeNodesIn(JSON.parse(body));
    } catch {
      return [];
    }
  });
}

function imagesOfNode(image) {
  if (typeof image === 'string') return [image];
  if (Array.isArray(image)) return image.flatMap(imagesOfNode);
  return typeof image?.url === 'string' ? [image.url] : [];
}

function ogImage(html) {
  for (const [tag] of html.matchAll(/<meta\b[^>]*>/gi)) {
    if (!/(?:property|name)\s*=\s*["']og:image(?::url)?["']/i.test(tag)) continue;
    const content = /content\s*=\s*["']([^"']+)["']/i.exec(tag)?.[1];
    if (content !== undefined) return unescaped(content);
  }
  return null;
}

function pageText(html) {
  const body = /<body\b[^>]*>([\s\S]*)<\/body\s*>/i.exec(html)?.[1] ?? html;
  return unescaped(body.replace(NOISE, ' ').replace(/<[^>]+>/g, ' '))
    .replace(/\s+/g, ' ')
    .trim();
}

/** What the phone sends: the recipe's JSON-LD when there is any, its text when there is none. */
function extractedPage(url, html) {
  const title = unescaped(/<title\b[^>]*>([\s\S]*?)<\/title\s*>/i.exec(html)?.[1] ?? '').trim();
  const clippedTitle = title === '' ? null : title.slice(0, 300);
  const recipes = jsonLdRecipes(html);
  const jsonLd = [];
  let room = MAX_PAGE_CHARS - (clippedTitle?.length ?? 0);
  for (const recipe of recipes) {
    const block = JSON.stringify(recipe);
    if (block.length > room) continue;
    jsonLd.push(block);
    room -= block.length;
  }
  const text = jsonLd.length > 0 ? '' : pageText(html).slice(0, room);
  const candidates = [...recipes.flatMap((recipe) => imagesOfNode(recipe.image)), ogImage(html)];
  const imageUrls = [
    ...new Set(
      candidates.flatMap((image) => {
        if (image === null || !URL.canParse(image, url)) return [];
        return pageLink(new URL(image, url).href) ?? [];
      }),
    ),
  ].slice(0, MAX_PAGE_IMAGES);
  return { url, title: clippedTitle, jsonLd, text, imageUrls };
}

async function fetchedHtml(start) {
  let url = pageLink(start);
  const hops = [];
  for (let hop = 0; hop <= MAX_REDIRECTS; hop += 1) {
    if (url === null) return { failure: 'link not public', hops };
    const response = await fetch(url, {
      redirect: 'manual',
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { 'User-Agent': USER_AGENT, Accept: 'text/html,application/xhtml+xml' },
    });
    hops.push(response.status);
    const location = response.headers.get('location');
    if (response.status >= 300 && response.status < 400 && location !== null) {
      url = pageLink(new URL(location, url).href);
      continue;
    }
    if (!response.ok) return { failure: `http ${response.status}`, hops };
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.length > MAX_BYTES) return { failure: `${bytes.length} bytes`, hops };
    return { url, hops, bytes: bytes.length, html: new TextDecoder().decode(bytes) };
  }
  return { failure: 'too many redirects', hops };
}

async function askedTheModel(page) {
  const { draftFromPageRequest } = require('../lib/recipes/draft_recipe_prompt.js');
  const { draftFrom, draftReply } = require('../lib/recipes/draft_recipe_reply.js');
  const { ModelCallError } = require('../lib/ai/generative_model.js');
  const { VertexModel } = require('../lib/ai/vertex_model.js');
  const { applicationDefaultTokens } = require('../lib/ai/access_token.js');
  const model = new VertexModel({
    project: process.env.NESTPREP_PROJECT ?? 'nestprep-643b7',
    location: process.env.AI_LOCATION ?? 'europe-west4',
    model: process.env.AI_MODEL ?? 'gemini-2.5-flash',
    tokens: applicationDefaultTokens,
  });
  try {
    const reply = await model.generate(draftFromPageRequest(page), AbortSignal.timeout(25_000));
    const draft = draftFrom(draftReply.parse(JSON.parse(reply.text)));
    return {
      tokens: reply.usage,
      isRecipe: draft !== null,
      ingredients: draft?.ingredients.length ?? 0,
      steps: draft?.steps.length ?? 0,
      draft,
    };
  } catch (error) {
    if (error instanceof ModelCallError) {
      return { refused: error.kind, detail: error.detail, tokens: error.usage };
    }
    return { refused: 'unreadable', detail: error instanceof Error ? error.message : 'unknown' };
  }
}

const args = process.argv.slice(2);
const dry = args.includes('--dry');
const urls = args.filter((arg) => arg !== '--dry');
if (urls.length === 0) {
  console.error('usage: node tools/recipe-import-eval.mjs [--dry] <url> [<url> ...]');
  process.exit(2);
}

for (const url of urls) {
  console.log(`\n${url}`);
  let fetched;
  try {
    fetched = await fetchedHtml(url);
  } catch (error) {
    console.log(`  fetch failed: ${error instanceof Error ? error.name : 'unknown'}`);
    continue;
  }
  console.log(`  statuses: ${fetched.hops.join(' -> ')}`);
  if (fetched.html === undefined) {
    console.log(`  refused: ${fetched.failure}`);
    continue;
  }
  const page = extractedPage(fetched.url, fetched.html);
  const jsonLdChars = page.jsonLd.reduce((total, block) => total + block.length, 0);
  console.log(`  page: ${fetched.bytes} bytes, title ${JSON.stringify(page.title)}`);
  console.log(`  json-ld: ${page.jsonLd.length} block(s), ${jsonLdChars} chars`);
  console.log(`  text: ${page.text.length} chars`);
  console.log(`  images: ${page.imageUrls.length}`);
  if (dry) continue;
  const answer = await askedTheModel(page);
  console.log(`  tokens: ${JSON.stringify(answer.tokens ?? null)}`);
  if (answer.refused !== undefined) {
    console.log(`  refused: ${answer.refused} (${answer.detail})`);
    continue;
  }
  console.log(
    `  isRecipe: ${answer.isRecipe}, ${answer.ingredients} lines, ${answer.steps} steps, cutShort: ${answer.draft?.cutShort ?? false}`,
  );
  if (answer.draft !== null) console.log(`  ${JSON.stringify(answer.draft)}`);
}
