import 'dino_definition.dart';

abstract final class ProfileCatalog {
  static const nameMaxLength = 16;
  static const defaultName = 'DINO98';
  static const babyAsset = 'assets/character/babyDino.webp';
  static const fragmentCoinFallback = 150;
  static const dinoCoinFallback = 3000;

  // Order, species, rarity and prices come from DINO_COLLECTION_CONFIG.
  static const dinos = <DinoDefinition>[
    DinoDefinition(
      id: 'spiderman',
      name: 'Spiderman',
      species: 'Triceratops',
      rarity: DinoRarity.rare,
      asset: 'assets/character/dino-spiderman.webp',
      description: 'Web-slinging trike, never sits still.',
      legacyId: 'dino-spiderman',
      legacySet: 'red',
    ),
    DinoDefinition(
      id: 'akatsuki',
      name: 'Akatsuki',
      species: 'Stegosaurus',
      rarity: DinoRarity.epic,
      asset: 'assets/character/dino-akatsuki.webp',
      description: 'Cloud-cloaked shadow of the jungle.',
      legacyId: 'dino-akatsuki',
      legacySet: 'yellow',
    ),
    DinoDefinition(
      id: 'batman',
      name: 'Batman',
      species: 'Triceratops',
      rarity: DinoRarity.epic,
      asset: 'assets/character/dino-batman.webp',
      description: 'Silent guardian of the night jungle.',
      legacyId: 'dino-batman',
      legacySet: 'purple',
    ),
    DinoDefinition(
      id: 'captain',
      name: 'Captain',
      species: 'T-Rex',
      rarity: DinoRarity.rare,
      asset: 'assets/character/dino-captain-america.webp',
      description: 'Shield up! Leads every hatchling charge.',
      legacyId: 'dino-captain-america',
      legacySet: 'green',
    ),
    DinoDefinition(
      id: 'doraemon',
      name: 'Doraemon',
      species: 'Triceratops',
      rarity: DinoRarity.legendary,
      asset: 'assets/character/dino-doraemon.webp',
      description: 'Pocket full of gadgets and snacks.',
      legacyId: 'dino-doraemon',
      legacySet: 'orange',
    ),
  ];

  static DinoDefinition? byId(String? id) {
    for (final dino in dinos) {
      if (dino.id == id || dino.legacyId == id) return dino;
    }
    return null;
  }

  static String titleFor(int level) => switch (level) {
    >= 91 => 'Legend',
    >= 61 => 'Collector',
    >= 31 => 'Master',
    >= 11 => 'Hunter',
    _ => 'Rookie',
  };
}
