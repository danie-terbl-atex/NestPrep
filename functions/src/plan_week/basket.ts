/**
 * What the week's lunches cost at the till, for every child together
 * (lunch-box ADR-0012 §4): each product's boxes across the household, in whole
 * packs, at the pack's price. The app's `LunchBasket` does the same sum and is
 * what a parent sees; here it only tells the logs whether a plan went over.
 */
export interface BasketPack {
  readonly productId: string;
  readonly boxesPerPack: number;
  readonly priceCents: number;
}

export interface BasketLine {
  readonly productId: string;
  readonly boxes: number;
  readonly packs: number;
  readonly cents: number;
}

export function basketLines(
  lunches: readonly { readonly productId: string }[],
  packs: readonly BasketPack[],
): BasketLine[] {
  const boxes: Record<string, number> = {};
  for (const lunch of lunches) boxes[lunch.productId] = (boxes[lunch.productId] ?? 0) + 1;
  return packs.flatMap((pack) => {
    const count = boxes[pack.productId] ?? 0;
    if (count === 0) return [];
    const whole = Math.ceil(count / Math.max(1, pack.boxesPerPack));
    return [
      { productId: pack.productId, boxes: count, packs: whole, cents: whole * pack.priceCents },
    ];
  });
}

export function basketCents(lines: readonly BasketLine[]): number {
  return lines.reduce((sum, line) => sum + line.cents, 0);
}
