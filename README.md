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
