import type { VercelRequest, VercelResponse } from '@vercel/node';
import jwt from 'jsonwebtoken';
import { isDatabaseConfigured, sql } from '../lib/db';
import { generatorProvider, reviewerProvider } from '../lib/ai/client';

/// Monitor do backend: diz, em JSON, se cada peça do servidor está de pé.
///
/// É público de propósito — é o mesmo caminho que o app percorre, então se
/// esta rota responde JSON, o aparelho também consegue falar com a API. Se
/// ela devolver a tela de login da Vercel (Deployment Protection ligada), é
/// exatamente isso que estava impedindo o app de funcionar.
///
/// Nenhum valor de variável de ambiente é exposto, só se está definida.
/// A página em `/status` é a leitura visual desta resposta; a raiz do
/// domínio é o site do Buggo.

type CheckStatus = 'ok' | 'fail' | 'off';

interface Check {
  /** Identificador estável, para script/monitor. */
  id: string;
  /** Nome legível, usado na página de status. */
  label: string;
  status: CheckStatus;
  /** `false` = recurso opcional; não derruba o servidor inteiro. */
  required: boolean;
  detail: string;
  durationMs?: number;
}

async function timed<T>(fn: () => Promise<T>): Promise<[T, number]> {
  const started = Date.now();
  const value = await fn();
  return [value, Date.now() - started];
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

/// Banco + esquema: a única dependência sem a qual nada funciona.
async function checkDatabase(): Promise<Check[]> {
  if (!isDatabaseConfigured()) {
    return [
      {
        id: 'database',
        label: 'Banco (Neon Postgres)',
        status: 'fail',
        required: true,
        detail: 'DATABASE_URL não está definida nas variáveis de ambiente.',
      },
    ];
  }

  let tables: Record<string, unknown>;
  let elapsed: number;
  try {
    [tables, elapsed] = await timed(async () => {
      const rows = await sql`
        select
          to_regclass('public.users') is not null as users_table,
          to_regclass('public.password_reset_tokens') is not null as reset_table,
          to_regclass('public.purchases') is not null as purchases_table
      `;
      return rows[0] as Record<string, unknown>;
    });
  } catch (error) {
    return [
      {
        id: 'database',
        label: 'Banco (Neon Postgres)',
        status: 'fail',
        required: true,
        detail: `Não foi possível consultar o banco: ${messageOf(error)}`,
      },
    ];
  }

  const missing = [
    tables.users_table ? null : 'users',
    tables.reset_table ? null : 'password_reset_tokens',
    tables.purchases_table ? null : 'purchases',
  ].filter((name): name is string => name !== null);

  const connection: Check = {
    id: 'database',
    label: 'Banco (Neon Postgres)',
    status: 'ok',
    required: true,
    detail: `Conectado, respondeu em ${elapsed} ms.`,
    durationMs: elapsed,
  };

  if (missing.length > 0) {
    return [
      connection,
      {
        id: 'schema',
        label: 'Tabelas do banco',
        status: 'fail',
        required: true,
        detail: `Faltando: ${missing.join(', ')}. Rode server/schema.sql no SQL Editor do Neon.`,
      },
    ];
  }

  // Só chega aqui com as tabelas no lugar, então contar é seguro.
  try {
    const rows = await sql`
      select
        (select count(*) from users)::int as users,
        exists (
          select 1 from information_schema.columns
          where table_schema = 'public'
            and table_name = 'users'
            and column_name = 'google_id'
        ) as has_google_id
    `;
    const row = rows[0] as { users: number; has_google_id: boolean };
    return [
      connection,
      {
        id: 'schema',
        label: 'Tabelas do banco',
        status: row.has_google_id ? 'ok' : 'fail',
        required: true,
        detail: row.has_google_id
          ? `users, password_reset_tokens e purchases no lugar · ${row.users} conta(s).`
          : 'Coluna users.google_id não existe. Rode o bloco final de server/schema.sql.',
      },
    ];
  } catch (error) {
    return [
      connection,
      {
        id: 'schema',
        label: 'Tabelas do banco',
        status: 'fail',
        required: true,
        detail: `Tabelas existem, mas a leitura falhou: ${messageOf(error)}`,
      },
    ];
  }
}

/// Assina e valida um token descartável — provar que JWT_SECRET existe não
/// basta, ele pode estar quebrado (vazio, com espaço colado, etc.).
function checkAuth(): Check {
  const base: Omit<Check, 'status' | 'detail'> = {
    id: 'auth',
    label: 'Sessões (JWT)',
    required: true,
  };
  if (!process.env.JWT_SECRET) {
    return { ...base, status: 'fail', detail: 'JWT_SECRET não está definida. Login e perfil não funcionam.' };
  }
  try {
    const token = jwt.sign({ sub: 'health-check' }, process.env.JWT_SECRET, { expiresIn: '1m' });
    const payload = jwt.verify(token, process.env.JWT_SECRET) as { sub?: string };
    if (payload.sub !== 'health-check') throw new Error('payload não confere');
    return { ...base, status: 'ok', detail: 'Assinatura e validação de token funcionando.' };
  } catch (error) {
    return { ...base, status: 'fail', detail: `JWT_SECRET inválida: ${messageOf(error)}` };
  }
}

/// Recuperação de senha. Opcional: sem isso o resto do app segue de pé.
function checkEmail(): Check {
  const configured = Boolean(process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD);
  return {
    id: 'email',
    label: 'E-mail (recuperação de senha)',
    status: configured ? 'ok' : 'off',
    required: false,
    detail: configured
      ? 'GMAIL_USER e GMAIL_APP_PASSWORD definidas.'
      : 'GMAIL_USER/GMAIL_APP_PASSWORD ausentes: "esqueci minha senha" falha.',
  };
}

function checkGoogleLogin(): Check {
  const configured = Boolean(process.env.GOOGLE_WEB_CLIENT_ID);
  return {
    id: 'google_login',
    label: 'Login com Google',
    status: configured ? 'ok' : 'off',
    required: false,
    detail: configured
      ? 'GOOGLE_WEB_CLIENT_ID definida.'
      : 'GOOGLE_WEB_CLIENT_ID ausente: o botão do Google não aparece no app.',
  };
}

/// Desafio do dia: precisa das duas IAs e das duas tabelas. Opcional — sem
/// isso o app só não mostra o cartão do desafio.
async function checkDailyChallenge(databaseUp: boolean): Promise<Check> {
  const base: Omit<Check, 'status' | 'detail'> = {
    id: 'daily_challenge',
    label: 'Desafio do dia (IA)',
    required: false,
  };

  const generator = generatorProvider();
  const reviewer = reviewerProvider();
  const missing = [
    generator ? null : 'DEEPSEEK_API_KEY',
    reviewer ? null : 'OPENAI_API_KEY',
  ].filter((name): name is string => name !== null);

  if (missing.length > 0) {
    return {
      ...base,
      status: 'off',
      detail: `${missing.join(' e ')} ausente(s): o desafio do dia não é gerado.`,
    };
  }

  if (!databaseUp) {
    return {
      ...base,
      status: 'off',
      detail: 'Chaves definidas, mas o banco não respondeu para checar as tabelas.',
    };
  }

  try {
    const rows = await sql`
      select
        to_regclass('public.daily_challenges') is not null as challenges,
        to_regclass('public.daily_completions') is not null as completions
    `;
    const row = rows[0] as { challenges: boolean; completions: boolean };
    const absent = [
      row.challenges ? null : 'daily_challenges',
      row.completions ? null : 'daily_completions',
    ].filter((name): name is string => name !== null);

    if (absent.length > 0) {
      return {
        ...base,
        status: 'fail',
        detail: `Faltando: ${absent.join(', ')}. Rode o bloco final de `
          + 'server/schema.sql no SQL Editor do Neon.',
      };
    }

    const today = await sql`
      select count(*)::int as total from daily_challenges
      where challenge_date = current_date
    `;
    const total = (today[0] as { total: number }).total;
    return {
      ...base,
      status: 'ok',
      detail: `${generator!.name}:${generator!.model} gera, `
        + `${reviewer!.name}:${reviewer!.model} revisa · `
        + `${total} desafio(s) preparado(s) hoje.`,
    };
  } catch (error) {
    return {
      ...base,
      status: 'fail',
      detail: `Não foi possível checar as tabelas: ${messageOf(error)}`,
    };
  }
}

/// A chave da service account é o ponto onde compras costumam quebrar sem
/// aviso, então aqui ela é realmente lida, não só checada por existir.
function checkPurchases(): Check {
  const base: Omit<Check, 'status' | 'detail'> = {
    id: 'purchases',
    label: 'Compras (Google Play)',
    required: false,
  };
  const raw = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  const packageName = process.env.ANDROID_PACKAGE_NAME;
  if (!raw || !packageName) {
    return {
      ...base,
      status: 'off',
      detail: 'PLAY_SERVICE_ACCOUNT_JSON/ANDROID_PACKAGE_NAME ausentes: compras não são creditadas.',
    };
  }
  try {
    const credentials = JSON.parse(raw) as { client_email?: string; private_key?: string };
    if (!credentials.client_email || !credentials.private_key) {
      throw new Error('sem client_email/private_key');
    }
    return { ...base, status: 'ok', detail: `Service account pronta para ${packageName}.` };
  } catch (error) {
    return { ...base, status: 'fail', detail: `PLAY_SERVICE_ACCOUNT_JSON inválida: ${messageOf(error)}` };
  }
}

interface Sample {
  at: string;
  status: string;
  totalMs: number;
  dbMs: number | null;
}

/// Grava a checagem e devolve as últimas [limit] amostras, em ordem
/// cronológica. É o que dá ao monitor um gráfico com histórico de verdade,
/// em vez de só o instante em que a página foi aberta.
///
/// A chave primária de `health_samples` é o minuto arredondado, então o
/// `on conflict do nothing` garante no máximo uma linha por minuto por mais
/// que a página (ou qualquer um) consulte a rota.
///
/// Nada aqui pode derrubar a resposta: se a tabela ainda não existe — ela é
/// o último bloco de schema.sql — o monitor mostra o gráfico vazio e diz o
/// porquê.
async function recordAndRead(
  status: string,
  totalMs: number,
  dbMs: number | null,
  limit: number,
): Promise<{ samples: Sample[]; note: string | null }> {
  try {
    await sql`
      insert into health_samples (bucket, status, total_ms, db_ms)
      values (date_trunc('minute', now()), ${status}, ${totalMs}, ${dbMs})
      on conflict (bucket) do nothing
    `;

    // Uma vez por hora basta para o histórico não crescer sem fim.
    if (new Date().getUTCMinutes() === 0) {
      await sql`delete from health_samples where bucket < now() - interval '7 days'`;
    }

    const rows = await sql`
      select bucket, status, total_ms, db_ms
      from health_samples
      order by bucket desc
      limit ${limit}
    `;
    const samples = rows
      .map((row) => ({
        at: new Date(row.bucket as string | number | Date).toISOString(),
        status: row.status as string,
        totalMs: row.total_ms as number,
        dbMs: (row.db_ms as number | null) ?? null,
      }))
      .reverse();
    return { samples, note: null };
  } catch (error) {
    return {
      samples: [],
      note: `Histórico indisponível (${messageOf(error)}). `
        + 'Rode o bloco final de server/schema.sql no SQL Editor do Neon.',
    };
  }
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // A página de status é servida da mesma origem, mas liberar a leitura
  // permite apontar qualquer monitor externo para cá.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 'no-store, max-age=0');

  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    res.status(204).end();
    return;
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const started = Date.now();
  const databaseChecks = await checkDatabase();
  const databaseUp = databaseChecks.every((c) => c.status === 'ok');
  const checks: Check[] = [
    ...databaseChecks,
    checkAuth(),
    checkEmail(),
    checkGoogleLogin(),
    checkPurchases(),
    await checkDailyChallenge(databaseUp),
  ];

  const broken = checks.filter((c) => c.status === 'fail');
  const status = broken.some((c) => c.required)
    ? 'down'
    : checks.every((c) => c.status === 'ok')
      ? 'ok'
      : 'degraded';

  // Duração só das checagens — medida antes de mexer no histórico, senão o
  // gráfico estaria medindo a si mesmo.
  const durationMs = Date.now() - started;
  const dbCheck = checks.find((c) => c.id === 'database');
  const dbMs = dbCheck?.durationMs ?? null;

  // `?history=0` pula a leitura (o job do GitHub Actions não precisa dela).
  const requested = Number(req.query.history);
  const limit = Number.isFinite(requested)
    ? Math.min(Math.max(requested, 0), 500)
    : 120;
  const history =
    limit > 0 && dbCheck?.status === 'ok'
      ? await recordAndRead(status, durationMs, dbMs, limit)
      : { samples: [], note: null };

  res.status(status === 'down' ? 503 : 200).json({
    status,
    // Resumo em uma linha, para quem só olha o topo da resposta.
    summary:
      status === 'ok'
        ? 'Tudo funcionando.'
        : status === 'degraded'
          ? `${checks.filter((c) => c.status !== 'ok').length} item(ns) fora do ar, nenhum essencial.`
          : `${broken.filter((c) => c.required).length} item(ns) essencial(is) fora do ar.`,
    checkedAt: new Date().toISOString(),
    durationMs,
    environment: process.env.VERCEL_ENV ?? 'desconhecido',
    region: process.env.VERCEL_REGION ?? null,
    commit: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? null,
    branch: process.env.VERCEL_GIT_COMMIT_REF ?? null,
    checks,
    history: history.samples,
    historyNote: history.note,
  });
}
