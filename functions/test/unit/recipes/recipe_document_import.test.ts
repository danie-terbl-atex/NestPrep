import { describe, expect, it } from 'vitest';

import {
  ModelCallError,
  type GenerativeModel,
  type ModelReply,
  type ModelRequest,
} from '../../../src/ai/generative_model';
import { vertexBody } from '../../../src/ai/vertex_model';
import {
  draftWithPhoto,
  type DocumentDraftLimits,
} from '../../../src/recipes/draft_document_recipe';
import { DRAFT_SYSTEM } from '../../../src/recipes/draft_recipe_prompt';
import {
  DOCUMENT_DRAFT_SYSTEM,
  documentDraftRequest,
  photoBoxRequest,
  scanRequest,
} from '../../../src/recipes/recipe_document_prompt';
import {
  MAX_FOUND_RECIPES,
  foundRecipesFrom,
  photoBoxOf,
} from '../../../src/recipes/recipe_document_reply';
import {
  MAX_RECIPE_PAGES,
  checkedPageImage,
  draftDocumentRecipeInput,
  scanRecipeDocumentInput,
  type ReadPage,
} from '../../../src/recipes/recipe_document_schemas';

const JPEG = '/9j/4AAQ';
const sent = new Set([1, 2, 3, 9, 10, 11, 12, 13, 28, 29]);
const quick: DocumentDraftLimits = {
  draft: { attempts: 1, perAttemptMs: 1_000, budgetMs: 1_000, backoffMs: [] },
  box: { attempts: 1, perAttemptMs: 1_000, budgetMs: 1_000, backoffMs: [] },
};

const readPage = (number: number, whole: string | null = null): ReadPage => ({
  number,
  top: JPEG,
  bottom: JPEG,
  whole,
});

const recipeReply = (photo: unknown): string =>
  JSON.stringify({
    isRecipe: true,
    name: 'Focaccia',
    ingredients: [{ name: 'Flour', quantity: 400, unit: 'g', group: 'Base dough' }],
    steps: ['Mix it.', 'Bake it.'],
    photo,
  });

function modelAnswering(
  answer: (request: ModelRequest) => string | ModelCallError,
): GenerativeModel & { asked: ModelRequest[] } {
  const asked: ModelRequest[] = [];
  return {
    name: 'fake',
    asked,
    generate(request): Promise<ModelReply> {
      asked.push(request);
      const reply = answer(request);
      if (reply instanceof ModelCallError) return Promise.reject(reply);
      return Promise.resolve({
        text: reply,
        usage: { inputTokens: 100, outputTokens: 10 },
        modelVersion: 'fake-1',
      });
    },
  };
}

describe('what a document scan accepts', () => {
  const body = (pages: unknown): unknown => ({ householdId: 'h1', documentName: 'Book', pages });

  it('takes one to fifty pages, each once', () => {
    const pages = (count: number): unknown[] =>
      Array.from({ length: count }, (_, at) => ({ number: at + 1, data: JPEG }));
    expect(scanRecipeDocumentInput.safeParse(body(pages(50))).success).toBe(true);
    expect(scanRecipeDocumentInput.safeParse(body(pages(0))).success).toBe(false);
    expect(scanRecipeDocumentInput.safeParse(body([...pages(1), ...pages(1)])).success).toBe(false);
    expect(scanRecipeDocumentInput.safeParse(body([{ number: 51, data: JPEG }])).success).toBe(
      false,
    );
  });

  it('refuses a page picture past 400 KB', () => {
    const big = 'A'.repeat(Math.ceil((400 * 1024) / 3) * 4 + 4);
    expect(scanRecipeDocumentInput.safeParse(body([{ number: 1, data: big }])).success).toBe(false);
  });
});

describe('what a document draft accepts', () => {
  const body = (pages: ReadPage[]): unknown => ({
    householdId: 'h1',
    documentName: 'Book',
    recipeName: 'Focaccia',
    pages,
  });

  it('takes at most twelve pages and eight photo choices', () => {
    const pages = (count: number, wholes: number): ReadPage[] =>
      Array.from({ length: count }, (_, at) => readPage(at + 1, at < wholes ? JPEG : null));
    expect(draftDocumentRecipeInput.safeParse(body(pages(MAX_RECIPE_PAGES, 8))).success).toBe(true);
    expect(draftDocumentRecipeInput.safeParse(body(pages(MAX_RECIPE_PAGES + 1, 0))).success).toBe(
      false,
    );
    expect(draftDocumentRecipeInput.safeParse(body(pages(9, 9))).success).toBe(false);
  });
});

describe('a page picture', () => {
  it('is a JPEG, or refused before a token is spent', () => {
    expect(checkedPageImage(JPEG)).toBe(JPEG);
    expect(() => checkedPageImage('iVBORw0KGgo=')).toThrow('could not be read');
    expect(() => checkedPageImage('not base64!')).toThrow('could not be read');
  });
});

describe('what the model is sent', () => {
  it('names each page in order, and lists recipes under recipeDocument', () => {
    const request = scanRequest([
      { number: 1, data: JPEG },
      { number: 2, data: JPEG },
    ]);
    expect(request.parts.map((part) => (part.kind === 'text' ? part.text : 'image'))).toEqual([
      'Page 1:',
      'image',
      'Page 2:',
      'image',
    ]);
    expect(request.labels).toEqual({ feature: 'recipeDocument' });
  });

  it('reads a recipe from halves, with its own pages whole as photo choices', () => {
    const request = documentDraftRequest('Focaccia', [readPage(9), readPage(28, JPEG)]);
    const labels = request.parts.flatMap((part) => (part.kind === 'text' ? [part.text] : []));
    expect(labels).toEqual([
      'The recipe to read: Focaccia',
      'Page 9, top half:',
      'Page 9, bottom half:',
      'Page 28, top half:',
      'Page 28, bottom half:',
      'Photo choice: the whole of page 28:',
    ]);
    expect(request.mediaResolution).toBeUndefined();
    expect(request.labels).toEqual({ feature: 'recipeImport' });
  });

  it('keeps every rule of a link or a snap, and folds in a base it builds on', () => {
    expect(DOCUMENT_DRAFT_SYSTEM).toContain('Never say what allergens');
    expect(DOCUMENT_DRAFT_SYSTEM).toContain('use the');
    expect(DOCUMENT_DRAFT_SYSTEM).toContain('changed amount');
    expect(DRAFT_SYSTEM).not.toContain('photo choices');
  });

  it('asks for the box alone at high resolution, which Vertex allows for one image only', () => {
    const request = photoBoxRequest('Focaccia', JPEG);
    expect(request.parts.filter((part) => part.kind === 'inline')).toHaveLength(1);
    expect(vertexBody(request)['generationConfig']).toMatchObject({
      mediaResolution: 'MEDIA_RESOLUTION_HIGH',
    });
    expect(
      vertexBody(scanRequest([{ number: 1, data: JPEG }]))['generationConfig'],
    ).not.toHaveProperty('mediaResolution');
  });
});

describe('the recipes a scan found', () => {
  it('keeps only pages that were sent, each once and in order, own pages first', () => {
    const found = foundRecipesFrom(
      {
        recipes: [
          {
            name: ' Focaccia ',
            summary: 'Bread.',
            pages: [29, 28, 28, 99],
            usesPages: [13, 9, 28],
          },
        ],
      },
      sent,
    );
    expect(found).toEqual([
      { name: 'Focaccia', summary: 'Bread.', pages: [28, 29], usesPages: [9, 13] },
    ]);
  });

  it('drops a recipe with no name or none of its own pages', () => {
    expect(
      foundRecipesFrom(
        {
          recipes: [
            { name: '', pages: [1] },
            { name: 'Ghost', pages: [77] },
            { name: 'Real', pages: [1] },
          ],
        },
        sent,
      ).map(({ name }) => name),
    ).toEqual(['Real']);
  });

  it('holds a recipe to twelve pages, its own before what it builds on', () => {
    const all = new Set(Array.from({ length: 50 }, (_, at) => at + 1));
    const own = Array.from({ length: 10 }, (_, at) => at + 20);
    const [found] = foundRecipesFrom(
      { recipes: [{ name: 'Long', pages: own, usesPages: [1, 2, 3, 4] }] },
      all,
    );
    expect(found?.pages).toEqual(own);
    expect(found?.usesPages).toEqual([1, 2]);
  });

  it('lists at most forty', () => {
    const recipes = Array.from({ length: 45 }, (_, at) => ({ name: `R${String(at)}`, pages: [1] }));
    expect(foundRecipesFrom({ recipes }, sent)).toHaveLength(MAX_FOUND_RECIPES);
  });
});

describe('a photo box', () => {
  it('is four edges on 0–1000 with room in it', () => {
    expect(photoBoxOf([560, 50, 888, 491])).toEqual([560, 50, 888, 491]);
    expect(photoBoxOf([-5, 0, 1200, 1000])).toEqual([0, 0, 1000, 1000]);
    expect(photoBoxOf([500, 500, 400, 600])).toBeNull();
    expect(photoBoxOf([500, 500, 510, 510])).toBeNull();
    expect(photoBoxOf([1, 2, 3])).toBeNull();
    expect(photoBoxOf(null)).toBeNull();
  });
});

describe('drafting a document recipe', () => {
  const pages = [readPage(9), readPage(28, JPEG), readPage(31, JPEG)];

  it('tightens the chosen photo with a second request, and bills both', async () => {
    const model = modelAnswering((request) =>
      request.mediaResolution === 'high'
        ? JSON.stringify({ box: [600, 40, 880, 480] })
        : recipeReply({ page: 31, box: [500, 0, 1000, 600] }),
    );
    const drafted = await draftWithPhoto(model, 'Focaccia', pages, quick);
    expect(drafted.value.photo).toEqual({ page: 31, box: [600, 40, 880, 480] });
    expect(drafted.usage).toEqual({ inputTokens: 200, outputTokens: 20 });
    expect(model.asked).toHaveLength(2);
  });

  it('keeps the looser box when the second request fails', async () => {
    const model = modelAnswering((request) =>
      request.mediaResolution === 'high'
        ? new ModelCallError('blocked', 'no')
        : recipeReply({ page: 31, box: [500, 0, 1000, 600] }),
    );
    const drafted = await draftWithPhoto(model, 'Focaccia', pages, quick);
    expect(drafted.value.photo).toEqual({ page: 31, box: [500, 0, 1000, 600] });
    expect(drafted.value.reply.name).toBe('Focaccia');
  });

  it('asks nothing more when the photo is on a page that was not a photo choice', async () => {
    const model = modelAnswering(() => recipeReply({ page: 9, box: [500, 0, 1000, 600] }));
    const drafted = await draftWithPhoto(model, 'Focaccia', pages, quick);
    expect(drafted.value.photo).toBeNull();
    expect(model.asked).toHaveLength(1);
  });

  it('has no photo when there is none', async () => {
    const model = modelAnswering(() => recipeReply(null));
    expect((await draftWithPhoto(model, 'Focaccia', pages, quick)).value.photo).toBeNull();
  });
});
