import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/game_local_store.dart';
import '../../profile/data/dino_collection_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/store_product.dart';
import '../domain/store_state.dart';

class StorePurchaseResult {
  const StorePurchaseResult({required this.state, required this.message});
  final StoreState state;
  final String message;
}

class StoreRepository {
  StoreRepository({GameLocalStore? store, FlutterSecureStorage? storage})
    : _store =
          store ??
          (storage == null
              ? GameLocalStore.shared
              : GameLocalStore(storage: storage));
  final GameLocalStore _store;

  Future<StoreState> load() => _store.transaction(_read);

  StoreState _read(GameSave save) {
    final collection = CollectionData.read(save);
    final home = save.object(GameStorageKeys.dinoHome);
    return StoreState(
      isLoading: false,
      coins: GameSave.number(
        save.values[GameStorageKeys.coins],
      ).clamp(0, 0x7fffffff),
      toolCounts: GameSave.counts(save.object(GameStorageKeys.tools)),
      chestCounts: ProfileRepository.chestCounts(save),
      inventoryCounts: GameSave.counts(save.object(GameStorageKeys.inventory)),
      ownedDinoIds: collection.unlocked.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet(),
      ownedPetIds: {
        'triceratops',
        if (home['ownedPets'] is List)
          ...(home['ownedPets'] as List).whereType<String>(),
      },
      foodCounts: GameSave.counts(home['foodInventory']),
    );
  }

  bool isOwned(StoreState state, StoreProduct product) {
    if (!product.isUnique) return false;
    return switch (product.grantType) {
      StoreGrantType.dino => state.ownedDinoIds.contains(product.grantId),
      StoreGrantType.pet => state.ownedPetIds.contains(product.grantId),
      _ => false,
    };
  }

  Future<StorePurchaseResult> purchase(
    StoreState state,
    StoreProduct product,
  ) => _store.transaction((save) {
    // Validate against persisted balances, not the page's possibly stale state.
    final current = _read(
      save,
    ).copyWith(selectedCategory: state.selectedCategory);
    StorePurchaseResult result(String message) =>
        StorePurchaseResult(state: current, message: message);
    // Temporary local grant for coin packs. Replace this branch with the IAP
    // receipt flow once store billing is connected.
    if (product.isIap && product.grantType != StoreGrantType.coins) {
      return result('IAP is not connected yet');
    }
    if (isOwned(current, product)) return result('Already owned');
    final price = product.price.toInt();
    if (current.coins < price) return result('Not enough coins');
    switch (product.grantType) {
      case StoreGrantType.tool:
        save.put(GameStorageKeys.tools, {
          ...current.toolCounts,
          product.grantId:
              (current.toolCounts[product.grantId] ?? 0) + product.quantity,
        });
      case StoreGrantType.chest:
        save.put(GameStorageKeys.chests, {
          ...current.chestCounts,
          product.grantId:
              (current.chestCounts[product.grantId] ?? 0) + product.quantity,
        });
      case StoreGrantType.dino:
        final collection = CollectionData.read(save);
        if (!collection.grantUnlock(product.grantId)) {
          return result('Already owned');
        }
        collection.persist(save);
      case StoreGrantType.pet:
        save.put(GameStorageKeys.dinoHome, {
          ...save.object(GameStorageKeys.dinoHome),
          'ownedPets': {...current.ownedPetIds, product.grantId}.toList()
            ..sort(),
        });
      case StoreGrantType.food:
        save.put(GameStorageKeys.dinoHome, {
          ...save.object(GameStorageKeys.dinoHome),
          'foodInventory': {
            ...current.foodCounts,
            product.grantId:
                ((current.foodCounts[product.grantId] ?? 0) + product.quantity)
                    .clamp(0, 9999),
          },
        });
      case StoreGrantType.coins:
        save.values[GameStorageKeys.coins] =
            '${(current.coins + product.quantity).clamp(0, 0x7fffffff)}';
        return StorePurchaseResult(
          state: _read(save).copyWith(selectedCategory: state.selectedCategory),
          message: 'Added ${product.quantity} coins',
        );
    }
    save.values[GameStorageKeys.coins] = '${current.coins - price}';
    return StorePurchaseResult(
      state: _read(save).copyWith(selectedCategory: state.selectedCategory),
      message: product.grantType == StoreGrantType.dino
          ? 'Unlocked ${product.name} - Set Avatar in Profile'
          : product.grantType == StoreGrantType.pet
          ? 'Unlocked ${product.name}'
          : 'Bought ${product.name} x${product.quantity}',
    );
  });
}
