import '../../../core/storage/game_local_store.dart';

enum ProfileDataMode { demo, fresh }

abstract final class ProfileMockData {
  // Chosen for this local build. Existing saves are never reset by changing it.
  static const mode = ProfileDataMode.demo;

  static void seed(GameSave save, {ProfileDataMode mode = mode}) {
    if (save.values[GameStorageKeys.seed] != null) return;
    final demo = mode == ProfileDataMode.demo;
    if (save.values[GameStorageKeys.profile] == null) {
      save.put(GameStorageKeys.profile, {
        'v': 1,
        'displayName': demo ? 'Dino Trainer' : 'DINO98',
      });
    }
    if (save.values[GameStorageKeys.coins] == null) {
      save.values[GameStorageKeys.coins] = demo ? '12500' : '500';
    }
    if (save.values[GameStorageKeys.collection] == null) {
      save.put(GameStorageKeys.collection, {
        'v': 1,
        'fragments': demo
            ? {
                'spiderman': 8,
                'akatsuki': 3,
                'batman': 0,
                'captain': 5,
                'doraemon': 0,
              }
            : <String, int>{},
        'unlocked': demo ? {'spiderman': true} : <String, bool>{},
        'equippedAvatarId': null,
      });
    }
    if (save.values[GameStorageKeys.chests] == null) {
      save.put(GameStorageKeys.chests, {
        'chest_fragment': demo ? 2 : 0,
        'chest_gold': 0,
        'chest_item': 0,
        'chest_mixed': 0,
        'chest_special': 0,
      });
    }
    save.values[GameStorageKeys.seed] = mode.name;
  }
}
