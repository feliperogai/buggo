# Efeitos sonoros do Buggo

Todos os sons vêm dos pacotes **[Kenney](https://kenney.nl/assets?q=audio)**
(Interface Sounds, Casino Audio e Music Jingles), licença **CC0** — uso
livre, sem atribuição obrigatória.

Os pacotes só são distribuídos em Ogg Vorbis, que o **iOS não decodifica**
(`AVAudioPlayer` não suporta Vorbis). Por isso os arquivos aqui já estão
convertidos para MP3 mono por `tool/build_sounds.py`.

## O que cada arquivo é

| Arquivo | Origem (Kenney) | Duração | Quando toca |
|---|---|---|---|
| `correct.mp3` | `confirmation_001` | 0,29s | Acertou a resposta / código rodou certo |
| `wrong.mp3` | `error_006` | 0,50s | Errou **sem** perder vida (Buggo+ ativo ou já zerado) |
| `life_lost.mp3` | `error_003` | 0,53s | Errou **e** perdeu uma vida |
| `purchase.mp3` | `confirmation_002` | 0,54s | Compra concluída |
| `coin.mp3` | `chip-lay-1` | 0,17s | Moedas ganhas (0,7s após a fanfarra) |
| `tap.mp3` | `click_001` | 0,10s | Confirmação ao ligar o som nas Configurações |
| `lesson_complete.mp3` | `jingles_STEEL16` | 0,91s | Lição concluída, junto do confete |
| `level_up.mp3` | `jingles_NES00` | 1,76s | Subiu de nível (1,4s após a fanfarra) |
| `achievement.mp3` | `jingles_SAX07` | 1,74s | Conquista desbloqueada — **ainda não plugado** |
| `streak.mp3` | `jingles_HIT00` | 0,28s | Sequência avançou (1,4s após a fanfarra) |

Total: **~85 KB**.

> `achievement.mp3` está pronto mas sem ponto de chamada: as conquistas são
> calculadas por predicado em `data/content/achievements_catalog.dart`, então
> não existe um evento de "desbloqueou agora" para disparar o som. Quando
> esse evento existir, é só chamar `SoundService.instance.play(Sfx.achievement)`.

## Só um som por evento

Erro e perda de vida acontecem juntos, mas tocar os dois embola o áudio —
por isso `_playErrorSound()` em `challenge_screen.dart` escolhe **um**: se a
vida foi descontada toca `life_lost`, senão toca `wrong`. Pelo mesmo motivo
as celebrações secundárias (`coin`, `level_up`, `streak`) entram com atraso,
depois que a fanfarra termina.

## Volume

Normalizado por categoria em `tool/build_sounds.py`: efeitos que tocam o
tempo todo ficam mais baixos (pico 0,40–0,55) que as celebrações, que são
pontuais (0,75–0,85). Para reequilibrar, mexa nos valores do `MAPPING` e
rode o script de novo.

## Trocar um som

1. Baixe o pacote da Kenney e coloque os `.ogg` nesta pasta.
2. Ajuste o `MAPPING` em `tool/build_sounds.py`.
3. Rode `py tool/build_sounds.py` (precisa de `soundfile`, `lameenc`,
   `numpy`). Ele converte, normaliza e **apaga os `.ogg` que sobrarem**.

Se um som não tocar, o motivo aparece no console como
`SoundService: som "x.mp3" indisponível (...)` — o app continua funcionando
normalmente sem ele.

O usuário pode desligar tudo em **Configurações › Som e vibração**.
