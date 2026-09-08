import { neon, NeonQueryFunction } from '@neondatabase/serverless';

/// A conexão é criada na primeira consulta, não na importação do módulo.
///
/// Antes isso era um `throw` no topo do arquivo: sem `DATABASE_URL`, *toda*
/// função que importasse este módulo quebrava antes de rodar uma linha, e a
/// Vercel devolvia uma página HTML de erro. O app lia isso como "Resposta
/// inesperada do servidor" e não havia como saber que faltava só uma variável
/// de ambiente. Agora quem falha é a consulta, com mensagem própria, e
/// `/api/health` consegue reportar o motivo em JSON.
let client: NeonQueryFunction<false, false> | null = null;

function getClient(): NeonQueryFunction<false, false> {
  if (client) return client;
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is not set');
  client = neon(url);
  return client;
}

export function isDatabaseConfigured(): boolean {
  return Boolean(process.env.DATABASE_URL);
}

/// Mesma interface de sempre (`` sql`select ...` ``), só que preguiçosa: o
/// proxy repassa a chamada e as propriedades (`transaction`, ...) para o
/// cliente criado sob demanda.
export const sql: NeonQueryFunction<false, false> = new Proxy(
  function () {} as unknown as NeonQueryFunction<false, false>,
  {
    apply: (_target, _thisArg, args: unknown[]) =>
      (getClient() as unknown as (...a: unknown[]) => unknown)(...args),
    get: (_target, prop: string | symbol) =>
      (getClient() as unknown as Record<string | symbol, unknown>)[prop],
  },
);

/// Consulta mais barata possível só para provar que o banco responde.
/// Usada por `/api/health`.
export async function pingDatabase(): Promise<void> {
  await sql`select 1 as ok`;
}
