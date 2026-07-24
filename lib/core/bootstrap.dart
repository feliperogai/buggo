import 'config/env_config.dart';
import 'storage/hive_storage.dart';

/// Local/network setup (Hive, .env). Runs after the first frame so the
/// splash animation is what the user sees first — not a static native icon
/// waiting on this to finish.
Future<void> bootstrapApp() async {
  await HiveStorage.init();
  await EnvConfig.load();
}
