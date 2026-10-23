/**
 * Answers shaped like Pick n Pay's own, cut down from the probes of
 * 2026-10-12 (the vault's PnP commerce API reference). No real client secret,
 * token or person is in here; ids are made up in the same shapes.
 */
export const CONFIG = {
  hybris: { baseStore: { uid: 'WC21' }, cdnUri: 'https://cdn-prd-02.pnp.co.za' },
  oidc: {
    authority: 'https://login.pnp.co.za/',
    authorizeEndpoint: 'https://login.pnp.co.za/authorize',
    clientId: 'storefront-test',
    clientSecret: 'not-a-real-secret',
    tokenEndpoint: 'https://login.pnp.co.za/token',
    scope: 'openid+offline_access',
  },
};

export const TOKENS = {
  access_token: 'eyJ.access.token',
  refresh_token: 'eyJ.refresh.token',
  id_token: 'eyJ.id.token',
  token_type: 'Bearer',
  expires_in: 3599,
};

export const CART = {
  type: 'cartWsDTO',
  code: '0379085864',
  baseStore: { uid: 'GC13' },
  cartSizeEnabled: {
    maximumDeliveryItemsQuantity: 45,
    maximumDeliveryItemsQuantityExceeded: false,
    warningDeliveryItemsExceeded: false,
  },
  entries: [
    {
      giveAwayIsRemovable: false,
      guid: '00ab85b1-1aae-4ef0-97d3-11c977d667c9',
      product: { code: '000000000000838685_EA' },
      quantity: 3,
    },
  ],
  totalItems: 3,
  totalPrice: { value: 65.97 },
  totalUnitCount: 3,
};

export const SAVED_CART = { ...CART, code: '0300000001', saveTime: '2026-09-01T10:00:00+0000' };

export const PRODUCT = {
  code: '000000000000838685_EA',
  name: 'Simba Potato Chips Mrs Balls Chutney 120g',
  price: {
    currencyIso: 'ZAR',
    formattedValue: 'R21.99',
    oldPrice: 0,
    priceType: 'BUY',
    value: 21.99,
  },
  quantityType: 'NORMAL',
  stock: { stockLevel: 25, stockLevelStatus: 'inStock' },
};

export const UNKNOWN_PRODUCT = {
  errors: [
    {
      message: "Product with code '999999999999999999_EA' not found!",
      type: 'UnknownIdentifierError',
    },
  ],
};
