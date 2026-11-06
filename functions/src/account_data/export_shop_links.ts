import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';

import { checkersLinkRef } from '../checkers/firestore_link_store';
import { pnpLinkRef } from '../pnp/firestore_pnp_link_store';
import { woolworthsLinkRef } from '../woolworths/firestore_woolworths_link_store';
import { type PlainValue, plainValue } from './plain_value';

type ShopLinkFields = Readonly<Record<string, string>>;

/**
 * What an export says of each shop link: only fields that are no secret.
 * A sealed session and a pending code's reference are never among them.
 */
export const SHOP_LINK_FIELDS = {
  checkers: {
    mobileMasked: 'session.mobileMasked',
    expiresAt: 'session.expiresAt',
    updatedAt: 'updatedAt',
  },
  pickNPay: {
    linkedAt: 'session.linkedAt',
    accessExpiresAt: 'session.accessExpiresAt',
  },
  woolworths: {
    emailMasked: 'session.emailMasked',
    linkedAt: 'session.linkedAt',
    idExpiresAt: 'session.idExpiresAt',
    updatedAt: 'updatedAt',
  },
} as const satisfies Record<string, ShopLinkFields>;

export type Shop = keyof typeof SHOP_LINK_FIELDS;

export async function exportShopLinks(store: Firestore, uid: string): Promise<PlainValue> {
  const [checkers, pickNPay, woolworths] = await store.getAll(
    checkersLinkRef(store, uid),
    pnpLinkRef(store, uid),
    woolworthsLinkRef(store, uid),
  );
  return shopLinksOf({ checkers, pickNPay, woolworths });
}

export function shopLinksOf(
  links: Readonly<Record<Shop, Pick<DocumentSnapshot, 'exists' | 'get'> | undefined>>,
): PlainValue {
  const shops = Object.keys(SHOP_LINK_FIELDS) as Shop[];
  return Object.fromEntries(
    shops.map((shop) => {
      const link = links[shop];
      if (link?.exists !== true) return [shop, null];
      const fields = Object.entries(SHOP_LINK_FIELDS[shop]).map(([name, path]) => [
        name,
        plainValue(link.get(path)),
      ]);
      return [shop, Object.fromEntries(fields) as PlainValue];
    }),
  );
}
