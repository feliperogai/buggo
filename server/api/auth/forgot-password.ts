import type { VercelRequest, VercelResponse } from '@vercel/node';
import { randomBytes } from 'crypto';
import { sql } from '../../lib/db';
import { sendPasswordResetEmail } from '../../lib/mailer';

const GENERIC_MESSAGE =
  'Se existir uma conta com este e-mail, enviamos um link de redefinição de senha.';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { email } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof email !== 'string' || !email.includes('@')) {
    res.status(400).json({ error: 'email é obrigatório' });
    return;
  }

  const normalizedEmail = email.trim().toLowerCase();
  const rows = await sql`select id from users where email = ${normalizedEmail}`;
  const userId = rows[0]?.id as string | undefined;

  // Always respond the same way whether or not the account exists, so the
  // endpoint can't be used to enumerate registered emails.
  if (!userId) {
    res.status(200).json({ message: GENERIC_MESSAGE });
    return;
  }

  const token = randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1h
  await sql`
    insert into password_reset_tokens (token, user_id, expires_at)
    values (${token}, ${userId}, ${expiresAt.toISOString()})
  `;

  const appUrl = process.env.APP_URL ?? '';
  const resetUrl = `${appUrl}/reset-password.html?token=${token}`;

  try {
    await sendPasswordResetEmail(normalizedEmail, resetUrl);
  } catch (err) {
    console.error('Failed to send password reset email', err);
  }

  res.status(200).json({ message: GENERIC_MESSAGE });
}
