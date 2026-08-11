# Login com Google, anúncios e pagamentos

Estado de cada frente e o que falta configurar fora do código.

| Frente | Código | Falta |
|---|---|---|
| Login com Google | Pronto | Criar os client IDs no Google Cloud e rodar a migração do banco |
| Anúncio premiado | Pronto (rodando com IDs de teste) | Criar conta AdMob e trocar os IDs |
| Pagamentos | Não implementado | Ver a seção 3 |

Enquanto as chaves não são preenchidas, nada quebra: o botão "Entrar com
Google" simplesmente não aparece, e os anúncios usam a unidade de teste do
Google.

---

## 1. Login com Google

### O que já funciona

O app pega o ID token da conta Google do aparelho e manda para
`POST /api/auth/google`. O backend valida assinatura, emissor, expiração e
audiência do token com a `google-auth-library`, e só então emite o JWT
próprio do Buggo — o mesmo que o login por e-mail/senha já usava.

Três casos são tratados em [server/api/auth/google.ts](server/api/auth/google.ts):

1. **Já entrou pelo Google antes** → encontra pelo `google_sub` e entra.
2. **Já tinha conta de e-mail/senha com o mesmo endereço** → vincula o Google
   à conta existente, preservando XP, moedas e progresso. Sem isso o usuário
   perderia tudo ao trocar de método de login.
3. **Primeiro acesso** → cria a conta sem senha.

O e-mail só é usado para vincular contas se o Google marcar como verificado.
Aceitar e-mail não verificado permitiria alguém cadastrar um endereço alheio
no Google e assumir a conta Buggo daquela pessoa.

### Passos de configuração

**1. Banco.** Rode [server/migrations/001_google_signin.sql](server/migrations/001_google_signin.sql)
no SQL Editor do Neon (projeto "buggo", branch production). Ela torna
`password_hash` anulável e adiciona `google_sub`.

**2. Google Cloud Console** (console.cloud.google.com):
- Crie um projeto e configure a Tela de consentimento OAuth (tipo Externo).
- Em Credenciais, crie **dois** client IDs OAuth:
  - **Android** — package `com.buggo.app` + a impressão SHA-1.
  - **Web** — é este que vai nas variáveis de ambiente.

**3. A pegadinha do SHA-1.** Com o Play App Signing (padrão para apps novos),
o Google **reassina** seu app com um certificado dele. O SHA-1 da sua keystore
local só vale para builds instalados direto no aparelho; o app vindo da loja
usa outro. Registre os dois:

```bash
# SHA-1 da sua keystore (builds locais)
keytool -list -v -keystore android/buggo-release.jks -alias buggo
```

O SHA-1 de produção fica no Play Console em **Configuração → Assinatura de app
→ Certificado da chave de assinatura**. Se só registrar o local, o login
funciona no seu celular e falha para todo mundo que baixar da loja.

**4. Variáveis de ambiente.** O mesmo Web client ID nos dois lados:
- `.env` do app: `GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com`
- Vercel (projeto do backend): `GOOGLE_CLIENT_ID` com o mesmo valor.

---

## 2. Anúncio premiado

### Como funciona

Só existe um anúncio no app, e ele é sempre opcional: quando as vidas zeram,
aparece "Assistir anúncio · Grátis · recupera todas as vidas" no card de
recuperação. Assistir até o fim devolve as 5 vidas.

Quem assina o Buggo+ tem vidas ilimitadas, então o botão nem é renderizado
para essas contas.

Fechar o anúncio no meio **não** dá recompensa — quem decide isso é o SDK do
AdMob via `onUserEarnedReward`, não o app. Ver
[lib/core/ads/ads_service.dart](lib/core/ads/ads_service.dart).

### Passos de configuração

1. Crie a conta em admob.google.com e cadastre o app (Android, `com.buggo.app`).
2. Copie o **App ID** (`ca-app-pub-...~...`, com `~`) para o
   `AndroidManifest.xml`, substituindo o ID de teste.
3. Crie um bloco de anúncios do tipo **Premiado** e copie o **ad unit ID**
   (`ca-app-pub-.../...`, com `/`) para `ADMOB_REWARDED_AD_UNIT_ID` no `.env`.
4. Cadastre seu celular como dispositivo de teste no painel do AdMob.

> Em debug o app **sempre** usa a unidade de teste, mesmo com o `.env`
> preenchido. Clicar nos próprios anúncios de produção durante o
> desenvolvimento gera tráfego inválido e é a causa mais comum de suspensão
> de conta AdMob.

### O que muda no Play Console

Anúncio não é só código — três formulários mudam:

- **Contém anúncios:** passa a ser **Sim**.
- **Segurança de Dados:** o SDK do AdMob coleta ID de publicidade,
  identificadores do dispositivo e interações no app. Precisa ser declarado
  como coletado e compartilhado com terceiros, para publicidade. Isso muda a
  resposta que está hoje em [store/PLAY_STORE.md](store/PLAY_STORE.md).
- **Política de privacidade:** [server/public/privacy.html](server/public/privacy.html)
  precisa ganhar uma seção sobre publicidade e o ID de publicidade.

O SDK também injeta sozinho a permissão `com.google.android.gms.permission.AD_ID`
no manifesto mesclado — é esperado, não precisa remover.

---

## 3. Pagamentos — plano

**Ainda não implementado.** O que existe hoje é a seção "Dinheiro real" do
Market, com cartões inertes marcados "Em breve".

### A regra que decide tudo

Vidas, moedas e Buggo+ são bens digitais consumidos dentro do app. Para esse
caso o Google Play **obriga** o uso do Play Billing. Pix, Stripe, Mercado Pago
ou qualquer checkout externo levam à remoção do app. Não há caminho
alternativo legítimo aqui.

- Taxa: 15% até US$ 1 milhão por ano, 30% acima.
- Exige um **perfil de pagamentos do Google** (conta de comerciante), com
  dados bancários e fiscais. É cadastro separado do de desenvolvedor e leva
  alguns dias para aprovar — comece por aqui, é o passo mais lento.

### Implementação

**Pacote:** `in_app_purchase` (mantido pelo time do Flutter).

**Produtos a criar no Play Console:**

| ID | Tipo | O que entrega |
|---|---|---|
| `buggo_plus_monthly` | Assinatura | Vidas ilimitadas por 30 dias |
| `coins_500`, `coins_1200`, ... | Consumível | Pacotes de moedas |

**Fluxo no app:**

1. `InAppPurchase.instance.queryProductDetails({...})` para buscar os preços
   reais — nunca exiba preço fixo no código, porque o Play converte moeda e
   aplica impostos por país.
2. `buyConsumable` (moedas) ou `buyNonConsumable` (assinatura).
3. Escutar `purchaseStream`.
4. **Validar no servidor** antes de creditar (próximo item).
5. `completePurchase` para finalizar. Consumível não consumido não pode ser
   comprado de novo; assinatura não confirmada em 3 dias é **estornada
   automaticamente** pelo Google.

**Validação no servidor (não é opcional aqui).** Como moedas e vidas
sincronizam com o Neon, um cliente modificado poderia alegar uma compra e
receber o crédito. O backend precisa de uma rota `POST /api/purchase/verify`
que receba o `purchaseToken`, consulte a Google Play Developer API
(`purchases.products.get` / `purchases.subscriptions.get`) com uma conta de
serviço, confirme que a compra existe e está paga, e só então credite.
Guarde o token numa tabela para não creditar a mesma compra duas vezes.

**Onde encaixa no código que já existe:** `activateMonthlyPlan` em
[lib/shared/providers/user_provider.dart](lib/shared/providers/user_provider.dart)
já concede vidas ilimitadas por 30 dias, e as colunas `unlimited_lives_until`
e `coins` já existem no schema. O que falta é a camada de compra e a
verificação — a lógica de negócio já está pronta.

**Assinatura precisa de mais cuidado:** renovação, cancelamento, período de
carência e reembolso chegam por *Real-time developer notifications* (Pub/Sub),
não pelo app. Sem tratar isso, um usuário que cancelou continua com vidas
ilimitadas até a data gravada no banco.

**Teste:** cadastre contas como testadores de licença no Play Console. Elas
compram de verdade pelo fluxo real, sem cobrança.
