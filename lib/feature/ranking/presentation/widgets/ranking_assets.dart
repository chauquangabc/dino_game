import '../../domain/ranking_entry.dart';

abstract final class RankingAssets {
  static const root = 'assets/rank';
  static const panel = '$root/panel-blank.webp';
  static const titleHeader = '$root/title-header-blank.webp';
  static const titleText = '$root/title-text-dino-rankings.webp';
  static const tabActive = '$root/button-active-blank.webp';
  static const tabInactive = '$root/button-inactive-blank.webp';
  static const row = '$root/row-blank.webp';
  static const avatarFrame = '$root/avatar-frame.webp';
  static const levelBadge = '$root/level-badge-blank.webp';

  static String rank(int rank) => switch (rank) {
    1 => '$root/rank-gold-blank.webp',
    2 => '$root/rank-silver-blank.webp',
    3 => '$root/rank-bronze-blank.webp',
    _ => '$root/rank-stone-blank.webp',
  };

  static String titleBadge(RankingTitleColor color) =>
      '$root/title-badge-${color.name}-blank.webp';
}
