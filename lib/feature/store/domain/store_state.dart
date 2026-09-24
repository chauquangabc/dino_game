import 'store_category.dart';

class StoreState {
  const StoreState({
    this.selectedCategory = StoreCategory.boosters,
    this.coins = 0,
    this.isLoading = true,
    this.purchaseInProgress = false,
    this.message,
    this.toolCounts = const {},
    this.chestCounts = const {},
    this.inventoryCounts = const {},
    this.ownedDinoIds = const {},
    this.ownedPetIds = const {},
    this.foodCounts = const {},
  });

  final StoreCategory selectedCategory;
  final int coins;
  final bool isLoading;
  final bool purchaseInProgress;
  final String? message;
  final Map<String, int> toolCounts;
  final Map<String, int> chestCounts;
  final Map<String, int> inventoryCounts;
  final Set<String> ownedDinoIds;
  final Set<String> ownedPetIds;
  final Map<String, int> foodCounts;

  StoreState copyWith({
    StoreCategory? selectedCategory,
    int? coins,
    bool? isLoading,
    bool? purchaseInProgress,
    String? message,
    bool clearMessage = false,
    Map<String, int>? toolCounts,
    Map<String, int>? chestCounts,
    Map<String, int>? inventoryCounts,
    Set<String>? ownedDinoIds,
    Set<String>? ownedPetIds,
    Map<String, int>? foodCounts,
  }) => StoreState(
    selectedCategory: selectedCategory ?? this.selectedCategory,
    coins: coins ?? this.coins,
    isLoading: isLoading ?? this.isLoading,
    purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
    message: clearMessage ? null : message ?? this.message,
    toolCounts: toolCounts ?? this.toolCounts,
    chestCounts: chestCounts ?? this.chestCounts,
    inventoryCounts: inventoryCounts ?? this.inventoryCounts,
    ownedDinoIds: ownedDinoIds ?? this.ownedDinoIds,
    ownedPetIds: ownedPetIds ?? this.ownedPetIds,
    foodCounts: foodCounts ?? this.foodCounts,
  );
}
