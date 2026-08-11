import type { VercelRequest, VercelResponse } from '@vercel/node';
import { OAuth2Client } from 'google-auth-library';
import { sql } from '../../lib/db';
import { signToken } from '../../lib/auth';
import { rowToProfile, UserRow } from '../../lib/profile';

// Client ID *Web* do projeto no Google Cloud. É a audiência esperada do ID
// token — o app manda o mesmo valor via GOOGLE_SERVER_CLIENT_ID no .env.
// Sem conferir a audiência, um ID token válido emitido para QUALQUER outro
// app Google seria aceito aqui e daria acesso a contas do Buggo.
const CLIENT_ID = process.env.GOOGLE_CLIENT_ID ?? '';

const client = new OAuth2Client();

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (!CLIENT_ID) {
    res.status(500).json({ error: 'Login com Google não está configurado no servidor' });
    return;
  }

  const { idToken } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof idToken !== 'string' || idToken.length === 0) {
    res.status(400).json({ error: 'idToken é obrigatório' });
    return;
  }

  // verifyIdToken confere assinatura, expiração, emissor e audiência.
  let payload;
  try {
    const ticket = await client.verifyIdToken({ idToken, audience: CLIENT_ID });
    payload = ticket.getPayload();
  } catch {
    res.status(401).json({ error: 'Token do Google inválido ou expirado' });
    return;
  }

  if (!payload?.sub || !payload.email) {
    res.status(401).json({ error: 'Token do Google sem os dados necessários' });
    return;
  }

  // Conta Google sem e-mail verificado pode ser de alguém que só digitou o
  // endereço. Aceitá-la permitiria sequestrar a conta de e-mail/senha de
  // outra pessoa que use o mesmo endereço.
  if (payload.email_verified === false) {
    res.status(401).json({ error: 'E-mail do Google não verificado' });
    return;
  }

  const googleSub = payload.sub;
  const email = payload.email.trim().toLowerCase();
  const name = (payload.name ?? '').trim() || email.split('@')[0];

  // 1) Já entrou pelo Google antes.
  const byGoogle = await sql`select * from users where google_sub = ${googleSub}`;
  if (byGoogle.length > 0) {
    const row = byGoogle[0] as UserRow;
    res.status(200).json({ token: signToken(row.id), profile: rowToProfile(row) });
    return;
  }

  // 2) Já tinha conta de e-mail/senha com o mesmo endereço: vincula o Google
  // a ela em vez de criar uma segunda conta com o progresso zerado. Seguro
  // porque o e-mail do Google está verificado (checado acima).
  const byEmail = await sql`select * from users where email = ${email}`;
  if (byEmail.length > 0) {
    const existing = byEmail[0] as UserRow;
    const linked = await sql`
      update users set google_sub = ${googleSub}, updated_at = now()
      where id = ${existing.id}
      returning *
    `;
    const row = linked[0] as UserRow;
    res.status(200).json({ token: signToken(row.id), profile: rowToProfile(row) });
    return;
  }

  // 3) Primeiro acesso: cria a conta sem senha.
  const created = await sql`
    insert into users (email, google_sub, name)
    values (${email}, ${googleSub}, ${name})
    returning *
  `;
  const row = created[0] as UserRow;
  res.status(201).json({ token: signToken(row.id), profile: rowToProfile(row) });
}
