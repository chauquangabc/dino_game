import 'package:flutter/widgets.dart';

import '../../../core/storage/game_local_store.dart';
import '../domain/chest_catalog.dart';
import '../domain/profile_catalog.dart';
import '../domain/profile_state.dart';
import 'dino_collection_repository.dart';

class ProfileRepository {
  ProfileRepository({GameLocalStore? store})
    : store = store ?? GameLocalStore.shared;
  final GameLocalStore store;
  Stream<void> get changes => store.changes;

  Future<ProfileState> load() => store.transaction((save) {
    final collection = CollectionData.read(save);
    final items = collection.items;
    final rawProfile = save.object(GameStorageKeys.profile);
    final name = normalizeName(rawProfile['displayName']?.toString() ?? '');
    final counts = chestCounts(save);
    return ProfileState(
      isLoading: false,
      profile: PlayerProfile(
        displayName: name.isEmpty ? ProfileCatalog.defaultName : name,
        coins: GameSave.number(
          save.values[GameStorageKeys.coins],
        ).clamp(0, 0x7fffffff),
        highestLevel: GameSave.number(
          save.values[GameStorageKeys.level],
          1,
        ).clamp(1, 100),
        equippedAvatarId: collection.equippedId,
      ),
      dinos: items,
      selectedDinoId:
          collection.equippedId ??
          items.where((d) => d.isUnlocked).firstOrNull?.id ??
          items.firstOrNull?.id,
      chests: List.unmodifiable(
        ChestCatalog.definitions.map(
          (d) => ProfileChest(
            id: d.id,
            name: d.name,
            asset: d.asset,
            quantity: counts[d.id] ?? 0,
          ),
        ),
      ),
    );
  });

  static String normalizeName(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
  static String? validateName(String value) {
    final name = normalizeName(value);
    if (name.isEmpty) return 'Name cannot be empty';
    if (name.characters.length > ProfileCatalog.nameMaxLength) {
      return 'Name is at most 16 characters';
    }
    return null;
  }

  Future<void> rename(String value) {
    final error = validateName(value);
    if (error != null) return Future.error(ArgumentError(error));
    return store.transaction((save) {
      CollectionData.read(save);
      save.put(GameStorageKeys.profile, {
        ...save.object(GameStorageKeys.profile),
        'displayName': normalizeName(value),
      });
    });
  }

  static Map<String, int> chestCounts(GameSave save) {
    final counts = GameSave.counts(save.object(GameStorageKeys.chests));
    const aliases = {
      'chest_level_1': 'chest_gold',
      'chest_level_2': 'chest_item',
      'chest_level_3': 'chest_fragment',
      'chest_level_4': 'chest_mixed',
      'chest_level_5': 'chest_special',
      'chest_level_6': 'chest_special',
    };
    for (final entry in aliases.entries) {
      counts[entry.value] =
          (counts[entry.value] ?? 0) + (counts.remove(entry.key) ?? 0);
    }
    final inventory = save.object(GameStorageKeys.inventory);
    if (inventory.containsKey('chest')) {
      counts['chest_gold'] =
          (counts['chest_gold'] ?? 0) +
          GameSave.number(inventory.remove('chest')).clamp(0, 0x7fffffff);
      save.put(GameStorageKeys.inventory, inventory);
    }
    save.put(GameStorageKeys.chests, counts);
    return counts;
  }
}
