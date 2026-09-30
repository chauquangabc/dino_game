enum LuckyWheelRewardType { coins, hammer, fragment, swap }

class LuckyWheelReward {
  const LuckyWheelReward({
    required this.id,
    required this.type,
    required this.quantity,
    required this.weight,
  });

  final String id;
  final LuckyWheelRewardType type;
  final int quantity;
  final int weight;

  String get name => switch (type) {
    LuckyWheelRewardType.coins => 'COINS',
    LuckyWheelRewardType.hammer => 'BASIC HAMMER',
    LuckyWheelRewardType.fragment => 'DINO FRAGMENT',
    LuckyWheelRewardType.swap => 'SWAP PAIR',
  };

  String get assetPath => switch (type) {
    LuckyWheelRewardType.coins => 'assets/store/coins/icon-coin.webp',
    LuckyWheelRewardType.hammer =>
      'assets/store/boosters/icon-booster-hammer.webp',
    LuckyWheelRewardType.fragment => 'assets/lucky_wheel/collection-icon.webp',
    LuckyWheelRewardType.swap => 'assets/store/boosters/icon-booster-swap.webp',
  };
}

class LuckyWheelResult {
  const LuckyWheelResult({
    required this.resultId,
    required this.reward,
    required this.segmentIndex,
    required this.createdAt,
    this.dinoId,
  });

  final String resultId;
  final LuckyWheelReward reward;
  final int segmentIndex;
  final DateTime createdAt;
  final String? dinoId;

  Map<String, dynamic> toJson() => {
    'spinResultId': resultId,
    'rewardId': reward.id,
    'type': reward.type.name,
    'quantity': reward.quantity,
    'segmentIndex': segmentIndex,
    'at': createdAt.millisecondsSinceEpoch,
    if (dinoId != null) 'dinoId': dinoId,
  };
}
