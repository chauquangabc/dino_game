import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/game_local_store.dart';
import '../../profile/data/dino_collection_repository.dart';
import '../../profile/domain/profile_catalog.dart';
import '../domain/lucky_wheel_catalog.dart';
import '../domain/lucky_wheel_reward.dart';
import '../domain/lucky_wheel_state.dart';

class LuckyWheelRepository {
  LuckyWheelRepository({
    GameLocalStore? store,
    FlutterSecureStorage? storage,
    Random? random,
    DateTime Function()? now,
  }) : _store =
           store ??
           (storage == null
               ? GameLocalStore.shared
               : GameLocalStore(storage: storage)),
       _random = random ?? Random.secure(),
       _now = now ?? DateTime.now;
  final GameLocalStore _store;
  final Random _random;
  final DateTime Function() _now;

  Future<LuckyWheelState> load() => _store.transaction((save) {
    CollectionData.read(save);
    final data = save.object(GameStorageKeys.luckyWheel);
    final now = _now(), today = _dateKey(_now());
    var spins = max(0, GameSave.number(data['luckyWheelSpins']));
    var streak = GameSave.number(
      data['luckyWheelStreakDay'],
    ).clamp(0, LuckyWheelCatalog.streakDays);
    if (data['lastDailySpinGrantDate'] != today) {
      spins += LuckyWheelCatalog.dailyFreeSpins;
      data['lastDailySpinGrantDate'] = today;
    }
    if (data['lastLuckyWheelVisitDate'] != today) {
      if (data['lastLuckyWheelVisitDate'] !=
          _dateKey(now.subtract(const Duration(days: 1)))) {
        streak = 0;
      }
      if (streak >= LuckyWheelCatalog.streakDays) streak = 0;
      streak++;
      data['lastLuckyWheelVisitDate'] = today;
      if (streak == LuckyWheelCatalog.streakDays) {
        spins += LuckyWheelCatalog.streakRewardSpins;
      }
    }
    data['luckyWheelSpins'] = spins;
    data['luckyWheelStreakDay'] = streak;
    save.put(GameStorageKeys.luckyWheel, data);
    return _state(data);
  });

  Future<LuckyWheelState> plusTurn(LuckyWheelState state) =>
      _store.transaction((save) {
        final data = save.object(GameStorageKeys.luckyWheel);
        data['luckyWheelSpins'] =
            max(0, GameSave.number(data['luckyWheelSpins'])) + 1;
        save.put(GameStorageKeys.luckyWheel, data);
        return _state(data);
      });

  Future<LuckyWheelState> spin(LuckyWheelState state) => _store.transaction((
    save,
  ) {
    final collection = CollectionData.read(save);
    final data = save.object(GameStorageKeys.luckyWheel);
    final current = _state(data);
    if (current.spins <= 0 || current.pendingResult != null) return current;
    final picked = _pickReward();
    var reward = picked;
    String? dinoId;
    if (picked.type == LuckyWheelRewardType.fragment) {
      dinoId = collection.rollFragment(_random);
      if (dinoId == null) {
        reward = LuckyWheelReward(
          id: picked.id,
          type: LuckyWheelRewardType.coins,
          quantity: picked.quantity * ProfileCatalog.fragmentCoinFallback,
          weight: picked.weight,
        );
      }
    }
    final now = _now();
    final result = LuckyWheelResult(
      resultId:
          'lw${now.microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 30).toRadixString(36)}',
      reward: reward,
      segmentIndex: LuckyWheelCatalog.rewards.indexOf(picked),
      createdAt: now,
      dinoId: dinoId,
    );
    data['luckyWheelSpins'] = current.spins - 1;
    data['pendingLuckyWheelResult'] = result.toJson();
    save.put(GameStorageKeys.luckyWheel, data);
    return _state(data);
  });

  Future<LuckyWheelState> claim(LuckyWheelState state) => _store.transaction((
    save,
  ) {
    final collection = CollectionData.read(save);
    final data = save.object(GameStorageKeys.luckyWheel);
    final pending = _decodeResult(data['pendingLuckyWheelResult']);
    if (pending == null || pending.resultId != state.pendingResult?.resultId) {
      return _state(data);
    }
    final claimed = data['claimedSpinResultIds'] is List
        ? (data['claimedSpinResultIds'] as List).whereType<String>().toList()
        : <String>[];
    if (!claimed.contains(pending.resultId)) {
      final quantity = pending.reward.quantity;
      switch (pending.reward.type) {
        case LuckyWheelRewardType.coins:
          save.values[GameStorageKeys.coins] =
              '${GameSave.number(save.values[GameStorageKeys.coins]) + quantity}';
        case LuckyWheelRewardType.hammer:
        case LuckyWheelRewardType.swap:
          final tools = GameSave.counts(save.object(GameStorageKeys.tools));
          final id = pending.reward.type == LuckyWheelRewardType.hammer
              ? 'hammer_basic'
              : 'swap_pair';
          tools[id] = (tools[id] ?? 0) + quantity;
          save.put(GameStorageKeys.tools, tools);
        case LuckyWheelRewardType.fragment:
          if (pending.dinoId != null) {
            collection.addFragments(pending.dinoId!, quantity);
          }
          collection.persist(save);
      }
      claimed.add(pending.resultId);
    }
    if (claimed.length > LuckyWheelCatalog.claimedIdsLimit) {
      claimed.removeRange(
        0,
        claimed.length - LuckyWheelCatalog.claimedIdsLimit,
      );
    }
    data['claimedSpinResultIds'] = claimed;
    data['pendingLuckyWheelResult'] = null;
    // Receipt, reward and pending-result removal commit in one recoverable write.
    save.put(GameStorageKeys.luckyWheel, data);
    return _state(data);
  });

  LuckyWheelReward _pickReward() {
    var value = _random.nextInt(
      LuckyWheelCatalog.rewards.fold<int>(0, (sum, r) => sum + r.weight),
    );
    for (final reward in LuckyWheelCatalog.rewards) {
      value -= reward.weight;
      if (value < 0) return reward;
    }
    return LuckyWheelCatalog.rewards.last;
  }

  LuckyWheelState _state(Map<String, dynamic> data) => LuckyWheelState(
    spins: max(0, GameSave.number(data['luckyWheelSpins'])),
    streakDay: GameSave.number(
      data['luckyWheelStreakDay'],
    ).clamp(0, LuckyWheelCatalog.streakDays),
    isLoading: false,
    pendingResult: _decodeResult(data['pendingLuckyWheelResult']),
  );

  LuckyWheelResult? _decodeResult(Object? raw) {
    final data = GameSave.map(raw);
    final original = LuckyWheelCatalog.byId('${data['rewardId']}');
    if (original == null || data['spinResultId'] is! String) return null;
    final type =
        LuckyWheelRewardType.values
            .where((t) => t.name == data['type'])
            .firstOrNull ??
        original.type;
    return LuckyWheelResult(
      resultId: data['spinResultId'] as String,
      reward: LuckyWheelReward(
        id: original.id,
        type: type,
        quantity: max(1, GameSave.number(data['quantity'])),
        weight: original.weight,
      ),
      segmentIndex: GameSave.number(
        data['segmentIndex'],
      ).clamp(0, LuckyWheelCatalog.rewards.length - 1),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        GameSave.number(data['at']),
      ),
      dinoId: ProfileCatalog.byId(data['dinoId']?.toString())?.id,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
