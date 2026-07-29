import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/sound_service.dart';
import '../../core/storage/hive_storage.dart';

/// Preferências de som e vibração, persistidas na box `settings` do Hive.
class AppSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;

  const AppSettings({this.soundEnabled = true, this.hapticsEnabled = true});

  AppSettings copyWith({bool? soundEnabled, bool? hapticsEnabled}) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _soundKey = 'soundEnabled';
  static const _hapticsKey = 'hapticsEnabled';

  @override
  AppSettings build() {
    final box = HiveStorage.settings;
    final settings = AppSettings(
      soundEnabled: box.get(_soundKey, defaultValue: true) as bool,
      hapticsEnabled: box.get(_hapticsKey, defaultValue: true) as bool,
    );
    _apply(settings);
    return settings;
  }

  /// Mantém o [SoundService] em sincronia com o estado — ele é um singleton
  /// consultado de dentro de callbacks, onde não há `ref` disponível.
  void _apply(AppSettings settings) {
    SoundService.instance
      ..soundEnabled = settings.soundEnabled
      ..hapticsEnabled = settings.hapticsEnabled;
  }

  void setSoundEnabled(bool value) {
    HiveStorage.settings.put(_soundKey, value);
    state = state.copyWith(soundEnabled: value);
    _apply(state);
    // Toca um som de confirmação ao ligar, para o usuário ouvir o efeito.
    if (value) SoundService.instance.play(Sfx.tap);
  }

  void setHapticsEnabled(bool value) {
    HiveStorage.settings.put(_hapticsKey, value);
    state = state.copyWith(hapticsEnabled: value);
    _apply(state);
    if (value) SoundService.instance.haptic(Haptic.light);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
