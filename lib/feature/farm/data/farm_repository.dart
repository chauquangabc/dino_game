import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/game_local_store.dart';
import '../domain/farm_catalog.dart';
import '../domain/farm_food.dart';
import '../domain/farm_state.dart';

typedef FarmClock = DateTime Function();

class FarmRepository {
  FarmRepository({
    GameLocalStore? store,
    FlutterSecureStorage? storage,
    FarmClock? clock,
  }) : _store =
           store ??
           (storage == null
               ? GameLocalStore.shared
               : GameLocalStore(storage: storage)),
       _clock = clock ?? DateTime.now;

  final GameLocalStore _store;
  final FarmClock _clock;

  Stream<void> get changes => _store.changes;

  Future<FarmState> load() => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> selectFood(String id) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    if (FarmCatalog.food(id) != null) home['selectedFoodId'] = id;
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> selectPet(String id) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    final owned = _stringSet(home['ownedPets']);
    if (owned.contains(id) && FarmCatalog.pets.any((pet) => pet.id == id)) {
      home['selectedPetId'] = id;
    }
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> feed(String id) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    final food = FarmCatalog.food(id);
    final inventory = GameSave.counts(home['foodInventory']);
    if (food != null && (inventory[id] ?? 0) > 0) {
      inventory[id] = inventory[id]! - 1;
      home
        ..['foodInventory'] = inventory
        ..['selectedFoodId'] = id
        ..['healthStartedAt'] = now.millisecondsSinceEpoch
        ..['healthFullUntil'] = now.add(food.duration).millisecondsSinceEpoch
        ..['healthDurationSeconds'] = food.duration.inSeconds
        ..['lastCoinCalculationAt'] = now.millisecondsSinceEpoch;
    }
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> buyOneFood(String id) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    final food = FarmCatalog.food(id);
    var coins = _coins(save);
    if (food != null &&
        food.acquisition == FarmFoodAcquisition.coins &&
        coins >= food.price) {
      final inventory = GameSave.counts(home['foodInventory']);
      inventory[id] = ((inventory[id] ?? 0) + 1).clamp(0, 9999);
      home['foodInventory'] = inventory;
      coins -= food.price;
      save.values[GameStorageKeys.coins] = '$coins';
    }
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> grantRewardedFood(String id) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    final food = FarmCatalog.food(id);
    final today = _dayKey(now);
    final used = home['adGrantDate'] == today
        ? GameSave.number(home['adGrantCount'])
        : 0;
    if (food?.acquisition == FarmFoodAcquisition.rewardedAd &&
        used < FarmCatalog.rewardedAdDailyCap) {
      final inventory = GameSave.counts(home['foodInventory']);
      inventory[id] = ((inventory[id] ?? 0) + 1).clamp(0, 9999);
      home
        ..['foodInventory'] = inventory
        ..['adGrantDate'] = today
        ..['adGrantCount'] = used + 1;
    }
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Future<FarmState> claim([int? requested]) => _store.transaction((save) {
    final now = _clock();
    final home = _normalized(save.object(GameStorageKeys.dinoHome), now);
    _syncCoins(home, now);
    final pending = _pending(home);
    final amount = (requested ?? pending).clamp(0, pending);
    if (amount > 0) {
      home['pendingCoins'] = (_pendingRaw(home) - amount).clamp(
        0.0,
        FarmCatalog.pendingCoinsCap.toDouble(),
      );
      save.values[GameStorageKeys.coins] = '${_coins(save) + amount}';
    }
    save.put(GameStorageKeys.dinoHome, home);
    return _state(save, home, now);
  });

  Map<String, dynamic> _normalized(Map<String, dynamic> source, DateTime now) {
    final home = Map<String, dynamic>.of(source);
    final inventory = GameSave.counts(home['foodInventory']);
    for (final food in FarmCatalog.foods) {
      inventory.putIfAbsent(food.id, () => food.startingCount);
    }
    final owned = _stringSet(home['ownedPets'])..add(FarmCatalog.defaultPetId);
    var selectedPet = '${home['selectedPetId'] ?? FarmCatalog.defaultPetId}';
    if (!owned.contains(selectedPet) ||
        !FarmCatalog.pets.any((pet) => pet.id == selectedPet)) {
      selectedPet = FarmCatalog.defaultPetId;
    }
    var selectedFood =
        '${home['selectedFoodId'] ?? FarmCatalog.foods.first.id}';
    if (FarmCatalog.food(selectedFood) == null) {
      selectedFood = FarmCatalog.foods.first.id;
    }
    final nowMs = now.millisecondsSinceEpoch;
    var last = GameSave.number(home['lastCoinCalculationAt'], nowMs);
    if (last <= 0 || last > nowMs) last = nowMs;
    final duration = GameSave.number(
      home['healthDurationSeconds'],
    ).clamp(0, const Duration(days: 365).inSeconds);
    var fullUntil = GameSave.number(home['healthFullUntil'], nowMs);
    var started = GameSave.number(home['healthStartedAt'], fullUntil);
    if (fullUntil >
        nowMs + duration * 1000 + const Duration(hours: 1).inMilliseconds) {
      fullUntil = nowMs;
    }
    if (started > fullUntil) started = fullUntil;
    return home
      ..['healthStartedAt'] = started
      ..['healthFullUntil'] = fullUntil
      ..['healthDurationSeconds'] = duration
      ..['lastCoinCalculationAt'] = last
      ..['pendingCoins'] = _pendingRaw(home)
      ..['selectedFoodId'] = selectedFood
      ..['foodInventory'] = inventory
      ..['ownedPets'] = (owned.toList()..sort())
      ..['selectedPetId'] = selectedPet
      ..['adGrantDate'] = '${home['adGrantDate'] ?? ''}'
      ..['adGrantCount'] = GameSave.number(home['adGrantCount']).clamp(0, 9999);
  }

  void _syncCoins(Map<String, dynamic> home, DateTime now) {
    final nowMs = now.millisecondsSinceEpoch;
    final last = GameSave.number(home['lastCoinCalculationAt'], nowMs);
    final elapsed = (nowMs - last).clamp(
      0,
      FarmCatalog.maxOffline.inMilliseconds,
    );
    final earned =
        elapsed * FarmCatalog.coinsPerHour / Duration.millisecondsPerHour;
    home
      ..['pendingCoins'] = (_pendingRaw(home) + earned).clamp(
        0.0,
        FarmCatalog.pendingCoinsCap.toDouble(),
      )
      ..['lastCoinCalculationAt'] = nowMs;
  }

  FarmState _state(GameSave save, Map<String, dynamic> home, DateTime now) {
    final duration = Duration(
      seconds: GameSave.number(home['healthDurationSeconds']),
    );
    final today = _dayKey(now);
    final used = home['adGrantDate'] == today
        ? GameSave.number(home['adGrantCount'])
        : 0;
    return FarmState(
      healthStartedAt: DateTime.fromMillisecondsSinceEpoch(
        GameSave.number(home['healthStartedAt']),
      ),
      healthFullUntil: DateTime.fromMillisecondsSinceEpoch(
        GameSave.number(home['healthFullUntil']),
      ),
      healthDuration: duration,
      pendingCoins: _pending(home),
      coins: _coins(save),
      foodInventory: Map.unmodifiable(GameSave.counts(home['foodInventory'])),
      ownedPetIds: Set.unmodifiable(_stringSet(home['ownedPets'])),
      selectedPetId: '${home['selectedPetId']}',
      selectedFoodId: '${home['selectedFoodId']}',
      adGrantsLeft: (FarmCatalog.rewardedAdDailyCap - used).clamp(
        0,
        FarmCatalog.rewardedAdDailyCap,
      ),
    );
  }

  int _coins(GameSave save) => GameSave.number(
    save.values[GameStorageKeys.coins],
    500,
  ).clamp(0, 0x7fffffff);

  int _pending(Map<String, dynamic> home) => _pendingRaw(home).floor();

  double _pendingRaw(Map<String, dynamic> home) {
    final value = home['pendingCoins'];
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return (parsed ?? 0).clamp(0.0, FarmCatalog.pendingCoinsCap.toDouble());
  }

  Set<String> _stringSet(Object? value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};

  String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
