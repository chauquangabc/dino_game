import 'dart:math';

import '../../../core/storage/game_local_store.dart';
import '../domain/dino_collection_item.dart';
import '../domain/profile_catalog.dart';
import 'profile_mock_data.dart';

/// Shared collection rules used by Profile, Store, chests and Lucky Wheel.
class CollectionData {
  CollectionData._(this._raw, this.fragments, this.unlocked, this.equippedId);
  final Map<String, dynamic> _raw;
  final Map<String, int> fragments;
  final Map<String, bool> unlocked;
  String? equippedId;

  static CollectionData read(GameSave save) {
    ProfileMockData.seed(save);
    final raw = save.object(GameStorageKeys.collection);
    final fr = GameSave.counts(raw['fragments']);
    final un = GameSave.map(raw['unlocked']);
    final inventory = save.object(GameStorageKeys.inventory);
    var changedInventory = false;
    for (final d in ProfileCatalog.dinos) {
      fr[d.id] = max(
        fr[d.id] ?? 0,
        fr.remove(d.legacyId) ?? 0,
      ).clamp(0, d.fragmentGoal);
      final legacyUnlocked = un.remove(d.legacyId) == true;
      un[d.id] = un[d.id] == true || legacyUnlocked;
      if (raw['migrationV'] != 1) {
        if (GameSave.number(inventory['dino:${d.id}']) > 0 ||
            GameSave.number(inventory['dino:${d.legacyId}']) > 0) {
          un[d.id] = true;
        }
        final pieces = inventory.keys
            .where(
              (key) => RegExp(
                '^piece:(${d.id}|${d.legacySet})-[0-9]+\$',
              ).hasMatch(key),
            )
            .toList();
        for (final key in pieces) {
          fr[d.id] =
              (fr[d.id]! + max<int>(0, GameSave.number(inventory.remove(key))))
                  .clamp(0, d.fragmentGoal);
          changedInventory = true;
        }
      }
      if (un[d.id] == true) fr[d.id] = d.fragmentGoal;
    }
    var equipped = ProfileCatalog.byId(raw['equippedAvatarId']?.toString())?.id;
    if (equipped == null && raw['migrationV'] != 1) {
      equipped = ProfileCatalog.byId(
        save.values[GameStorageKeys.legacyAvatar],
      )?.id;
    }
    if (un[equipped] != true) equipped = null;
    if (changedInventory) save.put(GameStorageKeys.inventory, inventory);
    final data = CollectionData._(
      raw,
      fr,
      un.map((key, value) => MapEntry(key, value == true)),
      equipped,
    );
    data.persist(save);
    return data;
  }

  List<DinoCollectionItem> get items => List.unmodifiable(
    ProfileCatalog.dinos.map(
      (d) => DinoCollectionItem(
        definition: d,
        fragments: fragments[d.id] ?? 0,
        isUnlocked: unlocked[d.id] == true,
        isEquipped: equippedId == d.id,
      ),
    ),
  );

  bool addFragments(String id, int amount) {
    final d = ProfileCatalog.byId(id);
    if (d == null || amount <= 0) return false;
    fragments[d.id] = ((fragments[d.id] ?? 0) + amount).clamp(
      0,
      d.fragmentGoal,
    );
    return true; // Reaching the goal does NOT assemble the dino automatically.
  }

  bool assemble(String id) {
    final d = ProfileCatalog.byId(id);
    if (d == null ||
        unlocked[d.id] == true ||
        (fragments[d.id] ?? 0) < d.fragmentGoal) {
      return false;
    }
    unlocked[d.id] = true;
    return true;
  }

  bool grantUnlock(String id) {
    final d = ProfileCatalog.byId(id);
    if (d == null || unlocked[d.id] == true) return false;
    unlocked[d.id] = true;
    fragments[d.id] = d.fragmentGoal;
    return true;
  }

  bool equip(String? id) {
    if (id == null || id == 'babyDino') {
      equippedId = null;
      return true;
    }
    final d = ProfileCatalog.byId(id);
    if (d == null || unlocked[d.id] != true) return false;
    equippedId = d.id;
    return true;
  }

  String? rollFragment(Random random) {
    final eligible = ProfileCatalog.dinos
        .where((d) => (fragments[d.id] ?? 0) < d.fragmentGoal)
        .toList();
    return eligible.isEmpty
        ? null
        : eligible[random.nextInt(eligible.length)].id;
  }

  String? rollUnlockable(Random random) {
    final eligible = ProfileCatalog.dinos
        .where((d) => unlocked[d.id] != true)
        .toList();
    return eligible.isEmpty
        ? null
        : eligible[random.nextInt(eligible.length)].id;
  }

  void persist(GameSave save) => save.put(GameStorageKeys.collection, {
    ..._raw,
    'v': 1,
    'migrationV': 1,
    'fragments': fragments,
    'unlocked': unlocked,
    'equippedAvatarId': equippedId,
  });
}

class DinoCollectionRepository {
  DinoCollectionRepository({GameLocalStore? store})
    : store = store ?? GameLocalStore.shared;
  final GameLocalStore store;
  Future<List<DinoCollectionItem>> load() =>
      store.transaction((save) => CollectionData.read(save).items);
  Future<bool> addFragments(String id, int amount) =>
      _change((data) => data.addFragments(id, amount));
  Future<bool> assemble(String id) => _change((data) => data.assemble(id));
  Future<bool> grantUnlock(String id) =>
      _change((data) => data.grantUnlock(id));
  Future<bool> equip(String? id) => _change((data) => data.equip(id));
  Future<bool> _change(bool Function(CollectionData) change) =>
      store.transaction((save) {
        final data = CollectionData.read(save);
        final result = change(data);
        data.persist(save);
        return result;
      });
}
