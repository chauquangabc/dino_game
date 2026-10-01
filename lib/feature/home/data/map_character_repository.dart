import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/storage/game_local_store.dart';
import '../../profile/data/dino_collection_repository.dart';
import '../domain/map_character_config.dart';

class MapCharacterRepository {
  MapCharacterRepository({GameLocalStore? store, FlutterSecureStorage? storage})
    : _store =
          store ??
          (storage == null
              ? GameLocalStore.shared
              : GameLocalStore(storage: storage));
  final GameLocalStore _store;
  Stream<void> get changes => _store.changes;

  Future<MapCharacter> loadEquipped() => _store.transaction(
    (save) => MapCharacterConfig.byId(CollectionData.read(save).equippedId),
  );

  Future<void> saveEquipped(String id) => _store.transaction((save) {
    final collection = CollectionData.read(save);
    if (!collection.equip(id)) {
      throw StateError('Dino must be unlocked before equipping');
    }
    collection.persist(save);
  });
}
