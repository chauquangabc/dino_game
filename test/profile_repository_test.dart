import 'dart:convert';
import 'dart:math';

import 'package:dino/core/storage/game_local_store.dart';
import 'package:dino/feature/home/data/map_character_repository.dart';
import 'package:dino/feature/lucky_wheel/data/lucky_wheel_repository.dart';
import 'package:dino/feature/lucky_wheel/domain/lucky_wheel_reward.dart';
import 'package:dino/feature/profile/data/chest_repository.dart';
import 'package:dino/feature/profile/data/dino_collection_repository.dart';
import 'package:dino/feature/profile/data/profile_mock_data.dart';
import 'package:dino/feature/profile/data/profile_repository.dart';
import 'package:dino/feature/profile/domain/chest_catalog.dart';
import 'package:dino/feature/profile/domain/chest_reward.dart';
import 'package:dino/feature/profile/domain/dino_collection_item.dart';
import 'package:dino/feature/profile/domain/profile_catalog.dart';
import 'package:dino/feature/store/data/store_repository.dart';
import 'package:dino/feature/store/domain/store_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  late MemorySecureStorage storage;
  late GameLocalStore store;
  late ProfileRepository profile;
  late DinoCollectionRepository collection;
  setUp(() {
    storage = MemorySecureStorage();
    store = GameLocalStore(storage: storage);
    profile = ProfileRepository(store: store);
    collection = DinoCollectionRepository(store: store);
  });

  test('demo seeds once, keeps Baby avatar and collection order', () async {
    final first = await profile.load();
    expect(first.profile!.coins, 12500);
    expect(first.profile!.equippedAvatarId, isNull);
    expect(first.selectedDinoId, 'spiderman');
    expect(first.dinos.map((d) => d.fragments), [8, 3, 0, 5, 0]);
    expect(first.chestCount, 2);
    await profile.rename('  Dino   King  ');
    await collection.addFragments('akatsuki', 2);
    final restarted = await ProfileRepository(
      store: GameLocalStore(storage: storage),
    ).load();
    expect(restarted.profile!.displayName, 'Dino King');
    expect(restarted.dinos[1].fragments, 5);
  });

  test('fresh scenario and title boundaries follow game rules', () async {
    await store.transaction(
      (s) => ProfileMockData.seed(s, mode: ProfileDataMode.fresh),
    );
    final state = await profile.load();
    expect(state.profile!.displayName, 'DINO98');
    expect(state.profile!.coins, 500);
    expect(state.chestCount, 0);
    expect(state.dinos.every((d) => d.fragments == 0 && !d.isUnlocked), isTrue);
    for (final (level, title) in [
      (1, 'Rookie'),
      (10, 'Rookie'),
      (11, 'Hunter'),
      (30, 'Hunter'),
      (31, 'Master'),
      (60, 'Master'),
      (61, 'Collector'),
      (90, 'Collector'),
      (91, 'Legend'),
      (100, 'Legend'),
    ]) {
      expect(ProfileCatalog.titleFor(level), title);
    }
  });

  test(
    'existing wallet/profile/chests are preserved during initial seeding',
    () async {
      storage.values.addAll({
        GameStorageKeys.coins: '42',
        GameStorageKeys.profile: '{"displayName":"Existing"}',
        GameStorageKeys.chests: '{"chest_fragment":0}',
        GameStorageKeys.collection: '{"fragments":{"akatsuki":6}}',
      });
      final state = await profile.load();
      expect(state.profile!.displayName, 'Existing');
      expect(state.profile!.coins, 42);
      expect(state.dinos[1].fragments, 6);
      expect(state.dinos.first.fragments, 0);
      expect(state.chestCount, 0);
    },
  );

  test(
    'names reject blank/long input and count user-perceived Unicode characters',
    () async {
      expect(ProfileRepository.validateName(' \n  '), isNotNull);
      expect(ProfileRepository.validateName('a' * 17), isNotNull);
      expect(ProfileRepository.validateName('👨‍👩‍👧‍👦' * 16), isNull);
      expect(ProfileRepository.validateName('a' * 16), isNull);
      await expectLater(profile.rename(''), throwsArgumentError);
    },
  );

  test(
    'legacy IDs, pieces, inventory and avatar migrate exactly once',
    () async {
      storage.values.addAll({
        GameStorageKeys.collection: jsonEncode({
          'fragments': {
            'akatsuki': 2,
            'dino-akatsuki': 4,
            'dino-captain-america': 5,
          },
          'unlocked': {'dino-akatsuki': true},
          'equippedAvatarId': 'dino-akatsuki',
        }),
        GameStorageKeys.inventory: '{"piece:green-1":2,"unrelated":9}',
        GameStorageKeys.chests: '{"chest_level_3":3}',
      });
      final state = await profile.load();
      expect(state.profile!.equippedAvatarId, 'akatsuki');
      expect(state.dinos[1].fragments, 8);
      expect(state.dinos[3].fragments, 7);
      expect(state.chestCount, 3);
      expect((await profile.load()).dinos[3].fragments, 7);
      final raw = jsonDecode(storage.values[GameStorageKeys.collection]!);
      expect(raw['unlocked'].containsKey('dino-akatsuki'), isFalse);
      expect(jsonDecode(storage.values[GameStorageKeys.inventory]!), {
        'unrelated': 9,
      });
    },
  );

  test('old Home avatar migrates only when the dino is owned', () async {
    storage.values[GameStorageKeys.legacyAvatar] = 'dino-spiderman';
    expect((await profile.load()).profile!.equippedAvatarId, 'spiderman');
    await collection.equip(null);
    expect((await profile.load()).profile!.equippedAvatarId, isNull);
    expect(
      (await MapCharacterRepository(store: store).loadEquipped()).id,
      'babyDino',
    );
  });

  test(
    '8 fragments require manual unlock; equip and selection are distinct',
    () async {
      await profile.load();
      expect(await collection.assemble('akatsuki'), isFalse);
      expect(await collection.equip('akatsuki'), isFalse);
      await collection.addFragments('akatsuki', 99);
      expect(
        (await collection.load())[1].status,
        DinoCollectionStatus.readyToUnlock,
      );
      expect(await collection.assemble('akatsuki'), isTrue);
      expect(await collection.assemble('akatsuki'), isFalse);
      expect(
        (await collection.load())[1].status,
        DinoCollectionStatus.unlocked,
      );
      expect(await collection.equip('akatsuki'), isTrue);
      expect(
        (await collection.load())[1].status,
        DinoCollectionStatus.equipped,
      );
      expect(
        (await MapCharacterRepository(store: store).loadEquipped()).id,
        'akatsuki',
      );
      expect(await collection.addFragments('unknown', 1), isFalse);
      expect(await collection.addFragments('akatsuki', -2), isFalse);
    },
  );

  test(
    'Store buys dino and chests with the same wallet, without auto-equipping',
    () async {
      final shop = StoreRepository(store: store);
      final state = await shop.load();
      final dino = StoreCatalog.products.firstWhere(
        (p) => p.grantId == 'batman',
      );
      await Future.wait([
        shop.purchase(state, dino),
        shop.purchase(state, dino),
      ]);
      final next = await profile.load();
      expect(next.profile!.coins, 6500);
      expect(next.dinos[2].isUnlocked, isTrue);
      expect(next.profile!.equippedAvatarId, isNull);
      final chest = StoreCatalog.products.firstWhere(
        (p) => p.id == 'chest_fragment_1',
      );
      await shop.purchase(state, chest); // intentionally stale state
      expect((await profile.load()).profile!.coins, 3500);
      expect((await profile.load()).chestCount, 3);
    },
  );

  test('serialized fragment writers never lose a concurrent update', () async {
    await profile.load();
    await Future.wait(
      List.generate(5, (_) => collection.addFragments('akatsuki', 1)),
    );
    final dino = (await collection.load())[1];
    expect(dino.fragments, 8);
    expect(dino.isUnlocked, isFalse);
  });

  test(
    'empty or unknown chest cannot consume inventory or grant rewards',
    () async {
      final chests = ChestRepository(store: store, random: Random(3));
      await profile.load();
      expect(await chests.open('chest_gold'), isNull);
      expect(await chests.open('unknown'), isNull);
      expect((await profile.load()).chestCount, 2);
    },
  );

  test(
    'open, duplicate tap, reopen and dismiss grant each chest exactly once',
    () async {
      final chests = ChestRepository(store: store, random: Random(7));
      final results = await Future.wait([
        chests.open('chest_fragment'),
        chests.open('chest_fragment'),
      ]);
      expect(results[0]!.id, results[1]!.id);
      expect((await profile.load()).chestCount, 1);
      final again = await Future.wait([
        chests.open('chest_fragment', expectedPreviousId: results[0]!.id),
        chests.open('chest_fragment', expectedPreviousId: results[0]!.id),
      ]);
      expect(again[0]!.id, again[1]!.id);
      expect(again[0]!.id, isNot(results[0]!.id));
      expect((await profile.load()).chestCount, 0);
      await chests.dismiss(
        results[0]!.id,
      ); // stale close cannot dismiss newer result
      expect((await chests.pending())!.id, again[0]!.id);
      await chests.dismiss(again[0]!.id);
      expect(await chests.pending(), isNull);
    },
  );

  test('all-complete fragment chests give 150 coins per fragment', () async {
    await profile.load();
    for (final d in ProfileCatalog.dinos) {
      await collection.addFragments(d.id, 8);
    }
    final before = (await profile.load()).profile!.coins;
    final result = (await ChestRepository(
      store: store,
      random: Random(1),
    ).open('chest_fragment'))!;
    expect(result.rewards.length, 1);
    expect(result.rewards.single.type, ChestRewardType.coin);
    expect(result.rewards.single.quantity, isIn([150, 300, 450]));
    expect(
      (await profile.load()).profile!.coins,
      before + result.rewards.single.quantity,
    );
  });

  test('all five chest tables grant valid persisted rewards', () async {
    for (final d in ChestCatalog.definitions) {
      for (var seed = 0; seed < 12; seed++) {
        final memory = MemorySecureStorage();
        final local = GameLocalStore(storage: memory);
        await local.transaction((s) {
          CollectionData.read(s);
          s.put(GameStorageKeys.chests, {d.id: 1});
        });
        final result = (await ChestRepository(
          store: local,
          random: Random(seed),
        ).open(d.id))!;
        expect(
          result.rewards.length,
          inInclusiveRange(1, ChestCatalog.tables[d.id]!.maxSlots),
        );
        expect(result.rewards.every((r) => r.quantity > 0), isTrue);
        final loaded = await ProfileRepository(store: local).load();
        expect(loaded.chestCount, 0);
        if (d.id == 'chest_gold') {
          expect(result.rewards.single.type, ChestRewardType.coin);
          expect(result.rewards.single.quantity, inInclusiveRange(300, 1500));
        }
        if (d.id == 'chest_special') {
          expect(
            result.rewards.where((r) => r.type == ChestRewardType.dino).length,
            1,
          );
          expect(loaded.dinos.where((r) => r.isUnlocked).length, 2);
        }
      }
    }
  });

  test(
    'interruption at every chest write recovers without loss or duplication',
    () async {
      await profile.load();
      final initial = Map<String, String>.of(storage.values);
      final baseline = MemorySecureStorage(initial);
      await ChestRepository(
        store: GameLocalStore(storage: baseline),
        random: Random(7),
      ).open('chest_fragment');
      for (final after in [false, true]) {
        for (var cut = 1; cut <= baseline.writes; cut++) {
          final memory = MemorySecureStorage(initial)
            ..failAt = cut
            ..failAfterWrite = after;
          final repo = ChestRepository(
            store: GameLocalStore(storage: memory),
            random: Random(7),
          );
          try {
            await repo.open('chest_fragment');
          } catch (_) {
            /* Simulated app termination. */
          }
          memory.failAt = null;
          final restartedStore = GameLocalStore(storage: memory);
          final restarted = ChestRepository(
            store: restartedStore,
            random: Random(7),
          );
          final result = await restarted.open('chest_fragment');
          final loaded = await ProfileRepository(store: restartedStore).load();
          expect(loaded.chestCount, 1, reason: 'cut=$cut after=$after');
          final awarded = result!.rewards.fold<int>(
            0,
            (sum, r) => sum + r.quantity,
          );
          expect(
            loaded.dinos.fold<int>(0, (sum, d) => sum + d.fragments),
            16 + awarded,
          );
          await restartedStore.recover();
          expect(
            (await ProfileRepository(store: restartedStore).load()).chestCount,
            1,
          );
        }
      }
    },
  );

  test(
    'Lucky Wheel fragment uses canonical IDs and never auto-unlocks',
    () async {
      await profile.load();
      await store.transaction((s) {
        s.put(GameStorageKeys.luckyWheel, {
          'luckyWheelSpins': 0,
          'pendingLuckyWheelResult': {
            'spinResultId': 'legacy-reward',
            'rewardId': 'fragment_2',
            'type': 'fragment',
            'quantity': 2,
            'segmentIndex': 6,
            'at': 0,
            'dinoId': 'dino-akatsuki',
          },
        });
      });
      await collection.addFragments('akatsuki', 3);
      final wheel = LuckyWheelRepository(store: store);
      final state = await wheel.load();
      expect(state.pendingResult!.dinoId, 'akatsuki');
      await Future.wait([wheel.claim(state), wheel.claim(state)]);
      final dino = (await collection.load())[1];
      expect(dino.fragments, 8);
      expect(dino.status, DinoCollectionStatus.readyToUnlock);
      expect((await wheel.load()).pendingResult, isNull);
    },
  );

  test(
    'Lucky Wheel all-complete fallback and repeated claim use shared wallet',
    () async {
      await profile.load();
      for (final d in ProfileCatalog.dinos) {
        await collection.addFragments(d.id, 8);
      }
      final wheel = LuckyWheelRepository(store: store, random: FixedRandom(43));
      final loaded = await wheel.load();
      final spun = await wheel.spin(loaded);
      expect(spun.pendingResult!.reward.type, LuckyWheelRewardType.coins);
      expect(spun.pendingResult!.reward.quantity, 150);
      final before = (await profile.load()).profile!.coins;
      await Future.wait([wheel.claim(spun), wheel.claim(spun)]);
      expect((await profile.load()).profile!.coins, before + 150);
    },
  );
}

class FixedRandom implements Random {
  FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => .5;
}
