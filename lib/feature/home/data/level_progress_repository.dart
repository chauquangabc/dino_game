import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/map_level_config.dart';

class LevelProgress {
  const LevelProgress({required this.unlockedLevel, required this.avatarLevel});

  final int unlockedLevel;
  final int avatarLevel;
}

class LevelProgressRepository {
  LevelProgressRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _unlockedLevelKey = 'dino-line-98-unlocked-level';
  static const _avatarLevelKey = 'dino-line-98-avatar-level';

  final FlutterSecureStorage _storage;

  Future<LevelProgress> load() async {
    final values = await Future.wait([
      _storage.read(key: _unlockedLevelKey),
      _storage.read(key: _avatarLevelKey),
    ]);

    final unlocked = _clampLevel(int.tryParse(values[0] ?? '') ?? 1);
    final savedAvatar = int.tryParse(values[1] ?? '') ?? unlocked;
    final avatar = savedAvatar.clamp(1, unlocked);

    return LevelProgress(unlockedLevel: unlocked, avatarLevel: avatar);
  }

  Future<int> unlockLevel(int level) async {
    final current = (await load()).unlockedLevel;
    final next = math.max(current, _clampLevel(level));
    await _storage.write(key: _unlockedLevelKey, value: '$next');
    return next;
  }

  Future<void> saveAvatarLevel(int level, {required int unlockedLevel}) {
    final next = level.clamp(1, unlockedLevel);
    return _storage.write(key: _avatarLevelKey, value: '$next');
  }

  int _clampLevel(int level) => level.clamp(1, MapLevelConfig.levelCount);
}
