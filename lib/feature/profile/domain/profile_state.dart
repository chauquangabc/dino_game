import 'dino_collection_item.dart';
import 'profile_catalog.dart';

enum ProfileTab { collection, chests }

class PlayerProfile {
  const PlayerProfile({
    required this.displayName,
    required this.coins,
    required this.highestLevel,
    this.equippedAvatarId,
  });

  final String displayName;
  final int coins, highestLevel;
  final String? equippedAvatarId;

  String get title => ProfileCatalog.titleFor(highestLevel);

  String get avatarAsset =>
      ProfileCatalog.byId(equippedAvatarId)?.asset ?? ProfileCatalog.babyAsset;
}

class ProfileChest {
  const ProfileChest({
    required this.id,
    required this.name,
    required this.asset,
    required this.quantity,
  });

  final String id, name, asset;
  final int quantity;
}

class ProfileState {
  const ProfileState({
    this.profile,
    this.dinos = const [],
    this.chests = const [],
    this.tab = ProfileTab.collection,
    this.selectedDinoId,
    this.isLoading = true,
    this.actionBusy = false,
    this.error,
    this.message,
  });

  final PlayerProfile? profile;
  final List<DinoCollectionItem> dinos;
  final List<ProfileChest> chests;
  final ProfileTab tab;
  final String? selectedDinoId, error, message;
  final bool isLoading, actionBusy;

  DinoCollectionItem? get selectedDino {
    for (final dino in dinos) {
      if (dino.id == selectedDinoId) return dino;
    }
    return null;
  }

  int get chestCount => chests.fold(0, (sum, item) => sum + item.quantity);

  ProfileState copyWith({
    PlayerProfile? profile,
    List<DinoCollectionItem>? dinos,
    List<ProfileChest>? chests,
    ProfileTab? tab,
    String? selectedDinoId,
    bool? isLoading,
    bool? actionBusy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    dinos: dinos ?? this.dinos,
    chests: chests ?? this.chests,
    tab: tab ?? this.tab,
    selectedDinoId: selectedDinoId ?? this.selectedDinoId,
    isLoading: isLoading ?? this.isLoading,
    actionBusy: actionBusy ?? this.actionBusy,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );
}
