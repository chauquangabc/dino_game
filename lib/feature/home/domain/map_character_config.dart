import '../../profile/domain/profile_catalog.dart';

class MapCharacter {
  const MapCharacter({
    required this.id,
    required this.name,
    required this.asset,
  });
  final String id, name, asset;
}

abstract final class MapCharacterConfig {
  static const babyDino = MapCharacter(
    id: 'babyDino',
    name: 'Baby Dino',
    asset: ProfileCatalog.babyAsset,
  );
  static final List<MapCharacter> characters = List.unmodifiable([
    babyDino,
    ...ProfileCatalog.dinos.map(
      (d) => MapCharacter(id: d.id, name: d.name, asset: d.asset),
    ),
  ]);
  static MapCharacter byId(String? id) {
    final canonical = ProfileCatalog.byId(id)?.id ?? id;
    return characters.where((c) => c.id == canonical).firstOrNull ?? babyDino;
  }
}
