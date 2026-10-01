class ChestDefinition {
  const ChestDefinition(this.id, this.name, this.storePrice);
  final String id, name;
  final int storePrice;
  String get asset => 'assets/store/chests/${id.replaceAll('_', '-')}.webp';
  String get openAsset =>
      'assets/store/chests/${id.replaceAll('_', '-')}-open.webp';
}

class ChestRewardEntry {
  const ChestRewardEntry(
    this.type,
    this.min,
    this.max, {
    this.weight = 1,
    this.step = 1,
  });
  final String type;
  final int min, max, weight, step;
}

class ChestRewardTable {
  const ChestRewardTable({
    this.guaranteed = const [],
    this.countWeights = const [],
    this.entries = const [],
    this.maxSlots = 3,
  });
  final List<ChestRewardEntry> guaranteed, entries;
  final List<(int, int)> countWeights;
  final int maxSlots;
}

abstract final class ChestCatalog {
  // Preserve the approved Profile UI order (fragment chest first).
  static const definitions = [
    ChestDefinition('chest_fragment', 'Fragment Chest', 3000),
    ChestDefinition('chest_gold', 'Gold Chest', 1500),
    ChestDefinition('chest_item', 'Item Chest', 1800),
    ChestDefinition('chest_mixed', 'Mixed Chest', 2400),
    ChestDefinition('chest_special', 'Special Chest', 12000),
  ];
  static ChestDefinition? byId(String id) {
    for (final d in definitions) {
      if (d.id == id) return d;
    }
    return null;
  }

  // CHEST_REWARD_TABLES from the standalone HTML.
  static const tables = {
    'chest_gold': ChestRewardTable(
      guaranteed: [ChestRewardEntry('coin', 300, 1500, step: 50)],
    ),
    'chest_fragment': ChestRewardTable(
      guaranteed: [ChestRewardEntry('fragment', 1, 3)],
    ),
    'chest_item': ChestRewardTable(
      countWeights: [(1, 40), (2, 40), (3, 20)],
      entries: [
        ChestRewardEntry('hammer', 1, 2, weight: 35),
        ChestRewardEntry('hammer', 1, 1, weight: 20),
        ChestRewardEntry('swap', 1, 2, weight: 30),
        ChestRewardEntry('swap', 1, 1, weight: 15),
      ],
    ),
    'chest_mixed': ChestRewardTable(
      countWeights: [(1, 30), (2, 45), (3, 25)],
      entries: [
        ChestRewardEntry('coin', 200, 800, step: 50, weight: 40),
        ChestRewardEntry('hammer', 1, 2, weight: 20),
        ChestRewardEntry('swap', 1, 2, weight: 15),
        ChestRewardEntry('fragment', 1, 2, weight: 25),
      ],
    ),
    'chest_special': ChestRewardTable(
      maxSlots: 5,
      guaranteed: [
        ChestRewardEntry('coin', 2000, 5000, step: 100),
        ChestRewardEntry('dino', 1, 1),
      ],
      countWeights: [(1, 100)],
      entries: [
        ChestRewardEntry('hammer', 3, 5, weight: 55),
        ChestRewardEntry('swap', 3, 5, weight: 45),
      ],
    ),
  };
  static const hammerWeights = [
    ('hammer_basic', 40),
    ('hammer_cross', 20),
    ('hammer_harvest', 15),
    ('hammer_stone', 15),
    ('hammer_spread', 6),
    ('hammer_color', 4),
  ];
  static const swapWeights = [('swap_pair', 70), ('swap_shuffle', 30)];
}
