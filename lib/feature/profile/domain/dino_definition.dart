enum DinoRarity { common, rare, epic, legendary }

class DinoDefinition {
  const DinoDefinition({
    required this.id,
    required this.name,
    required this.species,
    required this.rarity,
    required this.asset,
    required this.description,
    required this.legacyId,
    required this.legacySet,
    this.storePrice = 6000,
    this.fragmentGoal = 8,
  });

  final String id, name, species, asset, description, legacyId, legacySet;
  final DinoRarity rarity;
  final int storePrice, fragmentGoal;
}
