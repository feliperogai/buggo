import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db';
import { getUserIdFromRequest } from '../../lib/auth';
import { rowToProfile, UserRow } from '../../lib/profile';
import { chatJson, DeepSeekError, TEMPERATURE_STRICT } from '../../lib/deepseek';
import {
  GRADING_SYSTEM,
  MAX_ATTEMPTS_PER_DAY,
  buildGradingPrompt,
  todayInSaoPaulo,
} from '../../lib/challenge';

interface Grade {
  passed: boolean;
  feedback: string;
  errorLine: number | null;
}

// Um envio de 40 mil caracteres não é aluno resolvendo exercício, é alguém
// usando a rota como proxy de LLM. Corta antes de virar custo de token.
const MAX_CODE_LENGTH = 8000;

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

  const { code } = (req.body ?? {}) as Record<string, unknown>;
  if (typeof code !== 'string' || code.trim().length === 0) {
    res.status(400).json({ error: 'Escreva algum código antes de enviar' });
    return;
  }
  if (code.length > MAX_CODE_LENGTH) {
    res.status(400).json({ error: 'Código longo demais para este desafio' });
    return;
  }

  const today = todayInSaoPaulo();
  const rows = await sql`
    select * from daily_challenges
    where user_id = ${userId} and challenge_date = ${today}
  `;
  const challenge = rows[0] as
    | {
        id: string;
        language: string;
        statement: string;
        expected_behavior: string;
        xp_reward: number;
        coin_reward: number;
        solved: boolean;
        attempts: number;
      }
    | undefined;

  if (!challenge) {
    res.status(404).json({ error: 'Nenhum desafio aberto hoje. Abra o desafio primeiro.' });
    return;
  }

  // Já resolvido: sai antes de chamar a IA. Sem isto, reenviar o mesmo código
  // pagaria uma correção nova e creditaria XP de novo a cada envio.
  if (challenge.solved) {
    res.status(409).json({ error: 'Você já concluiu o desafio de hoje!' });
    return;
  }

  if (challenge.attempts >= MAX_ATTEMPTS_PER_DAY) {
    res.status(429).json({
      error: `Você usou as ${MAX_ATTEMPTS_PER_DAY} tentativas de hoje. O desafio novo chega amanhã.`,
    });
    return;
  }

  let grade: Grade;
  try {
    grade = await chatJson<Grade>({
      system: GRADING_SYSTEM,
      user: buildGradingPrompt({
        language: challenge.language,
        statement: challenge.statement,
        expectedBehavior: challenge.expected_behavior,
        code,
      }),
      temperature: TEMPERATURE_STRICT,
      maxTokens: 700,
    });
  } catch (e) {
    // Falha da IA não consome tentativa: o aluno não errou nada.
    const message =
      e instanceof DeepSeekError ? e.message : 'Não foi possível corrigir agora';
    res.status(503).json({ error: message });
    return;
  }

  const passed = grade.passed === true;
  const feedback =
    typeof grade.feedback === 'string' && grade.feedback.trim().length > 0
      ? grade.feedback.trim()
      : passed
        ? 'Resolvido! Bom trabalho.'
        : 'Ainda não está certo. Revise o enunciado e tente de novo.';

  await sql`
    update daily_challenges
    set attempts = attempts + 1,
        solved = ${passed},
        last_feedback = ${feedback}
    where id = ${challenge.id}
  `;

  // XP e moedas saem das colunas do desafio, não de nada que o app mande —
  // o cliente não escolhe a própria recompensa.
  let profile = null;
  if (passed) {
    const updated = await sql`
      update users
      set xp = xp + ${challenge.xp_reward},
          coins = coins + ${challenge.coin_reward},
          updated_at = now()
      where id = ${userId}
      returning *
    `;
    profile = rowToProfile(updated[0] as UserRow);
  }

  res.status(200).json({
    passed,
    feedback,
    errorLine: typeof grade.errorLine === 'number' ? grade.errorLine : null,
    attemptsLeft: Math.max(0, MAX_ATTEMPTS_PER_DAY - (challenge.attempts + 1)),
    xpEarned: passed ? challenge.xp_reward : 0,
    coinsEarned: passed ? challenge.coin_reward : 0,
    profile,
  });
}
