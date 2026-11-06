import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { assembleFrameDay, type FrameDaySources } from '../../../src/frames/frame_day';
import { frameDocument } from '../../../src/frames/frame_documents';
import { refuseFrame } from '../../../src/frames/frame_errors';
import {
  frameGroceryId,
  frameGroceryItemDocument,
  frameProductMatch,
  frameProductsInOrder,
  groceriesEditors,
  groceriesPanel,
  groceryAdderNamed,
  sameItemOnList,
  searchableProducts,
} from '../../../src/frames/frame_groceries';
import {
  FRAME_ADD_GROCERY_PER_CREDENTIAL,
  FRAME_SEARCH_PRODUCTS_PER_CREDENTIAL,
} from '../../../src/frames/frame_policy';
import {
  type AddFrameGroceryItemInput,
  addFrameGroceryItemInput,
  searchFrameProductsInput,
} from '../../../src/frames/frame_schemas';
import type { FrameShopProduct } from '../../../src/frames/frame_shop_catalogue';
import { ROLE_DEFAULTS, uniformGrant } from '../../../src/household/access';
import { parseInput } from '../../../src/household/parse_input';
import type { MemberRecord, StoredHousehold } from '../../../src/notifications/recipients';

/** Groceries added at the wall (photo-frames ADR-0012). */

const SECRET = 'a'.repeat(43);
const CHECKERS_PICK = {
  retailer: 'checkers',
  productId: '5f1b2c3d4e5f60718293a4b5',
  articleCode: '10136729EA',
  unitOfMeasure: 'EA',
  name: 'Clover Full Cream Milk 2L',
  brand: 'Clover',
  priceCents: 3499,
  imageId: '62a1f0',
};
const PNP_PICK = {
  retailer: 'pickNPay',
  productId: '000000000000838685_EA',
  articleCode: '000000000000838685',
  unitOfMeasure: 'EA',
  name: 'PnP Full Cream Milk 2L',
  brand: null,
  priceCents: 2999,
  imageId: 'medias/838685.jpg',
};
const WOOLWORTHS_PICK = {
  retailer: 'woolworths',
  productId: '6009178001234',
  articleCode: '6009178001234',
  unitOfMeasure: 'EA',
  name: 'Woolworths Full Cream Milk 2L',
  brand: 'Woolworths',
  priceCents: 3699,
  imageId:
    'Full-Cream-Milk-2L-6009178001234.jpg?V=kd3s&o=eyJidWNrZXQiOiJ3dy1vbmxpbmUtaW1hZ2VzLXByb2QifQ==&',
};

function reasonOf(run: () => unknown): unknown {
  try {
    run();
  } catch (error) {
    return error instanceof HttpsError ? (error.details as { reason?: unknown }).reason : error;
  }
  return undefined;
}

function input(more: Record<string, unknown> = {}): AddFrameGroceryItemInput {
  return parseInput(addFrameGroceryItemInput, { secret: SECRET, name: 'Milk', by: 'Sam', ...more });
}

describe('what a frame may send to add', () => {
  it('a name and who is adding it; no quantity, product or request id is none', () => {
    expect(input({ name: '  Milk ', by: ' Sam ', quantity: '  ' })).toEqual({
      secret: SECRET,
      name: 'Milk',
      by: 'Sam',
      quantity: null,
      product: null,
      requestId: null,
    });
    expect(input({ quantity: ' 2 L ' }).quantity).toBe('2 L');
  });

  it('a product from any connected shop, in the shape a pick is stored', () => {
    expect(input({ product: CHECKERS_PICK }).product).toEqual(CHECKERS_PICK);
    expect(input({ product: PNP_PICK }).product).toEqual(PNP_PICK);
    expect(input({ product: WOOLWORTHS_PICK }).product).toEqual(WOOLWORTHS_PICK);
    expect(
      input({ product: { ...WOOLWORTHS_PICK, unitOfMeasure: 'KG', imageId: undefined } }).product,
    ).toEqual({ ...WOOLWORTHS_PICK, unitOfMeasure: 'KG', imageId: null });
    expect(input({ product: { ...CHECKERS_PICK, brand: '', imageId: null } }).product).toEqual({
      ...CHECKERS_PICK,
      brand: null,
      imageId: null,
    });
  });

  it.each([
    ['no name', { name: '  ' }],
    ['a name past 80', { name: 'x'.repeat(81) }],
    ['a quantity past 40', { quantity: 'x'.repeat(41) }],
    ['nobody adding it', { by: ' ' }],
    ['a request id too short', { requestId: 'abc1234' }],
    ['a Checkers id that is not one', { product: { ...CHECKERS_PICK, productId: 'abc' } }],
    ['a PnP code at Checkers', { product: { ...CHECKERS_PICK, productId: PNP_PICK.productId } }],
    ['a PnP code without its unit', { product: { ...PNP_PICK, productId: '000000838685' } }],
    ['a shop nobody connected', { product: { ...CHECKERS_PICK, retailer: 'spar' } }],
    ['a Checkers id at Woolworths', { product: { ...WOOLWORTHS_PICK, retailer: 'checkers' } }],
    ['a Woolworths SKU too short', { product: { ...WOOLWORTHS_PICK, productId: '12345' } }],
    [
      'a Woolworths article code that is not its SKU',
      { product: { ...WOOLWORTHS_PICK, articleCode: '6009178009999' } },
    ],
    [
      'a Woolworths unit it never sells by',
      { product: { ...WOOLWORTHS_PICK, unitOfMeasure: 'KGM' } },
    ],
    [
      'a Woolworths picture on another path',
      { product: { ...WOOLWORTHS_PICK, imageId: 'images/../x.jpg' } },
    ],
    [
      'a Woolworths picture with a space',
      { product: { ...WOOLWORTHS_PICK, imageId: 'milk 2l.jpg' } },
    ],
    [
      'a Woolworths picture past 600',
      { product: { ...WOOLWORTHS_PICK, imageId: 'x'.repeat(601) } },
    ],
    ['a lowercase unit', { product: { ...CHECKERS_PICK, unitOfMeasure: 'ea' } }],
    ['a price in rand', { product: { ...CHECKERS_PICK, priceCents: 34.99 } }],
    ['a negative price', { product: { ...CHECKERS_PICK, priceCents: -1 } }],
    ['a product with no name', { product: { ...CHECKERS_PICK, name: ' ' } }],
    ['a brand past 100', { product: { ...CHECKERS_PICK, brand: 'x'.repeat(101) } }],
  ])('and refuses %s', (_, more) => {
    expect(reasonOf(() => input(more))).toBe('badRequest');
  });

  it('a search of two to eighty characters', () => {
    expect(parseInput(searchFrameProductsInput, { secret: SECRET, query: ' mi ' }).query).toBe(
      'mi',
    );
    for (const query of ['m', ' m ', 'x'.repeat(81)]) {
      expect(reasonOf(() => parseInput(searchFrameProductsInput, { secret: SECRET, query }))).toBe(
        'badRequest',
      );
    }
  });
});

describe('the switch on the frame document', () => {
  const frame = { name: 'Kitchen', panels: {} };

  it('is a shop and an area', () => {
    expect(
      frameDocument.parse({ ...frame, groceries: { shop: 'pickNPay', area: 'durban' } }).groceries,
    ).toEqual({ shop: 'pickNPay', area: 'durban' });
  });

  it('and at Woolworths the store and price list the phone found', () => {
    const groceries = { shop: 'woolworths', area: 'capeTown', store: '2008', priceZone: 'p60' };
    expect(frameDocument.parse({ ...frame, groceries }).groceries).toEqual(groceries);
  });

  it('is off when missing or broken, and never unlinks the frame', () => {
    for (const groceries of [
      undefined,
      null,
      {},
      { shop: 'spar', area: 'capeTown' },
      { shop: 'woolworths', area: 'capeTown' },
      { shop: 'woolworths', area: 'capeTown', store: '2008' },
      { shop: 'woolworths', area: 'capeTown', store: '20a8', priceZone: 'p30' },
      { shop: 'woolworths', area: 'capeTown', store: '2008', priceZone: 'p20' },
      { shop: 'woolworths', area: 'london', store: '2008', priceZone: 'p30' },
      { shop: 'checkers', area: 'london' },
      { shop: 'checkers' },
      'checkers',
    ]) {
      expect(frameDocument.parse({ ...frame, groceries }).groceries).toBeNull();
    }
  });

  it('searches 300 an hour and adds 60 an hour per frame', () => {
    expect(FRAME_SEARCH_PRODUCTS_PER_CREDENTIAL).toEqual({
      name: 'searchFrameProducts:credential',
      limit: 300,
      windowSeconds: 3600,
    });
    expect(FRAME_ADD_GROCERY_PER_CREDENTIAL).toEqual({
      name: 'addFrameGroceryItem:credential',
      limit: 60,
      windowSeconds: 3600,
    });
  });

  it('refuses with its own reasons', () => {
    expect(refuseFrame('groceriesOff').code).toBe('failed-precondition');
    expect(refuseFrame('notAllowedToAddGroceries').code).toBe('permission-denied');
    expect(refuseFrame('shopUnavailable').code).toBe('unavailable');
    expect(refuseFrame('shopUnavailable').details).toEqual({ reason: 'shopUnavailable' });
  });
});

const HOUSEHOLD: StoredHousehold = {
  timeZone: 'Africa/Johannesburg',
  members: {
    'uid-sam': 'admin',
    'uid-pat': 'parent',
    'uid-thandi': 'helper',
    'uid-nomsa': 'carer',
    'uid-zola': 'helper',
  },
  access: {
    'uid-thandi': ROLE_DEFAULTS.helper,
    'uid-nomsa': ROLE_DEFAULTS.carer,
    'uid-zola': uniformGrant('edit'),
  },
  kids: { 'tablet-mia': 'm-mia', 'tablet-leo': 'm-leo' },
  shiftOnly: { 'm-zola': true },
};

function member(
  id: string,
  displayName: string,
  role: string,
  claimedBy: string | null,
): MemberRecord {
  return { id, displayName, role, claimedBy };
}

const MEMBERS: MemberRecord[] = [
  member('m-sam', 'Sam Parker', 'admin', 'uid-sam'),
  member('m-pat', 'Pat', 'parent', 'uid-pat'),
  member('m-thandi', 'Thandi', 'helper', 'uid-thandi'),
  member('m-nomsa', 'Nomsa', 'carer', 'uid-nomsa'),
  member('m-zola', 'Zola', 'helper', 'uid-zola'),
  { ...member('m-mia', 'Mia', 'kid', null), access: { ...ROLE_DEFAULTS.kid, groceries: 'edit' } },
  { ...member('m-leo', 'Leo', 'kid', null), access: ROLE_DEFAULTS.kid },
  member('m-gran', 'Gran', 'parent', null),
];

const NAMES = Object.fromEntries(MEMBERS.map((each) => [each.id, each.displayName]));

describe('who may add to the list', () => {
  it('whoever the rules let edit groceries, and nobody who cannot sign in as themselves', () => {
    expect(groceriesEditors(HOUSEHOLD, MEMBERS)).toEqual(['m-sam', 'm-pat', 'm-thandi', 'm-mia']);
  });

  it('is the one of them with that first name, in any case', () => {
    const editors = groceriesEditors(HOUSEHOLD, MEMBERS);
    expect(groceryAdderNamed(editors, NAMES, ' sam ')).toBe('m-sam');
    expect(groceryAdderNamed(editors, NAMES, 'THANDI')).toBe('m-thandi');
  });

  it('and refuses somebody who may not, or nobody at all', () => {
    const editors = groceriesEditors(HOUSEHOLD, MEMBERS);
    for (const by of ['Nomsa', 'Zola', 'Leo', 'Gran', 'Nobody']) {
      expect(reasonOf(() => groceryAdderNamed(editors, NAMES, by))).toBe(
        'notAllowedToAddGroceries',
      );
    }
  });

  it('and asks who when two of them share the name', () => {
    const names = { ...NAMES, 'm-pat': 'Sam Jones' };
    expect(reasonOf(() => groceryAdderNamed(['m-sam', 'm-pat'], names, 'Sam'))).toBe('whoNeeded');
  });
});

describe('what an add writes', () => {
  it('exactly the typed item the app writes, credited to who is adding it', () => {
    expect(frameGroceryItemDocument(input({ quantity: '2 L' }), 'm-sam')).toEqual({
      name: 'Milk',
      quantity: '2 L',
      addedBy: 'm-sam',
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    });
  });

  it('a pick in the shape the grocery rules hold it to, picked by the same person', () => {
    const pick = input({ product: CHECKERS_PICK }).product;
    expect(pick).not.toBeNull();
    if (pick === null) return;
    expect(frameProductMatch(pick, 'm-sam')).toEqual({
      ...CHECKERS_PICK,
      currency: 'ZAR',
      pickedBy: 'm-sam',
    });
  });

  it('one id per frame and request', () => {
    expect(frameGroceryId('frame1', 'sheet_0001-AB')).toBe('frame-frame1-sheet_0001-AB');
  });

  it('is already on the list by the normalised name, or the key it was planned under', () => {
    const unbought = [
      { id: 'i1', name: 'Brown  Bread' },
      { id: 'i2', name: 'Apples for lunch', sourceKey: 'apples' },
    ];
    expect(sameItemOnList(' brown bread ', unbought)).toBe('i1');
    expect(sameItemOnList('Apples', unbought)).toBe('i2');
    expect(sameItemOnList('Milk', unbought)).toBeNull();
  });
});

function product(index: number, more: Partial<FrameShopProduct> = {}): FrameShopProduct {
  return {
    retailer: 'checkers',
    productId: String(index).padStart(24, 'a'),
    articleCode: `${String(index)}EA`,
    unitOfMeasure: 'EA',
    name: `Milk ${String(index)}`,
    brand: null,
    priceCents: 1000 + index,
    imageId: index === 0 ? 'img0' : null,
    isSoldByWeight: false,
    ...more,
  };
}

describe('what a search answers', () => {
  it('never a product sold by weight, and each product once', () => {
    const found = [product(0), product(1, { isSoldByWeight: true }), product(0), product(2)];
    expect(searchableProducts(found, 8).map((each) => each.productId)).toEqual([
      product(0).productId,
      product(2).productId,
    ]);
    expect(searchableProducts([product(0), product(2), product(3)], 2)).toHaveLength(2);
  });

  it('in Jev’s order, at most five, the first the best match only when Jev is sure', () => {
    const products = [0, 1, 2, 3, 4, 5, 6].map((index) => product(index));
    const ranking = [6, 0, 1, 2, 3, 4, 5].map((index) => ({
      productId: product(index).productId,
      fit: index === 6 ? 0.9 : 0.1,
    }));
    const answer = frameProductsInOrder(products, ranking);
    expect(answer.map((each) => each.name)).toEqual([
      'Milk 6',
      'Milk 0',
      'Milk 1',
      'Milk 2',
      'Milk 3',
    ]);
    expect(answer.map((each) => each.bestMatch)).toEqual([true, false, false, false, false]);
    expect(
      frameProductsInOrder(products, [{ productId: product(1).productId, fit: 0.59 }])[0]
        ?.bestMatch,
    ).toBe(false);
  });

  it('in the shop’s order with no best match when ranking failed', () => {
    const answer = frameProductsInOrder([product(0), product(1)], null);
    expect(answer.map((each) => each.name)).toEqual(['Milk 0', 'Milk 1']);
    expect(answer.some((each) => each.bestMatch)).toBe(false);
  });

  it('with everything a pick needs and the picture ready to fetch', () => {
    expect(frameProductsInOrder([product(0)], null)[0]).toEqual({
      retailer: 'checkers',
      productId: product(0).productId,
      articleCode: '0EA',
      unitOfMeasure: 'EA',
      name: 'Milk 0',
      brand: null,
      priceCents: 1000,
      imageId: 'img0',
      imageUrl: 'https://catalog.sixty60.co.za/v2/files/img0?width=300&height=300',
      bestMatch: false,
    });
  });
});

describe('the day', () => {
  const sources = (more: Partial<FrameDaySources>): FrameDaySources => ({
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: {
      calendar: false,
      todos: false,
      meals: false,
      lunch: false,
      addEvents: false,
      share: false,
      people: false,
      helperMemberId: null,
    },
    screensaver: null,
    today: '2026-11-03',
    localMinute: 9 * 60,
    names: NAMES,
    colors: {},
    ...more,
  });

  it('has no groceries while the frame does not add them', () => {
    expect(assembleFrameDay(sources({}))).not.toHaveProperty('groceries');
  });

  it('carries the shop, who may add by first name, and what is still to buy, newest first', () => {
    const day = assembleFrameDay(
      sources({
        groceries: {
          shop: 'pickNPay',
          editors: ['m-thandi', 'm-sam', 'm-gone'],
          items: [
            {
              id: 'i3',
              name: 'Milk',
              quantity: ' 2 L ',
              boughtBy: null,
              productMatch: {
                retailer: 'pickNPay',
                name: 'PnP Milk 2L',
                brand: 'PnP',
                imageId: 'medias/milk.jpg',
              },
            },
            { id: 'i2', name: 'Bread', quantity: null, boughtBy: 'm-sam', productMatch: null },
            {
              id: 'i1',
              name: 'Eggs',
              quantity: '',
              productMatch: { retailer: 'checkers', name: 'Eggs 6', brand: null, imageId: null },
            },
          ],
        },
      }),
    );
    expect(day.groceries).toEqual({
      shop: 'pickNPay',
      by: ['Sam', 'Thandi'],
      toBuy: [
        {
          id: 'i3',
          name: 'Milk',
          quantity: '2 L',
          product: {
            name: 'PnP Milk 2L',
            brand: 'PnP',
            imageUrl: 'https://cdn-prd-02.pnp.co.za/medias/milk.jpg',
          },
        },
        { id: 'i1', name: 'Eggs', product: { name: 'Eggs 6' } },
      ],
    });
  });

  it('says nothing about who added an item or what it cost', () => {
    expect(groceriesPanel({ shop: 'checkers', editors: [], items: [] }, NAMES)).toEqual({
      shop: 'checkers',
      by: [],
      toBuy: [],
    });
  });
});
