# Desafio diário com IA (DeepSeek)

Um desafio de programação por dia, gerado a partir do que o aluno já
estudou, resolvido digitando código num editor e corrigido pela IA.

## Como funciona

1. O aluno abre o card "Desafio do dia" na home.
2. O app chama `POST /api/challenge/daily`, mandando os títulos das lições
   que ele já concluiu.
3. O servidor lê linguagem, nível e contagem de lições no banco, monta o
   prompt e pede um desafio à DeepSeek. Guarda no Postgres e devolve ao app
   **sem o gabarito**.
4. O aluno escreve a solução no editor e envia.
5. `POST /api/challenge/submit` manda enunciado, gabarito e código para a IA,
   que devolve aprovado/reprovado, feedback e a linha do erro.
6. Se passou, o servidor credita XP e moedas e devolve o perfil atualizado.

Errar não custa vida. O mesmo desafio vale o dia inteiro — reabrir a tela não
gera desafio novo nem gasta chamada de IA.

## A chave da API

`DEEPSEEK_API_KEY` fica **só** nas Environment Variables da Vercel. Ela nunca
entra no app Flutter.

Isso não é preciosismo: qualquer pessoa extrai as strings de um APK em
minutos. Uma chave embutida no app é uma chave pública, e o consumo vai para
a sua fatura. Por isso o app fala com `/api/challenge/*`, e só
[server/lib/deepseek.ts](server/lib/deepseek.ts) conhece a chave.

O gabarito (`expected_behavior`) segue a mesma lógica: fica na tabela e nunca
é enviado ao app. Se fosse, bastaria olhar o tráfego para ver a resposta.

## Configuração

1. Crie a conta em platform.deepseek.com, gere uma API key e adicione crédito.
2. Na Vercel, no projeto do backend, adicione a variável `DEEPSEEK_API_KEY`.
3. Rode [server/migrations/002_daily_challenge.sql](server/migrations/002_daily_challenge.sql)
   no SQL Editor do Neon.
4. Publique o backend.

Enquanto `API_BASE_URL` não estiver no `.env` do app, o card nem aparece na
home — o desafio depende de conta e de servidor, então no modo convidado ele
seria um botão que sempre falha.

## Custo e limites

Cada geração e cada correção é uma chamada paga. O que protege a fatura:

- **Um desafio por dia por aluno**, garantido por constraint no banco
  (`daily_challenges_user_date_key`), não só por lógica de aplicação.
- **Teto de 20 envios por dia por aluno** — constante `MAX_ATTEMPTS_PER_DAY`
  em [server/lib/challenge.ts](server/lib/challenge.ts).
- **Limite de 8 mil caracteres por envio**, para a rota não virar proxy de LLM.
- Desafio já resolvido recusa novos envios antes de chamar a IA.
- Falha da IA não consome tentativa.

O modelo é `deepseek-chat` (V3), bem mais barato que o `deepseek-reasoner`.
Trocar é uma linha em `server/lib/deepseek.ts`.

## Ajustes que você provavelmente vai querer

**Dificuldade.** Três faixas por número de lições concluídas (`< 8`, `< 25`,
acima disso), em `difficultyFor` no `server/lib/challenge.ts`. Se os alunos
reclamarem que está fácil ou impossível, é o primeiro lugar a mexer.

**Recompensa.** Padrão de 40 XP e 20 moedas, nas colunas `xp_reward` e
`coin_reward` da tabela. Está acima de uma lição comum de propósito.

**Linguagem.** Quem ainda está em Fundamentos recebe Python, porque a trilha
de Lógica não ensina sintaxe nenhuma e o desafio é digitado. Regra em
`languageForChallenge`.

## Limitações conhecidas

**O código não roda.** A correção é a IA lendo o código, não execução real.
Ela acerta na esmagadora maioria dos casos de iniciante, mas pode aprovar
algo com um erro sutil de runtime. Se isso virar problema, o caminho é somar
um sandbox (Judge0 ou similar) que executa contra casos de teste e deixar a
IA só explicando o erro.

**A correção não é 100% determinística.** A temperatura está em 0 para
minimizar variação, mas dois envios idênticos podem, raramente, receber
vereditos diferentes.

**A IA pode gerar desafio ruim.** Enunciado ambíguo ou impossível acontece.
O aluno fica preso até o dia seguinte — vale considerar um botão de "gerar
outro" com limite, se aparecer nos relatos.
