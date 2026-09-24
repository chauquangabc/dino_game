enum RankingTitleColor { blue, green, orange, purple, red }

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.displayName,
    required this.avatarAsset,
    required this.completedLevel,
    required this.totalScore,
    required this.weeklyScore,
    required this.weeklyCompletedLevels,
    required this.title,
    required this.titleColor,
    this.isCurrentUser = false,
  });

  final int rank;
  final String displayName;
  final String avatarAsset;
  final int completedLevel;
  final int totalScore;
  final int weeklyScore;
  final int weeklyCompletedLevels;
  final String title;
  final RankingTitleColor titleColor;
  final bool isCurrentUser;
}
