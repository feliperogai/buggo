# Buggo

Buggo é um aplicativo mobile para aprender programação de forma simples, prática e divertida. A ideia do projeto é transformar o estudo em uma experiência parecida com um jogo, com lições curtas, trilhas de aprendizado, XP, moedas, conquistas e um mascote guiando o usuário.

O app foi pensado para iniciantes, principalmente jovens que estudam pelo celular e têm pouco tempo no dia a dia. As lições são rápidas e progressivas, para ajudar quem nunca programou a começar por lógica e avançar para linguagens como Python.

## O que o app tem

- Onboarding para configurar nome, nível, linguagem e meta diária.
- Trilhas de aprendizado com lições desbloqueadas por progresso.
- Conteúdo de lógica de programação e Python.
- Desafios interativos, quizzes e exercícios de completar código.
- Sistema de XP, moedas, streak e conquistas.
- Perfil do usuário com progresso e avatares.
- Market e tela de troféus.
- Dados salvos localmente no aparelho.

## Tecnologias

- Flutter
- Dart
- Riverpod
- go_router
- Hive

## Como rodar o projeto

Antes de começar, tenha o Flutter instalado na máquina.

1. Clone o repositório:

```bash
git clone https://github.com/caspheon/buggo.git
cd buggo
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Verifique se existe um dispositivo ou emulador disponível:

```bash
flutter devices
```

4. Rode o app:

```bash
flutter run
```

## Rodar testes

```bash
flutter test
```

## Observações

O projeto funciona sem backend. As informações do usuário, progresso e configurações são salvas localmente usando Hive.

## Backend

A API fica em `server/` (Vercel + Neon Postgres) e é publicada só a partir da
branch `main`. Detalhes de deploy, variáveis de ambiente e a configuração do
Google em `server/README.md`.

O app lê `API_BASE_URL` e `GOOGLE_SERVER_CLIENT_ID` do `.env` (veja
`.env.example`). As duas também podem ser passadas na hora do build, e nesse
caso vencem o arquivo:

```bash
flutter build appbundle \
  --dart-define=API_BASE_URL=https://buggo-api.vercel.app \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

Sem nenhum dos dois, o app usa a URL de produção embutida em
`lib/core/config/env_config.dart` — antes ele caía calado no modo convidado.

## Monitor do servidor

- Página: <https://buggo-api.vercel.app/> — estado atual, gráfico de tempo de
  resposta e faixa de disponibilidade
- JSON: `GET /api/health`
- Checagem automática de hora em hora: `.github/workflows/monitor.yml`
