import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { getUserIdFromRequest } from '../../lib/auth';
import { rowToProfile, UserRow } from '../../lib/profile';
import { lookupProduct } from '../../lib/products';
import {
  getProductPurchase,
  getSubscriptionPurchase,
  subscriptionEntitlement,
} from '../../lib/play';

/// Confirma uma compra direto com o Google antes de creditar qualquer coisa.
/// O app manda só o `purchaseToken`; nada do que ele afirma sobre o valor da
/// compra é usado — um APK modificado não consegue forjar um token que a
/// Play Developer API aceite.
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const userId = getUserIdFromRequest(req);
  if (!userId) {
    res.status(401).json({ error: 'Não autenticado' });
    return;
  }

  const { productId, purchaseToken } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof productId !== 'string' || typeof purchaseToken !== 'string') {
    res.status(400).json({ error: 'productId e purchaseToken são obrigatórios' });
    return;
  }

  const entry = lookupProduct(productId);
  if (!entry) {
    res.status(400).json({ error: 'Produto desconhecido' });
    return;
  }

  // Replay: o purchase_token é chave primária, então uma compra já creditada
  // apenas devolve o perfil atual. Consumíveis recomprados geram um token
  // novo a cada compra, então isso não bloqueia compras legítimas.
  const seen = await sql`
    select user_id from purchases where purchase_token = ${purchaseToken}
  `;
  if (seen.length > 0) {
    // Vale para os dois tipos: um token já registrado por outra conta não
    // pode ser reaproveitado para creditar esta.
    if (seen[0].user_id !== userId) {
      res.status(409).json({ error: 'Esta compra pertence a outra conta' });
      return;
    }
    // Consumível já creditado não credita de novo. Assinatura segue adiante:
    // o mesmo token reaparece a cada renovação com uma expiryTime nova.
    if (entry.kind === 'product') {
      res.status(200).json({ profile: await currentProfile(userId), alreadyGranted: true });
      return;
    }
  }

  try {
    if (entry.kind === 'subscription') {
      return await grantSubscription(res, userId, productId, purchaseToken);
    }
    return await grantCoins(res, userId, productId, purchaseToken, entry.coins);
  } catch (err) {
    console.error('Falha ao validar compra no Google Play', err);
    res.status(502).json({ error: 'Não foi possível confirmar a compra com o Google Play' });
  }
}

async function currentProfile(userId: string) {
  const rows = await sql`select * from users where id = ${userId}`;
  return rowToProfile(rows[0] as UserRow);
}

async function grantCoins(
  res: VercelResponse,
  userId: string,
  productId: string,
  purchaseToken: string,
  coins: number,
) {
  const purchase = await getProductPurchase(productId, purchaseToken);
  if (purchase.purchaseState !== 0) {
    res.status(402).json({ error: 'Compra não confirmada pelo Google Play' });
    return;
  }

  const updated = await sql`
    update users set coins = coins + ${coins}, updated_at = now()
    where id = ${userId}
    returning *
  `;
  await sql`
    insert into purchases (purchase_token, user_id, product_id, kind, coins_granted)
    values (${purchaseToken}, ${userId}, ${productId}, 'product', ${coins})
    on conflict (purchase_token) do nothing
  `;
  res.status(200).json({ profile: rowToProfile(updated[0] as UserRow) });
}

async function grantSubscription(
  res: VercelResponse,
  userId: string,
  productId: string,
  purchaseToken: string,
) {
  const purchase = await getSubscriptionPurchase(purchaseToken);
  const { active, expiresAt } = subscriptionEntitlement(purchase);
  if (!active || !expiresAt) {
    res.status(402).json({ error: 'Assinatura não está ativa' });
    return;
  }

  // Renovação: o mesmo token volta a cada mês com uma expiryTime nova, então
  // a linha é atualizada em vez de recusada como replay.
  const updated = await sql`
    update users set unlimited_lives_until = ${expiresAt.toISOString()}, updated_at = now()
    where id = ${userId}
    returning *
  `;
  await sql`
    insert into purchases (purchase_token, user_id, product_id, kind, expires_at)
    values (${purchaseToken}, ${userId}, ${productId}, 'subscription', ${expiresAt.toISOString()})
    on conflict (purchase_token) do update
      set expires_at = excluded.expires_at, updated_at = now()
  `;
  res.status(200).json({ profile: rowToProfile(updated[0] as UserRow) });
}

