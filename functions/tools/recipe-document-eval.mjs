#!/usr/bin/env node
/**
 * How the PDF import reads a real document (recipes ADR-0009). Renders the pages the way the
 * phone does (pdftoppm: 768 px whole pages to list the recipes; 1024 px pages in overlapping
 * halves, plus the recipe's own pages whole, to draft one), asks the real prompts through
 * Vertex on your own gcloud sign-in, and writes each recipe and its cropped photo to <out>.
 * Writes nothing anywhere else. One call to list, two requests per drafted recipe.
 *
 *     npm run build
 *     node tools/recipe-document-eval.mjs <file.pdf> <out-dir> [<recipe name> ...]
 */
import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';

const require = createRequire(import.meta.url);
const run = promisify(execFile);
const { VertexModel } = require('../lib/ai/vertex_model.js');
const { developerGcloudTokens } = require('../lib/ai/access_token.js');
const { callForJson } = require('../lib/ai/structured_call.js');
const { scanRequest } = require('../lib/recipes/recipe_document_prompt.js');
const { foundRecipesFrom, scanReply } = require('../lib/recipes/recipe_document_reply.js');
const { draftWithPhoto } = require('../lib/recipes/draft_document_recipe.js');
const { draftFrom } = require('../lib/recipes/draft_recipe_reply.js');
const { SCAN_CALL_LIMITS } = require('../lib/recipes/scan_recipe_document.js');

const [pdf, out, ...wanted] = process.argv.slice(2);
if (pdf === undefined || out === undefined) {
  console.error('usage: node tools/recipe-document-eval.mjs <file.pdf> <out-dir> [<recipe> ...]');
  process.exit(2);
}

const model = new VertexModel({
  project: process.env.NESTPREP_PROJECT ?? 'nestprep-643b7',
  location: process.env.AI_LOCATION ?? 'europe-west4',
  model: process.env.AI_MODEL ?? 'gemini-2.5-flash',
  tokens: developerGcloudTokens,
});
const work = await mkdtemp(join(tmpdir(), 'recipe-document-'));

async function pageCount() {
  const { stdout } = await run('pdfinfo', [pdf]);
  return Number(/Pages:\s+(\d+)/.exec(stdout)?.[1] ?? 0);
}

async function render(page, longEdge, crop) {
  const name = join(work, `p${String(page)}-${String(longEdge)}-${crop?.name ?? 'whole'}`);
  const area =
    crop === undefined
      ? []
      : [
          '-x',
          String(crop.x ?? 0),
          '-y',
          String(crop.y),
          '-W',
          String(crop.w ?? 99999),
          '-H',
          String(crop.h),
        ];
  await run('pdftoppm', [
    '-jpeg',
    '-jpegopt',
    'quality=78',
    '-scale-to',
    String(longEdge),
    '-f',
    String(page),
    '-l',
    String(page),
    '-singlefile',
    ...area,
    pdf,
    name,
  ]);
  return readFile(`${name}.jpg`);
}

async function heightAt(page, longEdge) {
  const { stdout } = await run('pdfinfo', ['-f', String(page), '-l', String(page), pdf]);
  const [, width, height] = /Page\s+\d+ size:\s+([\d.]+) x ([\d.]+)/.exec(stdout) ?? [];
  return Math.round((longEdge * Number(height)) / Math.max(Number(width), Number(height)));
}

async function halves(page) {
  const height = await heightAt(page, 1024);
  const half = Math.round(height * 0.55);
  const [top, bottom] = await Promise.all([
    render(page, 1024, { name: 'top', y: 0, h: half }),
    render(page, 1024, { name: 'bottom', y: height - half, h: half }),
  ]);
  return { top: top.toString('base64'), bottom: bottom.toString('base64') };
}

async function widthAt(page, longEdge) {
  const { stdout } = await run('pdfinfo', ['-f', String(page), '-l', String(page), pdf]);
  const [, width, height] = /Page\s+\d+ size:\s+([\d.]+) x ([\d.]+)/.exec(stdout) ?? [];
  return Math.round((longEdge * Number(width)) / Math.max(Number(width), Number(height)));
}

async function cropPhoto(page, box, file) {
  const longEdge = 2000;
  const [height, width] = await Promise.all([heightAt(page, longEdge), widthAt(page, longEdge)]);
  const [top, left, bottom, right] = box;
  const photo = await render(page, longEdge, {
    name: 'photo',
    x: Math.round((left / 1000) * width),
    y: Math.round((top / 1000) * height),
    w: Math.round(((right - left) / 1000) * width),
    h: Math.round(((bottom - top) / 1000) * height),
  });
  await writeFile(file, photo);
}

try {
  await mkdir(out, { recursive: true });
  const count = await pageCount();
  if (count > 50) throw new Error(`${String(count)} pages; the import takes 50`);
  const numbers = Array.from({ length: count }, (_, at) => at + 1);
  const pages = await Promise.all(
    numbers.map(async (number) => ({
      number,
      data: (await render(number, 768)).toString('base64'),
    })),
  );
  const scanned = await callForJson(model, scanRequest(pages), scanReply, SCAN_CALL_LIMITS);
  const found = foundRecipesFrom(scanned.value, new Set(numbers));
  console.log(`listed ${String(found.length)} recipes, tokens ${JSON.stringify(scanned.usage)}`);
  for (const recipe of found) {
    console.log(
      `  ${recipe.name}: pages ${recipe.pages.join(',')} uses ${recipe.usesPages.join(',') || '-'}`,
    );
  }
  const chosen = wanted.length === 0 ? found : found.filter(({ name }) => wanted.includes(name));
  for (const recipe of chosen) {
    const readPages = await Promise.all(
      [...recipe.usesPages, ...recipe.pages].map(async (number) => ({
        number,
        ...(await halves(number)),
        whole: recipe.pages.includes(number)
          ? (await render(number, 1024)).toString('base64')
          : null,
      })),
    );
    const drafted = await draftWithPhoto(model, recipe.name, readPages);
    const draft = draftFrom(drafted.value.reply);
    const slug = recipe.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    await writeFile(
      join(out, `${slug}.json`),
      JSON.stringify({ draft, photo: drafted.value.photo }, null, 1),
    );
    if (drafted.value.photo !== null) {
      await cropPhoto(drafted.value.photo.page, drafted.value.photo.box, join(out, `${slug}.jpg`));
    }
    console.log(
      `drafted ${recipe.name}: ${String(draft?.ingredients.length ?? 0)} lines, ` +
        `${String(draft?.steps.length ?? 0)} steps, photo ${JSON.stringify(drafted.value.photo)}, ` +
        `tokens ${JSON.stringify(drafted.usage)}`,
    );
  }
  console.log(`written to ${out}: ${(await readdir(out)).join(', ')}`);
} finally {
  await rm(work, { recursive: true, force: true });
}
