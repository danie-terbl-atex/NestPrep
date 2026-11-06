import type { HttpClient, HttpRequest } from '../shared/http_client';
import {
  WoolworthsRejected,
  WoolworthsSessionExpired,
  WoolworthsUnavailable,
  type WoolworthsCart,
  type WoolworthsCartLine,
  type WoolworthsProduct,
  type WoolworthsShop,
} from './woolworths_api';
import type { WoolworthsAppIdentity } from './woolworths_config';
import { dynUserIdOf } from './woolworths_id_token';
import {
  WFS_BASE,
  askWoolworths,
  readWoolworthsReply,
  type WoolworthsReply,
} from './woolworths_request';
import {
  cartOf,
  cartReply,
  isExpiredSession,
  productOf,
  productReply,
  wfsCodeOf,
} from './woolworths_wire';

export function wfsHeaders(app: WoolworthsAppIdentity, idToken: string): Record<string, string> {
  const dynUserId = dynUserIdOf(idToken);
  return {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    'Media-Type': 'application/json',
    Sessiontoken: idToken,
    Apiid: app.apiId,
    Sha1password: app.sha1Password,
    Appversion: app.appVersion,
    Os: app.os,
    Osversion: app.osVersion,
    Iscognito: 'true',
    Deviceversion: app.deviceVersion,
    Devicemodel: app.deviceModel,
    Network: 'Unavailable',
    'User-Agent': app.userAgent,
    ...(dynUserId === null ? {} : { Dyn_user_id: dynUserId }),
  };
}

function isSuccess(code: number): boolean {
  return code >= 200 && code < 300;
}

export class HttpWoolworthsShop implements WoolworthsShop {
  constructor(
    private readonly http: HttpClient,
    private readonly app: WoolworthsAppIdentity,
  ) {}

  async readCart(idToken: string): Promise<WoolworthsCart> {
    const reply = await this.ask(idToken, 'GET', `${WFS_BASE}/cartV2`);
    const code = wfsCodeOf(reply);
    if (!isSuccess(code)) throw new WoolworthsUnavailable(`cart ${String(code)}`);
    return cartOf(readWoolworthsReply(cartReply, reply));
  }

  async findProduct(idToken: string, sku: string): Promise<WoolworthsProduct | null> {
    const query = new URLSearchParams({ sku, deliveryType: 'OnDemand' });
    const reply = await this.ask(
      idToken,
      'GET',
      `${WFS_BASE}/productsV2/${encodeURIComponent(sku)}?${query.toString()}`,
    );
    const code = wfsCodeOf(reply);
    if (code === 400 || code === 404) return null;
    if (!isSuccess(code)) throw new WoolworthsUnavailable(`product ${String(code)}`);
    return productOf(sku, readWoolworthsReply(productReply, reply));
  }

  async addItems(idToken: string, lines: readonly WoolworthsCartLine[]): Promise<void> {
    const reply = await this.ask(
      idToken,
      'POST',
      `${WFS_BASE}/cart/OnDemand/itemV2`,
      lines.map(({ sku, quantity }) => ({
        catalogRefId: sku,
        productId: sku,
        quantity,
        substitutionSelection: 'SHOPPER_CHOICE',
      })),
    );
    const code = wfsCodeOf(reply);
    if (isSuccess(code)) return;
    if (code >= 400 && code < 500) throw new WoolworthsRejected(code);
    throw new WoolworthsUnavailable(`cart add ${String(code)}`);
  }

  private async ask(
    idToken: string,
    method: HttpRequest['method'],
    url: string,
    body?: unknown,
  ): Promise<WoolworthsReply> {
    const reply = await askWoolworths(this.http, url, {
      method,
      headers: wfsHeaders(this.app, idToken),
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    if (isExpiredSession(reply)) throw new WoolworthsSessionExpired();
    return reply;
  }
}
