import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String userBox = 'user_box';
  static const String progressBox = 'progress_box';
  static const String settingsBox = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(userBox);
    await Hive.openBox(progressBox);
    await Hive.openBox(settingsBox);
  }

  static Box get user => Hive.box(userBox);
  static Box get progress => Hive.box(progressBox);
  static Box get settings => Hive.box(settingsBox);
}
