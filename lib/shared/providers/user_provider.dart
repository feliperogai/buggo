import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../../core/storage/hive_storage.dart';

class UserNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    return _loadFromStorage();
  }

  UserProfile? _loadFromStorage() {
    final box = HiveStorage.user;
    final data = box.get('profile');
    if (data == null) return null;
    return UserProfile.fromMap(data as Map);
  }

  void saveProfile(UserProfile profile) {
    HiveStorage.user.put('profile', profile.toMap());
    state = profile;
  }

  void addXp(int amount) {
    if (state == null) return;
    final updated = state!.copyWith(xp: state!.xp + amount);
    saveProfile(updated);
  }

  void addCoins(int amount) {
    if (state == null) return;
    final updated = state!.copyWith(coins: state!.coins + amount);
    saveProfile(updated);
  }

  void completeLesson(String lessonId, {required int xp, required int coins}) {
    if (state == null) return;
    if (state!.completedLessons.contains(lessonId)) return;
    final now = DateTime.now();
    final lastDate = state!.lastStudyDate;
    final newStreak = _calculateStreak(lastDate, now, state!.streak);
    final updated = state!.copyWith(
      xp: state!.xp + xp,
      coins: state!.coins + coins,
      streak: newStreak,
      lastStudyDate: now,
      completedLessons: [...state!.completedLessons, lessonId],
    );
    saveProfile(updated);
  }

  int _calculateStreak(DateTime? lastDate, DateTime now, int currentStreak) {
    if (lastDate == null) return 1;
    final diff = now.difference(lastDate).inDays;
    if (diff == 0) return currentStreak;
    if (diff == 1) return currentStreak + 1;
    return 1;
  }

  void updateAvatar(int index, {String? photoPath, bool clearPhoto = false}) {
    if (state == null) return;
    saveProfile(state!.copyWith(
      avatarIndex: index,
      customPhotoPath: photoPath,
      clearPhoto: clearPhoto,
    ));
  }

  bool isLessonCompleted(String lessonId) {
    return state?.completedLessons.contains(lessonId) ?? false;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserProfile?>(
  UserNotifier.new,
);

final hasProfileProvider = Provider<bool>((ref) {
  return ref.watch(userProvider) != null;
});
