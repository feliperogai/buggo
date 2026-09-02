import 'package:buggo/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um convidado que joga e depois cria conta não pode perder o progresso —
/// antes, o perfil vindo do servidor (zerado) substituía o local inteiro.
/// Aqui só o merge é exercitado; a gravação no Hive fica para o app.
UserProfile merge(UserProfile account, UserProfile guest) => account.copyWith(
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
    );

void main() {
  final guest = UserProfile(
    name: 'Convidado',
    language: 'python',
    level: 'teen',
    dailyGoalMinutes: 30,
    xp: 480,
    coins: 120,
    streak: 7,
    completedLessons: const ['l1', 'l2', 'l3'],
    unlockedAchievements: const ['a1'],
    avatarIndex: 3,
    lives: 4,
    streakFreezes: 1,
    lastStudyDate: DateTime(2026, 8, 30),
  );

  final freshAccount = UserProfile(
    id: 'uuid-novo',
    email: 'felipe@exemplo.com',
    name: 'Felipe',
    language: 'logic',
    level: 'adult',
    dailyGoalMinutes: 15,
  );

  test('o perfil de convidado é reconhecido como convidado', () {
    expect(guest.isGuest, isTrue);
    expect(freshAccount.isGuest, isFalse);
  });

  test('criar conta carrega o progresso do convidado', () {
    final merged = merge(freshAccount, guest);
    expect(merged.xp, 480);
    expect(merged.coins, 120);
    expect(merged.streak, 7);
    expect(merged.completedLessons, ['l1', 'l2', 'l3']);
    expect(merged.unlockedAchievements, ['a1']);
    expect(merged.lives, 4);
    expect(merged.streakFreezes, 1);
    expect(merged.language, 'python');
    expect(merged.dailyGoalMinutes, 30);
    expect(merged.lastStudyDate, DateTime(2026, 8, 30));
  });

  test('a identidade da conta vem do servidor, não do convidado', () {
    final merged = merge(freshAccount, guest);
    expect(merged.id, 'uuid-novo');
    expect(merged.email, 'felipe@exemplo.com');
    expect(merged.name, 'Felipe');
    expect(merged.isGuest, isFalse);
  });

  test('o merge sobrevive à ida e volta pelo toMap/fromMap do Hive', () {
    final merged = merge(freshAccount, guest);
    final restored = UserProfile.fromMap(merged.toMap());
    expect(restored.xp, merged.xp);
    expect(restored.id, merged.id);
    expect(restored.completedLessons, merged.completedLessons);
  });
}
