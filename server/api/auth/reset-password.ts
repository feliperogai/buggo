import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { hashPassword } from '../../lib/auth';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { token, newPassword } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof token !== 'string' || typeof newPassword !== 'string') {
    res.status(400).json({ error: 'token e newPassword são obrigatórios' });
    return;
  }
  if (newPassword.length < 6) {
    res.status(400).json({ error: 'A senha precisa ter pelo menos 6 caracteres' });
    return;
  }

  const rows = await sql`
    select user_id, expires_at, used from password_reset_tokens where token = ${token}
  `;
  const record = rows[0] as { user_id: string; expires_at: string | Date; used: boolean } | undefined;

  if (!record || record.used || new Date(record.expires_at) < new Date()) {
    res.status(400).json({ error: 'Link inválido ou expirado. Peça um novo link.' });
    return;
  }

  const passwordHash = await hashPassword(newPassword);
  await sql`update users set password_hash = ${passwordHash}, updated_at = now() where id = ${record.user_id}`;
  await sql`update password_reset_tokens set used = true where token = ${token}`;

  res.status(200).json({ message: 'Senha redefinida com sucesso.' });
}
