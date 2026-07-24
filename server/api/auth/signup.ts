import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { hashPassword, signToken } from '../../lib/auth';
import { rowToProfile, UserRow } from '../../lib/profile';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { email, password, name } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof email !== 'string' || typeof password !== 'string' || typeof name !== 'string') {
    res.status(400).json({ error: 'email, password e name são obrigatórios' });
    return;
  }

  const normalizedEmail = email.trim().toLowerCase();
  const trimmedName = name.trim();
  if (!normalizedEmail.includes('@') || password.length < 6 || trimmedName.length === 0) {
    res.status(400).json({ error: 'Dados inválidos: e-mail válido, senha com 6+ caracteres e nome são obrigatórios' });
    return;
  }

  const existing = await sql`select id from users where email = ${normalizedEmail}`;
  if (existing.length > 0) {
    res.status(409).json({ error: 'Já existe uma conta com este e-mail' });
    return;
  }

  const passwordHash = await hashPassword(password);
  const rows = await sql`
    insert into users (email, password_hash, name)
    values (${normalizedEmail}, ${passwordHash}, ${trimmedName})
    returning *
  `;
  const row = rows[0] as UserRow;
  const token = signToken(row.id);
  res.status(201).json({ token, profile: rowToProfile(row) });
}
