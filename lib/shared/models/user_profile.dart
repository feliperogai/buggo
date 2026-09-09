class UserProfile {
  static const int maxLives = 5;
  static const int maxStreakFreezes = 2;

  /// Server account id (Neon `users.id`), or null for a guest profile that
  /// only exists locally.
  final String? id;
  final String? email;
  final String name;
  final String language;
  final String level;
  final int dailyGoalMinutes;
  final int xp;
  final int coins;
  final int streak;
  final DateTime? lastStudyDate;
  final List<String> completedLessons;
  final List<String> unlockedAchievements;
  final int avatarIndex; // which pixel art avatar (0-5)
  final String? customPhotoPath; // path to user's own photo
  final int lives;
  final DateTime? lastLifeLostAt; // null while lives are full
  final DateTime? unlimitedLivesUntil; // Buggo+ monthly plan expiry
  final int streakFreezes;

  /// Quando o usuário assistiu ao último anúncio que recarregou as vidas.
  /// Fica no perfil (e não só no aparelho) porque o limite é diário: guardado
  /// local, bastava limpar os dados do app para assistir de novo.
  final DateTime? lastAdRefillAt;

  const UserProfile({
    this.id,
    this.email,
    required this.name,
    required this.language,
    required this.level,
    required this.dailyGoalMinutes,
    this.xp = 0,
    this.coins = 0,
    this.streak = 0,
    this.lastStudyDate,
    this.completedLessons = const [],
    this.unlockedAchievements = const [],
    this.avatarIndex = 0,
    this.customPhotoPath,
    this.lives = maxLives,
    this.lastLifeLostAt,
    this.unlimitedLivesUntil,
    this.streakFreezes = 0,
    this.lastAdRefillAt,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? language,
    String? level,
    int? dailyGoalMinutes,
    int? xp,
    int? coins,
    int? streak,
    DateTime? lastStudyDate,
    List<String>? completedLessons,
    List<String>? unlockedAchievements,
    int? avatarIndex,
    String? customPhotoPath,
    bool clearPhoto = false,
    int? lives,
    DateTime? lastLifeLostAt,
    bool clearLastLifeLostAt = false,
    DateTime? unlimitedLivesUntil,
    int? streakFreezes,
    DateTime? lastAdRefillAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      language: language ?? this.language,
      level: level ?? this.level,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streak: streak ?? this.streak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      completedLessons: completedLessons ?? this.completedLessons,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      customPhotoPath:
          clearPhoto ? null : (customPhotoPath ?? this.customPhotoPath),
      lives: lives ?? this.lives,
      lastLifeLostAt: clearLastLifeLostAt
          ? null
          : (lastLifeLostAt ?? this.lastLifeLostAt),
      unlimitedLivesUntil: unlimitedLivesUntil ?? this.unlimitedLivesUntil,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      lastAdRefillAt: lastAdRefillAt ?? this.lastAdRefillAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'language': language,
        'level': level,
        'dailyGoalMinutes': dailyGoalMinutes,
        'xp': xp,
        'coins': coins,
        'streak': streak,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'completedLessons': completedLessons,
        'unlockedAchievements': unlockedAchievements,
        'avatarIndex': avatarIndex,
        'customPhotoPath': customPhotoPath,
        'lives': lives,
        'lastLifeLostAt': lastLifeLostAt?.toIso8601String(),
        'unlimitedLivesUntil': unlimitedLivesUntil?.toIso8601String(),
        'streakFreezes': streakFreezes,
        'lastAdRefillAt': lastAdRefillAt?.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) => UserProfile(
        id: map['id'] as String?,
        email: map['email'] as String?,
        name: map['name'] as String? ?? '',
        language: map['language'] as String? ?? 'logic',
        level: map['level'] as String? ?? 'adult',
        dailyGoalMinutes: map['dailyGoalMinutes'] as int? ?? 15,
        xp: map['xp'] as int? ?? 0,
        coins: map['coins'] as int? ?? 0,
        streak: map['streak'] as int? ?? 0,
        lastStudyDate: map['lastStudyDate'] != null
            ? DateTime.tryParse(map['lastStudyDate'] as String)
            : null,
        completedLessons:
            (map['completedLessons'] as List?)?.cast<String>() ?? [],
        unlockedAchievements:
            (map['unlockedAchievements'] as List?)?.cast<String>() ?? [],
        avatarIndex: map['avatarIndex'] as int? ?? 0,
        customPhotoPath: map['customPhotoPath'] as String?,
        lives: map['lives'] as int? ?? maxLives,
        lastLifeLostAt: map['lastLifeLostAt'] != null
            ? DateTime.tryParse(map['lastLifeLostAt'] as String)
            : null,
        unlimitedLivesUntil: map['unlimitedLivesUntil'] != null
            ? DateTime.tryParse(map['unlimitedLivesUntil'] as String)
            : null,
        streakFreezes: map['streakFreezes'] as int? ?? 0,
        lastAdRefillAt: map['lastAdRefillAt'] != null
            ? DateTime.tryParse(map['lastAdRefillAt'] as String)
            : null,
      );

  bool get isGuest => id == null;

  int get currentLevel => (xp / 100).floor() + 1;
  int get xpToNextLevel => 100 - (xp % 100);
  double get xpProgress => (xp % 100) / 100.0;

  bool get hasUnlimitedLives =>
      unlimitedLivesUntil != null &&
      unlimitedLivesUntil!.isAfter(DateTime.now());

  bool get canPlay => hasUnlimitedLives || lives > 0;

  /// Time remaining until all lives are automatically restored, or null if
  /// lives are already full (no countdown running).
  Duration? get timeUntilNextLife {
    if (lastLifeLostAt == null) return null;
    final target = lastLifeLostAt!.add(const Duration(hours: 24));
    final now = DateTime.now();
    if (!now.isBefore(target)) return Duration.zero;
    return target.difference(now);
  }
}
