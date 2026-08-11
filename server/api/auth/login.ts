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

  // Conta criada pelo Google não tem senha. Sem este guard, o bcrypt
  // receberia null e quebraria com 500 em vez de orientar o usuário.
  if (row && row.password_hash === null) {
    res.status(409).json({
      error: 'Esta conta usa o login com Google. Toque em "Entrar com Google".',
    });
    return;
  }

  if (!row || !(await comparePassword(password, row.password_hash!))) {
    res.status(401).json({ error: 'E-mail ou senha incorretos' });
    return;
  }

  const token = signToken(row.id);
  res.status(200).json({ token, profile: rowToProfile(row) });
}
