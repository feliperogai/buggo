// Maps a `users` row (snake_case, as stored in Postgres) to the JSON shape
// the Flutter app's `UserProfile.fromMap`/`toMap` already speaks (camelCase).
// Keeping this in one place means signup/login/profile all stay in sync.

export interface UserRow {
  id: string;
  email: string;
  password_hash: string | null;
  name: string;
  language: string;
  level: string;
  daily_goal_minutes: number;
  xp: number;
  coins: number;
  streak: number;
  last_study_date: string | null;
  completed_lessons: string[];
  unlocked_achievements: string[];
  avatar_index: number;
  custom_photo_path: string | null;
  lives: number;
  last_life_lost_at: string | null;
  unlimited_lives_until: string | null;
  streak_freezes: number;
  last_ad_refill_at: string | null;
}

// The neon serverless driver may hand back timestamptz columns as either a
// `Date` or an ISO string depending on version/config — normalize to ISO
// string (or null) so the Dart side's `DateTime.tryParse` always works.
function toIso(value: unknown): string | null {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  return String(value);
}

function toArray(value: unknown): string[] {
  return Array.isArray(value) ? value.map(String) : [];
}

export function rowToProfile(row: UserRow) {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    language: row.language,
    level: row.level,
    dailyGoalMinutes: row.daily_goal_minutes,
    xp: row.xp,
    coins: row.coins,
    streak: row.streak,
    lastStudyDate: toIso(row.last_study_date),
    completedLessons: toArray(row.completed_lessons),
    unlockedAchievements: toArray(row.unlocked_achievements),
    avatarIndex: row.avatar_index,
    customPhotoPath: row.custom_photo_path,
    lives: row.lives,
    lastLifeLostAt: toIso(row.last_life_lost_at),
    unlimitedLivesUntil: toIso(row.unlimited_lives_until),
    streakFreezes: row.streak_freezes,
    lastAdRefillAt: toIso(row.last_ad_refill_at),
  };
}
