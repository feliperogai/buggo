import type { VercelRequest, VercelResponse } from '@vercel/node';
import jwt from 'jsonwebtoken';
import { isDatabaseConfigured, sql } from '../lib/db';

/// Monitor do backend: diz, em JSON, se cada peça do servidor está de pé.
///
/// É público de propósito — é o mesmo caminho que o app percorre, então se
/// esta rota responde JSON, o aparelho também consegue falar com a API. Se
/// ela devolver a tela de login da Vercel (Deployment Protection ligada), é
/// exatamente isso que estava impedindo o app de funcionar.
///
/// Nenhum valor de variável de ambiente é exposto, só se está definida.
/// A página em `/status.html` é a leitura visual desta resposta.

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
  const checks: Check[] = [
    ...(await checkDatabase()),
    checkAuth(),
    checkEmail(),
    checkGoogleLogin(),
    checkPurchases(),
  ];

  const broken = checks.filter((c) => c.status === 'fail');
  const status = broken.some((c) => c.required)
    ? 'down'
    : checks.every((c) => c.status === 'ok')
      ? 'ok'
      : 'degraded';

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
    durationMs: Date.now() - started,
    environment: process.env.VERCEL_ENV ?? 'desconhecido',
    region: process.env.VERCEL_REGION ?? null,
    commit: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? null,
    branch: process.env.VERCEL_GIT_COMMIT_REF ?? null,
    checks,
  });
}
