import 'package:flutter/foundation.dart';

import 'audio/sound_service.dart';
import 'config/env_config.dart';
import 'notifications/notification_service.dart';
import 'storage/hive_storage.dart';

/// Local/network setup (Hive, .env, áudio). Runs after the first frame so
/// the splash animation is what the user sees first — not a static native
/// icon waiting on this to finish.
///
/// Cada etapa é isolada: uma que falhe (arquivo de áudio ausente, `.env` não
/// embutido na build, box do Hive corrompida) não pode segurar as outras nem
/// travar o app na splash, que é o que acontecia quando qualquer exceção
/// aqui subia para quem esperava este Future.
Future<void> bootstrapApp() async {
  await _step('Hive', HiveStorage.init);
  await _step('.env', EnvConfig.load);
  await _step('áudio', SoundService.instance.init);
  // Só cria o canal e liga o plugin. Nada é agendado aqui: o agendamento
  // depende do perfil, e quem faz isso é a splash depois de carregá-lo.
  await _step('notificações', NotificationService.instance.init);

  debugPrint('bootstrap: API em ${EnvConfig.apiBaseUrl} '
      '(origem: ${EnvConfig.apiBaseUrlSource.label})');
}

Future<void> _step(String name, Future<void> Function() run) async {
  try {
    await run();
  } catch (e, stack) {
    debugPrint('bootstrap: etapa "$name" falhou: $e');
    debugPrintStack(stackTrace: stack);
  }
}
