import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/sound_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/hive_storage.dart';
import 'user_provider.dart';

/// Preferências de som, vibração e lembretes, persistidas na box `settings`
/// do Hive.
class AppSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// Lembretes de estudo. Começam desligados de propósito: quem instala um
  /// app não pediu para ser notificado, e no Android 13+ a permissão só é
  /// pedida quando a pessoa liga isto.
  final bool remindersEnabled;

  /// Hora do lembrete diário, em 24h.
  final int reminderHour;

  const AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.remindersEnabled = false,
    this.reminderHour = defaultReminderHour,
  });

  static const int defaultReminderHour = 19;

  /// As opções oferecidas na tela. Nada de madrugada, e nada às 21h, que é a
  /// hora reservada ao aviso de sequência em risco.
  static const List<int> reminderHourOptions = [8, 12, 15, 18, 19, 20];

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? remindersEnabled,
    int? reminderHour,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _soundKey = 'soundEnabled';
  static const _hapticsKey = 'hapticsEnabled';
  static const _remindersKey = 'remindersEnabled';
  static const _reminderHourKey = 'reminderHour';

  @override
  AppSettings build() {
    final box = HiveStorage.settings;
    final settings = AppSettings(
      soundEnabled: box.get(_soundKey, defaultValue: true) as bool,
      hapticsEnabled: box.get(_hapticsKey, defaultValue: true) as bool,
      remindersEnabled: box.get(_remindersKey, defaultValue: false) as bool,
      reminderHour: box.get(_reminderHourKey,
          defaultValue: AppSettings.defaultReminderHour) as int,
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

  /// Liga ou desliga os lembretes.
  ///
  /// Devolve `false` quando a pessoa recusou a permissão do sistema — nesse
  /// caso a preferência não é ligada, para a tela não mostrar um interruptor
  /// aceso que não notifica nada.
  Future<bool> setRemindersEnabled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return false;
    }
    HiveStorage.settings.put(_remindersKey, value);
    state = state.copyWith(remindersEnabled: value);
    await syncReminders();
    if (value) SoundService.instance.play(Sfx.tap);
    return true;
  }

  Future<void> setReminderHour(int hour) async {
    HiveStorage.settings.put(_reminderHourKey, hour);
    state = state.copyWith(reminderHour: hour);
    await syncReminders();
  }

  /// Reagenda os lembretes com o estado atual do perfil.
  ///
  /// `ref.read` e não `watch`: chamar isto de dentro do próprio notifier
  /// durante o `build` criaria dependência circular com o perfil, que por sua
  /// vez chama este método ao concluir uma lição.
  Future<void> syncReminders() async {
    final user = ref.read(userProvider);
    await NotificationService.instance.sync(
      enabled: state.remindersEnabled,
      hour: state.reminderHour,
      streak: user?.streak ?? 0,
      lastStudyDate: user?.lastStudyDate,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
