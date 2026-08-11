import 'dart:async';

import 'ads/ads_service.dart';
import 'audio/sound_service.dart';
import 'config/env_config.dart';
import 'storage/hive_storage.dart';

/// Local/network setup (Hive, .env, áudio). Runs after the first frame so
/// the splash animation is what the user sees first — not a static native
/// icon waiting on this to finish.
Future<void> bootstrapApp() async {
  await HiveStorage.init();
  await EnvConfig.load();
  await SoundService.instance.init();
  // Sem await: o SDK de anúncios leva alguns segundos para subir e nada na
  // primeira tela depende dele. Segurar o boot por causa de anúncio seria
  // atrasar o app inteiro por uma função opcional.
  unawaited(AdsService.instance.initialize());
}
