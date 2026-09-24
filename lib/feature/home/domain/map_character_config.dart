class MapCharacter {
  const MapCharacter({
    required this.id,
    required this.name,
    required this.asset,
  });

  final String id;
  final String name;
  final String asset;
}

abstract final class MapCharacterConfig {
  static const MapCharacter babyDino = MapCharacter(
    id: 'babyDino',
    name: 'Baby Dino',
    asset: 'assets/character/babyDino.webp',
  );

  static const List<MapCharacter> characters = [
    babyDino,
    MapCharacter(
      id: 'dino-akatsuki',
      name: 'Dino Akatsuki',
      asset: 'assets/character/dino-akatsuki.webp',
    ),
    MapCharacter(
      id: 'dino-batman',
      name: 'Dino Batman',
      asset: 'assets/character/dino-batman.webp',
    ),
    MapCharacter(
      id: 'dino-captain-america',
      name: 'Dino Captain America',
      asset: 'assets/character/dino-captain-america.webp',
    ),
    MapCharacter(
      id: 'dino-doraemon',
      name: 'Dino Doraemon',
      asset: 'assets/character/dino-doraemon.webp',
    ),
    MapCharacter(
      id: 'dino-spiderman',
      name: 'Dino Spiderman',
      asset: 'assets/character/dino-spiderman.webp',
    ),
  ];

  static MapCharacter byId(String? id) {
    if (id == null) return babyDino;
    for (final character in characters) {
      if (character.id == id) return character;
    }
    return babyDino;
  }
}
