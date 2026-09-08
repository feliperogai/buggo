# Buggo Server

API protegida em frente ao Neon Postgres usada pelo app Flutter (Buggo) para
login, sincronização de perfil e ranking. O app nunca se conecta direto no
Postgres — só chama esta API por HTTPS.

## Deployment Protection precisa ficar DESLIGADA

É a causa de "o servidor não funciona no celular". Com a *Deployment
Protection* (Vercel Authentication) ligada, a Vercel responde a tela de login
dela **antes** de chamar qualquer função: o aparelho recebe HTML com HTTP 401
e nunca chega na API. Não é bug do app — e não aparece para quem testa pelo
navegador já logado na Vercel, que passa pelo muro sem perceber.

Como conferir: se `/api/health` responde JSON, está liberado. Se responde uma
página de login, está bloqueado. Nos logs da Vercel, o sinal é não existir
*nenhuma* invocação de função, mesmo com gente usando o app.

Onde desligar: **Vercel > projeto `buggo-api` > Settings > Deployment
Protection > Vercel Authentication > Disabled**, e salvar.

Deixar desligado é o certo aqui: esta API é pública por natureza (o app roda
em milhares de celulares anônimos) e ela tem a própria autenticação — JWT em
todas as rotas de dados, e o `/api/leaderboard` é público de propósito.

## Deploy (Vercel)

1. Crie um novo projeto na Vercel apontando para este repositório.
2. Em **Settings > General > Root Directory**, defina `server`.
3. Em **Settings > Environment Variables**, adicione as chaves listadas em
   `.env.example` (`DATABASE_URL`, `JWT_SECRET`, `GMAIL_USER`,
   `GMAIL_APP_PASSWORD`, `APP_URL`).
4. Desligue a Deployment Protection (seção acima).
5. Rode `schema.sql` uma vez no SQL Editor do Neon (projeto `buggo`, branch
   `production`) para criar as tabelas.
6. Faça o deploy. A URL gerada (ex: `https://buggo-api.vercel.app`) é o valor
   que vai em `API_BASE_URL` no `.env` do app Flutter.

### Só a main é publicada

`vercel.json` restringe o deploy automático à branch `main`. São duas travas,
porque a primeira sozinha não segura tudo:

```json
"git": { "deploymentEnabled": { "main": true, "*": false, "*/*": false } },
"ignoreCommand": "[ \"$VERCEL_GIT_COMMIT_REF\" != \"main\" ]"
```

O curinga `*` do `deploymentEnabled` não atravessa barra — uma branch como
`claude/alguma-coisa` escapava da regra e gerava preview (visto na prática).
O `ignoreCommand` fecha o buraco: ele sai com 0 (= ignorar o build) em tudo
que não for `main`, e com 1 (= construir) na `main`.

### O autor do commit decide se o deploy roda

No plano Hobby a Vercel **bloqueia** (estado `BLOCKED`, sem publicar) todo
deployment cujo commit foi assinado por um e-mail que não pertence à conta.
Foi o que aconteceu com vários deploys desta API. Antes de commitar:

```bash
git config user.name  "caspheon"
git config user.email "contact@caspheon.com"
```

## Monitor

- **Página**: <https://buggo-api.vercel.app/> — a raiz do domínio é o monitor.
  Traz o estado atual, o gráfico de tempo de resposta (total e banco, as duas
  séries em milissegundos no mesmo eixo), a faixa de disponibilidade amostra a
  amostra, cada peça do servidor e o mesmo histórico em tabela. Atualiza
  sozinha a cada 30s e diz explicitamente quando o que voltou foi a tela de
  login da Vercel.
- **Rota**: `GET /api/health` → JSON com `status` (`ok` | `degraded` | `down`),
  `summary`, a lista de checagens e o histórico recente. Responde 503 quando
  algo essencial caiu. Não expõe valor de variável nenhuma, só se está
  definida. `?history=0` pula o histórico; `?history=N` pede N amostras.
- **Histórico**: cada chamada grava no máximo uma linha por minuto em
  `health_samples` (a chave primária é o minuto arredondado, então acesso
  repetido à página não vira escrita repetida), e linhas com mais de 7 dias
  são apagadas. Sem a tabela — é o último bloco de `schema.sql` — o monitor
  continua de pé, só sem gráfico.
- **Automático**: `.github/workflows/monitor.yml` consulta a rota de hora em
  hora e falha o job (e-mail do GitHub) quando o `status` é `down`. Recurso
  opcional desligado vira aviso, não falha. De quebra, é o que mantém o
  gráfico com pontos mesmo quando ninguém está com a página aberta.

## Desenvolvimento local

```bash
cd server
npm install
cp .env.example .env   # preencha com um DATABASE_URL de teste
npm run dev             # roda `vercel dev`, exige `vercel login` antes
npm run typecheck
```

## Endpoints

- `POST /api/auth/signup` — `{ email, password, name }` → `{ token, profile }`
- `POST /api/auth/login` — `{ email, password }` → `{ token, profile }`
- `POST /api/auth/forgot-password` — `{ email }` → sempre `200`; envia e-mail
  se a conta existir
- `POST /api/auth/reset-password` — `{ token, newPassword }`
- `GET /api/profile` — header `Authorization: Bearer <token>`
- `PUT /api/profile` — header `Authorization: Bearer <token>`, corpo = perfil
  completo
- `GET /api/leaderboard?by=xp|streak&limit=20` — público
- `GET /api/health` — público; estado de cada dependência do servidor

## Endpoints novos

- `POST /api/auth/google` — `{ idToken }` → `{ token, profile }`. Valida o
  token com o Google, vincula a uma conta existente de mesmo e-mail ou cria
  uma nova (sem senha).
- `POST /api/purchases/verify` — header `Authorization: Bearer <token>`,
  corpo `{ productId, purchaseToken }` → `{ profile }`. Confirma a compra na
  Play Developer API antes de creditar. O `purchase_token` é chave primária
  da tabela `purchases`, então reenviar o mesmo token não credita de novo.

## O que precisa ser configurado fora do código

Sem estes passos o botão do Google não aparece e as compras ficam
indisponíveis — o app continua funcionando no resto.

### Google Cloud (login)

1. Crie (ou reaproveite) um projeto no Google Cloud.
2. **APIs e Serviços > Tela de permissão OAuth**: preencha e publique.
3. **Credenciais > Criar credenciais > ID do cliente OAuth**, duas vezes:
   - Tipo **Android**: pacote `com.buggo.app` + a impressão digital **SHA-1**
     da keystore de release (`keytool -list -v -keystore <sua.jks>`). Se for
     usar a Assinatura de apps do Google Play, cadastre também o SHA-1 que o
     Play Console mostra em *Configuração > Integridade do app*.
   - Tipo **Web**: copie o Client ID gerado.
4. O Client ID **Web** vai em dois lugares: `GOOGLE_WEB_CLIENT_ID` nas env
   vars da Vercel e `GOOGLE_SERVER_CLIENT_ID` no `.env` do app Flutter.

### Google Play Console (pagamentos)

1. Publique o app em pelo menos um canal de teste (interno serve). Produtos
   não aparecem para apps nunca publicados.
2. **Monetizar > Produtos > Produtos no app**, crie três consumíveis com
   exatamente estes IDs: `coins_200`, `coins_450`, `coins_950`.
3. **Monetizar > Produtos > Assinaturas**, crie `buggo_plus_monthly` com um
   plano base mensal. Defina os preços por país — o app não tem preço fixo,
   ele mostra o que o Play devolver.
4. **Configuração > Teste de licença**: adicione sua conta Google, senão as
   compras de teste são cobradas de verdade.

### Service account (validação das compras)

1. No Google Cloud, ative a **Google Play Android Developer API**.
2. **IAM > Contas de serviço**: crie uma, gere uma chave JSON.
3. No Play Console, **Usuários e permissões**: convide o e-mail da service
   account com permissão de *Ver dados financeiros* e *Gerenciar pedidos*.
4. Cole o JSON inteiro (uma linha só) em `PLAY_SERVICE_ACCOUNT_JSON` na
   Vercel, e defina `ANDROID_PACKAGE_NAME=com.buggo.app`.

### Neon

Rode o bloco novo do fim de `schema.sql` no SQL Editor (é idempotente):
torna `password_hash` opcional, adiciona `google_id` e cria a tabela
`purchases`.
