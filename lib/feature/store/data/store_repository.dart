import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/store_catalog.dart';
import '../domain/store_product.dart';
import '../domain/store_state.dart';
import 'store_storage_keys.dart';

class StorePurchaseResult {
  const StorePurchaseResult({required this.state, required this.message});

  final StoreState state;
  final String message;
}

class StoreRepository {
  StoreRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<StoreState> load() async {
    final values = await Future.wait([
      _storage.read(key: StoreStorageKeys.coins),
      _storage.read(key: StoreStorageKeys.tools),
      _storage.read(key: StoreStorageKeys.chests),
      _storage.read(key: StoreStorageKeys.inventory),
      _storage.read(key: StoreStorageKeys.collection),
      _storage.read(key: StoreStorageKeys.dinoHome),
    ]);

    var coins = int.tryParse(values[0] ?? '');
    if (coins == null) {
      coins = StoreCatalog.startCoins;
      await _storage.write(key: StoreStorageKeys.coins, value: '$coins');
    }

    return StoreState(
      coins: coins,
      isLoading: false,
      toolCounts: _decodeCountMap(values[1]),
      chestCounts: _decodeCountMap(values[2]),
      inventoryCounts: _decodeCountMap(values[3]),
      ownedDinoIds: _decodeUnlockedDinos(values[4]),
      ownedPetIds: _decodeOwnedPets(values[5]),
      foodCounts: _decodeFoodCounts(values[5]),
    );
  }

  bool isOwned(StoreState state, StoreProduct product) {
    if (!product.isUnique) return false;
    switch (product.grantType) {
      case StoreGrantType.dino:
        return state.ownedDinoIds.contains(product.grantId);
      case StoreGrantType.pet:
        return product.grantId == 'triceratops' ||
            state.ownedPetIds.contains(product.grantId);
      case StoreGrantType.tool:
      case StoreGrantType.chest:
      case StoreGrantType.coins:
      case StoreGrantType.food:
        return false;
    }
  }

  Future<StorePurchaseResult> purchase(
    StoreState state,
    StoreProduct product,
  ) async {
    if (product.isIap) {
      return StorePurchaseResult(
        state: state,
        message: 'IAP is not connected yet',
      );
    }
    if (isOwned(state, product)) {
      return StorePurchaseResult(state: state, message: 'Already owned');
    }

    final price = product.price.toInt();
    if (state.coins < price) {
      return StorePurchaseResult(state: state, message: 'Not enough coins');
    }

    final tools = Map<String, int>.from(state.toolCounts);
    final chests = Map<String, int>.from(state.chestCounts);
    final inventory = Map<String, int>.from(state.inventoryCounts);
    final dinos = Set<String>.from(state.ownedDinoIds);
    final pets = Set<String>.from(state.ownedPetIds)..add('triceratops');
    final foods = Map<String, int>.from(state.foodCounts);

    switch (product.grantType) {
      case StoreGrantType.tool:
        tools[product.grantId] =
            (tools[product.grantId] ?? 0) + product.quantity;
      case StoreGrantType.chest:
        chests[product.grantId] =
            (chests[product.grantId] ?? 0) + product.quantity;
      case StoreGrantType.dino:
        dinos.add(product.grantId);
      case StoreGrantType.pet:
        pets.add(product.grantId);
      case StoreGrantType.food:
        foods[product.grantId] =
            ((foods[product.grantId] ?? 0) + product.quantity).clamp(0, 9999);
      case StoreGrantType.coins:
        break;
    }

    await Future.wait([
      _writeCountMap(StoreStorageKeys.tools, tools),
      _writeCountMap(StoreStorageKeys.chests, chests),
      _writeCountMap(StoreStorageKeys.inventory, inventory),
      _writeCollection(dinos),
      _writeDinoHome(pets: pets, foods: foods),
    ]);

    final nextCoins = state.coins - price;
    await _storage.write(key: StoreStorageKeys.coins, value: '$nextCoins');

    final next = state.copyWith(
      coins: nextCoins,
      toolCounts: tools,
      chestCounts: chests,
      inventoryCounts: inventory,
      ownedDinoIds: dinos,
      ownedPetIds: pets,
      foodCounts: foods,
    );
    final message = product.grantType == StoreGrantType.dino
        ? 'Unlocked ${product.name}'
        : product.grantType == StoreGrantType.pet
        ? 'Unlocked ${product.name}'
        : 'Bought ${product.name} x${product.quantity}';
    return StorePurchaseResult(state: next, message: message);
  }

  Map<String, int> _decodeCountMap(String? raw) {
    final decoded = _decodeObject(raw);
    return decoded.map<String, int>((key, value) {
      final number = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      return MapEntry(key, number < 0 ? 0 : number);
    });
  }

  Set<String> _decodeUnlockedDinos(String? raw) {
    final collection = _decodeObject(raw);
    final unlocked = collection['unlocked'];
    if (unlocked is! Map) return {};
    return unlocked.entries
        .where((entry) => entry.value == true)
        .map((entry) => '${entry.key}')
        .toSet();
  }

  Set<String> _decodeOwnedPets(String? raw) {
    final home = _decodeObject(raw);
    final owned = home['ownedPets'];
    return {'triceratops', if (owned is List) ...owned.whereType<String>()};
  }

  Map<String, int> _decodeFoodCounts(String? raw) {
    final home = _decodeObject(raw);
    final inventory = home['foodInventory'];
    if (inventory is! Map) return {};
    return inventory.map<String, int>((key, value) {
      final count = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      return MapEntry('$key', count.clamp(0, 9999));
    });
  }

  Map<String, dynamic> _decodeObject(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeCountMap(String key, Map<String, int> value) =>
      _storage.write(key: key, value: jsonEncode(value));

  Future<void> _writeCollection(Set<String> unlockedIds) async {
    final raw = await _storage.read(key: StoreStorageKeys.collection);
    final collection = _decodeObject(raw);
    final fragments = _stringDynamicMap(collection['fragments']);
    final unlocked = _stringDynamicMap(collection['unlocked']);
    for (final id in unlockedIds) {
      unlocked[id] = true;
      fragments[id] = 8;
    }
    collection['v'] = 1;
    collection['fragments'] = fragments;
    collection['unlocked'] = unlocked;
    collection.putIfAbsent('equippedAvatarId', () => null);
    await _storage.write(
      key: StoreStorageKeys.collection,
      value: jsonEncode(collection),
    );
  }

  Future<void> _writeDinoHome({
    required Set<String> pets,
    required Map<String, int> foods,
  }) async {
    final raw = await _storage.read(key: StoreStorageKeys.dinoHome);
    final home = _decodeObject(raw);
    final owned = <String>{
      'triceratops',
      if (home['ownedPets'] is List)
        ...(home['ownedPets'] as List).whereType<String>(),
      ...pets,
    };
    final foodInventory = _stringDynamicMap(home['foodInventory']);
    for (final entry in foods.entries) {
      foodInventory[entry.key] = entry.value.clamp(0, 9999);
    }
    home['ownedPets'] = owned.toList()..sort();
    home['foodInventory'] = foodInventory;
    home.putIfAbsent('selectedPetId', () => 'triceratops');
    await _storage.write(
      key: StoreStorageKeys.dinoHome,
      value: jsonEncode(home),
    );
  }

  Map<String, dynamic> _stringDynamicMap(Object? value) {
    if (value is! Map) return {};
    return value.map((key, item) => MapEntry('$key', item));
  }
}
