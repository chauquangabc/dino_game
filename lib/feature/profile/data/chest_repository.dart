import 'dart:math';

import '../../../core/storage/game_local_store.dart';
import '../domain/chest_catalog.dart';
import '../domain/chest_reward.dart';
import '../domain/profile_catalog.dart';
import 'dino_collection_repository.dart';
import 'profile_repository.dart';

class ChestRepository {
  ChestRepository({GameLocalStore? store, Random? random})
    : store = store ?? GameLocalStore.shared,
      _random = random ?? Random.secure();
  final GameLocalStore store;
  final Random _random;

  Future<ChestOpeningResult?> pending() =>
      store.transaction((save) => _pending(save));
  ChestOpeningResult? _pending(GameSave save) {
    final json = save.object(GameStorageKeys.chestResult);
    return json.isEmpty ? null : ChestOpeningResult.fromJson(json);
  }

  /// The result and absolute after-balances are saved before any animation.
  /// expectedPreviousId makes Open Again idempotent even on concurrent taps.
  Future<ChestOpeningResult?> open(
    String chestId, {
    String? expectedPreviousId,
  }) => store.transaction((save) {
    final collection = CollectionData.read(save);
    final previous = _pending(save);
    if (previous != null && previous.id != expectedPreviousId) return previous;
    if (expectedPreviousId != null && previous?.id != expectedPreviousId) {
      return previous;
    }
    final counts = ProfileRepository.chestCounts(save);
    final table = ChestCatalog.tables[chestId];
    if (table == null || (counts[chestId] ?? 0) <= 0) return previous;
    final rewards = <String, ChestReward>{};
    final tools = GameSave.counts(save.object(GameStorageKeys.tools));
    var coins = GameSave.number(save.values[GameStorageKeys.coins]);

    void grant(ChestRewardType type, String id, int quantity) {
      final key = '${type.name}:$id';
      rewards[key] = ChestReward(
        type: type,
        id: id,
        quantity: (rewards[key]?.quantity ?? 0) + quantity,
      );
      switch (type) {
        case ChestRewardType.coin:
          coins += quantity;
        case ChestRewardType.tool:
          tools[id] = (tools[id] ?? 0) + quantity;
        case ChestRewardType.fragment:
          collection.addFragments(id, quantity);
        case ChestRewardType.dino:
          collection.grantUnlock(id);
      }
    }

    void roll(ChestRewardEntry entry) {
      var q = entry.min + _random.nextInt(entry.max - entry.min + 1);
      if (entry.step > 1) {
        q = max(entry.min, (q / entry.step).round() * entry.step);
      }
      switch (entry.type) {
        case 'coin':
          grant(ChestRewardType.coin, 'coin', q);
        case 'hammer':
          grant(ChestRewardType.tool, _weighted(ChestCatalog.hammerWeights), q);
        case 'swap':
          grant(ChestRewardType.tool, _weighted(ChestCatalog.swapWeights), q);
        case 'fragment':
          // Reserve each awarded piece before rolling the next: no excess piece
          // is lost when a dino reaches 8/8 midway through a chest.
          final remaining = max(0, table.maxSlots - rewards.length);
          q = min(q, remaining);
          for (var i = 0; i < q; i++) {
            final id = collection.rollFragment(_random);
            if (id == null) {
              grant(
                ChestRewardType.coin,
                'coin',
                ProfileCatalog.fragmentCoinFallback,
              );
            } else {
              grant(ChestRewardType.fragment, id, 1);
            }
          }
        case 'dino':
          final id = collection.rollUnlockable(_random);
          if (id == null) {
            grant(
              ChestRewardType.coin,
              'coin',
              ProfileCatalog.dinoCoinFallback,
            );
          } else {
            grant(ChestRewardType.dino, id, 1);
          }
      }
    }

    for (final entry in table.guaranteed) {
      roll(entry);
    }
    final entries = [...table.entries];
    final count = table.countWeights.isEmpty
        ? 0
        : _weighted(table.countWeights);
    for (
      var i = 0;
      i < count && entries.isNotEmpty && rewards.length < table.maxSlots;
      i++
    ) {
      final entry = _weighted(entries.map((e) => (e, e.weight)).toList());
      entries.remove(entry);
      roll(entry);
    }
    if (rewards.isEmpty) return previous;
    final result = ChestOpeningResult(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}',
      chestId: chestId,
      rewards: List.unmodifiable(rewards.values),
    );
    counts[chestId] = counts[chestId]! - 1;
    save.put(GameStorageKeys.chests, counts);
    save.values[GameStorageKeys.coins] = '$coins';
    save.put(GameStorageKeys.tools, tools);
    collection.persist(save);
    save.put(GameStorageKeys.chestResult, result.toJson());
    return result;
  }, journalKey: GameStorageKeys.chestTransaction);

  Future<void> dismiss(String resultId) => store.transaction((save) {
    if (_pending(save)?.id == resultId) {
      save.values[GameStorageKeys.chestResult] = null;
    }
  });

  T _weighted<T>(List<(T, int)> items) {
    var value = _random.nextInt(
      items.fold<int>(0, (sum, item) => sum + item.$2),
    );
    for (final item in items) {
      value -= item.$2;
      if (value < 0) return item.$1;
    }
    return items.last.$1;
  }
}
