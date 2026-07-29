import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Efeitos sonoros do app. O arquivo correspondente vai em
/// `assets/sounds/` — veja `assets/sounds/README.md` para onde baixar cada
/// um. Se o arquivo não existir, o som simplesmente não toca (o app segue
/// funcionando normalmente).
enum Sfx {
  /// Resposta certa no quiz.
  correct('correct.mp3'),

  /// Resposta errada no quiz.
  wrong('wrong.mp3'),

  /// Lição concluída — toca junto do confete na tela de sucesso.
  lessonComplete('lesson_complete.mp3'),

  /// Perdeu uma vida.
  lifeLost('life_lost.mp3'),

  /// Ganhou moedas.
  coin('coin.mp3'),

  /// Compra concluída no Market / tela de vidas.
  purchase('purchase.mp3'),

  /// Subiu de nível.
  levelUp('level_up.mp3'),

  /// Conquista desbloqueada.
  achievement('achievement.mp3'),

  /// Sequência (streak) avançou.
  streak('streak.mp3'),

  /// Toque genérico em botão.
  tap('tap.mp3');

  const Sfx(this.file);

  final String file;

  String get assetPath => 'sounds/$file';
}

/// Intensidade do retorno tátil, para não espalhar `HapticFeedback` cru
/// pelas telas e poder desligar tudo de uma vez nas Configurações.
enum Haptic { light, medium, heavy, selection }

/// Toca os efeitos sonoros e dispara os haptics do app.
///
/// Pontos importantes:
/// - Um [AudioPlayer] por efeito, em `PlayerMode.lowLatency`, para o som de
///   acerto/erro sair no instante do toque em vez de com atraso.
/// - Nada aqui pode derrubar a UI: se o asset faltar ou o áudio falhar, o
///   erro é engolido e só aparece no console em debug.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final Map<Sfx, AudioPlayer> _players = {};

  /// Efeitos ligados/desligados. Controlado pelas Configurações.
  bool soundEnabled = true;

  /// Haptics ligados/desligados. Controlado pelas Configurações.
  bool hapticsEnabled = true;

  /// Efeitos que ficaram indisponíveis (asset ausente, formato inválido).
  /// Uma vez marcados, não tentamos tocar de novo.
  final Set<Sfx> _unavailable = {};

  bool _initialized = false;

  /// Prepara os players. Chamado no bootstrap; seguro chamar mais de uma vez.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Efeitos curtos não devem interromper música de outros apps nem
      // roubar o foco de áudio do sistema.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('SoundService: falha ao configurar o contexto de áudio: $e');
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!soundEnabled || _unavailable.contains(sfx)) return;
    try {
      final player = _players.putIfAbsent(
        sfx,
        () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
      );
      await player.stop();
      await player.play(AssetSource(sfx.assetPath));
    } catch (e) {
      // Provavelmente o arquivo ainda não foi adicionado em assets/sounds/.
      // Marca como indisponível para não tentar (e logar) a cada toque.
      _unavailable.add(sfx);
      debugPrint('SoundService: som "${sfx.file}" indisponível ($e)');
    }
  }

  void haptic(Haptic type) {
    if (!hapticsEnabled) return;
    switch (type) {
      case Haptic.light:
        HapticFeedback.lightImpact();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.heavy:
        HapticFeedback.heavyImpact();
      case Haptic.selection:
        HapticFeedback.selectionClick();
    }
  }

  /// Atalho para os casos em que som e vibração andam juntos.
  void playWithHaptic(Sfx sfx, Haptic type) {
    play(sfx);
    haptic(type);
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
