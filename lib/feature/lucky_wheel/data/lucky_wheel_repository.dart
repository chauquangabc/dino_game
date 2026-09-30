import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../home/domain/map_character_config.dart';
import '../../store/data/store_storage_keys.dart';
import '../domain/lucky_wheel_catalog.dart';
import '../domain/lucky_wheel_reward.dart';
import '../domain/lucky_wheel_state.dart';

class LuckyWheelRepository {
  LuckyWheelRepository({FlutterSecureStorage? storage, Random? random})
    : _storage = storage ?? const FlutterSecureStorage(),
      _random = random ?? Random.secure();

  static const _stateKey = 'line98_lucky_wheel';
  final FlutterSecureStorage _storage;
  final Random _random;

  Map<String, dynamic> _data = {};

  Future<LuckyWheelState> load() async {
    _data = _decode(await _storage.read(key: _stateKey));
    final today = _dateKey(DateTime.now());
    var spins = _int(_data['luckyWheelSpins']);
    var streak = _int(_data['luckyWheelStreakDay']).clamp(0, 7);

    if (_data['lastDailySpinGrantDate'] != today) {
      spins += LuckyWheelCatalog.dailyFreeSpins;
      _data['lastDailySpinGrantDate'] = today;
    }

    if (_data['lastLuckyWheelVisitDate'] != today) {
      final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      if (_data['lastLuckyWheelVisitDate'] != yesterday) streak = 0;
      if (streak >= LuckyWheelCatalog.streakDays) streak = 0;
      streak++;
      _data['lastLuckyWheelVisitDate'] = today;
      if (streak == LuckyWheelCatalog.streakDays) {
        spins += LuckyWheelCatalog.streakRewardSpins;
      }
    }

    _data['luckyWheelSpins'] = spins;
    _data['luckyWheelStreakDay'] = streak;
    _data.putIfAbsent('claimedSpinResultIds', () => <String>[]);
    await _save();

    return LuckyWheelState(
      spins: spins,
      streakDay: streak,
      isLoading: false,
      pendingResult: _decodeResult(_data['pendingLuckyWheelResult']),
    );
  }

  Future<LuckyWheelState> plusTurn(LuckyWheelState state) async {
    final spins = state.spins + 1;
    _data['luckyWheelSpins'] = spins;
    await _save();
    return state.copyWith(spins: spins);
  }

  Future<LuckyWheelState> spin(LuckyWheelState state) async {
    if (state.spins <= 0 || state.pendingResult != null) return state;
    final pickedReward = _pickReward();
    final index = LuckyWheelCatalog.rewards.indexOf(pickedReward);
    var reward = pickedReward;
    String? dinoId;
    if (reward.type == LuckyWheelRewardType.fragment) {
      final collection = _decode(
        await _storage.read(key: StoreStorageKeys.collection),
      );
      final fragments = _map(collection['fragments']);
      final eligible = MapCharacterConfig.characters
          .skip(1)
          .where((dino) => _int(fragments[dino.id]) < 8)
          .toList();
      if (eligible.isEmpty) {
        reward = LuckyWheelReward(
          id: pickedReward.id,
          type: LuckyWheelRewardType.coins,
          quantity: pickedReward.quantity * 150,
          weight: pickedReward.weight,
        );
      } else {
        dinoId = eligible[_random.nextInt(eligible.length)].id;
      }
    }
    final now = DateTime.now();
    final result = LuckyWheelResult(
      resultId:
          'lw${now.microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}',
      reward: reward,
      segmentIndex: index,
      createdAt: now,
      dinoId: dinoId,
    );
    final spins = state.spins - 1;
    _data['luckyWheelSpins'] = spins;
    _data['pendingLuckyWheelResult'] = result.toJson();
    await _save();
    return state.copyWith(spins: spins, pendingResult: result);
  }

  Future<LuckyWheelState> claim(LuckyWheelState state) async {
    final result = state.pendingResult;
    if (result == null) return state;
    final claimed = ((_data['claimedSpinResultIds'] as List?) ?? const [])
        .map((value) => '$value')
        .toList();
    if (!claimed.contains(result.resultId)) {
      claimed.add(result.resultId);
      if (claimed.length > LuckyWheelCatalog.claimedIdsLimit) {
        claimed.removeRange(
          0,
          claimed.length - LuckyWheelCatalog.claimedIdsLimit,
        );
      }
      _data['claimedSpinResultIds'] = claimed;
      _data['pendingLuckyWheelResult'] = null;
      await _save();
      try {
        await _grant(result);
      } catch (_) {
        claimed.remove(result.resultId);
        _data['claimedSpinResultIds'] = claimed;
        _data['pendingLuckyWheelResult'] = result.toJson();
        await _save();
        rethrow;
      }
    }
    _data['claimedSpinResultIds'] = claimed;
    _data['pendingLuckyWheelResult'] = null;
    await _save();
    return state.copyWith(clearPending: true);
  }

  LuckyWheelReward _pickReward() {
    final total = LuckyWheelCatalog.rewards.fold<int>(
      0,
      (sum, item) => sum + item.weight,
    );
    var value = _random.nextInt(total);
    for (final reward in LuckyWheelCatalog.rewards) {
      value -= reward.weight;
      if (value < 0) return reward;
    }
    return LuckyWheelCatalog.rewards.last;
  }

  Future<void> _grant(LuckyWheelResult result) async {
    switch (result.reward.type) {
      case LuckyWheelRewardType.coins:
        final current =
            int.tryParse(
              await _storage.read(key: StoreStorageKeys.coins) ?? '',
            ) ??
            0;
        await _storage.write(
          key: StoreStorageKeys.coins,
          value: '${current + result.reward.quantity}',
        );
      case LuckyWheelRewardType.hammer:
        await _incrementCount(
          StoreStorageKeys.tools,
          'hammer_basic',
          result.reward.quantity,
        );
      case LuckyWheelRewardType.swap:
        await _incrementCount(
          StoreStorageKeys.tools,
          'swap_pair',
          result.reward.quantity,
        );
      case LuckyWheelRewardType.fragment:
        final dinoId = result.dinoId;
        if (dinoId == null) return;
        final collection = _decode(
          await _storage.read(key: StoreStorageKeys.collection),
        );
        final fragments = _map(collection['fragments']);
        final unlocked = _map(collection['unlocked']);
        final amount = _int(fragments[dinoId]) + result.reward.quantity;
        fragments[dinoId] = amount.clamp(0, 8);
        if (amount >= 8) unlocked[dinoId] = true;
        collection['v'] = 1;
        collection['fragments'] = fragments;
        collection['unlocked'] = unlocked;
        await _storage.write(
          key: StoreStorageKeys.collection,
          value: jsonEncode(collection),
        );
    }
  }

  Future<void> _incrementCount(String key, String itemId, int amount) async {
    final values = _decode(await _storage.read(key: key));
    values[itemId] = _int(values[itemId]) + amount;
    await _storage.write(key: key, value: jsonEncode(values));
  }

  LuckyWheelResult? _decodeResult(Object? raw) {
    if (raw is! Map) return null;
    final catalogReward = LuckyWheelCatalog.byId('${raw['rewardId']}');
    if (catalogReward == null || raw['spinResultId'] == null) return null;
    final typeName = raw['type']?.toString();
    LuckyWheelRewardType? type;
    for (final value in LuckyWheelRewardType.values) {
      if (value.name == typeName) type = value;
    }
    final reward = LuckyWheelReward(
      id: catalogReward.id,
      type: type ?? catalogReward.type,
      quantity: max(1, _int(raw['quantity'])),
      weight: catalogReward.weight,
    );
    return LuckyWheelResult(
      resultId: '${raw['spinResultId']}',
      reward: reward,
      segmentIndex: _int(raw['segmentIndex']).clamp(0, 7),
      createdAt: DateTime.fromMillisecondsSinceEpoch(_int(raw['at'])),
      dinoId: raw['dinoId']?.toString(),
    );
  }

  Future<void> _save() =>
      _storage.write(key: _stateKey, value: jsonEncode(_data));

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.map((key, item) => MapEntry('$key', item)) : {};

  Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final value = jsonDecode(raw);
      return _map(value);
    } catch (_) {
      return {};
    }
  }
}
