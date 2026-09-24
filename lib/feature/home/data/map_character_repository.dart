import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/map_character_config.dart';

class MapCharacterRepository {
  MapCharacterRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _equippedCharacterKey = 'dino-line-98-equipped-character';

  final FlutterSecureStorage _storage;

  Future<MapCharacter> loadEquipped() async {
    final id = await _storage.read(key: _equippedCharacterKey);
    return MapCharacterConfig.byId(id);
  }

  Future<void> saveEquipped(String id) {
    final character = MapCharacterConfig.byId(id);
    return _storage.write(key: _equippedCharacterKey, value: character.id);
  }
}
