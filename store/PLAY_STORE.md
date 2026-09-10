# Publicação do Buggo na Google Play

Tudo que o Play Console pede, já respondido. Os arquivos citados estão nesta
pasta (`store/`).

---

## 1. Arquivo para upload

| Item | Valor |
|---|---|
| Arquivo | `build/app/outputs/bundle/release/app-release.aab` |
| Tamanho | 43,2 MB |
| Package | `com.buggo.app` |
| Versão | 1.0.0 (versionCode 2) |
| Assinatura | keystore própria, verificada (`CN=Buggo`) |
| targetSdk | 36 |
| minSdk | 24 (Android 7.0) |
| Permissões | apenas `CAMERA` |

O versionCode **precisa subir a cada upload** — o Play recusa reenvio de um
número já usado. Bump em `pubspec.yaml` (`1.0.0+2` → `1.0.0+3`).

Regerar depois de qualquer mudança: `flutter build appbundle --release`

---

## 2. Ficha da loja

**Nome do app** (até 30 caracteres)
```
Buggo: Aprenda a Programar
```

**Descrição breve** (até 80 caracteres)
```
Aprenda lógica e programação com lições curtas, quizzes e desafios diários.
```

**Descrição completa** (até 4000 caracteres)
```
Aprender a programar não precisa ser chato. O Buggo transforma os fundamentos
da programação em lições curtas, quizzes e desafios que cabem na sua rotina.

COMECE PELA LÓGICA
Antes de qualquer linguagem, você aprende a pensar como um programador:
padrões, sequências, condições e estratégia. Tudo em forma de enigma, sem
código intimidador na primeira tela.

TRILHAS PARA CADA CAMINHO
Depois dos fundamentos, escolha para onde ir: Frontend, Backend, Mobile,
Banco de Dados ou Sistemas. Cada trilha tem lições organizadas em ordem,
para você nunca ficar perdido sobre o próximo passo.

LIÇÕES DE 5 MINUTOS
Defina sua meta diária — 5, 15 ou 30 minutos. O app respeita o seu ritmo e
lembra você de manter a sequência de dias.

APRENDA JOGANDO
Ganhe XP e moedas a cada lição concluída, suba de nível, desbloqueie
conquistas e acompanhe sua posição no ranking. O sistema de vidas mantém o
desafio interessante sem punir quem está aprendendo.

SEM CADASTRO OBRIGATÓRIO
Você pode usar tudo no modo convidado, com o progresso salvo no seu aparelho.
Se quiser sincronizar entre celulares e aparecer no ranking, crie uma conta em
poucos segundos.

FUNCIONA OFFLINE
As lições ficam disponíveis mesmo sem internet.

Comece hoje. Cinco minutos por dia já mudam o jogo.
```

**Categoria:** Educação
**Tags:** educação, programação, aprendizado, lógica
**E-mail de contato:** caspheon@gmail.com

**Política de privacidade:** publique `server/public/privacy.html` junto com o
backend no Vercel e use a URL resultante:
```
https://<seu-projeto>.vercel.app/privacy.html
```
Esse campo é obrigatório e a URL precisa estar no ar antes de enviar para
revisão.

---

## 3. Recursos gráficos

| Item | Arquivo | Status |
|---|---|---|
| Ícone 512×512 | `assets/images/icon_buggo.png` | Pronto (sem canal alfa) |
| Feature graphic 1024×500 | `store/feature_graphic.png` | Pronto |
| Screenshots de celular | `store/screenshots/*.png` (6 imagens, 1080×2400) | Prontos |

O Play exige no mínimo 2 screenshots de celular; 6 é o ideal para a ficha
ficar completa. Screenshots de tablet são opcionais — sem eles, o app
simplesmente não é destacado na aba de tablets.

---

## 4. Segurança de Dados (formulário)

Respostas conferidas contra o código (`server/schema.sql`, `server/api/`,
`server/lib/ai/`, `lib/features/`). Revisadas em 09/09/2026, depois da entrada
do login com Google, das compras no Play, do desafio do dia por IA e dos
anúncios do AdMob — a versão anterior era de 11/08 e ficou incorreta.

### Passo 1 — Visão geral

| Pergunta | Resposta |
|---|---|
| O app coleta ou compartilha os tipos de dados obrigatórios? | **Sim** |
| Todos os dados são criptografados em trânsito? | **Sim** — todo tráfego é HTTPS |
| Você oferece um jeito de o usuário pedir a exclusão dos dados? | **Sim** — por e-mail, descrito na política |

### Passo 2 — Tipos de dados a marcar

O formulário tem categorias fixas. Marque **exatamente** estas sete e nenhuma
outra:

| Categoria do Play | Subtipo | O que é no Buggo |
|---|---|---|
| Informações pessoais | Nome | Nome do perfil, exibido no ranking |
| Informações pessoais | Endereço de e-mail | Login e recuperação de senha |
| Informações pessoais | IDs de usuário | `users.id` e o `google_id` de quem entra pelo Google |
| Informações financeiras | Histórico de compras | Tabela `purchases` |
| Atividade no app | Interações no app | XP, moedas, vidas, sequência, lições concluídas |
| Atividade no app | Outro conteúdo gerado pelo usuário | O código/alternativa respondida no desafio do dia |
| Dispositivo ou outros IDs | ID do dispositivo ou outros IDs | ID de publicidade, usado pelo AdMob |

### Passo 3 — Detalhes de cada tipo

Para cada um, o Play pergunta as mesmas quatro coisas:

| Tipo | Coletado | Compartilhado | Obrigatório? | Finalidades |
|---|---|---|---|---|
| Nome | Sim | Não | **Opcional** | Gerenciamento de contas, Funcionalidade do app |
| Endereço de e-mail | Sim | Não | **Opcional** | Gerenciamento de contas |
| IDs de usuário | Sim | Não | **Opcional** | Gerenciamento de contas, Funcionalidade do app |
| Histórico de compras | Sim | Não | **Opcional** | Funcionalidade do app |
| Interações no app | Sim | Não | **Opcional** | Funcionalidade do app |
| Outro conteúdo gerado pelo usuário | Sim | **Sim** | **Opcional** | Funcionalidade do app |
| ID do dispositivo ou outros IDs | Sim | **Sim** | **Opcional** | **Publicidade ou marketing** |

Em "processado de forma efêmera", responda **não** para todos: tudo isso é
gravado, não usado e descartado na hora.

Tudo é **opcional** porque o app funciona inteiro no modo convidado, sem conta
— e assistir anúncio é escolha do usuário. "Obrigatório" no formulário
significa que o app não funciona sem o dado, o que não é o caso de nenhum.

Os dois **compartilhados** são os que saem para fora:

- **Outro conteúdo gerado pelo usuário** → vai para OpenAI (correção) e
  DeepSeek (geração). Sem nome, e-mail ou id junto: esses serviços não têm como
  saber de quem é a resposta.
- **ID do dispositivo ou outros IDs** → vai para o AdMob. A permissão
  `com.google.android.gms.permission.AD_ID` entra no manifesto de release pelo
  `com.google.android.gms:play-services-ads-api`, conferido no relatório de
  merge. Marque **só** "Publicidade ou marketing" como finalidade: não há
  analytics nem atribuição no projeto.

**Senha não é declarada.** O formulário do Play não tem categoria para
credencial — as opções de "Informações pessoais" vão de nome e e-mail a
telefone e etnia, nenhuma cobre senha. Ela é guardada só como hash bcrypt e
serve exclusivamente para autenticar. Se preferir ser conservador, o encaixe
mais próximo seria "Informações pessoais > Outras informações".

**Fotos → NÃO declare como coletadas.** O app usa a foto só para o avatar, e
a imagem **nunca sai do aparelho** —
`lib/shared/widgets/pixel_avatars.dart:202` lê o arquivo local direto e o
servidor guarda apenas o caminho, não a imagem. Pela definição do Google,
"coleta" é transmissão para fora do dispositivo; então a resposta correta é
não declarar.

A política de privacidade em `server/public/privacy.html` tem que descrever
exatamente estes mesmos itens. O Google reprova quando o formulário e a política
se contradizem — foi por isso que a frase "não usamos os seus dados para
publicidade" saiu de lá.

---

## 5. Demais formulários

**Classificação de conteúdo:** responda o questionário como app educativo.
Sem violência, sem conteúdo sexual, sem drogas, sem apostas, sem conteúdo
gerado por usuário. Resultado esperado: **Livre para todos os públicos**.

**Público-alvo:** se você marcar qualquer faixa abaixo de 13 anos, o app entra
no programa Famílias, que exige revisão mais rígida. Como o cadastro pede
e-mail, o caminho mais simples é declarar **13 anos ou mais**.

**Anúncios:** o app **não contém** anúncios.

**Compras no app:** o app **não tem** compras no app. Veja a ressalva na
seção 7.

**App de notícias / COVID / finanças:** não.

---

## 6. Ordem sugerida no Play Console

1. Criar o app (nome, idioma padrão português, app gratuito).
2. Preencher a ficha da loja com o texto e as imagens da seção 2 e 3.
3. Preencher Segurança de Dados, Classificação de Conteúdo e Público-alvo.
4. Subir o `.aab` em **Teste interno** primeiro, não direto em produção —
   é instantâneo, sem revisão, e você confirma o app instalado pela loja.
5. Depois de validar, promover para produção. A primeira revisão do Google
   costuma levar de alguns dias até 2 semanas para contas novas.

---

## 7. Permissões de fotos e vídeos

O Play bloqueia a versão se o app declarar `READ_MEDIA_IMAGES` sem justificar
"funcionalidade principal". Foto de perfil não é funcionalidade principal de
um app de programação, então justificar seria reprovado.

A solução foi remover a permissão: o `image_picker_android` (0.8.13+17) já usa
o **seletor de fotos do Android** por padrão, que devolve a imagem escolhida
sem exigir acesso à galeria inteira. Testado no emulador — o seletor abre com
"This app can only access the photos you select" e a foto vira avatar
normalmente, sem nenhum pedido de permissão.

Se alguém reintroduzir `READ_MEDIA_IMAGES` no
`android/app/src/main/AndroidManifest.xml`, o erro volta.

---

## 8. Ressalva antes de enviar

A aba **Market** mostra uma seção "Dinheiro real" com preços visíveis
(`R$ 14,90/mês` e pacotes de moedas), marcada como "Em breve". Os cartões são
inertes — sem `onTap`, sem processamento de pagamento — então **não há
violação** da política de Play Billing.

O risco é outro: revisores às vezes reprovam UI que anuncia preço sem produto
funcional. Para a primeira submissão, o mais seguro é ocultar essa seção
(`lib/features/market/presentation/screens/market_screen.dart:300-334`) e
reativá-la quando o Play Billing estiver integrado. É uma decisão sua — se
preferir manter, mantenha o rótulo "Em breve" bem visível, que é o que reduz
a chance de reprovação.
