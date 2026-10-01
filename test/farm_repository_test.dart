import 'package:dino/core/storage/game_local_store.dart';
import 'package:dino/feature/farm/data/farm_repository.dart';
import 'package:dino/feature/farm/domain/farm_mood.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage storage;
  late GameLocalStore store;
  late DateTime now;
  late FarmRepository farm;

  setUp(() {
    storage = MemorySecureStorage();
    store = GameLocalStore(storage: storage);
    now = DateTime(2026, 10, 1, 8);
    farm = FarmRepository(store: store, clock: () => now);
  });

  test('seeds inventory and default pet without replacing wallet', () async {
    storage.values[GameStorageKeys.coins] = '42';
    final state = await farm.load();
    expect(state.coins, 42);
    expect(state.selectedPetId, 'triceratops');
    expect(state.ownedPetIds, contains('triceratops'));
    expect(state.foodInventory, {
      'food_1': 5,
      'food_2': 3,
      'food_3': 1,
      'food_4': 0,
    });
  });

  test(
    'earns 20 coins per hour and caps one offline span at 24 hours',
    () async {
      await farm.load();
      now = now.add(const Duration(hours: 1));
      expect((await farm.load()).pendingCoins, 20);
      now = now.add(const Duration(days: 4));
      expect((await farm.load()).pendingCoins, 500);
    },
  );

  test('fractional earnings survive frequent synchronization', () async {
    await farm.load();
    for (var i = 0; i < 6; i++) {
      now = now.add(const Duration(minutes: 10));
      await farm.load();
    }
    expect((await farm.load()).pendingCoins, 20);
  });

  test('feeding consumes one item and mood follows boundaries', () async {
    await farm.load();
    final fed = await farm.feed('food_1');
    expect(fed.foodInventory['food_1'], 4);
    expect(fed.healthAt(now), 1);
    expect(fed.moodAt(now), FarmMood.happy);
    now = now.add(const Duration(minutes: 18, seconds: 1));
    expect((await farm.load()).moodAt(now), FarmMood.normal);
    now = now.add(const Duration(minutes: 24));
    expect((await farm.load()).moodAt(now), FarmMood.hungry);
  });

  test('partial and repeated claims share the wallet exactly', () async {
    await farm.load();
    now = now.add(const Duration(hours: 5));
    expect((await farm.load()).pendingCoins, 100);
    expect((await farm.claim(30)).coins, 530);
    final finalState = await farm.claim();
    expect(finalState.coins, 600);
    expect(finalState.pendingCoins, 0);
    expect((await farm.claim()).coins, 600);
  });

  test('only an owned known pet can be selected', () async {
    await store.transaction((save) {
      save.put(GameStorageKeys.dinoHome, {
        'ownedPets': ['triceratops', 'trex'],
      });
    });
    expect((await farm.selectPet('trex')).selectedPetId, 'trex');
    expect((await farm.selectPet('unknown')).selectedPetId, 'trex');
  });

  test('mock rewarded food respects daily cap', () async {
    for (var i = 0; i < 8; i++) {
      await farm.grantRewardedFood('food_4');
    }
    final state = await farm.load();
    expect(state.foodInventory['food_4'], 5);
    expect(state.adGrantsLeft, 0);
    now = now.add(const Duration(days: 1));
    expect((await farm.load()).adGrantsLeft, 5);
  });
}
