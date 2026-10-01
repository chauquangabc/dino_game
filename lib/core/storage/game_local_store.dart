import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class GameStorageKeys {
  static const profile = 'line98_profile';
  static const coins = 'line98_coins';
  static const collection = 'line98_collection';
  static const chests = 'line98_chests';
  static const tools = 'line98_tools';
  static const inventory = 'line98_inv';
  static const dinoHome = 'line98_dino_home';
  static const luckyWheel = 'line98_lucky_wheel';
  static const level = 'dino-line-98-unlocked-level';
  static const legacyAvatar = 'dino-line-98-equipped-character';
  static const seed = 'line98_profile_seed';
  static const chestResult = 'line98_chest_result';
  static const transaction = 'line98_game_tx';
  static const chestTransaction = 'line98_chest_tx';

  static const values = [
    profile,
    coins,
    collection,
    chests,
    tools,
    inventory,
    dinoHome,
    luckyWheel,
    level,
    legacyAvatar,
    seed,
    chestResult,
  ];
}

/// A mutable snapshot used only inside a serialized local transaction.
class GameSave {
  GameSave(this.values);
  final Map<String, String?> values;

  Map<String, dynamic> object(String key) {
    try {
      return map(jsonDecode(values[key] ?? '{}'));
    } on FormatException {
      return {};
    }
  }

  void put(String key, Object value) => values[key] = jsonEncode(value);

  static Map<String, dynamic> map(Object? value) =>
      value is Map ? value.map((key, item) => MapEntry('$key', item)) : {};

  static int number(Object? value, [int fallback = 0]) =>
      value is num && value.isFinite
      ? value.toInt()
      : int.tryParse('$value') ?? fallback;

  static Map<String, int> counts(Object? value) => map(
    value,
  ).map((key, item) => MapEntry(key, number(item).clamp(0, 0x7fffffff)));
}

/// All game-economy writers share this queue. A write-ahead journal contains
/// absolute after-values: replay after an interrupted write cannot double rewards.
class GameLocalStore {
  GameLocalStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final shared = GameLocalStore();
  final FlutterSecureStorage _storage;
  final _changes = StreamController<void>.broadcast();
  Future<void> _tail = Future<void>.value();
  Stream<void> get changes => _changes.stream;

  Future<T> transaction<T>(
    T Function(GameSave save) update, {
    String journalKey = GameStorageKeys.transaction,
  }) {
    final result = _tail.then((_) async {
      await _recover(GameStorageKeys.transaction);
      await _recover(GameStorageKeys.chestTransaction);
      final entries = await Future.wait(
        GameStorageKeys.values.map(
          (key) async => MapEntry(key, await _storage.read(key: key)),
        ),
      );
      final before = Map<String, String?>.fromEntries(entries);
      final save = GameSave(Map.of(before));
      final value = update(save);
      final writes = <String, String?>{
        for (final key in GameStorageKeys.values)
          if (save.values[key] != before[key]) key: save.values[key],
      };
      if (writes.isNotEmpty) {
        await _storage.write(
          key: journalKey,
          value: jsonEncode({'v': 1, 'writes': writes}),
        );
        await _apply(writes);
        await _storage.delete(key: journalKey);
        _changes.add(null);
      }
      return value;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> recover() => transaction((_) {});

  Future<void> _recover(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return;
    final record = GameSave.map(jsonDecode(raw));
    if (record['writes'] is! Map) {
      throw const FormatException('Invalid local transaction');
    }
    final writes = GameSave.map(record['writes']);
    if (writes.keys.any((key) => !GameStorageKeys.values.contains(key)) ||
        writes.values.any((value) => value != null && value is! String)) {
      throw const FormatException('Invalid transaction writes');
    }
    await _apply(writes.cast<String, String?>());
    await _storage.delete(key: key);
    _changes.add(null);
  }

  Future<void> _apply(Map<String, String?> writes) async {
    for (final entry in writes.entries) {
      if (entry.value == null) {
        await _storage.delete(key: entry.key);
      } else {
        await _storage.write(key: entry.key, value: entry.value);
      }
    }
  }
}
