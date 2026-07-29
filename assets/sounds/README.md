# Efeitos sonoros do Buggo

Coloque os arquivos **com exatamente estes nomes** nesta pasta. O app
funciona normalmente sem eles — quem não existir simplesmente não toca
(o `SoundService` marca como indisponível e segue em frente).

| Arquivo | Quando toca | Onde no código |
|---|---|---|
| `correct.mp3` | Acertou a resposta / código rodou certo | `challenge_screen.dart` |
| `wrong.mp3` | Errou a resposta / erro no código | `challenge_screen.dart` |
| `lesson_complete.mp3` | Lição concluída, junto do confete | `success_screen.dart` |
| `life_lost.mp3` | Perdeu uma vida de verdade | `challenge_screen.dart` |
| `coin.mp3` | Ganhou moedas (0,7s após a fanfarra) | `success_screen.dart` |
| `purchase.mp3` | Compra concluída | `market_screen.dart`, `hearts_screen.dart`, `lives_recovery_card.dart` |
| `level_up.mp3` | Subiu de nível | *(a plugar)* |
| `achievement.mp3` | Conquista desbloqueada | *(a plugar)* |
| `streak.mp3` | Sequência avançou | *(a plugar)* |
| `tap.mp3` | Confirmação ao ligar o som nas Configurações | `settings_provider.dart` |

## Onde baixar (tudo CC0, uso livre e sem atribuição obrigatória)

**[kenney.nl/assets/interface-sounds](https://kenney.nl/assets/interface-sounds)**
— melhor opção para a maioria. Pacote com ~100 sons curtos de UI. Sugestões:

- `correct.mp3` → `confirmation_001.ogg` ou `question_002.ogg`
- `wrong.mp3` → `error_006.ogg` ou `error_008.ogg`
- `purchase.mp3` → `confirmation_002.ogg`
- `tap.mp3` → `click_001.ogg` (bem discreto)
- `life_lost.mp3` → `error_003.ogg` (mais grave/seco)

**[kenney.nl/assets/casino-audio](https://kenney.nl/assets/casino-audio)**
— para `coin.mp3`, use `chip_lay_001.ogg` ou similar.

**[kenney.nl/assets/music-jingles](https://kenney.nl/assets/music-jingles)**
— jingles curtos para os momentos de celebração:

- `lesson_complete.mp3` → `jingles_STEEL16.ogg` (ou qualquer "win")
- `level_up.mp3` → `jingles_PIZZA00.ogg`
- `achievement.mp3` → `jingles_SAX07.ogg`
- `streak.mp3` → um jingle curto de 1s

Alternativas: [mixkit.co/free-sound-effects/game](https://mixkit.co/free-sound-effects/game),
[pixabay.com/sound-effects](https://pixabay.com/sound-effects/).

## Recomendações técnicas

- **Formato**: `.mp3` (o nome do arquivo na tabela precisa bater). Os
  pacotes da Kenney vêm em `.ogg`/`.wav` — converta e renomeie.
- **Duração**: 0,2–0,5s para os efeitos de UI; até 2s para as celebrações.
  Som longo demais atrapalha o ritmo do quiz.
- **Volume**: normalize tudo no mesmo nível, e deixe os efeitos de acerto/
  erro um pouco mais baixos — eles tocam o tempo todo.
- **Tamanho**: mono, 44.1kHz, ~64kbps já basta. Cada arquivo deve ficar
  abaixo de ~30KB para não inchar o APK.

## Como testar

Depois de colocar os arquivos, rode `flutter run`. Não precisa mexer em
código: o `SoundService` resolve pelo nome. Se um som não tocar, o motivo
aparece no console como `SoundService: som "x.mp3" indisponível (...)`.

O usuário pode desligar tudo em **Configurações › Som e vibração**.
