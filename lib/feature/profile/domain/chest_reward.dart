import 'profile_catalog.dart';

enum ChestRewardType { coin, tool, fragment, dino }

class ChestReward {
  const ChestReward({
    required this.type,
    required this.id,
    required this.quantity,
  });
  final ChestRewardType type;
  final String id;
  final int quantity;
  String get asset => switch (type) {
    ChestRewardType.coin => 'assets/store/coins/icon-coin.webp',
    ChestRewardType.fragment => 'assets/store/chests/fragment-$id.webp',
    ChestRewardType.dino =>
      ProfileCatalog.byId(id)?.asset ?? ProfileCatalog.babyAsset,
    ChestRewardType.tool =>
      id.startsWith('hammer_')
          ? 'assets/store/boosters/${id.replaceAll('_', '-')}.webp'
          : 'assets/store/boosters/icon-booster-swap.webp',
  };
  String get name => switch (type) {
    ChestRewardType.coin => 'Coins',
    ChestRewardType.fragment =>
      '${ProfileCatalog.byId(id)?.name ?? id} fragment',
    ChestRewardType.dino => ProfileCatalog.byId(id)?.name ?? id,
    ChestRewardType.tool => id.replaceAll('_', ' '),
  };
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'quantity': quantity,
  };
  factory ChestReward.fromJson(Map<String, dynamic> json) => ChestReward(
    type: ChestRewardType.values.byName(json['type'] as String),
    id: json['id'] as String,
    quantity: json['quantity'] as int,
  );
}

class ChestOpeningResult {
  const ChestOpeningResult({
    required this.id,
    required this.chestId,
    required this.rewards,
  });
  final String id, chestId;
  final List<ChestReward> rewards;
  Map<String, dynamic> toJson() => {
    'id': id,
    'chestId': chestId,
    'rewards': rewards.map((r) => r.toJson()).toList(),
  };
  factory ChestOpeningResult.fromJson(Map<String, dynamic> json) =>
      ChestOpeningResult(
        id: json['id'] as String,
        chestId: json['chestId'] as String,
        rewards: List.unmodifiable(
          (json['rewards'] as List).map(
            (r) => ChestReward.fromJson(Map<String, dynamic>.from(r as Map)),
          ),
        ),
      );
}
