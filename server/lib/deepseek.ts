// Cliente da API da DeepSeek (compatível com o formato da OpenAI).
//
// A chave vive só aqui, nas Environment Variables da Vercel. O app Flutter
// nunca fala com a DeepSeek direto — ele chama /api/challenge/*, e este
// arquivo é o único ponto que conhece a chave.

const BASE_URL = 'https://api.deepseek.com/chat/completions';

// deepseek-chat (V3) resolve bem geração e correção de exercícios básicos e
// custa uma fração do deepseek-reasoner. Se a correção começar a errar em
// desafios mais difíceis, trocar aqui é a única mudança necessária.
const MODEL = 'deepseek-chat';

// A geração pede criatividade (desafios repetidos entediam); a correção
// precisa ser previsível para o mesmo código receber sempre o mesmo veredito.
export const TEMPERATURE_CREATIVE = 1.0;
export const TEMPERATURE_STRICT = 0.0;

export class DeepSeekError extends Error {}

interface ChatOptions {
  system: string;
  user: string;
  temperature: number;
  maxTokens?: number;
}

/**
 * Faz uma chamada pedindo JSON de volta e já devolve o objeto parseado.
 *
 * Lança [DeepSeekError] com mensagem em português pronta para a resposta HTTP.
 */
export async function chatJson<T>(options: ChatOptions): Promise<T> {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    throw new DeepSeekError('DEEPSEEK_API_KEY não está configurada no servidor');
  }

  // Sem timeout, uma chamada travada seguraria a função serverless até o
  // limite da Vercel e o app ficaria girando sem resposta.
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 45_000);

  let response: Response;
  try {
    response = await fetch(BASE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          { role: 'system', content: options.system },
          { role: 'user', content: options.user },
        ],
        temperature: options.temperature,
        max_tokens: options.maxTokens ?? 1600,
        response_format: { type: 'json_object' },
      }),
      signal: controller.signal,
    });
  } catch (e) {
    const aborted = e instanceof Error && e.name === 'AbortError';
    throw new DeepSeekError(
      aborted ? 'A IA demorou demais para responder' : 'Não foi possível falar com a IA',
    );
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    // O corpo do erro pode conter detalhes da conta (crédito, limites). Fica
    // no log da Vercel, não na resposta ao app.
    console.error('DeepSeek respondeu %d: %s', response.status, await response.text());
    if (response.status === 429) {
      throw new DeepSeekError('A IA está sobrecarregada. Tente de novo em instantes.');
    }
    throw new DeepSeekError('A IA não conseguiu responder agora');
  }

  const body = (await response.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const content = body.choices?.[0]?.message?.content;
  if (!content) {
    throw new DeepSeekError('A IA devolveu uma resposta vazia');
  }

  try {
    return JSON.parse(content) as T;
  } catch {
    console.error('DeepSeek devolveu JSON inválido: %s', content);
    throw new DeepSeekError('A IA devolveu uma resposta em formato inesperado');
  }
}
