import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { signToken } from '../../lib/auth';
import { verifyGoogleIdToken } from '../../lib/google';
import { rowToProfile, UserRow } from '../../lib/profile';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { idToken } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof idToken !== 'string' || idToken.length === 0) {
    res.status(400).json({ error: 'idToken é obrigatório' });
    return;
  }

  let identity;
  try {
    identity = await verifyGoogleIdToken(idToken);
  } catch (err) {
    console.error('Google ID token inválido', err);
    res.status(401).json({ error: 'Não foi possível validar sua conta Google' });
    return;
  }

  // Google says it verified the address; without that we can't safely treat
  // it as proof of owning an existing password account with the same email.
  if (!identity.emailVerified) {
    res.status(401).json({ error: 'Sua conta Google não tem o e-mail verificado' });
    return;
  }

  // 1. Already linked.
  const linked = await sql`select * from users where google_id = ${identity.googleId}`;
  if (linked.length > 0) {
    const row = linked[0] as UserRow;
    res.status(200).json({ token: signToken(row.id), profile: rowToProfile(row) });
    return;
  }

  // 2. Same email as an existing (password) account: link the two instead of
  // creating a duplicate, so someone who signed up with a password can
  // switch to the Google button and keep their progress.
  const byEmail = await sql`select * from users where email = ${identity.email}`;
  if (byEmail.length > 0) {
    const existing = byEmail[0] as UserRow;
    const updated = await sql`
      update users set google_id = ${identity.googleId}, updated_at = now()
      where id = ${existing.id}
      returning *
    `;
    const row = updated[0] as UserRow;
    res.status(200).json({ token: signToken(row.id), profile: rowToProfile(row) });
    return;
  }

  // 3. Brand new account. No password_hash — this user signs in with Google.
  const created = await sql`
    insert into users (email, name, google_id)
    values (${identity.email}, ${identity.name ?? identity.email.split('@')[0]}, ${identity.googleId})
    returning *
  `;
  const row = created[0] as UserRow;
  res.status(201).json({ token: signToken(row.id), profile: rowToProfile(row) });
}
