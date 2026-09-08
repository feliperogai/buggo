import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../lib/db';
import { getUserIdFromRequest } from '../lib/auth';
import { rowToProfile, UserRow } from '../lib/profile';
import { positionFor, TrackPosition } from '../lib/curriculum';
import {
  Challenge,
  isAnswerCorrect,
  publicChallenge,
  REWARD_COINS,
  submittedCode,
} from '../lib/challenge';
import { generateDailyChallenge, PipelineError } from '../lib/ai/pipeline';
import { gradeCodeWrite } from '../lib/ai/grade';

/// Desafio do dia, gerado por IA a partir do ponto em que a pessoa está.
///
/// `GET`  devolve o desafio de hoje (gerando na primeira vez que alguém
///        daquela combinação linguagem+nível pede).
/// `POST` confere a resposta e credita as moedas, uma vez por dia.
///
/// Três decisões que sustentam o resto:
///
/// 1. Nada vem do app. Linguagem e progresso saem da linha do usuário no
///    banco, então um APK modificado não consegue se declarar mais avançado
///    para pegar desafio mais caro.
/// 2. O gabarito nunca sai do servidor. O app recebe o enunciado sem a
///    resposta e manda o que a pessoa escolheu.
/// 3. O prêmio sai de uma tabela em código (`REWARD_COINS`), a partir da
///    dificuldade que a IA classificou. A IA não decide valor — moeda tem
///    preço em real na Play Store.
///
/// XP não entra aqui: XP é dos módulos da trilha. O desafio diário paga em
/// moeda.

/// Data no fuso de quem usa o app. Rodar em UTC viraria o dia às 21h no
/// Brasil, e o "desafio de hoje" mudaria no meio da noite de ontem.
function todayInBrazil(): string {
  return new Date().toLocaleDateString('en-CA', {
    timeZone: 'America/Sao_Paulo',
  });
}

interface ChallengeRow {
  id: string;
  difficulty: keyof typeof REWARD_COINS;
  payload: Challenge;
  language_id: string;
  stage: number;
}

async function loadUser(userId: string): Promise<UserRow | undefined> {
  const rows = await sql`select * from users where id = ${userId}`;
  return rows[0] as UserRow | undefined;
}

async function findChallenge(
  date: string,
  position: TrackPosition,
): Promise<ChallengeRow | undefined> {
  const rows = await sql`
    select id, difficulty, payload, language_id, stage
    from daily_challenges
    where challenge_date = ${date}
      and language_id = ${position.languageId}
      and stage = ${position.stage}
  `;
  return rows[0] as ChallengeRow | undefined;
}

async function claimedToday(userId: string, date: string): Promise<number | null> {
  const rows = await sql`
    select coins_granted from daily_completions
    where user_id = ${userId} and challenge_date = ${date}
  `;
  return rows.length > 0 ? (rows[0].coins_granted as number) : null;
}

async function handleGet(
  req: VercelRequest,
  res: VercelResponse,
  userId: string,
) {
  const user = await loadUser(userId);
  if (!user) {
    res.status(404).json({ error: 'Usuário não encontrado' });
    return;
  }

  const position = positionFor(user.language, user.completed_lessons ?? []);
  if (!position) {
    res.status(200).json({
      challenge: null,
      reason: `Sem trilha publicada para "${user.language}".`,
    });
    return;
  }

  const date = todayInBrazil();
  let row = await findChallenge(date, position);

  if (!row) {
    let generated;
    try {
      generated = await generateDailyChallenge(position);
    } catch (error) {
      const failure = error instanceof PipelineError
        ? error.failure
        : { stage: 'generate', detail: String(error) };
      console.error('Desafio do dia falhou', failure);
      // Sem desafio hoje é melhor que desafio que ninguém conferiu. O app
      // simplesmente não mostra o cartão.
      res.status(200).json({
        challenge: null,
        reason: 'Não foi possível preparar o desafio de hoje.',
      });
      return;
    }

    // Duas pessoas da mesma combinação podem pedir ao mesmo tempo; a chave
    // única resolve, e a releitura devolve o que ganhou a corrida.
    await sql`
      insert into daily_challenges (
        challenge_date, language_id, stage, difficulty, payload,
        generator_model, reviewer_model, review_notes
      ) values (
        ${date}, ${position.languageId}, ${position.stage},
        ${generated.challenge.difficulty},
        ${JSON.stringify(generated.challenge)}::jsonb,
        ${generated.generatorModel}, ${generated.reviewerModel},
        ${generated.reviewNotes}
      )
      on conflict (challenge_date, language_id, stage) do nothing
    `;
    row = await findChallenge(date, position);
    if (!row) {
      res.status(200).json({
        challenge: null,
        reason: 'Não foi possível preparar o desafio de hoje.',
      });
      return;
    }
  }

  const granted = await claimedToday(userId, date);

  res.status(200).json({
    challengeId: row.id,
    date,
    languageId: row.language_id,
    rewardCoins: REWARD_COINS[row.difficulty],
    alreadyClaimed: granted !== null,
    coinsGranted: granted,
    challenge: publicChallenge(row.payload),
  });
}

async function handlePost(
  req: VercelRequest,
  res: VercelResponse,
  userId: string,
) {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const challengeId = typeof body.challengeId === 'string' ? body.challengeId : '';
  if (!challengeId) {
    res.status(400).json({ error: 'challengeId é obrigatório' });
    return;
  }

  const user = await loadUser(userId);
  if (!user) {
    res.status(404).json({ error: 'Usuário não encontrado' });
    return;
  }

  const position = positionFor(user.language, user.completed_lessons ?? []);
  if (!position) {
    res.status(400).json({ error: 'Sem trilha para a linguagem atual' });
    return;
  }

  const date = todayInBrazil();
  const rows = await sql`
    select id, difficulty, payload, language_id, stage
    from daily_challenges
    where id = ${challengeId} and challenge_date = ${date}
  `;
  const row = rows[0] as ChallengeRow | undefined;
  if (!row) {
    res.status(404).json({ error: 'Desafio não encontrado para hoje' });
    return;
  }

  // Responder o desafio de outra combinação renderia moeda por algo que não
  // é a trilha da pessoa.
  if (row.language_id !== position.languageId || row.stage !== position.stage) {
    res.status(403).json({ error: 'Este desafio não é o seu de hoje' });
    return;
  }

  // Desafio de escrever código não tem gabarito comparável: a correção é a
  // IA revisora lendo a resposta, depois das exigências objetivas.
  let correct: boolean;
  let feedback: string | null = null;

  if (row.payload.type === 'codeWrite') {
    const code = submittedCode(body.answer);
    if (code === null) {
      res.status(400).json({ error: 'Escreva o código antes de enviar.' });
      return;
    }
    try {
      const grade = await gradeCodeWrite(row.payload, code);
      correct = grade.passed;
      feedback = grade.feedback;
    } catch (_) {
      // Falha da IA não vira reprovação nem aprovação: nada é creditado e a
      // pessoa pode tentar de novo.
      res.status(503).json({
        error: 'Não foi possível corrigir agora. Tente de novo em instantes.',
      });
      return;
    }
  } else {
    correct = isAnswerCorrect(row.payload, body.answer);
  }

  if (!correct) {
    res.status(200).json({ correct: false, coinsGranted: 0, feedback });
    return;
  }

  const coins = REWARD_COINS[row.difficulty];

  // A chave primária (user_id, challenge_date) é o que impede farmar: a
  // segunda tentativa do dia não insere nada e não credita.
  const inserted = await sql`
    insert into daily_completions (
      user_id, challenge_date, challenge_id, coins_granted
    ) values (${userId}, ${date}, ${row.id}, ${coins})
    on conflict (user_id, challenge_date) do nothing
    returning coins_granted
  `;

  if (inserted.length === 0) {
    const current = await loadUser(userId);
    res.status(200).json({
      correct: true,
      alreadyClaimed: true,
      coinsGranted: 0,
      feedback,
      profile: current ? rowToProfile(current) : null,
    });
    return;
  }

  const updated = await sql`
    update users set coins = coins + ${coins}, updated_at = now()
    where id = ${userId}
    returning *
  `;

  res.status(200).json({
    correct: true,
    alreadyClaimed: false,
    coinsGranted: coins,
    feedback,
    profile: rowToProfile(updated[0] as UserRow),
  });
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const userId = getUserIdFromRequest(req);
  if (!userId) {
    res.status(401).json({ error: 'Não autenticado' });
    return;
  }

  if (req.method === 'GET') return handleGet(req, res, userId);
  if (req.method === 'POST') return handlePost(req, res, userId);

  res.status(405).json({ error: 'Method not allowed' });
}
