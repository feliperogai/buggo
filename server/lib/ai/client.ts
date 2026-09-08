/// Cliente mínimo para as duas IAs.
///
/// DeepSeek e OpenAI falam o mesmo dialeto (`POST /chat/completions` no
/// formato da OpenAI), então um cliente só atende as duas — muda a URL, a
/// chave e o modelo. Sem SDK: são ~40 linhas de `fetch` e evitam duas
/// dependências grandes numa função serverless.
///
/// A divisão de papéis é de propósito: **modelo que revisa a si mesmo
/// concorda consigo mesmo**. Gerador e revisor são de casas diferentes para
/// os erros não serem os mesmos.

export interface AiProvider {
  /** Nome curto, gravado junto do desafio para auditoria. */
  name: string;
  baseUrl: string;
  apiKey: string;
  model: string;
}

function provider(
  name: string,
  keyVar: string,
  modelVar: string,
  defaultModel: string,
  baseUrlVar: string,
  defaultBaseUrl: string,
): AiProvider | null {
  const apiKey = process.env[keyVar];
  if (!apiKey) return null;
  return {
    name,
    apiKey,
    model: process.env[modelVar] || defaultModel,
    baseUrl: (process.env[baseUrlVar] || defaultBaseUrl).replace(/\/+$/, ''),
  };
}

/// Quem escreve o desafio. DeepSeek é forte em código e barata.
export function generatorProvider(): AiProvider | null {
  return provider(
    'deepseek',
    'DEEPSEEK_API_KEY',
    'DEEPSEEK_MODEL',
    'deepseek-chat',
    'DEEPSEEK_BASE_URL',
    'https://api.deepseek.com/v1',
  );
}

/// Quem revisa. Outra casa, de propósito.
export function reviewerProvider(): AiProvider | null {
  return provider(
    'openai',
    'OPENAI_API_KEY',
    'OPENAI_MODEL',
    'gpt-4o-mini',
    'OPENAI_BASE_URL',
    'https://api.openai.com/v1',
  );
}

export class AiError extends Error {}

/// Pede uma resposta em JSON e devolve o objeto já parseado.
///
/// O `timeoutMs` importa: a função da Vercel tem teto de duração e uma
/// chamada pendurada derruba o pedido inteiro. Melhor falhar rápido e o app
/// simplesmente não mostrar o desafio do dia.
export async function chatJson(
  ai: AiProvider,
  options: {
    system: string;
    user: string;
    timeoutMs?: number;
    maxTokens?: number;
  },
): Promise<unknown> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), options.timeoutMs ?? 25000);

  let response: Response;
  try {
    response = await fetch(`${ai.baseUrl}/chat/completions`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ai.apiKey}`,
      },
      body: JSON.stringify({
        model: ai.model,
        temperature: 0.7,
        max_tokens: options.maxTokens ?? 900,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: options.system },
          { role: 'user', content: options.user },
        ],
      }),
    });
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new AiError(`${ai.name}: falha na chamada (${reason})`);
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) {
    const body = await response.text().catch(() => '');
    throw new AiError(
      `${ai.name}: HTTP ${response.status} ${body.slice(0, 200)}`,
    );
  }

  const body = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };
  const content = body.choices?.[0]?.message?.content;
  if (!content) throw new AiError(`${ai.name}: resposta sem conteúdo`);

  return parseJsonLoosely(content, ai.name);
}

/// Modelos às vezes embrulham o JSON numa cerca de markdown mesmo pedindo
/// JSON puro. Descascar é mais barato que uma tentativa a mais.
export function parseJsonLoosely(content: string, who: string): unknown {
  const cleaned = content
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(cleaned.slice(start, end + 1));
      } catch {
        // cai no throw abaixo
      }
    }
    throw new AiError(`${who}: resposta não é JSON`);
  }
}
