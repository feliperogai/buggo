import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../lib/db';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const by = req.query.by === 'streak' ? 'streak' : 'xp';
  const limitParam = Number(req.query.limit);
  const limit = Number.isFinite(limitParam) && limitParam > 0 ? Math.min(limitParam, 100) : 20;

  const rows = by === 'streak'
    ? await sql`
        select id, name, avatar_index, xp, streak from users
        order by streak desc, xp desc
        limit ${limit}
      `
    : await sql`
        select id, name, avatar_index, xp, streak from users
        order by xp desc, streak desc
        limit ${limit}
      `;

  const entries = rows.map((row) => ({
    id: row.id as string,
    name: row.name as string,
    avatarIndex: row.avatar_index as number,
    xp: row.xp as number,
    streak: row.streak as number,
  }));

  res.status(200).json({ entries });
}
