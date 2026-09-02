import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { comparePassword, signToken } from '../../lib/auth';
import { rowToProfile, UserRow } from '../../lib/profile';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { email, password } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof email !== 'string' || typeof password !== 'string') {
    res.status(400).json({ error: 'email e password são obrigatórios' });
    return;
  }

  const normalizedEmail = email.trim().toLowerCase();
  const rows = await sql`select * from users where email = ${normalizedEmail}`;
  const row = rows[0] as UserRow | undefined;
  if (!row) {
    res.status(401).json({ error: 'E-mail ou senha incorretos' });
    return;
  }

  // An account created through the Google button has no password. Saying so
  // is not an enumeration leak worth avoiding here: the alternative is the
  // user retrying a password that can never work.
  const passwordHash = row.password_hash;
  if (passwordHash === null) {
    res.status(401).json({
      error: 'Esta conta usa o login do Google. Toque em "Continuar com Google".',
    });
    return;
  }

  if (!(await comparePassword(password, passwordHash))) {
    res.status(401).json({ error: 'E-mail ou senha incorretos' });
    return;
  }

  const token = signToken(row.id);
  res.status(200).json({ token, profile: rowToProfile(row) });
}
