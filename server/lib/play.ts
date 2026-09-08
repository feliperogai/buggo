import { JWT } from 'google-auth-library';

// Cliente mínimo da Google Play Developer API. Só os dois endpoints que
// interessam — validar um produto consumível e validar uma assinatura.
// Evita a dependência `googleapis` inteira, que é grande demais para uma
// função serverless.

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const BASE = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

function requirePackageName(): string {
  const name = process.env.ANDROID_PACKAGE_NAME;
  if (!name) throw new Error('ANDROID_PACKAGE_NAME is not set');
  return name;
}

let cachedClient: JWT | null = null;

function getClient(): JWT {
  if (cachedClient) return cachedClient;
  const raw = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('PLAY_SERVICE_ACCOUNT_JSON is not set');

  let credentials: { client_email?: string; private_key?: string };
  try {
    credentials = JSON.parse(raw);
  } catch {
    throw new Error('PLAY_SERVICE_ACCOUNT_JSON is not valid JSON');
  }
  if (!credentials.client_email || !credentials.private_key) {
    throw new Error('PLAY_SERVICE_ACCOUNT_JSON sem client_email/private_key');
  }

  cachedClient = new JWT({
    email: credentials.client_email,
    // O PEM precisa de quebras de linha reais. Quando a chave chega com as
    // quebras escapadas (barra + n), é aqui que elas viram newline — o padrão
    // tem que ser a barra escapada; com /\n/ a troca seria de newline por
    // newline, ou seja, nada. Se a chave já vier com quebras reais, o replace
    // simplesmente não encontra nada e a deixa intacta.
    key: credentials.private_key.replace(/\\n/g, '\n'),
    scopes: [SCOPE],
  });
  return cachedClient;
}

async function playGet<T>(path: string): Promise<T> {
  const response = await getClient().request<T>({ url: `${BASE}/${path}` });
  return response.data;
}

/** Estado de um consumível. `purchaseState` 0 = comprado. */
export interface ProductPurchase {
  purchaseState?: number;
  consumptionState?: number;
  orderId?: string;
}

export function getProductPurchase(productId: string, token: string) {
  return playGet<ProductPurchase>(
    `${requirePackageName()}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`,
  );
}

/** Assinaturas v2 — `subscriptionState` é o campo que diz se está valendo. */
export interface SubscriptionPurchaseV2 {
  subscriptionState?: string;
  lineItems?: Array<{ productId?: string; expiryTime?: string }>;
}

export function getSubscriptionPurchase(token: string) {
  return playGet<SubscriptionPurchaseV2>(
    `${requirePackageName()}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`,
  );
}

/** Estados em que a assinatura dá direito ao benefício. */
const ENTITLED_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED', // cancelada mas ainda dentro do período pago
]);

export function subscriptionEntitlement(
  purchase: SubscriptionPurchaseV2,
): { active: boolean; expiresAt: Date | null } {
  const active = ENTITLED_STATES.has(purchase.subscriptionState ?? '');
  const expiry = purchase.lineItems?.[0]?.expiryTime;
  const expiresAt = expiry ? new Date(expiry) : null;
  // Uma assinatura "cancelada" só vale até o fim do período já pago.
  if (active && expiresAt && expiresAt.getTime() <= Date.now()) {
    return { active: false, expiresAt };
  }
  return { active, expiresAt };
}
