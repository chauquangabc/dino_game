import 'dino_definition.dart';

enum DinoCollectionStatus {
  fragmentsMissing('FIND MORE'),
  readyToUnlock('UNLOCK'),
  unlocked('SET AVATAR'),
  equipped('IN USE');

  const DinoCollectionStatus(this.label);
  final String label;
}

class DinoCollectionItem {
  const DinoCollectionItem({
    required this.definition,
    required this.fragments,
    required this.isUnlocked,
    required this.isEquipped,
  });
  final DinoDefinition definition;
  final int fragments;
  final bool isUnlocked, isEquipped;
  String get id => definition.id;
  String get name => definition.name;
  String get asset => definition.asset;
  String get species => definition.species;
  String get rarity => definition.rarity.name;
  int get fragmentGoal => definition.fragmentGoal;
  DinoCollectionStatus get status => isEquipped
      ? DinoCollectionStatus.equipped
      : isUnlocked
      ? DinoCollectionStatus.unlocked
      : fragments >= fragmentGoal
      ? DinoCollectionStatus.readyToUnlock
      : DinoCollectionStatus.fragmentsMissing;
}
