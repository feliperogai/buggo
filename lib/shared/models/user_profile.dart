class UserProfile {
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

  const UserProfile({
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
  });

  UserProfile copyWith({
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
  }) {
    return UserProfile(
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
    );
  }

  Map<String, dynamic> toMap() => {
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
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) => UserProfile(
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
      );

  int get currentLevel => (xp / 100).floor() + 1;
  int get xpToNextLevel => 100 - (xp % 100);
  double get xpProgress => (xp % 100) / 100.0;
}
