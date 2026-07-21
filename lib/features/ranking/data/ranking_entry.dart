class RankingEntry {
  final String id;
  final String name;
  final int avatarIndex;
  final int xp;
  final int streak;

  const RankingEntry({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.xp,
    required this.streak,
  });

  int get level => (xp / 100).floor() + 1;
}
