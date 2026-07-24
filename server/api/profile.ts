import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../lib/db';
import { getUserIdFromRequest } from '../lib/auth';
import { rowToProfile, UserRow } from '../lib/profile';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const userId = getUserIdFromRequest(req);
  if (!userId) {
    res.status(401).json({ error: 'Não autenticado' });
    return;
  }

  if (req.method === 'GET') {
    const rows = await sql`select * from users where id = ${userId}`;
    const row = rows[0] as UserRow | undefined;
    if (!row) {
      res.status(404).json({ error: 'Usuário não encontrado' });
      return;
    }
    res.status(200).json({ profile: rowToProfile(row) });
    return;
  }

  if (req.method === 'PUT') {
    // The app always pushes the full `UserProfile.toMap()` snapshot (not a
    // partial patch), so nullable fields are assigned directly — that's the
    // only way a value like `lastLifeLostAt`/`customPhotoPath` can ever be
    // cleared back to null once the lives refill / the photo is removed.
    const body = (req.body ?? {}) as Record<string, unknown>;
    if (typeof body.name !== 'string' || body.name.trim().length === 0) {
      res.status(400).json({ error: 'name é obrigatório' });
      return;
    }

    const rows = await sql`
      update users set
        name = ${body.name as string},
        language = ${(body.language as string) ?? 'logic'},
        level = ${(body.level as string) ?? 'adult'},
        daily_goal_minutes = ${(body.dailyGoalMinutes as number) ?? 15},
        xp = ${(body.xp as number) ?? 0},
        coins = ${(body.coins as number) ?? 0},
        streak = ${(body.streak as number) ?? 0},
        last_study_date = ${(body.lastStudyDate as string) ?? null},
        completed_lessons = ${(body.completedLessons as string[]) ?? []},
        unlocked_achievements = ${(body.unlockedAchievements as string[]) ?? []},
        avatar_index = ${(body.avatarIndex as number) ?? 0},
        custom_photo_path = ${(body.customPhotoPath as string) ?? null},
        lives = ${(body.lives as number) ?? 5},
        last_life_lost_at = ${(body.lastLifeLostAt as string) ?? null},
        unlimited_lives_until = ${(body.unlimitedLivesUntil as string) ?? null},
        streak_freezes = ${(body.streakFreezes as number) ?? 0},
        updated_at = now()
      where id = ${userId}
      returning *
    `;
    const row = rows[0] as UserRow | undefined;
    if (!row) {
      res.status(404).json({ error: 'Usuário não encontrado' });
      return;
    }
    res.status(200).json({ profile: rowToProfile(row) });
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
