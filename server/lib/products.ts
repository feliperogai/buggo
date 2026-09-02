// Catálogo de produtos do Google Play. Os ids têm que ser exatamente os
// mesmos criados no Play Console (Monetizar > Produtos), e o app lê os
// preços do próprio Play — não existe preço fixo no código, porque o Play
// mostra o valor já localizado e convertido.

export type ProductKind = 'product' | 'subscription';

export interface CatalogEntry {
  kind: ProductKind;
  /** Moedas creditadas na compra. Zero para a assinatura. */
  coins: number;
}

/** Pacotes de moedas — consumíveis, podem ser comprados várias vezes. */
export const COIN_PRODUCTS: Record<string, CatalogEntry> = {
  'coins_200': { kind: 'product', coins: 200 },
  'coins_450': { kind: 'product', coins: 450 },
  'coins_950': { kind: 'product', coins: 950 },
};

/** Buggo+ — assinatura mensal que dá vidas ilimitadas enquanto ativa. */
export const SUBSCRIPTION_ID = 'buggo_plus_monthly';

export const CATALOG: Record<string, CatalogEntry> = {
  ...COIN_PRODUCTS,
  [SUBSCRIPTION_ID]: { kind: 'subscription', coins: 0 },
};

export function lookupProduct(productId: string): CatalogEntry | undefined {
  return CATALOG[productId];
}
