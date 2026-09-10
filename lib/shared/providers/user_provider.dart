import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../../core/storage/hive_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/google_sign_in_service.dart';
import 'settings_provider.dart';

class UserNotifier extends Notifier<UserProfile?> {
  static const int lifeCoinCost = 50;
  static const Duration monthlyPlanDuration = Duration(days: 30);
  static const int streakFreezeCoinCost = 200;

  final _authRepository = AuthRepository();
  final _googleSignIn = GoogleSignInService();

  @override
  UserProfile? build() {
    final loaded = _loadFromStorage();
    if (loaded == null) return null;
    final refreshed = _refreshLives(loaded);
    if (!identical(refreshed, loaded)) {
      HiveStorage.user.put('profile', refreshed.toMap());
    }
    return refreshed;
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
    if (profile.id != null) {
      unawaited(_authRepository.pushProfile(profile));
    }
  }

  /// Adopts the account returned by the backend after a successful
  /// login/signup.
  ///
  /// On **signup** the account is brand new, so everything the guest already
  /// earned on this device is carried into it (and pushed to the server by
  /// [saveProfile]) — otherwise "criar conta para guardar o progresso" would
  /// silently throw that progress away.
  ///
  /// On **login** the server profile wins untouched: that account has its own
  /// history, and overwriting it with local guest data would corrupt it.
  void adoptServerProfile(
    UserProfile account, {
    required bool carryGuestProgress,
  }) {
    final guest = state;
    if (!carryGuestProgress || guest == null || !guest.isGuest) {
      saveProfile(account);
      return;
    }
    saveProfile(account.copyWith(
      language: guest.language,
      level: guest.level,
      dailyGoalMinutes: guest.dailyGoalMinutes,
      xp: guest.xp,
      coins: guest.coins,
      streak: guest.streak,
      lastStudyDate: guest.lastStudyDate,
      completedLessons: guest.completedLessons,
      unlockedAchievements: guest.unlockedAchievements,
      avatarIndex: guest.avatarIndex,
      customPhotoPath: guest.customPhotoPath,
      lives: guest.lives,
      lastLifeLostAt: guest.lastLifeLostAt,
      unlimitedLivesUntil: guest.unlimitedLivesUntil,
      streakFreezes: guest.streakFreezes,
    ));
  }

  /// Clears the local profile and server session (if any), leaving the app
  /// ready to show onboarding again. Does not touch the progress box: sair da
  /// conta não apaga o que a pessoa já estudou, e não existe mais nenhuma
  /// ação no app que apague.
  Future<void> logout() async {
    await _authRepository.logout();
    // Sem isto o Google reentra sozinho na mesma conta no próximo login, sem
    // mostrar o seletor — quem quis trocar de conta não consegue.
    await _googleSignIn.signOut();
    await HiveStorage.user.clear();
    state = null;
  }

  /// Restores lives to full once 24h have passed since the first loss, or
  /// keeps them full while a Buggo+ subscription is active. Returns the same
  /// instance (no-op) when nothing needs to change.
  UserProfile _refreshLives(UserProfile profile) {
    if (profile.lastLifeLostAt == null) return profile;

    if (profile.hasUnlimitedLives) {
      return profile.copyWith(
        lives: UserProfile.maxLives,
        clearLastLifeLostAt: true,
      );
    }

    final target = profile.lastLifeLostAt!.add(const Duration(hours: 24));
    if (!DateTime.now().isBefore(target)) {
      return profile.copyWith(
        lives: UserProfile.maxLives,
        clearLastLifeLostAt: true,
      );
    }

    return profile;
  }

  /// Re-checks the 24h refill timer. Safe to call whenever a lives-related
  /// screen is opened, since it is a no-op unless the timer has elapsed.
  void refreshLives() {
    if (state == null) return;
    final updated = _refreshLives(state!);
    if (!identical(updated, state)) {
      saveProfile(updated);
    }
  }

  /// Called when the user answers a question incorrectly. Ignored while a
  /// Buggo+ subscription is active.
  void loseLife() {
    if (state == null) return;
    final profile = _refreshLives(state!);
    if (profile.hasUnlimitedLives || profile.lives <= 0) {
      if (!identical(profile, state)) saveProfile(profile);
      return;
    }
    final updated = profile.copyWith(
      lives: profile.lives - 1,
      lastLifeLostAt: profile.lastLifeLostAt ?? DateTime.now(),
    );
    saveProfile(updated);
  }

  /// Spends coins to recover a single life. Returns false (no changes made)
  /// if the user can't afford it or already has full/unlimited lives.
  bool buyLife() => buyLives(1);

  /// Spends coins to recover [count] lives (capped at the max). Returns
  /// false if the user can't afford it or already has full/unlimited lives.
  bool buyLives(int count) {
    if (state == null) return false;
    final profile = _refreshLives(state!);
    if (profile.hasUnlimitedLives || profile.lives >= UserProfile.maxLives) {
      return false;
    }
    final missing = UserProfile.maxLives - profile.lives;
    final toBuy = count > missing ? missing : count;
    final cost = toBuy * lifeCoinCost;
    if (profile.coins < cost) return false;

    final newLives = profile.lives + toBuy;
    final updated = profile.copyWith(
      coins: profile.coins - cost,
      lives: newLives,
      clearLastLifeLostAt: newLives >= UserProfile.maxLives,
    );
    saveProfile(updated);
    return true;
  }

  /// Já assistiu ao anúncio de vidas hoje?
  ///
  /// O dia vira no fuso de São Paulo, e não em UTC: rodando em UTC o limite
  /// zeraria às 21h, no meio da noite de quem está jogando.
  bool get usedAdRefillToday {
    final last = state?.lastAdRefillAt;
    if (last == null) return false;
    return _brazilDay(last) == _brazilDay(DateTime.now());
  }

  /// Assistir anúncio vale a pena agora? Falso com vidas cheias, com Buggo+
  /// ativo (que já dá vidas ilimitadas) ou depois do anúncio do dia.
  bool get canWatchAdForLives {
    final profile = state;
    if (profile == null) return false;
    if (profile.hasUnlimitedLives) return false;
    if (profile.lives >= UserProfile.maxLives) return false;
    return !usedAdRefillToday;
  }

  /// Recarrega todas as vidas depois de um anúncio assistido até o fim.
  ///
  /// Chamado só pelo callback de recompensa do SDK. Devolve false quando o
  /// limite do dia já foi usado — a checagem é repetida aqui porque entre
  /// carregar o anúncio e terminar de assistir dá tempo de o estado mudar.
  bool refillLivesFromAd() {
    if (!canWatchAdForLives) return false;
    saveProfile(state!.copyWith(
      lives: UserProfile.maxLives,
      clearLastLifeLostAt: true,
      lastAdRefillAt: DateTime.now(),
    ));
    return true;
  }

  /// Data no fuso de Brasília, sem depender de pacote de timezone: o país
  /// está em UTC-3 o ano todo desde o fim do horário de verão.
  static String _brazilDay(DateTime instant) {
    final local = instant.toUtc().subtract(const Duration(hours: 3));
    return '${local.year}-${local.month}-${local.day}';
  }

  /// Spends coins to refill all missing lives at once. Returns false if the
  /// user can't afford it or already has full/unlimited lives.
  bool refillAllLives() {
    if (state == null) return false;
    final profile = _refreshLives(state!);
    final missing = UserProfile.maxLives - profile.lives;
    if (missing <= 0) return false;
    return buyLives(missing);
  }

  /// Spends coins to buy one Streak Freeze, up to [UserProfile.maxStreakFreezes].
  bool buyStreakFreeze() {
    if (state == null) return false;
    if (state!.streakFreezes >= UserProfile.maxStreakFreezes) return false;
    if (state!.coins < streakFreezeCoinCost) return false;

    saveProfile(state!.copyWith(
      coins: state!.coins - streakFreezeCoinCost,
      streakFreezes: state!.streakFreezes + 1,
    ));
    return true;
  }

  /// Activates (or extends) the Buggo+ plan, granting unlimited lives for
  /// 30 days. Buggo+ is a real-money subscription (see the Market screen),
  /// so this does not touch coins — call it once a purchase is confirmed
  /// by the payment provider (e.g. an IAP callback or a Supabase webhook).
  void activateBuggoPlus() {
    if (state == null) return;
    final profile = _refreshLives(state!);
    final base =
        profile.hasUnlimitedLives ? profile.unlimitedLivesUntil! : DateTime.now();
    saveProfile(profile.copyWith(
      unlimitedLivesUntil: base.add(monthlyPlanDuration),
      lives: UserProfile.maxLives,
      clearLastLifeLostAt: true,
    ));
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

  void updateLanguage(String language) {
    if (state == null) return;
    saveProfile(state!.copyWith(language: language));
  }

  void completeLesson(String lessonId, {required int xp, required int coins}) {
    if (state == null) return;
    if (state!.completedLessons.contains(lessonId)) return;
    final now = DateTime.now();
    final lastDate = state!.lastStudyDate;
    final (newStreak, freezesUsed) =
        _resolveStreak(lastDate, now, state!.streak, state!.streakFreezes);
    final updated = state!.copyWith(
      xp: state!.xp + xp,
      coins: state!.coins + coins,
      streak: newStreak,
      streakFreezes: state!.streakFreezes - freezesUsed,
      lastStudyDate: now,
      completedLessons: [...state!.completedLessons, lessonId],
    );
    saveProfile(updated);
    // Estudou hoje: o lembrete de hoje perde o sentido e o de sequência em
    // risco viraria mentira. O plano é refeito com a sequência nova.
    unawaited(ref.read(settingsProvider.notifier).syncReminders());
  }

  /// Computes the new streak and how many Streak Freezes get consumed to
  /// bridge missed days. If there aren't enough freezes to cover every
  /// missed day, the streak resets and no freezes are spent.
  (int, int) _resolveStreak(
    DateTime? lastDate,
    DateTime now,
    int currentStreak,
    int freezesAvailable,
  ) {
    if (lastDate == null) return (1, 0);
    final diff = now.difference(lastDate).inDays;
    if (diff == 0) return (currentStreak, 0);
    if (diff == 1) return (currentStreak + 1, 0);

    final missedDays = diff - 1;
    if (freezesAvailable >= missedDays) {
      return (currentStreak + 1, missedDays);
    }
    return (1, 0);
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
