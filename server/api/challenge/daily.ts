import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { getUserIdFromRequest } from '../../lib/auth';
import { UserRow } from '../../lib/profile';
import { chatJson, DeepSeekError, TEMPERATURE_CREATIVE } from '../../lib/deepseek';
import {
  GENERATION_SYSTEM,
  MAX_ATTEMPTS_PER_DAY,
  buildGenerationPrompt,
  languageForChallenge,
  todayInSaoPaulo,
} from '../../lib/challenge';

interface GeneratedChallenge {
  title: string;
  statement: string;
  starterCode: string;
  expectedBehavior: string;
}

// O que volta para o app. `expectedBehavior` fica de fora de propósito: é o
// gabarito, e mandá-lo entregaria a resposta a quem olhasse o tráfego.
function toPublicJson(row: {
  id: string;
  language: string;
  title: string;
  statement: string;
  starter_code: string;
  xp_reward: number;
  coin_reward: number;
  solved: boolean;
  attempts: number;
  last_feedback: string | null;
}) {
  return {
    id: row.id,
    language: row.language,
    title: row.title,
    statement: row.statement,
    starterCode: row.starter_code,
    xpReward: row.xp_reward,
    coinReward: row.coin_reward,
    solved: row.solved,
    attempts: row.attempts,
    attemptsLeft: Math.max(0, MAX_ATTEMPTS_PER_DAY - row.attempts),
    lastFeedback: row.last_feedback,
  };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const userId = getUserIdFromRequest(req);
  if (!userId) {
    res.status(401).json({ error: 'Não autenticado' });
    return;
  }

  const today = todayInSaoPaulo();

  // Desafio de hoje já existe? Devolve sem gastar chamada de IA. Isto também
  // é o que faz o app poder reabrir a tela quantas vezes quiser.
  const existing = await sql`
    select * from daily_challenges
    where user_id = ${userId} and challenge_date = ${today}
  `;
  if (existing.length > 0) {
    res.status(200).json({ challenge: toPublicJson(existing[0] as never) });
    return;
  }

  const users = await sql`select * from users where id = ${userId}`;
  const user = users[0] as UserRow | undefined;
  if (!user) {
    res.status(404).json({ error: 'Usuário não encontrado' });
    return;
  }

  // Os títulos das lições vêm do app porque o currículo mora lá, não aqui.
  // É só contexto para o prompt: a contagem que define a dificuldade e a
  // recompensa saem do banco, então mentir na lista não rende vantagem.
  const body = (req.body ?? {}) as Record<string, unknown>;
  const topics = Array.isArray(body.topics)
    ? (body.topics as unknown[])
        .filter((t): t is string => typeof t === 'string')
        .slice(0, 40)
    : [];

  const completedCount = user.completed_lessons?.length ?? 0;
  const language = languageForChallenge(user.language);

  let generated: GeneratedChallenge;
  try {
    generated = await chatJson<GeneratedChallenge>({
      system: GENERATION_SYSTEM,
      user: buildGenerationPrompt({
        language,
        level: user.level,
        completedCount,
        topics,
      }),
      temperature: TEMPERATURE_CREATIVE,
    });
  } catch (e) {
    const message =
      e instanceof DeepSeekError ? e.message : 'Não foi possível gerar o desafio de hoje';
    res.status(503).json({ error: message });
    return;
  }

  if (
    !generated.title ||
    !generated.statement ||
    !generated.expectedBehavior ||
    typeof generated.starterCode !== 'string'
  ) {
    res.status(503).json({ error: 'A IA devolveu um desafio incompleto. Tente de novo.' });
    return;
  }

  // ON CONFLICT porque dois toques rápidos no botão disparam duas gerações em
  // paralelo; a segunda encontra a linha da primeira em vez de estourar erro.
  const inserted = await sql`
    insert into daily_challenges
      (user_id, challenge_date, language, title, statement, starter_code, expected_behavior)
    values (
      ${userId}, ${today}, ${language}, ${generated.title.slice(0, 120)},
      ${generated.statement}, ${generated.starterCode}, ${generated.expectedBehavior}
    )
    on conflict on constraint daily_challenges_user_date_key do update
      set user_id = excluded.user_id
    returning *
  `;

  res.status(201).json({ challenge: toPublicJson(inserted[0] as never) });
}
